terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100.0"
    }
  }

  required_version = ">= 1.5.7"
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

variable "base_name" {
  type = string
  default = "snecck"
  validation {
    condition = length(var.base_name) < 10
    error_message = "Basename must be less than 10 characters and can only contain alphanumeric characters"
  }
}

# Create the compatibility kit resource group
resource "azurerm_resource_group" "rg_nc_storm_compatibility" {
  name     = "rg-${var.base_name}-${var.customer_slug}"
  location = "Sweden Central"
}

# Create the service bus namespace
resource "azurerm_servicebus_namespace" "sb_nc_storm_event_compatibility" {
  name                = "sb-${var.base_name}-${var.customer_slug}"
  location            = azurerm_resource_group.rg_nc_storm_compatibility.location
  resource_group_name = azurerm_resource_group.rg_nc_storm_compatibility.name
  sku                 = "Standard"

  tags = {
    source = "terraform"
  }
}

# Create the required topics
module "topics" {
  for_each     = toset(local.events)
  source       = "./topic_setup"
  name         = "${each.key}"
  namespace_id = azurerm_servicebus_namespace.sb_nc_storm_event_compatibility.id
}

# Create a Shared Access Policy for sender (i.e. the Azure Function)
resource "azurerm_servicebus_namespace_authorization_rule" "sender_sas_policy" {
  name         = "sender_sas_policy"
  namespace_id = azurerm_servicebus_namespace.sb_nc_storm_event_compatibility.id
  listen       = false
  send         = true
  manage       = false
}

# Create a Shared Access Policy for receiver (i.e. your code)
resource "azurerm_servicebus_namespace_authorization_rule" "receiver_sas_policy" {
  name         = "receiver_sas_policy"
  namespace_id = azurerm_servicebus_namespace.sb_nc_storm_event_compatibility.id
  listen       = true
  send         = false
  manage       = false
}

# Storage account for Azure Function
resource "azurerm_storage_account" "sa_nc_compatibility_function" {
  name                     = "sa${var.base_name}${var.customer_slug}"
  resource_group_name      = azurerm_resource_group.rg_nc_storm_compatibility.name
  location                 = azurerm_resource_group.rg_nc_storm_compatibility.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Service Plan for Azure Function
resource "azurerm_service_plan" "sp_nc_compatibility_kit_function" {
  name                = "sa-${var.base_name}-${var.customer_slug}"
  resource_group_name = azurerm_resource_group.rg_nc_storm_compatibility.name
  location            = azurerm_resource_group.rg_nc_storm_compatibility.location
  os_type             = "Linux"
  sku_name            = var.service_plan_sku
}

# Create the function app
resource "azurerm_linux_function_app" "func_nc_compatibility_kit" {
  name                = "func-${var.base_name}${var.customer_slug}"
  resource_group_name = azurerm_resource_group.rg_nc_storm_compatibility.name
  location            = azurerm_resource_group.rg_nc_storm_compatibility.location

  storage_account_name       = azurerm_storage_account.sa_nc_compatibility_function.name
  storage_account_access_key = azurerm_storage_account.sa_nc_compatibility_function.primary_access_key
  service_plan_id            = azurerm_service_plan.sp_nc_compatibility_kit_function.id

  builtin_logging_enabled = true

  connection_string {
    name  = "sb_connection_string"
    type  = "ServiceBus"
    value = azurerm_servicebus_namespace_authorization_rule.sender_sas_policy.primary_connection_string
  }

  identity {
    type = "SystemAssigned"
  }

  https_only = true


  site_config {
    application_stack {
      node_version = "20"
    }
  }
}

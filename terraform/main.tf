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

# Create the compatibility kit resource group
resource "azurerm_resource_group" "rg_nc_storm_compatibility" {
  name     = var.resource_group_name
  location = "Sweden Central"
}

# A Key Vault to store secrets and connection string
resource "azurerm_key_vault" "kv_nc_compatibility_kit" {
  name                        = var.keyvault_name
  location                    = azurerm_resource_group.rg_nc_storm_compatibility.location
  resource_group_name         = azurerm_resource_group.rg_nc_storm_compatibility.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

# Access policy for the current user, to be able to store secrets
# using terraform.
resource "azurerm_key_vault_access_policy" "access_policy_azcli" {
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  key_vault_id = azurerm_key_vault.kv_nc_compatibility_kit.id

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get", "Set"
  ]

  storage_permissions = [
    "Get",
  ]
}

# Create the service bus namespace
resource "azurerm_servicebus_namespace" "sb_nc_storm_event_compatibility" {
  name                = "sb-nc-storm-event-compatibility"
  location            = azurerm_resource_group.rg_nc_storm_compatibility.location
  resource_group_name = azurerm_resource_group.rg_nc_storm_compatibility.name
  sku                 = "Standard"

  tags = {
    source = "terraform"
  }
}

# Create the required topics
module "topics" {
  depends_on   = [azurerm_key_vault_access_policy.access_policy_azcli]
  for_each     = toset(local.events)
  source       = "./topic_setup"
  name         = "${each.key}"
  namespace_id = azurerm_servicebus_namespace.sb_nc_storm_event_compatibility.id
  key_vault_id = azurerm_key_vault.kv_nc_compatibility_kit.id
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

# Save the connection string for the sender in key vault
resource "azurerm_key_vault_secret" "keyvault_secret_sender" {
  depends_on   = [azurerm_key_vault_access_policy.access_policy_azcli]
  name         = "sender-connection-string"
  value        = azurerm_servicebus_namespace_authorization_rule.sender_sas_policy.primary_connection_string
  key_vault_id = azurerm_key_vault.kv_nc_compatibility_kit.id
}

# Save the connection string for the receiver in key vault
resource "azurerm_key_vault_secret" "keyvault_secret_receiver" {
  depends_on   = [azurerm_key_vault_access_policy.access_policy_azcli]
  name         = "receiver-connection-string"
  value        = azurerm_servicebus_namespace_authorization_rule.receiver_sas_policy.primary_connection_string
  key_vault_id = azurerm_key_vault.kv_nc_compatibility_kit.id
}

# Storage account for Azure Function
resource "azurerm_storage_account" "sa_nc_compatibility_function" {
  name                     = "nccompatkitstorage"
  resource_group_name      = azurerm_resource_group.rg_nc_storm_compatibility.name
  location                 = azurerm_resource_group.rg_nc_storm_compatibility.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Service Plan for Azure Function
resource "azurerm_service_plan" "sp_nc_compatibility_kit_function" {
  name                = "sa_nc_compatibility_kit_function"
  resource_group_name = azurerm_resource_group.rg_nc_storm_compatibility.name
  location            = azurerm_resource_group.rg_nc_storm_compatibility.location
  os_type             = "Linux"
  sku_name            = var.service_plan_sku
}

# Create the function app
resource "azurerm_linux_function_app" "func_nc_compatibility_kit" {
  name                = "func-nc-compatibility-kit"
  resource_group_name = azurerm_resource_group.rg_nc_storm_compatibility.name
  location            = azurerm_resource_group.rg_nc_storm_compatibility.location

  storage_account_name       = azurerm_storage_account.sa_nc_compatibility_function.name
  storage_account_access_key = azurerm_storage_account.sa_nc_compatibility_function.primary_access_key
  service_plan_id            = azurerm_service_plan.sp_nc_compatibility_kit_function.id

  connection_string {
    name  = "sb_connection_string"
    type  = "ServiceBus"
    value = azurerm_servicebus_namespace_authorization_rule.sender_sas_policy.primary_connection_string
  }

  identity {
    type = "SystemAssigned"
  }

  https_only = true

  site_config {}
}

# Allow the SystemManaged Identity access to read secrets in Key Vault
resource "azurerm_key_vault_access_policy" "access_policy_function" {
  key_vault_id       = azurerm_key_vault.kv_nc_compatibility_kit.id
  object_id          = "${azurerm_linux_function_app.func_nc_compatibility_kit.identity[0].principal_id}"
  tenant_id          = data.azurerm_client_config.current.tenant_id
  secret_permissions = ["Get"]
}


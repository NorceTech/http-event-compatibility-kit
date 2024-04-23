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

resource "azurerm_resource_group" "rg_nc_storm_compatibility" {
  name     = "rg-nc-storm-compatibility"
  location = "Sweden Central"
}

resource "azurerm_key_vault" "kv_nc_compatibility_kit" {
  name                        = "kv-nc-compatibility-kit"
  location                    = azurerm_resource_group.rg_nc_storm_compatibility.location
  resource_group_name         = azurerm_resource_group.rg_nc_storm_compatibility.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "access_policy_azcli" {
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id
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


resource "azurerm_servicebus_namespace" "sb_nc_storm_event_compatibility" {
  name                = "sb-nc-storm-event-compatibility"
  location            = azurerm_resource_group.rg_nc_storm_compatibility.location
  resource_group_name = azurerm_resource_group.rg_nc_storm_compatibility.name
  sku                 = "Standard"

  tags = {
    source = "terraform"
  }
}

module "topics" {
  depends_on = [azurerm_key_vault_access_policy.access_policy_azcli]
  for_each     = toset(local.events)
  source       = "./topic_setup"
  name         = "${each.key}"
  namespace_id = azurerm_servicebus_namespace.sb_nc_storm_event_compatibility.id
  key_vault_id = azurerm_key_vault.kv_nc_compatibility_kit.id
}

resource "azurerm_servicebus_namespace_authorization_rule" "sender_sas_policy" {
  name         = "sender_sas_policy"
  namespace_id = azurerm_servicebus_namespace.sb_nc_storm_event_compatibility.id
  listen       = false
  send         = true
  manage       = false
}

resource "azurerm_servicebus_namespace_authorization_rule" "receiver_sas_policy" {
  name         = "receiver_sas_policy"
  namespace_id = azurerm_servicebus_namespace.sb_nc_storm_event_compatibility.id
  listen       = true
  send         = false
  manage       = false
}


resource "azurerm_key_vault_secret" "keyvault_secret_sender" {
  depends_on = [azurerm_key_vault_access_policy.access_policy_azcli]
  name         = "sender-connection-string"
  value        = azurerm_servicebus_namespace_authorization_rule.sender_sas_policy.primary_connection_string
  key_vault_id = azurerm_key_vault.kv_nc_compatibility_kit.id
}
resource "azurerm_key_vault_secret" "keyvault_secret_receiver" {
  depends_on = [azurerm_key_vault_access_policy.access_policy_azcli]
  name         = "receiver-connection-string"
  value        = azurerm_servicebus_namespace_authorization_rule.receiver_sas_policy.primary_connection_string
  key_vault_id = azurerm_key_vault.kv_nc_compatibility_kit.id
}

resource "azurerm_storage_account" "sa_nc_compatibility_function" {
  name                     = "nccompatkitstorage"
  resource_group_name      = azurerm_resource_group.rg_nc_storm_compatibility.name
  location                 = azurerm_resource_group.rg_nc_storm_compatibility.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "sp_nc_compatibility_kit_function" {
  name                = "sa_nc_compatibility_kit_function"
  resource_group_name = azurerm_resource_group.rg_nc_storm_compatibility.name
  location            = azurerm_resource_group.rg_nc_storm_compatibility.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

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

output "identity" {
  value = azurerm_linux_function_app.func_nc_compatibility_kit.identity
}
output "principal_id" {
  value = "${azurerm_linux_function_app.func_nc_compatibility_kit.identity[0].principal_id}"
}

data "azurerm_function_app_host_keys" "host_key" {
  name                = azurerm_linux_function_app.func_nc_compatibility_kit.name
  resource_group_name = azurerm_resource_group.rg_nc_storm_compatibility.name
}



resource "azurerm_key_vault_access_policy" "access_policy_function" {
  key_vault_id        = azurerm_key_vault.kv_nc_compatibility_kit.id
  object_id           = "${azurerm_linux_function_app.func_nc_compatibility_kit.identity[0].principal_id}"
  tenant_id           = data.azurerm_client_config.current.tenant_id
#  object_id           = data.azuread_service_principal.app_sp.id
#  tenant_id           = data.azurerm_client_config.current.tenant_id
  secret_permissions  = ["Get"]
}


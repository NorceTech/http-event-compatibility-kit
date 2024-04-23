variable "resource_group_name" {
  description = "Resource Group Name for Norce/Storm Event Compatibility Kit"
  type        = string
  default     = "rg-nc-storm-compatibility"
}

variable "keyvault_name" {
  description = "Key Vault name. Globally unique name."
  type        = string
  default     = "kv-nc-compatibility-kit"
}

variable "service_plan_sku" {
  description = "The SKU for the service plan for the function. Default is Y1"
  type        = string
  default     = "Y1"
}
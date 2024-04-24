variable "asdresource_group_name" {
  description = "Resource Group Name for Norce/Storm Event Compatibility Kit"
  type        = string
  default     = "rg-nc-storm-compatibility"
}

variable "asdkeyvault_name" {
  description = "Key Vault name. Globally unique name."
  type        = string
  default     = "kv-nc-compatibility-kit"
}

variable "service_plan_sku" {
  description = "The SKU for the service plan for the function. Default is Y1"
  type        = string
  default     = "Y1"
}

variable "customer_slug" {
  description = "Customer-unique slug to use in naming of resources to handle requirement of globally unique names of azure resources. Max 12 alphanumeric characters."
  validation {
    condition = (length(var.customer_slug) <= 12) && can(regex("[0-9A-Za-z]+", var.customer_slug))
    error_message = "Customer-unique slug must be 12 characters or less and can only contain alphanumeric characters"
  }
  type = string
}
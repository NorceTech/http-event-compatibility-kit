variable "name" {}
variable "namespace_id" {}
variable "key_vault_id" {}

# Create the servicebus topic
resource "azurerm_servicebus_topic" "topic" {
  name                = var.name
  namespace_id        = var.namespace_id
  enable_partitioning = true
}

# Create the servicebus topic subscription
resource "azurerm_servicebus_subscription" "topic_subscription" {
  name               = "${var.name}_subscription"
  topic_id           = azurerm_servicebus_topic.topic.id
  max_delivery_count = 1
}
# Azure
# Path: ./environments/azure/platform/main.tf

locals {
  timestamp = replace(replace(replace(replace(timestamp(), "-", ""), "T", ""), ":", ""), "Z", "")
}

# Management Groups:
## Management Group: Top Level (under tenant root).
resource "azurerm_management_group" "mg_top" {
  display_name = "tshand-com"
}

## Management Group: Platform
resource "azurerm_management_group" "mg_platform" {
  display_name               = "platform"
  parent_management_group_id = azurerm_management_group.mg_top.id
  subscription_ids = [
    var.tf_subscription_id, # Add current platform subscription.
  ]
}

## Management Group: Workload
resource "azurerm_management_group" "mg_workloads" {
  display_name               = "workloads"
  parent_management_group_id = azurerm_management_group.mg_top.id
  subscription_ids = [
    var.tf_subscription_workload_id, # Add workload subscription.
  ]
}

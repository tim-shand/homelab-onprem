#==========================================#
# Platform: Monitoring & Diagnostics
#==========================================#

data "azuread_client_config" "current" {} # Get current user session data.

locals {
  name_part      = "${var.naming["prefix"]}-${var.naming["platform"]}" # Combine name parts in to single var.
  computed_tags  = {
    Modified = replace(replace(replace(replace(timestamp(), "-", ""), "T", ""), ":", ""), "Z", "") # Get timestamp to use for resource tags.
  }
  merged_tags = merge(local.computed_tags, var.tags) # Merge the tag map into existing tags variable.
  sa_name_max_length = 19 # Random integer suffix will add 5 chars, so max = 19 for base name.
  sa_name_base       = "${var.naming["prefix"]}${var.naming["platform"]}${var.naming["project"]}${var.naming["service"]}sa${random_integer.rndint.result}"
  sa_name_truncated  = length(local.sa_name_base) > local.sa_name_max_length ? substr(local.sa_name_base, 0, local.sa_name_max_length - 5) : local.sa_name_base
  sa_name_final      = "${local.sa_name_truncated}${random_integer.rndint.result}"
}

# Generate a random integer to use for suffix for uniqueness.
resource "random_integer" "rndint" {
  min = 10000
  max = 99999
}

# Create Resource Group.
resource "azurerm_resource_group" "plz_log_mon_rg" {
  name     = "${local.name_part}-log-mon-rg"
  location = var.location
  tags     = local.merged_tags
}

# Storage Account for logs.
resource "azurerm_storage_account" "plz_log_mon_sa" {
  name                     = "${local.sa_name_final}"
  resource_group_name      = azurerm_resource_group.plz_log_mon_rg.name
  location                 = azurerm_resource_group.plz_log_mon_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags                     = var.tags
}

#======================================#
# Log Analytics
#======================================#

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "plz_log-mon_law" {
  name                = "${local.name_part}-log-mon-law"
  resource_group_name = azurerm_resource_group.plz_log_mon_rg.name
  location            = azurerm_resource_group.plz_log_mon_rg.location
  tags                = local.merged_tags
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_linked_storage_account" "plz_log-mon_law_sa" {
  data_source_type    = "CustomLogs"
  resource_group_name = azurerm_resource_group.plz_log_mon_rg.name
  workspace_id        = azurerm_log_analytics_workspace.plz_log-mon_law.id
  storage_account_ids = [azurerm_storage_account.plz_log_mon_sa.id]
}

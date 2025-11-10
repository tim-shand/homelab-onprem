#==========================================#
# Platform: Monitoring & Diagnostics
#==========================================#

# Module outputs, to be passed to other modules.

output "plz_log_rg_name" {
  value = azurerm_resource_group.plz_log_mon_rg.name
  description = "Resource Group for Azure logging."
}

output "plz_log_sa_name" {
  value = azurerm_storage_account.plz_log_mon_sa.name
  description = "Storage Account for Azure logging."
}

# output "plz_log_amw_id" {
#   value = azurerm_monitor_workspace.plz_log_mon_amw.id
#   description = "Azure Monitor Workspace ID."
# }

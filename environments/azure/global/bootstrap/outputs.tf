#=================================================================#
# Azure Bootstrap: Outputs
#=================================================================#

# Service Principal
output "out_bootstrap_entraid_sp_name" {
  description = "The display name of the Service Principal used for IaC."
  value       = azuread_application.entra_iac_app.display_name
}

output "out_bootstrap_entraid_sp_appid" {
  description = "The Application ID of the Service Principal used for IaC."
  value       = azuread_application.entra_iac_app.client_id
}

# Backend Resources
output "out_bootstrap_iac_rg" {
  description = "The name of the Resource Group for the IaC backend."
  value = azurerm_resource_group.iac_rg.name
}

output "out_bootstrap_iac_sa" {
  description = "The name of the Storage Account for the IaC backend."
  value = azurerm_storage_account.iac_sa.name
}

output "out_bootstrap_iac_cn" {
  description = "The name of the Storage Account Container for the IaC backend."
  value = azurerm_storage_container.iac_sa_cn.name
}

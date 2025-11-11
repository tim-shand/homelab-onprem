#=================================================================#
# Azure IaC Backend: Outputs
#=================================================================#

# Backend Resources
output "out_iac_cn" {
  description = "The name of the Container for the IaC backend."
  value = azurerm_storage_container.iac_cn.name
}

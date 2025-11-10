#=================================================================#
# Azure IaC Backend: Main
# Creates: 
# - Resources for remote state backends (dedicated subscription).
#=================================================================#

#=================================================================#
# Azure: Backend Resources
#=================================================================#

# Data: Storage Account.
data "azurerm_storage_account" "iac_sa" {
  name                = var.iac_sa_name
  resource_group_name = var.iac_sa_rg
}

# Storage Container.
resource "azurerm_storage_container" "iac_cn" {
  name                  = var.iac_container_name
  storage_account_id    = data.azurerm_storage_account.iac_sa.id
  container_access_type = "private"
}

#=================================================================#
# Github: Secrets and Variables
#=================================================================#

# # Get data for existing Github Repository.
# data "github_repository" "gh_repository" {
#   full_name = "${var.github_config["org"]}/${var.github_config["repo"]}"
# }

# # Github: Variables - IaC Backend details (called during GHA workflows.)
# resource "github_actions_variable" "gh_var_iac_cn" {
#   repository       = data.github_repository.gh_repository.name
#   variable_name    = "ARM_IAC_BACKEND_CN"
#   value            = data.azurerm_storage_account.iac_sa
# }

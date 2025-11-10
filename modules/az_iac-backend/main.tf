#=================================================================#
# Azure IaC Backend: Main
# Creates: 
# - Resources for remote state backends (dedicated subscription).
#=================================================================#

#=================================================================#
# Azure: Entra ID Service Principal - Add Repo Credential
#=================================================================#

# Get current service principal data.
data "azuread_client_config" "current" {}

data "azuread_application" "this_sp" {
  client_id = data.azuread_client_config.current.client_id
}

# Federated credential for Service Principal (to be used with GitHub OIDC).
resource "azuread_application_federated_identity_credential" "entra_iac_app_cred" {
  application_id = data.azuread_application.this_sp.id
  display_name   = "GithubActions-${var.github_config["env"]}"
  description    = "[GithubActions]: ${var.github_config["org"]}/${var.github_config["repo"]} ENV:${var.github_config["env"]}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_config["org"]}/${var.github_config["repo"]}:environment:${var.github_config["env"]}"
}

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

# Get data for existing Github Repository.
data "github_repository" "gh_repo" {
  full_name = "${var.github_config["org"]}/${var.github_config["repo"]}"
}

resource "github_actions_environment_variable" "gh_repo_env_var" {
  repository       = data.github_repository.gh_repo.name
  environment      = var.github_config["env"]
  variable_name    = "ARM_IAC_BACKEND_CN"
  value            = azurerm_storage_container.iac_cn.name
}

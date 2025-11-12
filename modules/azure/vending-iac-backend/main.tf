#=============================================================================#
# Azure IaC Backend: Vending
# Creates: 
# - Resources for remote state backends (using dedicated subscription).
# - REQUIRES: 
#   - Service Principal: Application.ReadWrite.All
#   - Github PAT Token: For creating environments, secrets and variables.
#=============================================================================#

#=================================================================#
# Azure: Entra ID Service Principal - Add OIDC Credential
#=================================================================#

data "azuread_client_config" "current" {} # Get current user session data.

data "azuread_application" "this_sp" {
  client_id = data.azuread_client_config.current.client_id # Get this SP data.
}

# Federated credential for Service Principal (to be used with GitHub OIDC).
resource "azuread_application_federated_identity_credential" "entra_iac_app_cred" {
  count          = var.create_github_env ? 1 : 0 # Only needed is GH environment is created.
  application_id = data.azuread_application.this_sp.id
  display_name   = "oidc-github-${split("/", var.github_repo)[1]}-${var.project_name}"
  description    = "[Github-Actions]: ${var.github_repo} ENV:${var.project_name}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repo}:environment:${var.project_name}"
}

#=================================================================#
# Azure: Backend Resources
#=================================================================#

# Data: Get Storage Account created during bootstrap process for IaC.
data "azurerm_storage_account" "iac_storage_account" {
  name                = var.iac_storage_account_name
  resource_group_name = var.iac_storage_account_rg
}

# Create: Blob Storage Container.
resource "azurerm_storage_container" "iac_storage_container" {
  name                  = "tfstate-${var.project_name}"
  storage_account_id    = data.azurerm_storage_account.iac_storage_account.id
  container_access_type = "private"
}

#=================================================================#
# Github: Environments, Secrets, and Variables
#=================================================================#

# Data: Existing Github Repository.
# data "github_repository" "gh_repo" {
#   full_name = var.github_repo # "my-name/homelab"
# }

# Create: Github Repo - Environment
resource "github_repository_environment" "gh_repo_env" {
  count               = var.create_github_env ? 1 : 0 # Eval the variable true/false to set count.
  environment         = var.project_name # Get from variable map for project. 
  #repository          = data.github_repository.gh_repo.full_name # Obtained from data call.
  repository          = var.github_repo
  deployment_branch_policy {
    protected_branches     = false # Only branches with branch protection rules can deploy to this environment.
    custom_branch_policies = false # Only branches that match the specified name patterns can deploy to this environment.
  }
}

# Create: Github Repo - Environment: Variable (Backend Container)
resource "github_actions_environment_variable" "gh_repo_env_var" {
  count            = var.create_github_env ? 1 : 0 # Eval the variable true/false to set count.
  #repository       = data.github_repository.gh_repo.full_name
  repository       = github_repository_environment.gh_repo_env.repository
  environment      = github_repository_environment.gh_repo_env[count.index].environment
  variable_name    = "TF_BACKEND_CONTAINER"
  value            = azurerm_storage_container.iac_storage_container.name
}

# Create: Github Repo - Environment: Variable (Backend Key)
resource "github_actions_environment_variable" "gh_repo_env_var_key" {
  count           = var.create_github_env ? 1 : 0 # Eval the variable true/false to set count.
  repository      = github_repository_environment.gh_repo_env.repository
  environment     = github_repository_environment.gh_repo_env[count.index].environment
  variable_name   = "TF_BACKEND_KEY"
  value           = "tfstate-${var.project_name}.tfstate"
}

#=============================================================================#
# Azure IaC Backend: Vending
# Creates: 
# - Resources for remote state backends (using dedicated subscription).
# - REQUIRES: 
#   - Service Principal: Application.ReadWrite.All
#   - Github PAT Token: For creating environments, secrets and variables.
#=============================================================================#

# REQUIRED! :: Github provider MUST be defined in child modules to avoid issues with provider mismatch.
# Info: https://github.com/integrations/terraform-provider-github/issues/876#issuecomment-1303790559

terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
  }
}

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
  display_name   = "oidc-github-${var.github_config["repo"]}-${var.project_name}"
  description    = "[Github-Actions]: ${var.github_config["owner"]}/${var.github_config["repo"]} ENV:${var.project_name}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_config["owner"]}/${var.github_config["repo"]}:environment:${var.project_name}"
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

# Create: Github Repo - Environment
resource "github_repository_environment" "gh_repo_env" {
  count               = var.create_github_env ? 1 : 0 # Eval the variable true/false to set count.
  environment         = var.project_name # Get from variable map for project. 
  repository          = var.github_config["repo"]
}

# Create: Github Repo - Environment: Secret (Resource Subscription ID).
resource "github_actions_environment_secret" "gh_repo_env_secret_sub" {
  count            = var.create_github_env ? 1 : 0 # Eval the variable true/false to set count.
  repository       = github_repository_environment.gh_repo_env[count.index].repository
  environment      = github_repository_environment.gh_repo_env[count.index].environment
  secret_name      = "ARM_SUBSCRIPTION_ID"
  plaintext_value  = var.subscription_id
}

# Create: Github Repo - Environment: Variable (Backend Container)
resource "github_actions_environment_variable" "gh_repo_env_var" {
  count            = var.create_github_env ? 1 : 0 # Eval the variable true/false to set count.
  repository       = github_repository_environment.gh_repo_env[count.index].repository
  environment      = github_repository_environment.gh_repo_env[count.index].environment
  variable_name    = "TF_BACKEND_CONTAINER"
  value            = azurerm_storage_container.iac_storage_container.name
}

# Create: Github Repo - Environment: Variable (Backend Key)
resource "github_actions_environment_variable" "gh_repo_env_var_key" {
  count           = var.create_github_env ? 1 : 0 # Eval the variable true/false to set count.
  repository      = github_repository_environment.gh_repo_env[count.index].repository
  environment     = github_repository_environment.gh_repo_env[count.index].environment
  variable_name   = "TF_BACKEND_KEY"
  value           = "${var.project_name}.tfstate"
}

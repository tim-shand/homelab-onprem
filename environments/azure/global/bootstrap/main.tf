#=================================================================#
# Azure Bootstrap: Main
# Creates: 
# - Service Principal, Federated Credentials (OIDC) for IaC.
# - Github repository secrets and variables.
# - Resources for remote state backends (dedicated subscription).
#=================================================================#

# Set default naming conventions.
locals {
  name_part_long = "${var.naming["prefix"]}-${var.naming["platform"]}-${var.naming["service"]}"
  name_part_short = "${var.naming["prefix"]}${var.naming["platform"]}${var.naming["service"]}"
}

#=================================================================#
# Azure: Entra ID
#=================================================================#

# Create App Registration and Service Principal for IaC.
resource "azuread_application" "entra_iac_app" {
  display_name     = "${local.name_part_long}-sp" # Use long naming convention.
  logo_image       = filebase64("./iac-logo.png") # Image file for SP logo.
  owners           = [data.azuread_client_config.current.object_id] # Set current user as owner.
  notes            = "Management: Service Principal for IaC." # Descriptive notes on purpose of the SP.
}

# Service Principal for the App Registration.
resource "azuread_service_principal" "entra_iac_sp" {
  client_id                    = azuread_application.entra_iac_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

# Federated credential for Service Principal (to be used with GitHub OIDC).
resource "azuread_application_federated_identity_credential" "entra_iac_app_cred" {
  application_id = azuread_application.entra_iac_app.id
  display_name   = "GithubActions-OIDC"
  description    = "[Bootstrap]: Github CI/CD, federated credential."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_config["org"]}/${var.github_config["repo"]}:ref:refs/heads/${var.github_config["branch"]}"
}

# Assign 'Contributor' role for SP at top-level tenant root management group.
resource "azurerm_role_assignment" "rbac_mg_sp1" {
  scope                = data.azurerm_management_group.mg_tenant_root.id # Tenant Root MG ID.
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.entra_iac_sp.object_id # Service Principal ID.
}

# Assign 'User Access Administrator' role for SP at top-level tenant root management group.
resource "azurerm_role_assignment" "rbac_mg_sp2" {
  scope                = data.azurerm_management_group.mg_tenant_root.id # Tenant Root MG ID.
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.entra_iac_sp.object_id # Service Principal ID.
}

#=================================================================#
# Azure: Backend Resources
#=================================================================#

# Naming: Dynamically truncate string to a specified maximum length (max 24 chars for Storage Account naming).
locals {
  sa_name_max_length = 19 # Random integer suffix will add 5 chars, so max = 19 for base name.
  sa_name_base       = "${local.name_part_short}sa${random_integer.rndint.result}"
  sa_name_truncated  = length(local.sa_name_base) > local.sa_name_max_length ? substr(local.sa_name_base, 0, local.sa_name_max_length - 5) : local.sa_name_base
}

# Generate a random integer to use for suffix uniqueness.
resource "random_integer" "rndint" {
  min = 100000
  max = 999999
}

# Resource Group.
resource "azurerm_resource_group" "iac_rg" {
  name     = "${local.name_part_long}-rg"
  location = var.location
  tags     = var.tags
}

# Storage Account.
resource "azurerm_storage_account" "iac_sa" {
  name                     = "${local.sa_name_truncated}${random_integer.rndint.result}"
  resource_group_name      = azurerm_resource_group.iac_rg.name
  location                 = azurerm_resource_group.iac_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags                     = var.tags
}

# Storage Container.
resource "azurerm_storage_container" "iac_cn" {
  name                  = "tfstate-azure-mgt-iac-core"
  storage_account_id    = azurerm_storage_account.iac_sa.id
  container_access_type = "private"
}

# Assign 'Storage Data Contributor' role for current user.
resource "azurerm_role_assignment" "rbac_sa_cu" {
  scope                = azurerm_storage_account.iac_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_client_config.current.object_id
}

# Assign 'Storage Data Contributor' role for SP.
resource "azurerm_role_assignment" "rbac_sa_sp" {
  scope                = azurerm_storage_account.iac_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.entra_iac_sp.object_id
}

#=================================================================#
# Github: Secrets and Variables
#=================================================================#

# Get data for existing GetHub Repository.
data "github_repository" "gh_repository" {
  full_name = "${var.github_config["org"]}/${var.github_config["repo"]}"
}

# Github: Secrets - Add Federated Identity Credential (OIDC).
resource "github_actions_secret" "gh_tenant_id" {
  repository      = data.github_repository.gh_repository.name
  secret_name     = "ARM_TENANT_ID"
  plaintext_value = data.azuread_client_config.current.tenant_id
}

resource "github_actions_secret" "gh_subscription_id_iac" {
  repository      = data.github_repository.gh_repository.name
  secret_name     = "ARM_SUBSCRIPTION_ID_IAC"
  plaintext_value = var.subscription_id_iac # Primary platform subscription ID.
}

resource "github_actions_secret" "gh_client_id" {
  repository      = data.github_repository.gh_repository.name
  secret_name     = "ARM_CLIENT_ID"
  plaintext_value = azuread_application.entra_iac_app.client_id # Service Principal federated credential ID.
}

resource "github_actions_secret" "gh_use_oidc" {
  repository      = data.github_repository.gh_repository.name
  secret_name     = "ARM_USE_OIDC" # Must be set to "true" to use OIDC.
  plaintext_value = "true"
}

# Github: Variables - IaC Backend details (called during GHA workflows.)
resource "github_actions_variable" "gh_var_iac_rg" {
  repository       = data.github_repository.gh_repository.name
  variable_name    = "ARM_IAC_BACKEND_RG"
  value            = azurerm_resource_group.iac_rg.name
}

resource "github_actions_variable" "gh_var_iac_sa" {
  repository       = data.github_repository.gh_repository.name
  variable_name    = "ARM_IAC_BACKEND_SA"
  value            = azurerm_storage_account.iac_sa.name
}

resource "github_actions_variable" "gh_var_iac_cn" {
  repository       = data.github_repository.gh_repository.name
  variable_name    = "ARM_IAC_BACKEND_CN"
  value            = azurerm_storage_container.iac_cn.name
}

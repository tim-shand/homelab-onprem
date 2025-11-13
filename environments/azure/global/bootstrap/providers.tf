terraform {
  required_version = ">= 1.13.0"
  required_providers {
      azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 4.40.0"
      }
      azuread = {
          source  = "hashicorp/azuread"
          version = "~> 3.5.0"
      }
      random = {
          source  = "hashicorp/random"
          version = "~> 3.7.2"
      }
      github = {
          source  = "integrations/github"
          version = "~> 6.6.0"
      }
  }
}
provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id_iac # Uses dedicated IaC subscription.
}
provider "random" {}
provider "github" {}

# Get tenant ID From current session, used to obtain tenant root MG.
data "azurerm_management_group" "mg_tenant_root" {
  name = data.azuread_client_config.current.tenant_id
}
data "azuread_client_config" "current" {} # Get current user session data.
data "azurerm_subscription" "current" {} # Get current Azure CLI subscription.

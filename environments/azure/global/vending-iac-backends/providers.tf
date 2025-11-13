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
      github = {
          source  = "integrations/github"
          version = "~> 6.7.5"
      }
  }
  backend "azurerm" {} # Use dynamic backend supplied in GHA workflow, AFTER bootstrap process.
}

provider "azurerm" {
  features {}
  tenant_id       = data.azuread_client_config.current.tenant_id # Get tenant from current session.
  subscription_id = var.subscription_id # Target subscription for resources. 
}

provider "github" {
  owner = var.github_config["owner"]
  token = var.github_token # Repo secret passed in during Github Actions workflow. 
}

data "azuread_client_config" "current" {} # Get current user session data.
data "azurerm_subscription" "current" {} # Get current Azure CLI subscription.

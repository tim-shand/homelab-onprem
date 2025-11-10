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
  backend "azurerm" {} # Use dynamic backend supplied in GHA workflow, AFTER bootstrap process.
}
provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id_iac # Uses dedicated IaC subscription.
}
provider "github" {
  #token = var.gha_token
}

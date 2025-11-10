terraform {
  required_version = ">= 1.5.0"
  required_providers {
    # Used for Azure resources.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # OPTIONAL: Used for Cloudflare resources (DNS, domains, etc).
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.8.2"
    }
    # Used for generating time-based resources, used for timestamps in names or tags.
    time = {
      source = "hashicorp/time"
      version = "0.13.1"
    }
    # Used for GitHub resources, such as repositories, uploading secrets to Github Actions.
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  backend "azurerm" {} # Use dynamic backend supplied in GHA workflow.
}
# Provider configurations.
provider "azurerm" {
  subscription_id   = var.subscription_id # Obtain from GHA workflow.
  tenant_id         = var.azure_tenant_id # Obtain from GHA workflow.
  features {}
}

provider "cloudflare" {
  api_token         = var.cloudflare_api_token# Replace the associated variable with your Cloudflare API token.
}

provider "github" {
  owner             = var.github_org_user # Replace the associated variable with your GitHub org/user.
}

# Get data from current AzCli session.
data "azuread_client_config" "current" {} # Get current user session data.
data "azurerm_subscription" "current" {} # Get current Azure CLI subscription.

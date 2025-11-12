terraform {
  required_version = ">= 1.13.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
  }
  backend "azurerm" {} # Use dynamic backend supplied in GHA workflow.
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id # Project specific subscription.
}

provider "random" {}

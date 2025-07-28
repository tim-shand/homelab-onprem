terraform {
    required_version = ">= 1.5.0"
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 4.37"
        }
        azapi = {
            source  = "Azure/azapi"
            version = "~> 2.5.0"
        }
        random = {
            source  = "hashicorp/random"
            version = "~> 3.5"
        }
        time = {
            source  = "hashicorp/time"
            version = "~> 0.9"
        }
    }
    backend "azurerm" {}
}

provider "azapi" {
    tenant_id         = var.tf_tenant_id
    subscription_id   = var.tf_subscription_id
    client_id         = var.tf_client_id
    client_secret     = var.tf_client_secret
}

provider "azurerm" {
    tenant_id         = var.tf_tenant_id
    subscription_id   = var.tf_subscription_id
    client_id         = var.tf_client_id
    client_secret     = var.tf_client_secret
}

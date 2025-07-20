# Azure
# Path: environments/azure/platform/main.tf

locals {
  timestamp = replace(replace(replace(replace(timestamp(), "-", ""), "T", ""), ":", ""), "Z", "")
}

resource "azurerm_resource_group" "rg-test-01" {
  name      = "${var.orgPrefix}-${var.orgPlatform}-${var.orgProject}-${var.orgEnvironment}-rg"
  location  = var.location_preferred
  tags      = {
    Platform    = var.orgPlatform
    Project     = var.orgProject
    Environment = var.orgEnvironment
    Owner       = var.tagOwner
    Creator     = var.tagCreator
    Created     = local.timestamp
  }
}


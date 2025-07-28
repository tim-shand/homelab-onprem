# Azure
# Path: ./environments/azure/platform/main.tf

locals {
  timestamp = replace(replace(replace(replace(timestamp(), "-", ""), "T", ""), ":", ""), "Z", "")
}

resource "azurerm_resource_group" "rg-test-01" {
  name = "${var.org_prefix}-TestRun-rg"
  #name      = "${var.org_prefix}-${var.org_project}-${var.org_service}-${var.org_environment}-rg"
  location = var.default_location
  tags = {
    Service     = "TestRun" #var.org_service
    Project     = var.org_project
    Environment = "tst" #var.org_environment
    Owner       = var.tag_owner
    Creator     = var.tag_creator
    Created     = local.timestamp
  }
}

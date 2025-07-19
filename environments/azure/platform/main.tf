# Azure

resource "azurerm_resource_group" "rg-test-01" {
  name     = "${var.orgPrefix}-${var.orgPlatform}-${var.orgProject}-${var.orgEnvironment}-rg"
  location = var.location_preferred
  tags = {
    environment = var.orgEnvironment
    platform    = var.orgPlatform
    project     = var.orgProject
  }
}
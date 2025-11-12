#=================================================================#
# TESTING: Workload - Test
#=================================================================#

resource "azurerm_resource_group" "workload_test_rg" {
  name          = "${var.naming["prefix"]}-${var.naming["platform"]}-${var.naming["project"]}-rg"
  location      = var.location
  tags          = var.tags
}


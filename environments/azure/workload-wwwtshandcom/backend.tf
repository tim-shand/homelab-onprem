#=================================================#
# Workload: Personal Website - Backend
#=================================================#

# Values are passed during Github Actions workflow.

terraform {
  backend "azurerm" {} # Use dynamic backend supplied in GHA workflow.
}

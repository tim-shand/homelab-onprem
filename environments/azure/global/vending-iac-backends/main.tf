#=================================================================#
# Vending: Azure IaC Backends
#=================================================================#

#-------------------#
# Azure
#-------------------#

# Backend: Azure - Platform Landing Zone
module "iac_backend_plz" {
  source = "../../../modules/az_iac-backend"
  iac_container_name = "tfstate-azure-platformlz"
  github_config = {
    org = "tim-shand" # Github organization where repository is located.
    repo = "homelab" # Github repository to use for adding secrets and variables.
    env = "Azure-PlatformLandingZone"
  }
  subscription_id_iac = var.subscription_id_iac
  iac_sa_name = var.iac_sa_name
  iac_sa_rg = var.iac_sa_rg
}

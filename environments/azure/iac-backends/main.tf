#=================================================================#
# Azure IaC Backends: Variables
#=================================================================#

module "iac_backend" {
  source = "../../../tfmodules/az_iac-backend"
  iac_container_name = "tfstate-azure-platformlz"
  subscription_id_iac = var.subscription_id_iac
  iac_sa_name = var.iac_sa_name
  iac_sa_rg = var.iac_sa_rg
}

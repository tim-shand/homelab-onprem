#=================================================================#
# Vending: Azure IaC Backends
#=================================================================#

# Backend: Proxmox (on-prem)
module "vending_iac_backends" {
  for_each = var.projects # Repeat for all listed in terraform.tfvars
  source = "../../../../modules/azure/vending-iac-backend"
  iac_storage_account_rg = var.iac_storage_account_rg
  iac_storage_account_name = var.iac_storage_account_name
  github_config = var.github_config
  project_name = each.key # Prefixed with "tfstate": tfstate-proxmox
  create_github_env = each.value.create_github_env
}

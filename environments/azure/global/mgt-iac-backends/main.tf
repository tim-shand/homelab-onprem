#=================================================================#
# Vending: Azure IaC Backends
#=================================================================#

# Backend: Proxmox (on-prem)
module "iac_backends" {
  for_each = var.projects # Repeat for all listed in terraform.tfvars
  source = "../../../modules/azure/vending-iac-backend"
  iac_sa_rg = var.iac_sa_rg
  iac_sa_name = var.iac_sa_name
  github_repo = "tim-shand/homelab"
  project_name = each.key # Prefixed with "tfstate": tfstate-proxmox
  create_github_env = each.value.create_github_env
}

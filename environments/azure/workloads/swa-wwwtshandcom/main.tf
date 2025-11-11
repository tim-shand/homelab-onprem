#=================================================#
# Workload: Personal Website (www.tshand.com)
#=================================================#

module "swa-tshand-com" {
  source = "../../modules/app-web-staticwebapp"
  location = var.location
  subscription_id = var.subscription_id
  subscription_mg_name = var.management_group
  custom_domain_name = var.custom_domain_name
  swa_naming = var.naming
  swa_tags = var.tags
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_dnshost = var.cloudflare_dnshost
  cloudflare_zone_id = var.cloudflare_zone_id
  github_org_user = var.github_org_user
  github_repo_name = var.github_repo_name
  github_branch = var.github_branch
}

#=================================================================#
# Azure IaC Backend: Outputs
#=================================================================#

# Azure Backend Resources
output "out_iac_cn" {
  description = "The name of the Container for the IaC backend."
  value = azurerm_storage_container.iac_storage_container.name
}

# Github Environment Resources
output "out_gh_env" {
  description = "Name of the newly created Github environment."
  value = var.create_github_env ? github_repository_environment.gh_repo_env[0].environment : null
  # if: var.create_github_env (true) ? get: value | else: null
}

output "github_environment_created" {
  description = "Output the variable state: true/false."
  value = var.create_github_env 
}

output "github_environment_name" {
  description = "If created, output the name of the environment."
  value = var.create_github_env ? var.project_name : null
}

#=================================================================#
# Azure IaC Backends: Variables
#=================================================================#

variable "subscription_id_iac" {
  description = "Azure subscription for IaC."
  type        = string
}

variable "iac_storage_account_rg" {
  description = "Resource Group of the Storage Account for IaC backends."
  type        = string
}

variable "iac_storage_account_name" {
  description = "Storage Account name for IaC backends."
  type        = string
}

variable "github_repo" {
  description = "Full path for Github repository, including organization (my-name/homelab)."
  type = string
}

variable "projects" {
  description = "Map of project config for new IaC backends."
  type        = map(object({
                  create_github_env = bool
                }))
}

# variable "project_name" {
#   description = "Name of project for new IaC backend."
#   type        = string
# }

# variable "create_github_env" {
#   description = "Toggle the creation of Github environment and variables."
#   type = bool
#   default = false
# }

variable "github_token" {
  description = "Github PAT token for creating environments and secrets."
  type        = string
  sensitive   = true
  validation {
    condition     = var.create_github_env == false || var.github_token != ""
    error_message = "GitHub token must be provided when create_github_env = true."
  }
}

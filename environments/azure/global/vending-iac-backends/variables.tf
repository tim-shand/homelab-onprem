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

variable "projects" {
  description = "Map of project config for new IaC backends."
  type = map(object({
    create_github_env = bool
    subscription_id   = string
  }))
}

variable "github_config" {
  description = "Map of values for Github configuration."
  type = map(string)
}

variable "github_token" {
  description = "Github PAT token for creating environments and secrets."
  type        = string
  sensitive   = true
}

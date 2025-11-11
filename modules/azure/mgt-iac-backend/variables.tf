#=================================================================#
# Azure IaC Backend: Variables
#=================================================================#

variable "subscription_id_iac" {
  description = "Target Azure subscription for IaC."
  type        = string
}

variable "iac_storage_account_name" {
  description = "Storage Account name for IaC backends."
  type        = string
}

variable "iac_storage_account_rg" {
  description = "Resource Group of the Storage Account for IaC backends."
  type        = string
}

variable "iac_project_name" {
  description = "Name of the project for new IaC backend."
  type        = string
}

variable "github_config" {
  description = "A map of Github settings."
  type        = map(string)
  default     = {}
}

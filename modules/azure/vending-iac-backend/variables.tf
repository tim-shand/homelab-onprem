#=================================================================#
# Azure IaC Backend: Variables
#=================================================================#

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

variable "project_name" {
  description = "Name of project for new IaC backend."
  type        = string
}

variable "create_github_env" {
  description = "Toggle the creation of Github environment and variables."
  type = bool
  default = false
}

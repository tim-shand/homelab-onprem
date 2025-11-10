#=================================================================#
# Azure IaC Backends: Variables
#=================================================================#

variable "tenant_id" {
  description = "Target Azure tenant for IaC backend deployments."
  type        = string
}

variable "subscription_id_iac" {
  description = "Target Azure subscription for IaC backend deployments."
  type        = string
}

variable "iac_sa_rg" {
  description = "Target Azure subscription for IaC backend deployments."
  type        = string
}

variable "iac_sa_name" {
  description = "Target Azure subscription for IaC backend deployments."
  type        = string
}

variable "github_config" {
  description = "A map of Github settings."
  type        = map(string)
  default     = {}
}

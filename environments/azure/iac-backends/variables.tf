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

variable "gha_token" {
  description = "Github Actions token for modifying environment secrets."
  type        = string
  sensitive   = true
}

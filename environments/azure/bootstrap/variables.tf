#=================================================================#
# Azure Bootstrap: Variables
#=================================================================#

variable "tenant_id" {
  description = "Target Azure tenant for deployments."
  type        = string
}

variable "subscription_id_iac" {
  description = "Target Azure subscription for IaC."
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources into."
  type        = string
}

variable "naming" {
  description = "A map of naming parameters to use with resources."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "github_config" {
  description = "A map of Github settings."
  type        = map(string)
  default     = {}
}

#=================================================================#
# Azure IaC Backend: Variables
#=================================================================#

variable "subscription_id_iac" {
  description = "Target Azure subscription for IaC."
  type        = string
}

variable "iac_sa_rg" {
  description = "Target Azure subscription for IaC."
  type        = string
}

variable "iac_sa_name" {
  description = "Target Azure subscription for IaC."
  type        = string
}

variable "iac_container_name" {
  description = "Name of the container for new backend state."
  type        = string
}

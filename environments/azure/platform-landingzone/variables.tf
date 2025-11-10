#=================================================#
# Platform: Deploying Azure Platform Landing Zone.
#=================================================#

variable "azure_tenant_id" {
  description = "The Azure Tenant ID to deploy resources into."
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID for the target changes."
  type        = string
}

variable "location" {
  description = "The Azure location to deploy resources into."
  type        = string
  default     = "australiaeast"
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

variable "core_management_group_id" {
  description = "Desired ID of the top-level management group (under Tenant Root)."
  type        = string
}

variable "core_management_group_display_name" {
  description = "Desired display name of the top-level management group (under Tenant Root)."
  type        = string
}

# Module Switches

variable "enable_plz_hubvnet" {
  type    = bool # If enable_hub_network = true, Terraform creates a map: { "hub" = true }.
  default = true # If it’s false, the map is empty ({}) and Terraform skips the module.
}
variable "enable_plz_logging" {
  type    = bool # If enable_hub_network = true, Terraform creates a map: { "hub" = true }.
  default = true # If it’s false, the map is empty ({}) and Terraform skips the module.
}

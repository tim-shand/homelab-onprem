#=================================================================#
# TESTING: Workload - Test: Variables
#=================================================================#

variable "subscription_id" {
  description   = "Azure subscription for project."
  type          = string
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

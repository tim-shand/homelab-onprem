#==========================================#
# Platform: Monitoring & Diagnostics
#==========================================#

# Variables for the module.

variable "location" {
  description = "Target location for resources."
  type    = string
}

variable "naming" {
  description = "Map of naming conventions used for resources."
  type = map(string)
}

variable "tags" {
  description = "Map of key/value pairs used for resource tagging."
  type = map(string)
}

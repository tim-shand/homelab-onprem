# Terraform Variables
variable "tfbackend_resourcegroup" {
    type = string
    description = "Terraform backend Resource Group name."
}
variable "tfbackend_storageaccount" {
    type = string
    description = "Terraform backend Storage Account name."
}
variable "tfbackend_container" {
    type = string
    description = "Terraform backend Resource Group name."
}

# Azure: Platform Variables
variable "tenant_id" {
    type = string
    description = "Azure Tenant."
}
variable "subscription_id" {
    type = string
    description = "Azure Subscription."
}
variable "client_id" {
    type = string
    description = "Azure Service Principal (AppId)."
}
variable "client_secret" {
    type = string
    description = "Azure Service Principal Client Secret."
}
variable "location_preferred" {
    type = string
    description = "Preferred Azure location for resources."
}
variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
}

# Naming Conventions (using validations)
variable "orgPrefix" {
    type = string
    description = "Core naming prefix for majority of resources."
    validation {
        condition     = length(var.orgPrefix) == 3 # Must be exactly 3 characters
        error_message = "The orgPrefix must be exactly 3 characters long."
    }
}
variable "orgPlatform" {
    type = string
    description = "Platform code for naming convention."
}
variable "orgProject" {
    type = string
    description = "Project code for naming convention."
}
variable "orgEnvironment" {
    type = string
    description = "Environment code for naming convention (prd, dev, tst)."
    validation {
        condition = contains(["prd","dev","tst" ], var.orgEnvironment)
        error_message = "Valid value is one of the following: prd, dev, tst."
    }
}

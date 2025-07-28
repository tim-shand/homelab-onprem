# Terraform Variables
variable "tf_backend_resourcegroup" {
    type = string
    description = "Terraform backend Resource Group name."
}
variable "tf_backend_storageaccount" {
    type = string
    description = "Terraform backend Storage Account name."
}
variable "tf_backend_container" {
    type = string
    description = "Terraform backend Resource Group name."
}
variable "tf_backend_key" {
    type = string
    description = "Terraform backend Key name."
}

# Azure: Platform Variables
variable "tf_tenant_id" {
    type = string
    description = "Azure Tenant."
}
variable "tf_subscription_id" {
    type = string
    description = "Azure Subscription."
}
variable "tf_client_id" {
    type = string
    description = "Azure Service Principal (AppId)."
}
variable "tf_client_secret" {
    type = string
    description = "Azure Service Principal Client Secret."
}
variable "default_location" {
    type = string
    description = "Default Azure location for resources."
}

# Naming Conventions (using validations)
variable "org_prefix" {
    type = string
    description = "Core naming prefix for majority of resources."
    validation {
        condition     = length(var.org_prefix) == 3 # Must be exactly 3 characters
        error_message = "The org_pefix must be exactly 3 characters long."
    }
}
variable "org_service" {
    type = string
    description = "Service code for naming convention."
}
variable "org_project" {
    type = string
    description = "Project code for naming convention."
}
variable "org_environment" {
    type = string
    description = "Environment code for naming convention (prd, dev, tst)."
    validation {
        condition = contains(["prd","dev","tst" ], var.org_environment)
        error_message = "Valid value is one of the following: prd, dev, tst."
    }
}
variable "tag_creator" {
    type = string
    description = "Name of account creating resources."
}
variable "tag_owner" {
    type = string
    description = "Name of account creating resources."
}

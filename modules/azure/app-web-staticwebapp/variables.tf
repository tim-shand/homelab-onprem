#======================================#
# Module: Static Web App - Variables
#======================================#

# Azure
variable "subscription_id" {
  description = "Subscription ID for the target resources."
  type        = string
}

variable "location" {
  description = "The Azure location to deploy resources into."
  type        = string
}

variable "subscription_mg_name" {
  description = "Desired ID of the top-level management group (under Tenant Root)."
  type        = string
}

variable "swa_naming" {
  description = "A map of naming parameters to use with resources."
  type        = map(string)
  default     = {}
}

variable "swa_tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "custom_domain_name" {
  description = "Custom domain name to use with DNS CNAME and Azure SWA."
  type        = string
}

# Cloudflare: https://developers.cloudflare.com/fundamentals/api/get-started/create-token/
variable "cloudflare_zone_id" {
  description = "Github owner or organization."
  type        = string
}
variable "cloudflare_api_token" {
  description = "Github owner or organization."
  type        = string
}
variable "cloudflare_dnshost" {
  description = "Github owner or organization."
  type        = string
}

# Github
variable "github_org_user" {
  description = "Github owner or organization."
  type        = string
}

variable "github_repo_name" {
  description = "Name of Github repository holding source code."
  type        = string
}

variable "github_branch" {
  description = "Github repository branch to use."
  type        = string
  default     = "main"
}

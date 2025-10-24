#======================================================#
# Proxmox: Terraform - Providers File (Root)
#======================================================#

# Provider: Proxmox (BGP)
terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.85.1"
    }
  }
}

# Configuration:
provider "proxmox" {
  endpoint  = var.pve_host_config_01["url"] # Select first Proxmox API URL from list.
  api_token = var.pve_auth_api_token # Pass in variable to avoid hard-coding.
  insecure = true # Disable TLS certificate verification is required when using self-signed certificate.
}

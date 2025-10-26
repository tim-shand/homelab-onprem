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
  ssh {
    agent = true # Required for some actions not supported by Proxmox API, creating custom disks (templates).
    username  = var.pve_auth_ssh_un
    private_key = file(var.pve_auth_ssh_keyfile) # Generate local key-pair: ssh-keygen -t ed25519 | Add .pub to PVE node: ssh-copy-id user@pve_node
  }
}

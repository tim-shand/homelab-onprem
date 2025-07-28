terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.69.1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.root_pve_url
  api_token = var.root_pve_api_token
  ssh {
    agent = true
    username = var.root_pve_un
    password = var.root_pve_pw
  }
  insecure  = true
}
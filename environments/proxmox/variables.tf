#======================================================#
# Proxmox: Terraform - Variable Definitions File (Root)
#======================================================#

#----- Proxmox: Host Configuration -----#
variable "pve_auth_api_token" {
  description   = "Proxmox service account API token for Terraform."
  type          = string
  sensitive     = true # Secret value, keep hidden from outputs.
}

variable "pve_auth_ssh_un" {
  description   = "SSH account username, used for non-supported API actions."
  type          = string
  sensitive     = true # Secret value, keep hidden from outputs.
}

variable "pve_auth_ssh_keyfile" {
  description   = "SSH key file path, used for non-supported API actions."
  type          = string
  sensitive     = true # Secret value, keep hidden from outputs.
}

variable "pve_sys_node_domain_dns" {
  description   = "Map of domain and DNS configuration for the Proxmox cluster nodes."
  type          = map(string)
}

variable "pve_host_config_01" {
  description   = "A map of configuration items for Proxmox host 1."
  type          = map(string)
}

variable "pve_host_config_02" {
  description   = "A map of configuration items for Proxmox host 2."
  type          = map(string)
}

#----- VM: Cloud-Init Configuration -----#
variable "cloudinit_config" {
  description   = "Map of default cloud-init settings to use with VMs."
  type          = map(string)
}

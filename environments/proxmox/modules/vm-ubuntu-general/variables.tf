#=============================================================#
# Proxmox: Module - VM: Ubuntu General - Variables
#=============================================================#

variable "instances" {
  description   = "Number of VMs to create (0=none/destroy)."
  type          = number
}

variable "vm_details" {
  description   = "An object of configuration items for the VM."
  type = object({
    name        = string
    description = string
    pool_id     = string
    tags        = set(string)
    cpu         = number
    mem         = number
    disk_gb     = number
    vlan_id     = string
    cidr        = string
    subnet      = string
    ip_start    = number
    domain      = string
    gateway     = string
    dns         = string
  })
}

variable "pve_node_config" {
  description   = "A map of configuration items for Proxmox host."
  type          = map(string)
}

variable "cloudinit_config" {
  description   = "Map of default cloud-init settings to use with VMs."
  type          = map(string)
}

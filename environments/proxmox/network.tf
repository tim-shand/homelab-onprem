#======================================================#
# Proxmox: Terraform - Networking (Root)
#======================================================#

# Networking: PVE Nodes -------------------------------------------------------#
# Import: terraform -chdir=environments/proxmox import -var-file=env/prod.tfvars \
# proxmox_virtual_environment_network_linux_bridge.pve01_vmbr0 pve01:vmbr0 
resource "proxmox_virtual_environment_network_linux_bridge" "pve01_vmbr0" {
  node_name     = var.pve_host_config_01["name"]
  name          = "vmbr0"
  comment       = "PVE-Hosts"
  address       = "10.0.10.10/24" # Proxmox Host IP.
  gateway       = "10.0.10.254"
  autostart     = true
  vlan_aware    = false # Used to carry multiple VLANs.
  ports         = [ # Network (or VLAN) interfaces to attach to the bridge, specified by their interface name.
    var.pve_host_config_01["pve_nic"]
  ]
}

resource "proxmox_virtual_environment_network_linux_bridge" "pve02_vmbr0" {
  node_name     = var.pve_host_config_02["name"]
  name          = "vmbr0"
  comment       = "PVE-Hosts"
  address       = "10.0.10.11/24" # Proxmox Host IP.
  gateway       = "10.0.10.254"
  autostart     = true
  vlan_aware    = false # Used to carry multiple VLANs.
  ports         = [ # Network (or VLAN) interfaces to attach to the bridge, specified by their interface name.
    var.pve_host_config_02["pve_nic"]
  ]
}

# Networking: VM VLANs -------------------------------------------------------#
resource "proxmox_virtual_environment_network_linux_bridge" "pve01_vmbr1" {
  node_name     = var.pve_host_config_01["name"]
  name          = "vmbr1"
  comment       = "VLAN-SVR"
  autostart     = true
  vlan_aware    = true # Used to carry multiple VLANs.
  ports         = [ # Network (or VLAN) interfaces to attach to the bridge, specified by their interface name.
    var.pve_host_config_01["usb_nic"]
  ]
}

resource "proxmox_virtual_environment_network_linux_bridge" "pve02_vmbr1" {
  node_name     = var.pve_host_config_02["name"]
  name          = "vmbr1"
  comment       = "VLAN-SVR"
  autostart     = true
  vlan_aware    = true # Used to carry multiple VLANs.
  ports         = [ # Network (or VLAN) interfaces to attach to the bridge, specified by their interface name.
    var.pve_host_config_02["usb_nic"]
  ]
}

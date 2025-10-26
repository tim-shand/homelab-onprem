#======================================================#
# Proxmox: Terraform - Networking (Root)
#======================================================#

# Networking: Bridges -------------------------------------------------------#
# Import: terraform import proxmox_virtual_environment_network_linux_bridge.vmbr99 pve:vmbr99
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

# Create matching networking on second PVE node.
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

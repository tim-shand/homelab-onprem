### pfSense Firewall
# URL: https://atxfiles.netgate.com/mirror/downloads/

terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.69.1"
    }
  }
}

resource "proxmox_virtual_environment_vm" "fw_pfsense" {
  count   = var.instances
  name    = "${var.hostname_prefix}0${count.index + 1}"
  vm_id   = sum([var.vmid_start, count.index + 1])
  clone {
    vm_id = 9100
    full = true
  }
  on_boot = true
  startup {
    order = 1
  }
  pool_id = var.pool_id
  node_name = var.node_name
  description = "Firewall: pfSense 2.7.2"
  tags        = var.tags
  network_device {
    bridge = var.vnet1
    mac_address = var.macaddress
  }
  network_device {
    bridge = var.vnet2
  }
  network_device {
    bridge = var.vnet3
  }
}

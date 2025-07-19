terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.69.1"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm_k8s_master" {
  count   = var.instances
  name    = "${var.hostname_prefix}0${count.index + 1}"
  vm_id   = sum([var.vmid_start, count.index + 1])
  on_boot = true
  agent {
    enabled = true
  }
  startup {
    order = "${var.vmid_start + count.index}"
  }
  operating_system {
    type = "l26"
  }
  pool_id = var.pool_id
  node_name = var.node_name
  description = "Kubernetes: Master Node ${count.index + 1} (Control Plane)"
  tags        = var.tags
  cpu {
    cores = 2
    type = "x86-64-v2-AES"  # recommended for modern CPUs
  }
  memory {
    dedicated = 2048
    floating  = 2048 # set equal to dedicated to enable ballooning
  }
  disk {
    datastore_id = "local-lvm"
    file_id      = "local:iso/noble-server-cloudimg-amd64.img"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 32
  }
  network_device {
    bridge = var.vnet
  }
  initialization {
    ip_config {
      ipv4 {
        #address = "${var.ipv4_address}.${count.index + 5}/24"
        address = "${var.ipv4_address}${count.index}/24"
        gateway = var.ipv4_gateway
      }
    }
    dns {
      domain = var.domain
      servers = [ var.dns_servers ]
    }
    user_account {
      username = var.auth_username
      password = var.auth_password
      keys = [ var.auth_keys ]
    }
  }
}

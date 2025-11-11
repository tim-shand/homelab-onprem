#=============================================================#
# Proxmox: Module - VM: Ubuntu General
#=============================================================#

# Import: `terraform import proxmox_virtual_environment_cluster_options.options cluster` 

#----- Terraform: Providers -----#
terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.85.1"
    }
  }
}

#----- VM: Ubuntu General -----#
resource "proxmox_virtual_environment_vm" "vm_ubuntu_general" {
  count       = var.instances # 0=Destroy.
  name        = "${var.vm_details["name"]}0${count.index + 1}" # "svr-mgt-utl01"
  description = "${var.vm_details["description"]} 0${count.index + 1}" # "Management: Utility Server 01"
  node_name   = var.pve_node_config["name"] # Proxmox Node
  clone {
    vm_id     = "9901" # Ubuntu 24.04 Cloud-Init image.
    full      = true # Create a full clone, instead of linked clone.
  }
  pool_id     = var.vm_details["pool_id"] # "Management"
  tags        = var.vm_details["tags"] # ["mgt", "ubuntu"] # List of tags to apply to the VM.
  on_boot     = true
  bios        = "ovmf"
  stop_on_destroy = true
  agent {
    enabled   = true
  }
#   startup {
#     order     = "${count.index + 1}"
#   }
  cpu {
    cores     = var.vm_details["cpu"] # 2
    type      = "host"  # x86-64-v2-AES.
  }
  memory {
    dedicated = var.vm_details["mem"] # 2048 # 2GB RAM.
  }

  tpm_state {
    datastore_id    = "pve-zfs-pool"
    version         = "v2.0" # Use TPM 2.0 (required for Windows 11+).
  }

  efi_disk {
    datastore_id = "pve-zfs-pool"
    type         = "4m" # Required for Secure Boot. For backwards compatibility use 2m. 
  }

  disk {
    datastore_id = "pve-zfs-pool" # Use ZFS pool for storage.
    interface    = "virtio0"
    iothread     = true # Only valid for VirtIO disks.
    discard      = "on"
    size         = var.vm_details["disk_gb"] # 32
  }
  network_device {
    bridge    = var.pve_node_config["vm_net"] # VLAN aware Linux bridge.
    vlan_id   = var.vm_details["vlan_id"]
  }
  initialization {
    datastore_id  = "pve-zfs-pool" # Use ZFS pool for Cloud-Init disk storage.
    ip_config {
      ipv4 {
        address   = "${cidrhost(var.vm_details["subnet"], count.index + var.vm_details["ip_start"])}${var.vm_details["cidr"]}" # Adds x to begin IP addressing.
        gateway   = var.vm_details["gateway"]
      }
    }
    dns {
      domain      = var.vm_details["domain"]
      servers     = ["${var.vm_details["dns"]}"]
    }
    user_account {
      username    = var.cloudinit_config["username"]
      password    = var.cloudinit_config["password"]
    }
  }
}

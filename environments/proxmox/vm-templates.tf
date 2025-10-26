#======================================================#
# Proxmox: Terraform - VM Templates (Root)
#======================================================#

### NOTES ###
# - Currently requires SSH from runner to PVE host for creating custom disks (templates).

#----- VM Template: Ubuntu 24.04 (Cloud-Init) -----#

# Variables: Local File
locals {
  ubuntu_version = "noble" # Specify code name of latest Ubuntu release.
  template_image_storage = "local" # Set default storage for template files.
  template_disk_storage = "local-lvm" # Set default storage for template files.
}

# Download: Image File - Ubuntu Server
# resource "proxmox_virtual_environment_download_file" "image_ubuntu" {
#   content_type = "import" # iso
#   datastore_id = "${local.template_image_storage}" # Where to store image files.
#   node_name     = var.pve_host_config_01["name"] # Proxmox Node 1
#   url = "https://cloud-images.ubuntu.com/${local.ubuntu_version}/current/${local.ubuntu_version}-server-cloudimg-amd64.img"
#   file_name = "${local.ubuntu_version}-server-cloudimg-amd64.qcow2" # Need to rename file to .qcow2 to indicate the actual file format for import.
# }

# VM Template: Ubuntu Server
resource "proxmox_virtual_environment_vm" "vm_template_ubuntu24" {
  vm_id         = 9901
  count         = 1 # 1=Create, 0=Destroy
  name          = "vm-template-ubuntu24"
  description   = "VM Template: Ubuntu 24.04 (Cloud-Init)"
  pool_id       = "Templates" # Assign to 'Templates' pool.
  node_name     = var.pve_host_config_01["name"] # Proxmox Node 1
  template      = true # Set VM resource to be template.
  started       = false # Do not run after creation.
  machine       = "q35" # Q35=(newer, more modern chipset, supports native PCIe devices | i440fx=(older chipset,only supports older PCI bus).
  bios          = "ovmf" # seabios=(legacy BIOS), ovmf=(UEFI, requires 'efi_disk' block to be defined below). 
  operating_system {
    type = "l26" # l26=(Linux Kernel 2.6 - 5.X), win11=(Windows 11/2022-2025). 
  }
  tpm_state {
    datastore_id = "${local.template_disk_storage}"
    version = "v2.0" # Use TPM 2.0 (required for Windows 11+).
  }
  cpu {
    cores     = 2
    type      = "host"  # Use host CPU features (must be the same on all PVE nodes), otherwise x86-64-v2-AES (generic).
  }
  memory {
    dedicated = 2048 # 2GB RAM.
  }
  efi_disk {
    datastore_id = "${local.template_disk_storage}"
    type         = "4m" # Required for Secure Boot. For backwards compatibility use 2m. 
  }
  disk {
    datastore_id = "${local.template_disk_storage}"
    file_id      = "local:iso/noble-server-cloudimg-amd64.img" #proxmox_virtual_environment_download_file.image_ubuntu.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 32 # 32 GB
  }
  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      username    = var.cloudinit_config["username"]
      password    = var.cloudinit_config["password"]
    }
  }
  network_device {
    bridge = proxmox_virtual_environment_network_linux_bridge.pve01_vmbr1.name
  }
}

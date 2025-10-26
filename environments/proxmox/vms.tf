#=============================================================#
# Proxmox: Terraform - VMs
#=============================================================#

#----- VM: Management Server -----#
# Import: `terraform import proxmox_virtual_environment_cluster_options.options cluster` 
resource "proxmox_virtual_environment_vm" "vm_svr-mgt-utl01" {
  count       = 0 # 1=Create, 0=Destroy
  name        = "svr-mgt-utl01"
  description = "Management: Utility Server 01"
  node_name   = var.pve_host_config_01["name"] # Proxmox Node
  clone {
    vm_id     = "901" # Ubuntu 24.04 Cloud-Init image.
    full      = true # Create a full clone, instead of linked clone.
  }
  pool_id     = "Management"
  tags        = ["mgt", "ubuntu"] # List of tags to apply to the VM.
  on_boot     = true
  agent {
    enabled   = true
  }
  startup {
    order     = "1"
  }
  cpu {
    cores     = 2
    type      = "host"  # x86-64-v2-AES.
  }
  memory {
    dedicated = 2048 # 2GB RAM.
  }
  disk {
    datastore_id = "pve-zfs-pool" # Use ZFS pool for storage.
    interface    = "scsi0"
    #iothread     = true # Only valid for VirtIO disks.
    discard      = "on"
    size         = 32
  }
  network_device {
    bridge    = var.vm_config_svr-mgt-utl01["network"] # VLAN aware Linux bridge.
    vlan_id   = var.vm_config_svr-mgt-utl01["vlan_id"]
  }
  initialization {
    datastore_id  = "pve-zfs-pool" # Use ZFS pool for Cloud-Init disk storage.
    ip_config {
      ipv4 {
        address   = var.vm_config_svr-mgt-utl01["ipv4"]
        gateway   = var.vm_config_svr-mgt-utl01["gateway_ip"]
      }
    }
    dns {
      domain      = var.vm_config_svr-mgt-utl01["domain"]
      servers     = ["${var.vm_config_svr-mgt-utl01["dns_servers"]}"]
    }
    user_account {
      username    = var.cloudinit_config["username"]
      password    = var.cloudinit_config["password"]
    }
  }
}

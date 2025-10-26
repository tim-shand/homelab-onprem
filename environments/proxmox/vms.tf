#=============================================================#
# Proxmox: Terraform - VMs
#=============================================================#

module "vm_svr_management" {
  source            = "./modules/vm-ubuntu-general"
  instances         = 1 # 0=Destroy. ${count.index}
  pve_node_config   = var.pve_host_config_01
  vm_details        = {
    name        = "svr-mgt-utl"
    description = "Management: Utility Server"
    pool_id     = "Management"
    tags        = ["mgt", "ubuntu"] # List of tags to apply to the VM.
    cpu         = 2 # CPU cores.
    mem         = 2048 # 2GB RAM.
    disk_gb     = 32 # 32 GB storage.
    vlan_id     = "20" # VLAN ID to use.
    cidr        = "/24" # IP requires CIDR notation.
    subnet      = "10.0.20.0/24" # Network address used for generating IP address.
    ip_start    = "10" # Starting IP address location, multiple instances increment.
    domain      = "svr.tshand.int"
    gateway     = "10.0.20.254"
    dns         = "10.0.20.254"
  }
  cloudinit_config = var.cloudinit_config
}

#======================================================#
# Proxmox: Terraform - Main (Root)
#======================================================#

# Cluster Configuration -------------------------------------------------------#
# Import: `terraform import proxmox_virtual_environment_cluster_options.options cluster`
resource "proxmox_virtual_environment_cluster_options" "cluster_options" {
  #description               = "Homelab: Proxmox VE" # Known Bug: ("Homelab: Proxmox VE"), but now cty.StringVal("Homelab: Proxmox VE\n").
  language                  = "en"
  keyboard                  = "en-us"
  email_from                = "alerts@proxmox.${var.pve_sys_node_domain_dns["domain"]}"
  max_workers               = 5
  mac_prefix                = "BC:24:11:" # Change last bit only, first 6 are for Proxmox.
  next_id = {
    lower = 200
    upper = 9999
  }
  console                   = "html5" # Set default viewer.
}

# Node Domain & DNS ------------------------------------------------------------#
# Import: `terraform import proxmox_virtual_environment_dns.first_node first-node`
resource "proxmox_virtual_environment_dns" "pve_sys_dns_01" {
  node_name = var.pve_host_config_01["name"] # Node Name
  domain    = var.pve_sys_node_domain_dns["domain"] # Domain
  servers = [
    var.pve_sys_node_domain_dns["dns1"], # Primary DNS
    var.pve_sys_node_domain_dns["dns2"] # Secondary DNS
  ]
}

resource "proxmox_virtual_environment_dns" "pve_sys_dns_02" {
  node_name = var.pve_host_config_02["name"] # Node Name
  domain    = var.pve_sys_node_domain_dns["domain"] # Domain
  servers = [
    var.pve_sys_node_domain_dns["dns1"], # Primary DNS
    var.pve_sys_node_domain_dns["dns2"] # Secondary DNS
  ]
}

# Resource Pools --------------------------------------------------------------#
# Import: `terraform import proxmox_virtual_environment_pool.pool-1 pool-1`
resource "proxmox_virtual_environment_pool" "pool_templates" {
  pool_id = "Templates"
  comment = "VM templates."
}

resource "proxmox_virtual_environment_pool" "pool_management" {
  pool_id = "Management"
  comment = "Servers used for management purposes."
}

resource "proxmox_virtual_environment_pool" "pool_production" {
  pool_id = "Production"
  comment = "Production servers."
}

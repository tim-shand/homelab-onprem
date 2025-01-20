### Proxmox: Pools
resource "proxmox_virtual_environment_pool" "pve_pool_mgt" {
  pool_id = "mgt"
  comment = "Management"
}
resource "proxmox_virtual_environment_pool" "pve_pool_k8s" {
  pool_id = "k8s"
  comment = "Kubernetes"
}

### Proxmox: Networking (vNets)
resource "proxmox_virtual_environment_network_linux_bridge" "vmbr_mgt" {
  node_name = var.root_pve_node
  name    = "vmbr10"
  address = "10.0.10.0/24"
  autostart = true
  vlan_aware = true
  comment = "Bridge_10_Management"
}
resource "proxmox_virtual_environment_network_linux_bridge" "vmbr_k8s" {
  node_name = var.root_pve_node
  name    = "vmbr80"
  address = "10.0.80.0/24"
  autostart = true
  vlan_aware = true
  comment = "Bridge_80_Kubernetes"
}

### Proxmox: Virtual Machines
module "fw_pfsense" {
  instances = 1
  source = "./modules/fw_pfsense"
  macaddress = "BC:24:11:45:8B:C8"
  node_name = var.root_pve_node
  hostname_prefix = "inf-mgt-fwl"
  vmid_start = 110 # Receives appended third digit based on count.
  pool_id = proxmox_virtual_environment_pool.pve_pool_mgt.id
  tags = ["mgt","firewall"]
  vnet1 = "vmbr0"
  vnet2 = proxmox_virtual_environment_network_linux_bridge.vmbr_mgt.name
  vnet3 = proxmox_virtual_environment_network_linux_bridge.vmbr_k8s.name
}

module "k8s_master" {
  instances = 1 # Instances to create, use '0' to remove all.
  source = "./modules/vm_k8s_master"
  node_name = var.root_pve_node
  hostname_prefix = "k8s-svr-mas"
  vmid_start = 810 # Receives appended third digit based on count.
  pool_id = proxmox_virtual_environment_pool.pve_pool_k8s.id
  tags = ["k8s","master"]
  vnet = proxmox_virtual_environment_network_linux_bridge.vmbr_k8s.name
  ipv4_address = "10.0.80.1" # Receives appended host address based on count.
  ipv4_gateway = "10.0.80.1"
  domain = "lab.int"
  dns_servers = "10.0.80.1" # Example: "10.0.0.1","8.8.8.8"
  auth_username = var.root_ci_user
  auth_password = var.root_ci_password
  auth_keys = var.root_ssh_keys
  depends_on = [
    module.fw_pfsense
  ]
}

module "k8s_worker" {
  instances = 2 # Instances to create, use '0' to remove all.
  source = "./modules/vm_k8s_worker"
  node_name = var.root_pve_node
  hostname_prefix = "k8s-svr-wkr"
  vmid_start = 820 # Receives appended third digit based on count.
  pool_id = proxmox_virtual_environment_pool.pve_pool_k8s.id
  tags = ["k8s","worker"]
  vnet = proxmox_virtual_environment_network_linux_bridge.vmbr_k8s.name
  ipv4_address = "10.0.80.2" # Receives appended host address based on count.
  ipv4_gateway = "10.0.80.1"
  domain = "lab.int"
  dns_servers = "10.0.80.1" # Example: "10.0.0.1","8.8.8.8"
  auth_username = var.root_ci_user
  auth_password = var.root_ci_password
  auth_keys = var.root_ssh_keys
  depends_on = [
    module.k8s_master
  ]
}

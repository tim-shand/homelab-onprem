#======================================================#
# Proxmox: Terraform - Variable Values File (Example)
#======================================================#

#----- Proxmox: Host Configuration -----#
pve_auth_api_token = "terraform@token01!api01=12345678-abcd-1234-abcd-1234567890"

pve_host_config_01 = {
  name    = "pve-host-01"
  url     = "https://10.0.0.1:8006/api2/json"
  usb_nic = "enx001"
}

pve_host_config_02 = {
  name    = "pve-host-02"
  url     = "https://10.0.0.2:8006/api2/json"
  usb_nic = "enx002"
}

pve_sys_node_domain_dns = {
  domain    = "mgt.homelab.int"
  dns1      = "10.0.0.254" # OPNsense router.
  #dns2      = "10.0.0.254" # Edge router (ISP).
}

#----- VM: Cloud-Init Configuration -----#
cloudinit_config = {
  username  = "linuxadmin" # Default: VM username.
  password  = "change_me-123!" # Default: VM password
  domain    = "svr.homelab.int" # Default: Domain.
  gateway   = "10.0.50.254" # Should match VLAN gateway.
  ssh_keys  = "" # SSH keys used for SSH authentication to VM.
}

#----- VM: Management Configuration -----#
vm_config_svr-mgt-utl01 = {
  network       = "vmbr1"
  domain        = "svr.homelab.int"
  ipv4          = "10.0.50.10/24"
  gateway_ip    = "10.0.50.254"
  dns_servers   = "10.0.50.254"
  vlan_id       = "50"
}

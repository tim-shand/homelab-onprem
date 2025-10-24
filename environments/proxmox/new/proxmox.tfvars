#======================================================#
# Proxmox: Terraform - Variable Values File (Root)
#======================================================#

#----- Proxmox: Host Configuration -----#
pve_auth_api_token = "svc-pve-terraform@pve!api01=b7fc9f30-03be-4afb-902b-a27cb0d0a72b"

pve_host_config_01 = {
  name    = "inf-hvr-pve01"
  url     = "https://10.0.10.10:8006/api2/json"
  usb_nic = "enx00e04c424a71"
}

pve_host_config_02 = {
  name    = "inf-hvr-pve02"
  url     = "https://10.0.10.11:8006/api2/json"
  usb_nic = "enx00e04c424a99"
}

pve_sys_node_domain_dns = {
  domain    = "mgt.tshand.int"
  dns1      = "10.0.10.254" # OPNsense router.
  dns2      = "10.0.0.254" # Edge router (ISP).
}

#----- VM: Cloud-Init Configuration -----#
cloudinit_config = {
  username  = "linuxadmin" # Default: VM username.
  password  = "change_me-123!" # Default: VM password
  domain    = "svr.tshand.int" # Default: Domain.
  gateway   = "10.0.20.254" # Should match VLAN.
  #ssh_keys  = "" # SSH keys used for SSH authentication to VM.
}

#----- VM: Management Configuration -----#
vm_config_svr-mgt-utl01 = {
  network       = "vmbr1"
  domain        = "svr.tshand.int"
  ipv4          = "10.0.20.10/24"
  gateway_ip    = "10.0.20.254"
  dns_servers   = "10.0.20.254"
  vlan_id       = "20"
}

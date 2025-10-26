#======================================================#
# Proxmox: Terraform - Variable Values File (Example)
#======================================================#

#----- Proxmox: Host Configuration -----#
pve_auth_api_token = "terraform@token01!api01=12345678-abcd-1234-abcd-1234567890"
pve_auth_ssh_un       = "terraform" # Required for some actions not supported by Proxmox API, creating custom disks (templates).
pve_auth_ssh_keyfile  = "~/.ssh/id_ed25519"

pve_host_config_01 = {
  name    = "pve-host-01"
  url     = "https://10.0.0.1:8006/api2/json"
  pve_nic = "eno1" # On-board NIC.
  usb_nic = "enx001"
  pve_net = "vmbr0" # vmbr0 reserved for PVE hosts.
  vm_net  = "vmbr1" # vmbr1 used for VM VLANs.
}

pve_host_config_02 = {
  name    = "pve-host-02"
  url     = "https://10.0.0.2:8006/api2/json"
  pve_nic = "eno1" # On-board NIC.
  usb_nic = "enx001"
  pve_net = "vmbr0" # vmbr0 reserved for PVE hosts.
  vm_net  = "vmbr1" # vmbr1 used for VM VLANs.
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
  #ssh_keys  = "" # SSH keys used for SSH authentication to VM.
}

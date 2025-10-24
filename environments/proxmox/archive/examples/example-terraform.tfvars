# Proxmox Variables
root_pve_url = "https://10.0.0.100:8006/api2/json"
root_pve_node = "inf-hvr-pve01"
root_pve_api_token = "svc_terraform@pam!tf01=123456789"
root_pve_un = "root"
root_pve_pw = "123456789"
root_ssh_keys = <<-EOT
    ssh-ed25519 123456789 me@my-pc
    EOT
root_ci_user = "localadmin"
root_ci_password = "ChangeMe123"
root_ci_gateway = "10.0.0.1"
root_ci_domain = "lab.int"

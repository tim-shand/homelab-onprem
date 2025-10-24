# Proxmox Variables
variable "root_pve_url" {
    type = string
}
variable "root_pve_node" {
    type = string
}
variable "root_pve_api_token" {
    type = string
}
variable "root_pve_un" {
    type = string
}
variable "root_pve_pw" {
    type = string
}

# Cloud-Init Variables
variable "root_ssh_keys" {
    type = string
}
variable "root_ci_gateway" {
    type = string
}
variable "root_ci_domain" {
    type = string
}
variable "root_ci_user" {
    type = string
}
variable "root_ci_password" {
    type = string
    sensitive = true
}
# Proxmox Prep: Template - Ubuntu Cloud-Init

This bash script will download the latest cloud-init image of Ubuntu Server 24.04LTS.  

**In addtion, it will also:**

- Install the 'qemu-guest-agent' package within the image.
- Set the default root password.
- Expand the file system to 32 GB.
- Create a VM within Proxmox.
- Convert the VM to a template.

## Usage

This script is to be run from the Proxmox VE host itself.

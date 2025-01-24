# Proxmox Prep: Template - Ubuntu Cloud-Init

This bash script will download the latest cloud-init image of Ubuntu Server.  

**In addtion, this script will also:**

- Install the 'qemu-guest-agent' package within the image.
- Set the default root password as defined by variable.
- Expand the file system to 32 GB.
- Create a VM within Proxmox.
- Convert the VM to a template.

## Usage

This script is to be run from the Proxmox VE host itself.

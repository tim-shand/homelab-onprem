#! /bin/bash

#=====================================================#
# Utility: Proxmox Prep - Ubuntu Cloud-Init Template
#=====================================================#

# DESCRIPTION:
# This bash script will download the latest cloud-init image of Ubuntu Server.  
# In addtion, this script will also:
# - Install the 'qemu-guest-agent' package within the cloud-init image.
# - Set the default root password as defined by provided variable.
# - Expand the file system to 32 GB total.
# - Create a VM within Proxmox.
# - Convert the VM to a template.

# NOTE: 
# Requires administrator (sudo) privileges to run.

# USAGE:
# This script is to be run from the Proxmox VE host itself.
# ./scripts/utility/local-setup-linux.sh

#------------------------------------------------#
# VARIABLES
#------------------------------------------------#

required_pkgs="git curl libguestfs-tools" # List of required packages to install on host executing this script.
img_url="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img" # Image source URL.
img_file=$(echo $img_url | sed 's/^.*noble/noble/') # Image name extracted from URL.
tmpdir=/opt/tmpdir-images # Temporary directory for downloaded image file.
dstpath=/var/lib/vz/template/iso # Final destination path for image file.
exp_fs="32G" # String value for desired file system size during expansion.
default_rootpw="changeme123!" # Default root password for VM.
template_id=9000 # Template ID used in Proxmox, must be unique.
template_name="ztmp-ubuntu24-cloudinit" # Template name used in Proxmox.

# Confirmation of variables and user input to approve.
clear
echo "---------------------------------------------------------------------"
echo "This script will action the following:"
echo "  - Update apt repository and install required packages."
echo "  - Create a temporary directory, download Ubuntu cloud-init image."
echo "  - Modify image file (expand file system, set root password)."
echo "  - Create Proxmox VM, convert it to template."
echo
echo "~~~ IMPORTANT NOTE ~~~"
echo "Please review the variables defined in this script BEFORE proceeding."
echo "---------------------------------------------------------------------"
read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

### START ###
# Update apt repositry and install required packages.
echo "INFO: Updating repository and installing required packages..."
apt update -y &&  apt install $required_pkgs -y

# Create temp directory for image storage.
if [ ! -d "$tmpdir" ]; then
    echo "INFO: $tmpdir does not exist. Creating..."
    mkdir $tmpdir
else
    echo "INFO: $tmpdir already exists. Skip."
fi

# Download the current Ubuntu cloud-init disk image.
# Check if image file already present, confirm to re-download/overwrite.
if [ -f "$dstpath/$img_file" ]; then
    echo "WARN: Image file already present."
    echo "Download and overwrite existing file? ('N' skips this section)."
    read -p "Confirm? (Y/N): " ow_image
    if [[ $ow_image == [yY] || $ow_image == [yY][eE][sS] ]]; then
        echo "INFO: Downloading image file: $img_file"
        curl -o $tmpdir/$img_file $img_url
        echo "INFO: Moving image file to destination ($dstpath/)."
        mv $tmpdir/$img_file $dstpath/$img_file
    else
        echo "INFO: Skipping image file download."
    fi
else
    echo "INFO: Downloading image file: $img_file"
    curl -o $tmpdir/$img_file $img_url
    echo "INFO: Moving image file to destination ($dstpath/)."
    mv $tmpdir/$img_file $dstpath/$img_file
fi

# Run provisioning prep tasks.
# Expand file system, install guest agent, set root password.
if [ -f "$dstpath/$img_file" ]; then
    echo "INFO: Image file present. Begin modifications."
    echo "--- Expanding file system ($exp_fs)..."
    qemu-img resize $dstpath/$img_file $exp_fs
    echo "--- Installing 'qemu-guest-agent'..."
    virt-customize -a $dstpath/$img_file --install qemu-guest-agent
    echo "--- Configuring default root password..."
    virt-customize -a $dstpath/$img_file --root-password password:$default_rootpw
    echo "INFO: Customizations complete."
else
    echo "ERROR: Image file is not present. Abort."
    exit 1
fi

# Create VM and convert to template.
if [ -f "$dstpath/$img_file" ]; then
    echo "INFO: Creating inital VM..."
    qm create $template_id --name "$template_name" \
        --ostype l26 \
        --memory 1024 --balloon 0 \
        --agent 1 \
        --bios seabios \
        --boot order=scsi0 \
        --scsihw virtio-scsi-pci \
        --scsi0 local-lvm:0,import-from="$dstpath/$img_file",backup=0,cache=writeback,discard=on \
        --ide2 local-lvm:cloudinit \
        --cpu host --socket 1 --cores 1 \
        --vga virtio \
        --net0 virtio,bridge=vmbr0
    if qm status $template_id | grep -q "status:"; then
        echo "INFO: VM provisioned successfully."
        echo "INFO: Converting to template..."
        qm template $template_id # Convert VM to template.
        echo "INFO: Cleaning up..."
        rm -rf $tmpdir # Cleanup temporary directory.
        echo "----------------------------------------------"
        echo "Proxmox - Ubuntu Cloud-init template complete!"
        echo "----------------------------------------------"
        echo " "
    else
        echo "ERROR: VM failed to provision. Abort."
    fi
else
    echo "ERROR: Image file is not present in destination. Abort."
    exit 1
fi
#!/bin/bash
#
# Create a mount point
mkdir -p /tmp/cloudinit-iso

# Mount the ISO (read-only)
sudo mount -o loop /k8s/kvm/images/cloudinit-cp1.iso /tmp/cloudinit-iso

# List what's on it
ls -la /tmp/cloudinit-iso/

# Check the network-config file
cat /tmp/cloudinit-iso/network-config

# Check the user-data file
cat /tmp/cloudinit-iso/user-data

# Check meta-data
cat /tmp/cloudinit-iso/meta-data

# When done, unmount it
sudo umount /tmp/cloudinit-iso

#!/bin/bash
#
# Set up KVM and virsh on local host
# This setup is for Linux Mint 22 / Ubuntu

BASE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/CONFIG.sh
. "${BASE}/CONFIG.sh"


/bin/echo "---------------------------------------------------------"
/bin/echo "Updating packages and installing KVM/Virsh tools"
/bin/echo "---------------------------------------------------------"
/usr/bin/sudo apt update && sudo apt upgrade -y
/usr/bin/sudo apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    virtinst \
    libosinfo-bin \
    cloud-image-utils \
    genisoimage

/bin/echo "---------------------------------------------------------"
/bin/echo "Configuring groups"
/bin/echo "---------------------------------------------------------"
/usr/bin/sudo /usr/sbin/usermod -aG libvirt "$USER"
/usr/bin/sudo /usr/sbin/usermod -aG kvm "$USER"


/bin/echo "---------------------------------------------------------"
/bin/echo "Starting libvirtd"
/bin/echo "---------------------------------------------------------"
/usr/bin/sudo /usr/bin/systemctl stop libvirtd
/usr/bin/sudo /usr/bin/mkdir -p "${K8S_ROOT}/libvirt/images"
/usr/bin/sudo /usr/bin/chown -R libvirt-qemu:kvm "${K8S_ROOT}/libvirt"
/usr/bin/sudo /usr/bin/chmod 711 "${K8S_ROOT}/libvirt"
/usr/bin/sudo /usr/bin/systemctl enable --now libvirtd


/bin/echo "---------------------------------------------------------"
/bin/echo "Verifying installation:"
/bin/echo "---------------------------------------------------------"
/usr/bin/sg libvirt -c '
/usr/bin/virsh list --all
/usr/bin/virsh pool-info k8s-libvirt
/bin/echo -n "Number of KVM enabled cores(should be > 0): "
/bin/egrep -c "(vmx|svm)" /proc/cpuinfo

/bin/echo "Checking for KVM kernel module: (should be either kvm_intel or kvm_amd): "
/usr/sbin/lsmod | /bin/grep kvm_
'


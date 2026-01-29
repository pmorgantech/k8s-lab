# Root of disk REPO where we keep K8s, KVM, related data
K8S_ROOT=/k8s
export K8S_ROOT

# Set up a network bridge for K8s
NIC=enp5s0
BRIDGE_NAME=lan-br0

export NIC BRIDGE_NAME


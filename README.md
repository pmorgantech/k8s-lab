# Kubernetes Learning

This repository follows my work installing a local multi-vm Kubernetes lab to simulate a production environment for learning and testing. 

## High Level Plan

To experiment with K8s in my home lab, I will:

- Set up storage (LVM/xfs), dir structure for containers, kubernetes, kvm images, etc
- [Create a base image Kubernetes VMs](https://github.com/pmorgantech/k8s-base-images)
- Set up virsh for my K8s installation
- Configure/launch VMs
- Install K8s using kubeadm / ansible

### Storage Notes

I selected XFS as this seems like it will play better than EXT4 with high-churn KVM images and containerd images.

#### Storage Layout

```
/k8s
├── images/                 # Base disk image (to be cloned for kubernetes nodes)
|
├── kvm/                    # VM disks (libvirt)
│   ├── images/             # qcow2/raw disks
│   ├── snapshots/
│   └── templates/
│
├── containerd/             # container runtime storage
│   ├── content/            # image layers
│   ├── io.containerd.snapshotter.v1.overlayfs/
│   └── tmp/
│
├── kubelet/                # kubelet state
│   ├── pods/               # pod volumes, emptyDir, etc
│   ├── plugins/
│   └── plugins_registry/
|
└── logs/                   # optional: node-local logs
    └── pods/
```

### Virsh / KVM notes

I will use Debian 12 for this exercise.  I want to simulate a production environment as closely as possible so these images will be minimal, hardened following CIS benchmark, and be configured similarly to how production hosts would be configured to support K8s, with the exception that they will be self-contained VMs with simplified "hardware" lacking redundancies.

### K8s Notes

I will begin with 1x control plane and 2 worker nodes.  We will use bridged networking so all nodes will be available on the LAN.  I will start with Flannel CNI.

After this works successfully, I will build a second setup with a more production-friendly focus:
- 3x HA control plane
- 2x worker nodes
- Calico CNI

As of this writing, Kubernetes v1.35 is latest.  I will start deliberately with 1.33 to enable performing a few update cycles as part of the learning process.

### Terraform Bootstrapping

To bootstrap the Kubernetes cluster, I will use terraform with a libvirt provider.  This will configure a storage pool, a bridge network, and set up several virtual machines to act as control plane and worker nodes.  Terraform apply and destroy will create and destroy the virtual machines and pool/network, but any further provisioning of Kubernetes itself will be left to Ansible.

Some notes on the assumptions made here:

Although I want to simulate a production environment, there are inevitably a few compromises to make here for the sake of simplicity and expediency.  The purpose of this lab is to learn about running workloads on and troubleshooting Kubernetes,  not to create complex routing scenarios for a home network.

- Libvirt will define a bridge network that will allow hosts to have IPs on our LAN so the cluster is easily expanded to other LAN hosts and reachable on other hosts on the local lan without extra effort.
- We are statically addressing and naming the cluster inventory.  We have only a few hosts, and I wanted to ensure they are consistently named and reachable on my network without having to maintain dhcp or dns locally for them.

Toward this end, I created a bridge named "lan-br0" and gave it the IP of my desktop workstation.  I enslaved my ethernet interface to this bridge.

#### TFVars

To create the cluster, a local tfvars is necessary.  There is an example in the Terraform env directories.

## Single Control Plane cluster

To install this cluster:

```bash
cd terraform/env/single-cp
terraform init
terraform validate
terraform plan
terraform apply
```

This will create the VMs and run the playbook to install Kubernetes onto them.

A few last steps:  You may wish to copy the control plane /etc/kubernetes/admin.config to ~/.kube/config on your workstation to enable running kubectl locally.
Create local hosts entries for your VMs, and a ~/.ssh/config map for them similar to:

```
Host cp1 worker1 worker2
  IdentityFile ~/.ssh/id_ed25519
  User debian
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
```


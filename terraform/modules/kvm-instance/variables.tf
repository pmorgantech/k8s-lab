variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  default     = "k8s-lab"
}

variable "network_bridge" {
  description = "Name of the network bridge to use"
  default     = "virbr0"
}

variable "dns_servers" {
  description = "List of DNS server ip addresses"
  type = list(string)
  default = [ "8.8.8.8", "1.1.1.1" ]
}

variable "domain" {
  description = "Domain name to be used for kubernetes hosts"
  type = string
  default = "lab.local"
}

variable "default_gateway" {
  description = "IPv4 gateway"
  type = string
}

variable "nodes" {
  description = "Map of nodes in this cluster"
  type = map(object({
    role   = string
    memory = number
    vcpus  = number
    mac    = string
    ipaddr = string
  }))

  validation {
    condition = alltrue([
      for n in values(var.nodes) :
      contains(["control-plane", "worker"], n.role)
    ])
    error_message = "Node role must be one of 'control-plane' or 'worker'"
  }
}

variable "base_os_version" {
  description = "Name of base OS version"
  type        = string
  default     = "debian12"
}

variable "base_image_name" {
  description = "Name of base OS image file"
  type        = string
  default     = "debian12-k8s-base.qcow2"
}

variable "storage_pool_name" {
  description = "Name of storage pool to be used by cluster"
  type        = string
  default     = "k8s"
}

variable "live_image_path" {
  description = "Location of KVM images"
  type        = string
  default     = "/k8s/kvm/images" # Where live VM images live
}

variable "base_image_path" {
  description = "Location of KVM base images"
  type        = string
  default     = "/k8s/images" # Where the base images live
}

variable "ha_required" {
  description = "Whether or not this cluster is expected to be HA"
  type        = bool
  default     = false
}


# Sanity checks
locals {
  control_planes = [
    for n in values(var.nodes) : n if n.role == "control-plane"
  ]
  control_planes_count = length(local.control_planes)
  workers = [
    for n in values(var.nodes) : n if n.role == "worker"
  ]
  workers_count = length(local.workers)

  macs = [for n in values(var.nodes) : n.mac]

  ha_valid          = !var.ha_required || local.control_planes_count >= 3
  has_worker        = local.workers_count >= 1
  has_control_plane = local.control_planes_count >= 1
}


resource "null_resource" "ha_validation" {
  count = local.ha_valid ? 0 : 1
  provisioner "local-exec" {
    command = <<EOT
echo "ERROR: HA clusters require at least 3 control-plane nodes" >&2
exit 1
EOT
  }
}

resource "null_resource" "control_plane_validation" {
  count = local.has_control_plane ? 0 : 1
  provisioner "local-exec" {
    command = <<EOT
echo "ERROR: Cluster must have at least one control_plane node" >&2
exit 1
EOT
  }
}

resource "null_resource" "worker_validation" {
  count = local.has_worker ? 0 : 1
  provisioner "local-exec" {
    command = <<EOT
echo "ERROR: Cluster must have at least one worker node" >&2
exit 1
EOT
  }
}

resource "null_resource" "mac_validation" {
  count = length(distinct(local.macs)) == length(local.macs) ? 0 : 1
  provisioner "local-exec" {
    command = <<EOT
echo "ERROR: MAC addresses must be unique" >&2
exit 1
EOT
  }
}
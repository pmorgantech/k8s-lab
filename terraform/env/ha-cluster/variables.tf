# Variables to pass through to kvm-instance module

variable "cluster_name" {
  type = string
}

variable "network_bridge" {
  type = string
}

variable "nodes" {
  type = map(object({
    role   = string # control-plane | worker
    memory = number # MB
    vcpus  = number
    mac    = string
    ipaddr = string
  }))
}

variable "dns_servers" {
  type = list(string)
}

variable "default_gateway" {
  type = string
}

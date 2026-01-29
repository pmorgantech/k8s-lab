# Provision a set of nodes according to var.nodes configuration

# ------------------------------------------------------
# Cloudinit
# ------------------------------------------------------
data "template_file" "node_userdata" {
  for_each = var.nodes
    template = file("${path.module}/cloudinit/common.yaml")
    vars = {
      hostname = each.key
      domain = var.domain
    }
}

data "template_file" "network_config" {
  for_each = var.nodes
    template = file("${path.module}/cloudinit/network.cfg")
    vars = {
      static_ip = each.value.ipaddr
      gateway = var.default_gateway
      dns_list = jsonencode(var.dns_servers)
      #mac = each.value.mac
    }
}

resource "libvirt_cloudinit_disk" "node_init" {
  for_each = var.nodes
    name      = "cloudinit-${each.key}.iso"
    pool  = libvirt_pool.cluster.name

    network_config = data.template_file.network_config[each.key].rendered
    user_data = data.template_file.node_userdata[each.key].rendered
    meta_data = <<-EOT
instance-id: ${each.key}
local-hostname: "${each.key}.${var.domain}"
EOT
}


# ------------------------------------------------------
# Storage
# ------------------------------------------------------

resource "libvirt_pool" "cluster" {
  name = var.storage_pool_name
  type = "dir"
  path = var.live_image_path
}

resource "libvirt_volume" "os_volume" {
  name   = var.base_os_version
  pool           = libvirt_pool.cluster.name
  format         = "qcow2"
  source = "${var.base_image_path}/${var.base_image_name}"
}

# volume to attach to the control-plane domain as main disk
## Create one writable volume per node, using the base OS image as backing
resource "libvirt_volume" "vm" {
  for_each       = var.nodes

  name           = "${each.key}.qcow2"
  base_volume_id = libvirt_volume.os_volume.id
  pool           = libvirt_pool.cluster.name
  format         = "qcow2"
}


# ------------------------------------------------------
# Storage
# ------------------------------------------------------

resource "libvirt_network" "kubernetes_network" {
  name = var.network_bridge
  mode = "bridge"
  bridge = var.network_bridge
}


# ------------------------------------------------------
# Virtual Machine
# ------------------------------------------------------


resource "libvirt_domain" "cluster_nodes" {
  for_each = var.nodes
    name   = each.key
    memory = each.value["memory"]
    vcpu   = each.value["vcpus"]
    disk {
      # use the per-node writable volume created above
      volume_id = libvirt_volume.vm[each.key].id
    }
    cloudinit = libvirt_cloudinit_disk.node_init[each.key].id
    network_interface {
      network_id = libvirt_network.kubernetes_network.id
      hostname = each.key
      addresses = [each.value["ipaddr"]]
      mac = each.value["mac"]
    }
    
    console {
      type        = "pty"
      target_port = "0"
      target_type = "serial"
      #source_path = "/dev/pts/1"
    }
}
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

# volume to attach to the domain as main disk
## Create one writable volume per node, using the base OS image as backing
resource "libvirt_volume" "vm" {
  for_each       = var.nodes

  name           = "${each.key}.qcow2"
  base_volume_id = libvirt_volume.os_volume.id
  pool           = libvirt_pool.cluster.name
  format         = "qcow2"
}

## This will serve as longhorn storage on worker nodes
resource "libvirt_volume" "vm_storage" {
  for_each       = local.worker_nodes

  name           = "${each.key}_longhorn.qcow2"
  pool           = libvirt_pool.cluster.name
  format         = "qcow2"
  size           = 53687091200 # 50GB
}

# ------------------------------------------------------
# Network
# ------------------------------------------------------

resource "libvirt_network" "kubernetes_network" {
  name = var.network_bridge
  mode = "bridge"
  bridge = var.network_bridge
  autostart = true
}


# ------------------------------------------------------
# Virtual Machine
# ------------------------------------------------------


resource "libvirt_domain" "cluster_nodes" {
  for_each = var.nodes
    name   = each.key
    memory = each.value["memory"]
    vcpu   = each.value["vcpus"]

    # Enable host-passthrough to avoid K8s perf issues
    cpu {
      mode = "host-passthrough"
    }
    
    disk {
      # use the per-node writable volume created above
      volume_id = libvirt_volume.vm[each.key].id
    }

    # Additional CSI/Longhorn storage for worker nodes only
    dynamic "disk" {
      for_each = (
        contains(keys(libvirt_volume.vm_storage), each.key)
          ? [libvirt_volume.vm_storage[each.key]]
          : []
      )

      content {
        volume_id = disk.value.id
      }
    }

    cloudinit = libvirt_cloudinit_disk.node_init[each.key].id
    network_interface {
      network_id = libvirt_network.kubernetes_network.id
      hostname = each.key
      # We will set the address within cloudinit
      # Using addresses and mac here implies DHCP
      #addresses = [each.value["ipaddr"]]
      #mac = each.value["mac"]
    }
    
    console {
      type        = "pty"
      target_port = "0"
      target_type = "serial"
      #source_path = "/dev/pts/1"
    }
}


# ------------------------------------------------------
# Write ansible ini file
# ------------------------------------------------------
locals {
  control_plane_nodes = {
    for name, n in var.nodes : name => n
    if n.role == "control-plane"
  }

  worker_nodes = {
    for name, n in var.nodes : name => n
    if n.role == "worker"
  }

  repo_root = abspath("${path.module}/../../../")
}

resource "local_file" "ansible_inventory" {
  depends_on = [
    libvirt_domain.cluster_nodes
  ]
  
  filename = "${local.repo_root}/ansible/inventory/${var.cluster_name}.ini"
  content = templatefile("${path.module}/ansible_inventory.tpl", {
    control_plane_nodes = local.control_plane_nodes,
    worker_nodes = local.worker_nodes,
    cluster_name = var.cluster_name
  })
}

# ------------------------------------------------------
# Ansible runner
# ------------------------------------------------------

# Runs only on changes to inventory or playbook
resource "null_resource" "ansible_bootstrap" {
  depends_on = [
    local_file.ansible_inventory
  ]

  # We need to use sha256(inventory.content) instead of filesha for inventory because
  # it will not have been generated at plan time which is when filesha256 evaluates. 
  triggers = {
    inventory_hash = sha256(local_file.ansible_inventory.content)
    playbook_hash = filesha256("${local.repo_root}/ansible/site.yml")
  }

  provisioner "local-exec" {
    command = <<EOT
cd ${local.repo_root}/ansible
ansible-playbook -i inventory/${var.cluster_name}.ini site.yml
EOT
  }
}

# Where the magic happens

module "cluster" {
  source = "../../modules/kvm-instance"

  cluster_name    = var.cluster_name
  nodes           = var.nodes
  network_bridge  = var.network_bridge
  dns_servers     = var.dns_servers
  default_gateway = var.default_gateway
}

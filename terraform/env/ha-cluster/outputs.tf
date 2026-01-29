output "ansible_inventory_ini" {
  description = "INI-style inventory generated from node definitions"
  value       = module.cluster.ansible_inventory_ini
}
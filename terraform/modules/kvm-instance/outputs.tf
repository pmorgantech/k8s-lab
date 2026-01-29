# Generate an ini-format ansible inventory file
output "ansible_inventory_ini" {
  value = join("\n", concat(
    ["[control_plane]"],
    [
      for name, node in var.nodes :
      name
      if node.role == "control-plane"
    ],
    ["", "[workers]"],
    [
      for name, node in var.nodes :
      name
      if node.role == "worker"
    ],
    ["",""]
  ))
}

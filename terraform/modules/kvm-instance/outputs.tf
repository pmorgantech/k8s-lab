# Generate an ini-format ansible inventory file
output "ansible_inventory_ini" {
  value = join("\n", concat(
    ["[control_plane]"],
    [
      for name, node in var.nodes :
      "${name} ansible_host=${node.ipaddr} ansible_user=${var.login_user}"
      if node.role == "control-plane"
    ],

    ["", "[workers]"],
    [
      for name, node in var.nodes :
      "${name} ansible_host=${node.ipaddr} ansible_user=${var.login_user}"
      if node.role == "worker"
    ],
    ["", ""],
    [
      "[workstation]",
      "localhost",
      "", "",
      "[all:vars]",
      "ansible_python_interpreter=/usr/bin/python3",
      "cluster_name=${var.cluster_name}"
    ]
  ))
}

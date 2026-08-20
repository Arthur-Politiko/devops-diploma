# data "template_file" "master-node-init" {
#   template = file("${path.module}/deploy/master-node-init.yml")
#   vars = {
#     ssh_private_key = file("../vault/id_ed25519")
#     # ssh_public_key = "ubuntu:${file(var.vms_ssh_root_key)}"
#     # internal_master_ip = var.internal_master_ip
#   }
# }

# data "template_file" "worker-node-init" {
#   template = file("${path.module}/deploy/worker-node-init.yml")
#   vars = {
#     ssh_public_key = "ubuntu:${file(var.vms_ssh_public_key)}"
#     # internal_master_ip = var.internal_master_ip
#   }
# }

# locals {
#   user_data_templates = {
#     # master = data.template_file.master-node-init.rendered
#     # worker = data.template_file.worker-node-init.rendered
#     master = file("${path.module}/deploy/master-node-init.yml")
#     worker = file("${path.module}/deploy/worker-node-init.yml")
#   }
# }

locals {
  bastion = one([
    for vm in var.vms : vm
    if vm.vm_role == "bastion"
  ])
}

resource "local_file" "ansible_config" {
  filename = "${path.module}/../ansible/ansible.cfg"
  content = templatefile("${path.module}/templates/ansible.cfg.tpl", {
    bastion_user = local.bastion.user_name,
    bastion_ip = yandex_compute_instance.vms[local.bastion.vm_name].network_interface[0].nat_ip_address
  })
}

locals {
  master = [
    for vm in var.vms : vm
    if vm.vm_role == "master"
  ][0]
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/${var.ansible_inventory_path}"
  content = templatefile("${path.module}/${var.ansible_inventory_template_path}", {
    user_name = local.master.user_name,
    private_key_path = var.ssh_private_key,
    master_ips = {
      for name, vm in yandex_compute_instance.vms :
      name => vm.network_interface[0].ip_address
      if can(regex(".*master.*", name))
    },
    master_private_ip = yandex_compute_instance.vms[local.master.vm_name].network_interface[0].ip_address,
    worker_ips = {
      for name, vm in yandex_compute_instance.vms :
      name => vm.network_interface[0].ip_address
      if can(regex(".*worker.*", name))
    }
  })
}
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
    bastion_ip   = yandex_compute_instance.vms[local.bastion.vm_name].network_interface[0].nat_ip_address
  })
}

locals {
  admin = [
    for vm in yandex_compute_instance.vms : 
    {
      name = vm.name,
      ip   = vm.network_interface[0].ip_address,
      user_name = [for v in var.vms : v.user_name if v.vm_name == vm.name][0] 
    }
    if can(regex(".*admin.*", vm.name))
  ]
  masters = [
    for vm in yandex_compute_instance.vms :
    {
      name = vm.name,
      ip   = vm.network_interface[0].ip_address,
      user_name = [for v in var.vms : v.user_name if v.vm_name == vm.name][0] 
    }
    if can(regex(".*master.*", vm.name))
  ]
  workers = [
    for vm in yandex_compute_instance.vms :
    {
      name = vm.name,
      ip   = vm.network_interface[0].ip_address,
      user_name = [for v in var.vms : v.user_name if v.vm_name == vm.name][0] 
    }
    if can(regex(".*worker.*", vm.name))
  ]
  nat = [
    for vm in yandex_compute_instance.vms :
    {
      name      = vm.name,
      ip        = vm.network_interface[0].ip_address,
      user_name = [for v in var.vms : v.user_name if v.vm_name == vm.name][0]
    }
    if vm.name == "nat"
  ]
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/${var.ansible_inventory_path}"
  content = templatefile("${path.module}/${var.ansible_inventory_template_path}", {
    user_name        = local.masters[0].user_name,
    private_key_path = var.ssh_private_key,
    master = {
      name = local.masters[0].name,
      ip   = local.masters[0].ip
    },
    master_ips = local.masters,
    worker_ips = local.workers,
    nat_ips    = local.nat,
    admin_ips  = local.admin,
  })
}
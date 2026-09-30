# data "template_file" "public_init" {
#   # template = file("${path.module}/deploy/public-init.yml")
#   vars = {
#     ssh_private_key = file("../vault/id_ed25519")
#     # ssh_public_key = "ubuntu:${file(var.vms_ssh_root_key)}"
#   }
# }

# data "yandex_iam_service_account" "lookup" {
#   name = var.sa_name
# }

# data "metadata" "instance" {
#   for_each = { for vm in var.vms : vm.vm_name => vm }
#   name = each.value.vm_name
#   metadata = {
#     "enable-oslogin" = each.value.metadata["enable-oslogin"]
#     "ssh-keys" = each.value.user_data != "" ? "ubuntu:${file(var.vms_ssh_public_key)}" : ""
#     "user-data" = each.value.user_data != "" ? file("${path.module}/${each.value.user_data}") : ""    
#   }
# }

resource "yandex_compute_instance" "vms" {
  # depends_on = [data.yandex_compute_image.default]

  for_each                  = { for vm in var.vms : vm.vm_name => vm }
  allow_stopping_for_update = true
  name                      = each.value.vm_name
  hostname                  = each.value.vm_name

  platform_id = var.vm_platform_id
  zone        = yandex_vpc_subnet.subnets[each.value.vm_subnet].zone
  resources {
    cores         = var.vm_res_type[each.value.vm_role].cpu           # 
    memory        = var.vm_res_type[each.value.vm_role].ram           #
    core_fraction = var.vm_res_type[each.value.vm_role].core_fraction #
  }
  # service_account_id = each.value.sa_name == "k8s_admin_sa" ? yandex_iam_service_account.k8s_admin_sa.id : null
  # service_account_id = var.sa_id
  # metadata = data.metadata.instance[each.value.vm_name].metadata
  metadata = {
    "enable-oslogin" = each.value.metadata["enable-oslogin"]
    "ssh-keys"       = each.value.metadata["ssh-keys"] != "" ? "${each.value.user_name}:${file(each.value.metadata["ssh-keys"])}" : ""
    "user-data"      = each.value.metadata["user-data"] != "" ? file("${path.module}/${each.value.metadata["user-data"]}") : ""
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_boot_disks[each.value.vm_role].image_id != "" ? var.vm_boot_disks[each.value.vm_role].image_id : data.yandex_compute_image.default.image_id
      size     = var.vm_boot_disks[each.value.vm_role].disk_size # GB
    }
  }
  scheduling_policy {
    preemptible = true #var.default_scheduling_policy_flag
  }
  network_interface {
    subnet_id  = yandex_vpc_subnet.subnets[each.value.vm_subnet].id
    ip_address = each.value.internal_ip != "" ? each.value.internal_ip : null
    nat        = each.value.nat_enable
    # Статический публичный адрес только у NAT-ноды, чтобы внешние ссылки
    # переживали пересборку кластера. Остальные VM получают динамический адрес.
    nat_ip_address = each.value.vm_role == "nat" ? yandex_vpc_address.nat.external_ipv4_address[0].address : null
    # Attach SG from vm definition (NAT uses "public" SG by default).
    security_group_ids = [yandex_vpc_security_group.sg[each.value.vm_security_group].id]
  }
}

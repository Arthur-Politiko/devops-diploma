output "vms_info" {
  #depends_on = [ yandex_compute_instance.vms ]
  description = "Information about all VMs"
  value = {
    for vm_name, vm in yandex_compute_instance.vms : vm_name => {
      internal_ip = vm.network_interface[0].ip_address
      external_ip = vm.network_interface[0].nat_ip_address
      hostname    = vm.hostname
    }
  }
}

# output "vm_group_info" {
#   #depends_on = [ yandex_compute_instance.vms ]
#   description = "Information about all VMs"
#   value = [
#     for vm in yandex_compute_instance_group.asg-web.instances : {
#       internal_ip = vm.network_interface[0].ip_address
#       external_ip = vm.network_interface[0].nat_ip_address
#       fqdn        = vm.fqdn
#     }
#   ]
# }
# output "kubectl_adm" {
#   depends_on = [ yandex_kubernetes_cluster.regional_cluster, yandex_compute_instance.vms["jumphost"], yandex_compute_instance.vms["admin"]  ]
#   description = "Kubectl admin vm "
#   value = "ssh -J ubuntu@${yandex_compute_instance.vms["jumphost"].network_interface[0].nat_ip_address} emagorn@${yandex_compute_instance.vms["admin"].network_interface[0].nat_ip_address}"
# }


# output "kubectl_tun" {
#   depends_on = [ yandex_kubernetes_cluster.regional_cluster, yandex_compute_instance.vms["jumphost"] ]
#   description = "Kubectl config for the cluster"
#   value = "ssh -N -L 6443:${yandex_kubernetes_cluster.regional_cluster.master[0].internal_v4_address}:443 ubuntu@${yandex_compute_instance.vms["jumphost"].network_interface[0].nat_ip_address} -i ../vault/id_ed25519"
# }

output "connection_commands" {
  description = "SSH connection commands"
  value = {
    for vm_name, vm in yandex_compute_instance.vms : vm_name => 
    vm.network_interface[0].nat_ip_address != "" ? 
      "ssh -o ConnectTimeout=8 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${vm.network_interface[0].nat_ip_address} -i ../vault/id_ed25519" : ""
  }
}

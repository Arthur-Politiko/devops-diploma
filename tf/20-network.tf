resource "yandex_vpc_network" "net" {
  name = var.vpc_net_name
}

# resource "yandex_vpc_subnet" "public-sub" {
#   name           = var.vpc_public_name
#   zone           = var.default_zone
#   network_id     = yandex_vpc_network.net.id
#   v4_cidr_blocks = var.public_cidr
# }

# resource "yandex_vpc_subnet" "private-sub" {
#   name           = var.vpc_private_name
#   zone           = var.default_zone
#   network_id     = yandex_vpc_network.net.id
#   v4_cidr_blocks = var.private_cidr
# }

resource "yandex_vpc_subnet" "subnets" {
  depends_on = [yandex_vpc_route_table.rt]
  for_each = { for key, sub in var.subnets : key => sub }
  name           = each.value.name
  zone           = each.value.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = each.value.v4_cidr_blocks
  
  route_table_id = each.value.route_table_name != "" ? yandex_vpc_route_table.rt[each.value.route_table_name].id : null
}
resource "yandex_vpc_route_table" "rt" {
  for_each = var.rt
  name       = each.value.name
  network_id = yandex_vpc_network.net.id
  dynamic "static_route" {
    for_each = each.value.static_routes
    content {
      destination_prefix = static_route.value.destination_prefix
      next_hop_address   = static_route.value.next_hop_address
    }
  }
}
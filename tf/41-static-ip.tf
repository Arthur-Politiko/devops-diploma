# Статический публичный адрес для NAT-ноды.
resource "yandex_vpc_address" "nat" {
  name = "nat-public-ip"

  external_ipv4_address {
    zone_id = var.subnets["public-a"].zone
  }
}







# --------------   OUTPUT --------------- #
output "nat-public-ip" {
  value = yandex_vpc_address.nat.external_ipv4_address[0].address
}

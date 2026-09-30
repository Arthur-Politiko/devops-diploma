# Статический публичный адрес для NAT-ноды.
# Нужен, чтобы внешние ссылки (Grafana, позже тестовое приложение) не менялись
# при пересборке кластера: у прерываемых VM внешний адрес выдаётся заново.
#
# Адрес тарифицируется: ~0,26 ₽/час, пока привязан к работающей машине,
# и ~0,60 ₽/час, когда машина остановлена.
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

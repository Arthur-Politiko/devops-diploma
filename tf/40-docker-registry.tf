resource "yandex_container_registry" "registry" {
  name = var.docker.registry_name
}

resource "yandex_container_repository" "repo" {
  name = "${yandex_container_registry.registry.id}/${var.docker.repo_name}"
}



# --------------   OUTPUT --------------- #
output "registry-id" {
  value = yandex_container_registry.registry.id
}

output "repository-name" {
  value = yandex_container_repository.repo.name
}
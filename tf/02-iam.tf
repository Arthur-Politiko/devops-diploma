# resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
#   service_account_id = var.sa_id
#   description        = "Static access key for s3 access"
# #   output_to_lockbox  {
# #     secret_id             = "<идентификатор_секрета_Lockbox>"
# #     entry_for_access_key  = "<ключ_секрета_для_идентификатора_статического_ключа>"
# #     entry_for_secret_key  = "<ключ_секрета_для_секретного_ключа>"
# #   }
# }

# SSH keys are created and registered at org level by bootstrap/00-bootstrap.sh
# resource "yandex_organizationmanager_user_ssh_key" "ssh_key" {
#   organization_id = var.organization_id
#   subject_id      = var.sa_id
#   data            = "${file(var.ssh_key)}"
#   name            = "vms_ssh_key"
#   expires_at      = "2030-01-01T00:00:00Z"
# }

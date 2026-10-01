resource "yandex_storage_bucket" "bucket" {
  bucket                  = var.bucket.name
  default_storage_class   = var.bucket.storage_class
  disabled_statickey_auth = var.bucket.disabled_statickey_auth
  folder_id               = var.folder_id
  max_size                = var.bucket.max_size
  anonymous_access_flags {
    read        = var.bucket.access_flags.read
    list        = var.bucket.access_flags.list
    config_read = var.bucket.access_flags.config_read
  }
  versioning {
    enabled = var.bucket.versioning
  }
  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       kms_master_key_id = yandex_kms_symmetric_key.key-a.id
  #       sse_algorithm     = var.bucket.sse_algorithm
  #     }
  #   } 
  # }

}

# resource "yandex_storage_object" "object" {
#   bucket = yandex_storage_bucket.bucket.bucket
#   key = var.bucket_object.key
#   source = var.bucket_object.source
# }

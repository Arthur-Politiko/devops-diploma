###cloud vars
variable "sa_key_file" {
  description = "Path SA key file"
  type        = string
  default     = "../vault/diploma-sa-key.json"
  nullable    = true
}

variable "cloud_id" {
  type        = string
}

variable "folder_id" {
  type        = string
}

variable "sa_id" {
  description = "Service account ID for Yandex.Cloud"
  type        = string
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Zone for the VPC network"
}

variable "bucket" {
  description = "Configuration for the storage bucket"
  type        = object({
    access_flags = object({
      read        = optional(bool, true)
      list        = optional(bool, false)
      config_read = optional(bool, false)
    })
    name        = string
    max_size    = optional(number, 1073741824)
    storage_class = optional(string, "STANDARD")
    disabled_statickey_auth = bool
    versioning = bool
    sse_algorithm = optional(string, "aws:kms")
  })
  default = {
    access_flags = {}
    name         = "tfstate-devops-diploma"
    disabled_statickey_auth = false
    versioning = true
  }
}

# variable "kms_key" {
#   description = "key for basket encryption"
#   type        = object({
#     default_algorithm = optional(string, "AES_256")
#     folder_id         = optional(string, null)
#     name              = string
#     rotation_period   = optional(string, null)
#   })
#   default = {
#     name              = "basket-encryption-key"
#   }
# }

# variable "bucket_object" {
#   description = "Configuration for the storage object"
#   type        = object({
#     key          = string
#     source       = string
#     content_type = optional(string, "text/plain")
#   })
#   default = {
#     key          = "index.html"
#     source       = "./static-files/index.html"
#   }
# }
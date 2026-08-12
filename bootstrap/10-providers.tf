terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = ">= 0.170" 
    }
  }
  required_version = "~> 1.13" # версия tf с которой совместим провайдер yandex
}

provider "yandex" {
  cloud_id = var.cloud_id
  folder_id = var.folder_id
  zone = var.default_zone
  service_account_key_file = var.sa_key_file
}


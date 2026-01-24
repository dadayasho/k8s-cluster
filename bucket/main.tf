terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}


provider "yandex" {
  zone = "ru-central1-a" 
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  token     = var.token
}


resource "yandex_storage_bucket" "iam-bucket" {
  bucket    = "<bucket name>"
  folder_id = var.folder_id
}

resource "yandex_iam_service_account" "write_sa" {
  name        = "<Service account name>"
  folder_id   = var.folder_id
}

resource "yandex_iam_service_account_static_access_key" "write_sa_key" {
  service_account_id = yandex_iam_service_account.write_sa.id
}

resource "yandex_resourcemanager_folder_iam_binding" "write_sa" {
  folder_id = var.folder_id
  role      = "storage.uploader"
  members   = ["serviceAccount:${yandex_iam_service_account.write_sa.id}"]
}


output "bucket_name" {
    value = yandex_storage_bucket.iam-bucket.bucket
}

output "sa_access_key" {
  value = yandex_iam_service_account_static_access_key.write_sa_key.access_key
}

output "sa_secret_key" {
  value     = yandex_iam_service_account_static_access_key.write_sa_key.secret_key
  sensitive = true
}
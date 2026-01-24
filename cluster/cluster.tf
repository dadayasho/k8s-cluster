terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"


  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "<Bucket name>"
    region = "ru-central1"
    key    = "states/control-plane/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id = true
  }
  
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

data "yandex_compute_image" "container-optimized-image" {
  family = "container-optimized-image"
}
# -------- VPC --------

resource "yandex_vpc_network" "network-1" {
  name = "<Network name>"
}
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# -------- Control Plane --------
resource "yandex_compute_instance_group" "control-plane" {
  name = "control-plane"
  folder_id = var.folder_id
  service_account_id = "<Service account id>"
  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 4
      cores  = 2
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = data.yandex_compute_image.container-optimized-image.id
        size = 20
      }
    }
    network_interface {
      network_id = yandex_vpc_network.network-1.id
      subnet_ids = [yandex_vpc_subnet.subnet-1.id]
      nat = true
    }
    metadata = {
    #  docker-container-declaration = file("${path.module}/declaration.yaml")
      user-data = file("<Path to config>")
    }
  }
  scale_policy {
    fixed_scale {
      size = 3
    }
  }
  allocation_policy {
    zones = ["ru-central1-a"]
  }
  deploy_policy {
    max_unavailable = 2
    max_creating = 2
    max_expansion = 2
    max_deleting = 2
  }
}

# -------- Worker Plane --------
resource "yandex_compute_instance_group" "worker-plane" {
  name = "worker-plane"
  folder_id = var.folder_id
  service_account_id = "<Service account id>"
  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 4
      cores  = 2
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = data.yandex_compute_image.container-optimized-image.id
        size = 20
      }
    }
    network_interface {
      network_id = yandex_vpc_network.network-1.id
      subnet_ids = [yandex_vpc_subnet.subnet-1.id]
      nat = true
    }
    metadata = {
    #  docker-container-declaration = file("${path.module}/declaration.yaml")
      user-data = file("<Path to config>")
    }
  }
  scale_policy {
    fixed_scale {
      size = 3
    }
  }
  allocation_policy {
    zones = ["ru-central1-a"]
  }
  deploy_policy {
    max_unavailable = 2
    max_creating = 2
    max_expansion = 2
    max_deleting = 2
  }
}

# -------- Jump On VM --------

resource "yandex_vpc_address" "addr" {
  name = "test"
  deletion_protection = "false"
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

resource "yandex_compute_disk" "boot-disk-1" {
  name     = "boot-disk-1"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "20"
  image_id = "fd80tpcdvop5e9qcosnq"
}

resource "yandex_compute_instance" "jump-on" {
  name        = "jump-on"
  hostname    = "jump-on"
  platform_id = "standard-v3"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 100
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-1.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
    nat_ip_address = yandex_vpc_address.addr.external_ipv4_address[0].address
  }
  metadata = {
    user-data = file("<Path to config file>")
    #"${file("conf/meta.txt")}"
  }
  
}

output "ip_address" {
    description = "Static IP"
    value       = yandex_compute_instance.jump-on.network_interface[0].nat_ip_address
}

# -------- Nginx Balancer --------
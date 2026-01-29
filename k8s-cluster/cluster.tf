terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">=1.13"


  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    region = "ru-central1"
    key    = "states/jump-on/terraform.tfstate"
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
  name = "kuber"
}
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_address" "addr" {
  name = "test"
  deletion_protection = "false"
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}
# --------jump-on --------

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
    
    ip_address = "192.168.10.10"
    
  }
  metadata = {
    user-data = file("/vms/config_cloud_jump_on.yaml")
  }
  
}
# -------- Control plane --------
# -------- CP1 --------
resource "yandex_compute_disk" "boot-disk-cp1" {
  name     = "boot-disk-cp1"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "20"
  image_id = "fd80tpcdvop5e9qcosnq"
}

resource "yandex_compute_instance" "cp1-vm" {
  name        = "cp1-vm"
  hostname    = "cp1-vm"
  platform_id = "standard-v3"
  resources {
    cores         = 4
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-cp1.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
    ip_address = "192.168.10.21"
    
  }
  metadata = {
    user-data = file("/vms/config_cloud_control_plane.yaml")
  }
  
}

# -------- CP2 --------
resource "yandex_compute_disk" "boot-disk-cp2" {
  name     = "boot-disk-cp2"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "20"
  image_id = "fd80tpcdvop5e9qcosnq"
}

resource "yandex_compute_instance" "cp2-vm" {
  name        = "cp2-vm"
  hostname    = "cp2-vm"
  platform_id = "standard-v3"
  resources {
    cores         = 4
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-cp2.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
    ip_address = "192.168.10.23"
    
  }
  metadata = {
    user-data = file("/vms/config_cloud_control_plane.yaml")
  }
  
}
# -------- CP3 --------

resource "yandex_compute_disk" "boot-disk-cp3" {
  name     = "boot-disk-cp3"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "20"
  image_id = "fd80tpcdvop5e9qcosnq"
}

resource "yandex_compute_instance" "cp3-vm" {
  name        = "cp3-vm"
  hostname    = "cp3-vm"
  platform_id = "standard-v3"
  resources {
    cores         = 4
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-cp3.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
    ip_address = "192.168.10.25"
    
  }
  metadata = {
    user-data = file("/vms/config_cloud_control_plane.yaml")
  }
  
}
# -------- Worker plane --------
# -------- WP-1 --------
resource "yandex_compute_disk" "boot-disk-wp1" {
  name     = "boot-disk-wp1"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "20"
  image_id = "fd80tpcdvop5e9qcosnq"
}

resource "yandex_compute_instance" "wp1-vm" {
  name        = "wp1-vm"
  hostname    = "wp1-vm"
  platform_id = "standard-v3"
  resources {
    cores         = 4
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-wp1.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
    ip_address = "192.168.10.31"
    
  }
  metadata = {
    user-data = file("/vms/config_cloud_worker_plane.yaml")
  }
  
}
# -------- WP-2 --------
resource "yandex_compute_disk" "boot-disk-wp2" {
  name     = "boot-disk-wp2"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "20"
  image_id = "fd80tpcdvop5e9qcosnq"
}

resource "yandex_compute_instance" "wp2-vm" {
  name        = "wp2-vm"
  hostname    = "wp2-vm"
  platform_id = "standard-v3"
  resources {
    cores         = 4
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-wp2.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
    ip_address = "192.168.10.33"
    
  }
  metadata = {
    user-data = file("/vms/config_cloud_worker_plane.yaml")
  }
  
}
# -------- WP-3 --------
resource "yandex_compute_disk" "boot-disk-wp3" {
  name     = "boot-disk-wp3"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "20"
  image_id = "fd80tpcdvop5e9qcosnq"
}

resource "yandex_compute_instance" "wp3-vm" {
  name        = "wp3-vm"
  hostname    = "wp3-vm"
  platform_id = "standard-v3"
  resources {
    cores         = 4
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-wp3.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
    ip_address = "192.168.10.35"
    
  }
  metadata = {
    user-data = file("/vms/config_cloud_worker_plane.yaml")
  }
  
}

output "ip_address" {
    description = "Static IP"
    value       = yandex_compute_instance.jump-on.network_interface[0].nat_ip_address
}

output "ip_address-cp-1" {
    description = "IP CP-1"
    value       = yandex_compute_instance.cp1-vm.network_interface[0].ip_address
}
output "ip_address-cp-2" {
    description = "IP CP-2"
    value       = yandex_compute_instance.cp2-vm.network_interface[0].ip_address
}
output "ip_address-cp-3" {
    description = "IP CP-3"
    value       = yandex_compute_instance.cp3-vm.network_interface[0].ip_address
}

output "ip_address-wp-1" {
    description = "IP WP-1"
    value       = yandex_compute_instance.wp1-vm.network_interface[0].ip_address
}
output "ip_address-wp-2" {
    description = "IP wP-2"
    value       = yandex_compute_instance.wp2-vm.network_interface[0].ip_address
}
output "ip_address-wp-3" {
    description = "IP wP-3"
    value       = yandex_compute_instance.wp3-vm.network_interface[0].ip_address
}
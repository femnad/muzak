terraform {
  backend "gcs" {}
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

module "instance-module" {
  source      = "femnad/instance-module/gcp"
  version     = "0.14.1"
  github_user = "femnad"
  ssh_user    = var.ssh_user
  image       = "ubuntu-os-cloud/ubuntu-2204-lts"
}

module "dns-module" {
  source           = "femnad/dns-module/gcp"
  version          = "0.6.1"
  dns_name         = var.dns_name
  instance_ip_addr = module.instance-module.instance_ip_addr
  managed_zone     = var.managed_zone
}

module "firewall-module" {
  version = "0.7.1"
  source  = "femnad/firewall-module/gcp"
  network = module.instance-module.network_name
  self_reachable = {
    "443" = "tcp"
    "22"  = "tcp"
  }
  ip_mask = var.managed_connection ? 29 : 32
  ip_num  = var.managed_connection ? 7 : 1
  providers = {
    google = google
  }
}

resource "google_compute_attached_disk" "navidrome_storage_attachement" {
  disk     = var.volume_name
  instance = module.instance-module.id
}

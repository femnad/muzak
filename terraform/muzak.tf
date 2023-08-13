terraform {
  backend "gcs" {}
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

module "instance-module" {
  source          = "femnad/instance-module/gcp"
  version         = "0.20.0"
  github_user     = "femnad"
  image           = "ubuntu-os-cloud/ubuntu-2204-lts"
  name            = "muzak-instance"
  network_name    = "muzak-network"
  subnetwork_name = "muzak-subnetwork"
  service_account = var.service_account
  providers = {
    google = google
  }
}

module "dns-module" {
  source           = "femnad/dns-module/gcp"
  version          = "0.8.0"
  dns_name         = var.dns_name
  instance_ip_addr = module.instance-module.instance_ip_addr
  managed_zone     = var.managed_zone
  providers = {
    google = google
  }
}

module "firewall-module" {
  version = "0.10.1"
  source  = "femnad/firewall-module/gcp"
  network = module.instance-module.network_name
  prefix  = "muzak"
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
  provider = google
}

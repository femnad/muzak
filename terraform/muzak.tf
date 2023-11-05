terraform {
  backend "gcs" {
    bucket = "tf-fcd-sync"
    prefix = "muzak"
  }
}

data "sops_file" "secrets" {
  source_file = "secret.sops.yml"
}

provider "google" {
  project = data.sops_file.secrets.data["project"]
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = data.sops_file.secrets.data["project"]
  region  = var.region
  zone    = var.zone
}

data "google_compute_image" "ubuntu-latest" {
  project     = "ubuntu-os-cloud"
  family      = "ubuntu-minimal-2204-lts"
  most_recent = true
}

module "instance" {
  source  = "femnad/lazyspot/gcp"
  version = "0.1.0"

  attached_disks = [
    {
      source = data.sops_file.secrets.data["volume_name"]
      name   = "navidrome"
  }]
  github_user     = "femnad"
  image           = data.google_compute_image.ubuntu-latest.self_link
  max_run_seconds = 14400 # 4 hours
  name            = "muzak"
  service_account = data.sops_file.secrets.data["service_account"]

  providers = {
    google-beta = google-beta
  }
}

module "dns" {
  source  = "femnad/dns-module/gcp"
  version = "0.9.0"

  dns_name         = data.sops_file.secrets.data["dns_name"]
  instance_ip_addr = module.instance.instance_ip_addr
  managed_zone     = data.sops_file.secrets.data["managed_zone"]

  providers = {
    google = google
  }
}

module "firewall" {
  source  = "femnad/firewall-module/gcp"
  version = "0.11.0"

  ip_mask = var.managed_connection ? 29 : 32
  ip_num  = var.managed_connection ? 7 : 1
  network = module.instance.network_name
  prefix  = "muzak"
  self_reachable = {
    "443" = "tcp"
    "22"  = "tcp"
  }
  world_reachable = var.allow_https_access ? { port_map = {
    "443" = "tcp"
    }
  } : null

  providers = {
    google = google
  }
}

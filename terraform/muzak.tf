terraform {
  backend "gcs" {
    bucket = "tf-fcd-sync"
    prefix = "terraform/muzak"
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

data "google_compute_image" "debian-latest" {
  project     = "debian-cloud"
  family      = "debian-12"
  most_recent = true
}

module "instance" {
  source  = "femnad/instance-module/gcp"
  version = "0.23.2"

  attached_disks = [
    {
      source = data.sops_file.secrets.data["volume_name"]
      name   = "navidrome"
  }]
  github_user     = "femnad"
  image           = data.google_compute_image.debian-latest.self_link
  name            = "muzak-instance"
  service_account = data.sops_file.secrets.data["service_account"]

  providers = {
    google = google
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
  version = "0.11.0"
  source  = "femnad/firewall-module/gcp"

  network = module.instance.network_name
  ip_mask = var.managed_connection ? 29 : 32
  ip_num  = var.managed_connection ? 7 : 1
  prefix  = "muzak"
  self_reachable = {
    "443" = "tcp"
    "22"  = "tcp"
  }
  world_reachable = !var.needs_cert ? null : {
    port_map = {
      "443" = "tcp"
    }
  }

  providers = {
    google = google
  }
}

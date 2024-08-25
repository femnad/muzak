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

module "instance" {
  source  = "femnad/lazyspot/gcp"
  version = "0.6.5"

  disks = [
    {
      source = data.sops_file.secrets.data["volume_name"]
      name   = "navidrome"
  }]
  dns = {
    name = data.sops_file.secrets.data["dns_name"]
    zone = data.sops_file.secrets.data["managed_zone"]
  }
  firewall = {
    other = var.allow_https_access ? {
      "0.0.0.0/0" : {
        "tcp" = ["443"]
      }
    } : null
    self = {
      allow = {
        "tcp" = ["22", "443"]
      }
      ip_mask = var.managed_connection ? 29 : 32
      ip_num  = var.managed_connection ? 7 : 1
    }
  }
  github_user     = "femnad"
  max_run_seconds = 14400 # 4 hours
  name            = "muzak"
  service_account = data.sops_file.secrets.data["service_account"]
}

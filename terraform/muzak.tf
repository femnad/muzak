terraform {
  backend "gcs" {}
}

module "instance-module" {
  source      = "femnad/instance-module/gcp"
  version     = "0.12.0"
  github_user = "femnad"
  project     = "foolproj"
  ssh_user    = var.ssh_user
  image       = "ubuntu-os-cloud/ubuntu-2204-lts"
}

module "dns-module" {
  source           = "femnad/dns-module/gcp"
  version          = "0.4.0"
  dns_name         = var.dns_name
  instance_ip_addr = module.instance-module.instance_ip_addr
  managed_zone     = var.managed_zone
  project          = var.project
}

module "firewall-module" {
  version = "0.5.0"
  source  = "femnad/firewall-module/gcp"
  project = var.project
  network = module.instance-module.network_name
  self_reachable = {
    "443" = "tcp"
    "22" = "tcp"
  }
  world_reachable = {
  }
  ip_mask = var.managed_connection ? 29 : 32
  ip_num  = var.managed_connection ? 7 : 1
}

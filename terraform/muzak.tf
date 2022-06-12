terraform {
  backend "gcs" {}
}

module "instance-module" {
  source      = "femnad/instance-module/gcp"
  version     = "0.7.7"
  github_user = "femnad"
  project     = "foolproj"
  ssh_user    = var.ssh_user
}

module "dns-module" {
  source           = "femnad/dns-module/gcp"
  dns_name         = var.dns_name
  instance_ip_addr = module.instance-module.instance_ip_addr
  managed_zone     = var.managed_zone
  project          = var.project
}

module "firewall-module" {
  version = "0.2.5"
  source  = "femnad/firewall-module/gcp"
  project = var.project
  network = module.instance-module.network_name
  self_reachable = {
    "443" = "tcp"
  }
  world_reachable = {
    "80" = "tcp"
  }
}

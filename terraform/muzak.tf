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

resource "local_file" "butane" {
  filename        = "muzak.bu"
  file_permission = "0644"
  content = templatefile("muzak.bu.tpl", {
    base_mount_point      = var.base_mount_point
    bucket                = data.sops_file.secrets.data["bucket"]
    email                 = data.sops_file.secrets.data["email"]
    host                  = data.sops_file.secrets.data["host"]
    gcsfuse_image         = local.gcsfuse_image
    music_mount_point     = var.music_mount_point
    navidrome_image       = local.navidrome_image
    navidrome_mount_point = var.navidrome_mount_point
    tag                   = var.gcsfuse_tag
  })
}

data "local_file" "butane" {
  filename   = "muzak.bu"
  depends_on = [local_file.butane]
}

resource "null_resource" "ignition" {
  provisioner "local-exec" {
    command = "butane muzak.bu -o muzak.ign"
  }
  triggers = {
    butane-content = local_file.butane.id
  }
}

data "local_file" "ignition" {
  filename   = "muzak.ign"
  depends_on = [null_resource.ignition]
}

locals {
  gcsfuse_dockerfile   = "image/Dockerfile.gcsfuse"
  gcsfuse_name         = "femnad/gcsfuse"
  gcsfuse_image        = "${local.gcsfuse_name}:${var.gcsfuse_tag}"
  gcsfuse_qualified    = "registry-1.docker.io/${local.gcsfuse_image}"
  navidrome_dockerfile = "image/Dockerfile.navidrome"
  navidrome_name       = "femnad/navidrome"
  navidrome_image      = "${local.navidrome_name}:${var.navidrome_tag}"
  navidrome_qualified  = "registry-1.docker.io/${local.navidrome_image}"
}

data "google_compute_image" "fedora-coreas-latest" {
  project     = "fedora-coreos-cloud"
  family      = "fedora-coreos-stable"
  most_recent = true
}

resource "docker_image" "gcsfuse" {
  name = local.gcsfuse_qualified
  build {
    context    = "."
    dockerfile = local.gcsfuse_dockerfile
    tag        = [local.gcsfuse_image]
  }

  triggers = {
    dir_sha1 = sha1(filesha1(local.gcsfuse_dockerfile))
  }
}

resource "docker_registry_image" "gcsfuse" {
  name          = docker_image.gcsfuse.name
  keep_remotely = true
}

resource "docker_image" "navidrome" {
  name = local.navidrome_qualified
  build {
    context    = "."
    dockerfile = local.navidrome_dockerfile
    tag        = [local.navidrome_image]
  }

  triggers = {
    dir_sha1 = sha1(filesha1(local.navidrome_dockerfile))
  }
}

resource "docker_registry_image" "navidrome" {
  name          = docker_image.navidrome.name
  keep_remotely = true
}

module "instance" {
  source  = "femnad/instance-module/gcp"
  version = "0.23.2"

  attached_disks = [
    {
      source = data.sops_file.secrets.data["volume_name"]
      name   = "navidrome"
  }]
  github_user = "femnad"
  image       = data.google_compute_image.fedora-coreas-latest.self_link
  name        = "muzak-instance"
  metadata = {
    user-data = data.local_file.ignition.content
  }
  service_account = data.sops_file.secrets.data["service_account"]

  depends_on = [docker_registry_image.gcsfuse, docker_registry_image.navidrome, null_resource.ignition]

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

  providers = {
    google = google
  }
}

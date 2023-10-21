terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    google = {
      source  = "hashicorp/google"
      version = "5.2.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
}

provider "docker" {
  registry_auth {
    address     = "registry-1.docker.io"
    config_file = "~/.docker/config.json"
  }
}

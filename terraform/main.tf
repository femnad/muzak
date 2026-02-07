terraform {
  required_version = ">= 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.18.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = ">= 1.3.0"
    }
  }
}

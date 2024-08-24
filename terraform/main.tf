terraform {
  required_version = ">= 0.13"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.39.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = ">= 1.1.0"
    }
  }
}

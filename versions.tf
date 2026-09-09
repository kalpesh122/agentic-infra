terraform {
  required_version = ">= 1.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
  # Remote state: created once by `bootstrap/` (bucket name comes from `just bootstrap`).
  backend "gcs" {}
}

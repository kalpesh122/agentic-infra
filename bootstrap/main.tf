# Creates the remote-state bucket. Run once per project with `gcloud auth application-default login`:
#   cd bootstrap && tofu init && tofu apply -var project_id=<id> -var region=<region>
terraform {
  required_version = ">= 1.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

variable "project_id" { type = string }
variable "region" {
  type    = string
  default = "asia-south1"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "tfstate" {
  name                        = "tfstate-${var.project_id}"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning { enabled = true }
  lifecycle { prevent_destroy = true }
}

output "bucket" { value = google_storage_bucket.tfstate.name }

variable "project_id" { type = string }

locals {
  apis = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each           = toset(local.apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

output "enabled_apis" { value = keys(google_project_service.apis) }

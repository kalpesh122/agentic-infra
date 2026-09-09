variable "project_id" { type = string }
variable "region" { type = string }
variable "name" { type = string }
variable "image" { type = string }
variable "container_port" { type = number }
variable "min_instances" { type = number }
variable "max_instances" { type = number }
variable "allow_unauthenticated" { type = bool }
variable "cloudsql_instance" { type = string }
variable "env_vars" { type = map(string) }
variable "secret_env_vars" {
  description = "secret_id → ENV_VAR_NAME"
  type        = map(string)
}
variable "labels" { type = map(string) }

resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "${var.name}-run"
  display_name = "Cloud Run runtime for ${var.name}"
}

resource "google_project_iam_member" "runtime_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_secret_manager_secret_iam_member" "runtime_secrets" {
  for_each  = var.secret_env_vars
  project   = var.project_id
  secret_id = each.key
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_cloud_run_v2_service" "svc" {
  project  = var.project_id
  name     = var.name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"
  labels   = var.labels

  template {
    service_account = google_service_account.runtime.email
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    volumes {
      name = "cloudsql"
      cloud_sql_instance { instances = [var.cloudsql_instance] }
    }
    containers {
      image = var.image
      ports { container_port = var.container_port }
      resources {
        limits            = { cpu = "1", memory = "512Mi" }
        cpu_idle          = true
        startup_cpu_boost = true
      }
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
      dynamic "env" {
        for_each = var.secret_env_vars
        content {
          name = env.value
          value_source {
            secret_key_ref {
              secret  = env.key
              version = "latest"
            }
          }
        }
      }
      startup_probe {
        http_get { path = "/health" }
        initial_delay_seconds = 2
        period_seconds        = 3
        failure_threshold     = 10
      }
      liveness_probe {
        http_get { path = "/health" }
        period_seconds = 30
      }
    }
  }

  lifecycle {
    # CI deploys new images with gcloud; Terraform must not roll them back on the next apply.
    ignore_changes = [template[0].containers[0].image, client, client_version]
  }
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  count    = var.allow_unauthenticated ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.svc.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "url" { value = google_cloud_run_v2_service.svc.uri }
output "service_name" { value = google_cloud_run_v2_service.svc.name }
output "service_account_email" { value = google_service_account.runtime.email }

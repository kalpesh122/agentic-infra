variable "project_id" { type = string }
variable "region" { type = string }
variable "name" { type = string }
variable "tier" { type = string }
variable "environment" { type = string }
variable "labels" { type = map(string) }

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "google_sql_database_instance" "pg" {
  project             = var.project_id
  name                = "${var.name}-pg"
  region              = var.region
  database_version    = "POSTGRES_17"
  deletion_protection = var.environment == "prod"

  settings {
    tier              = var.tier
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    user_labels       = var.labels
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = var.environment == "prod"
    }
    ip_configuration {
      ipv4_enabled = true # Cloud Run connects over the Cloud SQL connector, not the public IP
    }
    maintenance_window {
      day  = 7
      hour = 3
    }
  }
}

resource "google_sql_database" "app" {
  project  = var.project_id
  instance = google_sql_database_instance.pg.name
  name     = "app"
}

resource "google_sql_user" "app" {
  project  = var.project_id
  instance = google_sql_database_instance.pg.name
  name     = "app"
  password = random_password.db.result
}

resource "google_secret_manager_secret" "db_password" {
  project   = var.project_id
  secret_id = "${var.name}-db-password"
  labels    = var.labels
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db.result
}

output "connection_name" { value = google_sql_database_instance.pg.connection_name }
output "password_secret_id" { value = google_secret_manager_secret.db_password.secret_id }
# Unix-socket URL used by the Cloud SQL connector inside Cloud Run; the password is injected from the secret.
output "database_url_socket" {
  value = "postgres://app@/app?host=/cloudsql/${google_sql_database_instance.pg.connection_name}"
}

variable "project_id" { type = string }
variable "github_repository" { type = string }
variable "environment" { type = string }
variable "deploy_targets" {
  type = object({
    registry_repository = string
    service_name        = string
    service_account     = string
    region              = string
  })
}

data "google_project" "this" { project_id = var.project_id }

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-${var.environment}"
  display_name              = "GitHub Actions (${var.environment})"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC"
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }
  # Only this repository can obtain credentials.
  attribute_condition = "attribute.repository == \"${var.github_repository}\""
  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
}

resource "google_service_account" "deployer" {
  project      = var.project_id
  account_id   = "github-deployer-${var.environment}"
  display_name = "GitHub Actions deployer (${var.environment})"
}

# Let the GitHub identity impersonate the deployer.
resource "google_service_account_iam_member" "wif" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

# Least privilege: push images, deploy the one service, act as its runtime account.
resource "google_artifact_registry_repository_iam_member" "push" {
  project    = var.project_id
  location   = var.deploy_targets.region
  repository = var.deploy_targets.registry_repository
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_cloud_run_v2_service_iam_member" "deploy" {
  project  = var.project_id
  location = var.deploy_targets.region
  name     = var.deploy_targets.service_name
  role     = "roles/run.developer"
  member   = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_service_account_iam_member" "act_as_runtime" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.deploy_targets.service_account}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deployer.email}"
}

output "provider_name" { value = google_iam_workload_identity_pool_provider.github.name }
output "deployer_service_account_email" { value = google_service_account.deployer.email }

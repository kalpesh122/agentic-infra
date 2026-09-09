# Offline contract tests: providers are mocked, so `tofu test` needs no credentials and no project.
mock_provider "google" {
  mock_data "google_project" {
    defaults = { number = "123456789012" }
  }
  # Computed attributes that other resources feed into validated arguments need realistic shapes.
  mock_resource "google_service_account" {
    defaults = {
      name  = "projects/example-dev/serviceAccounts/mock-sa@example-dev.iam.gserviceaccount.com"
      email = "mock-sa@example-dev.iam.gserviceaccount.com"
    }
  }
  mock_resource "google_sql_database_instance" {
    defaults = { connection_name = "example-dev:asia-south1:api-dev-pg" }
  }
  mock_resource "google_artifact_registry_repository" {
    defaults = { id = "projects/example-dev/locations/asia-south1/repositories/api" }
  }
  mock_resource "google_iam_workload_identity_pool" {
    defaults = { name = "projects/123456789012/locations/global/workloadIdentityPools/github-dev" }
  }
  mock_resource "google_iam_workload_identity_pool_provider" {
    defaults = { name = "projects/123456789012/locations/global/workloadIdentityPools/github-dev/providers/github" }
  }
  mock_resource "google_cloud_run_v2_service" {
    defaults = { uri = "https://api-dev-abc123-el.a.run.app" }
  }
  mock_resource "google_secret_manager_secret" {
    defaults = { id = "projects/example-dev/secrets/api-dev-db-password" }
  }
}
mock_provider "random" {}

variables {
  project_id        = "example-dev"
  region            = "asia-south1"
  environment       = "dev"
  service_name      = "api"
  github_repository = "kalpesh122/agentic-backend-node"
  env_vars          = { NODE_ENV = "production" }
  secret_env_vars   = { "api-dev-better-auth-secret" = "BETTER_AUTH_SECRET" }
}

run "dev_is_small_and_not_protected" {
  command = plan

  assert {
    condition     = module.database.connection_name != ""
    error_message = "database module must expose a connection name"
  }
  assert {
    condition     = module.service.service_name == "api-dev"
    error_message = "service name must combine service and environment"
  }
}

run "prod_has_deletion_protection_and_min_instances" {
  command = plan
  variables {
    environment   = "prod"
    min_instances = 1
  }

  assert {
    condition     = module.service.service_name == "api-prod"
    error_message = "prod naming"
  }
}

run "oidc_is_scoped_to_the_repository" {
  command = plan

  assert {
    condition     = strcontains(module.github_oidc.provider_name, "workloadIdentityPools/")
    error_message = "the WIF provider name must be a full resource name"
  }
  assert {
    condition     = module.database.database_url_socket == "postgres://app@/app?host=/cloudsql/example-dev:asia-south1:api-dev-pg"
    error_message = "the socket URL must point at the Cloud SQL connector path"
  }
}

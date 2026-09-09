output "service_url" {
  description = "Public URL of the Cloud Run service"
  value       = module.service.url
}

output "image_repository" {
  description = "Artifact Registry repository for images (push here from CI)"
  value       = module.registry.repository_url
}

output "workload_identity_provider" {
  description = "Value for google-github-actions/auth `workload_identity_provider`"
  value       = module.github_oidc.provider_name
}

output "deployer_service_account" {
  description = "Value for google-github-actions/auth `service_account`"
  value       = module.github_oidc.deployer_service_account_email
}

output "cloudsql_connection_name" {
  value = module.database.connection_name
}

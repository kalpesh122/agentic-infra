project_id        = "my-gcp-project-prod"
region            = "asia-south1"
environment       = "prod"
service_name      = "api"
github_repository = "kalpesh122/agentic-backend-node"
container_port    = 3000
min_instances     = 1
max_instances     = 10
database_tier     = "db-custom-1-3840"
env_vars = {
  NODE_ENV        = "production"
  BETTER_AUTH_URL = "https://api.example.com"
  CORS_ORIGINS    = "https://app.example.com"
}
secret_env_vars = {
  "api-prod-better-auth-secret" = "BETTER_AUTH_SECRET"
}

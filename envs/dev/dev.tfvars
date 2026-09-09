project_id        = "my-gcp-project-dev"
region            = "asia-south1"
environment       = "dev"
service_name      = "api"
github_repository = "kalpesh122/agentic-backend-node"
container_port    = 3000
min_instances     = 0
max_instances     = 2
database_tier     = "db-f1-micro"
env_vars = {
  NODE_ENV        = "production"
  BETTER_AUTH_URL = "https://api-dev.example.com"
  CORS_ORIGINS    = "https://app-dev.example.com"
}
# Secret Manager secret ids you create once (values never live in git) → env var names
secret_env_vars = {
  "api-dev-better-auth-secret" = "BETTER_AUTH_SECRET"
}

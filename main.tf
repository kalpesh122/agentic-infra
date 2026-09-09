locals {
  name   = "${var.service_name}-${var.environment}"
  labels = { environment = var.environment, service = var.service_name, managed_by = "opentofu" }
}

module "project" {
  source     = "./modules/project"
  project_id = var.project_id
}

module "registry" {
  source     = "./modules/registry"
  project_id = var.project_id
  region     = var.region
  name       = var.service_name
  labels     = local.labels
  depends_on = [module.project]
}

module "database" {
  source      = "./modules/database"
  project_id  = var.project_id
  region      = var.region
  name        = local.name
  tier        = var.database_tier
  environment = var.environment
  labels      = local.labels
  depends_on  = [module.project]
}

module "service" {
  source                = "./modules/service"
  project_id            = var.project_id
  region                = var.region
  name                  = local.name
  image                 = var.image != "" ? var.image : "${module.registry.repository_url}/${var.service_name}:bootstrap"
  container_port        = var.container_port
  min_instances         = var.min_instances
  max_instances         = var.max_instances
  allow_unauthenticated = var.allow_unauthenticated
  cloudsql_instance     = module.database.connection_name
  env_vars              = merge(var.env_vars, { DATABASE_URL = module.database.database_url_socket })
  secret_env_vars       = merge(var.secret_env_vars, { (module.database.password_secret_id) = "DATABASE_PASSWORD" })
  labels                = local.labels
  depends_on            = [module.project]
}

module "github_oidc" {
  source            = "./modules/github-oidc"
  project_id        = var.project_id
  github_repository = var.github_repository
  environment       = var.environment
  deploy_targets = {
    registry_repository = module.registry.repository_id
    service_name        = module.service.service_name
    service_account     = module.service.service_account_email
    region              = var.region
  }
  depends_on = [module.project]
}

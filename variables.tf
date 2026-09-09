variable "project_id" {
  description = "GCP project id that hosts this environment"
  type        = string
}

variable "region" {
  description = "Region for Cloud Run, Artifact Registry and Cloud SQL"
  type        = string
  default     = "asia-south1"
}

variable "environment" {
  description = "dev | prod (drives naming and sizing)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod"
  }
}

variable "service_name" {
  description = "Name of the Cloud Run service (and the image repository)"
  type        = string
  default     = "api"
}

variable "image" {
  description = "Full image reference to deploy. Leave empty on the first apply; CI sets it afterwards."
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "owner/repo allowed to deploy through Workload Identity Federation"
  type        = string
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "min_instances" {
  type    = number
  default = 0
}

variable "max_instances" {
  type    = number
  default = 4
}

variable "database_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-f1-micro"
}

variable "allow_unauthenticated" {
  description = "Expose the service publicly (true for APIs behind their own auth)"
  type        = bool
  default     = true
}

variable "env_vars" {
  description = "Plain (non-secret) environment variables for the service"
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Secret names in Secret Manager → env var names. Values are set outside Terraform."
  type        = map(string)
  default     = {}
}

variable "project_id" {
  description = "My GCP project ID"
  type        = string
}

variable "region" {
  description = "Region where I want to deploy (ex: europe-west1)"
  type        = string
  default     = "europe-west1"
}

variable "repo_id" {
  description = "Artifact Registry repo name"
  type        = string
  default     = "order-tracking"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "order-tracking"
}

variable "image" {
  description = "Full image path (Artifact Registry)"
  type        = string
}

variable "spring_profiles" {
  description = "Spring profiles to activate (h2, pg, kafka, etc.)"
  type        = string
  default     = "h2"
}

variable "container_cpu" {
  description = "CPU limit per container (ex: '1' or '1000m')"
  type        = string
  default     = "1"
}

variable "container_memory" {
  description = "Memory limit (ex: '512Mi' or '1Gi')"
  type        = string
  default     = "512Mi"
}

variable "concurrency" {
  description = "Max concurrent requests per instance"
  type        = number
  default     = 40
}

variable "min_instances" {
  type        = number
  default     = 0
}

variable "max_instances" {
  type        = number
  default     = 5
}

variable "public" {
  description = "Expose service publicly (allUsers invoker)"
  type        = bool
  default     = true
}

variable "ingress" {
  description = "Ingress policy"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

# Optional secret to inject .env-like content
variable "create_app_env_secret" {
  type        = bool
  default     = false
}

variable "app_env_content" {
  description = "Content of the optional secret (env data)"
  type        = string
  default     = ""
}

# Cloud Build trigger config
variable "cb_trigger_name" {
  description = "Name of the Cloud Build trigger"
  type        = string
  default     = "order-tracking-cloudbuild"
}

variable "github_owner" {
  description = "GitHub org/user that owns the repo"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "cb_branch_regex" {
  description = "Regex for the branch to trigger on (ex: ^main$)"
  type        = string
  default     = "^main$"
}

variable "cb_region" {
  description = "Region used for Artifact Registry in the build"
  type        = string
  default     = "europe-west1"
}

variable "cb_repo" {
  description = "Artifact Registry repository name used in the build"
  type        = string
  default     = "order-tracking"
}

variable "cb_image" {
  description = "Image name + tag for the build (ex: order-tracking:latest)"
  type        = string
  default     = "order-tracking:latest"
}

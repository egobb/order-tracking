variable "domain" {
  description = "Public domain used to access the app (e.g. tracking.example.com)"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address used for Let's Encrypt certificates"
  type        = string
}

variable "app_image" {
  description = "Docker image of the application"
  type        = string
  default     = "ghcr.io/egobb/order-tracking:latest"
}

variable "db_password" {
  description = "Password for the Postgres app user"
  type        = string
  sensitive   = true
}

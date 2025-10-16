variable "aws_region" {
  type    = string
  default = "us-east-1"
  description = "AWS region where the environment is deployed."
}

variable "image_tag" {
  type    = string
  default = "latest"
  description = "Docker image tag to deploy from ECR (e.g., 'latest', 'v1.0.0')."
}

variable "spring_profile" {
  type    = string
  default = "aws"
  description = "Spring profile to activate inside the container (e.g., aws, dev, prod)."
}

variable "task_cpu" {
  type    = string
  default = "512"
  description = "Fargate CPU units for the ECS task (must match allowed values: 256, 512, 1024, ...)."
}

variable "task_memory" {
  type    = string
  default = "1024"
  description = "Fargate memory in MiB for the ECS task (must match allowed values for the chosen CPU)."
}

variable "desired_count" {
  type    = number
  default = 1
  description = "Number of ECS tasks to run in the service."
}

variable "enable_https" {
  type    = bool
  default = false
  description = "Whether to provision ACM + Route53 resources and expose the service over HTTPS."
}

variable "domain_name" {
  type    = string
  default = "enriquegoberna.com"
  description = "Base domain name for DNS/ACM. Must be a Route53 hosted zone if HTTPS is enabled."
}

variable "subdomain" {
  type    = string
  default = "order-tracking" # => resolves to order-tracking.enriquegoberna.com
  description = "Subdomain for the app. Empty string means using the root domain."
}

variable "container_port" {
  type        = number
  default     = 8080
  description = "Container port exposed by the application. Used in ECS task definition, ALB target group, and SG rules."
}

# -------------------------------------------------------------------
# - Provides sane defaults for a dev environment (latest image, 1 task, HTTP only).
# - Keeps configuration flexible via variables so prod/staging can override them.
# -------------------------------------------------------------------

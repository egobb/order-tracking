variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "spring_profile" {
  type    = string
  default = "default" # "default" (H2) o "pg"
}

variable "task_cpu" {
  type    = string
  default = "512"
}

variable "task_memory" {
  type    = string
  default = "1024"
}

variable "desired_count" {
  type    = number
  default = 1
}

# HTTPS / Dominio (opcional)
variable "enable_https" {
  type    = bool
  default = false
}

variable "domain_name" {
  type    = string
  default = "enriquegoberna.com"
}

variable "subdomain" {
  type    = string
  default = "order-tracking" # => order-tracking.enriquegoberna.com
}

variable "container_port" {
  description = "Puerto en el que escucha el contenedor (usado en el ALB, target group y ECS task)"
  type        = number
  default     = 8080
}
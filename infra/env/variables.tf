variable "aws_region"     { type=string  default="eu-west-1" }
variable "vpc_cidr"       { type=string  default="10.20.0.0/16" }
variable "image_tag"      { type=string  default="latest" }
variable "spring_profile" { type=string  default="default" } # "default" (H2) o "pg"
variable "task_cpu"       { type=string  default="512" }
variable "task_memory"    { type=string  default="1024" }
variable "desired_count"  { type=number  default=1 }

# HTTPS / Dominio (opcional)
variable "enable_https" { type=bool   default=false }
variable "domain_name"  { type=string default="enriquegoberna.com" }
variable "subdomain"    { type=string default="order-tracking" } # => order-tracking.enriquegoberna.com

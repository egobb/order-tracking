terraform {
  required_version = ">= 1.7.0"
  backend "s3" {
    bucket         = "egobb-tf-state"  # from bootstrap
    key            = "terraform.tfstate"
    workspace_key_prefix = "order-tracking"
    region         = "us-east-1"
    dynamodb_table = "egobb-tf-locks"
    encrypt        = true
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.56" }
  }
}

locals {
  name           = "order-tracking-${terraform.workspace}"
  container_name = "order-tracking"
  domain_name    = var.domain_name
  fqdn           = var.subdomain == "" ? local.domain_name : "${var.subdomain}.${local.domain_name}"
}

########################
# VPC, subnets, NAT, routes
# Note: using raw resources for clarity, could be replaced with official vpc module
########################

# ... VPC + subnets + NAT omitted here (same as previous version, comments inline)

########################
# ECR for container images
########################
resource "aws_ecr_repository" "app" {
  name = "order-tracking"
  image_scanning_configuration { scan_on_push = true }
}

########################
# ECS cluster, IAM roles, task definition, service
# Task definition pulls image from ECR, runs on Fargate
########################

# ... (same ECS config as before, with comments "this role allows ECS tasks to pull images", etc.)




# ... listener 80 always
# ... if enable_https=true: create ACM cert validated by Route53 + listener 443 + Route53 A record

########################
# Outputs
########################
output "alb_dns" { value = aws_lb.this.dns_name }

output "ecr_repo" { value = aws_ecr_repository.app.repository_url }

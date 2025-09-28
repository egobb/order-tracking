terraform {
  required_version = ">= 1.7.0"
  backend "s3" {
    bucket         = "egobb-tf-state"  # from bootstrap
    key            = "terraform.tfstate"
    workspace_key_prefix = "order-tracking"
    region         = "eu-west-1"
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

########################
# Application Load Balancer
# HTTP by default, optional HTTPS if enable_https=true
########################
resource "aws_lb" "this" {
  name               = "${local.name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for s in aws_subnet.public : s.id]
}

# ... listener 80 always
# ... if enable_https=true: create ACM cert validated by Route53 + listener 443 + Route53 A record

########################
# Outputs
########################
output "alb_dns" { value = aws_lb.this.dns_name }
output "app_url" {
  value = var.enable_https ? "https://${local.fqdn}" : "http://${aws_lb.this.dns_name}"
}
output "ecr_repo" { value = aws_ecr_repository.app.repository_url }

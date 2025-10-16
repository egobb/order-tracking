terraform {
  required_version = ">= 1.7.0"

  # Remote backend shared by all workspaces.
  # State will be stored under: s3://egobb-tf-state-us-east-1/order-tracking/<workspace>/terraform.tfstate
  backend "s3" {
    bucket               = "egobb-tf-state-us-east-1"   # created in bootstrap
    key                  = "terraform.tfstate"          # base key; workspace_key_prefix adds the workspace path
    workspace_key_prefix = "order-tracking"
    region               = "us-east-1"
    dynamodb_table       = "egobb-tf-locks"
    encrypt              = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56"
    }
  }
}

# Common naming and DNS parameters derived from the active workspace.
# Pattern: resources get a stable prefix 'order-tracking-<workspace>'.
locals {
  name           = "order-tracking-${terraform.workspace}"
  container_name = "order-tracking"

  # DNS is optional: if subdomain is empty we use the apex domain, otherwise "<sub>.<domain>".
  domain_name = var.domain_name
  fqdn        = var.subdomain == "" ? local.domain_name : "${var.subdomain}.${local.domain_name}"
}

# Provider configuration typically lives in a separate file (e.g., provider.tf) so we can
# switch profiles/regions per environment without touching this main. If you need it here,
# define:
#
# provider "aws" {
#   region  = var.aws_region
#   profile = var.aws_profile
# }

# ECS cluster, task definition and service are defined in ecs.tf.
# The service registers tasks into the ALB target group from alb.tf.
# IAM roles (task/execution) come from bootstrap via terraform_remote_state.
# See: ecs.tf, alb.tf, security-groups.tf, datasources-network.tf

# HTTP listener (port 80) is always created in alb.tf.
# If enable_https = true, we provision an ACM certificate validated through Route53,
# add a 443 listener, and create a Route53 A/AAAA record pointing to the ALB.
# See: alb.tf and https.tf (if present).

# Outputs used by CI or to quickly access the service endpoint.
output "alb_dns" {
  value = aws_lb.this.dns_name
}

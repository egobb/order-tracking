data "aws_caller_identity" "this" {}


provider "aws" {
  # Tip: set AWS_PROFILE / AWS_REGION in your shell
  region = var.aws_region
  profile = "sso-egobb" # Optional, if using AWS SSO
}

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56"
    }
  }
  backend "s3" {
    bucket         = "egobb-tf-state-us-east-1"
    key            = "order-tracking/bootstrap/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "egobb-tf-locks"
    encrypt        = true
    profile        = "sso-egobb"
  }
}

########################
# Remote state (S3 + DynamoDB)
########################

resource "aws_s3_bucket" "tf_state" {
  bucket        = var.tf_state_bucket
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = var.tf_lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

########################
# GitHub OIDC + CI roles
########################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # NOTE: keep an eye on GitHub OIDC thumbprint changes.
  thumbprint_list = [
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}

resource "aws_iam_role" "ot_ecs_execution_role" {
  name                 = "ot-ecs-execution-role"
  assume_role_policy   = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags = {
    Project = "order-tracking"
    Scope   = "bootstrap"
  }
}

resource "aws_iam_role" "dev_deployer" {
  name               = "order-tracking-dev-deployer"
  assume_role_policy = data.aws_iam_policy_document.dev_trust.json
}

resource "aws_iam_role" "prod_deployer" {
  name               = "order-tracking-prod-deployer"
  assume_role_policy = data.aws_iam_policy_document.prod_trust.json
  managed_policy_arns = [
    aws_iam_policy.ci_deployer.arn
  ]
}

########################
# ECR for container images
########################
resource "aws_ecr_repository" "order_tracking" {
  name                 = "order-tracking"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "order-tracking"
    Env     = "dev"
  }
}

########################
# Optional: monthly budget
########################

resource "aws_budgets_budget" "monthly_budget" {
  name         = "Portfolio-Monthly-Budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_types {
    include_credit = true
    include_refund = true
    include_tax    = true
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_emails
  }
}

output "tf_state_bucket" {
  value = aws_s3_bucket.tf_state.bucket
}

output "tf_lock_table" {
  value = aws_dynamodb_table.tf_lock.name
}

output "dev_role_arn" {
  value = aws_iam_role.dev_deployer.arn
}

output "prod_role_arn" {
  value = aws_iam_role.prod_deployer.arn
}

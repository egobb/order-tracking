data "aws_caller_identity" "this" {}

provider "aws" {
  # The CLI profile/region are read from env (AWS_PROFILE / AWS_REGION) if present.
  # I set region explicitly for reproducibility, and keep the profile optional for AWS SSO.
  region  = var.aws_region
  profile = "sso-egobb" # Optional: remove if you rely solely on env vars or OIDC.
}

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56"
    }
  }

  # Remote backend for state and locking.
  # Important: Terraform cannot create its own backend resources during init.
  # Ensure the bucket and lock table exist before running `terraform init` with this backend,
  # or initialize locally first and then migrate the state.
  backend "s3" {
    bucket         = "egobb-tf-state-us-east-1"
    key            = "order-tracking/bootstrap/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "egobb-tf-locks"
    encrypt        = true
    profile        = "sso-egobb"
  }
}

# Remote state resources (S3 + DynamoDB).
# These are the canonical state and lock infra used by Terraform runs in this account.
# If you already have them, keep them as data sources instead of resources to avoid drift.
resource "aws_s3_bucket" "tf_state" {
  bucket        = var.tf_state_bucket
  force_destroy = false # Protect the state bucket from accidental deletion.
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled" # State relies on versioning for safe rollbacks.
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # AWS-managed key is fine; switch to KMS CMK if you need tighter control.
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
  billing_mode = "PAY_PER_REQUEST" # No capacity management needed for lock tables.
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# GitHub OIDC provider for GitHub Actions → AWS federation.
# The thumbprint is GitHub's IdP cert fingerprint; monitor for changes over time.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # Keep an eye on GitHub OIDC thumbprint changes; rotate if/when GitHub updates certs.
  thumbprint_list = [
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}

# ECS task execution role (pull images, send logs, fetch secrets for init/log drivers).
# The trust policy comes from the module where ecs_task_assume_role is defined.
resource "aws_iam_role" "ot_ecs_execution_role" {
  name               = "ot-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags = {
    Project = "order-tracking"
    Scope   = "bootstrap"
  }
}

# Role assumed by CI when deploying to DEV (trust policy defined elsewhere).
resource "aws_iam_role" "dev_deployer" {
  name               = "order-tracking-dev-deployer"
  assume_role_policy = data.aws_iam_policy_document.dev_trust.json
}

# Role assumed by CI when deploying to PROD (trust policy defined elsewhere).
# Attaches the CI deployer policy so PROD has the capabilities it needs.
resource "aws_iam_role" "prod_deployer" {
  name               = "order-tracking-prod-deployer"
  assume_role_policy = data.aws_iam_policy_document.prod_trust.json
  managed_policy_arns = [
    aws_iam_policy.ci_deployer.arn
  ]
}

# ECR repository for application container images.
# Tag mutability is kept mutable for now for convenience; consider immutability for release hygiene.
resource "aws_ecr_repository" "order_tracking" {
  name                 = "order-tracking"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true # Enable vulnerability scanning on push.
  }

  tags = {
    Project = "order-tracking"
    Env     = "dev"
  }
}

# Optional monthly cost guardrail.
# Sends forecasted notifications when the projected monthly cost exceeds 80% of the limit.
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

# Useful outputs for wiring and quick checks from the CLI.
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


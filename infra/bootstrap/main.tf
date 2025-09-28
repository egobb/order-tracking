data "aws_caller_identity" "this" {}

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56"
    }
  }
}

provider "aws" {
  # Tip: set AWS_PROFILE / AWS_REGION in your shell
  region = var.aws_region
  profile = "sso-egobb" # Optional, if using AWS SSO
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

# Permissions used by CI (start permissive, later tighten to least-privilege)
data "aws_iam_policy_document" "ci_permissions" {
  statement {
    sid     = "ECR"
    actions = ["ecr:*"]
    resources = ["*"]
  }

  statement {
    sid     = "ECSAndELB"
    actions = [
      "ecs:*",
      "elasticloadbalancing:*",
      "servicediscovery:*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "IAMPassRole"
    actions = ["iam:PassRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid     = "DescribeLogsCW"
    actions = [
      "ec2:Describe*",
      "logs:*",
      "cloudwatch:*",
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = ["*"]
  }

  # For HTTPS automation (ACM + Route53)
  statement {
    sid     = "ACMRoute53"
    actions = [
      "acm:*",
      "route53:*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "TerraformStateBucket"
    effect  = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}"
    ]
  }

  statement {
    sid     = "TerraformLockTable"
    effect  = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.this.account_id}:table/${var.tf_lock_table}"
    ]
  }

  statement {
    sid     = "TerraformStateObjects"
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}/*"
    ]
  }

}

resource "aws_iam_policy" "ci_deployer" {
  name   = "order-tracking-ci-deployer"
  policy = data.aws_iam_policy_document.ci_permissions.json
}

# DEV trust: only deploy/* branches
data "aws_iam_policy_document" "dev_trust" {
  statement {
    sid     = "AllowGitHubOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:egobb/order-tracking:environment:dev",         # <- si el job usa environment: dev
        "repo:egobb/order-tracking:ref:refs/heads/feature/infra-aws",
        "repo:egobb/order-tracking:ref:refs/heads/deploy/*", # <- si disparas desde deploy/*
        "repo:egobb/order-tracking:ref:refs/heads/develop",  # opcional
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dev_deployer" {
  name               = "order-tracking-dev-deployer"
  assume_role_policy = data.aws_iam_policy_document.dev_trust.json
  managed_policy_arns = [
    aws_iam_policy.ci_deployer.arn
  ]
}

# PROD trust: only tags v*
data "aws_iam_policy_document" "prod_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:egobb/order-tracking:ref:refs/tags/v*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "prod_deployer" {
  name               = "order-tracking-prod-deployer"
  assume_role_policy = data.aws_iam_policy_document.prod_trust.json
  managed_policy_arns = [
    aws_iam_policy.ci_deployer.arn
  ]
}

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

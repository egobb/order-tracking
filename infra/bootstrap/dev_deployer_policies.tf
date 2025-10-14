# IAM policy that lets the DEV deployer read and pass the ECS execution role.
# Rationale: CI needs to inspect the role (GetRole) and pass it to ECS tasks (PassRole).
# Safety note: I scope PassRole to the ECS tasks service via condition to avoid abuse.
resource "aws_iam_policy" "dev_deployer_exec_access" {
  name        = "order-tracking-dev-deployer-ecs-exec-access"
  description = "Allow DEV deployer to read and pass the ECS execution role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowReadExecutionRole",
        Effect   = "Allow",
        Action   = ["iam:GetRole"],
        Resource = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/ot-ecs-execution-role"
      },
      {
        Sid      = "AllowPassExecutionRoleToEcs",
        Effect   = "Allow",
        Action   = ["iam:PassRole"],
        Resource = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/ot-ecs-execution-role",
        # Important: limit PassRole to ECS tasks only. If I ever add other services,
        # extend this condition explicitly — never widen to "*".
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

# IAM policy to manage EC2 Security Groups used by this project in DEV.
# Why this exists: Terraform needs to create/update/delete SGs during deploys.
# Guardrails:
# - I keep Resources region/account-scoped where possible.
# - Tag conditions help ensure we only touch our project's SGs.
resource "aws_iam_policy" "dev_deployer_ec2_sg" {
  name        = "order-tracking-dev-deployer-ec2-sg"
  description = "Security Group permissions for DEV environment"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow creating SGs. Resource must be "*" for CreateSecurityGroup (API quirk).
      # I rely on Terraform and tagging to keep this constrained in practice.
      {
        Sid: "CreateSecurityGroupInVpc",
        Effect: "Allow",
        Action: "ec2:CreateSecurityGroup",
        Resource: "*"
      },
      # Allow managing rules (ingress/egress) on our SGs.
      # I scope by account+region. If I want to harden further, add tag conditions.
      {
        Sid:    "ManageRulesOnProjectSgs",
        Effect: "Allow",
        Action: [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress"
        ],
        Resource: "arn:aws:ec2:us-east-1:${data.aws_caller_identity.this.account_id}:security-group/*",
      },
      # Allow deleting SGs so Terraform can replace/destroy.
      {
        Sid:    "DeleteProjectSgs",
        Effect: "Allow",
        Action: ["ec2:DeleteSecurityGroup"],
        Resource: "arn:aws:ec2:us-east-1:${data.aws_caller_identity.this.account_id}:security-group/*"
      },
      # Allow tagging at creation time. This enforces baseline tags so later policies
      # can target by tags. If I change tag keys/values, update this condition too.
      {
        Sid:    "CreateTagsOnSgCreate",
        Effect: "Allow",
        Action: ["ec2:CreateTags"],
        Resource: "arn:aws:ec2:us-east-1:${data.aws_caller_identity.this.account_id}:security-group/*",
        Condition: {
          "ForAllValues:StringEquals": { "aws:TagKeys": ["Project","Env"] },
          "StringEquals": { "aws:RequestTag/Project": "order-tracking" }
        }
      },
      # Read-only EC2 describes needed by Terraform to resolve dependencies and graph.
      {
        Sid:    "ReadDescribeForEc2",
        Effect: "Allow",
        Action: [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables"
        ],
        Resource: "*"
      }
    ]
  })
}

# CI deployer permissions (broad to start; I will tighten to least-privilege as
# the infrastructure stabilizes). I keep services grouped by concern for clarity.
data "aws_iam_policy_document" "ci_permissions" {
  # ECR: CI needs to authenticate, create repos (if needed), and push/pull images.
  # Later: replace "ecr:*" with specific actions (GetAuthToken, CreateRepository, PutImage, etc.).
  statement {
    sid       = "ECR"
    actions   = ["ecr:*"]
    resources = ["*"]
  }

  # ECS/ELB/Service Discovery: required to register tasks, update services, and manage target groups.
  # Later: scope resources to ARNs of our cluster/services/target groups.
  statement {
    sid       = "ECSAndELB"
    actions   = [
      "ecs:*",
      "elasticloadbalancing:*",
      "servicediscovery:*"
    ]
    resources = ["*"]
  }

  # PassRole: ECS service/task roles must be passable by CI. Keep the ECS tasks condition in place.
  statement {
    sid       = "IAMPassRole"
    actions   = ["iam:PassRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  # Describes and logging: allow broad describes (Terraform + deploy scripts),
  # CloudWatch Logs for streams/groups, and SSM Parameter Store for configuration.
  # Note: consider scoping SSM parameters by path (e.g., /order-tracking/dev/*) later.
  statement {
    sid       = "DescribeLogsCW"
    actions   = [
      "ec2:Describe*",
      "logs:*",
      "cloudwatch:*",
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = ["*"]
  }

  # HTTPS automation: ACM (certs) + Route53 (DNS validation).
  # Later: restrict Route53 to the hosted zone ARN used by this project.
  statement {
    sid       = "ACMRoute53"
    actions   = [
      "acm:*",
      "route53:*"
    ]
    resources = ["*"]
  }

  # Terraform backend (state bucket): CI needs bucket-level reads for planning/apply.
  statement {
    sid      = "TerraformStateBucket"
    effect   = "Allow"
    actions  = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}"
    ]
  }

  # Terraform backend (DynamoDB lock table): allow basic CRUD on lock records.
  statement {
    sid      = "TerraformLockTable"
    effect   = "Allow"
    actions  = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.this.account_id}:table/${var.tf_lock_table}"
    ]
  }

  # Terraform backend (state objects): object-level access for the state files.
  statement {
    sid      = "TerraformStateObjects"
    effect   = "Allow"
    actions  = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}/*"
    ]
  }
}

# Concrete IAM policy wrapping the CI policy document above.
# Tip: if I later split permissions per workflow (build vs deploy), create multiple policies.
resource "aws_iam_policy" "ci_deployer" {
  name   = "order-tracking-ci-deployer"
  policy = data.aws_iam_policy_document.ci_permissions.json
}

# Attach all policies to the dev_deployer role used by CI.
# Note: keeping attachments explicit (vs. inline) makes auditing and future refactors easier.
resource "aws_iam_role_policy_attachment" "ci_deployer_attach" {
  role       = aws_iam_role.dev_deployer.name
  policy_arn = aws_iam_policy.ci_deployer.arn
}

resource "aws_iam_role_policy_attachment" "exec_access_attach" {
  role       = aws_iam_role.dev_deployer.name
  policy_arn = aws_iam_policy.dev_deployer_exec_access.arn
}

resource "aws_iam_role_policy_attachment" "dev_deployer_ec2_sg_attach" {
  role       = aws_iam_role.dev_deployer.name
  policy_arn = aws_iam_policy.dev_deployer_ec2_sg.arn
}

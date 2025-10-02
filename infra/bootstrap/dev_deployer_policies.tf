# Política con GetRole + PassRole
resource "aws_iam_policy" "dev_deployer_exec_access" {
  name        = "order-tracking-dev-deployer-ecs-exec-access"
  description = "Permite al deployer DEV leer y pasar el ECS execution role"

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
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Política para gestión de Security Groups (SG) acotada a la VPC del proyecto
resource "aws_iam_policy" "dev_deployer_ec2_sg" {
  name        = "order-tracking-dev-deployer-ec2-sg"
  description = "Permisos de SG para env DEV, acotados a la VPC"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Crear SG en una VPC concreta
      {
        "Sid": "CreateSecurityGroupInVpcWithTags",
        "Effect": "Allow",
        "Action": "ec2:CreateSecurityGroup",
        "Resource": "*",
        Condition: {
          "StringLike": { "aws:ResourceTag/Project": "order-tracking" }
        }
      },
      # Autorizar reglas (ingress/egress) sobre SGs que empiecen por ot-
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
        Condition: {
          "StringLike": { "aws:ResourceTag/Project": "order-tracking" }
        }
      },
      # Borrar SGs del proyecto (Terraform destroy/replace)
      {
        Sid:    "DeleteProjectSgs",
        Effect: "Allow",
        Action: ["ec2:DeleteSecurityGroup"],
        Resource: "arn:aws:ec2:us-east-1:${data.aws_caller_identity.this.account_id}:security-group/*",
        Condition: {
          "StringLike": { "aws:ResourceTag/Project": "order-tracking" }
        }
      },
      # Etiquetar al crear (Terraform)
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
      # Lecturas necesarias
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

# Attach policies
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
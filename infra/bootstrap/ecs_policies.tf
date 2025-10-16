# Trust policy for ECS tasks.
# This is the canonical trust relationship for roles assumed by ECS tasks.
# If tasks fail with "AccessDenied: not authorized to perform sts:AssumeRole",
# check that the task definition references the correct role and that this trust is present.
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Attach AWS's managed execution role policy.
# Why: the execution role needs ECR pull, CloudWatch Logs, and (optionally) Secrets/KMS for
# log drivers and image pulls. I keep this attached instead of inlining to inherit AWS updates.
resource "aws_iam_role_policy_attachment" "ot_ecs_execution_role_managed" {
  role       = aws_iam_role.ot_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Extra permissions for the execution role to read DB credentials from Secrets Manager.
# Note: Secrets use a random suffix. I scope by a fixed prefix path to avoid "*" while
# still matching the generated name. If secret naming changes, update this ARN prefix.
resource "aws_iam_role_policy" "ot_ecs_execution_role_secrets" {
  name = "allow-secretsmanager-get"
  role = aws_iam_role.ot_ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "SecretsRead",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = [
          # Postgres secret prefix (random suffix handled with wildcard).
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.this.account_id}:secret:ot/rds/postgres-*"
        ]
      }
    ]
  })
}

# Task role permissions for MSK Serverless using IAM auth.
# Why: the *application* (not the execution role) needs Kafka actions at runtime.
# Future hardening:
# - Scope Resource to the cluster/topic/group ARNs (see notes below).
# - Split read vs write roles if I later separate consumers/producers.
resource "aws_iam_role_policy" "task_kafka_iam" {
  name = "allow-msk-serverless-iam"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Cluster connection & metadata.
      {
        Effect: "Allow",
        Action: [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster"
        ],
        Resource: "*"
      },
      # Topic-level read/write operations for the app.
      {
        Effect: "Allow",
        Action: [
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ],
        Resource: "*"
      },
      # Topic administration. Keep only if the app *really* needs to manage topics at runtime.
      # Prefer managing topics with Terraform or a one-off admin pipeline.
      {
        Effect: "Allow",
        Action: [
          "kafka-cluster:CreateTopic",
          "kafka-cluster:AlterTopic"
        ],
        Resource: "*"
      },
      # Consumer group membership/management for the app.
      {
        Effect: "Allow",
        Action: [
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:JoinGroup"
        ],
        Resource: "*"
      }
    ]
  })
}

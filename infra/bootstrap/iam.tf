# IAM role assumed by ECS tasks at runtime.
# This is different from the execution role: execution is for pulling images and logging,
# while the task role defines what the application itself can access once running.
# If the application fails with AccessDenied errors, the missing permissions are usually here.

data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ot-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  # Keep this role minimal and attach separate inline/managed policies
  # depending on the services the task actually needs to access.
}

# Policy granting read-only access to database credentials in Secrets Manager.
# At this stage it uses a wildcard resource to avoid blocking deployments.
# Later, replace with a project-specific ARN prefix or tagged secrets.
resource "aws_iam_role_policy" "ecs_task" {
  name = "ot-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid     = "SecretsRead",
        Effect  = "Allow",
        Action  = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      }
    ]
  })
}

# Output to expose the role ARN.
# Useful to reference in ECS task definitions or to debug from the CLI.
output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

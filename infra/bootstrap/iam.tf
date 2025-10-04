#####################################
# IAM Role for ECS Tasks
#####################################

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
}

#####################################
# Policy for Secrets Manager + RDS
#####################################

resource "aws_iam_role_policy" "ecs_task" {
  name = "ot-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      }
    ]
  })
}

#####################################
# Outputs
#####################################

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

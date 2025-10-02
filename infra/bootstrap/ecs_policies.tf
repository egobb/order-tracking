# Trust para ECS tasks
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



# Política administrada estándar de AWS para execution role (ECR, Logs, Secrets, KMS)
resource "aws_iam_role_policy_attachment" "ot_ecs_execution_role_managed" {
  role       = aws_iam_role.ot_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# (Opcional) Si usas parámetros/ssm extra, añade adjuntos aquí.

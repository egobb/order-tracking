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
          # Prefijo del secreto de Postgres (usa wildcard por el sufijo aleatorio)
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.this.account_id}:secret:ot/rds/postgres-*"

        ]
      }
    ]
  })
}


resource "aws_iam_role_policy" "task_kafka_iam" {
  name = "allow-msk-serverless-iam"
  role = aws_iam_role.ot_ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action: [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster"
        ],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: [
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ],
        Resource: "*",
      },
       {
        Effect: "Allow",
         Action: [
           "kafka-cluster:CreateTopic",
           "kafka-cluster:AlterTopic"
         ],
         Resource: "*",
       } ,
      # Consumer groups
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

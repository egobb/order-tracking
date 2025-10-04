# ECS Cluster + Task Definition + Service (Fargate)
resource "aws_ecs_cluster" "this" {
  name = "order-tracking-cluster"
}

# Task roles (needed execution role for ECR pull + logs)
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

data "aws_iam_role" "task_execution" {
  name = "ot-ecs-execution-role"
}

# Log group for containers
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/order-tracking"
  retention_in_days = 14
}

# Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = "order-tracking"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = data.aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "order-tracking"
      image = "${data.aws_caller_identity.this.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/order-tracking:${var.image_tag}"
      essential = true
      portMappings = [{ containerPort = var.container_port, protocol = "tcp" }]

      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = var.spring_profile },

        # --- Kafka: MSK Serverless (IAM over TLS: puerto 9098) ---
        { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = data.terraform_remote_state.bootstrap.outputs.msk_bootstrap_brokers },
        { name = "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL", value = "SASL_SSL" },
        { name = "SPRING_KAFKA_PROPERTIES_SASL_MECHANISM",    value = "AWS_MSK_IAM" },
        { name = "SPRING_KAFKA_PROPERTIES_SASL_JAAS_CONFIG",  value = "software.amazon.msk.auth.iam.IAMLoginModule required;" },
        { name = "SPRING_KAFKA_PROPERTIES_SASL_CLIENT_CALLBACK_HANDLER_CLASS", value = "software.amazon.msk.auth.iam.IAMClientCallbackHandler" },

        # --- (Opcional) RDS si ya lo tienes por bootstrap ---
        { name = "SPRING_DATASOURCE_URL",      value = "jdbc:postgresql://${data.terraform_remote_state.bootstrap.outputs.rds_endpoint}:5432/${data.terraform_remote_state.bootstrap.outputs.rds_db_name}" }
      ]

      # (Opcional) secrets para DB user/pass desde Secrets Manager
      secrets = [
         { name = "SPRING_DATASOURCE_USERNAME", valueFrom = "${data.terraform_remote_state.bootstrap.outputs.rds_secret_arn}:username::" },
         { name = "SPRING_DATASOURCE_PASSWORD", valueFrom = "${data.terraform_remote_state.bootstrap.outputs.rds_secret_arn}:password::" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Account identity (to build ECR image URL)
data "aws_caller_identity" "this" {}

# Fargate Service
resource "aws_ecs_service" "this" {
  name            = "order-tracking-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.public_subnet_ids
    security_groups = [aws_security_group.svc.id]
    assign_public_ip = true  # simple for DEV (without NAT)
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "order-tracking"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]
}

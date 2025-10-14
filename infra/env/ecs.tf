# ECS cluster to host the service tasks.
# One cluster is enough for this project; if multi-tenant later, split by env or capacity providers.
resource "aws_ecs_cluster" "this" {
  name = "order-tracking-cluster"
}

# Execution role used by the ECS agent (image pulls, logs, secret fetches by log drivers, etc.).
# Resolved by name from bootstrap for simplicity.
data "aws_iam_role" "task_execution" {
  name = "ot-ecs-execution-role"
}

# Log group for application logs.
# 14 days keeps costs low while providing enough history during development.
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/order-tracking"
  retention_in_days = 14
}

# Task definition for the application (Fargate).
# Uses awsvpc networking and injects config for MSK Serverless (IAM auth) and Postgres.
resource "aws_ecs_task_definition" "this" {
  family                   = "order-tracking"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  # Roles: execution for agent actions, task for app runtime permissions (from bootstrap).
  execution_role_arn = data.aws_iam_role.task_execution.arn
  task_role_arn      = data.terraform_remote_state.bootstrap.outputs.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name         = "order-tracking"
      image        = "${data.aws_caller_identity.this.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/order-tracking:${var.image_tag}"
      essential    = true
      portMappings = [{ containerPort = var.container_port, protocol = "tcp" }]

      # App configuration via env vars. Keep secrets out of here; use the 'secrets' block instead.
      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = var.spring_profile },

        # Kafka (MSK Serverless) over IAM on port 9098.
        { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = data.terraform_remote_state.bootstrap.outputs.msk_bootstrap_brokers },
        { name = "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL", value = "SASL_SSL" },
        { name = "SPRING_KAFKA_PROPERTIES_SASL_MECHANISM",    value = "AWS_MSK_IAM" },
        { name = "SPRING_KAFKA_PROPERTIES_SASL_JAAS_CONFIG",  value = "software.amazon.msk.auth.iam.IAMLoginModule required;" },
        { name = "SPRING_KAFKA_PROPERTIES_SASL_CLIENT_CALLBACK_HANDLER_CLASS", value = "software.amazon.msk.auth.iam.IAMClientCallbackHandler" },

        # JDBC URL built from bootstrap outputs. Credentials are injected as ECS secrets below.
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${data.terraform_remote_state.bootstrap.outputs.rds_endpoint}:5432/${data.terraform_remote_state.bootstrap.outputs.rds_db_name}" }
      ]

      # ECS-managed injection from Secrets Manager. The ":json-key::" suffix selects the field.
      # Example: arn:...:secret:ot/rds/postgres-XXXX:username::  → fetches {"username": "...", "password": "..."}[username]
      secrets = [
        { name = "SPRING_DATASOURCE_USERNAME", valueFrom = "${data.terraform_remote_state.bootstrap.outputs.rds_secret_arn}:username::" },
        { name = "SPRING_DATASOURCE_PASSWORD", valueFrom = "${data.terraform_remote_state.bootstrap.outputs.rds_secret_arn}:password::" }
      ]

      # CloudWatch Logs configuration.
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

# Account identity (used to construct the ECR image URL above).
data "aws_caller_identity" "this" {}

# Fargate service fronted by the ALB.
# Tasks are launched in the subnets exported from bootstrap; assigning a public IP keeps dev simple.
resource "aws_ecs_service" "this" {
  name            = "order-tracking-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.terraform_remote_state.bootstrap.outputs.msk_client_subnet_ids
    security_groups  = [aws_security_group.svc.id]
    assign_public_ip = true # For DEV without NAT; switch off when moving to private subnets.
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "order-tracking"
    container_port   = var.container_port
  }

  # Ensure the ALB listener exists before registering targets.
  depends_on = [aws_lb_listener.http]
}

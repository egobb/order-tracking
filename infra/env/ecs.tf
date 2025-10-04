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

    # --- Postgres ---
    {
      name      = "postgres"
      image     = "postgres:16-alpine"
      essential = true
      environment = [
        { name = "POSTGRES_DB",       value = "ordertracking" },
        { name = "POSTGRES_USER",     value = "order" },
        { name = "POSTGRES_PASSWORD", value = "orderpass" }
      ]
      portMappings = [] # don't expose outside task
      healthCheck = {
        command     = ["CMD-SHELL", "pg_isready -U order -d ordertracking -h 127.0.0.1"]
        interval    = 10
        timeout     = 5
        retries     = 12
        startPeriod = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "postgres"
        }
      }
    },

    # --- Redpanda ---
    {
      name      = "redpanda"
      image     = "redpandadata/redpanda:latest"
      essential = true
      command = [
        "redpanda","start",
        "--mode","dev",
        "--overprovisioned",
        "--smp","1",
        "--reserve-memory","0M",
        "--memory","1024M",
        "--kafka-addr","0.0.0.0:19092",
        "--advertise-kafka-addr","127.0.0.1:19092"
      ]
      portMappings = []
      healthCheck = {
        command     = ["CMD-SHELL", "rpk cluster info >/dev/null 2>&1 || exit 1"]
        interval    = 10
        timeout     = 5
        retries     = 12
        startPeriod = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "redpanda"
        }
      }
    },

    # --- Order tracking ---
    {
      name      = "order-tracking"
      image     = "${data.aws_caller_identity.this.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/order-tracking:${var.image_tag}"
      essential = true
      portMappings = [
        { containerPort = var.container_port, protocol = "tcp" }
      ]
      environment = [
        { name = "SPRING_PROFILES_ACTIVE",         value = var.spring_profile },
        { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = "localhost:19092" },
        { name = "SPRING_DATASOURCE_URL",          value = "jdbc:postgresql://localhost:5432/ordertracking" },
        { name = "SPRING_DATASOURCE_USERNAME",     value = "order" },
        { name = "SPRING_DATASOURCE_PASSWORD",     value = "orderpass" }
      ]
      dependsOn = [
        { containerName = "postgres", condition = "HEALTHY" },
        { containerName = "redpanda", condition = "HEALTHY" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "app"
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

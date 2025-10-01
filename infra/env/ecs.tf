# Cluster ECS
resource "aws_ecs_cluster" "this" {
  name = "order-tracking-cluster"
}

# Roles para la tarea (execution role imprescindible para pull de ECR + logs)
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

# Log group para el contenedor
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
      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]
      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = var.spring_profile }
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

# Identidad de la cuenta (para construir la URL de ECR)
data "aws_caller_identity" "this" {}

# Servicio Fargate
resource "aws_ecs_service" "this" {
  name            = "order-tracking-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.public_subnet_ids
    security_groups = [aws_security_group.svc.id]
    assign_public_ip = true  # simple para DEV (sin NAT)
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "order-tracking"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]
}

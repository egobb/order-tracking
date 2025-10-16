# Application Load Balancer for the service.
# Placed in public subnets so it can accept internet traffic; the ECS tasks will live
# in private or public subnets behind it. Security is enforced by the ALB SG and target SGs.
resource "aws_lb" "this" {
  name               = "ot-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.public_subnet_ids
  idle_timeout       = 60 # Keep-alive long enough for typical HTTP clients; tune per workload.
}

# Target group receiving traffic from the ALB.
# target_type = "ip" is required for Fargate (no instance IDs to register).
# Health check points to /actuator/health by default; adjust to your app's probe endpoint.
resource "aws_lb_target_group" "this" {
  name        = "ot-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    matcher             = "200-399"   # Consider 200-299 if your app returns strict OK.
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

# HTTP listener on port 80 forwarding all requests to the target group.
# HTTPS can be added with a second listener (443) when a certificate and domain are ready.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# -------------------------------------------------------------------
# - Keeping an HTTP listener simplifies early bootstrap and health-check validation.
#   Once the domain and certificate are available, add HTTPS and redirect HTTP->HTTPS.
# - target_type "ip" matches ECS Fargate tasks and allows per-task registration.
# -------------------------------------------------------------------
########################
# Application Load Balancer
# HTTP by default, optional HTTPS if enable_https=true
########################

resource "aws_lb" "this" {
  name               = "ot-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.public_subnet_ids
  idle_timeout       = 60
}

# Target Group al que el ALB enviará tráfico
resource "aws_lb_target_group" "this" {
  name        = "ot-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    # cambia si tu app no tiene actuator
    path                = "/actuator/health"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

# Listener HTTP (puerto 80) que forwardea al TG
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

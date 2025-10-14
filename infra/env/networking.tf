# Security group for the ALB.
# Inbound: allow HTTP (80) from anywhere, optionally HTTPS (443) if enabled.
# Outbound: allow all traffic (needed for health checks, ALB to backends, etc.).
resource "aws_security_group" "alb" {
  name        = "ot-alb-sg"
  description = "ALB security group: HTTP/HTTPS in, all traffic out"
  vpc_id      = local.vpc_id

  # Always open port 80 for HTTP.
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Conditionally open port 443 for HTTPS when enable_https=true.
  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Egress fully open (0.0.0.0/0 + ::/0). This is common for ALBs since
  # the target group traffic must flow to ECS tasks or health checks.
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Security group for ECS service tasks.
# Inbound: only allow traffic from the ALB SG to the container port.
# Outbound: open, so tasks can reach RDS, MSK, or external APIs.
resource "aws_security_group" "svc" {
  name   = "ot-svc-sg"
  vpc_id = local.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # restrict inbound to ALB only
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# -------------------------------------------------------------------
# - ALB is internet-facing, so it needs 80/443 from everywhere.
# - Service tasks are protected: only the ALB SG can connect to them on the app port.
# - Outbound is open on both SGs, which simplifies connectivity in dev.
# -------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "ot-alb-sg"
  description = "ALB 80/443 in, all out"
  vpc_id      = var.vpc_id

  ingress { from_port = 80  to_port = 80  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] ipv6_cidr_blocks = ["::/0"] }
  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content { from_port = 443 to_port = 443 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] ipv6_cidr_blocks = ["::/0"] }
  }
  egress  { from_port = 0   to_port = 0   protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] ipv6_cidr_blocks = ["::/0"] }
}

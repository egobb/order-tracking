# Allow ECS service tasks to connect to MSK over IAM-authenticated TLS (port 9098).
# The target SG is defined in bootstrap, and this rule grants ingress specifically
# from the ECS service SG in this environment.
resource "aws_security_group_rule" "msk_ingress_from_svc" {
  type                     = "ingress"
  security_group_id        = data.terraform_remote_state.bootstrap.outputs.msk_sg_id
  from_port                = 9098
  to_port                  = 9098
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.svc.id
  description              = "Allow MSK IAM TLS (9098) from ECS service"
}

# Allow ECS service tasks to connect to RDS Postgres (port 5432).
# Target is the RDS SG created in bootstrap, with ingress scoped
# to the ECS service SG only.
resource "aws_security_group_rule" "rds_from_ecs_5432" {
  type                     = "ingress"
  security_group_id        = data.terraform_remote_state.bootstrap.outputs.rds_sg_id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.svc.id
  description              = "Allow Postgres (5432) from ECS service"
}

# -------------------------------------------------------------------
# - Keeps RDS and MSK SGs isolated and only opens them to ECS service traffic.
# - Uses SG→SG references instead of 0.0.0.0/0, applying the principle of least privilege.
# - Keeps bootstrap responsible for resource ownership (MSK, RDS SGs) while env attaches the rules.
# -------------------------------------------------------------------

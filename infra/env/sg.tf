
# Inbound en el SG del MSK (definido en bootstrap) desde el SG del servicio ECS
resource "aws_security_group_rule" "msk_ingress_from_svc" {
  type                     = "ingress"
  security_group_id        = data.terraform_remote_state.bootstrap.outputs.msk_sg_id
  from_port                = 9098
  to_port                  = 9098
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.svc.id  # tu SG del servicio ECS
}

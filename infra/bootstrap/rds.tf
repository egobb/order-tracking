#####################################
# Discover VPC & Private Subnets
#####################################

# Detecta tu VPC por tag o usa la default (ajusta el filtro si ya usas otro en el repo)
data "aws_vpc" "this" {
  default = true
}

# Busca subnets privadas (asumiendo que las etiquetas con "Tier=private")
data "aws_subnets" "private" {
  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
}

locals {
  private_subnet_ids = data.aws_subnets.private.ids
}

#####################################
# RDS PostgreSQL
#####################################

# Grupo de subredes de RDS
resource "aws_db_subnet_group" "pg" {
  name       = "ot-pg-subnets"
  subnet_ids = local.private_subnet_ids
}

# Security Group de RDS (ingress vacío, se añadirá desde env con SG→SG)
resource "aws_security_group" "rds" {
  name   = "ot-rds-sg"
  vpc_id = data.aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Secret en Secrets Manager para credenciales
resource "aws_secretsmanager_secret" "pg" {
  name = "ot/rds/postgres"
}

resource "aws_secretsmanager_secret_version" "pg" {
  secret_id     = aws_secretsmanager_secret.pg.id
  secret_string = jsonencode({
    username = "order"
    password = "orderpass-strong"
  })
}

# Instancia RDS PostgreSQL
resource "aws_db_instance" "pg" {
  identifier              = "ot-postgres"
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20

  db_name                 = "ordertracking"
  username                = jsondecode(aws_secretsmanager_secret_version.pg.secret_string).username
  password                = jsondecode(aws_secretsmanager_secret_version.pg.secret_string).password

  db_subnet_group_name    = aws_db_subnet_group.pg.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
}

#####################################
# Outputs
#####################################

output "rds_endpoint" {
  value = aws_db_instance.pg.address
}

output "rds_db_name" {
  value = aws_db_instance.pg.db_name
}

output "rds_secret_arn" {
  value = aws_secretsmanager_secret.pg.arn
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

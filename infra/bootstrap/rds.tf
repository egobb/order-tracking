# RDS PostgreSQL subnet group.
# Using the current public subnet list to get the cluster running quickly.
# RDS requires at least two subnets in different AZs. For a tighter posture,
# consider switching to private subnets once the rest of the stack is stable.
resource "aws_db_subnet_group" "pg" {
  name       = "ot-pg-subnets"
  subnet_ids = local.public_subnet_ids
}

# Security group for the database. Ingress is intentionally empty here;
# environment-specific modules should add SG→SG rules to allow only app traffic.
# Egress is open so the instance can reach AWS services (e.g., for logs, KMS, etc.).
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

# Secrets Manager entry for DB credentials.
# This keeps credentials out of source code, but note that Terraform state
# will still contain the secret value unless using managed password features (see notes).
resource "aws_secretsmanager_secret" "pg" {
  name = "ot/rds/postgres"
}

# Initial version with a simple JSON payload (username/password).
# The app will fetch this at runtime using IAM.
resource "aws_secretsmanager_secret_version" "pg" {
  secret_id     = aws_secretsmanager_secret.pg.id
  secret_string = jsonencode({
    username = "orders"
    password = "orders_strong"
  })
}

# RDS PostgreSQL instance for the application.
# Publicly accessible is disabled; connectivity happens inside the VPC via SG rules.
# Username/password are read from the secret above to have a single source of truth.
resource "aws_db_instance" "pg" {
  identifier        = "ot-postgres"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  db_name  = "ordertracking"
  username = jsondecode(aws_secretsmanager_secret_version.pg.secret_string).username
  password = jsondecode(aws_secretsmanager_secret_version.pg.secret_string).password

  db_subnet_group_name   = aws_db_subnet_group.pg.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # For bootstrap/dev I skip the final snapshot so `destroy` is quick and clean.
  # In any persistent env, enable final snapshot and/or deletion protection.
  skip_final_snapshot = true
}

# Outputs used by other modules or for quick checks.
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

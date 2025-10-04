# Default VPC de la cuenta/región actual
data "aws_vpc" "this" {}

# Todas las subnets de esa VPC
data "aws_subnets" "all_in_default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
}

# Cargamos detalles de cada subnet para saber si es pública
data "aws_subnet" "all" {
  for_each = toset(data.aws_subnets.all_in_default_vpc.ids)
  id       = each.value
}

# Locals que usarás en todos los recursos del módulo
locals {
  vpc_id = data.aws_vpc.this.id

  # Lista de AZs a excluir (MSK Serverless no soporta us-east-1e)
  # Si cambias de región y te vuelve a fallar, añade aquí la AZ concreta que te diga el error.
  unsupported_azs = ["us-east-1e"]

  # Públicas = con map_public_ip_on_launch = true
  public_subnet_ids = [
    for s in data.aws_subnet.all : s.id
    if s.map_public_ip_on_launch && !contains(local.unsupported_azs, s.availability_zone)
  ]
}

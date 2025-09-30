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

  # Públicas = con map_public_ip_on_launch = true
  public_subnet_ids = [
    for s in data.aws_subnet.all : s.id
    if s.map_public_ip_on_launch
  ]
}

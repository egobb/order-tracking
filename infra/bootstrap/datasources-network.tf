# Grab the default VPC for the current account/region.
# Note: I use the default VPC here just to avoid creating a custom one for this project.
# If in the future I want full control over networking, I should create a dedicated VPC.
data "aws_vpc" "this" {}

# Get all the subnets that belong to this VPC.
# Important: this will include both public and private subnets, so I’ll filter later.
data "aws_subnets" "all_in_default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
}

# Load details for each subnet individually.
# I need this step because only the subnet resource has the attribute
# `map_public_ip_on_launch`, which tells me if it’s public.
data "aws_subnet" "all" {
  for_each = toset(data.aws_subnets.all_in_default_vpc.ids)
  id       = each.value
}

# Local values to reuse across the module.
locals {
  vpc_id = data.aws_vpc.this.id

  # Some availability zones are not supported by certain services (e.g. MSK Serverless).
  # For example, us-east-1e is known to fail. If I change region and get errors,
  # I should add the failing AZ here so Terraform ignores it.
  unsupported_azs = ["us-east-1e"]

  # Public subnets = those with `map_public_ip_on_launch = true`.
  # I also exclude any AZs listed above because otherwise deployments may break.
  public_subnet_ids = [
    for s in data.aws_subnet.all : s.id
    if s.map_public_ip_on_launch && !contains(local.unsupported_azs, s.availability_zone)
  ]
}

# Outputs for other modules or debugging.
# Handy if I need to quickly check the IDs after apply.
output "vpc_id" {
  value = local.vpc_id
}

output "public_subnet_ids" {
  value = local.public_subnet_ids
}

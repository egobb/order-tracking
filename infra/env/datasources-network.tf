# Load network configuration from the bootstrap stack.
# We intentionally do not recreate VPC or subnets here;
# instead, we reuse the ones provisioned during bootstrap to ensure consistency.

locals {
  # VPC used for this environment. Comes from bootstrap remote state.
  vpc_id = data.terraform_remote_state.bootstrap.outputs.vpc_id

  # Public subnets available for ALB, ECS tasks, etc.
  # These are filtered in bootstrap to exclude unsupported AZs.
  public_subnet_ids = data.terraform_remote_state.bootstrap.outputs.public_subnet_ids
}

# -------------------------------------------------------------------
# - Centralizes networking in bootstrap so all environments share the same baseline.
# - Avoids duplication of VPC/subnet configuration across stacks.
# -------------------------------------------------------------------
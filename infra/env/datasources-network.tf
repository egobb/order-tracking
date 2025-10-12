locals {
  vpc_id             = data.terraform_remote_state.bootstrap.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.bootstrap.outputs.public_subnet_ids
}
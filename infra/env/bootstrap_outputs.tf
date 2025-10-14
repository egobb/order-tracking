# Import remote state from the bootstrap stack.
# This allows the environment stack (env) to reuse infrastructure pieces
# like IAM roles, S3 state bucket, DynamoDB lock table, etc.
# The values are fetched directly from the remote backend rather than being redefined.
data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    bucket = "egobb-tf-state-us-east-1"                # Bootstrap state bucket (created in bootstrap stack).
    key    = "order-tracking/bootstrap/terraform.tfstate" # Exact path to the bootstrap state file.
    region = var.aws_region                           # Region is parameterized so env matches bootstrap.
  }
}

# -------------------------------------------------------------------
# - Keeps a clear separation between bootstrap (global infra like state backend, IAM, base roles)
#   and environment-specific resources (env).
# - Remote state is the canonical way to share references across stacks without duplication.
# -------------------------------------------------------------------
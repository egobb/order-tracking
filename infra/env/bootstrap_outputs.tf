data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    bucket = "egobb-tf-state-us-east-1"
    key    = "order-tracking/bootstrap/terraform.tfstate"
    region = var.aws_region
  }
}
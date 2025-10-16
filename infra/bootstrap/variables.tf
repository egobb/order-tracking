# AWS region to deploy resources into.
# Default is us-east-1 because many managed services (e.g., MSK Serverless) are supported there first.
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# Name of the S3 bucket used to store Terraform remote state.
# This must be unique across AWS. Default is pre-provisioned for bootstrap.
variable "tf_state_bucket" {
  type    = string
  default = "egobb-tf-state-us-east-1"
}

# DynamoDB table name for Terraform state locking.
# Prevents concurrent applies from corrupting the state.
variable "tf_lock_table" {
  type    = string
  default = "egobb-tf-locks"
}

# Monthly budget limit in USD for the AWS account.
# Used by the budgets resource to trigger forecast notifications.
# Defined as string here because the AWS provider expects string inputs.
variable "monthly_budget_amount" {
  type    = string
  default = "20"
}

# List of email addresses to receive budget alerts.
# In practice, point this to a team distribution list instead of a personal inbox.
variable "budget_emails" {
  type    = list(string)
  default = ["egoberngarcia@gmail.com"]
}

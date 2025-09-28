variable "aws_region" {
  type    = string
  default = "eu-east-1"
}

variable "tf_state_bucket" {
  type    = string
  default = "egobb-tf-state"
}

variable "tf_lock_table" {
  type    = string
  default = "egobb-tf-locks"
}

variable "monthly_budget_amount" {
  type    = string
  default = "20"
}

variable "budget_emails" {
  type    = list(string)
  default = ["egoberngarcia@gmail.com"]
}



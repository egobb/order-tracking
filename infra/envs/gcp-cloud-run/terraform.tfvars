# --- Cloud Build trigger ---
github_owner    = "egobb"
github_repo     = "order-tracking"
cb_branch_regex = "^feature/infra-gcp"

cb_region = "europe-west1"
cb_repo   = "order-tracking"
cb_image  = "order-tracking:latest"

project_id   = "order-tracking-473419"
region       = "europe-west1"
repo_id      = "order-tracking"
service_name = "order-tracking"

image        = "gcr.io/cloudrun/hello"

public       = true
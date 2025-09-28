# --- Cloud Build trigger ---
github_owner    = "egobb"
github_repo     = "order-tracking"
cb_branch_regex = "^feature/infra-gcp"

cb_region = "europe-west1"
cb_repo   = "order-tracking"
cb_image  = "order-tracking:latest"
cb_trigger_name = "Google-CloudBuild-Trigger"

project_id   = "order-tracking-473419"
region       = "europe-west1"
repo_id      = "order-tracking"
service_name = "order-tracking"

image        = "ghcr.io/egobb/order-tracking:latest"

public       = true

cb_connection_id = "github-conn"
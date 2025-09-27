# Cloud Build trigger that points to my GitHub repo and runs the pipeline in cloudbuild.yaml
# Note: I must have the "Google Cloud Build" GitHub App installed and the repo authorized.

resource "google_cloudbuild_trigger" "order_tracking_build" {
  name        = var.cb_trigger_name
  description = "Build & push image for Order Tracking (Cloud Run env)"
  filename    = "infra/envs/gcp-cloud-run/cloudbuild.yaml" # I keep the pipeline colocated with this env

  github {
    owner = var.github_owner   # ex: "egobb"
    name  = var.github_repo    # ex: "order-tracking"

    push {
      # I keep it simple: trigger on pushes to main (I can switch to tags later)
      branch = var.cb_branch_regex  # ex: "^main$"
    }
  }

  substitutions = {
    # I set sane defaults here; I can override per-trigger in console if I want.
    _REGION = var.cb_region
    _REPO   = var.cb_repo
    _IMAGE  = var.cb_image
  }
}

# I need to grant Artifact Registry Writer to the Cloud Build default SA
# so it can push the image to my AR repo.
data "google_project" "current" {}

resource "google_project_iam_member" "cb_artifact_writer" {
  project = data.google_project.current.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.current.number}@cloudbuild.gserviceaccount.com"
}

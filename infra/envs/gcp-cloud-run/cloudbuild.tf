# Repositorio conectado vía "Connections" (selecciona el connection_id y la URL del repo)
resource "google_cloudbuildv2_repository" "repo" {
  project       = var.project_id
  location      = "global"
  connection    = var.cb_connection_id     # nombre de tu "Connection" (p. ej. "github-conn")
  remote_uri    = "https://github.com/egobb/order-tracking.git"
}

resource "google_cloudbuildv2_trigger" "order_tracking_build" {
  project  = var.project_id
  location = "global"
  name     = var.cb_trigger_name

  repository_event_config {
    repository = google_cloudbuildv2_repository.repo.id
    push {
      branch = var.cb_branch_regex       # sigue siendo regex, ej: "^main$"
    }
  }

  build {
    filename = "infra/envs/gcp-cloud-run/cloudbuild.yaml"
    substitutions = {
      _REGION = var.cb_region
      _REPO   = var.cb_repo
      _IMAGE  = var.cb_image
    }
  }
}

data "google_project" "current" {}

resource "google_project_iam_member" "cb_artifact_writer" {
  project = data.google_project.current.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.current.number}@cloudbuild.gserviceaccount.com"
}

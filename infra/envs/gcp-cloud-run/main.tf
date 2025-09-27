terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.39"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable all the APIs I need for Cloud Run + infra
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  project                    = var.project_id
  service                    = each.key
  disable_on_destroy         = false
  disable_dependent_services = false
}

# Artifact Registry for storing my container images
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.repo_id
  description   = "Order Tracking container images"
  format        = "DOCKER"
  depends_on    = [for a in google_project_service.apis : a]
}

# Service Account that Cloud Run will use
resource "google_service_account" "run_sa" {
  account_id   = "order-tracking-run-sa"
  display_name = "Order Tracking Cloud Run SA"
}

# Allow my service account to read secrets from Secret Manager
resource "google_project_iam_member" "sa_secretaccess" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

# Secret Manager to keep env vars (optional)
# I only create it if I want to store a blob with .env-like data
resource "google_secret_manager_secret" "app_env" {
  count     = var.create_app_env_secret ? 1 : 0
  secret_id = "order-tracking-app-env"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "app_env_v" {
  count       = var.create_app_env_secret ? 1 : 0
  secret      = google_secret_manager_secret.app_env[0].name
  secret_data = var.app_env_content
}

# Main Cloud Run service (v2 API)
resource "google_cloud_run_v2_service" "svc" {
  name     = var.service_name
  location = var.region
  ingress  = var.ingress # All traffic or internal only

  template {
    service_account = google_service_account.run_sa.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      # Here I specify the image I already pushed to Artifact Registry
      image = var.image

      ports {
        container_port = 8080
      }

      # Example of a simple env var (not secret)
      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = var.spring_profiles
      }

      # Example of reading env vars from Secret Manager (optional)
      dynamic "env" {
        for_each = var.create_app_env_secret ? [1] : []
        content {
          name = "APP_ENV_FROM_SECRET"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.app_env[0].name
              version = "latest"
            }
          }
        }
      }

      # Resource limits for each container
      resources {
        cpu_idle = true
        limits = {
          cpu    = var.container_cpu
          memory = var.container_memory
        }
      }
    }

    # Concurrency per instance (default is 80). Adjust if needed.
    max_instance_request_concurrency = var.concurrency
  }

  depends_on = [
    for a in google_project_service.apis : a,
  google_artifact_registry_repository.repo
]
}

# IAM binding → make service public if I want, or restrict to the SA
resource "google_cloud_run_service_iam_member" "public_invoker" {
location = google_cloud_run_v2_service.svc.location
project  = var.project_id
service  = google_cloud_run_v2_service.svc.name
role     = "roles/run.invoker"
member   = var.public ? "allUsers" : "serviceAccount:${google_service_account.run_sa.email}"
}

output "url" {
value = google_cloud_run_v2_service.svc.uri
}

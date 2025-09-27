# URL to access the Cloud Run service
output "cloud_run_url" {
  value = google_cloud_run_v2_service.svc.uri
}

# Artifact Registry repo name, just for reference
output "artifact_registry_repo" {
  value = google_artifact_registry_repository.repo.repository_id
}

# Cloud Build trigger id, for quick reference
output "cloudbuild_trigger_id" {
  value = google_cloudbuild_trigger.order_tracking_build.id
}
resource "google_container_registry" "this" {
  project  = data.google_project.this.project_id
  location = "EU"
}

resource "google_service_account" "registry" {
  account_id   = "${local.project_name}-registry"
  display_name = "${local.project_name}-registry"
  description  = "${local.project_name} Registry"
}

resource "google_project_iam_member" "registry" {
  role    = "roles/storage.admin"
  project = data.google_project.this.project_id
  member  = "serviceAccount:${google_service_account.registry.email}"
}

resource "google_service_account_key" "registry" {
  service_account_id = google_service_account.registry.name
}

resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_container_registry.this.id
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.kubernetes.email}"
}

data "google_container_registry_repository" "this" {
  region = lower(google_container_registry.this.location)
}

locals {
  gcr_url = "${data.google_container_registry_repository.this.repository_url}/"
}

output "gcr_location" {
  value = data.google_container_registry_repository.this.repository_url
}

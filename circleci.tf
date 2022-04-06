resource "circleci_context" "common" {
  name = "common"
}

resource "google_service_account" "circleci" {
  account_id = "circleci"
}

resource "google_service_account_key" "circleci" {
  service_account_id = google_service_account.circleci.name
}

resource "google_project_iam_binding" "circleci" {
  project = data.google_project.this.id
  for_each = toset([
    "roles/container.admin"
  ])
  role    = each.value
  members = [
    "serviceAccount:${google_service_account.circleci.email}",
  ]
}

resource "circleci_context_environment_variable" "common" {
  for_each = {
    GCP_SERVICE_ACCOUNT_KEY = google_service_account_key.circleci.private_key
    GCP_PROJECT_ID = data.google_project.this.project_id
    CLUSTER_NAME = google_container_cluster.this.name
    CLUSTER_ZONE = google_container_cluster.this.location
    DOCKER_REGISTRY = local.gcr_url
    DOCKER_REGISTRY_AUTH = "gcloud auth configure-docker"
    EXECUTOR_IMAGE = "google/cloud-sdk:latest"
    PROXY_URL = "socks5://${random_string.go-socks5-proxy-user.result}:${random_string.go-socks5-proxy-user.result}@${cloudflare_record.go-socks5-proxy.hostname}:${local.go-socks5-proxy-port}"
  }
  context_id = circleci_context.common.id
    variable = each.key
    value = each.value
}

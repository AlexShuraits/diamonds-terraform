locals {
  managed-secrets = [
    "cf_api_token",
    "cf_api_user_service_key",
    "circleci_token"
  ]
}

resource "google_secret_manager_secret" "this" {
  depends_on = [google_project_service.this]
  for_each   = { for i in local.managed-secrets : (i) => (i) }
  secret_id  = each.value

  replication {
    automatic = true
  }
}

data "google_secret_manager_secret_version" "this" {
  for_each = google_secret_manager_secret.this
  secret   = each.value.secret_id
}

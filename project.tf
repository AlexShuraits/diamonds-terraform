data "google_project" "this" {}

data "google_client_config" "this" {}

resource "google_project_service" "this" {
  for_each = toset([
    "iam",
    "compute",
    "containerregistry",
    "logging",
    "container",
    "secretmanager",
    "servicenetworking"
  ])
  project = data.google_project.this.id
  service = "${each.value}.googleapis.com"

}

data "cloudflare_zone" "this" {
  name = var.domain
}

resource "cloudflare_zone_settings_override" "this" {
  zone_id = data.cloudflare_zone.this.id
  settings {
    ssl = "full"
  }
}

locals {
  project_name = lower(data.google_project.this.name)
}

resource "google_sql_database_instance" "mysql" {
  name = "${local.project_name}-${random_id.mysql.hex}"
  region = data.google_client_config.this.region
  database_version = "MYSQL_5_7"
  settings {
    tier = "db-g1-small"
    ip_configuration {
      ipv4_enabled = true
      private_network = module.vpc.network_self_link
      dynamic "authorized_networks" {
        for_each = concat(var.authorized_ips, var.mysql_authorized_ips)
        content {
          value = authorized_networks.value.cidr_block
          name = authorized_networks.value.display_name
        }
      }
    }
    maintenance_window {
      day = "6"
      hour = "2"
      update_track = "stable"
    }
    backup_configuration {
      enabled = true
      start_time = "02:00"
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_service" "mysql" {
  metadata {
    name = "mysql"
  }
  spec {
    type = "ExternalName"
    external_name = google_sql_database_instance.mysql.private_ip_address
  }
}

resource "random_id" "mysql" {
  byte_length = 4
}

resource "random_password" "mysql_root_password" {
  length = 12
  special = false
}

resource "google_sql_user" "mysql_root" {
  name = "root"
  instance = google_sql_database_instance.mysql.name
  password = random_password.mysql_root_password.result
  host = "%"
}

resource "google_compute_global_address" "mysql"{
  name = "${local.project_name}-mysql-db"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 24
  network = module.vpc.network_name
}

resource "google_service_networking_connection" "mysql" {
  network                 = module.vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.mysql.name
  ]
}

resource "google_compute_network_peering_routes_config" "mysql" {
  for_each = toset([
    "servicenetworking",
  ])
  peering = "${each.value}-googleapis-com"
  network = module.vpc.network_name

  import_custom_routes = true
  export_custom_routes = true

  depends_on = [
    google_sql_database_instance.mysql
  ]
}

output "mysql" {
  value = random_password.mysql_root_password.result
  sensitive = true
}

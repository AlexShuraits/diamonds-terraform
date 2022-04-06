locals {
  be_prefix = "be"
}

module "be" {
  source = "./modules/k8s-service"
  name = local.be_prefix
  replicas = 1
  image = {
    name = "${local.gcr_url}/diamonds-${local.be_prefix}"
    tag = "latest"
  }
  cf_zone = data.cloudflare_zone.this.id
  ingress = {
    host = "api.${var.domain}"
    path = "/"
    tls_cert = tls_private_key.this.private_key_pem
    tls_key = cloudflare_origin_ca_certificate.this.certificate
    lb_address = google_compute_address.nginx-ingress.address
  }
  probes_disabled = true
  envs = {
    API_PORT = 3000
    APP_HOST = "https://mashina.${var.domain}"
    DB_HOST = "${kubernetes_service.mysql.metadata.0.name}.default.svc.cluster.local"
    DB_NAME = mysql_database.be.name
    DB_USERNAME = mysql_user.be.user
    DB_PASSWORD = random_password.be.result
  }
}

resource "mysql_database" "be" {
  name = "be"
}

resource "random_password" "be" {
  length = 16
  special = false
}

resource "mysql_user" "be" {
  user = "be"
  plaintext_password = random_password.be.result
  host = "%"
}

resource "mysql_grant" "be" {
  database = mysql_database.be.name
  privileges = ["ALL"]
  user = mysql_user.be.user
  host = "%"
}

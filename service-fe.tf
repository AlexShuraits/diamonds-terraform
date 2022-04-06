locals {
  fe_prefix = "fe"
}

module "fe" {
  source = "./modules/k8s-service"
  name = local.fe_prefix
  replicas = 1
  image = {
    name = "${local.gcr_url}/diamonds-${local.fe_prefix}"
    tag = "latest"
  }
  cf_zone = data.cloudflare_zone.this.id
  ingress = {
    host = "mashina.${var.domain}"
    path = "/"
    tls_cert = tls_private_key.this.private_key_pem
    tls_key = cloudflare_origin_ca_certificate.this.certificate
    lb_address = google_compute_address.nginx-ingress.address
  }
  liveness_probe_path = "/"
  readiness_probe_path = "/"
  envs = {
    NEXT_PUBLIC_REACT_APP_ENV = "dev"
    NEXT_PUBLIC_API_HOST = "https://mashina.${var.domain}"
  }
}

resource "google_compute_address" "nginx-ingress" {
  name         = "nginx-ingress"
  address_type = "EXTERNAL"
  region       = data.google_client_config.this.region
}

resource "kubernetes_namespace" "ingress-nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress-nginx" {
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress-nginx.metadata.0.name
  values = [ templatefile("values/nginx-ingress.yml", {
    ingress_lb_ip = google_compute_address.nginx-ingress.address
  })]
  version = "4.0.8"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "tls_cert_request" "this" {
  key_algorithm   = tls_private_key.this.algorithm
  private_key_pem = tls_private_key.this.private_key_pem
  subject {
    common_name  = local.project_name
    organization = "Diamonds"
  }
}

resource "cloudflare_origin_ca_certificate" "this" {
  csr                = tls_cert_request.this.cert_request_pem
  hostnames          = [var.domain, "*.${var.domain}"]
  request_type       = "origin-rsa"
  requested_validity = 365 * 15
  lifecycle {
    ignore_changes = [
      requested_validity
    ]
  }
}

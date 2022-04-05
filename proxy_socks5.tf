resource "kubernetes_namespace" "proxy" {
  metadata {
    name = "proxy"
  }
}

resource "kubernetes_deployment" "go-socks5-proxy" {
  metadata {
    name = "go-socks5-proxy"
    namespace = kubernetes_namespace.proxy.metadata.0.name
    labels = {
      app = "go-socks5-proxy"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "go-socks5-proxy"
      }
    }
    template {
      metadata {
        labels = {
          app = "go-socks5-proxy"
        }
      }
      spec {
        container {
          image = "serjs/go-socks5-proxy:v0.0.3"
          image_pull_policy = "Always"
          name = "go-socks5-proxy"
          resources {
            limits = {
              cpu = "0.1"
              memory = "50Mi"
            }
            requests = {
              cpu = "0.05"
              memory = "20Mi"
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.go-socks5-proxy-env.metadata.0.name
            }
          }
          port {
            container_port = local.go-socks5-proxy-port
          }
          readiness_probe {
            tcp_socket {
              port = local.go-socks5-proxy-port
            }
          }
        }
      }
    }
  }
}

resource "random_string" "go-socks5-proxy-user" {
  length = 16
  special = false
}

resource "random_password" "go-socks5-proxy-password" {
  length = 24
  special = false
}

output "socks5-proxy" {
  value = {
    username = random_string.go-socks5-proxy-user.result
    password = random_password.go-socks5-proxy-password.result
    address = cloudflare_record.go-socks5-proxy.hostname
    port = local.go-socks5-proxy-port
  }
  sensitive = true
}

locals {
  go-socks5-proxy-port = 1881
}

resource "kubernetes_secret" "go-socks5-proxy-env" {
  metadata {
    namespace = kubernetes_namespace.proxy.metadata.0.name
    name = "go-socks5-proxy-env"
  }
  data = {
    PROXY_USER = random_string.go-socks5-proxy-user.result
    PROXY_PASSWORD = random_string.go-socks5-proxy-user.result
    PROXY_PORT = local.go-socks5-proxy-port
  }
}

resource "kubernetes_service" "go-socks5-proxy" {
  metadata {
    name = "go-socks5-proxy"
    namespace = kubernetes_namespace.proxy.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.go-socks5-proxy.metadata.0.labels.app
    }
    port {
      port = local.go-socks5-proxy-port
    }
  }
}

resource "cloudflare_record" "go-socks5-proxy" {
  zone_id = data.cloudflare_zone.this.id
  name = "proxy.${var.domain}"
  value = google_compute_address.nginx-ingress.address
  type = "A"
  proxied = false
}

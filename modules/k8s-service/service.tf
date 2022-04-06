resource "kubernetes_namespace" "this" {
  metadata {
    name = "${var.project}-${var.name}"
  }
}

resource "kubernetes_deployment" "this" {
  count = var.probes_disabled ? 0 : 1
  wait_for_rollout = false
  metadata {
    name = var.name
    namespace = kubernetes_namespace.this.metadata.0.name
    labels = {
      app = var.name
    }
  }
  spec {
    replicas = var.autoscaling_enabled ? null : var.replicas
    selector {
      match_labels = {
        app = var.name
      }
    }
    template {
      metadata {
        labels = {
          app = var.name
        }
      }
      spec {
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key = "app"
                    operator = "In"
                    values = [var.name]
                  }
                }
              }
            }
          }
        }
        container {
          name = var.name
          image = "${var.image.name}:${var.image.tag}"
          image_pull_policy = "Always"
          port {
            container_port = var.port
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.default_env.metadata.0.name
            }
          }
          resources {
            limits = {
              cpu = var.resources.limit.cpu
              memory = var.resources.limit.ram
            }
            requests = {
              cpu = var.resources.request.cpu
              memory = var.resources.request.ram
            }
          }
          readiness_probe {
            http_get {
              path = var.readiness_probe_path
              port = var.port
            }
            initial_delay_seconds = 10
            success_threshold = 3
            failure_threshold = 3
            timeout_seconds = 15
          }
          liveness_probe {
            http_get {
              path = var.liveness_probe_path
              port = var.port
            }
            initial_delay_seconds = 10
            success_threshold = 1
            failure_threshold = 10
            timeout_seconds = 10
          }
        }
        dynamic toleration {
          for_each = var.tolerations
          content {
            key = toleration.key
            value = toleration.value
            effect = "NoExecute"
          }
        }
        node_selector = var.nodepool_selector
      }
    }
  }
  lifecycle {
    ignore_changes = [
      spec.0.template.0.spec.0.container.0.image,
      spec.0.template.0.spec.0.container.0.env,
    ]
  }
}

resource "kubernetes_deployment" "this_wo_probe" {
  count = var.probes_disabled ? 1 : 0
  wait_for_rollout = false
  metadata {
    name = var.name
    namespace = kubernetes_namespace.this.metadata.0.name
    labels = {
      app = var.name
    }
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = var.name
      }
    }
    template {
      metadata {
        labels = {
          app = var.name
        }
      }
      spec {
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key = "app"
                    operator = "In"
                    values = [var.name]
                  }
                }
              }
            }
          }
        }
        container {
          name = var.name
          image = "${var.image.name}:${var.image.tag}"
          image_pull_policy = "Always"
          port {
            container_port = var.port
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.default_env.metadata.0.name
            }
          }
          resources {
            limits = {
              cpu = var.resources.limit.cpu
              memory = var.resources.limit.ram
            }
            requests = {
              cpu = var.resources.request.cpu
              memory = var.resources.request.ram
            }
          }
        }
        dynamic toleration {
          for_each = var.tolerations
          content {
            key = toleration.key
            value = toleration.value
            effect = "NoExecute"
          }
        }
        node_selector = var.nodepool_selector
      }
    }
  }
  lifecycle {
    ignore_changes = [
      spec.0.template.0.spec.0.container.0.image,
      spec.0.template.0.spec.0.container.0.env,
    ]
  }
}

resource "kubernetes_pod_disruption_budget" "this" {
  metadata {
    name = var.name
    namespace = kubernetes_namespace.this.metadata.0.name
  }
  spec {
    selector {
      match_labels = {
        app = var.name
      }
    }
    max_unavailable = "0"
  }
}

resource "kubernetes_service" "this" {
  metadata {
    name = var.name
    namespace = kubernetes_namespace.this.metadata.0.name
  }
  spec {
    selector = {
      app = var.name
    }
    session_affinity = "ClientIP"
    port {
      port = 80
      target_port = var.port
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress" "this" {
  metadata {
    name      = "${var.name}-ingress"
    namespace = kubernetes_namespace.this.metadata.0.name
    annotations = var.ingress_annotations
  }
  spec {
    rule {
      host = var.ingress.host
      http {
        path {
          backend {
            service_name = kubernetes_service.this.metadata.0.name
            service_port = 80
          }
          path = var.ingress.path
        }
      }
    }
    tls {
      hosts = [var.ingress.host]
      secret_name = kubernetes_secret.ssl.metadata.0.name
    }
  }
}

resource "kubernetes_secret" "ssl" {
  metadata {
    name = "${var.name}-ssl-cert"
    namespace = kubernetes_namespace.this.metadata.0.name
  }
  type = "kubernetes.io/tls"
  data = {
    "tls.key" = var.ingress.tls_key
    "tls.crt" = var.ingress.tls_cert
  }
}

resource "kubernetes_secret" "default_env" {
  metadata {
    name = "${var.name}-default-env"
    namespace = kubernetes_namespace.this.metadata.0.name
  }
  data = var.envs
}

resource "cloudflare_record" "this" {
  zone_id = var.cf_zone
  name = var.ingress.host
  type = "A"
  value = var.ingress.lb_address
  proxied = true
}

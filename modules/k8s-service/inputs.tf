#DEFAULT
variable "project" {
  default = "diamonds"
}

variable "name" {}

variable "replicas" {}

variable "image" {
  type = object({
    name = string
    tag = string
  })
}

#DEFAULT
variable "port" {
  default = 3000
}

variable "resources" {
  default = {
    limit = {
      cpu = "0.3"
      ram = "512Mi"
    }
    request = {
      cpu = "0.1"
      ram = "128Mi"
    }
  }
}

variable "ingress" {
  type = object({
    host = string
    path = string
    tls_cert = string
    tls_key = string
    lb_address = string
  })
}

variable "ingress_annotations" {
  default = {
    "kubernetes.io/ingress.class" = "nginx",
    "nginx.ingress.kubernetes.io/server-snippet" = "set_real_ip_from 0.0.0.0/0; real_ip_header X-Forwarded-For;",
  }
}

variable "readiness_probe_path" {
  default = "/ping"
}

variable "liveness_probe_path" {
  default = "/ping"
}

variable "probes_disabled" {
  default = false
}

variable "envs" {
  type = map(string)
  default = {}
}

variable "cf_zone" {}

variable "autoscaling_enabled" {
  default = false
}

variable "scaling_params" {
  type = object({
    pollingInterval = number
    cooldownPeriod = number
    advanced = any
    triggers = list(any)
  })
  default = {
    pollingInterval = 30
    cooldownPeriod = 300
    advanced = {
      "restoreToOriginalReplicaCount" = true
      "horizontalPodAutoscalerConfig" = {
        "behavior" = {
          "scaleDown" = {
            "stabilizationWindowSeconds" = 300
            "policies" = [
              {
                "type" = "Pods"
                "value" = 1
                "periodSeconds" = 1800
              }
            ]
          }
        }
      }
    }
    triggers = [
      {
        "metadata" = {
          "type" = "Utilization"
          "value" = "100"
        }
        "type" = "cpu"
      },
    ]
  }
}

variable "minReplicaCount" {
  default = 1
}
variable "maxReplicaCount" {
  default = 1
}

variable "nodepool_selector" {
  default = {}
}

variable "tolerations" {
  default = {}
}

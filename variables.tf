variable "authorized_ips" {
  default = [
    {
      display_name = "Creo WG VPN"
      cidr_block   = "157.230.79.76/32"
    },
    {
      display_name = "Logiq WG VPN"
      cidr_block   = "167.172.101.72/32"
    }
  ]
}

variable "mysql_authorized_ips" {
  default = [
    {
      display_name = "OpenVPN"
      cidr_block   = "178.62.205.237/32"
    },
    {
      display_name = "Diamonds BI"
      cidr_block   = "34.77.212.185/32"
    }
  ]
}

variable "domain" {
  default = "diamondslg.com"
}

variable "k8s" {
  default = {
    machine_type = "n2-standard-2"
  }
}

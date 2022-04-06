terraform {
  required_version = ">= 1"
  backend "gcs" {
    bucket  = "diamonds-terraform-state"
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.4.0"
    }
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.6.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
    mysql = {
      source = "terraform-providers/mysql"
    }
    circleci = {
      source = "mrolla/circleci"
    }
  }
}

# In case of Terraform Cloud project setup this env vars MUST be defined:
# - GOOGLE_CREDENTIALS : Service account key JSON file without line breaks
# - GOOGLE_PROJECT : GCP Project ID
# - GOOGLE_REGION : Preferred region
# - GOOGLE_ZONE : Preferred zone

provider "google" {
  project = "sustained-truck-300419"
  region  = "europe-west3"
  zone    = "europe-west3-a"
}

provider "google-beta" {
  project = "sustained-truck-300419"
  region  = "europe-west3"
  zone    = "europe-west3-a"
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.this.endpoint}"
  token                  = data.google_client_config.this.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.this.endpoint}"
    token                  = data.google_client_config.this.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.this.master_auth.0.cluster_ca_certificate)
  }
}

provider "cloudflare" {
  api_token            = data.google_secret_manager_secret_version.this["cf_api_token"].secret_data
  api_user_service_key = data.google_secret_manager_secret_version.this["cf_api_user_service_key"].secret_data
}

provider "mysql" {
  endpoint = google_sql_database_instance.mysql.public_ip_address
  username = google_sql_user.mysql_root.name
  password = random_password.mysql_root_password.result
}

provider "circleci" {
  api_token    = data.google_secret_manager_secret_version.this["circleci_token"].secret_data
  vcs_type     = "github"
  organization = "AlexShuraits"
}

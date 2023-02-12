terraform {
  required_version = "~> 1.3.7"
  required_providers {
    local  = "~> 2.3.0"
    random = "~> 3.4.3"
    tls    = "~> 4.0.4"

    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.26.0"
    }
  }
}

provider "digitalocean" {
  token = var.token
}

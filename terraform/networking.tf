resource "digitalocean_vpc" "vpc" {
  name   = "k3s-testing"
  region = var.region
}

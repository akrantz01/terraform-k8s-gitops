resource "digitalocean_vpc" "vpc" {
  name   = "k3s-testing"
  region = var.region
}

resource "digitalocean_firewall" "control_plane" {
  name = "k3s-control-plane"

  droplet_ids = [digitalocean_droplet.control_plane.id]

  inbound_rule {
    protocol    = "tcp"
    port_range  = "6443"
    source_tags = ["agent"]
  }

  inbound_rule {
    protocol    = "tcp"
    port_range  = "10250"
    source_tags = ["k3s"]
  }

  inbound_rule {
    protocol    = "udp"
    port_range  = "8472"
    source_tags = ["k3s"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  dynamic "outbound_rule" {
    for_each = ["tcp", "udp"]
    content {
      protocol              = outbound_rule.value
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  }
}

resource "digitalocean_firewall" "agent" {
  name = "k3s-agent"

  droplet_ids = [for droplet in digitalocean_droplet.agent : droplet.id]

  inbound_rule {
    protocol    = "tcp"
    port_range  = "10250"
    source_tags = ["k3s"]
  }

  inbound_rule {
    protocol    = "udp"
    port_range  = "8472"
    source_tags = ["k3s"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  dynamic "outbound_rule" {
    for_each = ["tcp", "udp"]
    content {
      protocol              = outbound_rule.value
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  }
}

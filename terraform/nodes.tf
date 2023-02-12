resource "random_password" "join_token" {
  length = 48

  lower   = true
  upper   = true
  numeric = true
  special = false
}

resource "digitalocean_droplet" "control_plane" {
  name = "control-plane"

  region = var.region
  image  = "debian-11-x64"
  size   = "s-1vcpu-2gb-amd"

  ipv6     = true
  vpc_uuid = digitalocean_vpc.vpc.id

  backups       = false
  monitoring    = false
  droplet_agent = true

  ssh_keys = [digitalocean_ssh_key.ssh.id]

  tags = ["k3s", "control-plane"]

  user_data = templatefile("${path.module}/templates/control-plane.sh", {
    digitalocean_access_token = var.token

    cidr = digitalocean_vpc.vpc.ip_range

    join_token = random_password.join_token.result
  })
}

resource "random_string" "agent_suffix" {
  count = var.agent_count

  length = 8

  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "digitalocean_droplet" "agent" {
  count = var.agent_count

  name = "agent-${random_string.agent_suffix[count.index].result}"

  region = var.region
  image  = "debian-11-x64"
  size   = "s-1vcpu-1gb-amd"

  ipv6     = true
  vpc_uuid = digitalocean_vpc.vpc.id

  backups       = false
  monitoring    = false
  droplet_agent = true

  ssh_keys = [digitalocean_ssh_key.ssh.id]

  tags = ["k3s", "agent"]

  user_data = templatefile("${path.module}/templates/agent.sh", {
    control_plane_ip = digitalocean_droplet.control_plane.ipv4_address_private
    join_token       = random_password.join_token.result
  })
}

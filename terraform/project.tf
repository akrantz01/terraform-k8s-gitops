resource "digitalocean_project" "project" {
  name = "k3s"

  purpose     = "Web Application"
  environment = "Development"
}

resource "digitalocean_project_resources" "control_plane" {
  project = digitalocean_project.project.id

  resources = [
    digitalocean_droplet.control_plane.urn,
  ]
}

resource "digitalocean_project_resources" "agent" {
  project = digitalocean_project.project.id

  resources = [for agent in digitalocean_droplet.agent : agent.urn]
}

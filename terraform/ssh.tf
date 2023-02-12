resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "digitalocean_ssh_key" "ssh" {
  name       = "k3s"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_sensitive_file" "ssh" {
  filename = "key.pem"
  content  = tls_private_key.ssh.private_key_openssh

  file_permission = "0600"
}

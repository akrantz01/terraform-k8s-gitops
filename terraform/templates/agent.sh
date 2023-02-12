#!/usr/bin/env bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y

apt-get install -y apt-transport-https ca-certificates curl gnupg2 lsb-release wget

PRIVATE_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
INSTANCE_ID=$(curl -s http://169.254.169.254/metadata/v1/id)

# Install k3s
curl -sfL https://get.k3s.io | K3S_URL=https://${control_plane_ip}:6443 K3S_TOKEN=${join_token} sh -s - agent --node-ip $PRIVATE_IP --kubelet-arg="provider-id=digitalocean://$INSTANCE_ID" --kubelet-arg="cloud-provider=external"

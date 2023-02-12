#!/usr/bin/env bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y

apt-get install -y apt-transport-https ca-certificates curl gnupg2 lsb-release wget

# Install k3s
curl -sfL https://get.k3s.io | K3S_URL=https://${control_plane_ip}:6443 K3S_TOKEN=${join_token} sh -

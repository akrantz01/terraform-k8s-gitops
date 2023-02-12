#!/usr/bin/env bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y

apt-get install -y apt-transport-https ca-certificates curl gnupg2 jq lsb-release wget

ARCH=$(dpkg --print-architecture)
CODENAME=$(lsb_release -cs)
PRIVATE_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
INSTANCE_ID=$(curl -s http://169.254.169.254/metadata/v1/id)

# Setup PostgreSQL APT repository
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg
echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] https://apt.postgresql.org/pub/repos/apt $CODENAME-pgdg main" > /etc/apt/sources.list.d/postgresql.list

apt-get update

# Install and configure PostgreSQL
apt-get install -y postgresql-15

cat <<EOF > /etc/postgresql/15/main/conf.d/server.conf
listen_addresses = '127.0.0.1,$PRIVATE_IP'
port = 5432

authentication_timeout = 1min
password_encryption = scram-sha-256
EOF
cat <<EOF >> /etc/postgresql/15/main/pg_hba.conf
# Internal network
host    all             all             ${cidr}            scram-sha-256
EOF

systemctl enable postgresql
systemctl restart postgresql

# Add PostgreSQL user for k3s
pg_k3s_password=$(openssl rand -hex 32)
sudo -u postgres createuser \
  --no-superuser \
  --no-createdb \
  --no-createrole \
  k3s
sudo -u postgres psql -c "ALTER USER k3s WITH PASSWORD '$pg_k3s_password';"
sudo -u postgres createdb --owner k3s k3s

# Install k3s
curl -sfL https://get.k3s.io | K3S_TOKEN=${join_token} K3S_DATASTORE_ENDPOINT=postgres://k3s:$pg_k3s_password@127.0.0.1:5432/k3s?sslmode=disable sh -s - server --node-ip $PRIVATE_IP --disable traefik --disable servicelb --disable-cloud-controller --kubelet-arg="provider-id=digitalocean://$INSTANCE_ID" --kubelet-arg="cloud-provider=external"
sleep 15

# Deploy DigitalOcean CCM
mkdir -p /var/lib/rancher/k3s/server/manifests/
cat <<EOF > /var/lib/rancher/k3s/server/manifests/digitalocean-ccm.yaml
${manifest_digitalocean_ccm}
EOF

# Deploy Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install Argo CD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Wait for Argo CD to be ready
until kubectl -n argocd rollout status deployment/argocd-server; do sleep 1; done

# Setup Argo CD
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl config set-context --current --namespace=argocd
argocd login --core

argocd app create apps \
  --dest-namespace argocd \
  --dest-server https://kubernetes.default.svc \
  --repo https://github.com/akrantz01/terraform-k8s-gitops.git \
  --path apps

argocd app sync apps
argocd app sync -l app.kubernetes.io/instance=apps

# Restore default namespace
kubectl config set-context --current --namespace=default

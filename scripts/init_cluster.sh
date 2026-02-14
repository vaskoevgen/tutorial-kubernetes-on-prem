#!/bin/bash
set -e

# This script is meant to be run INSIDE the container

echo "Initializing Kubernetes Cluster..."

# Run the installation script if packages are not installed (redundant if baked in, but good for safety)
if ! command -v kubeadm &> /dev/null; then
    /scripts/install_k8s.sh
fi

# Pull images first
kubeadm config images pull

# Initialize the cluster
# We use --ignore-preflight-errors=all because we are in a container and some checks might fail (like swap, num cpu, etc)
# We set apiserver-advertise-address to the container's IP (or 0.0.0.0)
# Initialize the cluster using the configuration file
# We use --ignore-preflight-errors=all because we are in a container and some checks might fail (like swap, num cpu, etc)
kubeadm init \
  --config /scripts/kubeadm-config.yaml \
  --ignore-preflight-errors=all \
  --v=5

# Set up kubeconfig for root
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Install a Pod Network Add-on (Flannel is simple for this)
# Use the new v1.31 compatible manifest or latest generic one
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Untaint Control Plane (Single Node Mode)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "Cluster initialized successfully!"
echo "You can now use kubectl inside this container."

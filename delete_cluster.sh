#!/bin/bash

echo "Deleting Kubernetes Cluster..."

# Names of the containers
CONTAINERS="k8s-control-plane k8s-node"

# Delete containers
echo "Removing containers: $CONTAINERS"
docker rm -f $CONTAINERS 2>/dev/null || true

# Delete network
NETWORK_NAME="k8s-net"
if docker network ls | grep -q $NETWORK_NAME; then
    echo "Removing network: $NETWORK_NAME"
    docker network rm $NETWORK_NAME
else
    echo "Network $NETWORK_NAME not found or already removed."
fi

# Cleanup kubeconfig
if [ -f "kubeconfig" ]; then
    echo "Removing kubeconfig..."
    rm kubeconfig
fi

echo "Cluster deleted successfully."

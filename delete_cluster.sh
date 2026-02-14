#!/bin/bash

echo "Deleting Kubernetes Cluster..."

# Names of the containers
# Find all containers starting with k8s-
CONTAINERS=$(docker ps -a --filter "name=k8s-" --format "{{.Names}}")

# Delete containers
if [ -n "$CONTAINERS" ]; then
    echo "Removing containers:"
    echo "$CONTAINERS"
    docker rm -f $CONTAINERS
else
    echo "No k8s containers found."
fi

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

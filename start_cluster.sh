#!/bin/bash
set -e

echo "Starting Kubernetes Multi-Node Cluster (v1.31) setup..."

# 0. Create Network
NETWORK_NAME="k8s-net"
if ! docker network ls | grep -q $NETWORK_NAME; then
    echo "Creating network $NETWORK_NAME..."
    docker network create \
      --driver=bridge \
      --subnet=172.22.0.0/16 \
      --gateway=172.22.0.1 \
      $NETWORK_NAME
else
    echo "Network $NETWORK_NAME already exists."
fi

# 1. Build the image
echo "Building image..."
docker build -t tutorial-k8s-node .

# Cleanup old containers and generated files
echo "Cleaning up old containers and generated files..."
docker rm -f k8s-control-plane k8s-node 2>/dev/null || true

# Function to run a node
run_node() {
    local NAME=$1
    local EXTRA_ARGS=$2
    
    echo "Starting $NAME..."
    docker run -d --name $NAME \
        --hostname $NAME \
        --network $NETWORK_NAME \
        --privileged \
        --cgroupns=host \
        -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
        -v /lib/modules:/lib/modules:ro \
        -v /var/lib/containerd \
        -v /var/lib/kubelet \
        -v $(pwd)/scripts:/scripts \
        --tmpfs /run --tmpfs /run/lock \
        -e container=docker \
        --stop-signal SIGRTMIN+3 \
        $EXTRA_ARGS \
        tutorial-k8s-node
}

# 2. Run Control Plane
run_node "k8s-control-plane" "-p 6443:6443"

# 3. initialize Control Plane
echo "Waiting for control plane to be ready..."
sleep 5
echo "Installing K8s on Control Plane..."
docker exec k8s-control-plane /scripts/install_k8s.sh
echo "Initializing Cluster..."
docker exec k8s-control-plane /scripts/init_cluster.sh

echo "Setup complete!"
echo "To access the cluster:"
echo "1. Copy kubeconfig: docker cp k8s-control-plane:/etc/kubernetes/admin.conf ./kubeconfig"
echo "   export KUBECONFIG=$(pwd)/kubeconfig"
echo "   (Note: You might need to edit kubeconfig if connecting from outside, but mapped port 6443 should work for localhost)"

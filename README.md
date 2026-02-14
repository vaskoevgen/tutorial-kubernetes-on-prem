# Multi-Node Kubernetes on-prem via Docker (Tutorial)

This project demonstrates how to set up a **Multi-Node Kubernetes Cluster (v1.35)** using `kubeadm` inside Docker containers.

**Default Configuration:**
- **1 Control Plane Node** (Untainted to run workloads)
- **CNI Plugin (Flannel)**

## Prerequisites

- **Docker**: You must have Docker installed and running.
- **Root/Sudo privileges**: Required to run privileged containers.
- **Resources**: Ensure you have enough RAM (4GB+ recommended).

## Project Structure

- `Dockerfile`: shared base image (Ubuntu 22.04 + systemd).
- `scripts/`:
    - `install_k8s.sh`: Installs K8s v1.35 components.
    - `init_cluster.sh`: Initializes Control Plane.
- `start_cluster.sh`: **Main entry point**. Sets up network, containers, and runs the cluster.
- `delete_cluster.sh`: **Cleanup script**. Removes containers and network.
- `.gitignore`: Configured to ignore generated tokens and secrets.

## Quick Start

1.  **Clone this repository**.
2.  **Make scripts executable**:
    ```bash
    chmod +x start_cluster.sh delete_cluster.sh scripts/*.sh
    ```
3.  **Run the setup**:
    ```bash
    ./start_cluster.sh
    ```

    This will:
    - Create a Docker network (`k8s-net`).
    - Launch `k8s-control-plane`.
    - Install Kubernetes v1.35.
    - Initialize the cluster.

## Interacting with the Cluster

### Option 1: From inside Control Plane (Recommended)
This is the most reliable method as it runs inside the cluster network.
```bash
docker exec -it k8s-control-plane /bin/bash
# Then inside the container:
kubectl get nodes
```

### Option 2: From Host Machine (Local)
*Note: This might require network troubleshooting depending on your host's Docker configuration.*

1. Copy the kubeconfig:
   ```bash
   docker cp k8s-control-plane:/etc/kubernetes/admin.conf ./kubeconfig
   export KUBECONFIG=$(pwd)/kubeconfig
   ```

2. **Fix Server Address**: The kubeconfig uses the container IP by default. You must change it to `localhost` to use the mapped port:
   ```bash
   sed -i 's/172.22.0.[0-9]\+/localhost/g' ./kubeconfig
   ```

3. Check nodes:
   ```bash
   kubectl get nodes
   ```

**Expected Output:**
```
NAME                STATUS   ROLES           AGE   VERSION
k8s-control-plane   Ready    control-plane   2m    v1.31.14
```


## Deleting the Cluster

To stop and remove all cluster nodes and the associated network:

1.  **Run the cleanup script**:
    ```bash
    ./delete_cluster.sh
    ```
    This will remove the container (`k8s-control-plane`), delete the `k8s-net` Docker network, and remove the local `kubeconfig` file.

## Troubleshooting

- **Network Conflicts**: The script uses subnet `172.22.0.0/16`. If this conflicts, edit `start_cluster.sh` to change it.
- **Systemd/Cgroup**: Use a modern Docker version. The script sets `--cgroupns=host` which works for cgroup v2 hosts.
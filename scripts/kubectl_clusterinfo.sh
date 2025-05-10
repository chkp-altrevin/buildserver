#!/bin/bash
# Define variables
K3D_CLUSTER="k3d-demo-cluster"
KUBE_CONFIG="$HOME/.kube/config"

# Deploy Cluster --api-port 6550
# export K3D_FIX_DNS=1 && k3d cluster create k3d-demo-cluster --servers 1 --agents 3 -p "8280:80@loadbalancer" -p "8243:443@loadbalancer"
kubectl cluster-info

# Print completion message
echo "$K3D_CLUSTER cluster info. Kube config located $KUBE_CONFIG."

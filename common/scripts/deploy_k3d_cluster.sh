#!/bin/bash
# Define variables
K3D_CLUSTER="k3d-demo-cluster"
KUBE_CONFIG="$HOME/.kube/config"

# Deploy Cluster --api-port 6550 --subnet 172.28.0.0/16
# export K3D_FIX_DNS=1 && k3d cluster create k3d-demo-cluster --servers 1 --agents 3 --subnet 192.168.56.0/24 --api-port 6550 -p "8280:80@loadbalancer" -p "8243:443@loadbalancer"
export K3D_FIX_DNS=1 && k3d cluster create k3d-demo-cluster -v /dev/mapper:/dev/mapper --servers 1 --agents 3 --api-port 6550 -p "8280:80@loadbalancer" -p "8243:443@loadbalancer"
kubectl create namespace demoapps
# Print completion message
echo "$K3D_CLUSTER created. Kube config copied from $KUBE_CONFIG. Namespace demoapps created"

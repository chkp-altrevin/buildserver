#!/bin/bash
# Define variables
K3D_CLUSTER="k3d-demo-cluster"
KUBE_CONFIG="/home/vagrant/.kube/config"

# Deploy Cluster no loadbalancer
# export K3D_FIX_DNS=1 && k3d cluster create k3d-demo-cluster --servers 1 --agents 3
export K3D_FIX_DNS=1 && k3d cluster create k3d-demo-cluster -v /dev/mapper:/dev/mapper --servers 1 --agents 3
#
# Print completion message
echo "$K3D_CLUSTER created. Kube config copied from $KUBE_CONFIG."

#!/bin/bash
# Define variables
K3D_CLUSTER="k3d-demo-cluster"
#KUBE_CONFIG="/var/k3d/.kube/config"
#USER="vagrant"
#GROUP="vagrant"

# Remove Cluster
k3d cluster delete k3d-demo-cluster

# Create the destination directory
#mkdir -p "$DEST_DIR"

# Copy the contents of the /vagrant directory to the destination directory
#cp -r "$SOURCE_DIR"/* "$DEST_DIR"

# Change ownership and group of the copied files
#chown -R "$USER:$GROUP" "$DEST_DIR"

# fix those just in case
#find "$DEST_DIR" -type f -name "*.sh" -exec dos2unix  \;

# Find all .sh files in the destination directory and set executable permissions
#find "$DEST_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Print completion message
echo "$K3D_CLUSTER" removed.

#!/bin/bash -x
# Note this script stores the k3s data into $(pwd)/rancher-data, this way it is possible to stop the docker
# container and resume again (I never do that though, it tends to be tricky, it is a brute force approach).
# With #such a rancher deployment I can follow the quick start guide of Elemental. For command line usage I
# download #the ~/.kube/config file for the local cluster from the UI.
set -e

: ${RANCHER_VERSION=v2.9.3}

id=$(docker run --rm \
    -v $(pwd)/rancher-data:/var/lib/rancher \
    -v /usr/share/pki/trust/anchors:/usr/share/pki/trust/anchors \
    -v /usr/share/pki/trust/anchors:/container/certs \
    -e SSL_CERT_DIR="/container/certs" \
    -d -p 80:80 -p 443:443 -p 6443:6443 --privileged "rancher/rancher:${RANCHER_VERSION}")

# If there is already previous k3s data assume it reuses a previous deployment
if [ ! -e "$(pwd)/rancher-data/k3s" ]; then

  # Give sometime to bootstrap
  sleep 90

  # For convenience keep default password to a file
  docker logs ${id}  2>&1 | grep "Bootstrap Password:" > inital-passwd
else
  sleep 60
fi
Enter file contents here

#!/bin/bash -x
# Note this script stores the k3s data into $(pwd)/rancher-data, this way it is possible to stop the docker
# container and resume again. For command line usage I
# download #the ~/.kube/config file for the local cluster from the UI.
# moved the config folders below the repo so it isnt part of a workflow
set -e
: ${RANCHER_VERSION=v2.10.0}
id=$(docker run -d \
    -v $HOME/rancher-data:/var/lib/rancher \
    -e SSL_CERT_DIR="/container/certs" \
    -d -p 8080:80 -p 8443:443 -p 6443:6443  --restart unless-stopped --name rancher-ui --privileged "rancher/rancher:${RANCHER_VERSION}")
# If there is already previous k3s data assume it reuses a previous deployment
if [ ! -e "$HOME/rancher-data/k3s" ]; then
  # Give sometime to bootstrap
  sleep 90
  # For convenience keep default password to a file using handy docker filter script and values
  docker logs ${id}  2>&1 | grep "Bootstrap Password:" > $HOME/initial-passwd
  # $PROJECT_PATH/scripts/filter_docker.sh logs rancher-ui "Bootstrap Password:" > $HOME/initial-passwd
else
  sleep 60
fi

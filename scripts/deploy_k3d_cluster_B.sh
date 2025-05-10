# optional additional easy to use clusters
export K3D_FIX_DNS=1 && k3d cluster create k3d-demo-B-cluster -v /dev/mapper:/dev/mapper --servers 1 --agents 3 --api-port 6551 -p "8281:80@loadbalancer" -p "8244:443@loadbalancer"

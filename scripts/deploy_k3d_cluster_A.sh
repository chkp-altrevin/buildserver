# optional additional easy to use clusters
export K3D_FIX_DNS=1 && k3d cluster create k3d-demo-A-cluster -v /dev/mapper:/dev/mapper --servers 1 --agents 3 --api-port 6550 -p "8280:80@loadbalancer" -p "8243:443@loadbalancer"

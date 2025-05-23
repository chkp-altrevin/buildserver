echo "restarting.."
docker restart $(docker ps -a | grep "rancher/rancher" | awk '{ print $1 }')

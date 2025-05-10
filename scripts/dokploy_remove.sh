docker ps -a | grep "dokploy" | awk '{print $1}' | xargs docker rm -f && docker rmi -f
docker swarm leave --force

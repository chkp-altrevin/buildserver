# docker stop rancher/rancher || true && docker rm rancher/rancher || true
docker ps -a | grep "rancher/rancher" | awk '{print $1}' | xargs docker rm -f
# uncomment below to clean up all rancher folder and configs essentially a reset
# sudo rm -rf /home/vagrant/rancher-data
# rm $HOME/initial-passwd
sudo rm -rf $HOME/rancher-data $HOME/initial-passwd

#!/bin/bash

# wip to be generic setup
PROJECT_ZIP="$HOME/diy-devsec-lab-main.zip"
TEMP_DIR="$HOME/temp"
PROJECT_DIR="$HOME/diy-devsec-lab"
mkdir $TEMP_DIR
mkdir $PROJECT_DIR
mkdir $HOME/.kube
# apt install unzip
sudo apt install unzip -y
echo "kubeconfig folder check"
# Unzip the downloaded file into the target directory
unzip -o -a "$PROJECT_ZIP" -d "$TEMP_DIR"
mv $TEMP_DIR/diy-devsec-lab-main/* $PROJECT_DIR
echo "Extract and project files setup succesfully"
# Change permissions to make .sh files executable
find "$PROJECT_DIR" -name "*.sh" -exec chmod +x {} \;
#
rm -rf $TEMP_DIR
echo "Clean up removing temp folder"
#
echo "Download, unzip, and permission setting completed successfully."
# you will need to use sudo to complete this
sudo mv $HOME/diy-devsec-lab/profile/bash_aliases $HOME/.bash_aliases
sudo mv $HOME/diy-devsec-lab/profile/env.example $HOME/.env
echo "bash_alias and env copied sucessfully."
#
# assigning ownership and permissions to the local user
sudo chgrp -R $USER $HOME
sudo chown -R $USER $HOME
echo "Changing ownership and group to user successfully."

# if you want to modify these to something you like just make sure to set ext dns ifyou want to use outside of the host
# sudo hostnamectl set-hostname buildsever
# sudo -- sh -c "echo '192.168.56.10  rancher.diydevsec.local' >> /etc/hosts"
# sudo -- sh -c "echo '192.168.56.10  waf.diydevsec.local' >> /etc/hosts"
# sudo -- sh -c "echo '192.168.56.10  api.diydevsec.local' >> /etc/hosts"
# sudo -- sh -c "echo '192.168.56.10  buildserver.diydevsec.local' >> /etc/hosts"
#
wget -qO- https://github.com/SpectralOps/preflight/releases/download/v1.1.5/preflight_1.1.5_Linux_x86_64.tar.gz | tar xvz -C /usr/local/bin  -o preflight
# pull down latest spectral- dont forget to setup dsn either in env or manually
curl -L 'https://spectral-us.dome9.com/latest/x/sh'| sh
sudo cp $HOME/.spectral/spectral /usr/local/bin
echo "Spectral setup completed successfully."
#
# setting up docker using the install script
sudo ./install_docker.sh
# adding our local user to docker group
#
sudo usermod -aG docker $USER
echo "added user to docker group successfully."
# helm install
sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
echo "Helm installed successfully."
#
# install bitnami chart
helm repo add bitnami https://charts.bitnami.com/bitnami
echo "Adding bitnami chart successfully."
# pulling down shiftleft remember to set env vars either manually or in env
sudo cp $HOME/diy-devsec-lab/profile/bin/shiftleft /usr/local/bin
echo "Shiftleft setup completed successfully."
# installing k3d for demo cluster deploy on docker or other usecases
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
#
echo "K3D setup completed successfully."
# setting up the source for kubectl so we can use in apt
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
echo "Kubectl setup completed successfully."
# cleanup and updates
sudo usermod -aG docker $USER
sudo rm ./get_helm.sh
sudo rm ./get-docker.sh
sudo apt-get update
sudo apt-get upgrade -y
sudo apt install dos2unix build-essential git net-tools apt-transport-https unzip ca-certificates curl gnupg software-properties-common docker-compose-plugin kubectl -y
echo "Packages installed and updated successfully, restarting bash"
bash
$PROJECT_DIR/menu/setup_menu2.sh
# a docker image is used throughout however uncomment to have full zap installed-rember to add apt install default-jre
# sudo curl -fsSL https://github.com/zaproxy/zaproxy/releases/download/v2.15.0/ZAP_2_15_0_unix.sh -o ZAP_2_15_0_unix.sh
# sudo sh ./ZAP_2_15_0_unix.sh -q
# sudo rm $HOME/ZAP_2_15_0_unix.sh

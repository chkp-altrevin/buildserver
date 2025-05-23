#!/bin/bash

# install webmin repo
curl -o webmin-setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repos.sh
sudo sh webmin-setup-repos.sh -f
sudo apt install webmin -y

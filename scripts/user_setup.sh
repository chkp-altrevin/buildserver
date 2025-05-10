#!/bin/bash
if [ $# -ne 1 ]; then
  echo "Usage: $0 <username>"
  exit 1
fi
username="$1"
# Create the user
sudo adduser "$username"
# Add the user to the sudo group
sudo usermod -aG sudo "$username"
echo "User '$username' created with sudo privileges."

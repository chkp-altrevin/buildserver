#!/bin/bash
# echo 'export source /home/vagrant/.env' >> /home/vagrant/.bashrc
# Command to add to .bashrc
# command_to_add="alias ll='ls -alF'"
command_to_add="source $HOME/.env"

# Append the command to .bashrc
echo "$command_to_add" >> ~/.bashrc

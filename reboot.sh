#!/usr/bin/env bash
# ==============================================================================
# Buildserver Environment Setup Script (Continued)
# no need to modify only needed for vagrant virtualbox deployments
# ==============================================================================
#
# project path allows for summarizing eror logs to the host
# export PROJECT_PATH="/home/vagrant/buildserver"
# export VAGRANT_USER_PATH="/home/vagrant"
#
# ----- Logging Functions -----------------------------------------------------
#log_info() {
#  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
#  echo "[$timestamp] [INFO] $1" >> $PROJECT_PATH/provisioning.log
#}

#log_success() {
#  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
#  echo "[$timestamp] [SUCCESS] $1" >> $PROJECT_PATH/provisioning.log
#}

#log_error() {
#  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
#  echo "[$timestamp] [ERROR] $1" >> $PROJECT_PATH/provisioning.log
#}
sleep 10
echo "Provisioning Complete. You can continue to login using: vagrant ssh"

#!/bin/bash
# <UDF name="username" Label="New User Name" />
# <UDF name="userpass" Label="New User Password" />
# <UDF name="userpubkey" Label="SSH Key" />
source <ssinclude StackScriptID="1">
system_update 
user_add_sudo "$USERNAME" "$USERPASS"
user_add_pubkey "$USERNAME" "$USERPUBKEY"
# Disable Root Access 
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
# Disable Password Authentication 
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
#Adds ssh to restart list 
touch /tmp/restart-ssh
restartServices

#!/bin/bash

# Function to display the menu outside of vagrant
display_menu() {
    clear
    echo "=== Use "x" to go back =========== APPLICATION MENU"
    echo "d. Running Containers |   k. Cluster Status        "
    echo "                                                   "
    echo "V. Provision | x. Verify | x. License | x. Reset   "
    echo "==================================================="
    echo ""
    echo "RANCHER============================================"
    echo "D. Deploy  | o. OTP   | r. Verify | R. Remove      "
    echo ""
    echo "DOKPLOY============================================"
    echo "E. Deploy             | s. Verify | S. Remove      "
    echo "==================================================="
    echo ""
    echo "NGINX PROXY MANAGER ==============================="
    echo "N. Deploy             | p. Verify | F. Remove      "
    echo "==================================================="
    echo ""
    echo "PASSWORD MANAGER MENU ============================="
    echo "P. Setup  *wip                                     "
    echo "==================================================="
    echo -n "choose an option [1-9,a-z]: (x)  Exit "
}
# Global variable to store the custom script path
# CUSTOM_SCRIPT_PATH="$HOME/buildserver/scripts"
#

# Function to install Nginx Proxy Manager
npm_install() {
    local script_path="$HOME/buildserver/scripts/npm_install.sh"
    if [ -f "$script_path" ]; then
        echo "Installing Nginx Proxy Manager using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to show Nginx Proxy Manager status
npm_status() {
    local script_path="$HOME/buildserver/scripts/npm_status.sh"
    if [ -f "$script_path" ]; then
        echo "Nginx Proxy Manager status using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to remove Nginx Proxy Manager
npm_remove() {
    local script_path="$HOME/buildserver/scripts/npm_remove.sh"
    if [ -f "$script_path" ]; then
        echo "Removing Nginx Proxy Manager using $script_path"
        sudo bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}


# Function to call virtualbox provisioning menu
virtualbox_menu() {
    local script_path="$HOME/buildserver/menu/virtualbox_menu.sh"
    if [ -f "$script_path" ]; then
        echo "VirtualBox Provisioning using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to call pass menu
pass_menu() {
    local script_path="$HOME/buildserver/menu/pass_setup.sh"
    if [ -f "$script_path" ]; then
        echo "Pass Setup using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to deploy openappsec join the waf cause
deploy_open_appsec() {
    local script_path="$HOME/buildserver/scripts/deploy_open_appsec.sh"
    if [ -f "$script_path" ]; then
        echo "Deploying OpenAppsec using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to remove dokploy
dokploy_remove() {
    local script_path="$HOME/buildserver/scripts/dokploy_remove.sh"
    if [ -f "$script_path" ]; then
        echo "Removing Dokploy using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to show dokploy status
dokploy_status() {
    local script_path="$HOME/buildserver/scripts/dokploy_status.sh"
    if [ -f "$script_path" ]; then
        echo "Dokploy status using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to install dokploy
dokploy_custom_install() {
    local script_path="$HOME/buildserver/scripts/dokploy_custom_install.sh"
    if [ -f "$script_path" ]; then
        echo "Deploying Dokploy using $script_path"
        sudo bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to restart rancher
restart_rancher() {
    local script_path="$HOME/buildserver/scripts/restart_rancher.sh"
    if [ -f "$script_path" ]; then
        echo "Restarting Rancher using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to remove Harbor
remove_harbor() {
    local script_path="$HOME/buildserver/scripts/remove_harbor.sh"
    if [ -f "$script_path" ]; then
        echo "Removing Harbor using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to deploy Harbor
deploy_harbor() {
    local script_path="$HOME/buildserver/scripts/deploy_harbor.sh"
    if [ -f "$script_path" ]; then
        echo "Deploying Harbor using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to deploy Rancher
deploy_rancher() {
    local script_path="$HOME/buildserver/scripts/deploy_rancher2.sh"
    if [ -f "$script_path" ]; then
        echo "Deploying Rancher using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to grab rancher otp token
rancher_initial() {
    local script_path="$HOME/buildserver/scripts/rancher_initial.sh"
    if [ -f "$script_path" ]; then
        echo "OTP presented using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to remove Rancher remove Data
remove_rancher() {
    local script_path="$HOME/buildserver/scripts/remove_rancher.sh"
    if [ -f "$script_path" ]; then
        echo "Removing Rancher using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to verify Rancher is running
rancher_status() {
    local script_path="$HOME/buildserver/scripts/rancher_status.sh"
    if [ -f "$script_path" ]; then
        echo "Rancher Status using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to restart Rancher no harm to data
restart_rancher() {
    local script_path="$HOME/buildserver/scripts/deploy_rancher2.sh"
    if [ -f "$script_path" ]; then
        echo "Deploying Rancher using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
#
#
# Function to check docker status
docker_status() {
    local script_path="$HOME/buildserver/scripts/docker_status.sh"
    if [ -f "$script_path" ]; then
        echo "Docker Status using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# docker ps
docker_ps() {
    local script_path="$HOME/buildserver/scripts/docker_ps.sh"
    if [ -f "$script_path" ]; then
        echo "Docker Running Containers using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
#
# Function to run top
top_run() {
    local script_path="$HOME/buildserver/scripts/top_run.sh"
    if [ -f "$script_path" ]; then
        echo "Top using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to check docker info
docker_info() {
    local script_path="$HOME/buildserver/scripts/docker_info.sh"
    if [ -f "$script_path" ]; then
        echo "Docker info using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}

# Function to check rancher status
rancher_status() {
    local script_path="$HOME/buildserver/scripts/rancher_status.sh"
    if [ -f "$script_path" ]; then
        echo "Rancher Status using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to update packages
package_updates() {
    local script_path="$HOME/buildserver/scripts/package_updates.sh"
    if [ -f "$script_path" ]; then
        echo "Package updates using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to setup env vars
setup_env_vars() {
    local script_path="$HOME/buildserver/scripts/setup_env_vars.sh"
    if [ -f "$script_path" ]; then
        echo "Edit using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to apply env vars
export_env() {
    local script_path="$HOME/buildserver/scripts/export_env.sh"
    if [ -f "$script_path" ]; then
        echo "Backuping up ENV VARS using $script_path"
        echo "location c:\buildserver\profile\backup.env"
        bash "$script_path"
    else
        echo "Env Vars script does not exist at $script_path."
    fi
    pause
}
# Function to pause the script and wait for user input
pause() {
    echo -n "Press any key to continue..."
    read -n 1
}
# Main loop to display the menu and process user input
while true; do
    display_menu
    read choice
    case $choice in
        a) ;;
        b) ;;
        c) ;;
        d) docker_ps ;;
        e) ;;
        f) ;;
        g) ;;
        h) ;;
        i) ;;
        j) ;;
        k) ;;
        l) ;;
        m) ;;
        n) ;;
        o) rancher_initial ;;
        p) npm_status ;;
        q) ;;
        r) rancher_status ;;
        s) dokploy_status ;;
        t) ;;
        u) ;;
        v) ;;
        w) ;;
        y) ;;
        z) ;;
        1) ;;
        2) ;;
        3) ;;
        4) ;;
        5) ;;
        6) ;;
        7) ;;
        8) ;;
        9) ;;
        A) ;;
        B) ;;
        C) ;;
        D) deploy_rancher ;;
        E) dokploy_custom_install ;;
        F) npm_remove ;;
        J) ;;
        K) ;;
        L) ;;
        N) npm_install ;;
        P) pass_menu ;;
        Q) ;;
        R) remove_rancher ;;
        S) dokploy_remove ;;
        T) ;;
        U) ;;
        V) virtualbox_menu ;;
        W) ;;
        Y) ;;
        x) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please try again."; pause ;;
    esac
done

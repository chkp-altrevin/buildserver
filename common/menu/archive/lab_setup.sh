#!/bin/bash

# Function to display the menu outside of vagrant
display_menu() {
    clear
    echo "                                     LAB SETUP MENU"
    echo "SETUP ENV VARS====================================="
    echo "1. EDIT 2. BACKUP 3. IMPORT 4. RESET  |   x. renv  "
    echo "==================================================="
    echo "                                                   "
    echo "PACKAGE UPDATES-OS RELATED========================="
    echo "x. motd   |     U. Update | t. Top  "
    echo "KUBERNETES MENU===================================="
    echo "a. Cluster Status        | I. Install Cluster      "
    echo "p. Kubectl Get All Pods  | k. Kubectl Cluster-Info "
    echo "n. Kubectl Get Nodes     | R. Remove Cluster       "
    echo "==================================================="
    echo "7. CGNS DEPLOY MENU      |                         "
    echo "8. MANAGE APPLICATIONS   | 9. MANAGE DEMO APPS     "
    echo "==================================================="
    echo "DOCKER HEALTH/STATUS==============================="
    echo "s. Docker Stat  | i. Docker Info    | d. Docker PS "
    echo "==================================================="
    echo -n "choose an option [1-9,a-z]: (x)  Exit "
}
# Global variable to store the custom project path
# Dont modify unless you plan to use outside of Vagrant and VirtualBox
# =============================================
export PROJECT_PATH="/home/vagrant/buildserver"
# =============================================
# Function to manage cgns deployments
run_motd() {
    local script_path="$PROJECT_PATH/menu/run_motd.sh"
    if [ -f "$script_path" ]; then
        echo "Re running motd using $script_path"
        bash "$script_path"
    else
        echo "Failed Deployment script does not exist at $script_path."
    fi
    pause
}
cgns_menu() {
    local script_path="$PROJECT_PATH/menu/cgns_menu.sh"
    if [ -f "$script_path" ]; then
        echo "Launching CGNS Menu using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}

# Function to manage applications
manage_applications() {
    local script_path="$PROJECT_PATH/menu/import_backup.sh"
    if [ -f "$script_path" ]; then
        echo "Importing Backup Env Vars using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}

# Function to open demo menu
demo_menu() {
    local script_path="$PROJECT_PATH/menu/demo_menu.sh"
    if [ -f "$script_path" ]; then
        echo "Opening Demo Menu using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}

# Function to open app menu
app_menu() {
    local script_path="$PROJECT_PATH/menu/app_menu.sh"
    if [ -f "$script_path" ]; then
        echo "Opening App Menu using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to setup env vars
setup_env_vars() {
    local script_path="$PROJECT_PATH/scripts/setup_env_vars.sh"
    if [ -f "$script_path" ]; then
        echo "Edit using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to import env backups
import_env() {
    local script_path="$PROJECT_PATH/scripts/import_env.sh"
    if [ -f "$script_path" ]; then
        echo "Looking for $PROJECT_PATH/profile/backup.env using $script_path"
        bash "$script_path"
    else
        echo "$PROJECT_PATH/profile/backup.env does not exist at $script_path."
    fi
    pause
}

# Function to reset env
reset_env() {
    local script_path="$PROJECT_PATH/scripts/reset_env.sh"
    if [ -f "$script_path" ]; then
        echo "Resetting Env Vars using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to export env vars
export_env() {
    local script_path="$PROJECT_PATH/scripts/export_env.sh"
    if [ -f "$script_path" ]; then
        echo "Backuping up ENV VARS using $script_path"
        echo "location c:\(project-path)\profile\backup.env"
        bash "$script_path"
    else
        echo "Env Vars script does not exist at $script_path."
    fi
    pause
}
# Function to deploy Kubernetes Cluster
deploy_kubernetes_cluster() {
    local script_path="$PROJECT_PATH/scripts/deploy_k3d_cluster.sh"
    if [ -f "$script_path" ]; then
        echo "Deploying Kubernetes Cluster with LB using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to remove Kubernetes Cluster
remove_kubernetes_cluster() {
    local script_path="$PROJECT_PATH/scripts/delete_k3d_cluster.sh"
    if [ -f "$script_path" ]; then
        echo "Deleting K3D Demo Cluster using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to check k3d cluster status
k3d_clusterinfo() {
    local script_path="$PROJECT_PATH/scripts/k3d_clusterinfo.sh"
    if [ -f "$script_path" ]; then
        echo "Kubernetes Cluster Status using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to run kubectl cluster-info
kubectl_clusterinfo() {
    local script_path="$PROJECT_PATH/scripts/kubectl_clusterinfo.sh"
    if [ -f "$script_path" ]; then
        echo "kubectl cluster-info using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to check docker status
docker_status() {
    local script_path="$PROJECT_PATH/scripts/docker_status.sh"
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
    local script_path="$PROJECT_PATH/scripts/docker_ps.sh"
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
    local script_path="$PROJECT_PATH/scripts/top_run.sh"
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
    local script_path="$PROJECT_PATH/scripts/docker_info.sh"
    if [ -f "$script_path" ]; then
        echo "Docker info using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}

# Function to run kubectl cluster-info
kubectl_clusterinfo() {
    local script_path="$PROJECT_PATH/scripts/kubectl_clusterinfo.sh"
    if [ -f "$script_path" ]; then
        echo "Kubectl cluster-info using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}

# Function to run kubectl get nodes
kubectl_get_nodes() {
    local script_path="$PROJECT_PATH/scripts/kubectl_get_nodes.sh"
    if [ -f "$script_path" ]; then
        echo "Getting Nodes using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to run kubectl get pods all
kubectl_get_podsall() {
    local script_path="$PROJECT_PATH/scripts/kubectl_get_podsall.sh"
    if [ -f "$script_path" ]; then
        echo "Getting Nodes using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to update packages
package_updates() {
    local script_path="$PROJECT_PATH/scripts/package_updates.sh"
    if [ -f "$script_path" ]; then
        echo "Package updates using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
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
        a) k3d_clusterinfo ;;
        b) ;;
        c) ;;
        d) docker_ps ;;
        e) ;;
        f) ;;
        g) ;;
        h) ;;
        i) docker_info ;;
        j) ;;
        k) kubectl_clusterinfo ;;
        l) ;;
        m) ;;
        n) kubectl_get_nodes ;;
        o) ;;
        p) kubectl_get_podsall ;;
        q) ;;
        r) ;;
        s) docker_status ;;
        t) top_run ;;
        u) ;;
        v) ;;
        w) ;;
        y) ;;
        z) ;;
        1) setup_env_vars ;;
        2) export_env ;;
        3) import_env ;;
        4) reset_env ;;
        5) ;;
        6) ;;
        7) cgns_menu ;;
        8) app_menu ;;
        9) demo_menu ;;
        A) ;;
        B) ;;
        C) ;;
        D) ;;
        E) ;;
        F) ;;
        I) deploy_kubernetes_cluster ;;
        J) ;;
        K) ;;
        L) ;;
        N) ;;
        P) ;;
        Q) ;;
        R) remove_kubernetes_cluster ;;
        S) ;;
        T) ;;
        U) package_updates ;;
        V) verify ;;
        W) ;;
        Y) ;;
        x) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please try again."; pause ;;
    esac
done

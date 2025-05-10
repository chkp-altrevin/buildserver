#!/bin/bash

# Function to display the menu outside of vagrant
display_menu() {
    clear
    echo "> Setup Password Store"
    echo "============================================"
    echo "p. Set PassPhrase | a. Initialize | d. List "
    echo "b. Backup | c. Remove all Keys" 
    echo ">>>>>>>>>>>>> Pass Inserts <<<<<<<<<<<<<<<<<"
    echo "j. Spectral | k. Shiftleft | l. k8sOnboard  "
    echo "============================================"
    echo -n "choose an option [1-9,a-z]: (x)  Exit "
}
# Global variable to store the custom script path, dont modify unless
# you are using outside of Vagrant and VirtualBox deployment
# =============================================
export PROJECT_PATH="/home/vagrant/buildserver"
# =============================================
# Function to set PassPhrase
pass_change() {
    local script_path="$PROJECT_PATH/scripts/pass_change.sh"
    if [ -f "$script_path" ]; then
        echo "Setting PassPhrase using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to set spectral into password stores
pass_spectral() {
    local script_path="$PROJECT_PATH/scripts/pass_spectral.sh"
    if [ -f "$script_path" ]; then
        echo "Setting spectral password using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to show password stores
show_pass() {
    local script_path="$PROJECT_PATH/scripts/show_pass.sh"
    if [ -f "$script_path" ]; then
        echo "Showing password store using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to init pass
init_pass() {
    local script_path="$PROJECT_PATH/scripts/init2_pass.sh"
    if [ -f "$script_path" ]; then
        echo "Initializing pass using $script_path"
        bash "$script_path"
    else
        echo "Deployment script does not exist at $script_path."
    fi
    pause
}
# Function to backup pass
backup_pass() {
    local script_path="$PROJECT_PATH/scripts/backup_pass.sh"
    if [ -f "$script_path" ]; then
        echo "Testing Pass using $script_path"
        bash "$script_path"
    else
        echo "Env Vars script does not exist at $script_path."
    fi
    pause
}
# Function to reset pass
reset_pass() {
    local script_path="$PROJECT_PATH/scripts/reset_pass.sh"
    if [ -f "$script_path" ]; then
        echo "Resetting Pass using $script_path"
        bash "$script_path"
    else
        echo "Env Vars script does not exist at $script_path."
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
# Function to pause the script and wait for user input
pause() {
    echo -n "Press any key to go back"
    read -n 1
}
# Main loop to display the menu and process user input
while true; do
    display_menu
    read choice
    case $choice in
        a) init_pass ;;
        b) backup_pass ;;
        c) reset_pass ;;
        d) show_pass ;;
        e) setup_env_vars ;;
        f) test_env_vars ;;
        g) source_env_vars ;;
        h) reset_env_vars ;;
        i) ;;
        j) pass_spectral ;;
        k) pass_shiftleft ;;
        l) pass_k8sonboard ;;
        m) ;;
        n) ;;
        o) ;;
        p) pass_change ;;
        q) ;;
        r) ;;
        s) ;;
        t) ;;
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
        x) echo "Exiting..."; exit 0 ;;
        z) zap_scan ;;
        *) echo "Invalid option. Please try again."; pause ;;
    esac
done

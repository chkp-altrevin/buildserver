#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo." >&2
    exit 1
fi

# Define necessary packages
REQUIRED_PKGS=(build-essential git curl wget pkg-config apt-transport-https unzip gnupg software-properties-common)

# Check for required packages and install if missing
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -l | grep -q "${pkg}"; then
        echo "Missing package: ${pkg}. Installing..."
        apt update && apt install -y "$pkg"
    fi
done

# Parse command-line arguments
PROVISION_FILE=""
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --help)
            echo "Usage: $0 [--provisioning-file <file>]"
            exit 0
            ;;
        --provisioning-file)
            PROVISION_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Load provisioning file if provided
if [[ -n "$PROVISION_FILE" && -f "$PROVISION_FILE" ]]; then
    echo "Loading provisioning file: $PROVISION_FILE"
    source "$PROVISION_FILE"
fi

# Create the graphical menu
while true; do
    CHOICE=$(dialog --clear --stdout --title "Server Installer" \
        --menu "Select an option" 20 50 10 \
        1 "System Setup" \
        2 "Install Packages" \
        3 "Install Applications" \
        4 "Exit")

    case $CHOICE in
        1)
            while true; do
                SYS_CHOICE=$(dialog --clear --stdout --title "System Setup" \
                    --menu "Select an action" 20 60 10 \
                    1 "Toggle Theme" \
                    2 "Run System Updates" \
                    3 "Edit Env File" \
                    4 "Import Custom Env" \
                    5 "Reset Env File" \
                    6 "Run top" \
                    7 "Install Aliases" \
                    8 "Back")
                case $SYS_CHOICE in
                    1)
                        dialog --msgbox "Theme toggle not implemented yet." 10 40
                        ;;
                    2)
                        apt update && apt upgrade -y | tee >(dialog --title "System Update" --programbox 20 80)
                        ;;
                    3)
                        vi "$HOME/.env"
                        ;;
                    4)
                        dialog --inputbox "Enter path to env file:" 10 40 2> /tmp/env_path
                        ENV_PATH=$(cat /tmp/env_path)
                        if [[ -f "$ENV_PATH" ]]; then
                            cp "$ENV_PATH" "$HOME/.env"
                            dialog --msgbox "Environment file imported successfully." 10 40
                        else
                            dialog --msgbox "Invalid file path." 10 40
                        fi
                        ;;
                    5)
                        cp example.env "$HOME/.env"
                        dialog --msgbox "Environment file reset successfully." 10 40
                        ;;
                    6)
                        top
                        ;;
                    7)
                        echo "alias setup-menu='$PROJECT_PATH/menu/setup_menu.sh'" >> "$HOME/.bash_aliases"
                        dialog --msgbox "Aliases installed successfully." 10 40
                        ;;
                    8)
                        break
                        ;;
                esac
            done
            ;;
        2)
            while true; do
                PKG_CHOICE=$(dialog --clear --stdout --title "Install Packages" \
                    --menu "Select an option" 20 60 10 \
                    1 "Install Common" \
                    2 "Install Custom" \
                    3 "Back")
                case $PKG_CHOICE in
                    1)
                        apt install -y terraform google-cloud-cli pass powershell azure-cli helm kubectl python3 python3-pip hugo docker k3d | tee >(dialog --title "Install Log" --programbox 20 80)
                        ;;
                    2)
                        CHOICES=$(dialog --checklist "Select packages to install" 20 60 10 \
                            1 "Terraform" off \
                            2 "Google Cloud CLI" off \
                            3 "Pass" off \
                            4 "PowerShell" off \
                            5 "Azure CLI" off \
                            6 "Helm" off \
                            7 "Kubectl" off \
                            8 "Python3" off \
                            9 "Docker" off \
                            10 "k3d" off 2>&1 >/dev/tty)
                        
                        for choice in $CHOICES; do
                            case $choice in
                                1) apt install -y terraform ;;
                                2) apt install -y google-cloud-cli ;;
                                3) apt install -y pass ;;
                                4) apt install -y powershell ;;
                                5) apt install -y azure-cli ;;
                                6) apt install -y helm ;;
                                7) apt install -y kubectl ;;
                                8) apt install -y python3 python3-pip ;;
                                9) apt install -y docker ;;
                                10) apt install -y k3d ;;
                            esac
                        done
                        dialog --msgbox "Installation complete." 10 40
                        ;;
                    3)
                        break
                        ;;
                esac
            done
            ;;
        3)
            dialog --yesno "Install Rancher?" 10 40
            response=$?
            if [[ $response -eq 0 ]]; then
                if ! command -v docker &> /dev/null; then
                    dialog --msgbox "Docker is not installed. Installing now." 10 40
                    apt install -y docker.io
                fi
                docker run -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher:latest | tee >(dialog --title "Rancher Install Log" --programbox 20 80)
            fi
            ;;
        4)
            exit 0
            ;;
    esac
done






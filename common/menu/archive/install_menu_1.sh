#!/bin/bash

# Required packages
REQUIRED_PACKAGES=(curl unzip apt-utils fakeroot jq gpg gnupg2 xclip pinentry-tty dos2unix build-essential git pkg-config shellcheck net-tools apt-transport-https gnupg software-properties-common docker-compose-plugin)

# Optional packages with versions (last 3 versions)
declare -A OPTIONAL_PACKAGES
OPTIONAL_PACKAGES=(
    ["helm"]="v3.13.0 v3.12.2 v3.11.3"
    ["terraform"]="1.6.3 1.5.7 1.4.6"
    ["google-cloud-cli"]="450.0.0 440.0.0 430.0.0"
    ["pass"]="1.7.3 1.7.2 1.7.1"
    ["powershell"]="7.4.0 7.3.2 7.2.10"
    ["azure-cli"]="2.54.0 2.53.1 2.52.0"
    ["docker"]="24.0.7 23.0.6 22.0.5"
    ["kubectl"]="1.29.1 1.28.2 1.27.3"
    ["python3-pip"]="23.1 22.3 21.2"
    ["python3"]="3.12.2 3.11.6 3.10.12"
)

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "Dialog package is required but not installed. Installing..."
    sudo apt update && sudo apt install -y dialog
fi

# Display required package toggle
dialog --yesno "Required system packages are necessary for this script to function. Disabling them may break the installation.\n\nDo you want to keep them enabled?" 10 60
KEEP_REQUIRED=$?

if [[ $KEEP_REQUIRED -ne 0 ]]; then
    dialog --msgbox "Required packages cannot be disabled. They are necessary for the installation process." 8 50
fi

# Ask user to select optional packages
SELECTED_PACKAGES=()
for pkg in "${!OPTIONAL_PACKAGES[@]}"; do
    dialog --yesno "Do you want to install $pkg?" 8 50
    if [[ $? -eq 0 ]]; then
        # Get version choices
        VERSIONS=(${OPTIONAL_PACKAGES[$pkg]})
        CHOICES=()
        for ver in "${VERSIONS[@]}"; do
            CHOICES+=("$ver" "" "off")
        done
        # Let user pick a version
        SELECTED_VERSION=$(dialog --radiolist "Select a version for $pkg (latest if no selection is made):" 12 50 4 "${CHOICES[@]}" 3>&1 1>&2 2>&3)
        if [[ -z "$SELECTED_VERSION" ]]; then
            SELECTED_VERSION=${VERSIONS[0]}
        fi
        SELECTED_PACKAGES+=("$pkg:$SELECTED_VERSION")
    fi
done

# Confirmation before installation
dialog --yesno "You selected:\n${SELECTED_PACKAGES[*]}\n\nProceed with installation?" 10 60
CONFIRM=$?

if [[ $CONFIRM -ne 0 ]]; then
    dialog --msgbox "Installation canceled." 6 40
    exit 0
fi

# Update and install required packages
sudo apt update && sudo apt install -y "${REQUIRED_PACKAGES[@]}"

# Install selected optional packages with versions
for pkg_ver in "${SELECTED_PACKAGES[@]}"; do
    IFS=":" read -r pkg version <<< "$pkg_ver"
    case $pkg in
        "helm")
            curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            ;;
        "terraform")
            curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt update && sudo apt install -y terraform=$version
            ;;
        "google-cloud-cli")
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
            curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.gpg > /dev/null
            sudo apt update && sudo apt install -y google-cloud-cli=$version
            ;;
        "pass")
            sudo apt install -y pass=$version
            ;;
        "powershell")
            wget -q "https://github.com/PowerShell/PowerShell/releases/download/v$version/powershell-$version-linux-x64.tar.gz" -O /tmp/powershell.tar.gz
            mkdir -p /opt/microsoft/powershell/$version
            tar -xzf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/$version
            ln -sf /opt/microsoft/powershell/$version/pwsh /usr/bin/pwsh
            ;;
        "azure-cli")
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            ;;
        "docker")
            sudo apt install -y docker.io=$version
            ;;
        "kubectl")
            curl -LO "https://dl.k8s.io/release/$version/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            ;;
        "python3-pip")
            sudo apt install -y python3-pip=$version
            ;;
        "python3")
            sudo apt install -y python3=$version
            ;;
        *)
            echo "Package $pkg not found in the install script."
            ;;
    esac
done

dialog --msgbox "Installation completed successfully!" 6 40
clear

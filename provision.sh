#!/usr/bin/env bash
# set -e
# ==============================================================================
# DIY Buildserver Lab Environment Setup Script
#
# This script sets up your environment by:
#   - Displaying a banner and updating .bashrc
#   - Creating necessary directories and copying profile files
#   - Configuring hostname and hosts file entries
#   - Installing preflight, spectral, docker, helm, k3d, and more
#   - Setting up repositories, cloning demo repos, and installing packages
#   - Modifying bashrc, generating an initial SBOM, and cleaning up
#
# ====================== USECASE 2 =============================================
# If you plan to run the provisioning on your own linux server modify the below 
# env vars with your env settings. Otherwise leave these unmodified.
# ==============================================================================
#
export PROJECT_NAME="buildserver"
# project name or folder, should match your project folder, example buildserver
export PROJECT_PATH="/home/vagrant/buildserver"
# project path. example: export PROJECT_PATH="/home/ubuntu/buildserver"
export VAGRANT_USER_PATH="/home/vagrant"
# example: export VAGRANT_USER_PATH="/home/ubuntu"
export VAGRANT_USER="vagrant"
# example: export VAGRANT_USER="ubuntu"
#
#==============================================================================
#
# -----  Run as root check ----------------------------------------------------
#
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi
#
# ------- Function to check for existing vagrant deployment -------------------
#
check_vagrant_user() {
  if id "vagrant" &>/dev/null; then
    echo "Manual provisioning, continue to update? [Y/n]"
    read -r response
    case "$response" in
      [nN][oO]|[nN])
        echo "Exiting as per user choice."
        exit 1
        ;;
      *)
        echo "Continuing..."
        ;;
    esac
  fi
}

# ----------Function to generate a version ID with date and time -------------
#
generate_version_id() {
    echo "v$(date '+%Y%m%d_%H%M%S')"
}
# Store the generated version ID
VERSION_ID=$(generate_version_id)
# Save to a file (overwrite each run)
#
# Ensure the file exists
[ -f "$PROJECT_PATH/version.txt" ] || touch "$PROJECT_PATH/version.txt"

# Append the version
echo "$VERSION_ID" >> "$PROJECT_PATH/version.txt"

# --------- Function to add optional aliases ---------------------------------
import_menu_aliases() {
  local aliases_file="$HOME/.bash_aliases"
  local -A menu_aliases=(
    ["cls"]="clear"
    ["dps"]="docker ps"
    ["motd"]="/etc/update-motd.d/99-custom-motd"
    ["kci"]="kubernetes cluster-info"
  )

  # Create the file if it doesn't exist
  touch "$aliases_file"

  local added_any=false

  # Append aliases only if they aren't already present
  for alias in "${!menu_aliases[@]}"; do
    if ! grep -qE "^alias $alias=" "$aliases_file"; then
      echo "alias $alias='${menu_aliases[$alias]}'" >> "$aliases_file"
      echo "Added alias: $alias -> ${menu_aliases[$alias]}"
      added_any=true
    else
      echo "Alias '$alias' already exists, skipping."
    fi
  done

  # Source the aliases to apply them immediately
  if [[ "$added_any" == true ]]; then
    echo "Loading new aliases into current shell..."
    # shellcheck disable=SC1090
    source "$aliases_file"
  else
    echo "No new aliases added. Nothing to load."
  fi
}
#
touch $PROJECT_PATH/provisioning.log
touch $PROJECT_PATH/success.log
touch $PROJECT_PATH/error.log
#
# --------- Logging Functions ------------------------------------------------

log_info() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] [INFO] $1" >> $PROJECT_PATH/provisioning.log
}

log_success() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] [SUCCESS] $1" >> $PROJECT_PATH/provisioning.log
  echo "[$timestamp] [SUCCESS] $1" >> $PROJECT_PATH/success.log
}

log_error() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] [ERROR] $1" >> $PROJECT_PATH/provisioning.log
  echo "[$timestamp] [ERROR] $1" >> $PROJECT_PATH/error.log
}

# used to clear out error.logs when using vagrant up --provision
touch $PROJECT_PATH/error.log
> "$PROJECT_PATH/error.log"
# used to clear out success.logs when using vagrant up --provision
touch $PROJECT_PATH/success.log
> "$PROJECT_PATH/success.log"

# ------ Helper Function for Sudo ----------------------------------------------
# run_with_sudo: Executes a command with sudo if not already running as root.
run_with_sudo() {
  if [ "$EUID" -ne 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}

# ----------Function to set execute permissions to scripts folder ------------
make_scripts_executable() {
  log_info "Setting +x on sh files in scripts folder..."
  find $PROJECT_PATH/scripts -type f -name "*.sh" -exec chmod +x {} \; && \
    log_success "Permissions set successfully." || log_error "FATAL: Setting permissions failed."
}

# ----- Install Dependancies ----------------------------------------------------
install_dependancies() {
  log_info "Installing dependancies..."
  run_with_sudo apt-get install -y curl unzip apt-utils fakeroot && \
    log_success "APT Dependancies installed." || log_error "FATAL: Installing dependancies failed."
}

# ----- Banner Display --------------------------------------------------------
display_banner() {
  echo '01100010 01110101 01101001 01101100 01100100 01110011 01100101 01110010 01110110 01100101 01110010'
  echo '01100010 01110101 01101001 01101100 01100100 01110011 01100101 01110010 01110110 01100101 01110010'
  echo '01100010 01110101 01101001 01101100 01100100 01110011 01100101 01110010 01110110 01100101 01110010'
}

# ----- Add custom motd -------------------------------------------------------
add_custom_motd() {
  log_info "Adding custom file 99-custom-motd..."
  run_with_sudo cp "$PROJECT_PATH/profile/99-custom-motd" "/etc/update-motd.d/99-custom-motd" && \
  run_with_sudo chmod +x "/etc/update-motd.d/99-custom-motd" && \
    log_success "99-custom-motd file copied." || log_error "FATAL: Failed to copy 99-custom-motd."
}

# ----- Update .bashrc with PATH ----------------------------------------------
update_bashrc_path() {
  log_info "Updating .bashrc to include local bin in PATH..."
  sudo su -l $VAGRANT_USER -c 'echo $PATH' echo "export PATH=\$PATH:$VAGRANT_USER_PATH/.local/bin" >> "$VAGRANT_USER_PATH/.bashrc" && \
    log_success ".bashrc updated." || log_error "FATAL: Failed to update .bashrc."
}

# ----- Create Kube and Local Bin Directories ----------------------------------
create_directories() {
  log_info "Creating necessary directories..."
  run_with_sudo mkdir -p "$VAGRANT_USER_PATH/.local/bin" "$VAGRANT_USER_PATH/.kube" && \
    log_success "Directories created." || log_error "FATAL: Failed to create directories."
}

# ----- Create Profile Files & Apply Without Logout ----------------------------
copy_profile_files() {
  log_info "Copying profile files..."

  local bash_aliases_path="$VAGRANT_USER_PATH/.bash_aliases"
  local env_file_path="$VAGRANT_USER_PATH/.env"

  cp "$PROJECT_PATH/profile/bash_aliases" "$bash_aliases_path" && \
    log_success "bash_aliases copied." || log_error "FATAL: Failed to copy bash_aliases."

  cp "$PROJECT_PATH/profile/env.example" "$env_file_path" && \
    log_success "env.example copied." || log_error "FATAL: Failed to copy env.example."

  touch "$VAGRANT_USER_PATH/.Xauthority" && \
    log_success "Xauthority created." || log_error "NON-FATAL: Failed to create Xauthority."

  # Apply .bash_aliases if running in an interactive shell
  if [[ $- == *i* && "$VAGRANT_USER_PATH" == "$HOME" ]]; then
    log_info "Sourcing bash_aliases for current session..."
    source "$bash_aliases_path"
  else
    log_info "bash_aliases will apply on next login or manually source it."
  fi

  # Export environment variables from .env (ignore comments)
  if [[ -f "$env_file_path" ]]; then
    log_info "Loading environment variables from .env..."
    set -a
    # shellcheck disable=SC1090
    source "$env_file_path"
    set +a
    log_success ".env variables loaded into current session."
  fi
}

# ----- Configure Hostname & /etc/hosts -----------------------------------------
configure_hostname_hosts() {
  log_info "Configuring hostname and updating /etc/hosts..."
  run_with_sudo hostnamectl set-hostname buildserver && \
    log_success "Hostname set to buildserver." || log_error "FATAL: Hostname update failed."
  
  for host in "rancher.buildserver.local" "waf.buildserver.local" "web.buildserver.local" "demo.buildserver.local" "repo.buildserver.local" "api.buildserver.local" "buildserver.local"; do
    run_with_sudo sh -c "echo '192.168.56.10  $host' >> /etc/hosts" && \
      log_success "Added $host to /etc/hosts." || log_error "FATAL: Failed to add $host to /etc/hosts."
  done
}

# ----- Install Preflight -----------------------------------------------------
install_preflight() {
  log_info "Installing Preflight..."
  wget -qO- https://github.com/SpectralOps/preflight/releases/download/v1.1.5/preflight_1.1.5_Linux_x86_64.tar.gz | \
    tar xvz -C /usr/local/bin -o preflight && \
    log_success "Preflight installed." || log_error "FATAL: Preflight installation failed. If this was a --provision you can likely ignore"
}

# ----- Install Spectral ------------------------------------------------------
install_spectral() {
  log_info "Installing Spectral..."
  curl -L 'https://spectral-us.dome9.com/latest/x/sh' | sh && \
    log_success "Spectral installed." || log_error "FATAL: Spectral installation failed."
  run_with_sudo cp /root/.spectral/spectral /usr/local/bin && \
    log_success "Spectral copied to /usr/local/bin." || log_error "FATAL: Failed to copy Spectral to /usr/local/bin."
}

# ----- Install Docker Using Preflight ----------------------------------------
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log_info "Docker is already installed. Skipping installation."
  else
    log_info "Installing Docker via Preflight..."
    curl -fsSL https://get.docker.com | preflight run sha256=0158433a384a7ef6d60b6d58e556f4587dc9e1ee9768dae8958266ffb4f84f6f && \
      log_success "Docker installed." || log_error "FATAL: Docker installation failed. Check Preflight sha"
  fi
}

# ----- Add User to Docker Group ----------------------------------------------
#add_user_to_docker() {
#  log_info "Adding user $VAGRANT_USER to the Docker group..."
#  run_with_sudo usermod -aG docker $VAGRANT_USER | newgrp docker && \
#    log_success "User $VAGRANT_USER added to Docker group." || log_error "FATAL: Failed to add user $VAGRANT_USER to Docker group."
#}
#
# ----- Add User to Docker Group and Apply Immediately -------------------------
add_user_to_docker() {
  log_info "Adding $USER to the 'docker' group..."

  if id -nG "$USER" | grep -qw "docker"; then
    log_info "User $USER is already in the 'docker' group."
  else
    sudo usermod -aG docker "$USER" && \
      log_success "User $USER added to 'docker' group." || \
      log_error "FATAL: Failed to add user to 'docker' group."

    log_info "Starting newgrp session to apply docker group membership immediately..."
    newgrp docker <<EOF
echo "[INFO] You are now in a new shell with 'docker' group applied."
echo "[INFO] Testing Docker access..."
docker version && echo "[SUCCESS] Docker group access confirmed." || echo "[ERROR] Docker access failed."

# Exit the subshell if desired, or the user can continue from here
exit
EOF
  fi
}


# ----- Install NVM -----------------------------------------------------------
install_nvm() {
  log_info "Installing NVM..."
  sudo -i -u "$VAGRANT_USER" "$PROJECT_PATH/scripts/deploy_nvm.sh" && \
    log_success "NVM installed." || log_error "NON-FATAL: NVM installation failed. If this was a --provision you can likely ignore"
}

# ----- Configure Terraform Repository ----------------------------------------
configure_terraform_repo() {
  log_info "Configuring Terraform repository..."
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | run_with_sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null && \
    log_success "Terraform GPG key added." || log_error "FATAL: Failed to add Terraform GPG key."
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    run_with_sudo tee /etc/apt/sources.list.d/hashicorp.list && \
    log_success "Terraform repository added." || log_error "FATAL: Failed to add Terraform repository. If this was a --provision you can likely ignore"
}

# ----- Install Helm ----------------------------------------------------------
install_helm() {
  log_info "Installing Helm..."
  run_with_sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    log_success "Helm Installed." || log_error "FATAL: Helm installation failed. If this was a --provision you can likely ignore"
}

# ----- Install k3d -----------------------------------------------------------
install_k3d() {
  log_info "Installing k3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash && \
    log_success "k3d Installed." || log_error "FATAL: k3d Installation failed. If this was a --provision you can likely ignore"
}

# ----- Install Powershell ----------------------------------------------------
install_powershell() {
  if command -v pwsh >/dev/null 2>&1; then
    log_info "Powershell is already installed. Skipping installation."
  else
    log_info "Installing Powershell..."
    source /etc/os-release && \
    wget -q "https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb" && \
    run_with_sudo dpkg -i packages-microsoft-prod.deb && \
      log_success "Powershell Installed." || log_error "FATAL: Powershell Installation failed."
  fi
}

# ----- Install AWS CLI -----------------------------------------------------------
install_awscli() {
  if command -v aws >/dev/null 2>&1; then
    log_info "AWS CLI is already installed. Skipping installation."
  else
    log_info "Installing AWS CLI..."
    curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip | bash && unzip awscliv2.zip > /dev/null && \
    sudo ./aws/install && \
      log_success "AWS CLI Installed." || log_error "FATAL: AWS CLI Installation failed."
  fi
}

# ----- Install Google Cloud Repository ----------------------------------------
install_gcloudcli() {
  if command -v gcloud >/dev/null 2>&1; then
    log_info "Google Cloud Repository is already installed. Skipping installation."
  else
    log_info "Installing Google Cloud Repository..."
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | run_with_sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | run_with_sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
      log_success "Google Cloud Repository installed." || log_error "FATAL: Google Cloud Repository installation failed."
  fi
}

# ----- Install Azure CLI Repository ----------------------------------------
install_azurecli() {
  if command -v az >/dev/null 2>&1; then
    log_info "Azure CLI Repository is already installed. Skipping installation."
  else
    log_info "Installing Azure CLI..."
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | run_with_sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | run_with_sudo tee /etc/apt/sources.list.d/azure-cli.list && \
      log_success "Azure CLI Repository installed." || log_error "FATAL: Azure CLI Repository installation failed."
  fi
}

# ----- Configure kubectl Repository ------------------------------------------
configure_kubectl_repo() {
  if command -v kubectl >/dev/null 2>&1; then
    log_info "Kubectl is already installed. Skipping installation."
  else
    log_info "Installing Kubectl APT Source..."
    
    for attempt in {1..2}; do
      curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | run_with_sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
      run_with_sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
      echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | run_with_sudo tee /etc/apt/sources.list.d/kubernetes.list && \
      run_with_sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list && \
      log_success "Kubectl repository configured." && return 0
      
      log_warn "Attempt $attempt: Failed to configure kubectl repository. Retrying..."
      sleep 2  # Short delay before retrying
    done
    
    log_error "FATAL: Failed to configure kubectl repository after multiple attempts."
    return 1
  fi
}

# ----- Update Home Directory Permissions -------------------------------------
update_home_permissions() {
  log_info "Updating home directory permissions..."
  run_with_sudo chgrp -R "$VAGRANT_USER" "$VAGRANT_USER_PATH" && \
    run_with_sudo chown -R "$VAGRANT_USER" "$VAGRANT_USER_PATH" && \
    log_success "Home directory permissions updated." || log_error "FATAL: Failed to update home directory permissions."
}

# ----- Update and Upgrade System ---------------------------------------------
update_system() {
  log_info "Updating and upgrading system packages..."
  run_with_sudo apt-get update && run_with_sudo apt-get upgrade -y && \
    log_success "System updated and upgraded." || log_error "NON-FATAL: System update/upgrade failed."
}

# ----- Configure Git ---------------------------------------------------------
configure_git() {
  log_info "Configuring Git global settings..."
  git config --global user.email "$VAGRANT_USER@buildserver.local" && \
    git config --global --add safe.directory "$VAGRANT_USER_PATH/repos" && \
    git config --global user.name "$VAGRANT_USER" && \
    git config --global init.defaultBranch main && \
    log_success "Git configured." || log_error "NON-FATAL: Git configuration failed."
}

# ----- Clone Repositories ----------------------------------------------------
clone_repositories() {
  log_info "Cloning demo repositories..."
  mkdir -p "$VAGRANT_USER_PATH/repos"
  git clone https://github.com/chkp-altrevin/datacenter-objects-k8s.git "$VAGRANT_USER_PATH/repos/datacenter-objects-k8s" && \
    log_success "Cloned datacenter-objects-k8s." || log_error "NON-FATAL: Failed to clone datacenter-objects-k8. If this was a --provision you can likely ignore"
  git clone https://github.com/SpectralOps/spectral-goat.git "$VAGRANT_USER_PATH/repos/spectral-goat" && \
    log_success "Cloned spectral-goat." || log_error "NON-FATAL: Failed to clone spectral-goat. If this was a --provision you can likely ignore"
  git clone https://github.com/openappsec/waf-comparison-project.git "$VAGRANT_USER_PATH/repos/waf-comparison-project" && \
    log_success "Cloned waf-comparison-project." || log_error "NON-FATAL: Failed to clone waf-comparison-project. If this was a --provision you can likely ignore"
}

# ----- Install Additional Packages -------------------------------------------
install_packages() {
  log_info "Installing selected packages..."
  run_with_sudo apt-get install -y jq kubectl dos2unix build-essential git python3-pip python3 pkg-config \
    shellcheck net-tools apt-transport-https unzip gnupg software-properties-common docker-compose-plugin \
    terraform google-cloud-cli pass gpg gnupg2 xclip pinentry-tty powershell azure-cli && \
    log_success "APT Additional packages installed." || log_error "FATAL: APT Additional packages failed install."
}

# ----- Modify bashrc ---------------------------------------------------------
modify_bashrc() {
  log_info "Modifying bashrc to source .env..."
  "$PROJECT_PATH/scripts/insert_bashrc.sh" && \
    log_success "bashrc modified." || log_error "FATAL: bashrc modification failed."
}

# ----- Generate Initial SBOM -------------------------------------------------
generate_initial_sbom() {
  log_info "Generating initial SBOM..."
  "$PROJECT_PATH/scripts/initial_sbom.sh" && \
    log_success "Initial SBOM generated." || log_error "NON-FATAL: Initial SBOM generation failed."
}

# ----- Cleanup ----------------------------------------------------------------
cleanup() {
  log_info "Performing cleanup..."
  run_with_sudo rm -f ./get_helm.sh && \
  run_with_sudo rm -f ./packages-microsoft-prod.deb && \
  run_with_sudo rm -rf aws && \
  run_with_sudo rm -f awscliv2.zip && \
    log_success "Installer scripts removed." || log_error "NON-FATAL: Failed to remove Installer scripts or may not exist."
}

# ----- Main Execution ----------------------------------------------------------
# Info below is referenced in the README.md file for review if you plan to modify and make your own, review comments below for more info
# Use Case 1  = All functions below are required for Use Case 1 Vagrant and VirtualBox automated full deployment
# Use Case 2  = Comments that start with a 2, are optional review comments below for more info
main() {
  check_vagrant_user # 2 responsible for checking if we are a vagrant user and if so, we notify first
  make_scripts_executable # 2 chmod .sh +x the script folder, you need to do this manually if disabled
  install_dependancies  # 2 mainly to support extractions, utilities to automate and help run commands used for automation, disable for manual cycles
  display_banner # 2 fun stuff
  add_custom_motd # 2 more fun stuff but also the motd
  import_menu_aliases # if you plan to use cli menu and automation these are required
  # update_bashrc_path to be determined
  create_directories # 2 create custom directories needed for use case 1
  copy_profile_files # 2 alias and bash stuff needed for use case 1
  configure_hostname_hosts # 2 create hostname and records needed for use case 1
  install_preflight  # 2 used to precheck our external facing scripts such as docker, remove or not your call used for use case 1
  install_spectral # 2 installs spectral code scanner not required
  install_docker  # 2 install script with preflight dont leave to chance used for use case 1
  add_user_to_docker  # 2 add our user to docker group use for use case 1
  install_nvm  # 2 installs node version mgr, not required but a personal fav
  configure_terraform_repo # 2 install the terraform repository
  install_helm # 2 install the helm repository used for use case 1
  install_k3d # 2 install the k3d repository, responsible for creating k8s nodes on docker used for use case 1
  install_powershell # 2 install the powershell repository
  install_awscli # install the awscli repository
  install_gcloudcli # 2 install the google cloud repository
  install_azurecli # 2 install the azure cli repository
  configure_kubectl_repo # 2 install the kubectl repository used for use case 1
  update_home_permissions # 2 updates anything copied over to the $USER and $HOME paths used for use case 1 and 2
  update_system # 2 apt update upgrade used for use case 1
  configure_git # 2 configures git common configurations feel free to modify but used for use case 1
  clone_repositories # 2 install a few repos modify any as needed or remove your call
  install_packages # 2 install the packages we setup distro for required for use case 1
  modify_bashrc # 2 modify bashrc to include a new path used for use case 1
  update_home_permissions  # 2 apply permissions used for use case 1
  generate_initial_sbom # 2 generate the package list we installed used for use case 1 and 1
  cleanup # 2 cleanup install and temp content used for usecase 1 and 2
}
main

sleep 6
echo "=========================================================================="
# Print version ID
echo ""
echo "Script Version: $VERSION_ID (Saved to $PROJECT_PATH/version.txt)"
echo ""
echo "=========================================================================="
echo "========================================================================= "
echo "| Provisioning Log     | saved to $PROJECT_PATH/provisioning.log          "
echo "| Software Packages    | exported to $PROJECT_PATH/initial_sbom           "
echo "| Provision Error Logs | exported to $PROJECT_PATH/error.log              "
echo "=========================================================================="
sleep 6
echo "Summarizing errors if any"
echo ""
cat "$PROJECT_PATH/success.log"
echo "=========================================================================="
cat "$PROJECT_PATH/error.log"
echo ""
echo "If errors, fix and reprovision using, vagrant up --provision. If this is a"
echo "custom install using provision.sh, you can likely ignore NON-FATAL errors."
echo "=========================================================================="
echo "SSH with vagrant ssh or your terminal of choice                           "
echo "Login: vagrant:privatekey port:2222"
echo "=========================================================================="
echo "If you manually ran provision.sh - Logout and log back in to see changes  "

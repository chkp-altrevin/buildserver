#!/usr/bin/env bash
set -euo pipefail

# === SUDO-SAFE ENV SETUP ===
SUDO_USER="${SUDO_USER:-}"
ORIGINAL_USER="${SUDO_USER:-$USER}"
CALLER_HOME="${HOME}"

if [[ -n "$SUDO_USER" ]]; then
  CALLER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
fi


# Auto-recover if shell-init fails due to invalid working directory
if ! cd "$PWD" 2>/dev/null; then
  log_info "Current working directory is invalid. Changing to fallback: $PROJECT_PATH"
  cd "$PROJECT_PATH" || { log_error "Failed to change to fallback PROJECT_PATH: $PROJECT_PATH"; exit 1; }
fi

# Ensure all files under CALLER_HOME are owned by the original user
fix_ownership_in_home() {
  log_info "Ensuring proper ownership for all files in $CALLER_HOME"
  find "$CALLER_HOME" -user root -exec chown "$ORIGINAL_USER" {} +
  find "$CALLER_HOME" -group root -exec chgrp "$ORIGINAL_USER" {} +
  log_success "Ownership corrected for user: $ORIGINAL_USER"
}

: "${PROJECT_NAME:="buildserver"}"
: "${PROJECT_PATH:="$HOME/$PROJECT_NAME"}"
: "${TEST_MODE:=false}"

mkdir -p "$PROJECT_PATH"
LOG="${PROJECT_PATH}/provisioning.log"
touch "$LOG"
# --- Log Rotation ---
MAX_LOG_SIZE=1048576  # 1MB
if [ -f "$LOG" ] && [ "$(stat -c%s "$LOG")" -ge "$MAX_LOG_SIZE" ]; then
  mv "$LOG" "$LOG.old"
  touch "$LOG"
  log_info "Rotated provisioning log (exceeded 1MB)."
fi

# --- Trap Cleanup and Rollback ---
rollback_on_failure() {
  log_error "Provisioning failed. Initiating rollback..."
  # Example: remove partial installs or restore backups
  # rm -rf "$PROJECT_PATH/some_temp_dir"
  # [ -f "$PROJECT_PATH/.backup_config" ] && mv "$PROJECT_PATH/.backup_config" "$PROJECT_PATH/config"
  log_info "Rollback completed (placeholder)."
}

cleanup_on_exit() {
  log_info "Cleaning up temporary files and exiting."
}

trap 'rollback_on_failure' ERR
trap 'cleanup_on_exit' EXIT

# Auto-recover if shell-init fails due to invalid working directory
if ! cd "$PWD" 2>/dev/null; then
  log_info "Current working directory is invalid. Changing to PROJECT_PATH: $PROJECT_PATH"
  cd "$PROJECT_PATH" || { log_error "Failed to change to PROJECT_PATH: $PROJECT_PATH"; exit 1; }
fi


log_info()    { echo "[INFO]    $(date '+%F %T') - $*" | tee -a "$LOG"; }
log_success() { echo "[SUCCESS] $(date '+%F %T') - $*" | tee -a "$LOG"; }
log_error()   { echo "[ERROR]   $(date '+%F %T') - $*" | tee -a "$LOG" >&2; }

run_with_sudo() {
  if [[ $EUID -ne 0 ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

# === Injected Original Functions ===

install_required_dependencies() {
  log_info "Installing required dependencies..."
  local packages=(curl zip unzip apt-utils fakeroot dos2unix software-properties-common)
  if [[ "$TEST_MODE" == "true" ]]; then
    log_info "[TEST MODE] Would run: apt-get install -y ${packages[*]}"
    return 0
  fi
  run_with_sudo apt-get update -y
  run_with_sudo apt-get install -y "${packages[@]}" &&     log_success "Dependencies installed." ||     log_error "FATAL: Failed to install required dependencies."
}


# 

# ---------------- Flag Handling and Validation ----------------

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --project-name NAME        Optional: Project name (default: buildserver)"
  echo "  --project-path PATH        Required*: Path to install (default: $HOME/buildserver)"
  echo "  --virtualbox-vagrant-win   Enable Vagrant/VirtualBox Windows setup flow"
  echo "  -h, --help                 Show this help message"
  exit 0
}

# Defaults
PROJECT_NAME="${PROJECT_NAME:-buildserver}"
PROJECT_PATH="${PROJECT_PATH:-$HOME/$PROJECT_NAME}"
CHECK_VBOX_VAGRANT=false

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --project-name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --virtualbox-vagrant-win)
      CHECK_VBOX_VAGRANT=true
      shift
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

# Set required project path if not provided
if [[ -z "$PROJECT_PATH" ]]; then
  PROJECT_PATH="$CALLER_HOME/$PROJECT_NAME"
  echo "[INFO] No --project-path provided, defaulting to: $PROJECT_PATH"
fi

# Conditional user/env settings for Vagrant+VirtualBox
if [[ "$CHECK_VBOX_VAGRANT" == true ]]; then
  export VAGRANT_USER="vagrant"
  export VAGRANT_USER_PATH="/home/vagrant"
  export PROJECT_PATH="/home/vagrant/$PROJECT_NAME"
else
  export VAGRANT_USER="${USER}"
  export VAGRANT_USER_PATH="${HOME}"
fi

export PROJECT_NAME
export PROJECT_PATH

# -----  Run as root check ----------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# ---------------- VirtualBox + Vagrant Verification ----------------


# Run validation if flag passed
if [[ "$CHECK_VBOX_VAGRANT" == true ]]; then
  verify_virtualbox_and_vagrant
fi
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
  local aliases_file="$CALLER_HOME/.bash_aliases"
  local -A menu_aliases=(
    ["cls"]="clear"
    ["quick-setup"]="docker ps"
    ["motd"]="/etc/update-motd.d/99-custom-motd"
    ["renv"]="source $CALLER_HOME/.env"
    ["denv"]="source $PROJECT_PATH/common/profile/env.example"
    ["python"]="python3"
    ["clusters"]="kubectl config get-clusters"
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
#
# --------- Logging Functions ------------------------------------------------

log_info() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] [INFO] $1" >> $PROJECT_PATH/provisioning.log
}

log_success() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] [SUCCESS] $1" >> $PROJECT_PATH/provisioning.log
}

log_error() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] [ERROR] $1" >> $PROJECT_PATH/provisioning.log
}

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
  find $PROJECT_PATH/common/scripts -type f -name "*.sh" -exec chmod +x {} \; && \
    log_success "Permissions set successfully." || log_error "FATAL: Setting permissions failed."
}

# ----- Install Dependancies ----------------------------------------------------
install_dependancies() {
  log_info "Installing dependancies..."
  run_with_sudo apt-get -yq install curl unzip apt-utils fakeroot && \
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
  run_with_sudo cp "$PROJECT_PATH/common/profile/99-custom-motd" "/etc/update-motd.d/99-custom-motd" && \
  run_with_sudo chmod +x "/etc/update-motd.d/99-custom-motd" && \
    log_success "99-custom-motd file copied." || log_error "FATAL: Failed to copy 99-custom-motd."
}

# ----- Update .bashrc with PATH ----------------------------------------------
update_bashrc_path() {
  log_info "Updating .bashrc to include local bin in PATH..."
  sudo su -l $USER -c 'echo $PATH' echo "export PATH=\$PATH:$CALLER_HOME/.local/bin" >> "$CALLER_HOME/.bashrc" && \
    log_success ".bashrc updated." || log_error "FATAL: Failed to update .bashrc."
}

# ----- Create Kube and Local Bin Directories ----------------------------------
create_directories() {
  log_info "Creating necessary directories..."
  run_with_sudo mkdir -p "$CALLER_HOME/.local/bin" "$CALLER_HOME/.kube" && \
    log_success "Directories created." || log_error "FATAL: Failed to create directories."
}

# ----- Create Profile Files & Apply Without Logout ----------------------------
copy_profile_files() {
  log_info "Copying profile files..."

  local bash_aliases_path="$CALLER_HOME/.bash_aliases"
  local env_file_path="$CALLER_HOME/.env"

  cp "$PROJECT_PATH/common/profile/bash_aliases" "$bash_aliases_path" && \
    log_success "bash_aliases copied." || log_error "FATAL: Failed to copy bash_aliases."

  cp "$PROJECT_PATH/common/profile/env.example" "$env_file_path" && \
    log_success "env.example copied." || log_error "FATAL: Failed to copy env.example."

  touch "$CALLER_HOME/.Xauthority" && \
    log_success "Xauthority created." || log_error "NON-FATAL: Failed to create Xauthority."

  # Apply .bash_aliases if running in an interactive shell
  if [[ $- == *i* && "$CALLER_HOME" == "$CALLER_HOME" ]]; then
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
    run_with_sudo sh -c "echo '$(ip route get 1.1.1.1 | awk '{print $7}' | head -1)  $host' >> /etc/hosts" && \
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
add_user_to_docker() {
  log_info "Adding user $ORIGINAL_USER to the Docker group..."
  run_with_sudo usermod -aG docker "$ORIGINAL_USER" && \
    log_success "User $ORIGINAL_USER added to Docker group." || log_error "FATAL: Failed to add user $ORIGINAL_USER to Docker group."
}
# ----- Install NVM -----------------------------------------------------------

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

# ----- Install AWS CLI -----------------------------------------------------------
#install_awscli() {
#  if command -v aws >/dev/null 2>&1; then
#    log_info "AWS CLI is already installed. Skipping installation."
#  else
#    log_info "Installing AWS CLI..."
#    curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip | bash && unzip awscliv2.zip > /dev/null && \
#    sudo ./aws/install && \
#      log_success "AWS CLI Installed." || log_error "FATAL: AWS CLI Installation failed."
#  fi
#}

# ----- Install Google Cloud Repository ----------------------------------------
#install_gcloudcli() {
#  if command -v gcloud >/dev/null 2>&1; then
#    log_info "Google Cloud Repository is already installed. Skipping installation."
#  else
#    log_info "Installing Google Cloud Repository..."
#    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | run_with_sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
#    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | run_with_sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
#      log_success "Google Cloud Repository installed." || log_error "FATAL: Google Cloud Repository installation failed."
#  fi
#}

# ----- Install Azure CLI Repository ----------------------------------------
#install_azurecli() {
#  if command -v az >/dev/null 2>&1; then
#    log_info "Azure CLI Repository is already installed. Skipping installation."
#  else
#    log_info "Installing Azure CLI..."
#    curl -sL https://packages.microsoft.com/keys/microsoft.asc | run_with_sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg && \
#    echo "deb [signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | run_with_sudo tee /etc/apt/sources.list.d/azure-cli.list && \
#      log_success "Azure CLI Repository installed." || log_error "FATAL: Azure CLI Repository installation failed."
#  fi
#}

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

# ----- Update Preoject Directory Permissions ---------------------------------
update_home_permissions() {
  log_info "Updating project directory permissions..."
  run_with_sudo chgrp -R "$USER" "$PROJECT_PATH" && \
    run_with_sudo chown -R "$USER" "$PROJECT_PATH" && \
    log_success "Project directory permissions updated." || log_error "FATAL: Failed to update Project directory permissions."
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
  git config --global user.email "$USER@buildserver.local" && \
    git config --global --add safe.directory "$HOME/repos" && \
    git config --global user.name "$USER" && \
    git config --global init.defaultBranch main && \
    log_success "Git configured." || log_error "NON-FATAL: Git configuration failed."
}

# ----- Clone Repositories ----------------------------------------------------
clone_repositories() {
  log_info "Cloning demo repositories..."
  mkdir -p "$CALLER_HOME/repos"
  git clone https://github.com/chkp-altrevin/datacenter-objects-k8s.git "$CALLER_HOME/repos/datacenter-objects-k8s" && \
    log_success "Cloned datacenter-objects-k8s." || log_error "NON-FATAL: Failed to clone datacenter-objects-k8. If this was a --provision you can likely ignore"
  git clone https://github.com/SpectralOps/spectral-goat.git "$CALLER_HOME/repos/spectral-goat" && \
    log_success "Cloned spectral-goat." || log_error "NON-FATAL: Failed to clone spectral-goat. If this was a --provision you can likely ignore"
  git clone https://github.com/openappsec/waf-comparison-project.git "$CALLER_HOME/repos/waf-comparison-project" && \
    log_success "Cloned waf-comparison-project." || log_error "NON-FATAL: Failed to clone waf-comparison-project. If this was a --provision you can likely ignore"
}

# ----- Install Default Packages ----------------------------------------------
install_packages() {
  log_info "Installing selected packages..."
  run_with_sudo apt-get -yq install jq kubectl dos2unix build-essential git python3-pip python3 pkg-config \
    shellcheck net-tools apt-transport-https unzip gnupg software-properties-common docker-compose-plugin \
    terraform gnupg2 xclip && \
    log_success "APT Additional packages installed." || log_error "FATAL: APT Additional packages failed install."
}

# ----- Install Optional Packages Used for Future Use --------------------------
#install_optional_packages() {
#  log_info "Installing selected packages..."
#  run_with_sudo apt-get -yq install jq kubectl dos2unix build-essential git python3-pip python3 pkg-config \
#    shellcheck net-tools apt-transport-https unzip gnupg software-properties-common docker-compose-plugin \
#    terraform google-cloud-cli pass gpg gnupg2 xclip pinentry-tty powershell azure-cli && \
#    log_success "APT Additional packages installed." || log_error "FATAL: APT Additional packages failed install."
#}

# ----- Modify bashrc ---------------------------------------------------------
modify_bashrc() {
  log_info "Modifying bashrc to source .env..."
  "$PROJECT_PATH/common/scripts/insert_bashrc.sh" && \
    log_success "bashrc modified." || log_error "FATAL: bashrc modification failed."
}

# ----- Generate Initial SBOM -------------------------------------------------
generate_initial_sbom() {
  log_info "Generating initial SBOM..."
  "$PROJECT_PATH/common/scripts/initial_sbom.sh" && \
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
  install_required_dependencies
  check_vagrant_user
  make_scripts_executable
  display_banner # fun stuff
  add_custom_motd # the motd
  import_menu_aliases # if you plan to use cli menu and automation these are required
  create_directories # 2 create custom directories needed for use case 1
  copy_profile_files # 2 alias and bash stuff needed for use case 1
  configure_hostname_hosts # 2 create hostname and records needed for use case 1
  install_preflight  # 2 used to precheck our external facing scripts such as docker, remove or not your call used for use case 1
  install_docker  # 2 install script with preflight dont leave to chance used for use case 1
  add_user_to_docker  # 2 add our user to docker group use for use case 1
  # install_nvm  # 2 installs node version mgr, not required but a personal fav
  configure_terraform_repo # 2 install the terraform repository
  install_helm # 2 install the helm repository used for use case 1
  install_k3d # 2 install the k3d repository, responsible for creating k8s nodes on docker used for use case 1
  # install_powershell # 2 install the powershell repository
  #install_awscli # install the awscli repository
  #install_gcloudcli # 2 install the google cloud repository
  #install_azurecli # 2 install the azure cli repository
  configure_kubectl_repo # 2 install the kubectl repository used for use case 1
  update_home_permissions # 2 updates anything copied over to the vagrant and $HOME paths used for use case 1 and 2
  update_system # 2 apt update upgrade used for use case 1
  configure_git # 2 configures git common configurations feel free to modify but used for use case 1
  clone_repositories # 2 install a few repos modify any as needed or remove your call
  install_packages # 2 install the packages we setup distro for required for use case 1
  modify_bashrc # 2 modify bashrc to include a new path used for use case 1
  update_home_permissions  # 2 apply permissions used for use case 1
  generate_initial_sbom # 2 generate the package list we installed used for use case 1 and 1
  cleanup # 2 cleanup install and temp content used for usecase 1 and 2
  fix_ownership_in_home
# Final messaging based on user type
if [[ "${SUDO_USER:-$USER}" == "vagrant" ]]; then
  echo "If errors, fix and reprovision using, vagrant up --provision. If this is a"
  echo "custom install using provision.sh, you can likely ignore NON-FATAL errors."
  echo "=========================================================================="
  echo "SSH with vagrant ssh or your terminal of choice                           "
  echo "Login: vagrant:privatekey port:2222"
  echo "=========================================================================="
else
  echo "Looks like you ran the installer script - Logout and log back in to see changes  "
fi
  log_info "⚠️  Please log out and log back in to apply Docker group membership changes."
}
main

sleep 6
echo "=========================================================================="
# Print version ID
echo ""
echo "Script Version: $VERSION_ID (Saved to ${PROJECT_PATH}/version.txt)"
echo ""
echo "=========================================================================="
echo "========================================================================= "
echo "| Provisioning Log     | saved to ${PROJECT_PATH}/provisioning.log        "
echo "| Software Packages    | exported to $PROJECT_PATH/initial_sbom           "
echo "=========================================================================="
sleep 6
echo -e "\\n\033[1;31m[✖] Errors Detected:\033[0m"
grep --color=always ERROR "$PROJECT_PATH/provisioning.log"
echo "=========================================================================="
echo -e "\\n\033[1;32m[✔] Successful Tasks:\033[0m"
grep --color=always SUCCESS "$PROJECT_PATH/provisioning.log"

echo ""
echo "If errors, fix and reprovision using, vagrant up --provision. If this is a"
echo "custom install using provision.sh, you can likely ignore NON-FATAL errors."
echo "=========================================================================="
echo "SSH with vagrant ssh or your terminal of choice                           "
echo "Login: vagrant:privatekey port:2222"
echo "=========================================================================="
echo "If you manually ran provision.sh - Logout and log back in to see changes  "

# Safe argument parsing (override project vars)
while [[ $# -gt 0 ]]; do
  case $1 in
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --test) TEST_MODE=true; shift ;;
    *) shift ;;
  esac
done
# === Injected Updated Functions ===

generate_version_id() {
  local timestamp="v$(date '+%Y%m%d_%H%M%S')"
  local git_sha="nogit"
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
    git_sha=$(git rev-parse --short HEAD 2>/dev/null || echo "nogit")
  fi
  echo "${timestamp}_${git_sha}"
}


install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log_info "Docker is already installed. Skipping installation."
    return 0
  fi

  log_info "Attempting Docker installation with Preflight..."

  if command -v preflight >/dev/null 2>&1; then
    if ! curl -fsSL https://get.docker.com | preflight run sha256=0158433a384a7ef6d60b6d58e556f4587dc9e1ee9768dae8958266ffb4f84f6f; then
      log_error "Preflight validation failed. Falling back to direct install."
      curl -fsSL https://get.docker.com | sh && log_success "Docker installed via fallback." || log_error "FATAL: Docker fallback installation failed."
    else
      log_success "Docker installed via Preflight."
    fi
  else
    log_warn "Preflight not found. Falling back to direct install."
    curl -fsSL https://get.docker.com | sh && log_success "Docker installed via fallback." || log_error "FATAL: Docker fallback installation failed."
  fi
}


install_helm() {
  local version="v3.14.0"
  log_info "Installing Helm version $version..."

  run_with_sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
  chmod 700 get_helm.sh && \
  HELM_INSTALL_DIR="/usr/local/bin" DESIRED_VERSION="$version" ./get_helm.sh && \
    log_success "Helm $version installed." || log_error "FATAL: Helm installation failed. If this was a --provision you can likely ignore"
}


modify_bashrc() {
  log_info "Modifying .bashrc to source .env if not already included..."

  local bashrc_file="$CALLER_HOME/.bashrc"
  local env_source='[ -f "$CALLER_HOME/.env" ] && source "$CALLER_HOME/.env"'

  if grep -Fxq "$env_source" "$bashrc_file"; then
    log_info ".env sourcing already present in .bashrc. Skipping."
  else
    echo -e "\n# Auto-injected by buildserver provisioner\n$env_source" >> "$bashrc_file" && \
      log_success ".bashrc modified to source .env." || \
      log_error "FATAL: Failed to modify .bashrc."
  fi
}


generate_initial_sbom() {
  log_info "Generating initial SBOM..."

  local sbom_file="$PROJECT_PATH/initial_sbom"
  local package_list=(
    curl zip unzip apt-utils fakeroot dos2unix software-properties-common jq
    kubectl build-essential git python3-pip python3 pkg-config shellcheck
    net-tools apt-transport-https gnupg docker-compose-plugin terraform
    google-cloud-cli pass gpg gnupg2 xclip pinentry-tty azure-cli
  )

  {
    echo "# Initial SBOM - $(date)"
    for pkg in "${package_list[@]}"; do
      if dpkg-query -W -f='${binary:Package} ${Version}\n' "$pkg" 2>/dev/null; then
        :
      else
        echo "$pkg [NOT INSTALLED]"
      fi
    done
  } > "$sbom_file" && \
    log_success "SBOM saved to $sbom_file" || \
    log_error "NON-FATAL: Failed to generate SBOM."
}


cleanup() {
  log_info "Performing cleanup..."
  run_with_sudo rm -f ./get_helm.sh
  run_with_sudo rm -f awscliv2.zip
  run_with_sudo rm -rf aws
  log_success "Installer artifacts removed (Helm, AWS)." || \
    log_error "NON-FATAL: Some cleanup files may not have existed."
}

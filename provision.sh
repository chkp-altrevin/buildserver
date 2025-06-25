#!/usr/bin/env bash
set -euo pipefail
#
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
#==============================================================================

# ---------------------- log files (MOVED TO TOP) --------------------------------------
log_info()    { echo "[INFO]    $(date '+%F %T') - $*" | tee -a "${LOG:-/tmp/provision.log}"; }
log_success() { echo "[SUCCESS] $(date '+%F %T') - $*" | tee -a "${LOG:-/tmp/provision.log}"; }
log_error()   { echo "[ERROR]   $(date '+%F %T') - $*" | tee -a "${LOG:-/tmp/provision.log}" >&2; }
log_warn()    { echo "[WARN]    $(date '+%F %T') - $*" | tee -a "${LOG:-/tmp/provision.log}"; }

# === ENHANCED VAGRANT DETECTION ===
detect_vagrant_environment() {
  # Check multiple indicators for Vagrant
  if [[ -d "/vagrant" ]] || [[ "$USER" == "vagrant" ]] || [[ -f "/home/vagrant/.vagrant_provisioned" ]] || grep -q "vagrant" /etc/passwd 2>/dev/null; then
    return 0  # Is Vagrant
  else
    return 1  # Not Vagrant
  fi
}

# === VAGRANT SYNC FOLDER VALIDATION ===
validate_vagrant_sync() {
  if [[ "$IS_VAGRANT_ENV" == true ]]; then
    # Check if synced folder exists and has content
    if [[ -d "/vagrant" ]] && [[ "$(ls -A /vagrant 2>/dev/null)" ]]; then
      log_info "Vagrant sync folder /vagrant detected with content"
      
      # If PROJECT_PATH doesn't exist but /vagrant does, copy from vagrant
      if [[ ! -d "$PROJECT_PATH" ]] || [[ -z "$(ls -A "$PROJECT_PATH" 2>/dev/null)" ]]; then
        log_info "Copying from /vagrant to $PROJECT_PATH"
        mkdir -p "$PROJECT_PATH"
        cp -r /vagrant/* "$PROJECT_PATH/" 2>/dev/null || true
        chown -R vagrant:vagrant "$PROJECT_PATH"
      fi
    elif [[ -d "/home/vagrant/buildserver" ]] && [[ "$(ls -A /home/vagrant/buildserver 2>/dev/null)" ]]; then
      log_info "Vagrant synced to /home/vagrant/buildserver detected"
      PROJECT_PATH="/home/vagrant/buildserver"
    else
      log_warn "Vagrant environment detected but no synced folders found"
    fi
  fi
}

# === SUDO-SAFE ENV SETUP WITH VAGRANT DETECTION ===
SUDO_USER="${SUDO_USER:-}"
ORIGINAL_USER="${SUDO_USER:-$USER}"
IS_VAGRANT_ENV=false

# Detect if we're in Vagrant environment
if detect_vagrant_environment; then
  IS_VAGRANT_ENV=true
fi

# Set user context based on environment
if [[ "$IS_VAGRANT_ENV" == true ]]; then
  # Vagrant/VirtualBox deployment
  ORIGINAL_USER="vagrant"
  CALLER_HOME="/home/vagrant"
  PROJECT_NAME="${PROJECT_NAME:-buildserver}"
  PROJECT_PATH="/home/vagrant/$PROJECT_NAME"
else
  # Native Linux/WSL deployment
  if [[ -n "$SUDO_USER" ]]; then
    CALLER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  else
    CALLER_HOME="${HOME}"
  fi
  PROJECT_NAME="${PROJECT_NAME:-buildserver}"
  PROJECT_PATH="${CALLER_HOME}/${PROJECT_NAME}"
fi

DOT_BUILDSERVER="${DOT_BUILDSERVER:-.buildserver}"

# Auto-recover if shell-init fails due to invalid working directory
if ! cd "$PWD" 2>/dev/null; then
  mkdir -p "$PROJECT_PATH"
  cd "$PROJECT_PATH" || { echo "FATAL: Failed to change to PROJECT_PATH: $PROJECT_PATH"; exit 1; }
fi

# Create necessary directories
mkdir -p "$PROJECT_PATH"
mkdir -p "$PROJECT_PATH/$DOT_BUILDSERVER"
mkdir -p "$PROJECT_PATH/logs"

# Validate Vagrant sync folders
validate_vagrant_sync

# Fix ownership for Vagrant scenarios
if [[ "$IS_VAGRANT_ENV" == true ]]; then
  chown -R vagrant:vagrant "$PROJECT_PATH" 2>/dev/null || true
fi

# Logging setup
LOG="${PROJECT_PATH}/logs/provisioning.log"
touch "$LOG"

# --- Log Rotation ---
MAX_LOG_SIZE=1048576  # 1MB
if [ -f "$LOG" ] && [ "$(stat -c%s "$LOG")" -ge "$MAX_LOG_SIZE" ]; then
  mv "$LOG" "$LOG.old"
  touch "$LOG"
fi

# Set default values for optional variables
: "${TEST_MODE:=false}"

# Export the corrected variables
export PROJECT_NAME
export PROJECT_PATH
export ORIGINAL_USER
export CALLER_HOME
export IS_VAGRANT_ENV
export TEST_MODE

# Debug output for troubleshooting
log_info "=== ENVIRONMENT DETECTION RESULTS ==="
log_info "IS_VAGRANT_ENV: $IS_VAGRANT_ENV"
log_info "ORIGINAL_USER: $ORIGINAL_USER" 
log_info "CALLER_HOME: $CALLER_HOME"
log_info "PROJECT_PATH: $PROJECT_PATH"
log_info "Current working directory: $(pwd)"
log_info "Contents of PROJECT_PATH: $(ls -la "$PROJECT_PATH" 2>/dev/null || echo 'Directory does not exist or is empty')"

# --- Trap Cleanup and Rollback ---
cleanup_on_exit() {
  log_info "Cleaning up temporary files and exiting."
}

trap 'cleanup_on_exit' EXIT

# ----- Enhanced APT Functions with Error Handling -------------------------

# Function to clean and reset APT state
clean_apt_state() {
  log_info "🧹 Cleaning APT state..."
  run_with_sudo rm -rf /var/lib/apt/lists/* 2>/dev/null || true
  run_with_sudo apt-get clean 2>/dev/null || true
  run_with_sudo dpkg --configure -a 2>/dev/null || true
  log_success "APT state cleaned"
}

# Function to update APT with retries and error handling
robust_apt_update() {
  log_info "📦 Updating APT package lists with retry logic..."
  local max_attempts=5
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    log_info "APT update attempt $attempt of $max_attempts..."
    
    if run_with_sudo apt-get update \
        -o Acquire::http::No-Cache=true \
        -o Acquire::Retries=3 \
        -o Acquire::ForceIPv4=true \
        -o APT::Get::Fix-Missing=true \
        -o APT::Get::Fix-Broken=true; then
      log_success "✅ APT update successful on attempt $attempt"
      return 0
    else
      log_warn "⚠️ APT update attempt $attempt failed"
      
      if [ $attempt -lt $max_attempts ]; then
        log_info "💤 Waiting $((attempt * 10)) seconds before retry..."
        sleep $((attempt * 10))
        
        # Clean state before retry
        clean_apt_state
        
        # Try changing to a different mirror on later attempts
        if [ $attempt -ge 3 ]; then
          log_info "🔄 Attempting to use different mirror..."
          run_with_sudo sed -i 's|http://archive.ubuntu.com|http://us.archive.ubuntu.com|g' /etc/apt/sources.list 2>/dev/null || true
        fi
      fi
      
      ((attempt++))
    fi
  done
  
  log_error "❌ APT update failed after $max_attempts attempts"
  return 1
}

# Function to install packages with robust error handling
robust_apt_install() {
  local packages=("$@")
  log_info "🔧 Installing packages with robust error handling: ${packages[*]}"
  
  # First ensure we have clean, updated package lists
  if ! robust_apt_update; then
    log_error "Cannot proceed with package installation - APT update failed"
    return 1
  fi
  
  local max_attempts=3
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    log_info "Package installation attempt $attempt of $max_attempts..."
    
    if run_with_sudo apt-get install -y \
        -o APT::Get::Fix-Missing=true \
        -o APT::Get::Fix-Broken=true \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        "${packages[@]}"; then
      log_success "✅ Package installation successful on attempt $attempt"
      return 0
    else
      log_warn "⚠️ Package installation attempt $attempt failed"
      
      if [ $attempt -lt $max_attempts ]; then
        log_info "🔧 Attempting to fix broken packages..."
        run_with_sudo apt-get -f install -y 2>/dev/null || true
        run_with_sudo dpkg --configure -a 2>/dev/null || true
        
        log_info "💤 Waiting $((attempt * 5)) seconds before retry..."
        sleep $((attempt * 5))
        
        # Try installing packages individually if this is the last attempt
        if [ $attempt -eq $((max_attempts - 1)) ]; then
          log_info "🔄 Trying individual package installation..."
          local failed_packages=()
          for pkg in "${packages[@]}"; do
            if ! run_with_sudo apt-get install -y "$pkg" \
                -o APT::Get::Fix-Missing=true \
                -o APT::Get::Fix-Broken=true; then
              failed_packages+=("$pkg")
              log_warn "Failed to install individual package: $pkg"
            else
              log_success "Successfully installed: $pkg"
            fi
          done
          
          if [ ${#failed_packages[@]} -eq 0 ]; then
            log_success "✅ All packages installed individually"
            return 0
          else
            log_warn "⚠️ Failed packages: ${failed_packages[*]}"
          fi
        fi
      fi
      
      ((attempt++))
    fi
  done
  
  log_error "❌ Package installation failed after $max_attempts attempts"
  return 1
}

run_with_sudo() {
  if [[ $EUID -ne 0 ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

# ----------- Install Dependencies ----------------------------
install_required_dependencies() {
  log_info "Installing required dependencies..."
  local packages=(curl zip unzip apt-utils fakeroot dos2unix shellcheck software-properties-common)
  
  if [[ "${TEST_MODE:-false}" == "true" ]]; then
    log_info "[TEST MODE] Would install: ${packages[*]}"
    return 0
  fi
  
  if robust_apt_install "${packages[@]}"; then
    log_success "✅ Required dependencies installed successfully"
  else
    log_error "❌ FATAL: Failed to install required dependencies"
    return 1
  fi
}

# ---------------- Flag Handling and Validation ----------------
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --project-name NAME        Optional: Project name (default: buildserver)"
  echo "  --project-path PATH        Path to install (default: $PROJECT_PATH)"
  echo "  -h, --help                 Show this help message"
  exit 0
}

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --project-name)
      PROJECT_NAME="$2"
      PROJECT_PATH="${CALLER_HOME}/${PROJECT_NAME}"
      shift 2
      ;;
    --project-path)
      PROJECT_PATH="$2"
      shift 2
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

# -----  Run as root check ----------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# ------- Function to check for existing vagrant deployment -------------------
check_vagrant_user() {
  if id "vagrant" &>/dev/null; then
    echo "Detected Vagrant/VirtualBox deployment. You should cancel and use (quick-setup), continue to update? [Y/n]"
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

# -------- Function to generate a version ID to support lifecycle ------------
generate_version_id() {
    echo "v$(date '+%Y%m%d_%H%M%S')"
}

# Store the generated version ID
VERSION_ID=$(generate_version_id)
# Ensure the file exists
[ -f "$PROJECT_PATH/$DOT_BUILDSERVER/version.txt" ] || touch "$PROJECT_PATH/$DOT_BUILDSERVER/version.txt"
# Append the version
echo "$VERSION_ID" >> "$PROJECT_PATH/$DOT_BUILDSERVER/version.txt"

# --------- Function to add optional aliases ---------------------------------
import_menu_aliases() {
  local aliases_file="$CALLER_HOME/.bash_aliases"
  local -A menu_aliases=(
    ["cls"]="clear"
    ["quick-setup"]="$PROJECT_PATH/common/menu/quick_setup.sh"
    ["motd"]="/etc/update-motd.d/99-custom-motd"
    ["renv"]="source $CALLER_HOME/.env"
    ["denv"]="source $PROJECT_PATH/common/profile/env.example"
    ["python"]="python3"
    ["clusters"]="kubectl config get-clusters"
    ["kci"]="kubectl cluster-info"
  )

  # Create the file if it doesn't exist
  touch "$aliases_file"

  local added_any=false

  # Append aliases only if they aren't already present
  for alias in "${!menu_aliases[@]}"; do
    if ! grep -qE "^alias $alias=" "$aliases_file"; then
      echo "alias $alias='${menu_aliases[$alias]}'" >> "$aliases_file"
      log_info "Added alias: $alias -> ${menu_aliases[$alias]}"
      added_any=true
    else
      log_info "Alias '$alias' already exists, skipping."
    fi
  done

  # Source the aliases to apply them immediately
  if [[ "$added_any" == true ]]; then
    log_info "Loading new aliases into current shell..."
    # shellcheck disable=SC1090
    source "$aliases_file"
  else
    log_info "No new aliases added. Nothing to load."
  fi
}

# ----------Function to set execute permissions to scripts folder ------------
make_scripts_executable() {
  log_info "Setting +x on sh files in scripts folder..."
  find "$PROJECT_PATH/common/scripts" -type f -name "*.sh" -exec chmod +x {} \; && \
    log_success "Permissions set successfully." || log_error "FATAL: Setting permissions failed."
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
  echo "export PATH=\$PATH:$CALLER_HOME/.local/bin" >> "$CALLER_HOME/.bashrc" && \
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

# ----- Add User to Docker Group ----------------------------------------------
add_user_to_docker() {
  log_info "Adding user $ORIGINAL_USER to the Docker group..."
  run_with_sudo usermod -aG docker "$ORIGINAL_USER" && \
    log_success "User $ORIGINAL_USER added to Docker group." || log_error "FATAL: Failed to add user $ORIGINAL_USER to Docker group."
}

# ----- Install NVM -----------------------------------------------------------
install_nvm() {
  log_info "Installing NVM..."
  sudo -i -u "$ORIGINAL_USER" "$PROJECT_PATH/common/scripts/deploy_nvm.sh" && \
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
  local version="v3.14.0"
  log_info "Installing Helm version $version..."

  run_with_sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
  chmod 700 get_helm.sh && \
  HELM_INSTALL_DIR="/usr/local/bin" DESIRED_VERSION="$version" ./get_helm.sh && \
    log_success "Helm $version installed." || log_error "FATAL: Helm installation failed. If this was a --provision you can likely ignore"
}

# ----- Install k3d -----------------------------------------------------------
install_k3d() {
  log_info "Installing k3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash && \
    log_success "k3d Installed." || log_error "FATAL: k3d Installation failed. If this was a --provision you can likely ignore"
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

# ----- Update Project Directory Permissions ----------------------------------
update_home_permissions() {
  log_info "Updating project directory permissions..."
  run_with_sudo chgrp -R "$ORIGINAL_USER" "$PROJECT_PATH" && \
    run_with_sudo chown -R "$ORIGINAL_USER" "$PROJECT_PATH" && \
    log_success "Project directory permissions updated." || log_error "FATAL: Failed to update Project directory permissions."
}

# ----- Update and Upgrade System (Fault-Tolerant) -------------------------
update_system() {
  log_info "🧼 Preparing system for updates..."
  clean_apt_state
  
  if robust_apt_update; then
    log_info "🚀 Upgrading system packages..."
    if run_with_sudo apt-get upgrade -y \
        -o APT::Get::Fix-Missing=true \
        -o APT::Get::Fix-Broken=true \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold"; then
      log_success "✅ System updated and upgraded successfully"
    else
      log_error "⚠️ NON-FATAL: System upgrade encountered issues but continuing..."
    fi
  else
    log_error "⚠️ NON-FATAL: System update failed but continuing with installation..."
  fi
}

# ----- Configure Git ---------------------------------------------------------
configure_git() {
  log_info "Configuring Git global settings..."
  git config --global user.email "$ORIGINAL_USER@buildserver.local" && \
    git config --global --add safe.directory "$CALLER_HOME/repos" && \
    git config --global user.name "$ORIGINAL_USER" && \
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
  local essential_packages=(
    jq kubectl dos2unix build-essential git python3-pip python3 pkg-config
    net-tools apt-transport-https unzip gnupg software-properties-common 
    docker-compose-plugin terraform gnupg2 xclip
  )
  
  if robust_apt_install "${essential_packages[@]}"; then
    log_success "✅ Essential packages installed successfully"
  else
    log_error "❌ FATAL: Essential packages installation failed"
    return 1
  fi
}

# ----- Modify bashrc ---------------------------------------------------------
modify_bashrc() {
  log_info "Modifying .bashrc to source .env and export PROJECT_PATH..."

  local bashrc_file="$CALLER_HOME/.bashrc"
  local env_source="[ -f \"$CALLER_HOME/.env\" ] && source \"$CALLER_HOME/.env\""
  local project_path_export="export PROJECT_PATH=\"$PROJECT_PATH\""

  # Add .env sourcing if not already present
  if grep -Fxq "$env_source" "$bashrc_file"; then
    log_info ".env sourcing already present in .bashrc. Skipping."
  else
    echo -e "\n# Auto-injected by buildserver provisioner" >> "$bashrc_file"
    echo "$env_source" >> "$bashrc_file"
    log_success ".bashrc modified to source .env."
  fi

  # Add PROJECT_PATH export if not already present
  if grep -q "^export PROJECT_PATH=" "$bashrc_file"; then
    log_info "PROJECT_PATH export already present in .bashrc. Updating..."
    sed -i "s|^export PROJECT_PATH=.*|$project_path_export|" "$bashrc_file"
  else
    echo "$project_path_export" >> "$bashrc_file"
  fi
  
  log_success "PROJECT_PATH exported in .bashrc: $PROJECT_PATH"
}

# ----- Generate Initial SBOM -------------------------------------------------
generate_initial_sbom() {
  log_info "Generating initial SBOM..."

  local sbom_file="$PROJECT_PATH/initial_sbom"
  local package_list=(
    curl zip unzip apt-utils fakeroot dos2unix software-properties-common jq
    kubectl build-essential git nvm python3-pip python3 pkg-config shellcheck
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

# ----- Cleanup ----------------------------------------------------------------
cleanup() {
  log_info "Performing cleanup..."
  run_with_sudo rm -f ./get_helm.sh
  run_with_sudo rm -f awscliv2.zip
  run_with_sudo rm -rf aws
  log_success "Installer artifacts removed (Helm, AWS)." || \
    log_error "NON-FATAL: Some cleanup files may not have existed."
}

#------- Ensure files under CALLER_HOME are owned by the original user ---------
fix_ownership_in_home() {
  log_info "Ensuring proper ownership for all files in $CALLER_HOME"
  
  if [[ "$IS_VAGRANT_ENV" == true ]]; then
    # Vagrant-specific ownership fixes
    find "$CALLER_HOME" -user root -exec chown vagrant:vagrant {} + 2>/dev/null || true
    find "$PROJECT_PATH" -user root -exec chown vagrant:vagrant {} + 2>/dev/null || true
    find "$PROJECT_PATH/$DOT_BUILDSERVER" -user root -exec chown vagrant:vagrant {} + 2>/dev/null || true
  else
    # Standard ownership fixes
    find "$CALLER_HOME" -user root -exec chown "$ORIGINAL_USER" {} + 2>/dev/null || true
    find "$CALLER_HOME" -group root -exec chgrp "$ORIGINAL_USER" {} + 2>/dev/null || true
    find "$PROJECT_PATH/$DOT_BUILDSERVER" -user root -exec chown "$ORIGINAL_USER" {} + 2>/dev/null || true
    find "$PROJECT_PATH/$DOT_BUILDSERVER" -group root -exec chgrp "$ORIGINAL_USER" {} + 2>/dev/null || true
  fi
  
  log_success "Ownership corrected for user: $ORIGINAL_USER"
}

# ----- Main Execution ----------------------------------------------------------

main() {
  install_required_dependencies
  check_vagrant_user
  make_scripts_executable
  display_banner
  add_custom_motd
  import_menu_aliases
  create_directories
  copy_profile_files
  configure_hostname_hosts
  install_preflight
  install_docker
  add_user_to_docker
  install_nvm 
  configure_terraform_repo
  install_helm
  install_k3d
  configure_kubectl_repo
  update_home_permissions
  configure_git
  clone_repositories
  modify_bashrc
  update_home_permissions
  update_system
  install_packages
  generate_initial_sbom
  cleanup
  fix_ownership_in_home

# Final messaging based on user type
if [[ "$IS_VAGRANT_ENV" == true ]]; then
  echo "=================== Vagrant-VirtualBox Deployment ========================"
  echo "| Standby rebooting, this will take only a moment...                     |"
  echo "=========================================================================="
else
  echo "===================== Linux WSL All others ==============================="
  echo "| Logout and log back in to see changes. :)                              |"
  echo "=========================================================================="
fi
  log_info "⚠️  Please log out and log back in to apply Docker group membership changes."
}

main "$@"

# sleeping to ensure apt updates are completed
sleep 10
echo "=========================================================================="
# Print version ID
echo ""
echo "Script Version: $VERSION_ID (Saved to ${PROJECT_PATH}/$DOT_BUILDSERVER/version.txt)"
echo ""
echo "=========================================================================="
echo "=========================================================================="
echo "| Provisioning Log     | saved to ${PROJECT_PATH}/logs/provisioning.log |"
echo "| Software Packages    | exported to $PROJECT_PATH/initial_sbom          |"
echo "=========================================================================="
echo -e "\\n\033[1;31m[✖] Errors Detected:\033[0m"
grep --color=always ERROR "$PROJECT_PATH/logs/provisioning.log" || echo "No errors found!"
echo "=========================================================================="
echo -e "\\n\033[1;32m[✔] Successful Tasks:\033[0m"
grep --color=always SUCCESS "$PROJECT_PATH/logs/provisioning.log" || echo "No successful tasks logged!"

echo ""
echo "=================== Vagrant-VirtualBox Deployment ========================"
echo "| If errors, fix and reprovision, vagrant up --provision. If this is a   |"
echo "| You can likely ignore NON-FATAL errors if reprovisioning.              |"
echo "|                                                                        |"
echo "| SSH with vagrant ssh or your terminal of choice.                       |"
echo "| Login: vagrant:privatekey port:2222                                    |"
echo "=========================================================================="
echo ""
echo "===================== Linux WSL All others ==============================="
echo "| Logout and log back in to see changes.                                 |"
echo "=========================================================================="

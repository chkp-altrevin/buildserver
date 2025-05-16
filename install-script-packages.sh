#!/usr/bin/env bash
# install-script.sh
set -euo pipefail

# === Constants ===
DEFAULT_PROJECT_PATH="${HOME}/buildserver"
BACKUP_DIR="${HOME}/backup"
MAX_BACKUPS=3
REPO_URL="https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
INSTALL=false
INSTALL_CUSTOM=false
REPO_DOWNLOAD=false
SUDO=""
LOG_FILE="$HOME/install-script.log"
CREATED_FILES=()

# === Logging ===
log_info()    { echo -e "[INFO]    $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_success() { echo -e "[SUCCESS] $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "[ERROR]   $(date '+%F %T') - $*" | tee -a "$LOG_FILE" >&2; }

validate_install() {
  local cmd=$1
  local name=$2
  if command -v "$cmd" &>/dev/null; then
    log_success "$name validation passed."
  else
    log_error "$name validation failed: not found in PATH."
  fi
}

install_core_dependencies() {
  log_info "Installing core packages..."
  $SUDO apt-get update -yq
  $SUDO apt-get install -yq jq dos2unix build-essential git pkg-config shellcheck net-tools apt-transport-https unzip gnupg software-properties-common pass gpg gnupg2 xclip pinentry-tty
  validate_install jq "jq"
  validate_install git "git"
  validate_install unzip "unzip"
  log_success "Core dependencies installed."
}

install_helm() {
  if ! command -v helm &>/dev/null; then
    log_info "Installing Helm..."
    $SUDO apt-get install -y helm
  fi
  validate_install helm "Helm"
}

install_k3d() {
  if ! command -v k3d &>/dev/null; then
    log_info "Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  fi
  validate_install k3d "k3d"
}

install_kubectl() {
  if ! command -v kubectl &>/dev/null; then
    log_info "Installing kubectl..."
    $SUDO apt-get install -y kubectl
  fi
  validate_install kubectl "kubectl"
}

install_nvm() {
  if ! command -v nvm &>/dev/null && [ ! -s "$HOME/.nvm/nvm.sh" ]; then
    log_info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  fi
  [[ -s "$HOME/.nvm/nvm.sh" ]] && log_success "nvm installed and loaded." || log_error "nvm install failed."
}

install_python() {
  if ! command -v python3 &>/dev/null || ! command -v pip3 &>/dev/null; then
    log_info "Installing Python and pip..."
    $SUDO apt-get install -y python3 python3-pip
  fi
  validate_install python3 "Python3"
  validate_install pip3 "pip3"
}

install_docker() {
  if ! command -v docker &>/dev/null; then
    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    $SUDO apt-get install -y docker-compose-plugin
  fi
  validate_install docker "Docker"
  validate_install docker-compose "Docker Compose Plugin"
}

install_terraform() {
  log_info "Installing Terraform..."
  $SUDO apt-get install -y terraform
  validate_install terraform "Terraform"
}

install_gcloud() {
  log_info "Installing Google Cloud CLI..."
  $SUDO apt-get install -y google-cloud-cli
  validate_install gcloud "Google Cloud CLI"
}

install_powershell() {
  log_info "Installing PowerShell..."
  $SUDO apt-get install -y powershell
  validate_install pwsh "PowerShell"
}

install_azure_cli() {
  log_info "Installing Azure CLI..."
  $SUDO apt-get install -y azure-cli
  validate_install az "Azure CLI"
}

run_custom_installs() {
  install_core_dependencies
  install_helm
  install_k3d
  install_kubectl
  install_nvm
  install_python
  install_docker
  install_terraform
  install_gcloud
  install_powershell
  install_azure_cli
}

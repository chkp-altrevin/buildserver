#!/usr/bin/env bash

# Ensure unzip is available
command -v unzip >/dev/null 2>&1 || {
  echo "[INFO] unzip not found. Installing..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install unzip
  elif command -v apt-get >/dev/null; then
    sudo apt-get update && sudo apt-get install -y unzip
  elif command -v yum >/dev/null; then
    sudo yum install -y unzip
  elif command -v apk >/dev/null; then
    apk add unzip
  else
    echo "[ERROR] Could not determine package manager to install unzip." >&2
    exit 1
  fi
}

set -euo pipefail

OS_TYPE="$(uname)"
DEFAULT_DIR="buildserver"
FORCE=false
DRY_RUN=false
RESTORE_FILE=""
CUSTOM_PROJECT_PATH=""

get_home_path() {
  case "$OS_TYPE" in
    Darwin|Linux)
      echo "$HOME"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "$(cmd.exe /C "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')"
      ;;
    *)
      echo "$HOME"
      ;;
  esac
}

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --vagrant-virtualbox)
        VAGRANT_VIRTUALBOX=true
        ;;

  for arg in "$@"; do
    case "$arg" in
      --force)
        FORCE=true
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      --restore=*)
        RESTORE_FILE="${arg#--restore=}"
        ;;
      --project-path=*)
        CUSTOM_PROJECT_PATH="${arg#--project-path=}"
        ;;
    esac
  done
}

HOME_PATH="$(get_home_path)"
PROJECT_PATH="${HOME_PATH}/${CUSTOM_PROJECT_PATH:-$DEFAULT_DIR}"
BACKUP_DIR="${HOME_PATH}/backup"
ZIP_URL="https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
ZIP_FILE="main.zip"
TMP_DIR="$(mktemp -d)"
KEEP_BACKUPS=3
VAGRANT_VIRTUALBOX=false

install_vagrant_virtualbox() {
  read -rp "âš ï¸  This will install Vagrant and VirtualBox. Continue? [Y/n] " confirm
  case "$confirm" in
    [Nn]*)
      log "Operation cancelled by user."
      exit 0
      ;;
  esac

  case "$OS_TYPE" in
    Darwin)
      if ! command -v brew >/dev/null; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
      fi
      log "Installing Vagrant and VirtualBox via Homebrew..."
      brew install --cask vagrant
      brew install --cask virtualbox
      ;;
    Linux)
      if command -v apt-get >/dev/null; then
        log "Installing Vagrant and VirtualBox via apt-get..."
        sudo apt-get update
        sudo apt-get install -y vagrant virtualbox
      elif command -v yum >/dev/null; then
        log "Installing Vagrant and VirtualBox via yum..."
        sudo yum install -y vagrant VirtualBox
      else
        error "Unsupported Linux distribution. Install manually."
        exit 1
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      log "Detected Windows. Downloading Vagrant and VirtualBox installers..."
      TEMP_DIR="$(cmd.exe /C "echo %TEMP%" 2>/dev/null | tr -d '\r')"
      curl -L -o "$TEMP_DIR\vagrant.exe" https://releases.hashicorp.com/vagrant/2.4.1/vagrant_2.4.1_x86_64.msi
      curl -L -o "$TEMP_DIR\virtualbox.exe" https://download.virtualbox.org/virtualbox/7.0.18/VirtualBox-7.0.18-162988-Win.exe
      log "Launching installers..."
      start "" "$TEMP_DIR\vagrant.exe"
      start "" "$TEMP_DIR\virtualbox.exe"
      ;;
    *)
      error "Unsupported OS: $OS_TYPE"
      exit 1
      ;;
  esac
  log "âœ… Vagrant and VirtualBox installation initiated."
}


log()    { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
warn()   { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
error()  { echo -e "\033[1;31m[ERR!]\033[0m  $*"; }

restore_backup() {
  local zipfile="$1"
  if [[ ! -f "$BACKUP_DIR/$zipfile" ]]; then
    error "Backup file '$BACKUP_DIR/$zipfile' not found."
    exit 1
  fi
  read -rp "âš ï¸  This will replace $PROJECT_PATH with $zipfile. Continue? [Y/n] " response
  case "$response" in
    [Nn]*)
      log "Restore aborted."
      exit 0
      ;;
    *)
      log "Restoring from $zipfile..."
      $DRY_RUN && log "[DRY-RUN] Would unzip $zipfile and replace $PROJECT_PATH" && exit 0
      unzip -o "$BACKUP_DIR/$zipfile" -d "$TMP_DIR"
      rm -rf "$PROJECT_PATH"
      mv "$TMP_DIR/buildserver" "$PROJECT_PATH"
      log "âœ… Restore completed to $PROJECT_PATH."
      exit 0
      ;;
  esac
}

download_and_setup() {
  mkdir -p "$BACKUP_DIR"

  if [[ -d "$PROJECT_PATH" && "$FORCE" != true ]]; then
    read -rp "âš ï¸  $PROJECT_PATH already exists. Replace contents? [Y/n] " answer
    case "$answer" in
      [Nn]*)
        log "Operation cancelled by user."
        exit 0
        ;;
    esac
  fi

  if [[ -d "$PROJECT_PATH" ]]; then
    local backup_name="buildserver_backup_$(date +%Y%m%d%H%M%S).zip"
    log "ðŸ“¦ Backing up $PROJECT_PATH to $BACKUP_DIR/$backup_name"
    $DRY_RUN && log "[DRY-RUN] Would zip $PROJECT_PATH to $BACKUP_DIR/$backup_name" || zip -r "$BACKUP_DIR/$backup_name" "$PROJECT_PATH" >/dev/null
    ls -tp "$BACKUP_DIR"/buildserver_backup_*.zip | grep -v '/$' | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm --
  fi

  log "â¬‡ï¸  Downloading and extracting from $ZIP_URL"
  $DRY_RUN && log "[DRY-RUN] Would download and extract to $PROJECT_PATH" && exit 0

  curl -L "$ZIP_URL" -o "$TMP_DIR/$ZIP_FILE"
  unzip -o "$TMP_DIR/$ZIP_FILE" -d "$TMP_DIR"
  rm -rf "$PROJECT_PATH"
  mv "$TMP_DIR/buildserver-main" "$PROJECT_PATH"
  find "$PROJECT_PATH" -type f -name "*.sh" -exec chmod +x {} \;
  log "âœ… Setup complete at $PROJECT_PATH"
}

display_help() {
  cat <<EOF
Usage: provision.sh [OPTIONS]

Options:
  --install                   Run the provisioning steps
  --project-path=<name>       Set project folder name (defaults to 'buildserver')
  --restore=<zipfile>         Restore from existing backup zip
  --force                     Overwrite without confirmation
  --dry-run                   Show what would happen without making changes
  --vagrant-virtualbox        Install Vagrant and VirtualBox
  --help                      Show this help message

EOF
}

check_privileges() {
  if [[ "$OS_TYPE" == "Linux" || "$OS_TYPE" == "Darwin" ]]; then
    if [[ "$EUID" -ne 0 && "$FORCE" != true ]]; then
      warn "âš ï¸  Script not run as root. Some actions may require sudo."
      sudo -v || { error "âŒ Sudo required. Exiting."; exit 1; }
    fi
  elif [[ "$OS_TYPE" == MINGW* || "$OS_TYPE" == MSYS* || "$OS_TYPE" == CYGWIN* ]]; then
    net session >nul 2>&1
    if ($LASTEXITCODE -ne 0) {
      warn "âš ï¸  Please run this PowerShell terminal as Administrator."
    }
  fi
}

check_versions() {
  REQUIRED_VAGRANT="2.4.1"
  REQUIRED_VIRTUALBOX="7.0"

  CURRENT_VAGRANT=$(vagrant --version 2>/dev/null | awk '{print $2}')
  CURRENT_VIRTUALBOX=$(VBoxManage --version 2>/dev/null | cut -d'r' -f1)

  if [[ -n "$CURRENT_VAGRANT" ]]; then
    log "Detected Vagrant version: $CURRENT_VAGRANT"
  fi
  if [[ -n "$CURRENT_VIRTUALBOX" ]]; then
    log "Detected VirtualBox version: $CURRENT_VIRTUALBOX"
  fi
}

install_vagrant_virtualbox() {
  read -rp "âš ï¸  This will install Vagrant and VirtualBox. Continue? [Y/n] " confirm
  case "$confirm" in
    [Nn]*)
      log "Operation cancelled by user."
      exit 0
      ;;
  esac

  case "$OS_TYPE" in
    Darwin)
      if ! command -v brew >/dev/null; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
      fi
      brew install --cask vagrant
      brew install --cask virtualbox
      ;;
    Linux)
      if command -v apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y vagrant virtualbox
      elif command -v yum >/dev/null; then
        sudo yum install -y vagrant VirtualBox
      else
        error "Unsupported Linux distribution. Install manually."
        exit 1
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      TEMP_DIR="$(cmd.exe /C "echo %TEMP%" 2>/dev/null | tr -d '\r')"
      curl -L -o "$TEMP_DIR\vagrant.msi" https://releases.hashicorp.com/vagrant/2.4.1/vagrant_2.4.1_x86_64.msi
      curl -L -o "$TEMP_DIR\virtualbox.exe" https://download.virtualbox.org/virtualbox/7.0.18/VirtualBox-7.0.18-162988-Win.exe
      powershell -Command "[System.Windows.Forms.MessageBox]::Show('Installing Vagrant and VirtualBox...', 'Wyrd Provision Installer')"
      start /wait msiexec.exe /i "$TEMP_DIR\vagrant.msi" /quiet /norestart
      start /wait "$TEMP_DIR\virtualbox.exe" --silent --ignore-reboot
      ;;
    *)
      error "Unsupported OS: $OS_TYPE"
      exit 1
      ;;
  esac
  log "âœ… Vagrant and VirtualBox installation completed."
}

  parse_args "$@"
  log "Using OS: $OS_TYPE"
  log "Target path: $PROJECT_PATH"
  log "Backup directory: $BACKUP_DIR"
  $DRY_RUN && log "[DRY-RUN MODE ENABLED] No changes will be made."
  if [[ "$VAGRANT_VIRTUALBOX" == true ]]; then
    install_vagrant_virtualbox
    exit 0
  fi

  parse_args "$@"
  log "Using OS: $OS_TYPE"
  log "Target path: $PROJECT_PATH"
  log "Backup directory: $BACKUP_DIR"
  $DRY_RUN && log "[DRY-RUN MODE ENABLED] No changes will be made."
  if [[ -n "$RESTORE_FILE" ]]; then
    restore_backup "$RESTORE_FILE"
  else
    download_and_setup
  fi
}

main "$@"

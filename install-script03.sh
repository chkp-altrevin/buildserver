#!/usr/bin/env bash
set -euo pipefail

# === Constants ===
PROJECT_PATH="${HOME}/buildserver"
BACKUP_DIR="${HOME}/backup"
MAX_BACKUPS=3
REPO_URL="https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
REPO_INSTALL=false
REPO_DOWNLOAD=false
UPGRADE=false
CLEANUP=false
SUDO=""
LOG_FILE="$HOME/install-script.log"
CREATED_FILES=()
IS_WINDOWS=false

# === Logging ===
log_info()    { echo -e "[INFO]    $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_success() { echo -e "[SUCCESS] $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "[ERROR]   $(date '+%F %T') - $*" | tee -a "$LOG_FILE" >&2; }

cleanup() {
  log_info "Starting cleanup..."
  for file in "${CREATED_FILES[@]}"; do
    if [[ -e "$file" ]]; then
      rm -rf "$file"
      log_info "Removed: $file"
    fi
  done
  log_success "Cleanup complete."
  exit 0
}

trap 'log_error "An unexpected error occurred."; cleanup' ERR

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --install                 Download project and run provision.sh
  --repo-download           Download project only
  --project-path=PATH       Custom install location (default: $HOME/buildserver)
  --restore=FILE            Restore from a previous backup zip
  --virtualbox-vagrant-win  Use VirtualBox/Vagrant flow (for Windows Git Bash users)
  --help                    Show this help message

Example: ./install-script.sh --repo-download
EOF
  exit 0
}

parse_args() {
  RESTORE=""
  INSTALL=false
  REPO_DOWNLOAD=false
  VBOX_VAGRANT_WIN=false

  for arg in "$@"; do
    case "$arg" in
      --restore=*)
        RESTORE="${arg#*=}"
        ;;
      --install)
        INSTALL=true
        ;;
      --repo-download)
        REPO_DOWNLOAD=true
        ;;
      --virtualbox-vagrant-win)
        VBOX_VAGRANT_WIN=true
        ;;
      --project-path=*)
        PROJECT_PATH="${arg#*=}"
        ;;
      --help)
        usage
        ;;
      *)
        log_error "Unknown flag: $arg"
        usage
        ;;
    esac
  done
}

require_root_or_sudo() {
  if [ "$(id -u)" -ne 0 ]; then
    log_info "This script may require root privileges. Re-run with sudo if needed."
    SUDO="sudo"
  fi
}

check_dependencies() {
  REQUIRED_CMDS=(curl)
  MISSING=()

  if [[ "$VBOX_VAGRANT_WIN" = false && "$IS_WINDOWS" = false ]]; then
    REQUIRED_CMDS+=(zip unzip)
  fi

  for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      MISSING+=("$cmd")
    fi
  done

  if [ ${#MISSING[@]} -eq 0 ]; then
    return
  fi

  log_error "Missing required dependencies: ${MISSING[*]}"
  read -rp "Would you like to attempt to install them now? (yes/no): " CONFIRM

  case "$CONFIRM" in
    yes|y|Y)
      if command -v apt-get >/dev/null; then
        $SUDO apt-get update && $SUDO apt-get install -y "${MISSING[@]}"
      elif command -v yum >/dev/null; then
        $SUDO yum install -y "${MISSING[@]}"
      elif command -v dnf >/dev/null; then
        $SUDO dnf install -y "${MISSING[@]}"
      elif command -v apk >/dev/null; then
        $SUDO apk add --no-cache "${MISSING[@]}"
      elif command -v pacman >/dev/null; then
        $SUDO pacman -Sy --noconfirm "${MISSING[@]}"
      elif command -v brew >/dev/null; then
        brew install "${MISSING[@]}"
      else
        log_error "Unsupported package manager. Please install manually: ${MISSING[*]}"
        exit 1
      fi
      ;;
    *)
      log_error "Dependencies not installed. Exiting."
      exit 1
      ;;
  esac
}

backup_existing_project() {
  if [ -d "$PROJECT_PATH" ]; then
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    BACKUP_FILE="${BACKUP_DIR}/buildserver_${TIMESTAMP}.zip"
    mkdir -p "$BACKUP_DIR"
    if [[ "$IS_WINDOWS" = true ]]; then
      powershell.exe Compress-Archive -Path "$PROJECT_PATH\*" -DestinationPath "$BACKUP_FILE"
    else
      zip -r "$BACKUP_FILE" "$PROJECT_PATH" >/dev/null
    fi
    log_info "Existing project backed up to $BACKUP_FILE"
    CREATED_FILES+=("$BACKUP_FILE")
    ls -1t "${BACKUP_DIR}"/buildserver_*.zip | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm --
  fi
}

restore_backup() {
  BACKUP_FILE="${BACKUP_DIR}/${RESTORE}"
  if [ ! -f "$BACKUP_FILE" ]; then
    log_error "Backup file '$BACKUP_FILE' not found."
    exit 1
  fi

  log_info "Restoring backup from '$BACKUP_FILE' to '$PROJECT_PATH'"
  read -rp "Proceed? (yes/no): " CONFIRM
  case $CONFIRM in
    yes|y|Y)
      rm -rf "$PROJECT_PATH"
      if [[ "$IS_WINDOWS" = true ]]; then
        powershell.exe Expand-Archive -Path "$BACKUP_FILE" -DestinationPath "$PROJECT_PATH"
      else
        unzip -q "$BACKUP_FILE" -d "$(dirname "$PROJECT_PATH")"
      fi
      find "$PROJECT_PATH" -type f -name "*.sh" -exec chmod +x {} \;
      log_success "Project restored."
      exit 0
      ;;
    *)
      log_info "Restore aborted."
      exit 0
      ;;
  esac
}

main() {
  parse_args "$@"

  # Detect if running on Windows natively
  if [[ "${OS:-}" == "Windows_NT" || "$(uname -o 2>/dev/null)" == "Msys" ]]; then
    IS_WINDOWS=true
  fi
  
  require_root_or_sudo
  check_dependencies

  # Vagrant/VirtualBox handled here if flagged
  if [ "$VBOX_VAGRANT_WIN" = true ]; then
    handle_virtualbox_vagrant_win
  fi

  if [ "$#" -eq 0 ]; then
    usage
  fi

  if [ "$REPO_DOWNLOAD" = true ]; then
    log_info "Download-only mode to: $PROJECT_PATH"
    backup_existing_project
    restore_backup
    exit 0
  fi

  if [ "$INSTALL" = true ]; then
    log_info "Running full install to: $PROJECT_PATH"
    backup_existing_project
    install_project
    exit 0
  fi

  if [ -n "$RESTORE" ]; then
    restore_backup
  fi
}

main "$@"

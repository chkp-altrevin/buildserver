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
  --install                 Download project and run provision.sh (can be used with other flags)
  --repo-download       Download project only, no execution
  --project-path=PATH   Custom install location (default: $HOME/buildserver)
  --restore=FILE        Restore from a previous backup zip
  --help                Show this help message
  
Examples:
  ./install-script.sh --install
  ./install-script.sh --install --project-path=/custom/path
EOF
  exit 0
}

parse_args() {
  RESTORE=""
  INSTALL=false
  REPO_DOWNLOAD=false

  # Default project path
  PROJECT_PATH="${HOME}/buildserver"

  for arg in "$@"; do
    case "$arg" in
      --project-path=*)
        PROJECT_PATH="${arg#*=}"
        ;;
      --restore=*)
        RESTORE="${arg#*=}"
        ;;
      --install)
        INSTALL=true
        ;;
      --repo-download)
        REPO_DOWNLOAD=true
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
  REQUIRED_CMDS=(curl zip unzip)
  MISSING=()

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

set_persistent_project_path() {
  local bashrc="$HOME/.bashrc"
  local current_path
  current_path="$(pwd)"

  echo "[INFO] Setting PROJECT_PATH to $current_path"

  # Update or append the PROJECT_PATH in .bashrc
  if grep -q "^export PROJECT_PATH=" "$bashrc"; then
    sed -i "s|^export PROJECT_PATH=.*|export PROJECT_PATH=\"$current_path\"|" "$bashrc" && \
      echo "[SUCCESS] Updated existing PROJECT_PATH in $bashrc"
  else
    echo "export PROJECT_PATH=\"$current_path\"" >> "$bashrc" && \
      echo "[SUCCESS] Added new PROJECT_PATH to $bashrc"
  fi

  export PROJECT_PATH="$current_path"
  echo "[INFO] PROJECT_PATH is now active for this session and will persist in future shells."
}

backup_existing_project() {
  if [ -d "$PROJECT_PATH" ]; then
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    BACKUP_FILE="${BACKUP_DIR}/buildserver_${TIMESTAMP}.zip"
    mkdir -p "$BACKUP_DIR"
    zip -r "$BACKUP_FILE" "$PROJECT_PATH" >/dev/null
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
      unzip -q "$BACKUP_FILE" -d "$(dirname "$PROJECT_PATH")"
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

install_project() {
  if [ ! -f "$PROJECT_PATH/provision.sh" ]; then
    log_error "FATAL: provision.sh not found in $PROJECT_PATH"
    exit 1
  fi

  TMP_DIR=$(mktemp -d)
  log_info "Downloading and extracting project archive..."
  curl -fsSL "$REPO_URL" -o "$TMP_DIR/project.zip"
  unzip -q "$TMP_DIR/project.zip" -d "$TMP_DIR"
  EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d)
  rm -rf "$PROJECT_PATH"
  mv "$EXTRACTED_DIR" "$PROJECT_PATH"
  find "$PROJECT_PATH" -type f -name "*.sh" -exec chmod +x {} \;
  CREATED_FILES+=("$PROJECT_PATH")
  rm -rf "$TMP_DIR"

  if [ -x "$PROJECT_PATH/provision01.sh" ]; then
    log_info "Executing provision01.sh..."
    if [ "$EUID" -ne 0 ]; then
      sudo "$PROJECT_PATH/provision01.sh"
    else
      "$PROJECT_PATH/provision01.sh"
    fi
  else
    log_info "provision.sh not found or not executable."
  fi

  log_success "Project installation complete."
}

main() {
  parse_args "$@"

    require_root_or_sudo
  check_dependencies

  if [ "$#" -eq 0 ]; then
    usage
  fi

  if [ "$REPO_DOWNLOAD" = true ]; then
    log_info "Download-only mode to: $PROJECT_PATH"
    
    backup_existing_project

    TMP_DIR=$(mktemp -d)
    log_info "Downloading and extracting project archive..."
    curl -fsSL "$REPO_URL" -o "$TMP_DIR/project.zip"
    unzip -q "$TMP_DIR/project.zip" -d "$TMP_DIR"
    EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d)
    rm -rf "$PROJECT_PATH"
    mv "$EXTRACTED_DIR" "$PROJECT_PATH"
    find "$PROJECT_PATH" -type f -name "*.sh" -exec chmod +x {} \;
    CREATED_FILES+=("$PROJECT_PATH")
    rm -rf "$TMP_DIR"
    log_success "Project downloaded to '$PROJECT_PATH'."
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

  if [ -d "$PROJECT_PATH" ]; then
    read -rp "Project exists at '$PROJECT_PATH'. Overwrite? (yes/no): " CONFIRM
    case $CONFIRM in
      yes|y|Y)
        backup_existing_project
        ;;
      *)
        log_info "Installation aborted."
        exit 0
        ;;
    esac
  else
    backup_existing_project
  fi

  install_project
}

main "$@"

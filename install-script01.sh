#!/usr/bin/env bash
set -euo pipefail

# === Constants ===
export PROJECT_NAME="buildserver"
export PROJECT_PATH="${HOME}/${PROJECT_NAME}"
export BACKUP_DIR="${HOME}/backup"
export LOG_FILE="${HOME}/install-script.log"
export TEST_MODE=false
REPO_URL="https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
CREATED_FILES=()
SUDO=""

# === Logging ===
log_info()    { echo -e "[INFO]    $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_success() { echo -e "[SUCCESS] $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "[ERROR]   $(date '+%F %T') - $*" | tee -a "$LOG_FILE" >&2; }

# === Dependency Handling ===
install_missing_dependencies() {
  local missing=("$@")
  log_info "Attempting to install missing dependencies: ${missing[*]}"
  if command -v apt-get >/dev/null; then
    $SUDO apt-get update && $SUDO apt-get install -y "${missing[@]}"
  elif command -v yum >/dev/null; then
    $SUDO yum install -y "${missing[@]}"
  elif command -v dnf >/dev/null; then
    $SUDO dnf install -y "${missing[@]}"
  elif command -v apk >/dev/null; then
    $SUDO apk add --no-cache "${missing[@]}"
  elif command -v pacman >/dev/null; then
    $SUDO pacman -Sy --noconfirm "${missing[@]}"
  else
    log_error "No supported package manager found. Please install manually: ${missing[*]}"
    exit 1
  fi
}

check_dependencies() {
  local REQUIRED_CMDS=(curl zip unzip)
  local MISSING=()
  for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      MISSING+=("$cmd")
    fi
  done
  if [ ${#MISSING[@]} -gt 0 ]; then
    log_info "Missing dependencies detected: ${MISSING[*]}"
    install_missing_dependencies "${MISSING[@]}"
  fi
}

# === Flags and Usage ===
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --install                 Download and provision the project
  --repo-download           Only download the repository
  --provision               Run provision.sh with current settings
  --project-path=PATH       Set custom project path
  --restore=FILENAME        Restore from a previous backup
  --test                    Dry-run mode (no changes made)
  --help                    Show this help message
EOF
  exit 0
}

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --install) INSTALL=true ;;
      --repo-download) REPO_DOWNLOAD=true ;;
      --provision) PROVISION_ONLY=true ;;
      --test) TEST_MODE=true ;;
      --project-path=*) export PROJECT_PATH="${arg#*=}" ;;
      --restore=*) RESTORE="${arg#*=}" ;;
      --help) usage ;;
      *) log_error "Unknown flag: $arg"; usage ;;
    esac
  done
}

require_root_or_sudo() {
  if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
  fi
}

backup_existing_project() {
  if [ -d "$PROJECT_PATH" ]; then
    mkdir -p "$BACKUP_DIR"
    local backup_file="${BACKUP_DIR}/buildserver_$(date +%Y%m%d%H%M%S).zip"
    zip -r "$backup_file" "$PROJECT_PATH" >/dev/null
    log_info "Backup created: $backup_file"
    CREATED_FILES+=("$backup_file")
  fi
}

download_repo() {
  TMP_DIR=$(mktemp -d)
  curl -fsSL "$REPO_URL" -o "$TMP_DIR/project.zip"
  unzip -q "$TMP_DIR/project.zip" -d "$TMP_DIR"
  EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d)
  rm -rf "$PROJECT_PATH"
  mv "$EXTRACTED_DIR" "$PROJECT_PATH"
  find "$PROJECT_PATH" -type f -name "*.sh" -exec chmod +x {} \;
  rm -rf "$TMP_DIR"
  log_success "Repository installed to $PROJECT_PATH"
}

run_provision() {
  if [ ! -f "$PROJECT_PATH/provision01.sh" ]; then
    log_error "provision01.sh not found in $PROJECT_PATH"
    exit 1
  fi

  log_info "Running provision.sh..."
  ARGS=(--project-name "$PROJECT_NAME" --project-path "$PROJECT_PATH")
  if [[ "$TEST_MODE" == "true" ]]; then
    ARGS+=(--test)
  fi

  TEST_MODE="$TEST_MODE"   PROJECT_NAME="$PROJECT_NAME"   PROJECT_PATH="$PROJECT_PATH"   $SUDO -E bash "$PROJECT_PATH/provision01.sh" "${ARGS[@]}"
}

main() {
  INSTALL=false
  PROVISION_ONLY=false
  REPO_DOWNLOAD=false
  RESTORE=""

  parse_args "$@"
  require_root_or_sudo
  check_dependencies

  if [ "$REPO_DOWNLOAD" = true ]; then
    backup_existing_project
    download_repo
    exit 0
  fi

  if [ -n "$RESTORE" ]; then
    local backup_file="${BACKUP_DIR}/${RESTORE}"
    if [ ! -f "$backup_file" ]; then
      log_error "Restore file not found: $backup_file"
      exit 1
    fi
    unzip -q "$backup_file" -d "$(dirname "$PROJECT_PATH")"
    log_success "Restored from $backup_file"
    exit 0
  fi

  if [ "$INSTALL" = true ]; then
    backup_existing_project
    download_repo
    run_provision
    exit 0
  fi

  if [ "$PROVISION_ONLY" = true ]; then
    run_provision
    exit 0
  fi

  usage
}

main "$@"

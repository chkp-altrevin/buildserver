#!/usr/bin/env bash
set -euo pipefail

# === Constants ===
export PROJECT_NAME="buildserver"
# Safe handling of caller home directory
SUDO_USER="${SUDO_USER:-}"
export CALLER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6 2>/dev/null || echo "$HOME")"
export PROJECT_PATH="${CALLER_HOME}/${PROJECT_NAME}"
export BACKUP_DIR="${CALLER_HOME}/backup"
export LOG_FILE="${CALLER_HOME}/install-script.log"
export TEST_MODE=false
REPO_URL="https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
CREATED_FILES=()
SUDO=""
SUDO=""

# === Logging ===
log_info()    { echo -e "[INFO]    $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_success() { echo -e "[SUCCESS] $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "[ERROR]   $(date '+%F %T') - $*" | tee -a "$LOG_FILE" >&2; }
log_warn()    { echo -e "[WARN]    $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }

# === Flags and Usage ===
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --install                 Download and provision the project
  --repo-download           Only download the repository
  --install-custom          Run provision.sh with optional project path override
  --project-path=PATH       Set custom project path
  --restore=FILENAME        Restore from a previous backup
  --cleanup                 Remove created files and reset state
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
      --install-custom) INSTALL_CUSTOM=true ;;
      --cleanup) CLEANUP=true ;;
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
    local backup_file="${BACKUP_DIR}/${PROJECT_NAME}_$(date +%Y%m%d%H%M%S).zip"

    if ! command -v zip >/dev/null 2>&1; then
      log_error "zip command not found. Cannot backup $PROJECT_PATH."
      exit 1
    fi

    zip -rq "$backup_file" "$PROJECT_PATH" >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
      log_info "Backup created: $backup_file"
      zipinfo "$backup_file" | tee -a "$LOG_FILE"
      CREATED_FILES+=("$backup_file")
    else
      log_error "Backup failed. Aborting before deleting $PROJECT_PATH."
      exit 1
    fi
  fi
}

download_repo() {
  TMP_DIR=$(mktemp -d)
  log_info "Downloading repository to temporary directory..."
  curl -fsSL "$REPO_URL" -o "$TMP_DIR/project.zip"
  unzip -q "$TMP_DIR/project.zip" -d "$TMP_DIR"
  EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d)

  rm -rf "$PROJECT_PATH"
  mv "$EXTRACTED_DIR" "$PROJECT_PATH"
  find "$PROJECT_PATH" -type f -name "*.sh" -exec chmod +x {} \;
  rm -rf "$TMP_DIR"

  log_success "Repository installed to $PROJECT_PATH"
}

ensure_project_env_export() {
  if ! grep -q "export PROJECT_PATH=" "$HOME/.bashrc"; then
    echo "export PROJECT_PATH="$PROJECT_PATH"" >> "$HOME/.bashrc"
    echo "export PROJECT_NAME="$PROJECT_NAME"" >> "$HOME/.bashrc"
    log_info "Added PROJECT_PATH and PROJECT_NAME to .bashrc"
  fi

  if ! grep -q "$PROJECT_PATH/common/scripts" "$HOME/.bashrc"; then
    echo 'export PATH="$PROJECT_PATH/common/scripts:$PATH"' >> "$HOME/.bashrc"
    log_info "Updated PATH to include $PROJECT_PATH/common/scripts"
  fi
}

run_provision() {
  export PROJECT_PATH="$PROJECT_PATH"
  if [ ! -d "$PROJECT_PATH" ]; then
    log_error "PROJECT_PATH does not exist: $PROJECT_PATH"
    exit 1
  fi

  if [ ! -f "$PROJECT_PATH/provision.sh" ]; then
    log_error "provision.sh not found in $PROJECT_PATH"
    exit 1
  fi

  log_info "Running provision.sh..."
  ARGS=(--project-name "$PROJECT_NAME" --project-path "$PROJECT_PATH")
  if [[ "$TEST_MODE" == "true" ]]; then
    ARGS+=(--test)
  fi

  if [[ -n "$SUDO" ]]; then
    $SUDO -E TEST_MODE="$TEST_MODE" PROJECT_NAME="$PROJECT_NAME" PROJECT_PATH="$PROJECT_PATH" bash "$PROJECT_PATH/provision.sh" "${ARGS[@]}"
  else
    TEST_MODE="$TEST_MODE" PROJECT_NAME="$PROJECT_NAME" PROJECT_PATH="$PROJECT_PATH" bash "$PROJECT_PATH/provision.sh" "${ARGS[@]}"
  fi
}

check_dependencies() {
  local required=(curl unzip zip)
  for cmd in "${required[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_info "Installing missing dependency: $cmd"
      $SUDO apt-get update -y && $SUDO apt-get install -y "$cmd" || {
        log_error "FATAL: Failed to install $cmd"
        exit 1
      }
    fi
  done
  log_success "All dependencies verified."
}

main() {
  check_dependencies
  INSTALL=false
  INSTALL_CUSTOM=false
  REPO_DOWNLOAD=false
  CLEANUP=false
  RESTORE=""

  parse_args "$@"
  require_root_or_sudo

  if [ -n "$RESTORE" ]; then
    local backup_file="${BACKUP_DIR}/${RESTORE}"
    if [ ! -f "$backup_file" ]; then
      log_error "Restore file not found: $backup_file"
      exit 1
    fi
    unzip -q "$backup_file" -d "$(dirname "$PROJECT_PATH")" >> "$LOG_FILE" 2>&1
    log_success "Restored from $backup_file"
    exit 0
  fi

  if [ "$REPO_DOWNLOAD" = true ]; then
    download_repo
    exit 0
  fi

  if [ "$INSTALL" = true ]; then
    backup_existing_project
    download_repo
    run_provision
    ensure_project_env_export
    exit 0
  fi

  if [ "$INSTALL_CUSTOM" = true ]; then
    run_provision
    ensure_project_env_export
    exit 0
  fi

  usage
}

main "$@"

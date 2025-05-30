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
DEBUG=false

# === Flags ===
INSTALL=false
PROVISION_ONLY=false
REPO_DOWNLOAD=false
CLEANUP=false
RESTORE=""
CUSTOM_REPO_URL=""

# === Shell Profile Detection ===
case "$SHELL" in
  */zsh) PROFILE="$HOME/.zshrc" ;;
  */bash) PROFILE="$HOME/.bashrc" ;;
  *) PROFILE="$HOME/.profile" ;;
esac

# === Logging ===
log_info()    { echo -e "[INFO]    $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_success() { echo -e "[SUCCESS] $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "[ERROR]   $(date '+%F %T') - $*" | tee -a "$LOG_FILE" >&2; }
log_warn()    { echo -e "[WARN]    $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }

# === Cleanup Handler ===
cleanup() {
  [[ -d "${TMP_DIR:-}" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# === Usage ===
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Main Operations:
  --install                     Download the repository and provision the project (recommended)
  --repo-url=URL                Override the default repository zip URL
  --repo-download               Download the repository only (no provision)
  --provision-only              Re-provision using the local folder (no download or backup)

Maintenance:
  --restore=FILENAME            Restore project from a previous backup ZIP
  --cleanup                     Remove created files and reset environment

Modes:
  --test                        Dry-run mode (no actual changes made)
  --debug                       Enable verbose debug output (equivalent to 'set -x')

Help:
  --help                        Show this help message and exit

Examples:
  $0 --install                                 # Full install: download + provision
  $0 --repo-download                           # Download only
  $0 --repo-download --repo-url=https://...    # Download custom archive
  $0 --provision-only                          # Re-run provision.sh in current folder
  $0 --restore=backup_20240527.zip             # Restore from a specific backup file
EOF
  exit 0
}

# === Flag Parser ===
parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --debug) DEBUG=true ;;
      --install) INSTALL=true ;;
      --repo-download) REPO_DOWNLOAD=true ;;
      --provision-only) PROVISION_ONLY=true ;;
      --cleanup) CLEANUP=true ;;
      --test) TEST_MODE=true ;;
      --restore=*) RESTORE="${arg#*=}" ;;
      --repo-url=*) CUSTOM_REPO_URL="${arg#*=}" ;;
      --help) usage ;;
      *) log_error "Unknown flag: $arg"; usage ;;
    esac
  done

  if [[ -n "$CUSTOM_REPO_URL" ]]; then
    if [[ "$CUSTOM_REPO_URL" =~ ^https?://.*\.zip$ ]]; then
      REPO_URL="$CUSTOM_REPO_URL"
      log_info "Using custom REPO_URL: $REPO_URL"
    else
      log_error "Invalid URL format for --repo-url: $CUSTOM_REPO_URL"
      usage
    fi
  fi
}

# === Core Functions ===
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

    zip -rq "$backup_file" "$PROJECT_PATH" >> "$LOG_FILE" 2>&1 && {
      log_info "Backup created: $backup_file"
      zipinfo "$backup_file" | tee -a "$LOG_FILE"
      CREATED_FILES+=("$backup_file")
    } || {
      log_error "Backup failed. Aborting before deleting $PROJECT_PATH."
      exit 1
    }
  fi
}

download_repo() {
  TMP_DIR=$(mktemp -d)
  log_info "Downloading repository to temporary directory..."
  curl -L "$REPO_URL" -o "$TMP_DIR/project.zip"
  unzip -t "$TMP_DIR/project.zip" || { log_error "Corrupted zip file."; exit 1; }
  unzip -q "$TMP_DIR/project.zip" -d "$TMP_DIR"
  EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d)

  if [ "$TEST_MODE" = false ]; then
    rm -rf "$PROJECT_PATH"
    mkdir -p "$HOME"
    mkdir -p "$PROJECT_PATH"
    cp -a "$EXTRACTED_DIR/." "$PROJECT_PATH"
    find "$PROJECT_PATH" -type f -name "*.sh" -exec chmod +x {} \;

    INVOKING_USER="${SUDO_USER:-$USER}"
    if [[ -n "$SUDO" ]]; then
      chown -R "$INVOKING_USER:$INVOKING_USER" "$PROJECT_PATH"
      log_info "Ownership set to $INVOKING_USER for $PROJECT_PATH"
    fi
  else
    log_info "[TEST MODE] Would replace $PROJECT_PATH with extracted contents."
  fi

  log_success "Repository installed to $PROJECT_PATH"
}

ensure_project_env_export() {
  grep -q "export PROJECT_NAME=" "$PROFILE" || echo "export PROJECT_NAME=\"$PROJECT_NAME\"" >> "$PROFILE"
  grep -q "$PROJECT_PATH/common/scripts" "$PROFILE" || echo "export PATH=\"$PROJECT_PATH/common/scripts:\$PATH\"" >> "$PROFILE"
  grep -q "cd \$HOME/$PROJECT_NAME" "$PROFILE" || echo "cd \"$PROJECT_PATH\"" >> "$PROFILE"
  log_info "Environment variables and project path exported to $PROFILE"
}

run_provision() {
  if [ ! -d "$PROJECT_PATH" ]; then
    log_error "PROJECT_PATH does not exist: $PROJECT_PATH"
    exit 1
  fi
  if [ ! -f "$PROJECT_PATH/provision.sh" ]; then
    log_error "provision.sh not found in $PROJECT_PATH"
    exit 1
  fi

  log_info "Running provision.sh..."
  ARGS=(--project-name "$PROJECT_NAME")
  [[ "$TEST_MODE" == "true" ]] && ARGS+=(--test)

  if [[ -n "$SUDO" ]]; then
    $SUDO -E bash "$PROJECT_PATH/provision.sh" "${ARGS[@]}"
  else
    bash "$PROJECT_PATH/provision.sh" "${ARGS[@]}"
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

# === Entrypoint ===
main() {
  parse_args "$@"
  [[ "$DEBUG" == true ]] && set -x

  log_info "INSTALL=$INSTALL, REPO_DOWNLOAD=$REPO_DOWNLOAD, PROVISION_ONLY=$PROVISION_ONLY, CLEANUP=$CLEANUP, TEST_MODE=$TEST_MODE"

  check_dependencies
  require_root_or_sudo

  if [ -n "$RESTORE" ]; then
    local backup_file="${BACKUP_DIR}/${RESTORE}"
    if [ ! -f "$backup_file" ]; then
      log_error "Restore file not found: $backup_file"
      exit 1
    fi
    unzip -q "$backup_file" -d "$(dirname "$PROJECT_PATH")" >> "$LOG_FILE" 2>&1
    # Ensure ownership is correct after restore
    RESTORED_DIR="$(dirname "$PROJECT_PATH")/$(basename "$PROJECT_PATH")"
    INVOKING_USER="${SUDO_USER:-$USER}"
    if [[ -d "$RESTORED_DIR" && -n "$SUDO" ]]; then
      chown -R "$INVOKING_USER:$INVOKING_USER" "$RESTORED_DIR"
      log_info "Ownership set to $INVOKING_USER for $RESTORED_DIR"
    fi
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

  if [ "$PROVISION_ONLY" = true ]; then
    run_provision
    ensure_project_env_export
    exit 0
  fi

  usage
}

main "$@"

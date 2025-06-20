#!/usr/bin/env bash
set -euo pipefail

# === Enforce Linux or WSL Only (Warn on macOS) ===
OS_TYPE="$(uname -s)"
if [[ "$OS_TYPE" == "Darwin" ]]; then
  echo "⚠️  macOS detected. This environment is untested — proceed with caution."
  log_warn "macOS environment detected. Proceeding with caution (not officially supported)."
elif [[ "$OS_TYPE" != "Linux" ]]; then
  echo "❌ This script can only be run in a Linux environment."
  echo "💡 Please use a native Linux system or WSL."
  log_error "Incompatible OS: $OS_TYPE. Exiting."
  exit 1
fi

# Check for WSL if Linux is reported
if grep -qi microsoft /proc/version 2>/dev/null; then
  echo "[INFO] WSL environment detected. Proceeding..."
  log_info "WSL environment detected. Proceeding..."

# === Detect Vagrant Environment ===
if id "vagrant" &>/dev/null && [[ -d "/home/vagrant/buildserver" ]]; then
  echo "⚠️  Vagrant environment detected at /home/vagrant/buildserver."
  echo "💡 Please exit this session and re-run using: vagrant up --provision"
  log_warn "Vagrant user and environment detected. Aborting to avoid conflict."
  exit 0
fi

fi


# === Safe Defaults ===
: "${PROJECT_NAME:=buildserver}"
: "${REPO_DOWNLOAD:=false}"
: "${INSTALL:=false}"
: "${PROVISION_ONLY:=false}"
: "${CLEANUP:=false}"
: "${DEBUG:=false}"
: "${TEST_MODE:=false}"
: "${RESTORE:=}"

# === User Context ===
INVOKING_USER="${SUDO_USER:-$USER}"
INVOKING_HOME=$(eval echo "~$INVOKING_USER")

# === Paths ===
export PROJECT_PATH="${INVOKING_HOME}/${PROJECT_NAME}"
export BACKUP_DIR="${INVOKING_HOME}/backup"
export LOG_FILE="${INVOKING_HOME}/install-script.log"

# === ShellCheck Validation ===
echo "[INFO] Running shellcheck validation..."
SHELLCHECK_LOG="${PROJECT_PATH}/shellcheck.log"
mkdir -p "$(dirname "$SHELLCHECK_LOG")"
if command -v shellcheck &>/dev/null; then
  if command -v tput &>/dev/null && [ "$(tput colors)" -ge 8 ]; then
    COLOR_RED=$(tput setaf 1)
    COLOR_GREEN=$(tput setaf 2)
    COLOR_RESET=$(tput sgr0)
  else
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_RESET=""
  fi
  shellcheck "$0" > "$SHELLCHECK_LOG" 2>&1 || true
  echo "${COLOR_GREEN}[INFO] shellcheck completed. See log at $SHELLCHECK_LOG${COLOR_RESET}"
else
  echo "[WARN] shellcheck is not installed. Skipping script linting."
fi

REPO_URL="https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
CREATED_FILES=()
SUDO=""
DEBUG=false

# === Shell Profile Detection ===
case "$SHELL" in
  */zsh) PROFILE="$INVOKING_HOME/.zshrc" ;;
  */bash) PROFILE="$INVOKING_HOME/.bashrc" ;;
  *) PROFILE="$INVOKING_HOME/.profile" ;;
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

# === Flags and Usage ===
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Main Operations:
  --install                 Download the repository and provision the project (recommended)
  --provision-only          Re-provision using the local folder (no download or backup)
  --repo-download           Download the repository only (no provision)

Maintenance:
  --restore=FILENAME        Restore project from a previous backup ZIP
  --cleanup                 Remove created files and reset environment

Modes:
  --test                    Dry-run mode (no actual changes made)
  --debug                   Enable verbose debug output (equivalent to 'set -x')

Help:
  --help                    Show this help message and exit

Examples:
  $0 --install                         # Full install: download + provision
  $0 --provision-only                 # Re-run provision.sh in current folder
  $0 --restore=backup_20240527.zip    # Restore from a specific backup file
  $0 --install --debug                # Install with verbose command trace
  $0 --repo-download                  # Download project archive only
EOF
  exit 0
}

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --) ;;  # Ignore -- used for separating arguments
      --debug) DEBUG=true ;;
      --install) INSTALL=true ;;
      --repo-download) REPO_DOWNLOAD=true ;;
      --provision-only) PROVISION_ONLY=true ;;
      --cleanup) CLEANUP=true ;;
      --test) TEST_MODE=true ;;
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
    mv "$EXTRACTED_DIR" "$PROJECT_PATH"
    find "$PROJECT_PATH" -type f -name "*.sh" -exec chmod +x {} \;
  else
    log_info "[TEST MODE] Would replace $PROJECT_PATH with extracted contents."
  fi

  log_success "Repository installed to $PROJECT_PATH"
}

ensure_project_env_export() {
  local current_dir
  current_dir="$(pwd)"

  [[ -f "$PROFILE" ]] || touch "$PROFILE"

  local export_name="export PROJECT_NAME=\"$PROJECT_NAME\""
  local export_path="export PROJECT_PATH=\"$current_dir/$PROJECT_NAME\""
  local export_path_entry="export PATH=\"$current_dir/common/scripts:\$PATH\""
  local cd_path="cd \"$current_dir\""

  grep -Fxq "$export_name" "$PROFILE" || echo "$export_name" >> "$PROFILE"
  grep -Fxq "$export_path" "$PROFILE" || echo "$export_path" >> "$PROFILE"
  grep -Fxq "$export_path_entry" "$PROFILE" || echo "$export_path_entry" >> "$PROFILE"
  grep -Fxq "$cd_path" "$PROFILE" || echo "$cd_path" >> "$PROFILE"

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

log_latest_github_commit() {
  local repo_url="https://api.github.com/repos/chkp-altrevin/buildserver/commits?per_page=1"
  local log_file="latest_commit.log"
  local temp_log

  temp_log=$(mktemp) || {
    echo "[ERROR] Failed to create temporary file for commit log."
    return 1
  }

  {
    echo "== [LOG ENTRY] $(date '+%Y-%m-%d %H:%M:%S') =="
    curl -s "$repo_url" | jq -r '.[0] | "SHA: \(.sha[0:7])\nDate: \(.commit.committer.date)\nMessage: \(.commit.message)\n"'
    echo ""
  } > "$temp_log"

  # Append previous log content below the new entry
  [ -f "$log_file" ] && cat "$log_file" >> "$temp_log"

  mv "$temp_log" "$log_file"
  chown $INVOKING_USER && chgrp $INVOKING_USER
  echo "[INFO] Logged latest commit to $log_file"
}

main() {
  log_info "main() invoked with args: $*"
  parse_args "$@"
  [[ "$DEBUG" == true ]] && set -x
  check_dependencies
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
    log_latest_github_commit
    exit 0
  fi

  if [ "$PROVISION_ONLY" = true ]; then
    run_provision
    ensure_project_env_export
    log_success "Installation script completed."
    exit 0
  fi

  if [ "$CLEANUP" = true ]; then
    echo -e "\n[WARN] You are about to delete the buildserver project, backup files, and logs."
    read -rp "Are you sure you want to proceed? (yes/no): " CONFIRM_CLEANUP
    if [[ "$CONFIRM_CLEANUP" != "yes" ]]; then
      log_info "Cleanup aborted by user."
      exit 0
    fi

    log_info "Performing cleanup tasks..."
    FAILED_ITEMS=()
    for item in "$PROJECT_PATH" "$BACKUP_DIR" "$LOG_FILE"; do
      if [[ -e "$item" ]]; then
        if rm -rf "$item"; then
          log_info "Deleted: $item"
        else
          log_warn "Failed to delete: $item"
          FAILED_ITEMS+=("$item")
        fi
      fi
    done

    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
      log_warn "Cleanup completed with some issues. Could not delete:"
      for f in "${FAILED_ITEMS[@]}"; do
        echo " - $f"
      done
      exit 1
    else
      log_success "Cleanup completed successfully."
      exit 0
    fi
  fi

  usage
}

main "$@"

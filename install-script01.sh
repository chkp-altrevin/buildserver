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

run_provision() {
  export PROJECT_PATH="$PROJECT_PATH"
  if [ ! -d "$PROJECT_PATH" ]; then
    log_error "PROJECT_PATH does not exist: $PROJECT_PATH"
    exit 1
  fi

  if [ ! -f "$PROJECT_PATH/provision01.sh" ]; then
    log_error "provision01.sh not found in $PROJECT_PATH"
    exit 1
  fi

  log_info "Running provision.sh..."
  ARGS=(--project-name "$PROJECT_NAME" --project-path "$PROJECT_PATH")
  if [[ "$TEST_MODE" == "true" ]]; then
    ARGS+=(--test)
  fi
  TEST_MODE="$TEST_MODE" PROJECT_NAME="$PROJECT_NAME" PROJECT_PATH="$PROJECT_PATH" $SUDO -E bash "$PROJECT_PATH/provision01.sh" "${ARGS[@]}"
}

main() {
  INSTALL=false
  INSTALL_CUSTOM=false
  REPO_DOWNLOAD=false
  CLEANUP=false
  RESTORE=""

  parse_args "$@"
  require_root_or_sudo

  if [ "$INSTALL_CUSTOM" = true ]; then
    run_provision
    exit 0
  fi

  usage
}

main "$@"

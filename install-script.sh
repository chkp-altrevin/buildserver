#!/usr/bin/env bash
set -euo pipefail

# === Constants ===
DEFAULT_PROJECT_PATH="${HOME}/buildserver"
BACKUP_DIR="${HOME}/backup"
MAX_BACKUPS=3
REPO_URL="https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
REPO_INSTALL=false
REPO_DOWNLOAD=false
AUTO_CONFIRM=false
STATUS=false
RESET=false
SUDO=""
LOG_FILE="$HOME/install-script.log"
CREATED_FILES=()

# === Logging ===
log_info()    { echo -e "[INFO]    $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_success() { echo -e "[SUCCESS] $(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "[ERROR]   $(date '+%F %T') - $*" | tee -a "$LOG_FILE" >&2; }

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --repo-install        Download project and run provision.sh
  --repo-download       Download project only, no execution
  --project-path=PATH   Custom install location (default: $HOME/buildserver)
  --restore=FILE        Restore from a previous backup zip
  --force               Overwrite without confirmation
  --auto-confirm        Automatically install missing dependencies
  --status              Show current installation status
  --reset               Delete installed project and backups
  --help                Show this help message
EOF
  exit 0
}

parse_args() {
  PROJECT_PATH="$DEFAULT_PROJECT_PATH"
  FORCE=false
  RESTORE=""

  for arg in "$@"; do
    case "$arg" in
      --project-path=*)
        PROJECT_PATH="${arg#*=}"
        ;;
      --restore=*)
        RESTORE="${arg#*=}"
        ;;
      --force)
        FORCE=true
        ;;
      --repo-install)
        REPO_INSTALL=true
        ;;
      --repo-download)
        REPO_DOWNLOAD=true
        ;;
      --auto-confirm)
        AUTO_CONFIRM=true
        ;;
      --status)
        STATUS=true
        ;;
      --reset)
        RESET=true
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
  REQUIRED_CMDS=(curl zip unzip git)
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
  if [ "$AUTO_CONFIRM" = true ]; then
    CONFIRM=yes
  else
    read -rp "Would you like to attempt to install them now? (yes/no): " CONFIRM
  fi

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

status_report() {
  echo "📊 Installation Status Summary"
  if [ -d "$PROJECT_PATH/.git" ]; then
    LAST_COMMIT=$(git -C "$PROJECT_PATH" rev-parse --short HEAD)
    LAST_DATE=$(git -C "$PROJECT_PATH" log -1 --format=%cd)
    echo "✅ Project is installed at: $PROJECT_PATH"
    echo "🔖 Last commit: $LAST_COMMIT"
    echo "📅 Last update: $LAST_DATE"
  elif [ -d "$PROJECT_PATH" ]; then
    echo "⚠️  Project directory exists but is not a git repository."
  else
    echo "❌ Project is not installed at: $PROJECT_PATH"
  fi
  exit 0
}

reset_project() {
  log_info "Resetting project directory and backup files..."
  rm -rf "$PROJECT_PATH"
  rm -rf "$BACKUP_DIR"/buildserver_*.zip
  log_success "Project and backups have been removed."
  exit 0
}

# Existing functions (backup_existing_project, restore_backup, install_project) remain unchanged

main() {
  parse_args "$@"

  if [ "$STATUS" = true ]; then
    status_report
  fi

  if [ "$RESET" = true ]; then
    reset_project
  fi

  require_root_or_sudo
  check_dependencies

  if [ "$#" -eq 0 ]; then
    usage
  fi

  if [ "$REPO_DOWNLOAD" = true ]; then
    log_info "Download-only mode to: $PROJECT_PATH"
    FORCE=true
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

  if [ "$REPO_INSTALL" = true ]; then
    log_info "Running full install to: $PROJECT_PATH"
    FORCE=true
    backup_existing_project
    install_project
    exit 0
  fi

  if [ -n "$RESTORE" ]; then
    restore_backup
  fi

  if [ -d "$PROJECT_PATH" ] && [ "$FORCE" = false ]; then
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

#!/usr/bin/env bash
set -euo pipefail

# === Constants ===
DEFAULT_PROJECT_PATH="${HOME}/buildserver"
BACKUP_DIR="${HOME}/backup"
MAX_BACKUPS=3
REPO_URL="https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
INSTALL=false
AUTO_CONFIRM=false
SUDO=""

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --install             Run default install with overwrite
  --project-path=PATH   Custom install location (default: \$HOME/buildserver)
  --restore=FILE        Restore from a previous backup zip
  --force               Overwrite without confirmation
  --dry-run             Simulate actions without changes
  --auto-confirm        Automatically install missing dependencies
  --help                Show this help message
EOF
  exit 0
}

parse_args() {
  PROJECT_PATH="$DEFAULT_PROJECT_PATH"
  FORCE=false
  RESTORE=""
  DRY_RUN=false

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
      --dry-run)
        DRY_RUN=true
        ;;
      --install)
        INSTALL=true
        ;;
      --auto-confirm)
        AUTO_CONFIRM=true
        ;;
      --help)
        usage
        ;;
      *)
        echo "❌ Unknown flag: $arg"
        usage
        ;;
    esac
  done
}

require_root_or_sudo() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "⚠️  This script may require root privileges. Re-run with sudo if needed."
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

  echo "❌ Missing required dependencies: ${MISSING[*]}"
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
        echo "⚠️  Unsupported package manager. Please install manually: ${MISSING[*]}"
        exit 1
      fi
      ;;
    *)
      echo "❌ Dependencies not installed. Exiting."
      exit 1
      ;;
  esac
}

backup_existing_project() {
  if [ -d "$PROJECT_PATH" ]; then
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    BACKUP_FILE="${BACKUP_DIR}/buildserver_${TIMESTAMP}.zip"
    mkdir -p "$BACKUP_DIR"
    zip -r "$BACKUP_FILE" "$PROJECT_PATH" >/dev/null
    echo "📦 Existing project backed up to $BACKUP_FILE"

    ls -1t "${BACKUP_DIR}"/buildserver_*.zip | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm --
  fi
}

restore_backup() {
  BACKUP_FILE="${BACKUP_DIR}/${RESTORE}"
  if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found."
    exit 1
  fi

  echo "This will replace the current project at '$PROJECT_PATH' with the backup '$BACKUP_FILE'."
  read -rp "Proceed? (yes/no): " CONFIRM
  case $CONFIRM in
    yes|y|Y)
      rm -rf "$PROJECT_PATH"
      unzip -q "$BACKUP_FILE" -d "$(dirname "$PROJECT_PATH")"
      echo "✅ Project restored from backup."
      exit 0
      ;;
    *)
      echo "❌ Restore aborted."
      exit 0
      ;;
  esac
}

install_project() {
  TMP_DIR=$(mktemp -d)
  echo "⬇️  Downloading project archive..."
  curl -fsSL "$REPO_URL" -o "$TMP_DIR/project.zip"
  echo "📂 Extracting project..."
  unzip -q "$TMP_DIR/project.zip" -d "$TMP_DIR"
  EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d)
  rm -rf "$PROJECT_PATH"
  mv "$EXTRACTED_DIR" "$PROJECT_PATH"
  echo "✅ Project installed at '$PROJECT_PATH'"
  rm -rf "$TMP_DIR"
}

main() {
  parse_args "$@"
  require_root_or_sudo
  check_dependencies

  if [ "$#" -eq 0 ]; then
    usage
  fi

  if [ "$INSTALL" = true ]; then
    echo "🚀 Starting default install using path: $PROJECT_PATH"
    FORCE=true
    backup_existing_project
    install_project
  if [ -x "$HOME/buildserver/provision.sh" ]; then
    echo "🚀 Running post-install: provision.sh..."
    "$HOME/buildserver/provision.sh"
  else
    echo "⚠️  provision.sh not found or not executable at $HOME/buildserver/provision.sh"
  fi
    exit 0
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "⚙️  Dry run mode enabled. No changes will be made."
    echo "Would install to: $PROJECT_PATH"
    exit 0
  fi

  if [ -n "$RESTORE" ]; then
    restore_backup
  fi

  if [ -d "$PROJECT_PATH" ] && [ "$FORCE" = false ]; then
    echo "⚠️  Project directory '$PROJECT_PATH' already exists."
    read -rp "Do you want to overwrite it? (yes/no): " CONFIRM
    case $CONFIRM in
      yes|y|Y)
        backup_existing_project
        ;;
      *)
        echo "❌ Installation aborted."
        exit 0
        ;;
    esac
  else
    backup_existing_project
  fi

  install_project
}

main "$@"

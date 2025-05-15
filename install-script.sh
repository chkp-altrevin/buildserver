#!/usr/bin/env bash
set -euo pipefail

# === Constants ===
DEFAULT_PROJECT_PATH="${HOME}/buildserver"
BACKUP_DIR="${HOME}/backup"
MAX_BACKUPS=3
REPO_URL="https://github.com/${YOUR_USERNAME:-chkp-altrevin}/buildserver/archive/refs/heads/main.zip"

# === Functions ===

usage() {
  echo "Usage: $0 [--project-path=PATH] [--force] [--restore=FILE] [--dry-run]"
  exit 1
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
      --force)
        FORCE=true
        ;;
      --restore=*)
        RESTORE="${arg#*=}"
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      *)
        echo "Unknown option: $arg"
        usage
        ;;
    esac
  done
}

check_dependencies() {
  MISSING=()
  for cmd in curl unzip zip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      MISSING+=("$cmd")
    fi
  done

  if [ ${#MISSING[@]} -eq 0 ]; then
    return
  fi

  echo "Missing required dependencies: ${MISSING[*]}"
  read -rp "Would you like to attempt to install them now? (yes/no): " CONFIRM
  case "$CONFIRM" in
    yes|y|Y)
      echo "Attempting to install: ${MISSING[*]}"
      if command -v apt-get >/dev/null; then
        sudo apt-get update && sudo apt-get install -y "${MISSING[@]}"
      elif command -v dnf >/dev/null; then
        sudo dnf install -y "${MISSING[@]}"
      elif command -v yum >/dev/null; then
        sudo yum install -y "${MISSING[@]}"
      elif command -v apk >/dev/null; then
        sudo apk add --no-cache "${MISSING[@]}"
      elif command -v pacman >/dev/null; then
        sudo pacman -Sy --noconfirm "${MISSING[@]}"
      elif command -v brew >/dev/null; then
        brew install "${MISSING[@]}"
      else
        echo "Unsupported package manager. Please install manually: ${MISSING[*]}"
        exit 1
      fi
      ;;
    *)
      echo "âŒ Dependencies not installed. Exiting."
      exit 1
      ;;
  esac
}
  for cmd in curl unzip zip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: '$cmd' is required but not installed."
      exit 1
    fi
  done
}

backup_existing_project() {
  if [ -d "$PROJECT_PATH" ]; then
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    BACKUP_FILE="${BACKUP_DIR}/buildserver_${TIMESTAMP}.zip"
    mkdir -p "$BACKUP_DIR"
    zip -r "$BACKUP_FILE" "$PROJECT_PATH" >/dev/null
    echo "ðŸ“¦ Existing project backed up to $BACKUP_FILE"

    # Cleanup old backups
    ls -1t "${BACKUP_DIR}"/buildserver_*.zip | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm --
  fi
}

restore_backup() {
  if [ -z "$RESTORE" ]; then
    echo "Error: --restore flag requires a filename."
    exit 1
  fi

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
      echo "âœ… Project restored from backup."
      exit 0
      ;;
    *)
      echo "âŒ Restore aborted."
      exit 0
      ;;
  esac
}

install_project() {
  TMP_DIR=$(mktemp -d)
  echo "â¬‡ï¸  Downloading project archive..."
  curl -fsSL "$REPO_URL" -o "$TMP_DIR/project.zip"
  echo "ðŸ“‚ Extracting project..."
  unzip -q "$TMP_DIR/project.zip" -d "$TMP_DIR"
  EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d)
  rm -rf "$PROJECT_PATH"
  mv "$EXTRACTED_DIR" "$PROJECT_PATH"
  echo "âœ… Project installed at '$PROJECT_PATH'"
  rm -rf "$TMP_DIR"
}

main() {
  parse_args "$@"
  check_dependencies

  if [ "$DRY_RUN" = true ]; then
    echo "âš™ï¸  Dry run mode enabled. No changes will be made."
    echo "Would install to: $PROJECT_PATH"
    exit 0
  fi

  if [ -n "$RESTORE" ]; then
    restore_backup
  fi

  if [ -d "$PROJECT_PATH" ] && [ "$FORCE" = false ]; then
    echo "âš ï¸  Project directory '$PROJECT_PATH' already exists."
    read -rp "Do you want to overwrite it? (yes/no): " CONFIRM
    case $CONFIRM in
      yes|y|Y)
        backup_existing_project
        ;;
      *)
        echo "âŒ Installation aborted."
        exit 0
        ;;
    esac
  else
    backup_existing_project
  fi

  install_project
}

main "$@"

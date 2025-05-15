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
    echo "📦 Existing project backed up to $BACKUP_FILE"

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
  check_dependencies

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

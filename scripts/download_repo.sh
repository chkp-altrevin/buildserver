download_and_extract_repo() {
  local REPO_URL="https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
  local ZIP_NAME="buildserver-main.zip"
  local DEST_DIR="$HOME"
  local TEMP_DIR="$HOME/temp_repo_download"
  local TARGET_DIR="$HOME/buildserver"
  local BACKUP_DIR="$HOME/backup"
  local LOG_FILE="$HOME/repo_download.log"

  # Logging functions
  log_info()    { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [INFO]    $*" | tee -a "$LOG_FILE"; }
  log_success() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $*" | tee -a "$LOG_FILE"; }
  log_error()   { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [ERROR]   $*" | tee -a "$LOG_FILE"; }

  log_info "Starting buildserver repo provisioning..."

  # Check for existing buildserver folder
  if [[ -d "$TARGET_DIR" ]]; then
    echo "⚠️  '$TARGET_DIR' already exists."
    echo -n "Do you want to [d]elete it or [b]ack it up before continuing? [d/b]: "
    read -r action

    case "$action" in
      [dD])
        rm -rf "$TARGET_DIR"
        log_info "Deleted existing '$TARGET_DIR'"
        ;;
      [bB])
        mkdir -p "$BACKUP_DIR"
        local TIMESTAMP
        TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
        local BACKUP_PATH="$BACKUP_DIR/buildserver_backup_$TIMESTAMP.zip"

        if zip -r -q "$BACKUP_PATH" "$TARGET_DIR"; then
          log_success "Backed up to $BACKUP_PATH"
        else
          log_error "Backup failed"
          return 1
        fi

        rm -rf "$TARGET_DIR"

        # Prune old backups
        local backups
        backups=($(ls -1t "$BACKUP_DIR"/buildserver_backup_*.zip 2>/dev/null))
        if (( ${#backups[@]} > 3 )); then
          for old_backup in "${backups[@]:3}"; do
            rm -f "$old_backup"
            log_info "Pruned old backup: $old_backup"
          done
        fi
        ;;
      *)
        log_error "Invalid input. Exiting."
        return 1
        ;;
    esac
  fi

  mkdir -p "$TEMP_DIR"
  cd "$TEMP_DIR" || { log_error "Failed to access temp directory"; return 1; }

  # Download zip
  if curl -L -o "$ZIP_NAME" "$REPO_URL"; then
    log_success "Downloaded $ZIP_NAME"
  else
    log_error "Download failed"
    return 1
  fi

  # Unzip
  if unzip -q "$ZIP_NAME" -d "$DEST_DIR"; then
    log_success "Unzipped to $DEST_DIR"
  else
    log_error "Unzip failed"
    return 1
  fi

  # Rename folder
  if mv "$DEST_DIR/buildserver-main" "$TARGET_DIR"; then
    log_success "Renamed to '$TARGET_DIR'"
  else
    log_error "Rename failed"
    return 1
  fi

  # Fix script permissions
  local sh_files
  sh_files=$(find "$TARGET_DIR" -type f -name "*.sh")
  if [[ -n "$sh_files" ]]; then
    while IFS= read -r script; do
      chmod +x "$script" && log_info "chmod +x: $script"
    done <<< "$sh_files"
    log_success "All .sh files made executable"
  else
    log_info "No .sh files found to chmod"
  fi

  # Cleanup
  rm -rf "$TEMP_DIR"
  log_info "Provision complete and cleaned up."
}

#!/usr/bin/env bash

install_buildserver_repo() {
  local REPO_URL="https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
  local ZIP_NAME="buildserver-main.zip"
  local DEST_DIR="$HOME"
  local EXTRACTED_FOLDER="buildserver-main"
  local TARGET_FOLDER="buildserver"
  local TARGET_PATH="$DEST_DIR/$TARGET_FOLDER"
  local BACKUP_PATH="$DEST_DIR/${TARGET_FOLDER}_backup_$(date '+%Y%m%d_%H%M%S').zip"
  local TEMP_DIR="$HOME/temp_download"
  local LOG_FILE="$HOME/buildserver_download.log"

  # Logging functions
  log_info()    { echo -e "$(date '+%F %T') [INFO]    $*" | tee -a "$LOG_FILE"; }
  log_success() { echo -e "$(date '+%F %T') [SUCCESS] $*" | tee -a "$LOG_FILE"; }
  log_error()   { echo -e "$(date '+%F %T') [ERROR]   $*" | tee -a "$LOG_FILE" >&2; }

  log_info "Starting installation of buildserver repo..."

  # Check if directory exists
  if [[ -d "$TARGET_PATH" ]]; then
    echo "⚠️  '$TARGET_PATH' already exists."
    echo -n "This will Backup and Update the Project: $PROJECT_PATH. Proceed? [y/N]: "
    read -r response
    case "$response" in
      [yY][eE][sS]|[yY])
        log_info "Backing up current folder to: $BACKUP_PATH"
        if zip -r -q "$BACKUP_PATH" "$TARGET_PATH"; then
          log_success "Backup successful."
        else
          log_error "Failed to create backup. Exiting."
          return 1
        fi
  
        log_info "Unzipping update over existing folder..."
        if unzip -o -q "$ZIP_PATH" -d "$HOME"; then
          log_success "Update unzipped successfully to $HOME"
          # Optional: rename if needed
          if [[ -d "$HOME/buildserver-main" ]]; then
            mv -f "$HOME/buildserver-main" "$TARGET_PATH"
            log_success "Renamed 'buildserver-main' to 'buildserver'"
          fi
        else
          log_error "Failed to unzip update. Exiting."
          return 1
        fi
        ;;
      *)
        log_info "User chose not to proceed. Exiting."
        return 0
        ;;
    esac
  fi

  # Create temp directory
  mkdir -p "$TEMP_DIR"
  cd "$TEMP_DIR" || { log_error "Could not access temp dir."; return 1; }

  # Download zip file
  log_info "Downloading repository from $REPO_URL..."
  if curl -L -o "$ZIP_NAME" "$REPO_URL"; then
    log_success "Downloaded $ZIP_NAME"
  else
    log_error "Download failed."
    return 1
  fi

  # Unzip into $HOME
  log_info "Unzipping into $DEST_DIR..."
  if unzip -q "$ZIP_NAME" -d "$DEST_DIR"; then
    log_success "Unzipped successfully."
  else
    log_error "Unzip failed."
    return 1
  fi

  # Rename folder
  if mv "$DEST_DIR/$EXTRACTED_FOLDER" "$TARGET_PATH"; then
    log_success "Renamed '$EXTRACTED_FOLDER' to '$TARGET_FOLDER'"
  else
    log_error "Failed to rename extracted folder."
    return 1
  fi

  # chmod +x all .sh files
  log_info "Applying chmod +x to all .sh files..."
  local sh_files
  sh_files=$(find "$TARGET_PATH" -type f -name "*.sh")
  if [[ -n "$sh_files" ]]; then
    while IFS= read -r file; do
      chmod +x "$file" && log_info "chmod +x applied to $file" || log_error "Failed to chmod $file"
    done <<< "$sh_files"
    log_success "All shell scripts are now executable."
  else
    log_info "No .sh files found to chmod."
  fi

  # Cleanup
  rm -rf "$TEMP_DIR"
  log_info "Installation complete. Temporary files cleaned."
}

install_buildserver_repo

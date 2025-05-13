refresh_buildserver_repo() {
  local REPO_URL="https://github.com/chkp-altrevin/buildserver.git"
  local REPO_NAME="buildserver"
  local PROJECT_PATH="$HOME/$REPO_NAME"
  local BACKUP_NAME="${REPO_NAME}_backup_$(date +%Y%m%d_%H%M%S).zip"
  local BACKUP_PATH="$HOME/$BACKUP_NAME"

  if [ -d "$PROJECT_PATH/.git" ]; then
    log_info "Zipping up current repo to $BACKUP_PATH..."
    (cd "$PROJECT_PATH" && zip -r "$BACKUP_PATH" . > /dev/null) && \
      log_success "Backup created: $BACKUP_PATH" || \
      log_error "Failed to create backup archive."
  else
    log_info "No existing repo found to backup."
  fi

  log_info "Removing existing project directory at $PROJECT_PATH..."
  rm -rf "$PROJECT_PATH" && log_success "Old project directory removed." || log_error "Failed to remove existing project."

  log_info "Cloning repository from $REPO_URL..."
  git clone "$REPO_URL" "$PROJECT_PATH" && log_success "Repository cloned." || { log_error "Git clone failed."; return 1; }

  log_info "Setting executable permission on provision.sh..."
  chmod +x "$PROJECT_PATH/provision.sh" && log_success "provision.sh is now executable." || log_error "Failed to chmod provision.sh."

  log_info "Executing provision.sh..."
  (cd "$PROJECT_PATH" && ./provision.sh) && log_success "Provisioning complete." || log_error "Provisioning failed."
}

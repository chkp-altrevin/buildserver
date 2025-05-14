#!/usr/bin/env bash

FORCE_YES=true
LOG_FILE="$HOME/refresh_repo.log"

log_info()    { echo -e "\033[1;34m[INFO]\033[0m    $(date '+%F %T') $*" | tee -a "$LOG_FILE"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $(date '+%F %T') $*" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m   $(date '+%F %T') $*" | tee -a "$LOG_FILE" >&2; }

refresh_buildserver_repo() {
  local REPO_URL="https://github.com/chkp-altrevin/buildserver.git"
  local REPO_NAME="buildserver"
  # local PROJECT_PATH="$HOME/$REPO_NAME"
  local BACKUP_DIR="$HOME/backups"
  local BACKUP_NAME="${REPO_NAME}_backup_$(date +%Y%m%d_%H%M%S).zip"
  local BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

  # Ensure 'zip' is installed
  command -v zip &>/dev/null || {
    log_info "Installing zip package..."
    sudo apt-get update -y && sudo apt-get install -y zip && log_success "zip installed." || log_error "Failed to install zip."
  }

  mkdir -p "$BACKUP_DIR"

  if [ -d "$PROJECT_PATH/.git" ]; then
    log_info "Creating backup of existing repo at $BACKUP_PATH..."
    (cd "$PROJECT_PATH" && zip -r "$BACKUP_PATH" . > /dev/null) &&       log_success "Backup created: $BACKUP_PATH" ||       log_error "Failed to create backup archive."
  else
    log_info "No existing repo found to backup."
  fi

  log_info "Pruning old backups in $BACKUP_DIR (keeping latest 3)..."
  ls -t "$BACKUP_DIR/${REPO_NAME}_backup_"*.zip 2>/dev/null | tail -n +4 | xargs -r rm -f &&     log_success "Old backups pruned." || log_info "No old backups to prune."

  log_info "Updating repository from $REPO_URL..."
  cd $PROJECT_PATH && git pull origin --autostash && log_success "Repository Updated." || { log_error "Git Update failed."; return 1; }

  log_info "Setting executable permission on provision.sh..."
  chmod +x "$PROJECT_PATH/provision.sh" && log_success "provision.sh is now executable." || log_error "Failed to chmod provision.sh."

  log_info "Executing provision.sh as root..."
  (cd "$PROJECT_PATH" && sudo ./provision.sh) && log_success "Provisioning complete." || log_error "Provisioning failed."
}
check_vagrant_user
refresh_buildserver_repo

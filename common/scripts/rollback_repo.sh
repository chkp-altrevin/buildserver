#!/usr/bin/env bash

BACKUP_DIR="$HOME/backup"
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/chkp-altrevin/buildserver/main/install-script.sh"
INSTALL_SCRIPT="install-script.sh"

# Check if backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "❌ Backup directory does not exist: $BACKUP_DIR"
  exit 1
fi

# Find most recent .zip file
latest_file=$(find "$BACKUP_DIR" -type f -name "*.zip" -printf "%T@ %p\n" | sort -nr | head -1 | awk '{print $2}')

if [[ -z "$latest_file" ]]; then
  echo "❌ No .zip backup files found in $BACKUP_DIR"
  exit 1
fi

selected_file="$(basename "$latest_file")"
echo "✅ Most recent backup found: $selected_file"

# Download and run the install script with --restore
echo "⚙️ Downloading and executing install script with --restore=$selected_file..."
curl -fsSL "$INSTALL_SCRIPT_URL" -o "$INSTALL_SCRIPT" && \
chmod +x "$INSTALL_SCRIPT" && \
sudo ./"$INSTALL_SCRIPT" --restore="$selected_file"

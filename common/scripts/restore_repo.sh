#!/usr/bin/env bash
# scripted install for
# curl -fsSL https://raw.githubusercontent.com/chkp-altrevin/buildserver/main/install-script.sh -o install-script.sh && chmod +x install-script.sh && sudo ./install-script.sh --restore

BACKUP_DIR="$HOME/backup"
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/chkp-altrevin/buildserver/main/install-script.sh"
INSTALL_SCRIPT="install-script.sh"

# Check if backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "❌ Backup directory does not exist: $BACKUP_DIR"
  exit 1
fi

# Get list of backup files
mapfile -t backups < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.zip" | sort)

# Validate files
if [[ ${#backups[@]} -eq 0 ]]; then
  echo "❌ No .zip backups found in $BACKUP_DIR"
  exit 1
fi

# Display files with numbers
echo "📦 Available Backups:"
for i in "${!backups[@]}"; do
  file="$(basename "${backups[$i]}")"
  printf "%2d. %s\n" "$((i + 1))" "$file"
done

# Ask user to choose
read -rp "Select a backup to restore [1-${#backups[@]}]: " selection

# Validate input
if ! [[ "$selection" =~ ^[0-9]+$ ]] || ((selection < 1 || selection > ${#backups[@]})); then
  echo "❌ Invalid selection. Exiting."
  exit 1
fi

# Extract selected file
selected_file="$(basename "${backups[$((selection - 1))]}")"
echo "✅ Selected: $selected_file"

# Run install script with restore flag
echo "⚙️ Downloading and running install script with --restore=$selected_file..."
curl -fsSL "$INSTALL_SCRIPT_URL" -o "$INSTALL_SCRIPT" && \
chmod +x "$INSTALL_SCRIPT" && \
sudo ./"$INSTALL_SCRIPT" --restore="$selected_file"

#!/bin/bash

# Define source and destination paths
SOURCE="$HOME/.backup.env"
DEST="$HOME/.env"
BACKUP="$HOME/.env_before_import"

# Check if the source file exists
if [ ! -f "$SOURCE" ]; then
    echo "Error: Source file $SOURCE does not exist."
    exit 1
fi

# If the destination file exists, create a backup
if [ -f "$DEST" ]; then
    echo "Backing up existing .env file to $BACKUP"
    mv "$DEST" "$BACKUP"
fi

# Copy and rename the backup.env to .env
cp "$SOURCE" "$DEST"
echo "File copied and renamed to $DEST"

# Set appropriate permissions (optional)
chmod 600 "$DEST"
echo "Permissions set to 600 for security"

exit 0

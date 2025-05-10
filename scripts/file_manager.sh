#!/bin/bash

# Default configurations
UPLOAD_DIR="./uploads"     # Directory to save uploaded files
BACKUP_DIR="./backups"     # Directory to store backups
EDITOR="nano"              # Default editor

# Ensure required directories exist
mkdir -p "$UPLOAD_DIR" "$BACKUP_DIR"

# Function to display usage
usage() {
    echo "Usage: $0 [-f FILE] [-e] [-b]"
    echo "  -f FILE    Specify the file to upload"
    echo "  -e         Edit the file before saving"
    echo "  -b         Create a backup of the file if it exists in the upload directory"
    exit 1
}

# Parse command-line arguments
EDIT=false
BACKUP=false
FILE=""
while getopts "f:eb" OPTION; do
    case $OPTION in
        f) FILE="$OPTARG" ;;
        e) EDIT=true ;;
        b) BACKUP=true ;;
        *) usage ;;
    esac
done

# Validate file input
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
    echo "Error: File not specified or does not exist."
    usage
fi

# Extract filename and target path
FILENAME=$(basename "$FILE")
TARGET="$UPLOAD_DIR/$FILENAME"

# Handle backups
if $BACKUP && [[ -f "$TARGET" ]]; then
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/${FILENAME}_$TIMESTAMP"
    cp "$TARGET" "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"
fi

# Edit the file if requested
if $EDIT; then
    $EDITOR "$FILE"
fi

# Upload (move) the file
mv "$FILE" "$TARGET"
echo "File uploaded to: $TARGET"

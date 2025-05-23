#!/bin/bash

# Edit our file
echo "=========================================================="
echo "Review $HOME/.env save and autobackup to $HOME/.backup.env"
echo "=========================================================="
sleep 5
vi $HOME/.env

# Define source file and destination directory
source_file="$HOME/.env"
export_file=".backup.env"
destination_directory="$HOME"

# Check if the source file exists
if [ -f "$source_file" ]; then
    # Copy the file to the destination directory
    cp -b "$source_file" "$destination_directory/$export_file"
    echo "File copied successfully!"
else
    echo "Source file not found!"
fi

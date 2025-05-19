#!/bin/bash
# modify as needed
# export PROJECT_PATH="$HOME/buildserver"

# Define source file and destination directory
source_file="$HOME/.env"
env_file=".env"
backup_env_file=".backup.env"
destination_directory="$HOME"
repo_directory="$PROJECT_PATH"
repo_source_file="$PROJECT_PATH/profile/env.example"

# backup local env just in case
if [ -f "$source_file" ]; then
    # Open to modify
    vi "$destination_directory/$env_file"
else
    cp $repo_source_file $destination_directory/$env_file
    vi $destination_directory/$env_file
fi

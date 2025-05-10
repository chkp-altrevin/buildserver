#!/bin/bash

set_project_path() {
  local default_path="$HOME/buildserver"
  local confirmed_path="$default_path"
  local original_folder="$default_path"

  echo "Current PROJECT_PATH: $default_path"
  read -rp "Is this correct? (y/n): " response

  if [[ "$response" =~ ^[Nn]$ ]]; then
    read -rp "Enter the correct path for PROJECT_PATH: " user_path

    if [[ ! -d "$user_path" ]]; then
      echo "Directory does not exist. Creating it now..."
      mkdir -p "$user_path" || {
        echo "[ERROR] Failed to create directory: $user_path"
        exit 1
      }

      echo "Directory created: $user_path"

      # Move files from buildserver to the new directory
      if [[ -d "$original_folder" ]]; then
        echo "Moving contents from $original_folder to $user_path..."
        mv "$original_folder"/* "$user_path"/ 2>/dev/null

        echo "Cleaning up original directory: $original_folder"
        rm -rf "$original_folder" 2>/dev/null || echo "[WARN] Could not remove $original_folder (might not be empty)"
      else
        echo "[WARN] Original folder $original_folder does not exist. Nothing to move."
      fi
    fi

    confirmed_path="$user_path"
  fi

  export PROJECT_PATH="$confirmed_path"
  echo "PROJECT_PATH set to: $PROJECT_PATH"

  # Persisting to ~/.bashrc
  if grep -q '^export PROJECT_PATH=' ~/.bashrc; then
    sed -i "s|^export PROJECT_PATH=.*|export PROJECT_PATH=$PROJECT_PATH|" ~/.bashrc
  else
    echo "export PROJECT_PATH=$PROJECT_PATH" >> ~/.bashrc
  fi

  echo "PROJECT_PATH has been made persistent in ~/.bashrc"
}

# Run the function
set_project_path


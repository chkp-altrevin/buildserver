#!/bin/bash

# Load environment variables from ~/.env file
ENV_FILE="$HOME/.env"

if [[ -f "$ENV_FILE" ]]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: ~/.env file not found!"
    exit 1
fi

# Ensure git is installed
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed. Please install Git first."
    exit 1
fi

# Check internet connectivity
echo "Checking internet connectivity..."
EXTERNAL_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)

if [[ -z "$EXTERNAL_IP" ]]; then
    echo "Error: No internet connection detected."
    exit 1
fi

echo "Internet connection is active. Your external IP is: $EXTERNAL_IP"

# Function to configure Git credentials
configure_git_credential() {
    local SERVICE_NAME=$1
    local USER_VAR=$2
    local TOKEN_VAR=$3
    local HOST=$4

    local USERNAME=${!USER_VAR}
    local TOKEN=${!TOKEN_VAR}

    if [[ -z "$USERNAME" || -z "$TOKEN" ]]; then
        echo "Skipping $SERVICE_NAME: Credentials missing in ~/.env"
        return
    fi

    local EXISTING_CREDENTIAL=$(git credential reject <<< "url=https://$HOST" 2>/dev/null | grep "password=")

    if [[ -n "$EXISTING_CREDENTIAL" ]]; then
        echo "$SERVICE_NAME credentials already exist."
        read -p "Do you want to override them? (y/N): " CHOICE
        if [[ "$CHOICE" != "y" && "$CHOICE" != "Y" ]]; then
            echo "Skipping $SERVICE_NAME..."
            return
        fi
    fi

    echo "Configuring credentials for $SERVICE_NAME..."
    git credential reject <<< "url=https://$USERNAME@$HOST"
    git credential approve <<EOF
protocol=https
host=$HOST
username=$USERNAME
password=$TOKEN
EOF

    echo "$SERVICE_NAME credentials set successfully."
}

# Configure credentials for each service
configure_git_credential "GitHub" "GITHUB_USER" "GITHUB_TOKEN" "github.com"
configure_git_credential "GitLab" "GITLAB_USER" "GITLAB_TOKEN" "gitlab.com"
configure_git_credential "Bitbucket" "BITBUCKET_USER" "BITBUCKET_TOKEN" "bitbucket.org"
configure_git_credential "Private Registry" "PRIVATE_USER" "PRIVATE_TOKEN" "myprivateregistry.com"

echo "Git authentication setup complete."

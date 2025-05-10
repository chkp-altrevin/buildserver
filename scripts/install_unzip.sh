#!/bin/bash

# Function to check if unzip is installed
check_unzip_installed() {
    if command -v unzip > /dev/null 2>&1; then
        echo "unzip is already installed."
    else
        echo "unzip is not installed. Installing unzip..."
        install_unzip
    fi
}

# Function to install unzip
install_unzip() {
    # Determine the package manager and install unzip
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update
        sudo apt-get install -y unzip
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y unzip
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf install -y unzip
    elif [ -x "$(command -v pacman)" ]; then
        sudo pacman -Sy unzip
    elif [ -x "$(command -v zypper)" ]; then
        sudo zypper install -y unzip
    else
        echo "Unsupported package manager. Please install unzip manually."
        exit 1
    fi

    if command -v unzip > /dev/null 2>&1; then
        echo "unzip has been successfully installed."
    else
        echo "Failed to install unzip."
        exit 1
    fi
}

# Run the check
check_unzip_installed

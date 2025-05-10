#!/bin/bash

# Define variables

SOURCE_DIR="/vagrant"
DEST_DIR="/home/vagrant/diy-devsec-lab"
USER="vagrant"
GROUP="vagrant"

# Create the destination directory
mkdir -p "$DEST_DIR"

# Copy the contents of the /vagrant directory to the destination directory
cp -r "$SOURCE_DIR"/* "$DEST_DIR"

#dos2unix tries not to modify scripts thus the add as needed
find /home/vagrant/diy-devsec-lab -type f -print0 | xargs -0 dos2unix --
#find $DEST_DIR -type f -print0 | xargs -0 dos2unix --

# Change ownership and group of the copied files
chown -R "$USER:$GROUP" "$DEST_DIR"

# fix those just in case
find "$DEST_DIR" -type f -name "*.sh" -exec dos2unix  \;

# Find all .sh files in the destination directory and set executable permissions
find "$DEST_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Print completion message
echo "Vagrant folder copied to $DEST_DIR with ownership and permissions set."

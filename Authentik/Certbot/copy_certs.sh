#!/bin/bash

# Define source and destination directories
SOURCE_DIR="/etc/letsencrypt/live/ubuntuserver.buzz/"
DEST_DIR="/home/jake/authentik/certs/ubuntuserver.buzz/"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Source directory $SOURCE_DIR does not exist."
  exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Open up permissions to ensure the copy is successful
chmod -R 0777 "$(dirname "$DEST_DIR")"
chmod -R 0777 "$DEST_DIR"

# Copy the actual files, not symbolic links
cp -L "$SOURCE_DIR"* "$DEST_DIR"

# Restore locked-down permissions after the copy
chown -R jake:jake "$DEST_DIR"
chmod -R 0755 "$DEST_DIR"

# Set permissions on the /certs directory
chown -R jake:jake "$(dirname "$(dirname "$DEST_DIR")")"
chmod -R 0755 "$(dirname "$(dirname "$DEST_DIR")")"

# Verify permissions
echo "Verifying permissions..."
ls -l "$DEST_DIR"

echo "Certificates and directory copied successfully to $DEST_DIR"

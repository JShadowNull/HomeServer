#!/bin/bash

# Prevent running as root
if [ "$(whoami)" = "root" ]; then
    echo "Error: This script should not be run as root. Please run as a regular user."
    exit 1
fi

# Check if docker group exists
if ! getent group docker >/dev/null; then
    echo "Error: Docker group not found. Please install Docker first."
    exit 1
fi

# Check if user is already in docker group
if groups | grep -q '\bdocker\b'; then
    echo "User $(whoami) is already in the docker group."
    exit 0
fi

# Add user to docker group
sudo usermod -aG docker "$(whoami)"

# Success message with instructions
echo "User $(whoami) has been added to the docker group."
echo "To apply these changes, you need to:"
echo "1. Log out and back in, or"
echo "2. Restart your system, or"
echo "3. Run the following command: newgrp docker"
echo ""
echo "Afterwards, verify with: groups"

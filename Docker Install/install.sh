#!/bin/bash

# Exit on error
set -e

echo "Starting Docker Engine installation..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Error: Cannot detect OS. /etc/os-release not found."
    exit 1
fi

# Validate OS support
case "$OS" in
    ubuntu|debian)
        echo "Detected OS: $PRETTY_NAME"
        ;;
    *)
        echo "Error: This script only supports Ubuntu and Debian."
        echo "Detected OS: $PRETTY_NAME"
        exit 1
        ;;
esac

# Remove conflicting packages
echo "Removing conflicting packages..."
for pkg in docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

# Remove old Docker repository configurations
echo "Cleaning up old Docker repository configurations..."
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/sources.list.d/docker.sources
sudo rm -f /etc/apt/keyrings/docker.asc
sudo rm -f /etc/apt/keyrings/docker.gpg

# Update package index and install required packages
echo "Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Create the directory for Docker's GPG key
echo "Setting up Docker repository..."
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker's official GPG key (OS-specific URL)
echo "Adding Docker GPG key..."
sudo curl -fsSL https://download.docker.com/linux/${OS}/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker's repository using DEB822 format (recommended)
echo "Configuring Docker repository..."
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/${OS}
Suites: ${VERSION_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Update the package index
echo "Updating package index..."
sudo apt-get update

# Install Docker packages
echo "Installing Docker Engine and plugins..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
echo "Verifying Docker installation..."
docker --version
sudo docker run --rm hello-world

# Check Docker service status
echo "Checking Docker service status..."
sudo systemctl status docker --no-pager

echo "Docker installation completed successfully!"
echo "To use Docker without sudo, run: sudo usermod -aG docker $USER"
echo "Then log out and back in for the changes to take effect."

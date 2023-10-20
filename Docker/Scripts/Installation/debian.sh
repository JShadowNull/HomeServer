#!/bin/bash

# Check if figlet is installed, and install it if not
if ! command -v figlet &> /dev/null; then
  echo "figlet is not installed. Installing..."
  apt-get update
  apt-get install -y figlet
fi

# Display a colorful title using figlet
figlet -f slant -c -t "Docker Stack" | lolcat

# Check if the directories already exist before creating them
if [ ! -d "/etc/apt/keyrings" ]; then
  mkdir -p /etc/apt/keyrings
fi

# Check if Docker and Docker Compose are already installed
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
  # Update the package repository
  apt-get update

  # Install Docker
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io

  # Start and enable Docker
  systemctl start docker
  systemctl enable docker

  # Install Docker Compose
  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# Verify installation
docker --version
docker-compose --version

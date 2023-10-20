#!/bin/bash

# Update the package list
sudo apt update

# Install Docker
sudo apt install -y docker.io

# Enable and start the Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Install Python3 and pip if not already installed
sudo apt install -y python3 python3-pip

# Install Docker Compose using pip
pip3 install docker-compose

# Verify the installations
docker --version
docker-compose --version

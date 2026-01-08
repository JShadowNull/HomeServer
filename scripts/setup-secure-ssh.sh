#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if Debian-based
if ! grep -E 'debian|ubuntu' /etc/os-release > /dev/null 2>&1; then
    echo -e "${RED}Error: This script is for Debian-based systems only.${NC}"
    exit 1
fi

echo -e "${GREEN}SSH Security Setup${NC}"
echo "===================="

# Generate SSH key if needed
if [[ ! -f ~/.ssh/id_rsa.pub ]] && [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
    echo -e "${YELLOW}No SSH keys found. Generating...${NC}"
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
fi

# Display public key
echo -e "\n${GREEN}Your public key (add this to ~/.ssh/authorized_keys on the remote system):${NC}"
echo "===================="
cat ~/.ssh/id_*.pub
echo "===================="
echo -e "\n${YELLOW}Copy the above key to systems that need to access THIS machine${NC}"
read -p "Press Enter after you've added this key to remote systems..."

# Harden SSH
echo -e "\n${YELLOW}Hardening SSH configuration...${NC}"

# Apply hardening
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# Test and restart
if sudo sshd -t; then
    sudo systemctl restart ssh || sudo systemctl restart sshd
    echo -e "${GREEN}SSH hardened successfully - key authentication only${NC}"
else
    echo -e "${RED}Configuration error!${NC}"
    exit 1
fi
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

# Generate SSH key pair
mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [[ ! -f ~/.ssh/authorized_keys ]]; then
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

# Generate temporary key pair
TEMP_KEY="/tmp/ssh_temp_key"
ssh-keygen -t ed25519 -f "$TEMP_KEY" -N "" -C "$(whoami)@$(hostname)"

echo -e "\n${GREEN}=== PRIVATE KEY (save this to your Mac) ===${NC}"
echo -e "${YELLOW}Save this as ~/.ssh/id_ed25519 on your Mac:${NC}"
echo "----BEGIN PRIVATE KEY----"
cat "$TEMP_KEY"
echo "----END PRIVATE KEY----"

echo -e "\n${GREEN}=== PUBLIC KEY (adding to this server) ===${NC}"
cat "$TEMP_KEY.pub" >> ~/.ssh/authorized_keys
echo -e "${GREEN}✓ Public key added to authorized_keys${NC}"

# Show the public key too
echo -e "\n${YELLOW}Public key (for reference):${NC}"
cat "$TEMP_KEY.pub"

# Clean up temp files
rm -f "$TEMP_KEY" "$TEMP_KEY.pub"

echo -e "\n${YELLOW}Now hardening SSH configuration...${NC}"

# Harden SSH
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# Test and restart
if sudo sshd -t; then
    sudo systemctl restart ssh || sudo systemctl restart sshd
    echo -e "${GREEN}✓ SSH hardened successfully${NC}"
else
    echo -e "${RED}Configuration error!${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== SETUP COMPLETE ===${NC}"
echo -e "${YELLOW}1. Copy the private key above to ~/.ssh/id_ed25519 on your Mac${NC}"
echo -e "${YELLOW}2. Run: chmod 600 ~/.ssh/id_ed25519 on your Mac${NC}"
echo -e "${YELLOW}3. Connect with: ssh $(whoami)@$(hostname -I | awk '{print $1}')${NC}"
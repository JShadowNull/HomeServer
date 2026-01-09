#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}GitHub SSH Key Setup${NC}"
echo "====================="

# Get email for key
read -p "Enter your GitHub email: " github_email

# Create SSH directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key
KEY_FILE="$HOME/.ssh/github"
echo -e "\n${YELLOW}Generating SSH key for GitHub...${NC}"
ssh-keygen -t ed25519 -C "$github_email" -f "$KEY_FILE" -N ""

# Display public key
echo -e "\n${GREEN}=== COPY THIS TO GITHUB ===${NC}"
echo -e "${BLUE}Go to: https://github.com/settings/ssh/new${NC}"
echo -e "${YELLOW}Title: $(hostname) - $(date +'%Y-%m-%d')${NC}"
echo -e "${YELLOW}Key:${NC}"
echo "==========================================="
cat "${KEY_FILE}.pub"
echo "==========================================="

# Add to SSH config
echo -e "\n${YELLOW}Adding to SSH config...${NC}"
SSH_CONFIG="$HOME/.ssh/config"

# Create or update SSH config
if ! grep -q "github.com" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github
    AddKeysToAgent yes
EOF
    echo -e "${GREEN}✓ SSH config updated${NC}"
else
    echo -e "${YELLOW}GitHub config already exists in SSH config${NC}"
fi

# Start SSH agent and add key
echo -e "\n${YELLOW}Adding key to SSH agent...${NC}"
eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add "$KEY_FILE" 2>/dev/null || true

echo -e "\n${GREEN}=== SETUP COMPLETE ===${NC}"
echo -e "${YELLOW}1. Copy the key above and paste it into GitHub${NC}"
echo -e "${YELLOW}2. Go to: ${BLUE}https://github.com/settings/ssh/new${NC}"
echo -e "${YELLOW}3. Test with: ${GREEN}ssh -T git@github.com${NC}"
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

# Check if key already exists
KEY_FILE="$HOME/.ssh/github"
if [[ -f "$KEY_FILE" ]]; then
    echo -e "${YELLOW}GitHub SSH key already exists at $KEY_FILE${NC}"
    read -p "Use existing key? (y/n): " use_existing
    if [[ "$use_existing" != "y" ]]; then
        read -p "Overwrite existing key? (y/n): " overwrite
        if [[ "$overwrite" != "y" ]]; then
            echo -e "${RED}Exiting...${NC}"
            exit 1
        fi
        rm -f "$KEY_FILE" "${KEY_FILE}.pub"
    else
        echo -e "${GREEN}Using existing key${NC}"
    fi
fi

# Generate SSH key if needed
if [[ ! -f "$KEY_FILE" ]]; then
    echo -e "\n${YELLOW}Generating SSH key for GitHub...${NC}"
    ssh-keygen -t ed25519 -C "$github_email" -f "$KEY_FILE" -N ""
    echo -e "${GREEN}✓ Key generated${NC}"
fi

# Display public key
echo -e "\n${GREEN}=== COPY THIS PUBLIC KEY TO GITHUB ===${NC}"
echo -e "${BLUE}Go to: https://github.com/settings/ssh/new${NC}"
echo -e "${YELLOW}Title: $(hostname) - $(date +'%Y-%m-%d')${NC}"
echo -e "${YELLOW}Key:${NC}"
echo "==========================================="
cat "${KEY_FILE}.pub"
echo "==========================================="

# Add to SSH config
echo -e "\n${YELLOW}Configuring SSH...${NC}"
SSH_CONFIG="$HOME/.ssh/config"

# Create or update SSH config
if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
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
echo -e "${GREEN}✓ Key added to agent${NC}"

# Ask about updating git remote
echo -e "\n${YELLOW}Do you want to update the git remote for the current repository?${NC}"
read -p "Update git remote to use SSH? (y/n): " update_remote

if [[ "$update_remote" == "y" ]]; then
    if git rev-parse --git-dir > /dev/null 2>&1; then
        read -p "Enter SSH URL (e.g., git@github.com:username/repo.git): " ssh_url
        git remote set-url origin "$ssh_url"
        echo -e "${GREEN}✓ Git remote updated${NC}"
        git remote -v
    else
        echo -e "${YELLOW}Not in a git repository${NC}"
    fi
fi

echo -e "\n${GREEN}=== SETUP COMPLETE ===${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Copy the public key above to ${BLUE}https://github.com/settings/ssh/new${NC}"
echo -e "2. Test connection: ${GREEN}ssh -T git@github.com${NC}"
echo -e "3. You should see: 'Hi username! You've successfully authenticated'"

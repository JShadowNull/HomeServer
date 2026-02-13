#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if Debian-based
if ! grep -E 'debian|ubuntu' /etc/os-release > /dev/null 2>&1; then
    echo -e "${RED}Error: This script is for Debian-based systems only.${NC}"
    exit 1
fi

echo -e "${GREEN}Server SSH Security Setup${NC}"
echo "========================="
echo ""
echo "This script will:"
echo "  1. Set up SSH key authentication"
echo "  2. Harden SSH server configuration"
echo "  3. Disable password authentication"
echo ""

# Ensure SSH directory exists
mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [[ ! -f ~/.ssh/authorized_keys ]]; then
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

echo -e "${YELLOW}Do you want to use an existing SSH key or generate a new one?${NC}"
echo "1) Use existing key (recommended if you already have a key for servers)"
echo "2) Generate new key"
read -p "Choose option (1/2): " key_option

case $key_option in
    1)
        echo -e "\n${YELLOW}Using existing SSH key${NC}"
        echo -e "\n${BLUE}=== How to get your public key ===${NC}"
        echo -e "${YELLOW}If you only have the private key, extract the public key on your Mac:${NC}"
        echo -e "  ${GREEN}ssh-keygen -y -f ~/.ssh/id_ed25519${NC}"
        echo -e "  ${GREEN}ssh-keygen -y -f ~/.ssh/id_rsa${NC}"
        echo -e "  ${GREEN}ssh-keygen -y -f ~/.ssh/server_key${NC}"
        echo -e "\n${YELLOW}Or if you have the .pub file:${NC}"
        echo -e "  ${GREEN}cat ~/.ssh/id_ed25519.pub${NC}"
        echo -e "\n${BLUE}Please paste your PUBLIC key below:${NC}"
        echo -e "${YELLOW}(The key should start with 'ssh-ed25519' or 'ssh-rsa')${NC}"
        read -r public_key

        # Validate public key format
        if [[ ! "$public_key" =~ ^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ssh-dss) ]]; then
            echo -e "${RED}Error: Invalid public key format${NC}"
            exit 1
        fi

        # Add to authorized_keys if not already present
        if grep -Fxq "$public_key" ~/.ssh/authorized_keys 2>/dev/null; then
            echo -e "${YELLOW}This key is already in authorized_keys${NC}"
        else
            echo "$public_key" >> ~/.ssh/authorized_keys
            echo -e "${GREEN}✓ Public key added to authorized_keys${NC}"
        fi
        ;;
    2)
        echo -e "\n${YELLOW}Generating new SSH key pair...${NC}"
        TEMP_KEY="/tmp/ssh_temp_key"
        ssh-keygen -t ed25519 -f "$TEMP_KEY" -N "" -C "$(whoami)@$(hostname)"

        echo -e "\n${GREEN}=== PRIVATE KEY (save this to your client machine) ===${NC}"
        echo -e "${YELLOW}Save this as ~/.ssh/id_ed25519 (or ~/.ssh/server_key) on your client:${NC}"
        echo "==========================================="
        cat "$TEMP_KEY"
        echo "==========================================="

        # Add public key to authorized_keys
        cat "$TEMP_KEY.pub" >> ~/.ssh/authorized_keys
        echo -e "\n${GREEN}✓ Public key added to authorized_keys${NC}"

        # Show the public key for reference
        echo -e "\n${YELLOW}Public key (for reference):${NC}"
        cat "$TEMP_KEY.pub"

        # Clean up temp files
        rm -f "$TEMP_KEY" "$TEMP_KEY.pub"

        echo -e "\n${RED}IMPORTANT: Save the private key above before continuing!${NC}"
        read -p "Press Enter after you've saved the private key..."
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo -e "\n${YELLOW}Now hardening SSH server configuration...${NC}"

# Backup SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✓ SSH config backed up${NC}"

# Harden SSH configuration
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

echo -e "${GREEN}✓ SSH configuration hardened${NC}"

# Test configuration before restarting
echo -e "\n${YELLOW}Testing SSH configuration...${NC}"
if sudo sshd -t; then
    echo -e "${GREEN}✓ Configuration is valid${NC}"

    echo -e "\n${RED}WARNING: About to restart SSH service${NC}"
    echo -e "${YELLOW}Make sure you have another terminal session open!${NC}"
    echo -e "${YELLOW}If something goes wrong, you can revert using the backup${NC}"
    read -p "Restart SSH service now? (y/n): " restart_confirm

    if [[ "$restart_confirm" == "y" ]]; then
        sudo systemctl restart ssh || sudo systemctl restart sshd
        echo -e "${GREEN}✓ SSH service restarted${NC}"
    else
        echo -e "${YELLOW}Skipping restart. Run manually: sudo systemctl restart ssh${NC}"
    fi
else
    echo -e "${RED}Configuration test failed! Not restarting SSH.${NC}"
    echo -e "${YELLOW}Restore backup: sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== SETUP COMPLETE ===${NC}"
echo -e "\n${YELLOW}Client machine setup instructions:${NC}"
if [[ $key_option == "2" ]]; then
    echo -e "1. Save the private key shown above to ${BLUE}~/.ssh/server_key${NC}"
    echo -e "2. Run: ${GREEN}chmod 600 ~/.ssh/server_key${NC}"
    echo -e "3. Connect: ${GREEN}ssh -i ~/.ssh/server_key $(whoami)@$(hostname -I | awk '{print $1}')${NC}"
else
    echo -e "1. Connect: ${GREEN}ssh $(whoami)@$(hostname -I | awk '{print $1}')${NC}"
fi
echo -e "\n${YELLOW}Security features enabled:${NC}"
echo -e "  ✓ Password authentication disabled"
echo -e "  ✓ Public key authentication enabled"
echo -e "  ✓ Root login disabled"
echo -e "  ✓ Empty passwords disabled"

#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script info
SCRIPT_NAME="SSH Security Configuration Script"
SCRIPT_VERSION="1.0.0"

# SSH config paths
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_CONFIG_BACKUP="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# Function to display banner
show_banner() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "   $SCRIPT_NAME"
    echo "   Version: $SCRIPT_VERSION"
    echo "========================================"
    echo -e "${NC}"
}

# Function to check if running on Debian-based system
check_debian() {
    if ! grep -E 'debian|ubuntu' /etc/os-release > /dev/null 2>&1; then
        echo -e "${RED}Error: This script is designed for Debian-based systems only.${NC}"
        exit 1
    fi
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}Warning: Running as root. SSH key will be created for root user.${NC}"
        read -p "Continue as root? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}Exiting. Please run as regular user with sudo for system changes.${NC}"
            exit 1
        fi
    fi
}

# Function to create SSH directory if it doesn't exist
ensure_ssh_dir() {
    if [[ ! -d "$SSH_DIR" ]]; then
        echo -e "${YELLOW}Creating SSH directory...${NC}"
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
    fi
}

# Function to generate SSH key
generate_ssh_key() {
    echo -e "\n${BLUE}=== SSH Key Generation ===${NC}"
    
    # Check if key already exists
    if [[ -f "$SSH_DIR/id_rsa" ]] || [[ -f "$SSH_DIR/id_ed25519" ]]; then
        echo -e "${YELLOW}SSH keys already exist:${NC}"
        ls -la "$SSH_DIR"/id_* 2>/dev/null || true
        read -p "Generate new key anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Key type selection
    echo -e "\n${GREEN}Select key type:${NC}"
    echo "1) RSA (4096 bits) - Most compatible"
    echo "2) Ed25519 - Modern and secure (recommended)"
    read -p "Choice (1-2) [2]: " key_choice
    key_choice=${key_choice:-2}
    
    # Get key comment
    read -p "Enter comment for key (e.g., your email): " key_comment
    
    case $key_choice in
        1)
            ssh-keygen -t rsa -b 4096 -C "$key_comment" -f "$SSH_DIR/id_rsa"
            ;;
        2)
            ssh-keygen -t ed25519 -C "$key_comment" -f "$SSH_DIR/id_ed25519"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return
            ;;
    esac
    
    echo -e "${GREEN}SSH key generated successfully!${NC}"
}

# Function to display public key
display_public_key() {
    echo -e "\n${BLUE}=== Your SSH Public Keys ===${NC}"
    echo -e "${YELLOW}Copy these to your remote servers BEFORE applying SSH hardening:${NC}\n"
    
    if [[ -f "$SSH_DIR/id_rsa.pub" ]]; then
        echo -e "${GREEN}RSA Public Key:${NC}"
        cat "$SSH_DIR/id_rsa.pub"
        echo
    fi
    
    if [[ -f "$SSH_DIR/id_ed25519.pub" ]]; then
        echo -e "${GREEN}Ed25519 Public Key:${NC}"
        cat "$SSH_DIR/id_ed25519.pub"
        echo
    fi
    
    echo -e "${RED}IMPORTANT: Save these keys and add them to your servers NOW!${NC}"
    echo -e "${YELLOW}You can add them to remote servers with:${NC}"
    echo "ssh-copy-id user@remote-server"
    echo -e "\nOr manually add to ~/.ssh/authorized_keys on remote servers\n"
    
    read -p "Press Enter when you have copied your keys to remote servers..."
}

# Function to verify SSH key access
verify_ssh_access() {
    echo -e "\n${BLUE}=== Verify SSH Access ===${NC}"
    echo -e "${YELLOW}Before we harden SSH, let's verify you can connect with your key.${NC}"
    
    read -p "Do you want to test SSH connection to a server? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${RED}Warning: Skipping SSH test. Make sure you have key access!${NC}"
        return
    fi
    
    read -p "Enter server address (user@host): " test_server
    echo -e "${YELLOW}Testing SSH connection...${NC}"
    
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$test_server" echo "SSH key authentication successful"; then
        echo -e "${GREEN}Success! SSH key authentication is working.${NC}"
    else
        echo -e "${RED}Warning: SSH key authentication failed!${NC}"
        echo -e "${YELLOW}Make sure to copy your public key to the server before continuing.${NC}"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to harden SSH configuration
harden_ssh_config() {
    echo -e "\n${BLUE}=== SSH Hardening Configuration ===${NC}"
    
    if [[ ! -f "$SSHD_CONFIG" ]]; then
        echo -e "${RED}Error: SSH config file not found at $SSHD_CONFIG${NC}"
        return
    fi
    
    # Check if we need sudo
    if [[ ! -w "$SSHD_CONFIG" ]]; then
        echo -e "${YELLOW}Need sudo privileges to modify SSH configuration${NC}"
        SUDO_CMD="sudo"
    else
        SUDO_CMD=""
    fi
    
    # Backup current config
    echo -e "${YELLOW}Backing up current SSH config...${NC}"
    $SUDO_CMD cp "$SSHD_CONFIG" "$SSHD_CONFIG_BACKUP"
    echo -e "${GREEN}Backup saved to: $SSHD_CONFIG_BACKUP${NC}"
    
    # Interactive hardening options
    echo -e "\n${GREEN}Select hardening options:${NC}"
    
    # Disable root login
    read -p "1. Disable root login? (Y/n): " -n 1 -r
    echo
    DISABLE_ROOT=${REPLY:-Y}
    
    # Disable password authentication
    read -p "2. Disable password authentication? (Y/n): " -n 1 -r
    echo
    DISABLE_PASSWORD=${REPLY:-Y}
    
    # Change SSH port
    read -p "3. Change SSH port from 22? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "   Enter new SSH port (1024-65535): " NEW_PORT
        if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]] || [ "$NEW_PORT" -lt 1024 ] || [ "$NEW_PORT" -gt 65535 ]; then
            echo -e "${RED}Invalid port number. Keeping default port 22.${NC}"
            NEW_PORT=""
        fi
    fi
    
    # Limit users
    read -p "4. Limit SSH access to specific users? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "   Enter allowed users (space-separated): " ALLOWED_USERS
    fi
    
    # Create new config
    echo -e "\n${YELLOW}Applying SSH hardening settings...${NC}"
    
    # Create temporary config file
    TEMP_CONFIG=$(mktemp)
    $SUDO_CMD cp "$SSHD_CONFIG" "$TEMP_CONFIG"
    
    # Apply settings
    if [[ $DISABLE_ROOT =~ ^[Yy]$ ]]; then
        $SUDO_CMD sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$TEMP_CONFIG"
        echo -e "${GREEN}✓ Root login disabled${NC}"
    fi
    
    if [[ $DISABLE_PASSWORD =~ ^[Yy]$ ]]; then
        $SUDO_CMD sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$TEMP_CONFIG"
        $SUDO_CMD sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$TEMP_CONFIG"
        $SUDO_CMD sed -i 's/^#*UsePAM.*/UsePAM no/' "$TEMP_CONFIG"
        echo -e "${GREEN}✓ Password authentication disabled${NC}"
    fi
    
    if [[ -n "$NEW_PORT" ]]; then
        $SUDO_CMD sed -i "s/^#*Port.*/Port $NEW_PORT/" "$TEMP_CONFIG"
        echo -e "${GREEN}✓ SSH port changed to $NEW_PORT${NC}"
    fi
    
    if [[ -n "$ALLOWED_USERS" ]]; then
        # Remove existing AllowUsers line if present
        $SUDO_CMD sed -i '/^AllowUsers/d' "$TEMP_CONFIG"
        # Add new AllowUsers line
        echo "AllowUsers $ALLOWED_USERS" | $SUDO_CMD tee -a "$TEMP_CONFIG" > /dev/null
        echo -e "${GREEN}✓ SSH access limited to: $ALLOWED_USERS${NC}"
    fi
    
    # Additional hardening settings
    echo -e "\n${YELLOW}Applying additional security settings...${NC}"
    
    # Ensure these settings exist or add them
    $SUDO_CMD grep -q "^Protocol" "$TEMP_CONFIG" || echo "Protocol 2" | $SUDO_CMD tee -a "$TEMP_CONFIG" > /dev/null
    $SUDO_CMD sed -i 's/^#*Protocol.*/Protocol 2/' "$TEMP_CONFIG"
    
    $SUDO_CMD grep -q "^PubkeyAuthentication" "$TEMP_CONFIG" || echo "PubkeyAuthentication yes" | $SUDO_CMD tee -a "$TEMP_CONFIG" > /dev/null
    $SUDO_CMD sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$TEMP_CONFIG"
    
    $SUDO_CMD grep -q "^PermitEmptyPasswords" "$TEMP_CONFIG" || echo "PermitEmptyPasswords no" | $SUDO_CMD tee -a "$TEMP_CONFIG" > /dev/null
    $SUDO_CMD sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$TEMP_CONFIG"
    
    $SUDO_CMD grep -q "^MaxAuthTries" "$TEMP_CONFIG" || echo "MaxAuthTries 3" | $SUDO_CMD tee -a "$TEMP_CONFIG" > /dev/null
    $SUDO_CMD sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' "$TEMP_CONFIG"
    
    $SUDO_CMD grep -q "^ClientAliveInterval" "$TEMP_CONFIG" || echo "ClientAliveInterval 300" | $SUDO_CMD tee -a "$TEMP_CONFIG" > /dev/null
    $SUDO_CMD sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 300/' "$TEMP_CONFIG"
    
    $SUDO_CMD grep -q "^ClientAliveCountMax" "$TEMP_CONFIG" || echo "ClientAliveCountMax 2" | $SUDO_CMD tee -a "$TEMP_CONFIG" > /dev/null
    $SUDO_CMD sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 2/' "$TEMP_CONFIG"
    
    echo -e "${GREEN}✓ Additional security settings applied${NC}"
    
    # Test configuration
    echo -e "\n${YELLOW}Testing SSH configuration...${NC}"
    if $SUDO_CMD sshd -t -f "$TEMP_CONFIG"; then
        echo -e "${GREEN}✓ Configuration test passed${NC}"
        $SUDO_CMD mv "$TEMP_CONFIG" "$SSHD_CONFIG"
    else
        echo -e "${RED}✗ Configuration test failed!${NC}"
        echo -e "${YELLOW}Keeping original configuration${NC}"
        $SUDO_CMD rm -f "$TEMP_CONFIG"
        return 1
    fi
    
    # Restart SSH service
    echo -e "\n${YELLOW}Restarting SSH service...${NC}"
    if systemctl is-active --quiet ssh; then
        $SUDO_CMD systemctl restart ssh
        echo -e "${GREEN}✓ SSH service restarted${NC}"
    elif systemctl is-active --quiet sshd; then
        $SUDO_CMD systemctl restart sshd
        echo -e "${GREEN}✓ SSH service restarted${NC}"
    else
        echo -e "${RED}Warning: Could not restart SSH service automatically${NC}"
        echo -e "${YELLOW}Please restart SSH manually with: sudo systemctl restart ssh${NC}"
    fi
    
    # Final warnings
    echo -e "\n${RED}IMPORTANT REMINDERS:${NC}"
    echo -e "${YELLOW}1. Keep this terminal session open until you verify access${NC}"
    echo -e "${YELLOW}2. Test SSH access in a NEW terminal window${NC}"
    if [[ -n "$NEW_PORT" ]]; then
        echo -e "${YELLOW}3. Connect using new port: ssh -p $NEW_PORT user@server${NC}"
    fi
    if [[ $DISABLE_PASSWORD =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}4. Password authentication is now disabled - use SSH keys only${NC}"
    fi
    echo -e "${YELLOW}5. If you lose access, restore from: $SSHD_CONFIG_BACKUP${NC}"
}

# Function to setup authorized_keys
setup_authorized_keys() {
    echo -e "\n${BLUE}=== Authorized Keys Setup ===${NC}"
    
    if [[ ! -f "$AUTHORIZED_KEYS" ]]; then
        echo -e "${YELLOW}Creating authorized_keys file...${NC}"
        touch "$AUTHORIZED_KEYS"
        chmod 600 "$AUTHORIZED_KEYS"
    fi
    
    echo -e "${GREEN}Current authorized keys:${NC}"
    if [[ -s "$AUTHORIZED_KEYS" ]]; then
        cat "$AUTHORIZED_KEYS"
    else
        echo "(none)"
    fi
    
    read -p "Do you want to add a public key to authorized_keys? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Paste the public key (press Ctrl+D when done):${NC}"
        NEW_KEY=$(cat)
        echo "$NEW_KEY" >> "$AUTHORIZED_KEYS"
        echo -e "${GREEN}✓ Key added to authorized_keys${NC}"
    fi
}

# Main function
main() {
    show_banner
    check_debian
    check_root
    
    echo -e "${YELLOW}This script will:${NC}"
    echo "1. Generate SSH keys (if needed)"
    echo "2. Display your public key for copying to servers"
    echo "3. Verify SSH key access"
    echo "4. Harden SSH configuration"
    echo "5. Setup authorized_keys file"
    echo
    read -p "Continue? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Exiting..."
        exit 0
    fi
    
    # Ensure SSH directory exists
    ensure_ssh_dir
    
    # Generate SSH keys
    generate_ssh_key
    
    # Display public keys
    display_public_key
    
    # Verify SSH access
    verify_ssh_access
    
    # Setup authorized_keys
    setup_authorized_keys
    
    # Harden SSH config
    read -p "Do you want to harden SSH configuration? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        harden_ssh_config
    fi
    
    echo -e "\n${GREEN}=== SSH Security Setup Complete ===${NC}"
    echo -e "${YELLOW}Remember to:${NC}"
    echo "- Test SSH access in a new terminal"
    echo "- Keep backup of $SSHD_CONFIG_BACKUP"
    echo "- Document any port changes"
    echo -e "\n${GREEN}Stay secure!${NC}"
}

# Run main function
main "$@"
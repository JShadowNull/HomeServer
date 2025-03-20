#!/bin/bash

# Function to prompt for required input
prompt() {
    while true; do
        read -p "$1: " input
        if [ -n "$input" ]; then
            echo "$input"
            break
        else
            echo "Error: This field cannot be empty."
        fi
    done
}

# Step 1: Prompt for email and custom key name
email=$(prompt "Enter your GitHub email address")
keyname=$(prompt "Enter a custom name for your SSH key (e.g., mykey)")

# Define key paths
private_key="$HOME/.ssh/$keyname"
public_key="$private_key.pub"

# Step 2: Check if key files already exist
if [ -f "$private_key" ] || [ -f "$public_key" ]; then
    read -p "SSH key '$keyname' already exists. Overwrite? (y/n): " overwrite
    if [[ "$overwrite" != "y" ]]; then
        echo "Exiting..."
        exit 1
    fi
    rm -f "$private_key" "$public_key"  # Remove existing keys
fi

# Step 3: Generate SSH key
echo "Generating SSH key..."
ssh-keygen -t ed25519 -C "$email" -f "$private_key" -N ""

# Step 4: Add SSH key to SSH agent
echo "Adding SSH key to SSH agent..."
eval "$(ssh-agent -s)"
ssh-add "$private_key"

# Step 5: Display public key
echo -e "\nYour SSH public key is:"
cat "$public_key"
echo -e "\nCopy the key above and add it to GitHub:"
echo "1. Go to https://github.com/settings/ssh/new"
echo "2. Paste the key and save"

# Step 6: Confirm key added to GitHub
read -p "Have you added the SSH key to GitHub? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Please add the SSH key to GitHub and rerun this script."
    exit 1
fi

# Step 7: Prompt for SSH remote URL
ssh_url=$(prompt "Enter your repository's SSH URL (e.g., git@github.com:username/repo.git)")

# Step 8: Update remote origin
echo "Updating git remote origin..."
git remote set-url origin "$ssh_url"

# Step 9: Verify changes
echo -e "\nNew remote URL:"
git remote -v

# Step 10: Test connection
echo -e "\nTesting SSH connection to GitHub..."
ssh -T git@github.com

echo -e "\nSetup complete! You can now use SSH with your custom key '$keyname'."

#!/bin/bash

# ===============================================================
#  User Creation Script
#  - Ensures figlet is installed
#  - Enforces lowercase-only usernames
#  - Loops until valid username entered
#  - Optionally grants sudo privileges
# ===============================================================

# Ensure figlet is installed
if ! command -v figlet &>/dev/null; then
    echo "⚙️  'figlet' is not installed. Installing now..."
    sudo apt update -qq && sudo apt install -y figlet >/dev/null
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to install figlet. Please install it manually with: sudo apt install figlet"
        exit 1
    fi
    echo "✅ figlet installed successfully."
fi

# Function to display a title
function display_title() {
    echo -e "\n$(figlet -f slant "$1")\n"
}

# Function to display a check title
function display_check_title() {
    echo -e "\n$(figlet -f small "$1")\n"
}

# Display title
display_title "User Creation Script"

# Prompt for valid username (lowercase only)
while true; do
    read -p "Enter the username for the new user (lowercase only): " username

    # Check for lowercase-only valid usernames
    if [[ ! "$username" =~ ^[a-z][-a-z0-9_]*$ ]]; then
        echo "❌ Invalid username. Use lowercase letters, numbers, hyphens, or underscores only."
        continue
    fi

    # Check if the username already exists
    if id "$username" &>/dev/null; then
        echo "⚠️  User '$username' already exists. Please choose a different username."
        continue
    fi

    # Username is valid
    break
done

# Prompt for password
read -s -p "Enter a password for $username: " password
echo

# Prompt for sudo privileges
read -p "Do you want to grant sudo privileges to $username? (y/n): " grant_sudo

# Create the user
if ! sudo adduser --disabled-password --gecos "" "$username"; then
    echo "❌ Failed to create user '$username'. Exiting."
    exit 1
fi

# Set the password for the new user
echo "$username:$password" | sudo chpasswd

# Grant sudo privileges if requested
if [[ "$grant_sudo" =~ ^[Yy]$ ]]; then
    sudo usermod -aG sudo "$username"
    echo "✅ Sudo privileges granted to '$username'."
else
    echo "ℹ️  Sudo privileges not granted to '$username'."
fi

# Display completion message
display_check_title "User Creation Complete"
echo "🎉 User '$username' has been created successfully."

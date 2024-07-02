#!/bin/bash

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

# Prompt for username
read -p "Enter the username for the new user: " username

# Prompt for password
read -s -p "Enter a password for $username: " password
echo

# Prompt for sudo privileges
read -p "Do you want to grant sudo privileges to $username? (y/n): " grant_sudo

# Check if the username already exists
if id "$username" &>/dev/null; then
    echo "User '$username' already exists. Please choose a different username."
    exit 1
fi

# Create the user with the provided password and home directory
sudo adduser --disabled-password --gecos "" "$username"

# Set the password for the new user
echo "$username:$password" | sudo chpasswd

# Check if sudo privileges should be granted
if [[ "$grant_sudo" == [yY] || "$grant_sudo" == [yY][eE][sS] ]]; then
    # Add the user to the sudo group
    sudo usermod -aG sudo "$username"
    echo "Sudo privileges granted to '$username'."
else
    echo "Sudo privileges not granted to '$username'."
fi

# Display completion message
display_check_title "User Creation Complete"
echo "User '$username' has been created."

# Optional: Set a password for the new user
# sudo passwd "$username"

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

# Prompt for YOUR_SECURE_PASSWORD_HERE
read -s -p "Enter a YOUR_SECURE_PASSWORD_HERE for $username: " YOUR_SECURE_PASSWORD_HERE
echo

# Prompt for sudo privileges
read -p "Do you want to grant sudo privileges to $username? (y/n): " grant_sudo

# Check if the username already exists
if id "$username" &>/dev/null; then
    echo "User '$username' already exists. Please choose a different username."
    exit 1
fi

# Create the user with the provided YOUR_SECURE_PASSWORD_HERE and home directory
sudo adduser --disabled-YOUR_SECURE_PASSWORD_HERE --gecos "" "$username"

# Set the YOUR_SECURE_PASSWORD_HERE for the new user
echo "$username:$YOUR_SECURE_PASSWORD_HERE" | sudo chpasswd

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

# Optional: Set a YOUR_SECURE_PASSWORD_HERE for the new user
# sudo passwd "$username"

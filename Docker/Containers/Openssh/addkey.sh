#!/bin/bash

# Function to display a title
function display_title() {
    echo -e "\n$(figlet -f slant "$1")\n"
}

# Display title
display_title "Add SSH Key to User Script"

# Check if Figlet is installed
if ! command -v figlet &> /dev/null; then
    echo "Figlet is not installed. Please install Figlet to use this script."
    exit 1
fi

# Prompt for the target user
echo "Select a user to add an SSH key for:"
mapfile -t system_users < <(getent passwd | cut -d: -f1)
PS3="Enter the number of the user: "
select user_choice in "${system_users[@]}"; do
    if [[ -n $user_choice ]]; then
        selected_user="$user_choice"
        echo "Selected user: $selected_user"
        break
    else
        echo "Invalid option. Please select a user."
    fi
done

# Create SSH key directory if it doesn't exist for the selected user
ssh_key_dir="/home/$selected_user/.ssh"
if [ ! -d "$ssh_key_dir" ]; then
    echo "Creating SSH key directory for $selected_user..."
    mkdir -p "$ssh_key_dir"
    chown "$selected_user:$selected_user" "$ssh_key_dir"
    chmod 700 "$ssh_key_dir"
fi

# Prompt for the SSH key
echo "Please paste the public SSH key to add for $selected_user below:"
read -p "Enter public key (press Enter to finish): " ssh_key
while [ -n "$ssh_key" ]; do
    echo "$ssh_key" >> "$ssh_key_dir/authorized_keys"
    echo "SSH key added for $selected_user."
    read -p "Enter another public key (press Enter to finish): " ssh_key
done

# Set permissions for the authorized_keys file
chmod 600 "$ssh_key_dir/authorized_keys"

# Display completion message
display_title "SSH Key Added to User"
echo "SSH key(s) have been added to the authorized_keys file for $selected_user."

# Function to display a title for the configuration check
function display_check_title() {
    echo -e "\n== $1 ==\n"
}

# Display title for configuration check
display_check_title "OpenSSH Configuration Check"

# Check SSH key directory permissions
echo -e "\nChecking SSH key directory permissions for $selected_user...\n"
if [ -d "$ssh_key_dir" ]; then
    key_dir_permissions=$(stat -c %a "$ssh_key_dir")
    if [ "$key_dir_permissions" -eq 700 ]; then
        echo "SSH key directory permissions are set correctly (700)."
    else
        echo "SSH key directory permissions are incorrect. Setting to 700..."
        chmod 700 "$ssh_key_dir"
        echo "SSH key directory permissions have been set to 700."
    fi
else
    echo "SSH key directory not found for $selected_user: $ssh_key_dir"
fi

# Check authorized_keys file permissions
echo -e "\nChecking authorized_keys file permissions for $selected_user...\n"
authorized_keys_file="$ssh_key_dir/authorized_keys"
if [ -e "$authorized_keys_file" ]; then
    keys_file_permissions=$(stat -c %a "$authorized_keys_file")
    if [ "$keys_file_permissions" -eq 600 ]; then
        echo "authorized_keys file permissions are set correctly (600)."
    else
        echo "authorized_keys file permissions are incorrect. Setting to 600..."
        chmod 600 "$authorized_keys_file"
        echo "authorized_keys file permissions have been set to 600."
    fi
else
    echo "authorized_keys file not found for $selected_user: $authorized_keys_file"
fi

# Display completion message for the configuration check
display_check_title "Configuration Check Complete"
echo "OpenSSH configuration and permissions check complete."

#!/bin/bash

# Function to display a title
function display_title() {
    echo -e "\n$(figlet -f slant "$1")\n"
}

# Display title
display_title "SSH Configuration Script"

# Check if Figlet is installed
if ! command -v figlet &> /dev/null; then
    echo "Figlet is not installed. Please install Figlet to use this script."
    exit 1
fi

# Create SSH key directory if it doesn't exist
ssh_key_dir="$HOME/.ssh"
if [ ! -d "$ssh_key_dir" ]; then
    echo "Creating SSH key directory..."
    mkdir -p "$ssh_key_dir"
    chmod 700 "$ssh_key_dir"
fi

# Install OpenSSH server
echo "Installing OpenSSH server..."
sudo apt-get update
sudo apt-get install -y openssh-server

# Configure SSH settings
echo -e "\nConfiguring SSH settings...\n"

# Disable root login
read -p "Disable root login? (yes/no): " disable_root
if [[ $disable_root == "yes" ]]; then
    echo "PermitRootLogin no" | sudo tee /etc/ssh/sshd_config
    echo "Root login disabled."
fi

# Disable YOUR_SECURE_PASSWORD_HERE login
read -p "Disable YOUR_SECURE_PASSWORD_HERE login? (yes/no): " disable_YOUR_SECURE_PASSWORD_HERE
if [[ $disable_YOUR_SECURE_PASSWORD_HERE == "yes" ]]; then
    echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
    echo "Password login disabled."
fi

# Prompt for authorized keys
read -p "Would you like to add authorized SSH keys? (yes/no): " add_keys
if [[ $add_keys == "yes" ]]; then
    echo "Please paste your public SSH key(s) below:"
    read -p "Enter public key (press Enter to finish): " ssh_key
    while [ -n "$ssh_key" ]; do
        echo "$ssh_key" | sudo tee -a "$ssh_key_dir/authorized_keys"
        read -p "Enter another public key (press Enter to finish): " ssh_key
    done
    echo "Authorized keys added."
fi

# Prompt for user to configure SSH keys for
echo -e "\nSelect a user to configure SSH keys for:"
mapfile -t system_users < <(getent passwd | cut -d: -f1)
PS3="Enter the number of the user (or 0 to skip): "
select user_choice in "${system_users[@]}"; do
    if [[ $REPLY -eq 0 ]]; then
        echo "Skipping user configuration."
        break
    elif [[ -n $user_choice ]]; then
        echo "Configuring SSH keys for user: $user_choice"
        ssh_key_file="/home/$user_choice/.ssh/authorized_keys"
        mkdir -p "$(dirname "$ssh_key_file")"
        touch "$ssh_key_file"
        chmod 700 "$(dirname "$ssh_key_file")"
        chmod 600 "$ssh_key_file"
        echo "Authorized keys file created: $ssh_key_file"
        echo "Please paste the public SSH key(s) for $user_choice below:"
        read -p "Enter public key (press Enter to finish): " user_ssh_key
        while [ -n "$user_ssh_key" ]; do
            echo "$user_ssh_key" >> "$ssh_key_file"
            read -p "Enter another public key (press Enter to finish): " user_ssh_key
        done
        echo "Authorized keys added for user: $user_choice"
        break
    else
        echo "Invalid option. Please select a user or enter 0 to skip."
    fi
done

# Restart SSH service
sudo systemctl restart ssh

# Display completion message
display_title "SSH Configuration Complete"
echo "SSH configuration is complete. You can now connect using SSH keys."

# Function to display a title for the configuration check
function display_check_title() {
    echo -e "\n== $1 ==\n"
}

# Display title for configuration check
display_check_title "OpenSSH Configuration Check"

# Check SSH configuration syntax
echo -e "\nChecking SSH configuration syntax...\n"
if sudo /usr/sbin/sshd -t; then
    echo "SSH configuration syntax is valid."
else
    echo "SSH configuration syntax is invalid. Please review the configuration file."
fi

# Check SSH configuration file permissions
echo -e "\nChecking SSH configuration file permissions...\n"
config_file="/etc/ssh/sshd_config"
if [ -e "$config_file" ]; then
    config_permissions=$(stat -c %a "$config_file")
    if [ "$config_permissions" -eq 644 ]; then
        echo "SSH configuration file permissions are set correctly (644)."
    else
        echo "SSH configuration file permissions are incorrect. Setting to 644..."
        sudo chmod 644 "$config_file"
        echo "SSH configuration file permissions have been set to 644."
    fi
else
    echo "SSH configuration file not found: $config_file"
fi

# Check SSH key directory permissions
echo -e "\nChecking SSH key directory permissions...\n"
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
    echo "SSH key directory not found: $ssh_key_dir"
fi

# Check authorized_keys file permissions
echo -e "\nChecking authorized_keys file permissions...\n"
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
    echo "authorized_keys file not found: $authorized_keys_file"
fi

# Display completion message for the configuration check
display_check_title "Configuration Check Complete"
echo "OpenSSH configuration and permissions check complete."

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
display_title "WireGuard Cleanup Script"

# Prompt for the WireGuard configuration file name
read -p "Enter the name of the WireGuard configuration file (without the .conf extension): " wg_config_file

# Check if the WireGuard configuration file exists
if [ -e "/etc/wireguard/$wg_config_file.conf" ]; then
    # Stop and disable the WireGuard service
    sudo systemctl stop wg-quick@"$wg_config_file"
    sudo systemctl disable wg-quick@"$wg_config_file"
    
    # Remove the WireGuard configuration file
    echo "Removing WireGuard configuration file..."
    sudo rm -f "/etc/wireguard/$wg_config_file.conf"
else
    echo "WireGuard configuration file does not exist."
fi

# Remove system IP and name from /etc/hosts
if [ -n "$system_ip" ] && [ -n "$system_name" ]; then
    echo "Removing system IP and name from /etc/hosts..."
    sudo sed -i "/$system_ip $system_name/d" /etc/hosts
fi

# Remove DNS server entry from resolvconf
if [ -n "$wg_dns_server" ]; then
    echo "Removing DNS server entry from resolvconf..."
    echo "nameserver $wg_dns_server" | sudo resolvconf -d tun.$wg_config_file
fi

# Uninstall WireGuard
echo "Uninstalling WireGuard..."
sudo apt-get remove --purge -y wireguard

# Disable IPv4 forwarding
echo "Disabling IPv4 forwarding..."
sudo sysctl -w net.ipv4.ip_forward=0

# Display completion message for the clean-up script
display_check_title "Clean-Up Complete"
echo "WireGuard configuration and changes have been undone."

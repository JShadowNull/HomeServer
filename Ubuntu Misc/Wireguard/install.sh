#!/bin/bash

# Function to display a title
function display_title() {
    echo -e "\n$(figlet -f slant "$1")\n"
}

# Function to display a check title
function display_check_title() {
    echo -e "\n$(figlet -f small "$1")\n"
}

# Function to create a symbolic link from /etc/resolv.conf to /run/resolvconf/resolv.conf
function create_resolvconf_symlink() {
    echo "Creating symbolic link from /etc/resolv.conf to /run/resolvconf/resolv.conf..."
    sudo ln -sf /run/resolvconf/resolv.conf /etc/resolv.conf
}

# Display title
display_title "WireGuard Configuration Script"

# Check if Figlet is installed
if ! command -v figlet &> /dev/null; then
    echo "Figlet is not installed. Please install Figlet to use this script."
    exit 1
fi

# Check if resolvconf is installed
if ! dpkg -l | grep -q "ii  resolvconf"; then
    echo "Installing resolvconf..."
    sudo apt-get update
    sudo apt-get install -y resolvconf
fi

# Check if NetworkManager is installed
if ! dpkg -l | grep -q "ii  NetworkManager"; then
    echo "Installing NetworkManager..."
    sudo apt-get update
    sudo apt-get install -y network-manager
fi

# Create a symbolic link for /etc/resolv.conf if it doesn't exist
if [ ! -L /etc/resolv.conf ]; then
    create_resolvconf_symlink
fi

# Enable IPv4 forwarding
echo "Enabling IPv4 forwarding..."

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# Uncomment the IPv4 forwarding line in /etc/sysctl.conf
sed -i '/^#net.ipv4.ip_forward=/s/^#//' /etc/sysctl.conf

#Apply changes
echo "IPv4 forwarding has been enabled."
sudo sysctl -p

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install WireGuard
echo "Installing WireGuard..."
sudo apt-get install -y wireguard

# Prompt for WireGuard configuration file name
read -p "Enter the name of the WireGuard configuration file (without the .conf extension): " wg_config_file

# Check if the configuration file already exists
if [ ! -e "/etc/wireguard/$wg_config_file.conf" ]; then
    # Create a new WireGuard configuration file
    echo "Creating a new WireGuard configuration file..."
    sudo touch "/etc/wireguard/$wg_config_file.conf"
    sudo chmod 600 "/etc/wireguard/$wg_config_file.conf"
    echo "WireGuard configuration file created at /etc/wireguard/$wg_config_file.conf."
fi

# Open WireGuard configuration file in nano editor
echo "Opening WireGuard configuration file in nano editor..."
sudo nano "/etc/wireguard/$wg_config_file.conf"

# Create a systemd service unit for WireGuard
echo "Creating a systemd service unit for WireGuard..."
cat <<EOF | sudo tee "/etc/systemd/system/wg-quick@$wg_config_file.service" > /dev/null
[Unit]
Description=Manage WireGuard VPN Interface $wg_config_file

[Service]
Type=oneshot
ExecStart=/usr/bin/wg-quick up $wg_config_file
ExecStop=/usr/bin/wg-quick down $wg_config_file
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Extract DNS server IP from WireGuard configuration file
wg_dns_server=$(grep -Eo 'DNS = [0-9.]+' "/etc/wireguard/$wg_config_file.conf" | cut -d ' ' -f 3)

# Check if DNS server IP is found
if [ -z "$wg_dns_server" ]; then
    echo "DNS server IP not found in WireGuard configuration file. Please manually configure resolvconf."
else
    # Configure resolvconf for WireGuard with extracted DNS server IP
    echo "Configuring resolvconf for WireGuard with DNS server IP: $wg_dns_server"
    echo "nameserver $wg_dns_server" | sudo resolvconf -a tun.$wg_config_file -m 0 -x
fi

# Start and enable WireGuard service
sudo systemctl daemon-reload
sudo systemctl start "wg-quick@$wg_config_file"
sudo systemctl enable "wg-quick@$wg_config_file"

# Display WireGuard interface status
display_check_title "WireGuard Status"
sudo systemctl status "wg-quick@$wg_config_file"

# Display completion message for the configuration check
display_check_title "Configuration Check Complete"
echo "WireGuard configuration and permissions check complete."
echo "WireGuard service has been started and enabled."

# Restart NetworkManager service to apply DNS changes
echo "Restarting NetworkManager service..."
sudo systemctl restart NetworkManager
sudo systemctl enable NetworkManager

echo "WireGuard service enabled and started."

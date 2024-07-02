
# WireGuard Configuration and Cleanup Scripts

These scripts help you configure and clean up WireGuard on your system.

## Prerequisites

- Ensure you have `figlet` installed for displaying titles. You can install it using:
  ```bash
  sudo apt-get install figlet
  ```

## Configuration Script

### Script Content

Save the following content to a file, for example, `wg_config.sh`:

```bash
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
```

### Usage

1. Save the script content to a file, for example, `wg_config.sh`.

2. Make the script executable:
   ```bash
   chmod +x wg_config.sh
   ```

3. Run the script:
   ```bash
   ./wg_config.sh
   ```

## Cleanup Script

### Script Content

Save the following content to a file, for example, `wg_cleanup.sh`:

```bash
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
```

### Usage

1. Save the script content to a file, for example, `wg_cleanup.sh`.

2. Make the script executable:
   ```bash
   chmod +x wg_cleanup.sh
   ```

3. Run the script:
   ```bash
   ./wg_cleanup.sh
   ```

## Notes

- The configuration script checks if required packages (`figlet`, `resolvconf`, `network-manager`) are installed and installs them if necessary.
- It enables IPv4 forwarding and creates a symbolic link for `/etc/resolv.conf`.
- The script prompts for the WireGuard configuration file name and creates a new configuration file if it doesn't exist.
- It creates a systemd service unit for WireGuard and starts the service.
- The cleanup script stops and disables the WireGuard service, removes the configuration file, and uninstalls WireGuard.
- It also removes the DNS server entry from `resolvconf` and disables IPv4 forwarding.

By following these steps, you can configure and clean up WireGuard on your system efficiently.
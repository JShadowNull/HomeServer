
# Docker Install Script

This script will install Docker on an Ubuntu system. Follow the steps below to ensure Docker is installed correctly.

## Prerequisites

- **Ubuntu system**: Ensure you are running an Ubuntu-based system.
- **Sudo privileges**: You must have sudo privileges to install Docker.

## Installation Steps

1. **Create and Run the Install Script**

   Save the following script to a file, for example `install_docker.sh`, and run it with `sudo`:

   ```bash
   #!/bin/bash

   # Update package index and install required packages
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl

   # Create the directory for Docker's GPG key
   sudo install -m 0755 -d /etc/apt/keyrings

   # Add Docker's official GPG key
   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc

   # Add Docker's repository to Apt sources
   echo      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

   # Update the package index and install Docker packages
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

   # Output Docker version to verify installation
   docker --version
   ```

2. **Make the Script Executable**

   Run the following command to make the script executable:

   ```bash
   chmod +x install_docker.sh
   ```

3. **Run the Script**

   Execute the script to install Docker:

   ```bash
   sudo ./install_docker.sh
   ```

4. **Verify Docker Installation**

   After the script completes, verify the installation by checking the Docker version:

   ```bash
   docker --version
   ```

## Conclusion

By following these steps, you should have Docker installed on your Ubuntu system. This script ensures that the latest version of Docker is installed from the official Docker repository.
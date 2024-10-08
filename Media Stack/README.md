
# Docker Compose Configuration Instructions

This guide will help you set up and run the provided Docker Compose configuration with a .env file for managing sensitive data. Please follow the steps below to customize the configuration for your environment.

## Prerequisites

- Docker and Docker Compose installed on your system.
- Basic understanding of Docker and networking.

## Files Included

- `docker-compose.yml`: The main Docker Compose configuration file.
- `.env`: File containing environment variables.

## Steps to Customize and Run

1. **Download the Configuration Files**

   Ensure you have the `docker-compose.yml` file and create a `.env` file in the same directory.

2. **Create and Edit the .env File**

   Create a `.env` file in the same directory as your `docker-compose.yml` file and add the following environment variables:

   ```plaintext
   VPN_SERVICE_PROVIDER=custom
   VPN_TYPE=wireguard
   VPN_ENDPOINT_IP=example_ip
   VPN_ENDPOINT_PORT=example_port
   WIREGUARD_PUBLIC_KEY=example_public_key
   WIREGUARD_PRIVATE_KEY=example_private_key
   WIREGUARD_PRESHARED_KEY=example_preshared_key
   WIREGUARD_ADDRESSES=10.144.141.30/32
   PUID=1000
   PGID=1000
   TZ=America/New_York
   WEBUI_PASSWORD=example_password
   WEBUI_USERNAME=admin
   ```

   Replace the placeholders with your actual values.

3. **Edit the docker-compose.yml File**

   Open the `docker-compose.yml` file in a text editor and reference the environment variables from the `.env` file:

   ### Gluetun Service

   ```yaml
   gluetun:
     environment:
       - VPN_SERVICE_PROVIDER=${VPN_SERVICE_PROVIDER}
       - VPN_TYPE=${VPN_TYPE}
       - VPN_ENDPOINT_IP=${VPN_ENDPOINT_IP}
       - VPN_ENDPOINT_PORT=${VPN_ENDPOINT_PORT}
       - WIREGUARD_PUBLIC_KEY=${WIREGUARD_PUBLIC_KEY}
       - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}
       - WIREGUARD_PRESHARED_KEY=${WIREGUARD_PRESHARED_KEY}
       - WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES}
   ```

   ### Jackett Service

   ```yaml
   jackett:
     volumes:
       - /path/to/jackett/config:/config  # Replace with actual path to Jackett config
       - /path/to/jackett/downloads:/downloads  # Replace with actual path to Jackett downloads
   ```

   ### Radarr Service

   ```yaml
   radarr:
     volumes:
       - /path/to/radarr/config:/config  # Replace with actual path to Radarr config
       - /path/to/Media/Movies:/movies  # Replace with actual path to Movies
       - /path/to/Media/Movies:/downloads/Movies  # Replace with actual path to Movies downloads
       - /path/to/Media/TV:/downloads/tvshows  # Replace with actual path to TV downloads
   ```

   ### Sonarr Service

   ```yaml
   sonarr:
     volumes:
       - /path/to/sonarr/config:/config  # Replace with actual path to Sonarr config
       - /path/to/Media/TV:/tv  # Replace with actual path to TV shows
       - /path/to/qbtorrent/downloads:/downloads  # Replace with actual path to qBittorrent downloads
   ```

   ### Jellyseerr Service

   ```yaml
   jellyseerr:
     volumes:
       - /path/to/jellyseerr/config:/app/config  # Replace with actual path to Jellyseerr config
   ```

   ### Jellyfin Service

   ```yaml
   jellyfin:
     volumes:
       - /path/to/jellyfin/config:/config  # Replace with actual path to Jellyfin config
       - /path/to/Media/TV:/data/tvshows  # Replace with actual path to TV shows
       - /path/to/Media/Movies:/data/movies  # Replace with actual path to Movies
   ```

   ### qBittorrent Services

   ```yaml
   qbittorrentmov:
     environment:
       - WEBUI_PASSWORD=${WEBUI_PASSWORD}
     volumes:
       - /path/to/qbtorrent/config/mov:/config  # Replace with actual path to qBittorrent MOV config
       - /path/to/Media/Movies:/downloads/movies  # Replace with actual path to Movies downloads

   qbittorrenttv:
     environment:
       - WEBUI_PASSWORD=${WEBUI_PASSWORD}
     volumes:
       - /path/to/qbtorrent/config/tv:/config  # Replace with actual path to qBittorrent TV config
       - /path/to/Media/TV:/downloads/tvshows  # Replace with actual path to TV shows downloads
   ```

   ### Portainer Service

   ```yaml
   portainer:
     volumes:
       - /var/run/docker.sock:/var/run/docker.sock
       - portainer_data:/data
   ```

4. **Save the Changes**

   Save the `docker-compose.yml` file and the `.env` file after making the necessary changes.

5. **Run the Docker Compose Stack**

   Open a terminal and navigate to the directory containing the `docker-compose.yml` file. Run the following command to start the services:

   ```bash
   docker-compose up -d
   ```

   This command will start all the services in detached mode.

6. **Verify the Services**

   Use the `docker ps` command to verify that all containers are running:

   ```bash
   docker ps
   ```

   Check the logs for any errors:

   ```bash
   docker-compose logs -f
   ```

## Notes

- Ensure the paths you provide for volumes exist on your host machine.
- Replace the placeholders in the environment variables with your actual values.

## Troubleshooting

- If you encounter any issues, check the logs for each service using the `docker-compose logs <service_name>` command.
- Make sure your VPN settings are correct in the Gluetun service.

For further assistance, refer to the official documentation of each service.
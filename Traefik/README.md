
# Traefik Setup and Configuration

This document provides a step-by-step guide to setting up and configuring Traefik for your home server environment.

## Prerequisites

- Docker installed on your system.
- Docker Compose installed on your system.
- Basic knowledge of Docker and Traefik.

## Directory Structure

Ensure your directory structure is as follows:

```
Traefik/
├── data/
│   ├── acme.json
│   ├── config.yml
│   ├── traefik.yml
├── docker-compose.yml
└── .env
```

## Step-by-Step Guide

### 1. Clone the Repository

First, clone the repository to your local machine:

```bash
git clone https://github.com/JShadowNull/HomeServer.git
cd HomeServer/Traefik
```

### 2. Create `acme.json` File

Create the `acme.json` file which Traefik will use to store SSL certificates:

```bash
touch data/acme.json
chmod 600 data/acme.json
```

### 3. Update Configuration Files

#### `data/traefik.yml`

Update the `data/traefik.yml` file with your desired settings. This file contains the main configuration for Traefik.

#### `data/config.yml`

Update the `data/config.yml` file with your desired settings. This file contains additional dynamic configuration for Traefik.

### 4. Docker Compose Configuration

The `docker-compose.yml` file should look like this:

```yaml
services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    networks:
      - frontend
    ports:
      - 80:80      # HTTP port
      - 443:443    # HTTPS port
      - 8082:8082  # Metrics port
      - 81:81      # Custom port
      - 444:444    # Custom port
    environment:
      CF_DNS_API_TOKEN_FILE: /run/secrets/cf_api_token
      TRAEFIK_DASHBOARD_CREDENTIALS: ${TRAEFIK_DASHBOARD_CREDENTIALS}
      TZ: America/New_York
    secrets:
      - cf_api_token
    env_file: .env
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./data/traefik.yml:/traefik.yml:ro
      - ./data/acme.json:/acme.json
      - ./data/config.yml:/config.yml:ro
      - ./data/logs:/var/log/traefik
      - /home/user/traefik/certs:/home  # Change '/home/user/' to the appropriate path
    command:
      - "--entrypoints.metrics.address=:8082"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.entrypoints=http"
      - "traefik.http.routers.traefik.rule=Host(`traefik.local.example.com`)"  # Change to your Traefik dashboard domain
      - "traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_DASHBOARD_CREDENTIALS}"
      - "traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto=https"
      - "traefik.http.middlewares.trusted-default-whitelist.ipAllowList.sourcerange=10.0.0.0/24,192.168.1.0/24"  # Change to your trusted IP ranges
      - "traefik.http.routers.traefik.middlewares=traefik-https-redirect"
      - "traefik.http.routers.traefik-secure.entrypoints=https"
      - "traefik.http.routers.traefik-secure.rule=Host(`traefik.local.example.com`)"  # Change to your Traefik dashboard domain
      - "traefik.http.routers.traefik-secure.middlewares=traefik-auth, trusted-default-whitelist"
      - "traefik.http.routers.traefik-secure.tls=true"
      - "traefik.http.routers.traefik-secure.tls.certresolver=cloudflare"
      - "traefik.http.routers.traefik-secure.tls.domains[0].main=example.com"  # Change to your main domain
      - "traefik.http.routers.traefik-secure.tls.domains[0].sans=*.example.com"  # Change to your main domain wildcard
      - "traefik.http.routers.traefik-secure.tls.domains[1].main=local.example.com"  # Change to your local domain
      - "traefik.http.routers.traefik-secure.tls.domains[1].sans=*.local.example.com"  # Change to your local domain wildcard
      - "traefik.http.routers.traefik-secure.service=api@internal"

secrets:
  cf_api_token:
    file: ./cf_api_token.txt  # Change to the path where your Cloudflare API token file is located

networks:
  frontend:
    external: true
```

### 5. Start Traefik

Run the following command to start Traefik:

```bash
docker-compose up -d
```

### 6. Access the Dashboard

You can access the Traefik dashboard by navigating to `http://<your-server-ip>:8080` in your web browser.

## Additional Information

- Ensure you have the correct permissions set for `data/acme.json`.
- You can configure middlewares, routers, and services in the `data/config.yml` file according to your needs.
- For more information on Traefik configuration, refer to the [official Traefik documentation](https://doc.traefik.io/traefik/).

## Troubleshooting

If you encounter any issues, check the logs for the Traefik container:

```bash
docker logs traefik
```

For further assistance, consult the Traefik [community forum](https://community.containo.us/).

## License

This project is licensed under the MIT License.
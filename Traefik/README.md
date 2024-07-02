
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
├── acme.json
├── config.yml
├── docker-compose.yml
└── dynamic.yml
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
touch acme.json
chmod 600 acme.json
```

### 3. Update Configuration Files

#### `config.yml`

Update the `config.yml` file with your desired settings. This file contains static configuration for Traefik.

#### `dynamic.yml`

Update the `dynamic.yml` file with your desired settings. This file contains dynamic configuration for Traefik.

### 4. Docker Compose Configuration

The `docker-compose.yml` file should look like this:

```yaml
version: '3.7'

services:
  traefik:
    image: traefik:v2.9
    container_name: traefik
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./traefik.toml:/etc/traefik/traefik.toml
      - ./config.yml:/etc/traefik/config.yml
      - ./dynamic.yml:/etc/traefik/dynamic.yml
      - ./acme.json:/acme.json
    networks:
      - traefik

networks:
  traefik:
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

- Ensure you have the correct permissions set for `acme.json`.
- You can configure middlewares, routers, and services in the `dynamic.yml` file according to your needs.
- For more information on Traefik configuration, refer to the [official Traefik documentation](https://doc.traefik.io/traefik/).

## Troubleshooting

If you encounter any issues, check the logs for the Traefik container:

```bash
docker logs traefik
```

For further assistance, consult the Traefik [community forum](https://community.containo.us/).

## License

This project is licensed under the MIT License.
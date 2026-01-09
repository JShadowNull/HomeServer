# HomeServer Setup Guide

This guide walks you through setting up your complete home server environment with all the included services and security configurations.

## Prerequisites

- Ubuntu/Debian-based system
- Sudo privileges
- Domain name (for external access)
- Cloudflare account (for SSL certificates via Traefik)

## Quick Start

1. **System Setup**
   ```bash
   # Install Docker
   ./scripts/system/install-docker.sh
   
   # Create user and add to Docker group
   ./scripts/user-management/add-user.sh
   ./scripts/user-management/add-docker-group.sh
   
   # Secure SSH access
   ./scripts/system/setup-secure-ssh.sh
   ```

2. **Network Setup**
   ```bash
   # Create Docker networks
   docker network create frontend
   docker network create backend
   ```

3. **Deploy Core Services**
   ```bash
   # Deploy Traefik (reverse proxy)
   cd services/traefik
   docker compose up -d
   
   # Deploy Authentik (authentication)
   cd ../authentik
   docker compose up -d
   
   # Deploy Portainer (container management)
   cd ../portainer
   docker compose up -d
   ```

## Detailed Setup Instructions

### 1. System Preparation

#### Docker Installation
The Docker installation script automatically detects your OS and installs the latest version:
```bash
./scripts/system/install-docker.sh
```

#### User Management
Create a service user for running containers:
```bash
./scripts/user-management/add-user.sh
```

Add users to the Docker group:
```bash
./scripts/user-management/add-docker-group.sh
```

#### SSH Security
Secure your SSH configuration and setup key-based authentication:
```bash
./scripts/system/setup-secure-ssh.sh
```

### 2. Service Configuration

#### Traefik Setup
Traefik acts as your reverse proxy and handles SSL certificates automatically.

1. Configure your domain in `services/traefik/docker-compose.yml`
2. Add your Cloudflare API token to `services/traefik/cf_api_token.txt`
3. Update `services/traefik/data/traefik.yml` with your settings

#### Authentik Setup
Authentik provides single sign-on for all your services.

1. Configure database settings in `services/authentik/docker-compose.yml`
2. Set up initial admin user via web interface
3. Configure LDAP/OAuth providers as needed

#### Media Stack
Includes Plex, Sonarr, Radarr, and other media management tools.

1. Update paths in `services/media-stack/docker-compose.yml`
2. Configure each service via web interfaces

### 3. Optional Services

#### Nextcloud
Self-hosted cloud storage with LDAP integration.

#### Portainer
Web-based Docker management interface.

#### Wireguard VPN
Secure remote access to your home network:
```bash
./scripts/system/setup-wireguard.sh
```

## Security Best Practices

1. **SSH Hardening**: Use key-based authentication only
2. **Firewall**: Configure UFW to allow only necessary ports
3. **SSL**: Use Traefik with Cloudflare for automatic SSL certificates
4. **Backups**: Regular backups of configuration and data
5. **Updates**: Keep all containers and system packages updated

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for common issues and solutions.

## Service URLs

After deployment, access your services at:

- Traefik Dashboard: `https://traefik.yourdomain.com`
- Authentik: `https://auth.yourdomain.com`
- Portainer: `https://portainer.yourdomain.com`
- Nextcloud: `https://cloud.yourdomain.com`
- Media services: `https://plex.yourdomain.com`, etc.

## Support

For issues or questions:
1. Check the troubleshooting guide
2. Review service-specific README files
3. Check Docker logs: `docker logs <container_name>`
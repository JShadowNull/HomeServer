# HomeServer

A complete home server setup with containerized services, automated SSL, single sign-on, and comprehensive security configurations.

## 🏗️ Architecture Overview

This repository provides a production-ready home server stack with:

- **Reverse Proxy**: Traefik with automatic SSL certificates
- **Authentication**: Authentik SSO with LDAP support  
- **Media Stack**: Plex, Sonarr, Radarr, and download clients
- **Cloud Storage**: Nextcloud with LDAP integration
- **Management**: Portainer for container administration
- **Security**: SSH hardening, VPN access, and secure defaults

## 🚀 Quick Start

1. **Prerequisites**
   ```bash
   # Ubuntu/Debian system with sudo access
   # Domain name pointing to your server
   # Cloudflare account for SSL certificates
   ```

2. **System Setup**
   ```bash
   # Clone repository
   git clone <repository-url>
   cd HomeServer
   
   # Install Docker
   ./scripts/system/install-docker.sh
   
   # Secure SSH
   ./scripts/system/setup-secure-ssh.sh
   ```

3. **Deploy Services**
   ```bash
   # Create networks
   docker network create frontend
   docker network create backend
   
   # Deploy core stack
   cd services/traefik && docker compose up -d
   cd ../authentik && docker compose up -d
   cd ../portainer && docker compose up -d
   ```

📖 **[Full Setup Guide](docs/setup-guide.md)** | 🔧 **[Troubleshooting](docs/troubleshooting.md)**

## 📁 Repository Structure

```
HomeServer/
├── docs/                          # Documentation
│   ├── setup-guide.md            # Complete setup instructions
│   └── troubleshooting.md         # Common issues and solutions
├── services/                      # Docker Compose services
│   ├── traefik/                   # Reverse proxy & SSL
│   ├── authentik/                 # SSO authentication
│   ├── media-stack/               # Plex, Sonarr, Radarr
│   ├── nextcloud/                 # Cloud storage
│   └── portainer/                 # Container management
├── scripts/                       # Automation scripts
│   ├── system/                    # System setup & security
│   ├── user-management/           # User creation & permissions
│   └── network/                   # Network configuration
└── configs/                       # Configuration templates
```

## 🛠️ Available Scripts

### System Setup
- `install-docker.sh` - Install Docker on Ubuntu/Debian
- `setup-secure-ssh.sh` - Harden SSH and setup key authentication
- `setup-github-ssh.sh` - Generate SSH keys for GitHub
- `setup-wireguard.sh` - Install and configure WireGuard VPN

### User Management  
- `add-user.sh` - Create system users with optional sudo
- `add-docker-group.sh` - Add users to Docker group

### Network Tools
- `wireguard-remove.sh` - Remove WireGuard configuration

## 🔧 Services Included

| Service | Purpose | Access |
|---------|---------|--------|
| **Traefik** | Reverse proxy, SSL termination | `traefik.yourdomain.com` |
| **Authentik** | Single sign-on, LDAP provider | `auth.yourdomain.com` |
| **Portainer** | Docker container management | `portainer.yourdomain.com` |
| **Nextcloud** | File storage and collaboration | `cloud.yourdomain.com` |
| **Media Stack** | Plex, Sonarr, Radarr, etc. | `plex.yourdomain.com` |

## 🔒 Security Features

- **SSH Hardening**: Key-only authentication, disabled root login
- **SSL Everywhere**: Automatic certificate generation via Let's Encrypt
- **Single Sign-On**: Centralized authentication for all services
- **Network Segmentation**: Frontend/backend Docker networks
- **VPN Access**: WireGuard for secure remote access
- **Fail2ban**: Intrusion prevention (optional)

## 🎯 Key Features

- **Zero-downtime deploys** with Docker Compose
- **Automatic SSL certificates** via Traefik + Let's Encrypt
- **Single sign-on** across all services with Authentik
- **Monitoring and logging** with built-in dashboards
- **Backup ready** with volume configurations
- **Production tested** configurations

## 📋 Requirements

### Hardware
- 4GB+ RAM (8GB recommended)
- 50GB+ storage (more for media)
- x86_64 or ARM64 CPU

### Software
- Ubuntu 20.04+ or Debian 11+
- Domain name with DNS control
- Cloudflare account (for SSL)

### Network
- Port 80/443 forwarded to server
- Optional: Port 51820 for WireGuard

## 🚨 Important Notes

1. **Security First**: Always run the SSH hardening script before exposing your server
2. **Backup Strategy**: Configure regular backups of Docker volumes and configs  
3. **Domain Setup**: Ensure your domain DNS points to your server before deployment
4. **Resource Planning**: Monitor resource usage and scale as needed

## 🆘 Getting Help

1. **Check logs**: `docker logs <service_name>`
2. **Read docs**: Comprehensive guides in `/docs/`
3. **Review configs**: Service-specific README files
4. **Community support**: Issues and discussions on GitHub

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

## 📜 License

MIT License - see LICENSE file for details

---

**⚠️ Security Notice**: This configuration is designed for home lab use. For production environments, implement additional security measures including proper network segmentation, monitoring, and backup strategies.

**🔗 Quick Links**:
[Setup Guide](docs/setup-guide.md) • [Troubleshooting](docs/troubleshooting.md) • [Issues](../../issues) • [Discussions](../../discussions)
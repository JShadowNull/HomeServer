# Troubleshooting Guide

Common issues and their solutions for the HomeServer setup.

## Docker Issues

### Docker Installation Problems

**Error: Permission denied**
```bash
# Add user to docker group
./scripts/user-management/add-docker-group.sh
# Then logout and login again
```

**Error: Docker daemon not running**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Container Issues

**Container won't start**
```bash
# Check logs
docker logs <container_name>

# Check resource usage
docker stats

# Restart container
docker restart <container_name>
```

**Port conflicts**
```bash
# Check what's using the port
sudo netstat -tulpn | grep <port>
sudo lsof -i :<port>
```

## SSH Issues

### Cannot connect after hardening

**Locked out due to key issues**
```bash
# If you have physical access or another SSH session:
sudo systemctl stop ssh
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl start ssh
```

**Key permission issues**
```bash
# On client machine
chmod 600 ~/.ssh/id_ed25519
chmod 700 ~/.ssh

# On server
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

## Traefik Issues

### SSL Certificate Problems

**Certificates not generating**
1. Check Cloudflare API token permissions
2. Verify domain DNS points to your server
3. Check Traefik logs: `docker logs traefik`

**"Too many redirects" error**
- Check your Cloudflare SSL/TLS setting (should be "Full" or "Full (strict)")
- Verify Traefik middleware configuration

### Service Not Accessible

**502 Bad Gateway**
1. Check if backend service is running
2. Verify service is on correct Docker network
3. Check service health endpoints

**404 Not Found**
1. Verify router rules in labels
2. Check domain configuration
3. Ensure service labels are correct

## Authentik Issues

### Cannot Access Admin Interface

**Forgot admin credentials**
```bash
# Reset admin password
docker exec -it authentik-server ak create_admin_group
docker exec -it authentik-server ak change_password admin
```

### LDAP Connection Issues

**Services can't connect to Authentik LDAP**
1. Check network connectivity between containers
2. Verify LDAP provider configuration
3. Check firewall rules

## Network Issues

### Services Can't Communicate

**Container networking problems**
```bash
# Check Docker networks
docker network ls
docker network inspect frontend
docker network inspect backend

# Recreate networks if needed
docker network rm frontend backend
docker network create frontend
docker network create backend
```

### DNS Resolution Issues

**Can't resolve service names**
1. Ensure containers are on same Docker network
2. Use container names for internal communication
3. Check `/etc/hosts` for conflicts

## Storage Issues

### Permission Denied Errors

**Volume mount permission issues**
```bash
# Fix ownership
sudo chown -R 1000:1000 /path/to/data
sudo chmod -R 755 /path/to/data

# For specific services, check their user IDs
docker exec -it <container> id
```

### Disk Space Issues

**Out of space**
```bash
# Clean up Docker
docker system prune -a
docker volume prune

# Check disk usage
df -h
du -sh /var/lib/docker/
```

## Service-Specific Issues

### Media Stack

**Plex not finding media**
1. Check volume mounts in docker-compose.yml
2. Verify file permissions
3. Ensure media paths are accessible

**Download clients not working**
1. Check VPN configuration
2. Verify port mappings
3. Check download directory permissions

### Nextcloud

**Can't upload large files**
1. Check PHP upload limits in config
2. Verify reverse proxy timeout settings
3. Check available disk space

**Slow performance**
1. Enable Redis cache
2. Optimize database
3. Check resource allocation

## General Debugging

### Checking Logs

```bash
# Docker container logs
docker logs <container_name>
docker logs -f <container_name>  # Follow logs

# System logs
sudo journalctl -u docker
sudo journalctl -f  # Follow all logs

# Service-specific logs
docker exec -it <container> tail -f /var/log/service.log
```

### Resource Monitoring

```bash
# Container resource usage
docker stats

# System resources
htop
free -h
df -h

# Network connections
netstat -tulpn
ss -tulpn
```

### Network Testing

```bash
# Test connectivity between containers
docker exec -it <container1> ping <container2>
docker exec -it <container> nslookup <hostname>

# Test external connectivity
docker exec -it <container> curl -I https://google.com
```

## Recovery Procedures

### Complete Reset

If everything is broken and you need to start over:

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all networks (except defaults)
docker network rm frontend backend

# Remove all volumes (WARNING: This deletes all data!)
docker volume rm $(docker volume ls -q)

# Clean up everything
docker system prune -a --volumes
```

### Backup and Restore

**Create backup**
```bash
# Backup docker volumes
docker run --rm -v <volume_name>:/data -v $(pwd):/backup ubuntu tar czf /backup/backup.tar.gz -C /data .

# Backup configuration
tar czf config-backup.tar.gz services/ scripts/ docs/
```

**Restore backup**
```bash
# Restore volume
docker run --rm -v <volume_name>:/data -v $(pwd):/backup ubuntu tar xzf /backup/backup.tar.gz -C /data

# Restore configuration
tar xzf config-backup.tar.gz
```

## Getting Help

1. **Check logs first**: Most issues are revealed in the logs
2. **Search documentation**: Check service-specific documentation
3. **Community forums**: Docker, Traefik, and service-specific communities
4. **GitHub issues**: Check the repository issues page
5. **Discord/Reddit**: HomeServer and selfhosted communities

## Useful Commands Reference

```bash
# Docker management
docker ps -a                    # List all containers
docker images                   # List all images
docker volume ls                # List all volumes
docker network ls               # List all networks
docker system df                # Show Docker disk usage
docker system prune -a          # Clean up everything

# Container management
docker exec -it <container> bash     # Access container shell
docker inspect <container>           # Get container details
docker port <container>              # Show port mappings
docker restart <container>           # Restart container

# Service management
sudo systemctl status docker         # Check Docker service
sudo systemctl restart docker        # Restart Docker service
sudo systemctl enable docker         # Enable Docker at boot
```
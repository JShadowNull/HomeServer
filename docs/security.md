# Security Guidelines

Important security practices and configurations for the HomeServer setup.

## 🛡️ Security Overview

This repository includes multiple layers of security validation to prevent sensitive information from being committed and ensure secure deployment practices.

## 🔍 Automated Security Scanning

### Security Scan Script
Run comprehensive security checks:

```bash
# Full security scan
./scripts/system/security-scan.sh

# Specific scans
./scripts/system/security-scan.sh --patterns-only   # Just sensitive patterns
./scripts/system/security-scan.sh --docker-only     # Docker security only
./scripts/system/security-scan.sh --git-only        # Git history check
```

**What it detects:**
- Hardcoded passwords, API keys, tokens
- Private keys and certificates
- Insecure file permissions
- Environment files in repository
- Docker security issues
- Sensitive data in git history

### Pre-commit Hooks
Automatic validation before each commit:

```bash
# Install security hooks
./scripts/system/setup-git-hooks.sh
```

**Prevents commits with:**
- ❌ Sensitive information
- ❌ Hardcoded credentials  
- ❌ Insecure configurations
- ❌ Outdated documentation

## 🔐 Sensitive Data Management

### Environment Variables
**DO NOT** commit files containing:
- Real passwords, API keys, tokens
- Domain names, IP addresses
- Private keys or certificates

**DO** use template files:
- `.env.example` - Template for environment variables
- `*.example` - Template for any config file

### Example Setup Process

1. **Copy template files**:
   ```bash
   cp services/traefik/.env.example services/traefik/.env
   cp services/traefik/cf_api_token.txt.example services/traefik/cf_api_token.txt
   ```

2. **Edit with real values**:
   ```bash
   # Edit .env files with your actual configuration
   nano services/traefik/.env
   nano services/traefik/cf_api_token.txt
   ```

3. **Verify files are ignored**:
   ```bash
   git status  # Should not show .env files
   ```

## 📋 .gitignore Protection

The comprehensive `.gitignore` file protects against committing:

### Credentials & Keys
```
*.key, *.pem, *.crt          # Certificates and keys
*api_token*, *api_key*       # API credentials
.env, .env.*                 # Environment files
*secret*, *credential*       # Secret files
```

### Data & Logs
```
data/, volumes/, storage/    # Persistent data
logs/, *.log                 # Log files  
backup/, *.backup            # Backup files
```

### Service-specific
```
services/traefik/data/acme.json     # SSL certificates
services/authentik/media/           # User uploads
services/media-stack/downloads/     # Downloaded media
services/nextcloud/data/            # User files
```

## 🔧 Service Security Configuration

### Traefik Security
```yaml
# Use environment variables
environment:
  TRAEFIK_DASHBOARD_CREDENTIALS: ${TRAEFIK_DASHBOARD_CREDENTIALS}
  CF_DNS_API_TOKEN_FILE: /run/secrets/cf_api_token

# Secure middleware
labels:
  - "traefik.http.middlewares.trusted-whitelist.ipAllowList.sourcerange=10.0.0.0/24"
```

### Authentik Security  
```yaml
# Strong secret key (50+ characters)
AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}

# Secure database password
AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
```

### Docker Security
```yaml
# Avoid privileged containers
# privileged: true  ❌

# Use specific user IDs
user: "1000:1000"

# Limit container capabilities
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE
```

## 🚨 Security Incident Response

### If Secrets Are Committed

1. **Immediate action**:
   ```bash
   # Stop services using compromised credentials
   docker compose down
   
   # Rotate all affected credentials
   # - Change passwords
   # - Regenerate API keys
   # - Update certificates
   ```

2. **Clean git history**:
   ```bash
   # Remove sensitive data from git history
   git filter-branch --force --index-filter \
   'git rm --cached --ignore-unmatch path/to/sensitive/file' \
   --prune-empty --tag-name-filter cat -- --all
   
   # Force push (WARNING: Rewrites history)
   git push --force --all
   ```

3. **Update security**:
   ```bash
   # Run security scan
   ./scripts/system/security-scan.sh
   
   # Update .gitignore if needed
   # Reinstall git hooks
   ./scripts/system/setup-git-hooks.sh
   ```

### If Systems Are Compromised

1. **Isolate systems**:
   ```bash
   # Stop all services
   docker compose -f services/*/docker-compose.yml down
   
   # Check for unauthorized access
   docker logs <container_name>
   ```

2. **Investigate**:
   ```bash
   # Check system logs
   sudo journalctl -u ssh
   sudo journalctl -u docker
   
   # Check file integrity
   find /etc -name "*.conf" -mtime -1
   ```

3. **Recovery**:
   ```bash
   # Update all passwords and keys
   # Rebuild containers from clean images  
   # Restore from known-good backups
   ```

## ✅ Security Checklist

### Before Deployment
- [ ] Run security scan: `./scripts/system/security-scan.sh`
- [ ] Install git hooks: `./scripts/system/setup-git-hooks.sh`
- [ ] Copy and configure `.env.example` files
- [ ] Generate strong, unique passwords
- [ ] Configure firewall rules
- [ ] Enable fail2ban (optional)

### Regular Maintenance
- [ ] Rotate credentials monthly
- [ ] Update container images weekly
- [ ] Review access logs weekly
- [ ] Run security scan before major changes
- [ ] Backup configurations regularly

### Production Deployment
- [ ] Use Docker secrets instead of environment variables
- [ ] Enable container security scanning
- [ ] Set up monitoring and alerting
- [ ] Configure log aggregation
- [ ] Implement backup and disaster recovery

## 📚 Additional Resources

### Security Tools
- [git-secrets](https://github.com/awslabs/git-secrets) - Prevent secrets in git
- [truffleHog](https://github.com/trufflesecurity/truffleHog) - Find secrets in git history
- [Docker Bench](https://github.com/docker/docker-bench-security) - Docker security scanner

### Best Practices
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Security Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

### Emergency Contacts
- Document emergency contact procedures
- Keep offline backups of critical configurations
- Maintain disaster recovery runbooks

---

**Remember**: Security is an ongoing process, not a one-time setup. Regular reviews and updates are essential for maintaining a secure environment.
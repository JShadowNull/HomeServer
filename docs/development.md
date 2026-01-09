# Development Guide

Guidelines for maintaining and contributing to the HomeServer repository.

## README Consistency

This repository includes automated tools to keep the README.md synchronized with the actual file structure.

### Validation Script

The `validate-readme.sh` script ensures README accuracy:

```bash
# Validate README consistency
./scripts/system/validate-readme.sh --validate

# Update README with current structure  
./scripts/system/validate-readme.sh --update
```

**Features:**
- Scans actual directory structure
- Validates script references exist
- Auto-generates services table
- Updates file structure diagram

### Git Hooks

Install pre-commit hooks to prevent README inconsistencies:

```bash
# Setup automatic validation on commit
./scripts/system/setup-git-hooks.sh
```

The pre-commit hook will:
- ✅ Validate README before each commit
- ❌ Block commits if README is out of sync
- 💡 Show how to fix issues

### Manual Updates

When adding new services or scripts:

1. **Add the files normally**
2. **Run validation**: `./scripts/system/validate-readme.sh --update`
3. **Review changes** and commit
4. **Git hooks will prevent future drift**

## Directory Structure Rules

### Services (`/services/`)
```
services/
├── service-name/
│   ├── docker-compose.yml    # Required
│   ├── README.md            # Service documentation
│   ├── .env.example         # Environment template
│   └── data/                # Configuration files
```

### Scripts (`/scripts/`)
```
scripts/
├── system/           # OS setup, security, system config
├── user-management/  # User creation, permissions
└── network/         # Network configuration, VPN
```

**Script Guidelines:**
- Use kebab-case: `setup-service.sh`
- Include description comment at top
- Make executable: `chmod +x script.sh`
- Test before committing

### Documentation (`/docs/`)
```
docs/
├── setup-guide.md      # Complete setup instructions
├── troubleshooting.md  # Common issues and solutions  
└── development.md      # This file
```

## Contributing Workflow

### Adding New Services

1. **Create service directory**:
   ```bash
   mkdir -p services/my-service
   cd services/my-service
   ```

2. **Add required files**:
   ```bash
   # docker-compose.yml - service definition
   # README.md - service documentation
   # .env.example - environment template
   ```

3. **Update documentation**:
   ```bash
   ./scripts/system/validate-readme.sh --update
   ```

### Adding New Scripts

1. **Place in appropriate directory**:
   - System setup: `scripts/system/`
   - User management: `scripts/user-management/`
   - Network config: `scripts/network/`

2. **Follow naming convention**: `action-target.sh`

3. **Add description comment**:
   ```bash
   #!/bin/bash
   # Description: Brief description of what this script does
   ```

4. **Make executable and test**:
   ```bash
   chmod +x scripts/system/my-script.sh
   ./scripts/system/my-script.sh --help
   ```

5. **Update README**:
   ```bash
   ./scripts/system/validate-readme.sh --update
   ```

## Code Standards

### Shell Scripts
- Use `#!/bin/bash` shebang
- Add `set -euo pipefail` for safety
- Include help option (`--help`)
- Use consistent color coding
- Add input validation
- Test error conditions

### Docker Compose
- Use consistent service naming
- Include health checks
- Set restart policies
- Use external networks
- Document environment variables

### Documentation
- Keep README sections synchronized
- Update troubleshooting guide
- Include setup examples
- Document all environment variables

## Testing

### README Validation
```bash
# Test validation without changes
./scripts/system/validate-readme.sh --validate

# Test with updates
./scripts/system/validate-readme.sh --update
```

### Git Hook Testing
```bash
# Install hooks
./scripts/system/setup-git-hooks.sh

# Test hook behavior
git add .
git commit -m "Test commit"  # Should validate README
```

### Script Testing
```bash
# Test all scripts have execute permissions
find scripts/ -name "*.sh" -type f ! -executable

# Test scripts have proper shebangs
grep -L "#!/bin/bash" scripts/**/*.sh

# Test scripts follow safety practices
grep -L "set -euo pipefail" scripts/**/*.sh
```

## Automation

### Pre-commit Validation
The repository includes automatic README validation:

- **On every commit**: Validates README consistency
- **Blocks bad commits**: Prevents documentation drift
- **Shows fix commands**: Guides to resolution

### CI/CD Integration
For advanced setups, add to GitHub Actions:

```yaml
name: Validate Documentation
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate README
        run: ./scripts/system/validate-readme.sh --validate
```

## Maintenance

### Regular Tasks
1. **Update README**: Run validation monthly
2. **Review scripts**: Check for outdated references
3. **Test services**: Verify docker-compose files work
4. **Update docs**: Keep troubleshooting guide current

### Version Management
- Tag releases: `git tag v1.0.0`
- Document changes: Update README with new features
- Test compatibility: Verify scripts work on target systems

## Troubleshooting Development

### README Issues
```bash
# README validation fails
./scripts/system/validate-readme.sh --validate
# Follow suggested fix commands

# Manual structure check
tree -a -I '.git|.DS_Store' --dirsfirst
```

### Git Hook Issues
```bash
# Hook not working
ls -la .git/hooks/pre-commit
cat .git/hooks/pre-commit

# Disable temporarily  
git commit --no-verify -m "Skip validation"

# Reinstall hooks
./scripts/system/setup-git-hooks.sh
```

### Script Issues
```bash
# Permission denied
chmod +x scripts/system/script-name.sh

# Path issues
which script-name.sh
echo $PATH
```

This workflow ensures the repository documentation stays accurate and useful for all users.
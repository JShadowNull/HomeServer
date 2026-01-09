#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo -e "${BLUE}Security Scan for Sensitive Information${NC}"
echo "======================================="

# Track security issues
SECURITY_ISSUES=0

# Function to log security issue
log_issue() {
    local severity="$1"
    local message="$2"
    local file="$3"
    local line="$4"
    
    echo -e "${RED}[$severity] $message${NC}"
    echo "  File: $file:$line"
    echo ""
    ((SECURITY_ISSUES++))
}

# Function to log warning
log_warning() {
    local message="$1"
    local file="$2"
    local line="$3"
    
    echo -e "${YELLOW}[WARNING] $message${NC}"
    echo "  File: $file:$line"
    echo ""
}

# Function to scan for sensitive patterns
scan_sensitive_patterns() {
    echo -e "${YELLOW}Scanning for sensitive information patterns...${NC}"
    
    # Define sensitive patterns
    local patterns=(
        "password\s*[:=]\s*['\"][^'\"]{3,}['\"]"
        "secret\s*[:=]\s*['\"][^'\"]{3,}['\"]"
        "token\s*[:=]\s*['\"][^'\"]{8,}['\"]"
        "api[_-]?key\s*[:=]\s*['\"][^'\"]{8,}['\"]"
        "private[_-]?key\s*[:=]"
        "-----BEGIN\s+(PRIVATE\s+KEY|RSA\s+PRIVATE\s+KEY|DSA\s+PRIVATE\s+KEY|EC\s+PRIVATE\s+KEY)"
        "[A-Za-z0-9+/]{40,}={0,2}"  # Base64 encoded secrets (40+ chars)
        "[0-9a-fA-F]{32,64}"        # Hex encoded secrets
        "pk_[a-zA-Z0-9]{24,}"       # Stripe private keys
        "sk_[a-zA-Z0-9]{24,}"       # Stripe secret keys
        "AKIA[0-9A-Z]{16}"          # AWS Access Key ID
        "ghp_[a-zA-Z0-9]{36}"       # GitHub Personal Access Token
        "glpat-[a-zA-Z0-9-_]{20}"   # GitLab Personal Access Token
    )
    
    # Scan files
    cd "$REPO_ROOT"
    
    for pattern in "${patterns[@]}"; do
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                local file=$(echo "$line" | cut -d: -f1)
                local line_num=$(echo "$line" | cut -d: -f2)
                local content=$(echo "$line" | cut -d: -f3-)
                
                # Skip template/example files
                if [[ "$file" =~ \.(example|template|sample)$ ]] || [[ "$content" =~ (REPLACE_|CHANGE_|YOUR_|example_|template_|sample_) ]]; then
                    continue
                fi
                
                log_issue "CRITICAL" "Potential sensitive data found" "$file" "$line_num"
                echo "    Content: $content"
                echo ""
            fi
        done < <(grep -rn -i -E "$pattern" . --exclude-dir=".git" --exclude="*.log" 2>/dev/null || true)
    done
}

# Function to scan for hardcoded IPs and URLs
scan_hardcoded_values() {
    echo -e "${YELLOW}Scanning for hardcoded values...${NC}"
    
    cd "$REPO_ROOT"
    
    # Scan for private IP addresses (excluding examples and comments)
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local file=$(echo "$line" | cut -d: -f1)
            local line_num=$(echo "$line" | cut -d: -f2)
            local content=$(echo "$line" | cut -d: -f3-)
            
            # Skip comments and examples
            if [[ "$content" =~ ^[[:space:]]*# ]] || [[ "$content" =~ (example|template|CHANGE) ]]; then
                continue
            fi
            
            log_warning "Hardcoded private IP address" "$file" "$line_num"
            echo "    Content: $content"
            echo ""
        fi
    done < <(grep -rn -E "([0-9]{1,3}\.){3}[0-9]{1,3}" . --exclude-dir=".git" --exclude="*.md" --exclude="*.log" 2>/dev/null | grep -E "(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.)" || true)
    
    # Scan for real domain names (not examples)
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local file=$(echo "$line" | cut -d: -f1)
            local line_num=$(echo "$line" | cut -d: -f2)
            local content=$(echo "$line" | cut -d: -f3-)
            
            # Skip example domains and comments
            if [[ "$content" =~ (example\.com|example\.org|localhost|yourdomain\.com) ]] || [[ "$content" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            
            # Check for real domains
            if [[ "$content" =~ [a-zA-Z0-9-]+\.[a-zA-Z]{2,} ]]; then
                log_warning "Potential real domain name" "$file" "$line_num"
                echo "    Content: $content"
                echo ""
            fi
        fi
    done < <(grep -rn -E "[a-zA-Z0-9-]+\.[a-zA-Z]{2,}" . --exclude-dir=".git" --exclude="*.md" --exclude="*.log" 2>/dev/null || true)
}

# Function to check for insecure file permissions
check_file_permissions() {
    echo -e "${YELLOW}Checking file permissions...${NC}"
    
    cd "$REPO_ROOT"
    
    # Check for files with overly permissive permissions
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null)
            if [[ "$perms" =~ (777|666|755) ]] && [[ "$file" =~ \.(key|pem|crt|token|secret)$ ]]; then
                log_issue "HIGH" "Insecure permissions on sensitive file" "$file" "permissions: $perms"
            fi
        fi
    done < <(find . -type f \( -name "*.key" -o -name "*.pem" -o -name "*.crt" -o -name "*token*" -o -name "*secret*" \) 2>/dev/null || true)
    
    # Check for world-writable files
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            log_issue "HIGH" "World-writable file found" "$file" ""
        fi
    done < <(find . -type f -perm -002 2>/dev/null || true)
}

# Function to check environment files and system artifacts
check_environment_files() {
    echo -e "${YELLOW}Checking environment files and system artifacts...${NC}"
    
    cd "$REPO_ROOT"
    
    # Check for .env files that shouldn't be committed
    while IFS= read -r file; do
        if [[ -f "$file" ]] && [[ ! "$file" =~ \.(example|template|sample)$ ]]; then
            log_issue "CRITICAL" "Environment file should not be committed" "$file" ""
            
            # Check if .gitignore excludes it
            if git check-ignore "$file" >/dev/null 2>&1; then
                echo "    Note: File is properly ignored by .gitignore"
            else
                echo "    Action: Add '$file' to .gitignore"
            fi
            echo ""
        fi
    done < <(find . -name ".env*" -type f 2>/dev/null || true)
    
    # Check for OS artifacts that shouldn't be committed
    local os_artifacts=(
        ".DS_Store"
        ".DS_Store?"
        "._*"
        "Thumbs.db"
        "desktop.ini"
        "ehthumbs.db"
        ".Spotlight-V100"
        ".Trashes"
    )
    
    for artifact in "${os_artifacts[@]}"; do
        while IFS= read -r file; do
            if [[ -f "$file" ]]; then
                log_issue "MEDIUM" "OS artifact file should not be committed" "$file" ""
                echo "    Action: Remove with 'git rm \"$file\"' and ensure .gitignore covers it"
                echo ""
            fi
        done < <(find . -name "$artifact" -type f 2>/dev/null || true)
    done
}

# Function to check for secrets in git history
check_git_history() {
    echo -e "${YELLOW}Checking git history for secrets (last 10 commits)...${NC}"
    
    cd "$REPO_ROOT"
    
    if [[ -d ".git" ]]; then
        # Check recent commits for sensitive patterns
        local commits=$(git log --oneline -10 --pretty=format:"%h" 2>/dev/null || echo "")
        
        for commit in $commits; do
            # Check commit diff for sensitive patterns
            local diff_output=$(git show "$commit" 2>/dev/null || true)
            
            if echo "$diff_output" | grep -q -E "(password|secret|token|api[_-]?key)" -i; then
                log_warning "Potential sensitive data in commit" "git:$commit" ""
                echo "    Run: git show $commit | grep -i -E '(password|secret|token|key)'"
                echo ""
            fi
        done
    else
        echo "    Not a git repository - skipping git history check"
    fi
}

# Function to check Docker Compose security
check_docker_security() {
    echo -e "${YELLOW}Checking Docker Compose security...${NC}"
    
    cd "$REPO_ROOT"
    
    # Check for privileged containers
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local file=$(echo "$line" | cut -d: -f1)
            local line_num=$(echo "$line" | cut -d: -f2)
            
            log_warning "Privileged container found" "$file" "$line_num"
            echo ""
        fi
    done < <(grep -rn "privileged:\s*true" . --include="*.yml" --include="*.yaml" 2>/dev/null || true)
    
    # Check for host network mode
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local file=$(echo "$line" | cut -d: -f1)
            local line_num=$(echo "$line" | cut -d: -f2)
            
            log_warning "Host network mode found" "$file" "$line_num"
            echo ""
        fi
    done < <(grep -rn "network_mode:\s*host" . --include="*.yml" --include="*.yaml" 2>/dev/null || true)
}

# Function to provide security recommendations
show_recommendations() {
    echo -e "${BLUE}Security Recommendations:${NC}"
    echo "========================="
    
    echo "1. Use environment variables for sensitive data:"
    echo "   - Create .env files (add to .gitignore)"
    echo "   - Use Docker secrets for production"
    echo ""
    
    echo "2. Secure file permissions:"
    echo "   - Private keys: chmod 600"
    echo "   - Config files: chmod 644"
    echo "   - Scripts: chmod 755"
    echo ""
    
    echo "3. Git security:"
    echo "   - Use git-secrets or similar tools"
    echo "   - Set up pre-commit hooks"
    echo "   - Review commits before pushing"
    echo ""
    
    echo "4. Docker security:"
    echo "   - Avoid privileged containers"
    echo "   - Use non-root users"
    echo "   - Limit container capabilities"
    echo ""
    
    echo "5. Regular security practices:"
    echo "   - Rotate secrets regularly"
    echo "   - Use strong, unique passwords"
    echo "   - Enable 2FA where possible"
    echo "   - Monitor for unauthorized access"
}

# Main execution
main() {
    local scan_all=true
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --patterns-only)
                scan_sensitive_patterns
                exit 0
                ;;
            --permissions-only)
                check_file_permissions
                exit 0
                ;;
            --docker-only)
                check_docker_security
                exit 0
                ;;
            --git-only)
                check_git_history
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --patterns-only     Only scan for sensitive patterns"
                echo "  --permissions-only  Only check file permissions"
                echo "  --docker-only      Only check Docker security"
                echo "  --git-only         Only check git history"
                echo "  -v, --verbose      Show detailed output"
                echo "  -h, --help         Show this help"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Run all scans
    scan_sensitive_patterns
    scan_hardcoded_values
    check_file_permissions
    check_environment_files
    check_git_history
    check_docker_security
    
    echo -e "\n${BLUE}Security Scan Results:${NC}"
    echo "======================"
    
    if [[ $SECURITY_ISSUES -eq 0 ]]; then
        echo -e "${GREEN}✓ No critical security issues found${NC}"
    else
        echo -e "${RED}✗ Found $SECURITY_ISSUES security issue(s)${NC}"
        echo -e "${YELLOW}Review and fix the issues listed above${NC}"
    fi
    
    echo ""
    show_recommendations
    
    # Return non-zero if issues found
    if [[ $SECURITY_ISSUES -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
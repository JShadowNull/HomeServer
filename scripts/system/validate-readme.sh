#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
README_FILE="$REPO_ROOT/README.md"
TEMP_README="/tmp/readme_updated.md"

echo -e "${BLUE}README Validation and Update Script${NC}"
echo "===================================="

# Function to generate current directory structure
generate_structure() {
    echo "HomeServer/"
    cd "$REPO_ROOT"
    
    # Generate tree structure, excluding hidden files and common temp files
    tree -a -I '.git|.DS_Store|node_modules|*.tmp|*.log' --dirsfirst --charset ascii | tail -n +2 | head -n -2 || {
        # Fallback if tree is not available
        find . -type d -name ".git" -prune -o -type f -print | sort | sed 's|^\./||' | awk '
        BEGIN { FS="/" }
        {
            for(i=1; i<NF; i++) {
                for(j=0; j<i-1; j++) printf "│   "
                if(i==NF-1) printf "├── "
                else printf ""
            }
            print $NF
        }'
    }
}

# Function to scan for available scripts
scan_scripts() {
    echo -e "${YELLOW}Scanning for scripts...${NC}"
    
    # System scripts
    echo "### System Setup"
    find "$REPO_ROOT/scripts/system" -name "*.sh" -type f | sort | while read -r script; do
        name=$(basename "$script" .sh)
        # Get description from script comments
        desc=$(head -20 "$script" | grep -E "^#.*[Dd]escription|^# " | head -1 | sed 's/^#[[:space:]]*//' || echo "System utility script")
        echo "- \`$name.sh\` - $desc"
    done
    
    echo ""
    echo "### User Management"
    find "$REPO_ROOT/scripts/user-management" -name "*.sh" -type f | sort | while read -r script; do
        name=$(basename "$script" .sh)
        desc=$(head -20 "$script" | grep -E "^#.*[Dd]escription|^# " | head -1 | sed 's/^#[[:space:]]*//' || echo "User management script")
        echo "- \`$name.sh\` - $desc"
    done
    
    echo ""
    echo "### Network Tools"
    find "$REPO_ROOT/scripts/network" -name "*.sh" -type f | sort | while read -r script; do
        name=$(basename "$script" .sh)
        desc=$(head -20 "$script" | grep -E "^#.*[Dd]escription|^# " | head -1 | sed 's/^#[[:space:]]*//' || echo "Network configuration script")
        echo "- \`$name.sh\` - $desc"
    done
}

# Function to scan for services
scan_services() {
    echo -e "${YELLOW}Scanning for services...${NC}"
    
    echo "| Service | Purpose | Access |"
    echo "|---------|---------|--------|"
    
    find "$REPO_ROOT/services" -maxdepth 1 -type d ! -path "$REPO_ROOT/services" | sort | while read -r service_dir; do
        service_name=$(basename "$service_dir")
        
        # Try to get description from README or docker-compose.yml
        purpose="Container service"
        if [[ -f "$service_dir/README.md" ]]; then
            purpose=$(head -10 "$service_dir/README.md" | grep -E "^[A-Z].*[a-z]" | head -1 | cut -c1-50 || echo "Container service")
        fi
        
        # Format service name
        formatted_name=$(echo "$service_name" | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
        
        echo "| **$formatted_name** | $purpose | \`$service_name.yourdomain.com\` |"
    done
}

# Function to validate README structure
validate_readme() {
    echo -e "${YELLOW}Validating README structure...${NC}"
    
    local errors=0
    
    # Check if main sections exist
    if ! grep -q "## 📁 Repository Structure" "$README_FILE"; then
        echo -e "${RED}✗ Missing 'Repository Structure' section${NC}"
        ((errors++))
    fi
    
    if ! grep -q "## 🛠️ Available Scripts" "$README_FILE"; then
        echo -e "${RED}✗ Missing 'Available Scripts' section${NC}"
        ((errors++))
    fi
    
    if ! grep -q "## 🔧 Services Included" "$README_FILE"; then
        echo -e "${RED}✗ Missing 'Services Included' section${NC}"
        ((errors++))
    fi
    
    # Check for outdated script references
    while IFS= read -r line; do
        if [[ "$line" =~ \`([^`]+\.sh)\` ]]; then
            script_name="${BASH_REMATCH[1]}"
            if ! find "$REPO_ROOT/scripts" -name "$script_name" -type f | grep -q .; then
                echo -e "${RED}✗ Script reference not found: $script_name${NC}"
                ((errors++))
            fi
        fi
    done < "$README_FILE"
    
    return $errors
}

# Function to update README sections
update_readme() {
    echo -e "${YELLOW}Updating README with current structure...${NC}"
    
    cp "$README_FILE" "$TEMP_README"
    
    # Generate new structure
    local new_structure
    new_structure=$(generate_structure | sed 's/^/    /')
    
    # Generate new scripts section
    local new_scripts
    new_scripts=$(scan_scripts)
    
    # Generate new services table
    local new_services
    new_services=$(scan_services)
    
    # Update structure section
    awk -v new_struct="$new_structure" '
    /^## 📁 Repository Structure$/ { 
        print; print ""; print "```"; print new_struct; print "```"; 
        # Skip until next section
        while ((getline) && !/^## /) continue
        if (!/^$/) print
        next
    }
    1' "$TEMP_README" > "$TEMP_README.tmp" && mv "$TEMP_README.tmp" "$TEMP_README"
    
    # Update scripts section
    awk -v new_scripts="$new_scripts" '
    /^## 🛠️ Available Scripts$/ { 
        print; print ""; print new_scripts; 
        # Skip until next section
        while ((getline) && !/^## /) continue
        if (!/^$/) print
        next
    }
    1' "$TEMP_README" > "$TEMP_README.tmp" && mv "$TEMP_README.tmp" "$TEMP_README"
    
    # Update services section
    awk -v new_services="$new_services" '
    /^## 🔧 Services Included$/ { 
        print; print ""; print new_services; 
        # Skip until next section
        while ((getline) && !/^## /) continue
        if (!/^$/) print
        next
    }
    1' "$TEMP_README" > "$TEMP_README.tmp" && mv "$TEMP_README.tmp" "$TEMP_README"
    
    echo -e "${GREEN}✓ README updated successfully${NC}"
}

# Function to show differences
show_diff() {
    echo -e "${BLUE}Changes to be applied:${NC}"
    if command -v diff >/dev/null 2>&1; then
        diff -u "$README_FILE" "$TEMP_README" || true
    else
        echo "Diff tool not available. Updated file ready at: $TEMP_README"
    fi
}

# Main execution
main() {
    local update_mode=false
    local validate_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--update)
                update_mode=true
                shift
                ;;
            -v|--validate)
                validate_only=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -u, --update     Update README with current structure"
                echo "  -v, --validate   Only validate README (no updates)"
                echo "  -h, --help       Show this help"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Validate first
    if validate_readme; then
        echo -e "${GREEN}✓ README structure validation passed${NC}"
    else
        echo -e "${RED}✗ README validation failed${NC}"
        if [[ "$validate_only" == true ]]; then
            exit 1
        fi
        echo -e "${YELLOW}Will update README to fix issues...${NC}"
        update_mode=true
    fi
    
    if [[ "$validate_only" == true ]]; then
        echo -e "${GREEN}Validation complete.${NC}"
        exit 0
    fi
    
    if [[ "$update_mode" == true ]]; then
        update_readme
        show_diff
        
        read -p "Apply these changes to README.md? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv "$TEMP_README" "$README_FILE"
            echo -e "${GREEN}✓ README.md updated successfully${NC}"
        else
            rm -f "$TEMP_README"
            echo -e "${YELLOW}Changes discarded${NC}"
        fi
    else
        echo -e "${GREEN}README is up to date${NC}"
    fi
    
    # Cleanup
    rm -f "$TEMP_README" "$TEMP_README.tmp"
}

# Check dependencies
if ! command -v tree >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: 'tree' command not found. Using fallback directory listing.${NC}"
    echo "Install tree with: sudo apt install tree"
fi

main "$@"
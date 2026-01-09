#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Setting up global .gitignore for system artifacts${NC}"
echo "=================================================="

# Create global gitignore file
GLOBAL_GITIGNORE="$HOME/.gitignore_global"

echo -e "${YELLOW}Creating global .gitignore at: $GLOBAL_GITIGNORE${NC}"

cat > "$GLOBAL_GITIGNORE" << 'EOF'
# Global .gitignore for system artifacts
# This prevents OS-specific files from being committed in any repository

## macOS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
.AppleDouble
.LSOverride
.com.apple.timemachine.donotpresent
.DocumentRevisions-V100
.fseventsd
.TemporaryItems
.VolumeIcon.icns
.AppleDB
.AppleDesktop
Network Trash Folder

## Windows  
Thumbs.db
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/
*.cab
*.msi
*.msm
*.msp
*.lnk

## Linux
*~
.fuse_hidden*
.directory
.Trash-*
.nfs*

## IDEs and Editors
.vscode/
.idea/
*.swp
*.swo
*~
.emacs.d/
.vim/
*.sublime-project
*.sublime-workspace

## Temporary files
*.tmp
*.temp
*.log
*.bak
*.old
*.orig
.cache/
EOF

# Configure git to use the global gitignore
echo -e "${YELLOW}Configuring git to use global .gitignore...${NC}"
git config --global core.excludesfile "$GLOBAL_GITIGNORE"

echo -e "${GREEN}✓ Global .gitignore setup complete!${NC}"
echo -e "${YELLOW}This will prevent system artifacts from being committed in any repository.${NC}"

# Show current configuration
echo -e "\n${YELLOW}Current git global configuration:${NC}"
echo "Global .gitignore: $(git config --global core.excludesfile)"

echo -e "\n${GREEN}System artifacts like .DS_Store will now be ignored globally.${NC}"
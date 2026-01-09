#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo -e "${GREEN}Setting up Git hooks for README validation${NC}"
echo "=============================================="

# Check if we're in a git repository
if [[ ! -d "$REPO_ROOT/.git" ]]; then
    echo -e "${RED}Error: Not in a Git repository${NC}"
    exit 1
fi

# Install pre-commit hook
HOOKS_DIR="$REPO_ROOT/.git/hooks"
SOURCE_HOOK="$REPO_ROOT/.githooks/pre-commit"
TARGET_HOOK="$HOOKS_DIR/pre-commit"

if [[ -f "$TARGET_HOOK" ]]; then
    echo -e "${YELLOW}Existing pre-commit hook found. Backing up...${NC}"
    cp "$TARGET_HOOK" "$TARGET_HOOK.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Copy and make executable
cp "$SOURCE_HOOK" "$TARGET_HOOK"
chmod +x "$TARGET_HOOK"

echo -e "${GREEN}✓ Pre-commit hook installed${NC}"
echo -e "${YELLOW}The hook will validate README consistency before each commit${NC}"

# Test the hook
echo -e "\n${YELLOW}Testing README validation...${NC}"
if "$REPO_ROOT/scripts/system/validate-readme.sh" --validate; then
    echo -e "${GREEN}✓ README validation test passed${NC}"
else
    echo -e "${YELLOW}README needs updating. Run:${NC}"
    echo "./scripts/system/validate-readme.sh --update"
fi

echo -e "\n${GREEN}Git hooks setup complete!${NC}"
echo -e "${YELLOW}To disable hooks temporarily: git commit --no-verify${NC}"
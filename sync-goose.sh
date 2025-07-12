#!/bin/bash

# Sync Goose configuration from ~/.config/goose to dotfiles
# This script updates your dotfiles with the current Goose configuration

DOTFILES_DIR="$HOME/dotfiles"
GOOSE_CONFIG_DIR="$HOME/.config/goose"
DOTFILES_GOOSE_DIR="$DOTFILES_DIR/config/goose"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Syncing Goose configuration from ~/.config/goose to dotfiles...${NC}"

# Check if source directory exists
if [ ! -d "$GOOSE_CONFIG_DIR" ]; then
    echo -e "${RED}Error: $GOOSE_CONFIG_DIR does not exist${NC}"
    exit 1
fi

# Remove existing dotfiles goose directory and copy fresh
echo -e "Removing old configuration..."
rm -rf "$DOTFILES_GOOSE_DIR"

echo -e "Copying current configuration..."
cp -r "$GOOSE_CONFIG_DIR" "$DOTFILES_GOOSE_DIR"

# Restore .gitignore (it gets overwritten by the copy)
cat > "$DOTFILES_GOOSE_DIR/.gitignore" << 'EOF'
# Goose files to ignore in version control

# History and temporary files
history.txt
*.bak
*.bak.*

# Memory directory (user-specific data)
memory/

# Log files
*.log

# Any other temporary or user-specific files
.DS_Store
*~
*.swp
*.swo
EOF

echo -e "${GREEN}Sync complete!${NC}"
echo -e "${YELLOW}Don't forget to commit the changes to your dotfiles repository.${NC}"

# Show what changed
echo -e "\n${YELLOW}Changed files:${NC}"
cd "$DOTFILES_DIR"
git status --porcelain | grep -E "config/goose/" || echo "No changes detected"

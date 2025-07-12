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

# Create dotfiles goose directory if it doesn't exist
mkdir -p "$DOTFILES_GOOSE_DIR"

# Files to sync (excluding sensitive/temporary files)
FILES_TO_SYNC=(
    "config.yaml"
    "permission.yaml"
)

# Sync each file
for file in "${FILES_TO_SYNC[@]}"; do
    if [ -f "$GOOSE_CONFIG_DIR/$file" ]; then
        echo -e "Syncing ${GREEN}$file${NC}..."
        cp "$GOOSE_CONFIG_DIR/$file" "$DOTFILES_GOOSE_DIR/$file"
        echo -e "  ✓ Updated $DOTFILES_GOOSE_DIR/$file"
    else
        echo -e "${YELLOW}Warning: $GOOSE_CONFIG_DIR/$file not found, skipping...${NC}"
    fi
done

echo -e "${GREEN}Sync complete!${NC}"
echo -e "${YELLOW}Don't forget to commit the changes to your dotfiles repository.${NC}"

# Show what changed
echo -e "\n${YELLOW}Changed files:${NC}"
cd "$DOTFILES_DIR"
git status --porcelain | grep -E "config/goose/" || echo "No changes detected"

#!/bin/bash

# Pi coding agent configuration sync script
# Run from config/pi/ directory to symlink dotfiles into ~/.pi/agent/
#
# Usage: ./sync.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PI_AGENT_DIR="$HOME/.pi/agent"

echo "⚡ Syncing Pi coding agent configuration..."
echo ""

# Ensure ~/.pi/agent exists
mkdir -p "$PI_AGENT_DIR"

# ── Config files ──────────────────────────────────────────────

sync_file() {
    local name="$1"
    local src="$SCRIPT_DIR/$name"
    local dest="$PI_AGENT_DIR/$name"
    if [ -f "$src" ]; then
        echo "   • $name"
        ln -sf "$src" "$dest"
    elif [ -L "$dest" ]; then
        echo "   • $name (removed — no longer in dotfiles)"
        rm -f "$dest"
    fi
}

sync_file "settings.json"
sync_file "keybindings.json"
sync_file "AGENTS.md"
sync_file "SYSTEM.md"
sync_file "APPEND_SYSTEM.md"

# ── Pi root config (~/.pi/, not ~/.pi/agent/) ─────────────────

PI_DIR="$HOME/.pi"
mkdir -p "$PI_DIR"

if [ -f "$SCRIPT_DIR/tool-guard.yaml" ]; then
    echo "   • tool-guard.yaml → ~/.pi/tool-guard.yaml"
    ln -sf "$SCRIPT_DIR/tool-guard.yaml" "$PI_DIR/tool-guard.yaml"
fi

# ── Resource directories ──────────────────────────────────────

sync_dir() {
    local name="$1"
    local src="$SCRIPT_DIR/$name"
    local dest="$PI_AGENT_DIR/$name"
    if [ -d "$src" ]; then
        echo "   • $name/"
        ln -sfn "$src" "$dest"
    elif [ -L "$dest" ]; then
        echo "   • $name/ (removed — no longer in dotfiles)"
        rm -f "$dest"
    fi
}

sync_dir "prompts"
sync_dir "skills"
sync_dir "themes"
sync_dir "extensions"
sync_dir "agents"

echo ""
echo "✅ Pi configuration sync complete!"
echo ""
echo "📝 Summary:"
echo "   • Config files symlinked: $(ls "$SCRIPT_DIR"/*.json "$SCRIPT_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo "   • Resource dirs symlinked: prompts, skills, themes, extensions"
echo ""
echo "💡 Run /reload in pi to apply changes without restarting."

#!/bin/zsh
# search-cache.sh — Fast lookup in ~/Code/dk-digital-bank/dk.yaml
# Usage: search-cache.sh <query>
# Outputs matching workspace or discovered entries.

CACHE="$HOME/Code/dk-digital-bank/dk.yaml"
QUERY="$1"

if [[ ! -f "$CACHE" ]]; then
    print -r "Cache not found: $CACHE" >&2
    exit 1
fi

if [[ -z "$QUERY" ]]; then
    # List all workspaces
    yq e '.workspaces | to_entries | .[] | "\(.key) | \(.value.description) | session: \(.value.session_name)"' "$CACHE"
else
    # Search workspaces
    yq e '.workspaces | to_entries | .[] | "\(.key) | \(.value.description) | session: \(.value.session_name)"' "$CACHE" \
        | grep -i "$QUERY" 2>/dev/null || true

    # Search discovered repos
    yq e '.discovered | to_entries | .[] | "DISCOVERED/\(.key) | \(.value)"' "$CACHE" 2>/dev/null \
        | grep -i "$QUERY" 2>/dev/null || true
fi

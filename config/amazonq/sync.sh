#!/bin/bash

# Amazon Q Configuration Sync Script
# This script sets up Amazon Q CLI configurations

set -e

echo "🔧 Setting up Amazon Q configuration..."

# Check if q CLI is installed
if ! command -v q &> /dev/null; then
    echo "⚠️  WARNING: Amazon Q CLI is not installed"
    echo "   Please install Q CLI first"
    exit 1
fi

echo "✅ Dependencies check passed"

# Create ~/.aws/amazonq directory if it doesn't exist
mkdir -p ~/.aws/amazonq

# Setup MCP configuration
echo "📝 Linking MCP configuration..."
ln -sfn ~/dotfiles/config/amazonq/mcp.json ~/.aws/amazonq/mcp.json
echo "   ~/.aws/amazonq/mcp.json -> ~/dotfiles/config/amazonq/mcp.json"

echo ""
echo "🎉 Amazon Q setup complete!"
echo ""
echo "MCP servers configured:"
if command -v jq &> /dev/null; then
    jq -r '.mcpServers | keys[]' ~/dotfiles/config/amazonq/mcp.json | sed 's/^/   - /'
else
    echo "   - Install jq to see configured MCP servers"
fi
echo ""
echo "Usage:"
echo "   q chat  # Start Q CLI with MCP servers"

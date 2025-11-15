#!/bin/bash
# Install Claude Code Plugins
# Creates symlinks to official Anthropic plugins

set -euo pipefail

echo "🔌 Installing Claude Code plugins..."

# Plugin directory
PLUGIN_DIR=".claude/plugins"
mkdir -p "$PLUGIN_DIR"

# Check if plugins available in Claude cache
CACHE_DIR="$HOME/.claude/plugins/cache"

# code-review plugin
if [ -d "$CACHE_DIR/code-review" ]; then
  ln -sf "$CACHE_DIR/code-review" "$PLUGIN_DIR/code-review"
  echo "✅ Installed: code-review plugin"
else
  echo "⚠️  WARNING: code-review plugin not found in cache"
  echo "   Install via Claude Code marketplace first"
fi

# feature-dev plugin
if [ -d "$CACHE_DIR/feature-dev" ]; then
  ln -sf "$CACHE_DIR/feature-dev" "$PLUGIN_DIR/feature-dev"
  echo "✅ Installed: feature-dev plugin"
else
  echo "⚠️  WARNING: feature-dev plugin not found in cache"
  echo "   Install via Claude Code marketplace first"
fi

# research-agent (from claude-agent-sdk-demos)
# Note: This is a demo, not a plugin, but useful for reference
if [ -d "$CACHE_DIR/research-agent" ]; then
  ln -sf "$CACHE_DIR/research-agent" "$PLUGIN_DIR/research-agent"
  echo "✅ Installed: research-agent demo"
else
  echo "ℹ️  INFO: research-agent demo not found (optional)"
fi

echo "✅ Plugin installation complete"
echo ""
echo "Verify plugins:"
echo "  ls -la .claude/plugins/"

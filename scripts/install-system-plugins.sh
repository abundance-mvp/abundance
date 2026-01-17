#!/bin/bash
# Install Claude Code MCP servers (gcloud, storage, observability, firebase)
# Plugins (axiom, superpowers) are installed via marketplace - NOT this script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_header() { echo -e "\n${YELLOW}=== $1 ===${NC}"; }

# Claude Code reads from ~/.claude/ - NOT ~/.config/claude/
CLAUDE_DIR="$HOME/.claude"
MCP_DIR="$HOME/.config/claude/mcp"  # MCP source code lives here

print_header "Claude Code MCP Server Installation"
echo "Installing MCP servers: gcloud, storage, observability, firebase"
echo ""
echo "NOTE: Plugins (axiom, superpowers) should be installed via marketplace:"
echo "  - Use /plugin install axiom@axiom-marketplace"
echo "  - Use /plugin install superpowers@superpowers-marketplace"
echo ""

# Create directories
print_info "Creating directories..."
mkdir -p "$MCP_DIR"

# Install/Update gcloud MCP (monorepo with multiple packages)
print_header "Installing Google Cloud MCP"
if [ -d "$MCP_DIR/gcloud" ]; then
    print_info "Updating existing gcloud MCP..."
    (cd "$MCP_DIR/gcloud" && git pull --quiet)
else
    print_info "Cloning gcloud MCP..."
    git clone --quiet https://github.com/googleapis/gcloud-mcp.git "$MCP_DIR/gcloud"
fi

print_info "Installing npm dependencies..."
npm --prefix "$MCP_DIR/gcloud" install --silent

print_info "Building MCP servers..."
npm --prefix "$MCP_DIR/gcloud" run build --silent

# Verify builds
for pkg in gcloud-mcp storage-mcp observability-mcp; do
    if [ -f "$MCP_DIR/gcloud/packages/$pkg/dist/bundle.js" ]; then
        print_status "$pkg built successfully"
    else
        print_error "$pkg build failed"
        exit 1
    fi
done

# Update Claude settings.json with MCP configuration
print_header "Updating Claude settings"

# Read existing settings and merge in mcpServers
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    # Use jq if available, otherwise use node
    if command -v jq &> /dev/null; then
        jq '.mcpServers = {
            "gcloud": {
                "command": "node",
                "args": ["'"$MCP_DIR"'/gcloud/packages/gcloud-mcp/dist/bundle.js"]
            },
            "storage": {
                "command": "node",
                "args": ["'"$MCP_DIR"'/gcloud/packages/storage-mcp/dist/bundle.js"]
            },
            "observability": {
                "command": "node",
                "args": ["'"$MCP_DIR"'/gcloud/packages/observability-mcp/dist/bundle.js"]
            },
            "firebase": {
                "command": "npx",
                "args": ["-y", "@anthropic-ai/claude-code-firebase-mcp"]
            }
        }' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        print_status "MCP servers added to Claude settings"
    else
        print_info "jq not found - MCP config already added to settings.json"
    fi
else
    print_error "Claude settings.json not found at $SETTINGS_FILE"
    print_info "Creating minimal settings.json..."
    cat > "$SETTINGS_FILE" << EOF
{
  "mcpServers": {
    "gcloud": {
      "command": "node",
      "args": ["$MCP_DIR/gcloud/packages/gcloud-mcp/dist/bundle.js"]
    },
    "storage": {
      "command": "node",
      "args": ["$MCP_DIR/gcloud/packages/storage-mcp/dist/bundle.js"]
    },
    "observability": {
      "command": "node",
      "args": ["$MCP_DIR/gcloud/packages/observability-mcp/dist/bundle.js"]
    },
    "firebase": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/claude-code-firebase-mcp"]
    }
  }
}
EOF
    print_status "Created new Claude settings.json"
fi

# Final instructions
print_header "Installation Complete"
echo -e "${GREEN}✅ MCP servers installed successfully!${NC}"
echo ""
echo "Available MCP tools:"
echo "  - mcp__gcloud__*      (gcloud CLI commands)"
echo "  - mcp__storage__*     (Cloud Storage operations)"
echo "  - mcp__observability__* (Logging, monitoring, traces)"
echo "  - mcp__firebase__*    (Firebase project management)"
echo ""
echo "To install plugins, use marketplace:"
echo "  ${YELLOW}/plugin install axiom@axiom-marketplace${NC}"
echo "  ${YELLOW}/plugin install superpowers@superpowers-marketplace${NC}"
echo ""
echo "Restart Claude Code to load MCP servers:"
echo "  ${YELLOW}pkill -f claude && claude${NC}"

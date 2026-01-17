#!/bin/bash
# Test MCP and plugin configuration

echo "=== Testing MCP Configuration ==="
echo ""

# Test gcloud MCP
echo "1. Testing gcloud MCP..."
if node /Users/w/.config/claude/mcp/gcloud/packages/gcloud-mcp/dist/bundle.js --version 2>/dev/null; then
    echo "✓ gcloud MCP is accessible"
else
    echo "✗ gcloud MCP failed"
fi

# Test Firebase MCP 
echo ""
echo "2. Testing Firebase MCP..."
if npx -y @gannonh/firebase-mcp --version 2>&1 | grep -q "firebase-mcp"; then
    echo "✓ Firebase MCP package exists"
else
    echo "✗ Firebase MCP package not found"
fi

# Test environment variables
echo ""
echo "3. Testing environment variables..."
source /Users/w/code/abundance-mvp/.env
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "✓ GOOGLE_APPLICATION_CREDENTIALS is set: $GOOGLE_APPLICATION_CREDENTIALS"
    if [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        echo "✓ Service account file exists"
    else
        echo "✗ Service account file not found at: $GOOGLE_APPLICATION_CREDENTIALS"
        echo "  Please download from: https://console.cloud.google.com/iam-admin/serviceaccounts"
    fi
else
    echo "✗ GOOGLE_APPLICATION_CREDENTIALS not set"
fi

# Check plugin directories
echo ""
echo "4. Testing plugin installations..."
if [ -d "/Users/w/.config/claude/plugins/axiom" ]; then
    echo "✓ Axiom plugin installed"
else
    echo "✗ Axiom plugin not found"
fi

if [ -d "/Users/w/.config/claude/plugins/superpowers" ]; then
    echo "✓ Superpowers plugin installed"
else
    echo "✗ Superpowers plugin not found"
fi

echo ""
echo "=== Configuration Summary ==="
echo "To complete setup:"
echo "1. Download service account JSON from GCP Console"
echo "2. Save to: /Users/w/code/abundance-mvp/service-account.json"
echo "3. Restart Claude Code: pkill -f claude && claude"
echo "4. Test with: mcp__gcloud__run_gcloud_command"
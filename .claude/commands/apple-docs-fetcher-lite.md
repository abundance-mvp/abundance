Fetch Apple Developer documentation using MCP with automatic token limit protection

**When to use**: When you need Apple documentation but token limits prevent using the full apple-docs-fetcher skill

Invoke the Skill tool with skill="apple-docs-fetcher-lite" to dispatch a documentation agent that will:

1. Parse requested API/framework from arguments
2. Check docs/apple-context-map.json for recommended documentation paths
3. Use MCP tool (mcp**sosumi**fetchAppleDocumentation) to fetch docs
4. Format as markdown for use in implementation
5. Cache locally in docs/apple/ for future reference

Query: $ARGUMENTS

Examples:

- `/apple-docs-fetcher-lite SwiftUI.View` - Fetch SwiftUI View documentation
- `/apple-docs-fetcher-lite AVFoundation.AVCaptureSession` - Fetch camera session docs
- `/apple-docs-fetcher-lite LAContext` - Fetch biometric auth docs
- `/apple-docs-fetcher-lite "Face ID authentication"` - Search and fetch Face ID docs

If no arguments provided, list available documentation categories from docs/apple-context-map.json.

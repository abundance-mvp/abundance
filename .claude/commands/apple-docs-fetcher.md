Fetch Apple Developer documentation using MCP server with context map guidance.

Invoke the Skill tool with skill="apple-docs-fetcher" to dispatch a documentation agent that will:
1. Parse requested API/framework from arguments
2. Check docs/apple-context-map.json for recommended documentation paths
3. Use MCP tool (mcp__sosumi__fetchAppleDocumentation) to fetch docs
4. Format as markdown for use in implementation
5. Cache locally in docs/apple/ for future reference

Query: $ARGUMENTS

Examples:
- `/apple-docs-fetcher SwiftUI.View` - Fetch SwiftUI View documentation
- `/apple-docs-fetcher AVFoundation.AVCaptureSession` - Fetch camera session docs
- `/apple-docs-fetcher LAContext` - Fetch biometric auth docs
- `/apple-docs-fetcher "Face ID authentication"` - Search and fetch Face ID docs

If no arguments provided, list available documentation categories from docs/apple-context-map.json.

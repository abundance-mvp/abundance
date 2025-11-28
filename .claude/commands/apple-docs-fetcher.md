Fetch Apple Developer documentation using MCP server with sosumi.ai API fallback.

Invoke the Skill tool with skill="apple-docs-fetcher" to dispatch a documentation agent that will:
1. Parse requested API/framework from arguments
2. Use MCP tool (mcp__sosumi__searchAppleDocumentation) to search docs
3. Use MCP tool (mcp__sosumi__fetchAppleDocumentation) to fetch docs
4. If MCP unavailable, fall back to sosumi.ai API via WebFetch
5. Format as markdown for use in implementation

Query: $ARGUMENTS

Examples:
- `/apple-docs-fetcher SwiftUI.View` - Fetch SwiftUI View documentation
- `/apple-docs-fetcher AVFoundation.AVCaptureSession` - Fetch camera session docs
- `/apple-docs-fetcher LAContext` - Fetch biometric auth docs
- `/apple-docs-fetcher "Face ID authentication"` - Search and fetch Face ID docs

If no arguments provided, search for general iOS development documentation.

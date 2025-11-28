Fetch Apple Developer documentation using MCP with automatic token limit protection and sosumi.ai API fallback.

**When to use**: When you need Apple documentation but token limits prevent using the full apple-docs-fetcher skill

Invoke the Skill tool with skill="apple-docs-fetcher-lite" to dispatch a documentation agent that will:

1. Parse requested API/framework from arguments
2. Use MCP tool (mcp__sosumi__searchAppleDocumentation) to search docs
3. Use MCP tool (mcp__sosumi__fetchAppleDocumentation) to fetch docs
4. If MCP unavailable, fall back to sosumi.ai API via WebFetch
5. Format as concise markdown for use in implementation

Query: $ARGUMENTS

Examples:

- `/apple-docs-fetcher-lite SwiftUI.View` - Fetch SwiftUI View documentation
- `/apple-docs-fetcher-lite AVFoundation.AVCaptureSession` - Fetch camera session docs
- `/apple-docs-fetcher-lite LAContext` - Fetch biometric auth docs
- `/apple-docs-fetcher-lite "Face ID authentication"` - Search and fetch Face ID docs

If no arguments provided, search for general iOS development documentation.

---
name: apple-docs-fetcher
description: Fetch Apple Developer documentation using MCP server with context map guidance
---

## When to Use

- During iOS stage development research (automatic via verified-stage-development)
- When implementing iOS features and need API documentation
- When verifying Apple API capabilities

## Usage

Call with feature path, API name, or concept:
- `apple-docs-fetcher swift_language.basics`
- `apple-docs-fetcher AVCaptureSession`
- `apple-docs-fetcher "Face ID authentication"`

## Lookup Strategy

1. **MCP Search:** Call `mcp__sosumi__searchAppleDocumentation` to find documentation
2. **MCP Fetch:** Call `mcp__sosumi__fetchAppleDocumentation` with resolved path
3. **API Fallback:** If MCP unavailable, use sosumi.ai API via WebFetch

## Implementation

**Step 1: Parse input**
- Clean and normalize the query string
- Identify if it's a full path or search term

**Step 2: Try MCP tools (primary method)**
```
Try mcp__sosumi__searchAppleDocumentation(query=input)
If MCP unavailable or timeout → Go to Step 4 (Fallback)
If 0 results: Report "No documentation found"
If 1 result: Use it
If 2+ results: Present top 3 to user for selection
```

**Step 3: Fetch documentation via MCP**
```
Call mcp__sosumi__fetchAppleDocumentation(path=resolved_path)
Return markdown content to agent
Content stays in session memory only
```

**Step 4: Fallback to sosumi.ai API**
```
If MCP unavailable or timeout:
  WebFetch("https://sosumi.ai/api/search?q={query}", "Extract doc paths")
  Parse search results
  WebFetch("https://sosumi.ai/api/docs{path}", "Extract API documentation")
  Return formatted documentation
```

## Error Handling

- MCP unavailable: Fall back to sosumi.ai API via WebFetch
- MCP timeout: Fall back to sosumi.ai API via WebFetch
- No search results: Report "No documentation found for [query]"
- Ambiguous results: Present options to user

## Fallback Strategy: sosumi.ai API

When MCP tools (`mcp__sosumi__*`) are unavailable or timeout:

**Use WebFetch with sosumi.ai API:**

```
Search: WebFetch("https://sosumi.ai/api/search?q={query}", "Extract documentation paths and descriptions")
Fetch: WebFetch("https://sosumi.ai/api/docs{path}", "Extract API documentation, methods, and availability")
```

**Example fallback flow:**
```
Input: "AVCaptureSession"
→ MCP unavailable
→ WebFetch("https://sosumi.ai/api/search?q=AVCaptureSession", ...)
→ Parse results for documentation path
→ WebFetch("https://sosumi.ai/api/docs/documentation/avfoundation/avcapturesession", ...)
→ Return formatted docs
```

## Example Flows

**MCP available (primary):**
```
Input: "URLSession"
→ mcp__sosumi__searchAppleDocumentation("URLSession")
→ Single result found
→ mcp__sosumi__fetchAppleDocumentation("/documentation/foundation/urlsession")
→ Return docs
```

**MCP unavailable (fallback):**
```
Input: "swift concurrency"
→ MCP tools unavailable
→ WebFetch("https://sosumi.ai/api/search?q=swift+concurrency", ...)
→ Parse results → path: /documentation/swift/concurrency
→ WebFetch("https://sosumi.ai/api/docs/documentation/swift/concurrency", ...)
→ Return docs
```

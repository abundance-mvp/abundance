---
name: apple-docs-fetcher
description: Fetch Apple Developer documentation using MCP server with sosumi.ai API fallback.
---

## When to Use

- **Automatically via ios-superpowers** for all iOS/Swift development work
- During iOS stage development research (via verified-stage-development)
- When implementing iOS features and need API documentation
- When verifying Apple API capabilities
- Manual lookups when exploring iOS frameworks

## Integration with ios-superpowers

This skill is called automatically by `ios-superpowers` orchestrator. You typically don't need to invoke it directly unless:
- Manual documentation lookup outside a workflow
- Refreshing stale documentation
- Exploring APIs before starting work

See: `.claude/skills/ios-superpowers/SKILL.md`

## Usage

Call with feature path, API name, or concept:
- `apple-docs-fetcher swift_language.basics`
- `apple-docs-fetcher AVCaptureSession`
- `apple-docs-fetcher "Face ID authentication"`

## Common Lookups Reference

See `references/common-lookups.md` for pre-defined paths to frequently used documentation.

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

---

## Token Budget Management

When fetching multiple APIs, enforce token limits:

- **Per API:** 8,000 tokens max
- **Total per session:** 25,000 tokens max
- **Strategy:** Search first, fetch selectively, extract key info and discard full docs

**Lite mode (recommended for bulk lookups):**
1. Search for API
2. Extract key information from search results
3. Only fetch full docs if search insufficient
4. Immediately summarize and discard full content

---

## Integration Points

### ios-superpowers
- Called automatically during all workflows
- Fetches docs for detected iOS APIs
- Combines with Axiom skill context

### verified-stage-development
- Called during iOS stage research verification
- Validates technical claims against official docs
- Creates verification summary

### ios-sprint-executor
- Called in Phase 1 (pre-sprint setup)
- Called in Phase 4.5 (Apple docs verification)
- Verifies API usage in code review

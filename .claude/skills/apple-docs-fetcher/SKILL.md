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

1. **Context Map Lookup:** Read `docs/apple-context-map.json` and check for feature path match
2. **Search Fallback:** Call `mcp__sosumi__searchAppleDocumentation` if not in context map
3. **Fetch:** Call `mcp__sosumi__fetchAppleDocumentation` with resolved path

## Implementation

**Step 1: Parse input**
- If input matches pattern `category.feature` → Context map lookup
- Otherwise → Search fallback

**Step 2: Context map lookup**
```
Read docs/apple-context-map.json
Parse input as category.feature (e.g., "swift_language.basics")
If found, extract primary_api path
Return path for fetching
```

**Step 3: Search fallback**
```
Call mcp__sosumi__searchAppleDocumentation(query=input)
If 0 results: Report "No documentation found"
If 1 result: Use it
If 2+ results: Present top 3 to user for selection
```

**Step 4: Fetch documentation**
```
Call mcp__sosumi__fetchAppleDocumentation(path=resolved_path)
Return markdown content to agent
Content stays in session memory only
```

## Error Handling

- Context map missing/malformed: Log warning, proceed to search
- MCP timeout: Report error with connection check suggestion
- No search results: Report "No documentation found for [query]"
- Ambiguous results: Present options to user

## Example Flows

**Context map hit:**
```
Input: "swift_language.concurrency"
→ Read context map
→ Find /documentation/swift/swift_standard_library/concurrency
→ Fetch directly
→ Return docs
```

**Search fallback:**
```
Input: "URLSession"
→ Read context map (no match)
→ Search MCP
→ Single result found
→ Fetch /documentation/foundation/urlsession
→ Return docs
```

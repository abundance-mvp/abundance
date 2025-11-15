---
name: apple-docs-fetcher-lite
description: Lightweight Apple documentation fetcher with token limit protection - fetches and summarizes Apple docs without exceeding context limits
---

# Apple Docs Fetcher Lite

**Purpose**: Fetch Apple Developer documentation using MCP with automatic token limit protection

**When to use**: When you need Apple documentation but token limits prevent using the full apple-docs-fetcher skill

## Problem

The apple-docs-fetcher skill can exceed 25,000 token limits when fetching large documentation pages, causing workflows to hang.

## Solution Strategy

1. **Search first, fetch selectively**: Use `mcp__sosumi__searchAppleDocumentation` to find relevant docs
2. **Targeted fetching**: Only fetch specific, focused documentation paths
3. **Summarization**: Extract only the essential information needed for verification
4. **Fallback**: If fetch fails, use search results only

## Usage Pattern

### Step 1: Search for APIs

```
Use mcp__sosumi__searchAppleDocumentation with focused queries:
- "VNCoreMLRequest iOS 26"
- "VNDetectBarcodesRequest"
- "Vision Framework object detection"
```

**Extract from search results**:
- API names
- Brief descriptions
- Documentation paths
- Availability (iOS version)

### Step 2: Selective Fetch (Optional)

ONLY fetch if you need specific details beyond search results:

```
Use mcp__sosumi__fetchAppleDocumentation for SHORT paths:
✅ GOOD: "/documentation/vision/vndetectbarcodesrequest"
❌ BAD: "/documentation/vision" (too broad, will timeout)
```

**Immediately extract**:
- Method signatures
- Key properties
- Code examples
- Requirements

**Then discard** the full documentation to free tokens.

### Step 3: Synthesize Findings

Create a concise summary document with:
- Verified API names and paths
- Availability requirements
- Key capabilities (bullet points)
- Official documentation URLs
- Any limitations discovered

## Token Budget Management

**Per verification task:**
- Search results: ~2,000 tokens max
- Single doc fetch: ~5,000 tokens max (if needed)
- Synthesis output: ~1,000 tokens max
- **Total budget: ~8,000 tokens per API**

**For multiple APIs:**
- Do searches in parallel (single message, multiple tool calls)
- Fetch docs sequentially (one at a time)
- Synthesize after each fetch
- Never hold more than 1 fetched doc in context at once

## Example: Vision Framework Verification

### Task: Verify iOS 26 Vision Framework APIs for object detection and barcode scanning

**Step 1: Parallel searches**
```
Single message with 3 tool calls:
- mcp__sosumi__searchAppleDocumentation("VNCoreMLRequest")
- mcp__sosumi__searchAppleDocumentation("VNDetectBarcodesRequest")
- mcp__sosumi__searchAppleDocumentation("Vision Framework iOS 26")
```

**Extract from results:**
- API paths: /documentation/vision/vncoremlrequest
- Availability: iOS 11.0+
- Purpose: Run Core ML models on Vision requests
- Key finding: VNCoreMLRequest exists, no VNRecognizeObjectsRequest

**Step 2: Targeted fetch (if needed)**
```
mcp__sosumi__fetchAppleDocumentation("/documentation/vision/vndetectbarcodesrequest")
```

**Extract immediately:**
- Symbologies supported: UPC-E, EAN-13, EAN-8, Code 128, QR Code, etc.
- Returns: VNBarcodeObservation objects
- Properties: barcodeDescriptor, symbology, payloadStringValue

**Step 3: Create summary**
```markdown
## Vision Framework Verification (2025-11-08)

### VNCoreMLRequest
- **Status**: ✅ Verified
- **Path**: /documentation/vision/vncoremlrequest
- **Availability**: iOS 11.0+
- **Purpose**: Process images using Core ML models
- **Usage**: Wrap YOLOv3-Tiny model for object detection
- **Source**: https://developer.apple.com/documentation/vision/vncoremlrequest

### VNDetectBarcodesRequest
- **Status**: ✅ Verified
- **Path**: /documentation/vision/vndetectbarcodesrequest
- **Availability**: iOS 11.0+
- **Supported symbologies**: UPC-E, EAN-13, EAN-8, Code 128, Code 39, ITF14, QR Code
- **Returns**: VNBarcodeObservation with symbology and payload
- **Source**: https://developer.apple.com/documentation/vision/vndetectbarcodesrequest

### VNRecognizeObjectsRequest
- **Status**: ❌ Does not exist
- **Finding**: No such API in Vision Framework
- **Alternative**: Use VNCoreMLRequest with object detection model
```

## Anti-Patterns (What NOT to do)

❌ **Don't fetch broad documentation**
```
mcp__sosumi__fetchAppleDocumentation("/documentation/vision")
→ Will return 50,000+ tokens, cause timeout
```

❌ **Don't fetch multiple large docs in sequence**
```
fetch("/documentation/swiftui")
fetch("/documentation/combine")
fetch("/documentation/swift")
→ Will accumulate 100,000+ tokens
```

❌ **Don't keep fetched docs in context**
```
fetch doc 1 → fetch doc 2 → fetch doc 3 → then analyze
→ All 3 docs remain in context, exceeds limits
```

✅ **Do this instead**
```
fetch doc 1 → extract key info → discard →
fetch doc 2 → extract key info → discard →
consolidate extracted info
```

## Integration with verified-stage-development

When the verified-stage-development skill needs Apple documentation:

**Before launching research agent:**
1. Identify specific APIs to verify (e.g., VNCoreMLRequest, VNDetectBarcodesRequest)
2. Create focused verification questions
3. Set token budget: 8,000 tokens per API

**In research agent prompt:**
```
Use apple-docs-fetcher-lite pattern:
1. Search for "VNCoreMLRequest" and "VNDetectBarcodesRequest"
2. Extract API names, paths, availability from search results
3. ONLY fetch individual API docs if search results insufficient
4. Immediately extract key details after each fetch
5. Create concise verification summary
6. Total token budget: 16,000 for both APIs
```

**After research agent completes:**
- Research agent returns concise summary (not full docs)
- Main workflow continues without token bloat
- Full documentation URLs included for reference

## Fallback Strategy

If MCP fetch consistently fails:

**Plan B: Use search results only**
- Search provides: API names, brief descriptions, paths
- Sufficient for verification: "API exists, available in iOS X+"
- Document limitation in validation report
- Include official URLs for manual review

**Plan C: Use WebFetch on developer.apple.com**
- Construct URL: `https://developer.apple.com/documentation/vision/vncoremlrequest`
- WebFetch with prompt: "Extract API availability, purpose, and key methods"
- Less reliable than MCP but works when MCP fails

## Success Criteria

✅ **Successful verification session:**
- Verified 3-5 APIs
- Total tokens used: < 25,000
- All essential information extracted
- Workflow completes without hanging
- Verification summary created

❌ **Failed session (retry with adjustments):**
- Tokens exceeded 25,000
- MCP fetch timed out
- Agent hung waiting for response
- No summary produced

## Template: Verification Summary Output

```markdown
# Apple Documentation Verification: [Feature Name]

**Date**: YYYY-MM-DD
**APIs Verified**: [count]
**Method**: MCP search + selective fetch
**Token Budget**: [used] / 25,000

## Verified APIs

### [API Name 1]
- **Status**: ✅/❌
- **Availability**: iOS X.X+
- **Path**: /documentation/...
- **Key Capabilities**: [bullet points]
- **Limitations**: [if any]
- **Source**: [developer.apple.com URL]

### [API Name 2]
...

## Unverified Claims

- [Claim]: Could not verify (reason)
- Recommendation: [manual review/defer to next stage]

## Official Documentation URLs

1. [API 1]: https://developer.apple.com/...
2. [API 2]: https://developer.apple.com/...

## Notes

[Any important context, warnings, or recommendations]
```

---

## Skill Checklist

When using this skill:

- [ ] Identify specific APIs to verify (3-5 max per session)
- [ ] Set token budget: 8,000 per API
- [ ] Use search first, fetch only if needed
- [ ] Extract immediately, discard full docs
- [ ] Create concise summary
- [ ] Include official URLs for reference
- [ ] Monitor token usage throughout
- [ ] If approaching 20,000 tokens, stop fetching and synthesize

---

**This skill prevents token limit failures while still providing Apple documentation verification for the verified-stage-development workflow.**

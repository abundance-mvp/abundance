# MCP Token Limit Solution

**Problem Identified**: 2025-11-08
**Solution Implemented**: apple-docs-fetcher-lite skill
**Status**: ✅ Ready for use

---

## Problem

The `apple-docs-fetcher` skill causes token limit failures when fetching large Apple documentation:

- **Symptom**: verified-stage-development workflow hangs when fetching Apple docs
- **Root cause**: Fetching broad documentation paths (e.g., `/documentation/vision`) returns 50,000+ tokens
- **Token limit**: 25,000 tokens per agent session
- **Impact**: Cannot complete iOS-related stages (2.2, 2.4, 3.1, 4.1)

## Solution

Created **apple-docs-fetcher-lite** skill with intelligent token management:

### Key Changes

1. **Search-first approach**
   - Use `mcp__sosumi__searchAppleDocumentation` to find APIs
   - Extract key info from search results (often sufficient)
   - Only fetch if search results lack needed details

2. **Selective fetching**
   - Fetch specific API docs only (e.g., `/documentation/vision/vncoremlrequest`)
   - Never fetch broad paths (e.g., `/documentation/vision`)
   - Immediately extract key info and discard full doc

3. **Token budgeting**
   - 8,000 tokens max per API verification
   - 25,000 tokens total max per session
   - Monitor usage, stop if approaching limits

4. **Extract-and-discard pattern**
   - Fetch doc → Extract essentials → Discard doc → Fetch next
   - Never accumulate multiple fetched docs in context

### Implementation

**File**: `.claude/skills/apple-docs-fetcher-lite/SKILL.md`

**Usage pattern**:

```
Step 1: Search (parallel, low tokens)
- mcp__sosumi__searchAppleDocumentation("VNCoreMLRequest")
- mcp__sosumi__searchAppleDocumentation("VNDetectBarcodesRequest")

Extract from results:
- API names
- Availability
- Brief descriptions
- Documentation paths

Step 2: Selective fetch (sequential, one at a time)
IF search results insufficient:
  - mcp__sosumi__fetchAppleDocumentation("/documentation/vision/vncoremlrequest")
  - Extract: method signatures, properties, requirements
  - Discard full doc

Step 3: Synthesize
Create concise summary:
- Verified API names
- Key capabilities (bullets)
- Official doc URLs
- Limitations
```

### Integration with verified-stage-development

Updated `.claude/skills/verified-stage-development/SKILL.md`:

**Before** (broken):
```
3. Invoke apple-docs-fetcher for foundational docs
4. Invoke apple-docs-fetcher for feature-specific docs
```

**After** (fixed):
```
1. Identify 3-5 specific APIs to verify
2. Pass to research agent with token budget
3. Research agent uses apple-docs-fetcher-lite pattern
4. Returns concise summary (not full docs)
```

---

## Usage Guidelines

### For Research Verification Agents

When creating research agents for iOS stages:

```markdown
## Apple Documentation Verification

Use apple-docs-fetcher-lite pattern:

1. APIs to verify: VNCoreMLRequest, VNDetectBarcodesRequest, Vision Framework
2. Token budget: 25,000 total (8,000 per API)

**Process**:
- Search first: mcp__sosumi__searchAppleDocumentation
- Extract from search: API names, availability, capabilities
- Fetch selectively: Only if search insufficient
- Immediately extract and discard: Method signatures, properties
- Create summary: Concise verification report with official URLs

**Output**: docs/validation/RESEARCH-VALIDATION-stage-X.X.md
- Verified APIs section
- Key capabilities (bullets, not full docs)
- Official documentation URLs
- Token usage: [used] / 25,000
```

### What To Do

✅ **Search for specific APIs**
```
mcp__sosumi__searchAppleDocumentation("VNDetectBarcodesRequest")
```

✅ **Fetch specific API docs**
```
mcp__sosumi__fetchAppleDocumentation("/documentation/vision/vndetectbarcodesrequest")
```

✅ **Extract immediately**
```
Supported symbologies: UPC-E, EAN-13, EAN-8, Code 128
Returns: VNBarcodeObservation
Availability: iOS 11.0+
```

✅ **Create concise summary**
```markdown
### VNDetectBarcodesRequest
- Status: ✅ Verified
- Availability: iOS 11.0+
- Symbologies: UPC-E, EAN-13, EAN-8, Code 128, QR Code
- Source: https://developer.apple.com/documentation/vision/vndetectbarcodesrequest
```

### What NOT To Do

❌ **Don't fetch broad paths**
```
mcp__sosumi__fetchAppleDocumentation("/documentation/vision")
→ Returns 50,000+ tokens, causes failure
```

❌ **Don't accumulate docs**
```
fetch("/documentation/vision/vncoremlrequest")
fetch("/documentation/vision/vndetectbarcodesrequest")
fetch("/documentation/vision/vnimagerequesthandler")
→ All 3 docs stay in context, exceeds 25,000 tokens
```

❌ **Don't use full apple-docs-fetcher skill**
```
Skill("apple-docs-fetcher")
→ Will fetch multiple large docs, exceed limits
```

---

## Fallback Strategy

If MCP continues to fail:

### Plan B: Search-only verification
- Search provides: API names, brief descriptions, paths
- Sufficient for: "API exists, available in iOS X+"
- Document limitation in validation report
- Include URLs for manual review

### Plan C: WebFetch developer.apple.com
```
WebFetch("https://developer.apple.com/documentation/vision/vncoremlrequest",
         "Extract API availability, purpose, and key methods")
```

Less reliable than MCP but works when MCP fails.

---

## Testing

### Test Case 1: Vision Framework (3 APIs)

**APIs**: VNCoreMLRequest, VNDetectBarcodesRequest, VNImageRequestHandler

**Expected**:
- Search: 3 parallel searches, ~2,000 tokens total
- Fetch: 0-3 docs (only if needed), ~5,000 tokens each max
- Summary: ~1,000 tokens
- **Total: < 20,000 tokens** ✅

**Result**: Workflow completes, verification summary created

### Test Case 2: Token limit stress test

**APIs**: 5 Vision Framework APIs

**Expected**:
- Search: 5 parallel searches, ~3,000 tokens total
- Fetch: Selective (2-3 docs), ~15,000 tokens total
- Summary: ~1,500 tokens
- **Total: ~19,500 tokens** ✅

**Result**: Stays under 25,000 limit, workflow completes

### Test Case 3: Fallback to search-only

**Scenario**: All fetches timing out

**Expected**:
- Search: Extract all info from search results
- Fetch: Skip (timeout)
- Summary: Based on search only, note limitation
- **Total: ~3,000 tokens** ✅

**Result**: Partial verification, workflow completes with caveats

---

## Success Metrics

✅ **Successful iOS stage execution:**
- Verified 3-5 iOS APIs
- Total tokens < 25,000
- Workflow completed without hanging
- Verification summary created
- All essential info extracted

❌ **Failed execution (indicates need for adjustment):**
- Tokens exceeded 25,000
- MCP fetch timed out
- Workflow hung
- No summary produced

---

## Next Steps

1. **Test with Stage 2.1 re-execution**
   - Verify VNCoreMLRequest, VNDetectBarcodesRequest
   - Monitor token usage
   - Confirm workflow completes

2. **If successful, apply to Stage 2.2**
   - iOS client architecture verification
   - SwiftUI, Combine, async/await APIs
   - Vision Framework integration

3. **Document any adjustments needed**
   - Update apple-docs-fetcher-lite if patterns emerge
   - Refine token budgets based on actual usage
   - Add more fallback strategies if needed

---

## Related Files

- **Lite skill**: `.claude/skills/apple-docs-fetcher-lite/SKILL.md`
- **Updated workflow**: `.claude/skills/verified-stage-development/SKILL.md`
- **This document**: `docs/tech-stack/MCP-TOKEN-LIMIT-SOLUTION.md`

---

**Status**: Ready for Stage 2.1 re-execution with apple-docs-fetcher-lite pattern

# SPEC-PIPE-003: Session Persistence (Design)

**Created:** 2026-01-18
**Status:** Planned
**Author:** Claude Code Audit

---

## Overview

This design spec proposes a hybrid session persistence approach for the Layer 2 cataloging pipeline. The goal is to provide Gemini 3 Pro with context from previous cataloging attempts, enabling more consistent results when users add photos or request re-cataloging, while simultaneously reducing API costs by up to 90%.

Currently, each Layer 2 call to `processItemWithGemini()` starts completely fresh with no knowledge of previous attempts. This stateless design was appropriate for MVP but becomes inefficient as users iterate on their catalogs.

---

## Problem Statement

### Current Implementation: Stateless Layer 2

**Reference:** `functions/src/ai-pipeline/gemini/gemini-service.ts:30-133`

Each call to `processItemWithGemini()`:
1. Fetches the image from URL
2. Builds a fresh conversation with system prompt + tools
3. Sends to Gemini 3 Pro with zero prior context
4. Executes tool calls (Google Lens, barcode lookup, web search)
5. Returns final catalog result

### Problems with Stateless Design

#### 1. Inconsistent Results on Re-catalog

When a user triggers Layer 2 again (e.g., after adding a new photo angle):

- Gemini has no memory of previous identification
- May produce different name/brand/model than before
- Tool call results may differ (Google Lens can return different matches)
- User sees confusing inconsistencies between catalog attempts

**Example:**
```
First catalog:  "Apple Mac Mini M2 Pro 512GB" (confidence: high)
Second catalog: "Apple Mac Mini M2" (confidence: medium)
```

The user expected refinement, not regression.

#### 2. Wasted Tool Calls

If barcode lookup previously returned "Samsung Galaxy S24 Ultra 256GB", re-calling barcode_lookup with the same UPC wastes:
- ~$0.005 per UPC API call
- ~$0.015 per Google Lens call
- Latency (500ms+ per external API call)

For items with multiple catalog attempts, this compounds quickly.

#### 3. No Learning from User Corrections

When users manually correct catalog data (e.g., fixing brand from "Generic" to "Apple"), subsequent re-catalogs ignore these corrections entirely. The model should be aware of user-provided ground truth.

---

## Proposed Solution: Hybrid Approach

The solution combines three complementary mechanisms:

1. **Firestore History** - Persistent storage of previous Layer 2 results
2. **Context Caching** - Gemini API caching for system prompt + tool definitions
3. **Context Injection** - Include previous results in new prompts

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Re-catalog Request                                                          │
│  (User adds photo or taps "Re-catalog")                                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  1. Fetch Catalog History                                                    │
│     Collection: items/{itemId}/catalogHistory                                │
│     Get: Most recent 3 entries (ordered by timestamp desc)                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  2. Check Context Cache                                                      │
│     Key: sha256(systemPrompt + toolDefinitions)                              │
│     If cached: Use cached context (90% token cost reduction)                 │
│     If not: Create cache with 1-hour TTL                                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  3. Build Prompt with Context Injection                                      │
│     Inject previous results as context prefix:                               │
│     "Previous identification: {name}, {brand}, {model}..."                   │
│     "Tool results from previous attempt: {barcode: ..., lens: ...}"         │
│     "User corrections: {field: oldValue → newValue}..."                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  4. Gemini 3 Pro Call (with history context)                                 │
│     Model can now:                                                           │
│     - Confirm previous identification with new image                         │
│     - Skip redundant tool calls (e.g., same barcode)                        │
│     - Refine/update based on additional visual data                          │
│     - Respect user corrections                                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  5. Store Result in History                                                  │
│     items/{itemId}/catalogHistory/{historyId}                                │
│     Record: timestamp, model, imageUrls, toolCalls, result, metadata         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Component A: Firestore History

### Collection Structure

```
items/{itemId}/catalogHistory/{historyId}
```

Store every Layer 2 result as a history entry, enabling:
- Rollback to previous versions
- Audit trail for debugging
- Context for future catalog attempts

### What Gets Stored

| Field | Purpose |
|-------|---------|
| `timestamp` | When this catalog attempt occurred |
| `modelId` | Which Gemini model was used (e.g., `gemini-3-pro-preview`) |
| `imageUrls` | Array of image URLs processed in this attempt |
| `toolCalls` | Record of all tool calls made and their results |
| `result` | The CatalogItem output from this attempt |
| `metadata` | Processing stats (duration, token usage, etc.) |

### Retention Policy

- **Keep:** Most recent 10 entries per item
- **Archive:** Older entries moved to cold storage (GCS) after 30 days
- **Delete:** Archived entries after 1 year

---

## Component B: Context Caching

### Gemini Explicit Context Caching

Gemini 3 supports explicit context caching via the Caching API:

**Reference:** https://cloud.google.com/vertex-ai/generative-ai/docs/context-caching

### Cacheable Content

The following content is identical across all Layer 2 calls:

| Content | Approx. Tokens |
|---------|---------------|
| System Prompt (`SYSTEM_PROMPT`) | ~800 tokens |
| Tool Definitions (3 tools) | ~600 tokens |
| Response Schema (`CATALOG_ITEM_SCHEMA`) | ~400 tokens |
| **Total** | **~1,800 tokens** |

**Note:** Gemini requires minimum 2,048 tokens for caching. Our current setup is close but may need padding or inclusion of additional context (e.g., category taxonomy).

### Cache Configuration

```typescript
interface ContextCacheConfig {
  // Unique identifier for this cache configuration
  cacheKey: string;  // sha256(systemPrompt + tools + schema)

  // TTL for cached context (max: 1 hour for cost optimization)
  ttlSeconds: 3600;

  // Content to cache
  cachedContent: {
    systemInstruction: string;
    tools: Tool[];
    responseSchema: object;
  };
}
```

### Cost Savings

| Scenario | Without Caching | With Caching | Savings |
|----------|-----------------|--------------|---------|
| Input tokens (cached) | $0.0025/1K | $0.00025/1K | 90% |
| Typical call (~2K cached tokens) | ~$0.005 | ~$0.0005 | $0.0045 |

For an item cataloged 5 times: saves ~$0.02 per item.

---

## Component C: Context Injection

### Prompt Prefix Format

When history exists, inject it as a prefix to the user message:

```
PREVIOUS CATALOG CONTEXT:
========================

Last identification (2026-01-18T10:30:00Z, confidence: high):
- Name: Apple Mac Mini M2 Pro
- Brand: Apple
- Model: Mac Mini M2 Pro 512GB
- Category: Electronics > Computers > Desktop
- Condition: like-new
- Estimated Value: $899

Tool results from previous attempt:
- barcode_lookup(036000291452): {found: true, title: "Apple Mac Mini M2 Pro 512GB"}
- google_lens_search: {exact_matches: true, products: [...]}
- web_search("Apple Mac Mini M2 Pro like-new price"): {prices: [{source: "eBay", price: 899}]}

User corrections applied:
- condition: "good" → "like-new" (user override)

========================

Now analyze the NEW image(s) below. You may:
- Confirm the previous identification if new images match
- Update specific fields if you see new information
- Skip redundant tool calls (e.g., same barcode)
- Correct errors if new visual evidence contradicts previous
```

### Injection Logic

```typescript
function buildContextPrefix(history: CatalogHistoryEntry[]): string {
  if (history.length === 0) return '';

  const latest = history[0];  // Most recent
  const parts: string[] = [];

  parts.push('PREVIOUS CATALOG CONTEXT:');
  parts.push('========================\n');

  // Last identification
  parts.push(`Last identification (${latest.timestamp}, confidence: ${latest.result.confidence}):`);
  parts.push(`- Name: ${latest.result.name}`);
  parts.push(`- Brand: ${latest.result.brand || 'Unknown'}`);
  parts.push(`- Model: ${latest.result.model || 'N/A'}`);
  // ... more fields

  // Tool call history (deduplicated)
  parts.push('\nTool results from previous attempt:');
  for (const call of latest.toolCalls) {
    parts.push(`- ${call.name}(${JSON.stringify(call.args)}): ${summarize(call.result)}`);
  }

  // User corrections (if any)
  if (latest.userCorrections?.length > 0) {
    parts.push('\nUser corrections applied:');
    for (const correction of latest.userCorrections) {
      parts.push(`- ${correction.field}: "${correction.oldValue}" → "${correction.newValue}" (user override)`);
    }
  }

  parts.push('========================\n');
  parts.push('Now analyze the NEW image(s) below...');

  return parts.join('\n');
}
```

---

## Data Model

### CatalogHistoryEntry

```typescript
/**
 * A single catalog history entry for an item.
 * Stored in: items/{itemId}/catalogHistory/{historyId}
 */
interface CatalogHistoryEntry {
  /** Document ID (auto-generated) */
  id: string;

  /** When this catalog attempt occurred */
  timestamp: FirebaseFirestore.Timestamp;

  /** Gemini model used for this attempt */
  modelId: string;  // e.g., 'gemini-3-pro-preview'

  /** Image URLs processed in this attempt */
  imageUrls: string[];

  /** All tool calls made during this attempt */
  toolCalls: ToolCallRecord[];

  /** The CatalogItem result from this attempt */
  result: CatalogResultSnapshot;

  /** Processing metadata */
  metadata: CatalogMetadata;

  /** User corrections applied after this attempt (for tracking) */
  userCorrections?: UserCorrection[];
}
```

### ToolCallRecord

```typescript
/**
 * Record of a single tool call made during cataloging.
 */
interface ToolCallRecord {
  /** Tool name (google_lens_search, barcode_lookup, web_search) */
  name: string;

  /** Arguments passed to the tool */
  args: Record<string, unknown>;

  /** Result returned by the tool */
  result: Record<string, unknown>;

  /** Duration of tool execution in milliseconds */
  durationMs: number;

  /** Whether this call was skipped due to cache */
  skipped?: boolean;

  /** If skipped, which history entry provided the cached result */
  cachedFromHistoryId?: string;
}
```

### CatalogResultSnapshot

```typescript
/**
 * Snapshot of catalog result at time of cataloging.
 * Mirrors CatalogItem but with explicit null handling.
 */
interface CatalogResultSnapshot {
  name: string;
  category: string;
  subCategory: string;
  brand: string | null;
  model: string | null;
  color: string;
  condition: 'new' | 'like-new' | 'good' | 'fair' | 'poor';
  dimensions: string | null;
  quantity: number;
  estimatedValue: number | null;
  confidence: 'high' | 'medium' | 'low';
  processingNotes: string | null;
}
```

### CatalogMetadata

```typescript
/**
 * Processing metadata for debugging and analytics.
 */
interface CatalogMetadata {
  /** Total processing duration in milliseconds */
  totalDurationMs: number;

  /** Number of tool calling iterations */
  toolIterations: number;

  /** Token usage breakdown */
  tokenUsage: {
    promptTokens: number;
    completionTokens: number;
    cachedTokens: number;
  };

  /** Whether context cache was used */
  contextCacheHit: boolean;

  /** Context cache key if used */
  contextCacheKey?: string;

  /** Trigger source */
  triggerSource: 'user_request' | 'photo_added' | 'initial_catalog';
}
```

### UserCorrection

```typescript
/**
 * Record of a user correction to catalog data.
 */
interface UserCorrection {
  /** Field that was corrected */
  field: keyof CatalogResultSnapshot;

  /** Original value from AI */
  oldValue: unknown;

  /** User-provided value */
  newValue: unknown;

  /** When the correction was made */
  correctedAt: FirebaseFirestore.Timestamp;
}
```

---

## Implementation Steps

### Task 1: Create Data Model

**File:** `functions/src/ai-pipeline/models/catalog-history.ts`

- Define TypeScript interfaces (above)
- Create Zod schemas for validation
- Export type guards

**Estimated effort:** 2 hours

### Task 2: Create History Service

**File:** `functions/src/ai-pipeline/services/history-service.ts`

- `getHistory(itemId: string, limit?: number): Promise<CatalogHistoryEntry[]>`
- `saveHistory(itemId: string, entry: Omit<CatalogHistoryEntry, 'id'>): Promise<string>`
- `getUserCorrections(itemId: string): Promise<UserCorrection[]>`
- `pruneHistory(itemId: string, keepCount: number): Promise<void>`

**Estimated effort:** 4 hours

### Task 3: Create Context Cache Service

**File:** `functions/src/ai-pipeline/services/context-cache-service.ts`

- `getOrCreateCache(config: ContextCacheConfig): Promise<CacheHandle>`
- `getCacheKey(systemPrompt: string, tools: Tool[]): string`
- `invalidateCache(cacheKey: string): Promise<void>`

**Note:** Requires Vertex AI SDK update for caching API support.

**Estimated effort:** 6 hours

### Task 4: Modify Gemini Service

**File:** `functions/src/ai-pipeline/gemini/gemini-service.ts`

- Add `historyContext?: CatalogHistoryEntry[]` parameter to `processItemWithGemini()`
- Inject history context prefix into user message
- Record tool calls for history storage
- Support context cache usage

**Estimated effort:** 4 hours

### Task 5: Update Orchestrator

**File:** `functions/src/ai-pipeline/gemini/orchestrator.ts`

- Fetch history before calling gemini-service
- Save history after successful cataloging
- Handle user correction tracking
- Add metadata collection

**Estimated effort:** 3 hours

### Task 6: Add Firestore Indexes

**File:** `firestore.indexes.json`

```json
{
  "collectionGroup": "catalogHistory",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
}
```

**Estimated effort:** 30 minutes

### Task 7: Write Tests

**Files:**
- `functions/src/ai-pipeline/services/__tests__/history-service.test.ts`
- `functions/src/ai-pipeline/services/__tests__/context-cache-service.test.ts`
- `functions/src/ai-pipeline/gemini/__tests__/gemini-service-with-history.test.ts`

**Estimated effort:** 6 hours

---

## Cost Savings Analysis

### Before: Stateless Layer 2

| Component | Cost per Call |
|-----------|---------------|
| Gemini 3 Pro input tokens (~2K cached + ~2K dynamic) | $0.01 |
| Gemini 3 Pro output tokens (~1K) | $0.01 |
| Google Lens (SerpAPI) | $0.015 |
| Web Search | $0.014 |
| **Total per call** | **~$0.04** |

For an item cataloged 3 times: **$0.12**

### After: Hybrid Session Persistence

| Component | First Call | Subsequent Calls |
|-----------|------------|------------------|
| Gemini 3 Pro input (cached) | $0.01 | $0.001 |
| Gemini 3 Pro input (dynamic) | $0.005 | $0.005 |
| Gemini 3 Pro output | $0.01 | $0.01 |
| Tool calls | $0.029 | $0.00 (skipped) |
| **Total per call** | **~$0.044** | **~$0.016** |

For an item cataloged 3 times: First: $0.044 + 2×$0.016 = **$0.076**

**Savings:** 37% reduction per item with multiple catalogs.

### Break-even Analysis

- Context cache has a small storage cost (~$0.00025/hour per cached context)
- Break-even at ~2 cached calls per hour
- At typical usage (items cataloged within minutes of each other), ROI is positive

---

## Considerations

### Privacy & Data Retention

- History contains image URLs and catalog data
- Must respect user data deletion requests (cascade delete history)
- Consider GDPR implications for EU users

### Graceful Degradation

- If history service fails, fall back to stateless operation
- If context cache is unavailable, proceed without caching
- Log warnings but don't block cataloging

### Concurrency

- Multiple concurrent catalogs of same item possible
- Use optimistic locking or last-write-wins
- History entries are append-only (no conflicts)

### Model Version Changes

- History entries from older models may be less useful
- Consider versioning in context injection
- Allow users to "reset" history for an item

---

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| Data Model | **Planned** | Interfaces defined in this spec |
| History Service | **Planned** | |
| Context Cache Service | **Planned** | Pending SDK support verification |
| Gemini Service Updates | **Planned** | |
| Orchestrator Updates | **Planned** | |
| Firestore Indexes | **Planned** | |
| Tests | **Planned** | |

**Overall Status:** PLANNED

**Implementation Plan:** `docs/plans/2026-01-18-hybrid-session-persistence.md`

---

## References

- [SPEC-ARCH-002: Layer 1 / Layer 2 Pipeline Architecture](/docs/specs/SPEC-ARCH-002-layer1-layer2-pipeline.md)
- [Gemini Context Caching Documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/context-caching)
- [Current gemini-service.ts](/functions/src/ai-pipeline/gemini/gemini-service.ts)
- [Current prompts.ts](/functions/src/ai-pipeline/gemini/prompts.ts)

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-18 | 1.0 | Initial design spec |

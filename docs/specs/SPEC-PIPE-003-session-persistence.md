# SPEC-PIPE-003: Session Persistence (Design)

**Created:** 2026-01-18
**Status:** Implemented
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
| `catalogedAt` | Server timestamp when this catalog attempt occurred |
| `model` | Which Gemini model was used (e.g., `gemini-3-pro-preview`) |
| `imageUrls` | Array of image URLs processed in this attempt |
| `toolCalls` | Record of all tool calls made with `{ name, args, result, success }` |
| `result` | CatalogResultSnapshot (name, brand, model, category, subCategory, confidence, estimatedValue, condition) |
| `metadata` | Processing stats (`totalTokens`, `durationMs`, `usedContextCache`) |

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
PREVIOUS CATALOG INFORMATION:
This item was previously cataloged with the following information:
- Name: Apple Mac Mini M2 Pro
- Brand: Apple
- Model: Mac Mini M2 Pro 512GB
- Category: Electronics
- Confidence: high
- Estimated Value: $899
- Condition: like-new

Previous tool calls:
- google_lens_search: Success
- barcode_lookup: Success
- web_search: Success

Use this context to maintain consistency. If new images provide clearer information,
you may update the identification, but explain why in your reasoning.
```

### Injection Logic

```typescript
export function formatHistoryForPrompt(history: CatalogHistoryEntry[]): string {
  if (history.length === 0) {
    return '';
  }

  const latest = history[0];
  const result = latest.result;

  const lines = [
    'PREVIOUS CATALOG INFORMATION:',
    'This item was previously cataloged with the following information:',
    `- Name: ${result.name}`,
    `- Brand: ${result.brand || 'Unknown'}`,
    `- Model: ${result.model || 'Unknown'}`,
    `- Category: ${result.category}`,
    `- Confidence: ${result.confidence}`
  ];

  if (result.estimatedValue) {
    lines.push(`- Estimated Value: $${result.estimatedValue}`);
  }
  if (result.condition) {
    lines.push(`- Condition: ${result.condition}`);
  }

  lines.push('');
  lines.push('Previous tool calls:');
  for (const tc of latest.toolCalls) {
    lines.push(`- ${tc.name}: ${tc.success ? 'Success' : 'Failed'}`);
  }

  lines.push('');
  lines.push('Use this context to maintain consistency. If new images provide clearer information,');
  lines.push('you may update the identification, but explain why in your reasoning.');

  return lines.join('\n');
}
```

---

## Data Model

### CatalogHistoryEntry

```typescript
/**
 * Represents a single catalog history entry for an item.
 * Stored in Firestore subcollection: items/{itemId}/catalogHistory/{entryId}
 */
interface CatalogHistoryEntry {
  /** Firestore document ID */
  id: string;

  /** Timestamp when this catalog was performed */
  catalogedAt: Timestamp;

  /** Gemini model used (e.g., 'gemini-3-pro-preview') */
  model: string;

  /** Image URLs processed in this catalog session */
  imageUrls: string[];

  /** Tool calls made during this session */
  toolCalls: ToolCallRecord[];

  /** Final catalog result */
  result: CatalogResultSnapshot;

  /** Processing metadata */
  metadata: CatalogMetadata;
}
```

**Note:** The design originally included `userCorrections` for tracking user overrides, but this field was not included in the initial implementation. User correction tracking may be added in a future iteration.

### ToolCallRecord

```typescript
/**
 * Record of a tool call made during cataloging
 */
interface ToolCallRecord {
  /** Tool name (google_lens_search, barcode_lookup, web_search) */
  name: string;

  /** Arguments passed to the tool */
  args: Record<string, unknown>;

  /** Result returned by the tool */
  result: Record<string, unknown>;

  /** Whether the call succeeded */
  success: boolean;
}
```

### CatalogResultSnapshot

```typescript
/**
 * Snapshot of catalog result at a point in time.
 * A subset of CatalogItem fields relevant for history context.
 */
interface CatalogResultSnapshot {
  name: string;
  brand: string | null;
  model: string | null;
  category: string;
  subCategory: string | null;
  confidence: Confidence;
  estimatedValue: number | null;
  condition: Condition | null;
}
```

### CatalogMetadata

```typescript
/**
 * Processing metadata for a catalog session
 */
interface CatalogMetadata {
  /** Total tokens used across all iterations */
  totalTokens: number;

  /** Processing duration in milliseconds */
  durationMs: number;

  /** Whether context cache was used */
  usedContextCache: boolean;
}
```

### UserCorrection (Not Yet Implemented)

The original design included a `UserCorrection` interface for tracking when users manually correct catalog data. This has not been implemented yet but remains a future consideration:

```typescript
// FUTURE: Not yet implemented
interface UserCorrection {
  field: keyof CatalogResultSnapshot;
  oldValue: unknown;
  newValue: unknown;
  correctedAt: FirebaseFirestore.Timestamp;
}
```

---

## Implementation Steps

### Task 1: Create Data Model

**File:** `functions/src/ai-pipeline/gemini/schemas/catalog-history.ts`

- Define TypeScript interfaces (`CatalogHistoryEntry`, `ToolCallRecord`, `CatalogResultSnapshot`, `CatalogMetadata`)
- Export types for use by history and gemini services

**Estimated effort:** 2 hours

### Task 2: Create History Service

**File:** `functions/src/ai-pipeline/gemini/catalog-history-service.ts`

- `saveCatalogHistory(itemId, entry)` - Persist catalog result to history
- `getRecentCatalogHistory(itemId, limit)` - Retrieve recent history entries
- `catalogItemToSnapshot(item)` - Convert CatalogItem to snapshot
- `formatHistoryForPrompt(history)` - Format history for prompt injection
- Auto-cleanup of entries beyond `MAX_HISTORY_ENTRIES` (10)

**Estimated effort:** 4 hours

### Task 3: Create Context Cache Service

**File:** `functions/src/ai-pipeline/gemini/context-cache-service.ts`

- `getOrCreateContextCache()` - Get/create cached context for system prompt + tools
- `listContextCaches()` - List existing caches (debugging)
- `deleteContextCache(name)` - Delete specific cache
- `estimateTokenSavings()` - Cost analysis utility
- In-memory cache reference with TTL tracking

**Estimated effort:** 6 hours

### Task 4: Modify Gemini Service

**File:** `functions/src/ai-pipeline/gemini/gemini-service.ts`

- Added `processItemWithGeminiPersistent()` as new entry point with persistence
- History context injection into user prompt
- Tool call recording with `success` flag
- Token tracking via `response.usageMetadata`
- Context cache integration via `getOrCreateContextCache()`

**Estimated effort:** 4 hours

### Task 5: Update Orchestrator

**File:** `functions/src/ai-pipeline/gemini/orchestrator.ts`

- Now calls `processItemWithGeminiPersistent()` instead of `processItemWithGemini()`
- Passes `itemId` for history tracking
- Passes `additionalImageUrls` for multi-image support
- Flattens catalog results to top-level Firestore fields

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
| Data Model | **Implemented** | `functions/src/ai-pipeline/gemini/schemas/catalog-history.ts` |
| History Service | **Implemented** | `functions/src/ai-pipeline/gemini/catalog-history-service.ts` |
| Context Cache Service | **Implemented** | `functions/src/ai-pipeline/gemini/context-cache-service.ts` |
| Gemini Service Updates | **Implemented** | `processItemWithGeminiPersistent()` in `gemini-service.ts` |
| Orchestrator Updates | **Implemented** | Now uses persistent processing |
| Firestore Indexes | **Implemented** | `catalogHistory` index in `firestore.indexes.json` |
| Tests | **Implemented** | Unit tests for history and cache services |

**Overall Status:** IMPLEMENTED

**Implementation Plan:** `docs/plans/2026-01-18-hybrid-session-persistence.md`

---

## Implementation Details

### Files Created/Modified

| File | Purpose |
|------|---------|
| `functions/src/ai-pipeline/gemini/schemas/catalog-history.ts` | Data model interfaces |
| `functions/src/ai-pipeline/gemini/schemas/index.ts` | Schema exports |
| `functions/src/ai-pipeline/gemini/catalog-history-service.ts` | History CRUD operations |
| `functions/src/ai-pipeline/gemini/context-cache-service.ts` | Gemini context caching |
| `functions/src/ai-pipeline/gemini/gemini-service.ts` | Added `processItemWithGeminiPersistent()` |
| `functions/src/ai-pipeline/gemini/orchestrator.ts` | Updated to use persistent processing |
| `firestore.indexes.json` | Added catalogHistory index |
| `functions/src/ai-pipeline/gemini/__tests__/catalog-history-service.test.ts` | Unit tests |
| `functions/src/ai-pipeline/gemini/__tests__/context-cache-service.test.ts` | Unit tests |

### Key Functions

**catalog-history-service.ts:**
- `saveCatalogHistory(itemId, entry: SaveCatalogHistoryInput)` - Persist catalog result to history (auto-adds `catalogedAt`, auto-prunes old entries)
- `getRecentCatalogHistory(itemId, limit = 1)` - Retrieve recent history entries, newest first
- `catalogItemToSnapshot(item: CatalogItem)` - Convert CatalogItem to CatalogResultSnapshot
- `formatHistoryForPrompt(history: CatalogHistoryEntry[])` - Format history as prompt prefix text

**context-cache-service.ts:**
- `getOrCreateContextCache()` - Get/create cached context for system prompt + tools (1-hour TTL)
- `listContextCaches()` - List existing caches (debugging/monitoring)
- `deleteContextCache(name)` - Delete specific cache by name
- `estimateTokenSavings()` - Cost analysis utility (~2300 tokens, 90% savings)
- `clearCacheReference()` - Clear in-memory cache (testing/force refresh)

**gemini-service.ts:**
- `processItemWithGeminiPersistent(imageUrl, itemId?, useContextCache?, additionalImageUrls?)` - Main entry point with persistence and multi-image support

### Firestore Path

```
items/{itemId}/catalogHistory/{entryId}
```

### Configuration

- **MAX_HISTORY_ENTRIES:** 10 (auto-cleanup of older entries via `cleanupOldEntries()`)
- **CACHE_TTL_SECONDS:** 3600 (1 hour, with in-memory reference tracking)
- **Estimated token savings:** 90% on cached system prompt + tools (~2300 tokens)
- **History fetch limit:** Default 1 (most recent entry only for prompt injection)

---

## References

- [SPEC-ARCH-002: Layer 1 / Layer 2 Pipeline Architecture](./SPEC-ARCH-002-layer1-layer2-pipeline.md)
- [Gemini Context Caching Documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/context-caching)
- gemini-service.ts: `functions/src/ai-pipeline/gemini/gemini-service.ts`
- prompts.ts: `functions/src/ai-pipeline/gemini/prompts.ts`

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-18 | 1.0 | Initial design spec |
| 2026-01-18 | 1.1 | Implementation complete - all components implemented |

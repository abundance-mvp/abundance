# Hybrid Session Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use backend-superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enable Gemini to remember previous catalog results when users add photos or request re-cataloging, using a hybrid approach of Firestore history + Context Caching.

**Architecture:** Store previous Layer 2 results in Firestore per-item, use Gemini Explicit Context Caching for system prompts (90% token savings), and construct prompts with previous context for updates.

**Tech Stack:** TypeScript (Firebase Functions), Firestore, Gemini 3 Pro API, @google/genai SDK

---

## Background

**Current State:** Each Layer 2 call in `gemini-service.ts:40-51` is stateless:

```typescript
let contents: Content[] = [{
  role: 'user',
  parts: [
    { text: 'Analyze this image and create catalog entry(ies).' },
    { inlineData: { mimeType: 'image/jpeg', data: imageBase64 } }
  ]
}];
```

**Problem:** When user adds more photos to an existing item or requests re-cataloging, Gemini has no memory of:

- Previous identification (brand, model)
- Previous tool calls and results
- Previous confidence assessments

**Solution:** Hybrid approach combining:

1. **Firestore History:** Store catalog results in `items/{itemId}/catalogHistory` subcollection
2. **Context Caching:** Cache system prompt + tool definitions (min 2048 tokens, 90% cost reduction)
3. **Context Injection:** Include previous results in new prompts for continuity

---

## Prerequisites

- Read: `docs/specs/SPEC-PIPE-003-session-persistence.md` (design spec)
- Gemini Context Caching API: <https://ai.google.dev/gemini-api/docs/caching>
- Current implementation: `functions/src/ai-pipeline/gemini/gemini-service.ts`

---

## Task 1: Create Catalog History Data Model

**Files:**

- Create: `functions/src/ai-pipeline/gemini/schemas/catalog-history.ts`
- Modify: `functions/src/ai-pipeline/gemini/schemas/catalog-item.ts:1-50`

**Step 1: Write the interface definition**

```typescript
// functions/src/ai-pipeline/gemini/schemas/catalog-history.ts

/**
 * Represents a single catalog history entry for an item.
 * Stored in Firestore subcollection: items/{itemId}/catalogHistory/{entryId}
 */
export interface CatalogHistoryEntry {
  /** Firestore document ID */
  id: string;

  /** Timestamp when this catalog was performed */
  catalogedAt: FirebaseFirestore.Timestamp;

  /** Gemini model used (e.g., 'gemini-3-pro-preview') */
  model: string;

  /** Image URLs processed in this catalog session */
  imageUrls: string[];

  /** Tool calls made during this session */
  toolCalls: ToolCallRecord[];

  /** Final catalog result */
  result: CatalogResultSnapshot;

  /** Processing metadata */
  metadata: {
    /** Total tokens used */
    totalTokens: number;
    /** Processing duration in ms */
    durationMs: number;
    /** Whether context cache was used */
    usedContextCache: boolean;
  };
}

/**
 * Record of a tool call made during cataloging
 */
export interface ToolCallRecord {
  /** Tool name (google_lens_search, barcode_lookup, web_search) */
  name: string;
  /** Arguments passed to the tool */
  args: Record<string, unknown>;
  /** Result returned by the tool */
  result: Record<string, unknown>;
  /** Whether the call succeeded */
  success: boolean;
}

/**
 * Snapshot of catalog result at a point in time
 */
export interface CatalogResultSnapshot {
  name: string;
  brand: string | null;
  model: string | null;
  category: string;
  subCategory: string | null;
  confidence: 'high' | 'medium' | 'low';
  estimatedValue: number | null;
  condition: string | null;
}
```

**Step 2: Verify the file was created**

Run: `ls -la functions/src/ai-pipeline/gemini/schemas/catalog-history.ts`
Expected: File exists

**Step 3: Export from schemas index**

Add to `functions/src/ai-pipeline/gemini/schemas/index.ts`:

```typescript
export * from './catalog-history';
```

**Step 4: Commit**

```bash
git add functions/src/ai-pipeline/gemini/schemas/
git commit -m "feat(ai-pipeline): add catalog history data model

- CatalogHistoryEntry interface for Firestore subcollection
- ToolCallRecord for tracking tool calls
- CatalogResultSnapshot for result snapshots

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Create Catalog History Service

**Files:**

- Create: `functions/src/ai-pipeline/gemini/catalog-history-service.ts`

**Step 1: Write the service**

```typescript
// functions/src/ai-pipeline/gemini/catalog-history-service.ts

/**
 * Service for managing catalog history in Firestore.
 * Enables session persistence by storing and retrieving previous catalog results.
 */

import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { CatalogHistoryEntry, ToolCallRecord, CatalogResultSnapshot } from './schemas/catalog-history';
import { CatalogItem } from './schemas/catalog-item';

const HISTORY_COLLECTION = 'catalogHistory';
const MAX_HISTORY_ENTRIES = 5; // Keep last 5 entries per item

/**
 * Save a catalog result to history.
 *
 * @param itemId - The item document ID
 * @param entry - The history entry to save (without id)
 * @returns The saved entry ID
 */
export async function saveCatalogHistory(
  itemId: string,
  entry: Omit<CatalogHistoryEntry, 'id'>
): Promise<string> {
  const db = getFirestore();
  const historyRef = db
    .collection('items')
    .doc(itemId)
    .collection(HISTORY_COLLECTION);

  // Add new entry
  const docRef = await historyRef.add({
    ...entry,
    catalogedAt: FieldValue.serverTimestamp()
  });

  // Cleanup old entries (keep only MAX_HISTORY_ENTRIES)
  await cleanupOldEntries(historyRef);

  return docRef.id;
}

/**
 * Get the most recent catalog history for an item.
 *
 * @param itemId - The item document ID
 * @param limit - Maximum entries to retrieve (default: 1)
 * @returns Array of history entries, newest first
 */
export async function getRecentCatalogHistory(
  itemId: string,
  limit: number = 1
): Promise<CatalogHistoryEntry[]> {
  const db = getFirestore();
  const snapshot = await db
    .collection('items')
    .doc(itemId)
    .collection(HISTORY_COLLECTION)
    .orderBy('catalogedAt', 'desc')
    .limit(limit)
    .get();

  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  } as CatalogHistoryEntry));
}

/**
 * Convert a CatalogItem to a CatalogResultSnapshot for storage.
 */
export function catalogItemToSnapshot(item: CatalogItem): CatalogResultSnapshot {
  return {
    name: item.name,
    brand: item.brand ?? null,
    model: item.model ?? null,
    category: item.category,
    subCategory: item.subCategory ?? null,
    confidence: item.confidence ?? 'medium',
    estimatedValue: item.estimatedValue ?? null,
    condition: item.condition ?? null
  };
}

/**
 * Format previous catalog history for inclusion in prompt.
 */
export function formatHistoryForPrompt(history: CatalogHistoryEntry[]): string {
  if (history.length === 0) {
    return '';
  }

  const latest = history[0];
  const result = latest.result;

  return `
PREVIOUS CATALOG INFORMATION:
This item was previously cataloged with the following information:
- Name: ${result.name}
- Brand: ${result.brand || 'Unknown'}
- Model: ${result.model || 'Unknown'}
- Category: ${result.category}
- Confidence: ${result.confidence}
${result.estimatedValue ? `- Estimated Value: $${result.estimatedValue}` : ''}
${result.condition ? `- Condition: ${result.condition}` : ''}

Previous tool calls:
${latest.toolCalls.map(tc => `- ${tc.name}: ${tc.success ? 'Success' : 'Failed'}`).join('\n')}

Use this context to maintain consistency. If new images provide clearer information,
you may update the identification, but explain why in your reasoning.
`;
}

/**
 * Remove old history entries beyond MAX_HISTORY_ENTRIES.
 */
async function cleanupOldEntries(
  historyRef: FirebaseFirestore.CollectionReference
): Promise<void> {
  const snapshot = await historyRef
    .orderBy('catalogedAt', 'desc')
    .offset(MAX_HISTORY_ENTRIES)
    .get();

  const batch = getFirestore().batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));

  if (snapshot.docs.length > 0) {
    await batch.commit();
  }
}
```

**Step 2: Verify the file was created**

Run: `ls -la functions/src/ai-pipeline/gemini/catalog-history-service.ts`
Expected: File exists

**Step 3: Commit**

```bash
git add functions/src/ai-pipeline/gemini/catalog-history-service.ts
git commit -m "feat(ai-pipeline): add catalog history service

- saveCatalogHistory() to persist results
- getRecentCatalogHistory() to retrieve previous context
- formatHistoryForPrompt() for context injection
- Auto-cleanup of old entries (keep last 5)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Implement Context Caching for System Prompt

**Files:**

- Create: `functions/src/ai-pipeline/gemini/context-cache-service.ts`
- Modify: `functions/src/ai-pipeline/gemini/prompts.ts` (extract cacheable content)

**Step 1: Write the context cache service**

```typescript
// functions/src/ai-pipeline/gemini/context-cache-service.ts

/**
 * Context Caching Service for Gemini 3 Pro
 *
 * Uses Gemini's Explicit Context Caching to cache system prompts and tool
 * definitions, achieving ~90% token cost reduction on repeated calls.
 *
 * Requirements:
 * - Minimum 2048 tokens for caching (our system prompt + tools exceeds this)
 * - Cache TTL: 1 hour minimum, up to 24 hours
 * - Cache is immutable - create new cache for prompt changes
 *
 * @see https://ai.google.dev/gemini-api/docs/caching
 */

import { GoogleGenAI, CachedContent } from '@google/genai';
import { createVertexAIClient } from './vertexai-config';
import { SYSTEM_PROMPT, CATALOG_TOOLS, GEMINI_MODEL_ID } from './prompts';

/** Cache TTL in seconds (1 hour) */
const CACHE_TTL_SECONDS = 3600;

/** In-memory reference to current cache (refresh on cold start) */
let currentCache: CachedContent | null = null;
let cacheExpiresAt: Date | null = null;

/**
 * Get or create a cached context for the system prompt and tools.
 *
 * @returns CachedContent object to use in generateContent calls
 */
export async function getOrCreateContextCache(): Promise<CachedContent> {
  // Check if we have a valid cache
  if (currentCache && cacheExpiresAt && new Date() < cacheExpiresAt) {
    return currentCache;
  }

  const ai = createVertexAIClient();

  // Create cached content with system prompt and tools
  // Note: The system prompt + tool definitions exceed 2048 tokens minimum
  const cachedContent = await ai.caches.create({
    model: GEMINI_MODEL_ID,
    config: {
      systemInstruction: SYSTEM_PROMPT,
      tools: CATALOG_TOOLS,
      ttl: `${CACHE_TTL_SECONDS}s`
    },
    displayName: 'abundance-catalog-context'
  });

  // Store reference and expiry
  currentCache = cachedContent;
  cacheExpiresAt = new Date(Date.now() + CACHE_TTL_SECONDS * 1000);

  console.log(`Created context cache: ${cachedContent.name}, expires: ${cacheExpiresAt.toISOString()}`);

  return cachedContent;
}

/**
 * List existing caches (for debugging/monitoring).
 */
export async function listContextCaches(): Promise<CachedContent[]> {
  const ai = createVertexAIClient();
  const caches: CachedContent[] = [];

  for await (const cache of ai.caches.list()) {
    caches.push(cache);
  }

  return caches;
}

/**
 * Delete a specific cache by name.
 */
export async function deleteContextCache(cacheName: string): Promise<void> {
  const ai = createVertexAIClient();
  await ai.caches.delete({ name: cacheName });
  console.log(`Deleted context cache: ${cacheName}`);

  // Clear local reference if it matches
  if (currentCache?.name === cacheName) {
    currentCache = null;
    cacheExpiresAt = null;
  }
}

/**
 * Check if context caching is available and beneficial.
 * Returns estimated token savings.
 */
export function estimateTokenSavings(): { systemTokens: number; savingsPercent: number } {
  // Rough estimate: system prompt ~1500 tokens, tools ~800 tokens
  const systemTokens = 2300;
  const savingsPercent = 90; // Per Google's documentation

  return { systemTokens, savingsPercent };
}
```

**Step 2: Verify the file was created**

Run: `ls -la functions/src/ai-pipeline/gemini/context-cache-service.ts`
Expected: File exists

**Step 3: Commit**

```bash
git add functions/src/ai-pipeline/gemini/context-cache-service.ts
git commit -m "feat(ai-pipeline): add Gemini context cache service

- getOrCreateContextCache() for cached system prompts
- 90% token cost reduction on repeated calls
- 1 hour TTL with auto-refresh
- Cache management utilities

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Modify Gemini Service to Use History and Cache

**Files:**

- Modify: `functions/src/ai-pipeline/gemini/gemini-service.ts`

**Step 1: Add imports**

Add to top of file after existing imports:

```typescript
import {
  saveCatalogHistory,
  getRecentCatalogHistory,
  formatHistoryForPrompt,
  catalogItemToSnapshot
} from './catalog-history-service';
import { getOrCreateContextCache } from './context-cache-service';
import { ToolCallRecord } from './schemas/catalog-history';
```

**Step 2: Create new function signature with itemId parameter**

Add new function (keep existing for backwards compatibility):

```typescript
/**
 * Process an image with session persistence.
 * Uses previous catalog history for context continuity.
 *
 * @param imageUrl - Public URL of the image to process
 * @param itemId - Optional item ID for history lookup (enables persistence)
 * @param useContextCache - Whether to use cached system prompt (default: true)
 * @returns CatalogItem or array of CatalogItems
 */
export async function processItemWithGeminiPersistent(
  imageUrl: string,
  itemId?: string,
  useContextCache: boolean = true
): Promise<CatalogItem | CatalogItem[]> {
  const startTime = Date.now();
  const toolCallRecords: ToolCallRecord[] = [];

  // Get previous history if itemId provided
  let historyContext = '';
  if (itemId) {
    const history = await getRecentCatalogHistory(itemId, 1);
    historyContext = formatHistoryForPrompt(history);
  }

  const imageBase64 = await fetchImageBase64(imageUrl);
  const ai = createVertexAIClient();

  // Build user prompt with optional history context
  const userPrompt = historyContext
    ? `${historyContext}\n\nAnalyze this NEW image and update/confirm the catalog entry.`
    : 'Analyze this image and create catalog entry(ies).';

  let contents: Content[] = [{
    role: 'user',
    parts: [
      { text: userPrompt },
      { inlineData: { mimeType: 'image/jpeg', data: imageBase64 } }
    ]
  }];

  // Use context cache if enabled
  let cachedContent;
  if (useContextCache) {
    try {
      cachedContent = await getOrCreateContextCache();
    } catch (err) {
      console.warn('Context cache unavailable, falling back to inline config:', err);
    }
  }

  const toolDeclarations = CATALOG_TOOLS.flatMap(t => t.functionDeclarations || []);

  // Configure request - use cache or inline config
  const requestConfig = cachedContent
    ? { cachedContent: cachedContent.name }
    : {
        systemInstruction: SYSTEM_PROMPT,
        tools: [{ functionDeclarations: toolDeclarations as any }],
        ...GENERATION_CONFIG
      };

  let response = await ai.models.generateContent({
    model: GEMINI_MODEL_ID,
    contents,
    config: requestConfig
  });

  let iterations = 0;
  const maxIterations = 10;

  while (iterations < maxIterations) {
    const functionCalls = response.functionCalls || [];

    if (functionCalls.length === 0) {
      break;
    }

    console.log(`Iteration ${iterations + 1}: Processing ${functionCalls.length} function call(s)`);

    const toolResults = await Promise.all(
      functionCalls.map(async (call: FunctionCall) => {
        const name = call.name || '';
        const args = call.args || {};
        let result: Record<string, unknown>;
        let success = true;

        try {
          result = await executeToolCall(name, args, imageUrl) as Record<string, unknown>;
        } catch (err) {
          result = { error: err instanceof Error ? err.message : 'Unknown error' };
          success = false;
        }

        // Record tool call for history
        toolCallRecords.push({ name, args, result, success });

        return {
          functionResponse: { name, response: result }
        };
      })
    );

    const modelParts = getModelPartsWithThoughtSignature(response);
    const userParts: Part[] = toolResults.map(r => ({ functionResponse: r.functionResponse }));

    contents = [
      ...contents,
      { role: 'model', parts: modelParts },
      { role: 'user', parts: userParts }
    ];

    response = await ai.models.generateContent({
      model: GEMINI_MODEL_ID,
      contents,
      config: requestConfig
    });

    iterations++;
  }

  const text = response.text;
  if (!text) {
    throw new Error(`No text response from Gemini after ${iterations} iterations`);
  }

  const catalogResult = JSON.parse(text) as CatalogItem | CatalogItem[];
  const durationMs = Date.now() - startTime;

  // Save to history if itemId provided
  if (itemId) {
    const resultItem = Array.isArray(catalogResult) ? catalogResult[0] : catalogResult;
    await saveCatalogHistory(itemId, {
      catalogedAt: null as any, // Will be set by FieldValue.serverTimestamp()
      model: GEMINI_MODEL_ID,
      imageUrls: [imageUrl],
      toolCalls: toolCallRecords,
      result: catalogItemToSnapshot(resultItem),
      metadata: {
        totalTokens: 0, // TODO: Extract from response.usageMetadata
        durationMs,
        usedContextCache: !!cachedContent
      }
    });
  }

  return catalogResult;
}
```

**Step 3: Run TypeScript compilation check**

Run: `cd functions && npx tsc --noEmit`
Expected: No errors

**Step 4: Commit**

```bash
git add functions/src/ai-pipeline/gemini/gemini-service.ts
git commit -m "feat(ai-pipeline): add persistent Gemini processing

- processItemWithGeminiPersistent() with session history
- Context injection from previous catalog results
- Tool call recording for history
- Optional context caching for 90% token savings
- Backwards compatible (original function unchanged)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Update Orchestrator to Use Persistent Processing

**Files:**

- Modify: `functions/src/ai-pipeline/gemini/orchestrator.ts`

**Step 1: Read current orchestrator**

Read: `functions/src/ai-pipeline/gemini/orchestrator.ts`

**Step 2: Update to use processItemWithGeminiPersistent**

Change the import and function call:

```typescript
// Change import
import { processItemWithGeminiPersistent } from './gemini-service';

// In the orchestrator function, change:
const catalogResult = await processItemWithGeminiPersistent(
  imageUrl,
  itemId,  // Pass itemId for history tracking
  true     // Use context cache
);
```

**Step 3: Run TypeScript compilation check**

Run: `cd functions && npx tsc --noEmit`
Expected: No errors

**Step 4: Commit**

```bash
git add functions/src/ai-pipeline/gemini/orchestrator.ts
git commit -m "feat(ai-pipeline): enable session persistence in orchestrator

- Use processItemWithGeminiPersistent for all Layer 2 processing
- Pass itemId for history tracking
- Enable context caching by default

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Add Firestore Indexes for History Queries

**Files:**

- Modify: `firestore.indexes.json`

**Step 1: Add index for catalogHistory subcollection**

Add to `indexes` array:

```json
{
  "collectionGroup": "catalogHistory",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "catalogedAt", "order": "DESCENDING" }
  ]
}
```

**Step 2: Deploy indexes**

Run: `firebase deploy --only firestore:indexes`
Expected: Indexes deployed successfully

**Step 3: Commit**

```bash
git add firestore.indexes.json
git commit -m "feat(firestore): add index for catalogHistory subcollection

- Enables efficient orderBy(catalogedAt, desc) queries
- Required for getRecentCatalogHistory()

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Write Unit Tests

**Files:**

- Create: `functions/src/ai-pipeline/gemini/__tests__/catalog-history-service.test.ts`
- Create: `functions/src/ai-pipeline/gemini/__tests__/context-cache-service.test.ts`

**Step 1: Write catalog history tests**

```typescript
// functions/src/ai-pipeline/gemini/__tests__/catalog-history-service.test.ts

import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  formatHistoryForPrompt,
  catalogItemToSnapshot
} from '../catalog-history-service';
import { CatalogHistoryEntry } from '../schemas/catalog-history';
import { CatalogItem } from '../schemas/catalog-item';

describe('catalog-history-service', () => {
  describe('catalogItemToSnapshot', () => {
    it('should convert CatalogItem to snapshot', () => {
      const item: CatalogItem = {
        name: 'Apple iPhone 15 Pro',
        brand: 'Apple',
        model: 'iPhone 15 Pro',
        category: 'electronics',
        subCategory: 'smartphones',
        confidence: 'high',
        estimatedValue: 999,
        condition: 'like-new'
      };

      const snapshot = catalogItemToSnapshot(item);

      expect(snapshot.name).toBe('Apple iPhone 15 Pro');
      expect(snapshot.brand).toBe('Apple');
      expect(snapshot.confidence).toBe('high');
    });

    it('should handle missing optional fields', () => {
      const item: CatalogItem = {
        name: 'Unknown Item',
        category: 'other'
      } as CatalogItem;

      const snapshot = catalogItemToSnapshot(item);

      expect(snapshot.brand).toBeNull();
      expect(snapshot.model).toBeNull();
      expect(snapshot.estimatedValue).toBeNull();
    });
  });

  describe('formatHistoryForPrompt', () => {
    it('should format history entry for prompt injection', () => {
      const history: CatalogHistoryEntry[] = [{
        id: 'test-id',
        catalogedAt: { toDate: () => new Date() } as any,
        model: 'gemini-3-pro-preview',
        imageUrls: ['https://example.com/image.jpg'],
        toolCalls: [
          { name: 'google_lens_search', args: {}, result: {}, success: true },
          { name: 'barcode_lookup', args: {}, result: {}, success: false }
        ],
        result: {
          name: 'Apple iPhone 15 Pro',
          brand: 'Apple',
          model: 'iPhone 15 Pro',
          category: 'electronics',
          subCategory: 'smartphones',
          confidence: 'high',
          estimatedValue: 999,
          condition: 'like-new'
        },
        metadata: {
          totalTokens: 1500,
          durationMs: 3000,
          usedContextCache: true
        }
      }];

      const prompt = formatHistoryForPrompt(history);

      expect(prompt).toContain('PREVIOUS CATALOG INFORMATION');
      expect(prompt).toContain('Apple iPhone 15 Pro');
      expect(prompt).toContain('Brand: Apple');
      expect(prompt).toContain('google_lens_search: Success');
      expect(prompt).toContain('barcode_lookup: Failed');
    });

    it('should return empty string for empty history', () => {
      const prompt = formatHistoryForPrompt([]);
      expect(prompt).toBe('');
    });
  });
});
```

**Step 2: Run tests**

Run: `cd functions && npm test -- catalog-history-service`
Expected: All tests pass

**Step 3: Commit**

```bash
git add functions/src/ai-pipeline/gemini/__tests__/
git commit -m "test(ai-pipeline): add catalog history service tests

- catalogItemToSnapshot conversion tests
- formatHistoryForPrompt tests
- Edge case handling

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Update SPEC-PIPE-003 with Implementation Details

**Files:**

- Update: `docs/specs/SPEC-PIPE-003-session-persistence.md` (after created by spec audit)

**Step 1: Add implementation section**

After the design spec is created by the spec audit, add implementation details:

- File locations
- Function signatures
- Firestore paths
- Context caching configuration

**Step 2: Commit**

```bash
git add docs/specs/SPEC-PIPE-003-session-persistence.md
git commit -m "docs: update SPEC-PIPE-003 with implementation details

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Deploy and Verify

**Step 1: Run full test suite**

Run: `cd functions && npm test`
Expected: All tests pass

**Step 2: Build for production**

Run: `cd functions && npm run build`
Expected: No errors

**Step 3: Deploy to staging**

Run: `firebase deploy --only functions --project abundance-mvp-staging`
Expected: Deployment successful

**Step 4: Verify with MCP tools**

Use Firebase MCP:

```
functions_list_functions
functions_get_logs function_names=["onItemCreatedGemini3"] min_severity="INFO" page_size=10
```

**Step 5: Test end-to-end**

1. Create a new item via iOS app
2. Wait for Layer 2 processing
3. Check Firestore for `catalogHistory` subcollection
4. Add another photo to same item
5. Verify prompt includes previous context

**Step 6: Commit final verification**

```bash
git add .
git commit -m "chore: verify hybrid session persistence deployment

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Catalog history data model | `schemas/catalog-history.ts` |
| 2 | History service | `catalog-history-service.ts` |
| 3 | Context cache service | `context-cache-service.ts` |
| 4 | Persistent Gemini processing | `gemini-service.ts` |
| 5 | Orchestrator update | `orchestrator.ts` |
| 6 | Firestore indexes | `firestore.indexes.json` |
| 7 | Unit tests | `__tests__/*.test.ts` |
| 8 | Spec update | `SPEC-PIPE-003-session-persistence.md` |
| 9 | Deploy and verify | (deployment) |

**Estimated Token Savings:** 90% reduction on repeated Layer 2 calls (~$0.036 → ~$0.004 per call)

**Data Model:**

- `items/{itemId}/catalogHistory/{entryId}` - Subcollection for history entries
- Max 5 entries per item (auto-cleanup)

---

## Execution Options

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?

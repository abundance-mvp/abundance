# Spec Updates for Session Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update spec documents to reflect the implemented context-cache and gemini-persistent features.

**Architecture:** Three specs need updates: SPEC-PIPE-002 (Layer 2 Cataloging) needs a new section documenting the persistent processing function; SPEC-PIPE-003 (Session Persistence) needs status update from "Planned" to "Implemented" and MAX_HISTORY_ENTRIES correction; README.md needs status update.

**Tech Stack:** Markdown documentation

---

## Task 1: Update SPEC-PIPE-003 Status and MAX_HISTORY_ENTRIES

**Files:**
- Modify: `docs/specs/SPEC-PIPE-003-session-persistence.md:4` (status)
- Modify: `docs/specs/SPEC-PIPE-003-session-persistence.md:150` (retention count)
- Modify: `docs/specs/SPEC-PIPE-003-session-persistence.md:632` (config section)

**Step 1: Update spec status from Planned to Implemented**

Change line 4:
```markdown
**Status:** Planned
```
To:
```markdown
**Status:** Implemented
```

**Step 2: Update retention policy count from 10 to match implementation**

The spec at line 150 says "Most recent 10 entries" but we just changed implementation to 10 (from 5). Verify this is now consistent - no change needed.

**Step 3: Update configuration section at line 632**

Change:
```markdown
- **MAX_HISTORY_ENTRIES:** 5 (auto-cleanup of older entries)
```
To:
```markdown
- **MAX_HISTORY_ENTRIES:** 10 (auto-cleanup of older entries, matches retention policy)
```

**Step 4: Commit**

```bash
git add docs/specs/SPEC-PIPE-003-session-persistence.md
git commit -m "docs: update SPEC-PIPE-003 status to Implemented and fix MAX_HISTORY_ENTRIES"
```

---

## Task 2: Update README.md Spec Index

**Files:**
- Modify: `docs/specs/README.md:39`

**Step 1: Update SPEC-PIPE-003 status in spec index**

Change line 39:
```markdown
| [SPEC-PIPE-003](../specs/SPEC-PIPE-003-session-persistence.md) | Session Persistence | **Planned** | Hybrid context caching design spec |
```
To:
```markdown
| [SPEC-PIPE-003](../specs/SPEC-PIPE-003-session-persistence.md) | Session Persistence | **Implemented** | Hybrid context caching with Firestore history |
```

**Step 2: Commit**

```bash
git add docs/specs/README.md
git commit -m "docs: update SPEC-PIPE-003 status to Implemented in README"
```

---

## Task 3: Add Session Persistence Section to SPEC-PIPE-002

**Files:**
- Modify: `docs/specs/SPEC-PIPE-002-layer2-cataloging.md` (add new section before section 7)

**Step 1: Add new section documenting processItemWithGeminiPersistent**

Insert after line 661 (after `processItemWithGemini` function ends), add new section:

```markdown

### Session Persistence Mode

For items requiring context continuity across multiple catalog attempts, use `processItemWithGeminiPersistent()`:

**Reference:** [SPEC-PIPE-003: Session Persistence](../specs/SPEC-PIPE-003-session-persistence.md)

```typescript
export async function processItemWithGeminiPersistent(
  imageUrl: string,
  itemId?: string,
  useContextCache: boolean = true
): Promise<CatalogItem | CatalogItem[]>
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `imageUrl` | string | Public URL of the image to process |
| `itemId` | string? | Optional item ID for history lookup/save |
| `useContextCache` | boolean | Whether to use cached system prompt (default: true) |

**Features:**

1. **History Context Injection** - When `itemId` is provided, fetches recent catalog history and injects it into the prompt
2. **Context Caching** - Caches system prompt + tool definitions for ~90% token cost reduction
3. **Tool Call Recording** - Records all tool calls (including failures) for history
4. **Token Tracking** - Accumulates `totalTokenCount` across all iterations
5. **Auto-Save** - Saves catalog result to history subcollection after processing

**History Storage:**

```
items/{itemId}/catalogHistory/{entryId}
```

Each entry contains:
- `catalogedAt` - Timestamp
- `model` - Gemini model ID
- `imageUrls` - Images processed
- `toolCalls` - Array of tool call records
- `result` - CatalogResultSnapshot
- `metadata` - Token count, duration, cache usage

**Cost Savings:**

| Scenario | Without Persistence | With Persistence |
|----------|---------------------|------------------|
| First catalog | ~$0.04 | ~$0.044 |
| Subsequent catalogs | ~$0.04 | ~$0.016 |
| 3 catalogs total | ~$0.12 | ~$0.076 (37% savings) |

```

**Step 2: Update Table of Contents**

At line 8, after the existing ToC entries, the section numbers may need adjustment. The new section "Session Persistence Mode" should be documented if there's a ToC.

**Step 3: Commit**

```bash
git add docs/specs/SPEC-PIPE-002-layer2-cataloging.md
git commit -m "docs: add Session Persistence Mode section to SPEC-PIPE-002"
```

---

## Task 4: Add Key Files to SPEC-PIPE-002

**Files:**
- Modify: `docs/specs/SPEC-PIPE-002-layer2-cataloging.md:72-82` (Key Files table)

**Step 1: Add new files to the Key Files table**

After line 82 (after web-search.ts row), add:

```markdown
| `functions/src/ai-pipeline/gemini/catalog-history-service.ts` | Catalog history CRUD |
| `functions/src/ai-pipeline/gemini/context-cache-service.ts` | Gemini context caching |
| `functions/src/ai-pipeline/gemini/schemas/catalog-history.ts` | History data models |
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-PIPE-002-layer2-cataloging.md
git commit -m "docs: add session persistence files to SPEC-PIPE-002 Key Files"
```

---

## Task 5: Update Cost Estimates in SPEC-PIPE-002

**Files:**
- Modify: `docs/specs/SPEC-PIPE-002-layer2-cataloging.md` (section 9, after line 935)

**Step 1: Add note about cost savings with session persistence**

After the cost breakdown table (around line 936), add:

```markdown

**With Session Persistence:**

When using `processItemWithGeminiPersistent()`, subsequent catalogs of the same item achieve significant cost savings through context caching and tool call deduplication. See [SPEC-PIPE-003](../specs/SPEC-PIPE-003-session-persistence.md#cost-savings-analysis) for detailed analysis.
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-PIPE-002-layer2-cataloging.md
git commit -m "docs: add session persistence cost savings reference to SPEC-PIPE-002"
```

---

## Task 6: Add Related Specification Link

**Files:**
- Modify: `docs/specs/SPEC-PIPE-002-layer2-cataloging.md` (end of file, Related Specifications section)

**Step 1: Add SPEC-PIPE-003 to Related Specifications**

At the end of the Related Specifications section (after line 1109), add:

```markdown
- [SPEC-PIPE-003: Session Persistence](../specs/SPEC-PIPE-003-session-persistence.md)
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-PIPE-002-layer2-cataloging.md
git commit -m "docs: add SPEC-PIPE-003 to Related Specifications in SPEC-PIPE-002"
```

---

## Task 7: Final Verification

**Step 1: Verify all spec links work**

```bash
# Check for broken links
grep -r "SPEC-PIPE-003" docs/specs/*.md
```

**Step 2: Verify consistency**

Check that:
- SPEC-PIPE-003 status is "Implemented"
- README shows "Implemented"
- MAX_HISTORY_ENTRIES is consistently 10
- All file references exist

**Step 3: Run any doc linting (if available)**

```bash
# If markdownlint is available
npx markdownlint docs/specs/*.md || true
```

**Step 4: Final commit (if any fixes needed)**

```bash
git add docs/specs/
git commit -m "docs: fix any spec inconsistencies"
```

---

## Summary of Changes

| File | Changes |
|------|---------|
| `SPEC-PIPE-003-session-persistence.md` | Status → Implemented, MAX_HISTORY_ENTRIES → 10 |
| `README.md` | Status → Implemented in index table |
| `SPEC-PIPE-002-layer2-cataloging.md` | Add Session Persistence Mode section, Key Files, cost reference, related spec link |

---

## Estimated Total Time

- Task 1: 2 minutes
- Task 2: 1 minute
- Task 3: 5 minutes
- Task 4: 2 minutes
- Task 5: 2 minutes
- Task 6: 1 minute
- Task 7: 3 minutes

**Total: ~16 minutes**

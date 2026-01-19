# Plan: Legacy Pipeline Cleanup (Complete Deprecation)

**Date:** 2026-01-18
**Status:** Ready for execution
**Risk:** Low (code cleanup only - functions already disabled)
**Supersedes:** 2026-01-17-deprecate-legacy-pipeline.md

## Executive Summary

The legacy 4-layer AI pipeline functions are **already disabled in production** but the source code remains in the repository. This plan completes the deprecation by removing dead code.

### Current State (Verified via MCP)

| Item | Status | Evidence |
|------|--------|----------|
| Legacy triggers deployed | **NO** | `functions_list_functions` shows no `onItemCreated`, `onLayer2aComplete`, `onLayer2bComplete` |
| Legacy exports in index.ts | **YES** | Lines 8-10, 186-188 still import/export legacy triggers |
| Legacy trigger files | **YES** | 3 files: `onItemCreated.ts`, `onLayer2aComplete.ts`, `onLayer2bComplete.ts` |
| Legacy layer2a/2b/3 code | **YES** | 8 source files + 7 test files |
| Legacy providers | **YES** | 5 source files + 6 test files |
| Gemini 3 pipeline active | **YES** | `onItemCreatedGemini3` deployed and running |

---

## Execution Plan

### Phase 1: Remove Legacy Exports from index.ts

**Executor:** `backend-superpowers:execute-plans`

#### Step 1.1: Edit index.ts

Remove legacy imports (lines 8-10):
```typescript
// DELETE these lines:
import { onItemCreated } from './triggers/onItemCreated';
import { onLayer2aComplete } from './triggers/onLayer2aComplete';
import { onLayer2bComplete } from './triggers/onLayer2bComplete';
```

Remove legacy exports (lines 186-188):
```typescript
// DELETE from export block:
  onItemCreated,
  onLayer2aComplete,
  onLayer2bComplete,
```

#### Step 1.2: Verify Build

```bash
cd /Users/w/code/abundance-mvp/functions && npm run build
```

**Success criteria:** Build completes with no errors

---

### Phase 2: Delete Legacy Trigger Files

**Executor:** `backend-superpowers:execute-plans`

#### Step 2.1: Delete files

```bash
trash functions/src/triggers/onItemCreated.ts
trash functions/src/triggers/onLayer2aComplete.ts
trash functions/src/triggers/onLayer2bComplete.ts
```

#### Step 2.2: Verify no broken imports

```bash
cd /Users/w/code/abundance-mvp/functions && npm run build
```

---

### Phase 3: Delete Legacy Pipeline Code

**Executor:** `backend-superpowers:execute-plans`

#### Step 3.1: Delete layer2a directory

```bash
trash functions/src/ai-pipeline/layer2a
```

Files removed:
- `extractAttributes.ts`
- `__tests__/extractAttributes.test.ts`

#### Step 3.2: Delete layer2b directory

```bash
trash functions/src/ai-pipeline/layer2b
```

Files removed:
- `identifyProduct.ts`
- `BarcodeHybridLookup.ts`
- `__tests__/identifyProduct.test.ts`
- `__tests__/BarcodeHybridLookup.test.ts`
- `__tests__/BarcodeHybridLookup.edge-cases.test.ts`

#### Step 3.3: Delete layer3 directory

```bash
trash functions/src/ai-pipeline/layer3
```

Files removed:
- `synthesize.ts`
- `__tests__/synthesize.test.ts`
- `__tests__/synthesize.edge-cases.test.ts`

---

### Phase 4: Delete Legacy Providers

**Executor:** `backend-superpowers:execute-plans`

#### Step 4.1: Delete Claude providers

```bash
trash functions/src/ai-pipeline/providers/ClaudeHaikuProvider.ts
trash functions/src/ai-pipeline/providers/ClaudeSonnetProvider.ts
trash functions/src/ai-pipeline/providers/__tests__/ClaudeHaikuProvider.test.ts
trash functions/src/ai-pipeline/providers/__tests__/ClaudeSonnetProvider.test.ts
```

#### Step 4.2: Delete external API providers

```bash
trash functions/src/ai-pipeline/providers/SerpAPIProvider.ts
trash functions/src/ai-pipeline/providers/OpenFoodFactsProvider.ts
trash functions/src/ai-pipeline/providers/UPCitemdbProvider.ts
trash functions/src/ai-pipeline/providers/__tests__/SerpAPIProvider.test.ts
trash functions/src/ai-pipeline/providers/__tests__/OpenFoodFactsProvider.test.ts
trash functions/src/ai-pipeline/providers/__tests__/OpenFoodFactsProvider.rate-limit.test.ts
trash functions/src/ai-pipeline/providers/__tests__/UPCitemdbProvider.test.ts
```

#### Step 4.3: Keep GeminiProvider

The following file is **KEPT** (may be used by layer1):
- `functions/src/ai-pipeline/providers/GeminiProvider.ts`
- `functions/src/ai-pipeline/providers/__tests__/GeminiProvider.test.ts`

---

### Phase 5: Verify and Test

**Executor:** `backend-superpowers:execute-plans`

#### Step 5.1: Run full test suite

```bash
cd /Users/w/code/abundance-mvp/functions && npm test
```

**Success criteria:** All tests pass

#### Step 5.2: Run build

```bash
cd /Users/w/code/abundance-mvp/functions && npm run build
```

**Success criteria:** Build succeeds with no errors

#### Step 5.3: Verify deployed functions (MCP)

Use `mcp__plugin_firebase_firebase__functions_list_functions` to confirm:
- `onItemCreatedGemini3` still deployed
- No legacy function names appear

#### Step 5.4: Check recent logs (MCP)

Use `mcp__plugin_firebase_firebase__functions_get_logs`:
```json
{
  "function_names": ["onItemCreatedGemini3"],
  "min_severity": "WARNING",
  "page_size": 20
}
```

**Success criteria:** No new errors since cleanup

---

### Phase 6: Remove Anthropic Dependency

**Executor:** `backend-superpowers:execute-plans`

#### Step 6.1: Check for remaining Anthropic usage

```bash
rg "@anthropic-ai/sdk" functions/src/
rg "Anthropic" functions/src/
```

**If no results:** Proceed to Step 6.2

#### Step 6.2: Uninstall Anthropic SDK

```bash
cd /Users/w/code/abundance-mvp/functions && npm uninstall @anthropic-ai/sdk
```

#### Step 6.3: Remove secret (OPTIONAL)

```bash
firebase functions:secrets:destroy ANTHROPIC_API_KEY
```

**WARNING:** Only do this if confirmed unused. Prefer keeping secret for now.

---

### Phase 7: Commit Changes

**Executor:** Git commit via Claude Code

```bash
git add -A
git commit -m "chore(ai-pipeline): remove legacy 4-layer pipeline code

BREAKING CHANGE: Removed legacy AI pipeline code (already disabled in production)

Removed:
- onItemCreated, onLayer2aComplete, onLayer2bComplete triggers
- layer2a/ (extractAttributes via old Gemini)
- layer2b/ (identifyProduct via Claude Haiku)
- layer3/ (synthesize via Claude Sonnet)
- Legacy providers (ClaudeHaiku, ClaudeSonnet, SerpAPI, OpenFoodFacts, UPCitemdb)

Kept:
- onItemCreatedGemini3 (active production pipeline)
- layer1/ (on-device detection)
- GeminiProvider (may be used by layer1)

The new Gemini 3 Pro pipeline handles all cataloging in a single
function call with native tool use.

Refs: docs/plans/2026-01-18-legacy-pipeline-cleanup.md"
```

---

## Verification Checklist (MCP-Powered)

| Phase | Check | MCP Tool | Status |
|-------|-------|----------|--------|
| Pre-flight | Gemini 3 deployed | `functions_list_functions` | ✅ Verified |
| Pre-flight | Legacy NOT deployed | `functions_list_functions` | ✅ Verified |
| Phase 1 | index.ts exports cleaned | `npm run build` | ⬜ Pending |
| Phase 2 | Trigger files deleted | `Glob` | ⬜ Pending |
| Phase 3 | Layer code deleted | `Glob` | ⬜ Pending |
| Phase 4 | Providers deleted | `Glob` | ⬜ Pending |
| Phase 5 | Tests pass | `npm test` | ⬜ Pending |
| Phase 5 | Build succeeds | `npm run build` | ⬜ Pending |
| Phase 5 | Functions healthy | `functions_get_logs` | ⬜ Pending |
| Phase 6 | Anthropic removed | `npm ls @anthropic-ai/sdk` | ⬜ Pending |
| Phase 7 | Changes committed | `git status` | ⬜ Pending |

---

## Rollback Plan

**Not needed** - this is code cleanup only. Legacy functions are already disabled in production.

If build/tests fail during cleanup:
1. `git checkout -- functions/` to restore files
2. Investigate which file is still referenced
3. Update plan and retry

---

## Files Summary

### Files to DELETE (23 total)

**Triggers (3):**
- `functions/src/triggers/onItemCreated.ts`
- `functions/src/triggers/onLayer2aComplete.ts`
- `functions/src/triggers/onLayer2bComplete.ts`

**Layer2a (2):**
- `functions/src/ai-pipeline/layer2a/extractAttributes.ts`
- `functions/src/ai-pipeline/layer2a/__tests__/extractAttributes.test.ts`

**Layer2b (5):**
- `functions/src/ai-pipeline/layer2b/identifyProduct.ts`
- `functions/src/ai-pipeline/layer2b/BarcodeHybridLookup.ts`
- `functions/src/ai-pipeline/layer2b/__tests__/identifyProduct.test.ts`
- `functions/src/ai-pipeline/layer2b/__tests__/BarcodeHybridLookup.test.ts`
- `functions/src/ai-pipeline/layer2b/__tests__/BarcodeHybridLookup.edge-cases.test.ts`

**Layer3 (3):**
- `functions/src/ai-pipeline/layer3/synthesize.ts`
- `functions/src/ai-pipeline/layer3/__tests__/synthesize.test.ts`
- `functions/src/ai-pipeline/layer3/__tests__/synthesize.edge-cases.test.ts`

**Providers (10):**
- `functions/src/ai-pipeline/providers/ClaudeHaikuProvider.ts`
- `functions/src/ai-pipeline/providers/ClaudeSonnetProvider.ts`
- `functions/src/ai-pipeline/providers/SerpAPIProvider.ts`
- `functions/src/ai-pipeline/providers/OpenFoodFactsProvider.ts`
- `functions/src/ai-pipeline/providers/UPCitemdbProvider.ts`
- `functions/src/ai-pipeline/providers/__tests__/ClaudeHaikuProvider.test.ts`
- `functions/src/ai-pipeline/providers/__tests__/ClaudeSonnetProvider.test.ts`
- `functions/src/ai-pipeline/providers/__tests__/SerpAPIProvider.test.ts`
- `functions/src/ai-pipeline/providers/__tests__/OpenFoodFactsProvider.test.ts`
- `functions/src/ai-pipeline/providers/__tests__/OpenFoodFactsProvider.rate-limit.test.ts`
- `functions/src/ai-pipeline/providers/__tests__/UPCitemdbProvider.test.ts`

### Files to KEEP

- `functions/src/ai-pipeline/gemini/` - New Gemini 3 Pro pipeline
- `functions/src/ai-pipeline/tools/` - Tool implementations
- `functions/src/ai-pipeline/layer1/` - On-device detection
- `functions/src/ai-pipeline/cost-tracking/` - Cost logging
- `functions/src/ai-pipeline/providers/GeminiProvider.ts` - May be used by layer1
- `functions/src/ai-pipeline/__tests__/integration-setup.ts` - Shared test utils
- `functions/src/triggers/onItemCreatedGemini3.ts` - Active pipeline

---

## Cost Impact

Already realized - legacy functions were disabled on 2026-01-17.

**Savings:** ~45% reduction in AI costs per item (from ~$0.07 to ~$0.038)

# Plan: Deprecate Legacy 4-Layer AI Pipeline

**Date:** 2026-01-17
**Status:** Ready for execution
**Risk:** Medium (production change)

## Background

The Stage 7.0 Gemini 3 Pro pipeline is fully implemented, but the legacy 4-layer pipeline (Gemini Flash → Claude Haiku → Claude Sonnet) is still deployed and running in parallel. This causes:

1. **Double billing** - Both pipelines process every item
2. **Confusion** - Two sets of results may conflict
3. **Unnecessary complexity** - Legacy code still maintained

## Current State

### Deployed Cloud Functions (BOTH active)
| Function | Pipeline | Trigger |
|----------|----------|---------|
| `onItemCreated` | Legacy | `items/{itemId}` create |
| `onLayer2aComplete` | Legacy | `items/{itemId}` update (layer2a done) |
| `onLayer2bComplete` | Legacy | `items/{itemId}` update (layer2b done) |
| `onItemCreatedGemini3` | **NEW** | `items/{itemId}` create |

### Legacy Files to Remove
```
functions/src/
├── ai-pipeline/
│   ├── layer2a/                    # DELETE
│   │   ├── extractAttributes.ts
│   │   └── __tests__/
│   ├── layer2b/                    # DELETE
│   │   ├── identifyProduct.ts
│   │   ├── BarcodeHybridLookup.ts
│   │   └── __tests__/
│   ├── layer3/                     # DELETE
│   │   ├── synthesize.ts
│   │   └── __tests__/
│   └── providers/                  # DELETE (except GeminiProvider if needed elsewhere)
│       ├── ClaudeHaikuProvider.ts
│       ├── ClaudeSonnetProvider.ts
│       ├── SerpAPIProvider.ts
│       ├── OpenFoodFactsProvider.ts
│       ├── UPCitemdbProvider.ts
│       └── __tests__/
├── triggers/
│   ├── onItemCreated.ts            # DELETE
│   ├── onLayer2aComplete.ts        # DELETE
│   └── onLayer2bComplete.ts        # DELETE
```

---

## Execution Plan

### Phase 1: Stop Legacy Functions (Immediate)

**Step 1.1: Update index.ts to remove legacy exports**

Edit `functions/src/index.ts`:

```typescript
// REMOVE these imports (lines 8-10):
// import { onItemCreated } from './triggers/onItemCreated';
// import { onLayer2aComplete } from './triggers/onLayer2aComplete';
// import { onLayer2bComplete } from './triggers/onLayer2bComplete';

// CHANGE the export block (lines 185-193) to:
export {
  // onItemCreated,        // REMOVED - legacy
  // onLayer2aComplete,    // REMOVED - legacy
  // onLayer2bComplete,    // REMOVED - legacy
  onItemCreatedGemini3,
  onItemDeleted,
  onSessionCreated,
  onItemFromSession
};
```

**Step 1.2: Deploy to remove legacy functions**

```bash
cd /Users/w/code/abundance-mvp/functions
npm run build
firebase deploy --only functions
```

**Step 1.3: Verify legacy functions are deleted**

```bash
firebase functions:list
# Should NOT show: onItemCreated, onLayer2aComplete, onLayer2bComplete
# Should show: onItemCreatedGemini3
```

### Phase 2: Verify New Pipeline Works (1-2 days)

**Step 2.1: Test item creation**
- Create a new item via the app
- Verify `onItemCreatedGemini3` processes it
- Check Firestore for correct `catalog` field structure

**Step 2.2: Monitor logs**
```bash
firebase functions:log --only onItemCreatedGemini3
```

**Step 2.3: Check for errors**
- No legacy trigger errors
- Gemini 3 Pro completing successfully
- Tool calls working (google_lens, barcode_lookup, web_search)

### Phase 3: Remove Legacy Code (After verification)

**Step 3.1: Delete legacy trigger files**
```bash
rm functions/src/triggers/onItemCreated.ts
rm functions/src/triggers/onLayer2aComplete.ts
rm functions/src/triggers/onLayer2bComplete.ts
rm -rf functions/src/triggers/__tests__/error-scenarios.test.ts  # if legacy-specific
```

**Step 3.2: Delete legacy pipeline code**
```bash
rm -rf functions/src/ai-pipeline/layer2a
rm -rf functions/src/ai-pipeline/layer2b
rm -rf functions/src/ai-pipeline/layer3
```

**Step 3.3: Delete legacy providers**
```bash
rm functions/src/ai-pipeline/providers/ClaudeHaikuProvider.ts
rm functions/src/ai-pipeline/providers/ClaudeSonnetProvider.ts
rm functions/src/ai-pipeline/providers/SerpAPIProvider.ts
rm functions/src/ai-pipeline/providers/OpenFoodFactsProvider.ts
rm functions/src/ai-pipeline/providers/UPCitemdbProvider.ts
rm -rf functions/src/ai-pipeline/providers/__tests__/ClaudeHaikuProvider.test.ts
rm -rf functions/src/ai-pipeline/providers/__tests__/ClaudeSonnetProvider.test.ts
rm -rf functions/src/ai-pipeline/providers/__tests__/SerpAPIProvider.test.ts
rm -rf functions/src/ai-pipeline/providers/__tests__/OpenFoodFactsProvider.test.ts
rm -rf functions/src/ai-pipeline/providers/__tests__/OpenFoodFactsProvider.rate-limit.test.ts
rm -rf functions/src/ai-pipeline/providers/__tests__/UPCitemdbProvider.test.ts
```

**Step 3.4: Keep these files (still used)**
```
functions/src/ai-pipeline/
├── gemini/                 # NEW - Gemini 3 Pro pipeline
├── tools/                  # NEW - Tool implementations
├── layer1/                 # KEEP - On-device detection (separate concern)
├── cost-tracking/          # KEEP - Cost logging
├── providers/
│   └── GeminiProvider.ts   # EVALUATE - may be used by layer1
└── __tests__/
    └── integration-setup.ts  # KEEP
```

**Step 3.5: Update any remaining imports**

Search for and remove any imports of deleted files:
```bash
grep -r "layer2a\|layer2b\|layer3\|ClaudeHaiku\|ClaudeSonnet" functions/src/
```

**Step 3.6: Run tests and build**
```bash
cd /Users/w/code/abundance-mvp/functions
npm test
npm run build
```

**Step 3.7: Commit cleanup**
```bash
git add -A
git commit -m "chore(ai-pipeline): remove legacy 4-layer pipeline

BREAKING CHANGE: Removed legacy AI pipeline in favor of Gemini 3 Pro

Removed:
- onItemCreated trigger (replaced by onItemCreatedGemini3)
- onLayer2aComplete, onLayer2bComplete triggers
- layer2a/ (extractAttributes via old Gemini)
- layer2b/ (identifyProduct via Claude Haiku)
- layer3/ (synthesize via Claude Sonnet)
- Legacy providers (ClaudeHaiku, ClaudeSonnet, SerpAPI, etc.)

The new Gemini 3 Pro pipeline handles all cataloging in a single
function call with native tool use.

Refs: docs/plans/2026-01-14-stage-7.0-gemini-3-pro-implementation.md"
```

### Phase 4: Remove Anthropic Dependency (Optional)

If Claude is no longer used anywhere:

**Step 4.1: Remove from package.json**
```bash
cd /Users/w/code/abundance-mvp/functions
npm uninstall @anthropic-ai/sdk
```

**Step 4.2: Remove API key from Firebase secrets**
```bash
firebase functions:secrets:destroy ANTHROPIC_API_KEY
```

---

## Rollback Plan

If issues occur after Phase 1:

1. **Revert index.ts** to re-export legacy triggers
2. **Redeploy**: `firebase deploy --only functions`
3. **Investigate** logs before retrying

---

## Verification Checklist

- [ ] Phase 1: Legacy exports removed from index.ts
- [ ] Phase 1: `firebase deploy` successful
- [ ] Phase 1: Legacy functions no longer in `firebase functions:list`
- [ ] Phase 2: New item creation works
- [ ] Phase 2: Gemini 3 Pro logs show successful processing
- [ ] Phase 2: No double-processing observed
- [ ] Phase 3: Legacy code files deleted
- [ ] Phase 3: `npm test` passes
- [ ] Phase 3: `npm run build` succeeds
- [ ] Phase 4: Anthropic SDK removed (if applicable)

---

## Cost Impact

**Before (both pipelines):**
- Gemini Flash: ~$0.002/item
- Claude Haiku: ~$0.003/item
- Claude Sonnet: ~$0.015/item
- SerpAPI: ~$0.015/item
- **Total: ~$0.035/item × 2 pipelines = ~$0.07/item**

**After (Gemini 3 Pro only):**
- Gemini 3 Pro: ~$0.004/item
- Google Lens (SerpAPI): ~$0.015/item
- Web Search (Grounding): ~$0.014/item
- Barcode (UPCitemdb): ~$0.005/item
- **Total: ~$0.038/item**

**Savings: ~45% reduction in AI costs**

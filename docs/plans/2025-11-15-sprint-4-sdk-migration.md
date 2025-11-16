# Implementation Plan: Stage 3.4 SDK Migration

**Date**: 2025-11-15
**Objective**: Migrate 4 Stage 3.4 documents from deprecated @google-cloud/vertexai to current @google/genai SDK
**References**:

- docs/validation/RESEARCH-VALIDATION-stage-3.4-sdk-migration.md (technical verification)
- docs/tech-stack/GOOGLE-GENAI-SDK-USAGE.md (correct patterns)
- docs/validation/RESEARCH-VALIDATION-stage-4.3.md (SDK verification)

---

## Objective

**Goal**: Update all Stage 3.4 documentation to use @google/genai SDK (v1.29.0+) instead of deprecated @google-cloud/vertexai, unblocking Sprint 4 Layer 2a implementation planning.

**Scope**:

- 4 documents requiring refactoring
- 0 code changes (documentation only)
- 0 breaking changes to functionality
- All pricing and capabilities remain identical

---

## Scope

### Documents to Refactor

1. **CODE-EXAMPLE-010-vertex-ai-attribute-extraction.md** (620 lines)

   - Primary SDK integration example
   - Complete service implementation
   - Unit test examples
   - Package.json dependencies

2. **CODE-EXAMPLE-011-layer-2a-cloud-function.md** (698 lines)

   - Cloud Function implementation
   - Integration with CODE-EXAMPLE-010 service
   - Firestore trigger patterns
   - Deployment instructions

3. **RESEARCH-VALIDATION-stage-3.4.md** (816 lines)

   - Historical SDK verification
   - Add migration notes
   - Preserve original verification
   - Reference current SDK

4. **ADR-014-cloud-ai-provider-selection.md** (156 lines)
   - Decision record for Gemini selection
   - Add implementation note
   - Specify @google/genai SDK
   - Maintain decision validity

---

## Migration Pattern

### Pattern 1: Import Statement

**Before** (lines to update):

```javascript
const { VertexAI } = require("@google-cloud/vertexai");
```

**After**:

```javascript
const { GoogleGenAI } = require("@google/genai");
```

**Documents affected**: CODE-EXAMPLE-010 (line 42), CODE-EXAMPLE-011 (implicit in service import)

---

### Pattern 2: Client Initialization

**Before**:

```javascript
const vertexAI = new VertexAI({
  project: process.env.GCP_PROJECT_ID || "abundance-prod",
  location: process.env.VERTEX_AI_LOCATION || "us-central1",
});
```

**After**:

```javascript
// Cloud Functions (production): Use ADC
const genAI = new GoogleGenAI();

// Local development: Use API key
const genAI = new GoogleGenAI(process.env.GOOGLE_API_KEY);
```

**Documents affected**: CODE-EXAMPLE-010 (lines 86-89), RESEARCH-VALIDATION-stage-3.4 (lines 20-25, 86-102)

---

### Pattern 3: Model Configuration

**Before**:

```javascript
const model = vertexAI.preview.getGenerativeModel({
  model: "gemini-2.5-flash-lite",
  generationConfig: {
    temperature: 0.2,
    topP: 0.8,
    topK: 40,
    maxOutputTokens: 256,
    responseMimeType: "application/json",
    responseSchema: getAttributeSchema(),
  },
});
```

**After**:

```javascript
const model = genAI.getGenerativeModel({
  model: "gemini-2.5-flash-lite",
  generationConfig: {
    temperature: 0.2,
    topP: 0.8,
    topK: 40,
    maxOutputTokens: 256,
    responseMimeType: "application/json",
    responseSchema: getAttributeSchema(),
  },
});
```

**Changes**: Remove `.preview` namespace only

**Documents affected**: CODE-EXAMPLE-010 (lines 92-102), RESEARCH-VALIDATION-stage-3.4 (lines 92-102)

---

### Pattern 4: Image Loading (NEW REQUIREMENT)

**Before** (Cloud Storage URL directly):

```javascript
const result = await model.generateContent({
  contents: [
    {
      role: "user",
      parts: [
        { text: prompt },
        {
          fileData: {
            fileUri: imageUrl,
            mimeType: "image/jpeg",
          },
        },
      ],
    },
  ],
});
```

**After** (Fetch and convert to base64):

```javascript
// 1. Fetch image from Cloud Storage
const fetch = require("node-fetch"); // or built-in fetch in Node.js 18+
const imageResponse = await fetch(imageUrl);
const arrayBuffer = await imageResponse.arrayBuffer();
const base64Image = Buffer.from(arrayBuffer).toString("base64");

// 2. Generate content with inlineData
const result = await model.generateContent([
  prompt,
  {
    inlineData: {
      mimeType: "image/jpeg",
      data: base64Image,
    },
  },
]);
```

**Documents affected**: CODE-EXAMPLE-010 (lines 111-124), RESEARCH-VALIDATION-stage-3.4 (lines 660-674)

---

### Pattern 5: Response Parsing (UNCHANGED)

**Before and After** (identical):

```javascript
const responseText = result.response.text();
const attributes = JSON.parse(responseText);
const tokensUsed = result.response.usageMetadata?.totalTokenCount || 0;
```

**Changes**: None (fully compatible)

**Documents affected**: No changes needed

---

### Pattern 6: Package.json Dependencies

**Before**:

```json
{
  "dependencies": {
    "@google-cloud/vertexai": "^1.0.0",
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  }
}
```

**After**:

```json
{
  "dependencies": {
    "@google/genai": "^1.29.0",
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  }
}
```

**Documents affected**: CODE-EXAMPLE-010 (lines 474-486), CODE-EXAMPLE-011 (lines 312-339)

---

### Pattern 7: Environment Variables

**Before**:

```bash
# Required
GCP_PROJECT_ID=abundance-prod
VERTEX_AI_LOCATION=us-central1
```

**After**:

```bash
# Local development (API key mode)
GOOGLE_API_KEY=your_api_key_from_aistudio

# Cloud Functions (ADC mode, no env vars needed)
# Service account authentication automatic
```

**Documents affected**: CODE-EXAMPLE-010 (lines 492-497), CODE-EXAMPLE-011 (lines 369-376)

---

## Acceptance Criteria

### Document 1: CODE-EXAMPLE-010

- [ ] Line 19: Update SDK reference from @google-cloud/vertexai to @google/genai
- [ ] Line 42: Update import statement to `GoogleGenAI`
- [ ] Lines 86-102: Update initialization pattern (API key or ADC)
- [ ] Lines 111-124: Add image fetching and base64 conversion
- [ ] Lines 474-486: Update package.json to @google/genai ^1.29.0
- [ ] Lines 492-497: Update environment variables (GOOGLE_API_KEY)
- [ ] Add migration note at top of document
- [ ] Update all code comments to reflect new SDK

### Document 2: CODE-EXAMPLE-011

- [ ] Line 32: No direct import (uses CODE-EXAMPLE-010 service)
- [ ] Lines 86-102: Service initialization uses new SDK internally
- [ ] Lines 312-339: Update package.json to @google/genai ^1.29.0
- [ ] Lines 369-376: Update environment variables section
- [ ] Add migration note referencing CODE-EXAMPLE-010 changes
- [ ] Update integration notes to reflect SDK change

### Document 3: RESEARCH-VALIDATION-stage-3.4

- [ ] Add **Migration Note** section at top (after Executive Summary)
- [ ] Lines 13-46 (Claim 1): Add note that @google-cloud/vertexai is now deprecated
- [ ] Document BOTH old SDK (historical) and new SDK (current)
- [ ] Reference RESEARCH-VALIDATION-stage-3.4-sdk-migration.md for migration details
- [ ] Reference GOOGLE-GENAI-SDK-USAGE.md for current patterns
- [ ] Preserve original verification (don't delete historical context)
- [ ] Add "Status" field: "MIGRATED" with date

### Document 4: ADR-014

- [ ] Add **Implementation Note** section after Decision section
- [ ] Specify @google/genai SDK as implementation package
- [ ] Clarify that decision (Gemini selection) remains valid
- [ ] Reference GOOGLE-GENAI-SDK-USAGE.md for implementation
- [ ] Update revision history with migration note
- [ ] Maintain decision approval status

---

## Verification Checklist

### Pre-Migration Verification

- [x] Read all 4 documents completely
- [x] Identify all @google-cloud/vertexai references
- [x] Cross-reference with GOOGLE-GENAI-SDK-USAGE.md patterns
- [x] Cross-reference with RESEARCH-VALIDATION-stage-4.3.md verification
- [x] Document migration patterns above

### Post-Migration Verification

- [ ] Zero references to @google-cloud/vertexai in CODE-EXAMPLE-010
- [ ] Zero references to @google-cloud/vertexai in CODE-EXAMPLE-011
- [ ] package.json uses @google/genai ^1.29.0 in both documents
- [ ] All code examples compile (syntax check, no execution)
- [ ] Migration notes added to RESEARCH-VALIDATION-stage-3.4
- [ ] Implementation notes added to ADR-014
- [ ] Historical verification preserved in RESEARCH-VALIDATION-stage-3.4
- [ ] All cross-references updated

---

## Breaking Changes (Documentation Only)

### No Breaking Changes to Functionality

- Pricing: Unchanged ($0.10/$0.40 per million tokens)
- Capabilities: Unchanged (JSON Schema Mode, 1M context window)
- Model ID: Unchanged (gemini-2.5-flash-lite)
- Response structure: Unchanged (backward compatible)

### Documentation Changes Only

1. Import statement: `VertexAI` → `GoogleGenAI`
2. Initialization: `{ project, location }` → `apiKey` or ADC
3. Model namespace: `.preview` removed
4. Image loading: `fileUri` → `inlineData` with base64
5. Package name: `@google-cloud/vertexai` → `@google/genai`
6. Environment variables: `GCP_PROJECT_ID`, `VERTEX_AI_LOCATION` → `GOOGLE_API_KEY`

---

## Sprint 4 Impact

### Blocking Issues Resolved

- ✅ Sprint 4 Layer 2a implementation plan can reference correct SDK
- ✅ CODE-EXAMPLE-010 provides accurate integration patterns
- ✅ CODE-EXAMPLE-011 provides accurate Cloud Function patterns
- ✅ No confusion between deprecated and current SDKs

### No Code Changes Required

- This is documentation-only migration
- No actual implementation code exists yet in Sprint 4
- Sprint 4 will use correct SDK from day 1

---

## Execution Steps

### Step 1: Refactor CODE-EXAMPLE-010

1. Read document fully
2. Add migration note at top
3. Update line 19 (SDK reference)
4. Update line 42 (import statement)
5. Update lines 86-102 (initialization)
6. Update lines 111-124 (image loading)
7. Update lines 474-486 (package.json)
8. Update lines 492-497 (environment variables)
9. Update all code comments

### Step 2: Refactor CODE-EXAMPLE-011

1. Read document fully
2. Add migration note at top
3. Update lines 312-339 (package.json)
4. Update lines 369-376 (environment variables)
5. Update integration notes

### Step 3: Update RESEARCH-VALIDATION-stage-3.4

1. Read document fully
2. Add Migration Note section (after line 9)
3. Update Claim 1 (lines 13-46) with deprecation note
4. Add references to migration documents
5. Preserve all original verification
6. Update status field

### Step 4: Update ADR-014

1. Read document fully
2. Add Implementation Note section (after Decision section)
3. Specify @google/genai SDK
4. Reference implementation guides
5. Update revision history

### Step 5: Create Checkpoint

1. Document all changes made
2. Verify acceptance criteria
3. Report token usage
4. Confirm Sprint 4 unblocked

---

## Token Budget

- **Estimated**: 15,000 tokens
- **Actual**: (to be measured)
- **Budget**: 25,000 tokens (well under budget)

---

## Success Metrics

1. ✅ All 4 documents updated
2. ✅ Zero @google-cloud/vertexai references in code examples
3. ✅ All package.json snippets use @google/genai
4. ✅ Historical verification preserved
5. ✅ Sprint 4 planning unblocked
6. ✅ Checkpoint document created

---

**Status**: Ready for Execution

**Next Step**: Execute Step 1 (Refactor CODE-EXAMPLE-010)

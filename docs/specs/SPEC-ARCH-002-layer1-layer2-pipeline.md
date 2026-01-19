# SPEC-ARCH-002: Layer 1 / Layer 2 Pipeline Architecture

**Created:** 2026-01-17
**Updated:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## Overview

This document specifies the two-layer AI cataloging pipeline architecture for the Abundance MVP:

- **Layer 1 (Standard):** Gemini 3 Flash (`gemini-3-flash-preview`) - Object detection, cropping, and basic cataloging
- **Layer 2 (Premium):** Gemini 3 Pro (`gemini-3-pro-preview`) - Enhanced accuracy with tool calling for valuation

---

## Model Configuration

### Layer 1: Gemini 3 Flash

| Setting | Value | Reference |
|---------|-------|-----------|
| Model ID | `gemini-3-flash-preview` | `functions/src/ai-pipeline/layer1/prompts.ts:14` |
| Thinking Level | `LOW` | `functions/src/ai-pipeline/layer1/prompts.ts:66` |
| Temperature | 0.1 | `functions/src/ai-pipeline/layer1/prompts.ts:60` |
| Response Format | JSON (schema-constrained) | `functions/src/ai-pipeline/layer1/prompts.ts:63-64` |
| Max Output Tokens | 4096 | `functions/src/ai-pipeline/layer1/prompts.ts:62` |
| API Timeout | 30 seconds | `functions/src/ai-pipeline/layer1/prompts.ts:92` |
| Max Retries | 2 (exponential backoff) | `functions/src/ai-pipeline/layer1/prompts.ts:95` |

### Layer 2: Gemini 3 Pro

| Setting | Value | Reference |
|---------|-------|-----------|
| Model ID | `gemini-3-pro-preview` | `functions/src/ai-pipeline/gemini/prompts.ts:141` |
| Temperature | 0.1 | `functions/src/ai-pipeline/gemini/prompts.ts:133` |
| Response Format | JSON (schema-constrained) | `functions/src/ai-pipeline/gemini/prompts.ts:137-138` |
| Max Output Tokens | 8192 | `functions/src/ai-pipeline/gemini/prompts.ts:136` |
| Tool Calling | Enabled (3 tools) | `functions/src/ai-pipeline/gemini/prompts.ts:70-130` |
| Max Tool Iterations | 10 | `functions/src/ai-pipeline/gemini/gemini-service.ts:65` |

---

## Tier Model

### Standard Tier (Layer 1 Only)

**Trigger:** Automatic on capture session completion
**Firestore Trigger:** `onSessionCreated` (`functions/src/triggers/onSessionCreated.ts:138`)
**Cost:** ~$0.002/item

**Capabilities:**
- Object detection with bounding boxes (`box_2d`: [ymin, xmin, ymax, xmax] normalized 0-1000)
- Multi-image grouping (same object across different angles via `groupId`)
- Server-side cropping with `sharp` library
- Basic cataloging:
  - Name/label (specific: "Apple Mac Mini M2")
  - Category (electronics, furniture, kitchen, etc.)
  - Color, material, condition (when visible)
  - Confidence score (high/medium/low)

**Output:** Pre-catalogued items with status `detecting` -> `detected`

### Premium Tier (Layer 2)

**Trigger:** User taps "Catalog" button OR item created with status `pending`
**Firestore Trigger:** `onItemCreatedGemini3` (`functions/src/triggers/onItemCreatedGemini3.ts:28`)
**Cost:** ~$0.04/item (includes tool calls)

**Capabilities (additive to Layer 1):**
- Condition assessment (new, like-new, good, fair, poor)
- Estimated value/price range
- Improved accuracy via tool calling:
  - Google Lens visual search
  - Barcode lookup (UPC/EAN)
  - Web search for pricing
- Processing notes/reasoning

**Output:** Fully catalogued items with status `complete`

---

## Firestore Trigger Flow

### Layer 1 Flow (Session-based Detection)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  1. iOS App: Capture Session                                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  User captures photo(s) → Images uploaded to GCS temp bucket                 │
│  Session doc created: sessions/{sessionId}                                   │
│  Initial status: "uploading"                                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  2. Firestore Trigger: onSessionCreated                                      │
│     Reference: functions/src/triggers/onSessionCreated.ts:138                │
├─────────────────────────────────────────────────────────────────────────────┤
│  Trigger conditions (either):                                                │
│  - Status changes from "uploading" to "detecting"                           │
│  - imagesUploaded === expectedImageCount && imagesUploaded > 0              │
│                                                                              │
│  Validation:                                                                 │
│  - userId is non-empty string                                               │
│  - originalImageUrls is non-empty array                                     │
│  - All URLs from allowed buckets (abundance-*-temp)                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  3. Layer 1 Detection Service                                                │
│     Reference: functions/src/ai-pipeline/layer1/layer1-service.ts:172        │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Fetch images from GCS → convert to base64                               │
│  2. Call Gemini 3 Flash with retry logic (exponential backoff)              │
│  3. Parse detection response (objects array with bounding boxes)            │
│  4. Validate response against schema                                        │
│  5. Crop detected objects with sharp (5% padding)                           │
│  6. Upload crops to permanent bucket: users/{userId}/items/{groupId}_crop_N │
│  7. Generate signed URLs (24-hour expiration)                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  4. Session Document Update                                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  status: "detected"                                                          │
│  detectedObjects: [                                                          │
│    {                                                                         │
│      groupId: string,                                                        │
│      label: string,                                                          │
│      category: string,                                                       │
│      confidence: "high" | "medium" | "low",                                 │
│      croppedImageUrls: string[],                                            │
│      boundingBoxes: [{ imageIndex, box_2d }]                                │
│    }                                                                         │
│  ]                                                                           │
│  reasoning?: string (if no objects detected)                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Layer 2 Flow (Item Cataloging)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  1. Item Document Created                                                    │
│     Collection: items/{itemId}                                               │
│     Status: "pending"                                                        │
│     imagePath: path to cropped image in GCS                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  2. Firestore Trigger: onItemCreatedGemini3                                  │
│     Reference: functions/src/triggers/onItemCreatedGemini3.ts:28             │
├─────────────────────────────────────────────────────────────────────────────┤
│  Secrets: SERPAPI_KEY (for Google Lens)                                     │
│  Memory: 512MiB                                                              │
│  Timeout: 120 seconds                                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  3. Gemini 3 Pro Orchestrator                                                │
│     Reference: functions/src/ai-pipeline/gemini/orchestrator.ts:21           │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Get signed URL for image (15-minute expiration)                         │
│  2. Call processItemWithGemini()                                            │
│  3. Validate result against CatalogItem schema                              │
│  4. Flatten catalog data to top-level Firestore fields                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  4. Gemini 3 Pro Service (with Tool Calling Loop)                            │
│     Reference: functions/src/ai-pipeline/gemini/gemini-service.ts:30         │
├─────────────────────────────────────────────────────────────────────────────┤
│  Initial call with image + tool declarations                                │
│                                                                              │
│  While (functionCalls present && iterations < 10):                          │
│    1. Execute tool calls in parallel                                        │
│    2. Preserve thought_signature (CRITICAL for Gemini 3)                    │
│    3. Append model parts + tool results to conversation                     │
│    4. Call Gemini again with updated context                                │
│                                                                              │
│  Return final JSON response as CatalogItem                                  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  5. Item Document Update                                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  status: "complete"                                                          │
│  name, category, subCategory, brand, model, color: from catalog             │
│  condition: "new" | "like-new" | "good" | "fair" | "poor"                   │
│  estimatedValue: number | null                                              │
│  confidence: "high" | "medium" | "low"                                      │
│  processingNotes: string | null                                             │
│  completedAt: timestamp                                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Tool Definitions

### google_lens_search

**Purpose:** Visual product matching via SerpAPI

**Reference:** `functions/src/ai-pipeline/gemini/prompts.ts:73-87`

```typescript
{
  name: 'google_lens_search',
  description: 'Search for product information using visual matching.',
  parameters: {
    type: 'object',
    properties: {
      image_url: {
        type: 'string',
        description: 'Public URL of the product image'
      }
    },
    required: ['image_url']
  }
}
```

**Implementation:** `functions/src/ai-pipeline/tools/google-lens.ts:36`

**Response Schema:**
```typescript
interface GoogleLensResult {
  exact_matches: boolean;
  products: Array<{
    title: string;
    brand?: string;
    price?: number;
    source: string;
    link: string;
  }>;
}
```

### barcode_lookup

**Purpose:** UPC/EAN barcode lookup via UPCitemdb API

**Reference:** `functions/src/ai-pipeline/gemini/prompts.ts:89-110`

```typescript
{
  name: 'barcode_lookup',
  description: 'Look up product information by barcode number.',
  parameters: {
    type: 'object',
    properties: {
      code: {
        type: 'string',
        description: 'The barcode number'
      },
      symbology: {
        type: 'string',
        enum: ['upc_a', 'upc_e', 'ean_13', 'ean_8', 'qr', 'code_128'],
        description: 'The barcode format (optional)'
      }
    },
    required: ['code']
  }
}
```

**Implementation:** `functions/src/ai-pipeline/tools/barcode-lookup.ts:39`

**Response Schema:**
```typescript
interface BarcodeResult {
  found: boolean;
  product?: {
    title: string;
    brand?: string;
    model?: string;
    description?: string;
  };
  barcode?: string;
}
```

### web_search

**Purpose:** E-commerce price search via Google Search Grounding

**Reference:** `functions/src/ai-pipeline/gemini/prompts.ts:112-129`

```typescript
{
  name: 'web_search',
  description: 'Search e-commerce sites for current pricing.',
  parameters: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: 'Search query'
      }
    },
    required: ['query']
  }
}
```

**Implementation:** `functions/src/ai-pipeline/tools/web-search.ts:19`

Uses Gemini 3 Pro with `googleSearch` grounding tool. Searches Amazon, eBay, Walmart, Target.

**Response Schema:**
```typescript
interface WebSearchResult {
  prices: Array<{
    source: string;
    price: number;
    condition?: string;
  }>;
  raw?: string;
}
```

---

## Thought Signature Handling (CRITICAL)

### Gemini 3 Requirement

Gemini 3 models require `thought_signature` preservation when using function calling. Without it, the API returns a 400 error.

**Reference:** `functions/src/ai-pipeline/gemini/gemini-service.ts:90-100`

### Implementation

```typescript
// CRITICAL: Preserve the original model parts including thought_signature
// Gemini 3 requires thought_signature for function calls, otherwise returns 400 error
// See: https://cloud.google.com/vertex-ai/generative-ai/docs/thought-signatures
const modelParts = getModelPartsWithThoughtSignature(response);
```

**Reference:** `functions/src/ai-pipeline/gemini/gemini-service.ts:145-157`

```typescript
function getModelPartsWithThoughtSignature(response: GenerateContentResponse): Part[] {
  const candidate = response.candidates?.[0];
  if (!candidate?.content?.parts) {
    return [];
  }
  // Return the original parts which include thought_signature
  return candidate.content.parts.filter(part =>
    part.functionCall || part.thought || part.thoughtSignature
  );
}
```

### Key Points

1. **Never strip model response parts** - They may contain `thought_signature`
2. **Filter to relevant parts** - Include `functionCall`, `thought`, `thoughtSignature`
3. **Maintain conversation order** - Model parts must precede user parts (tool results)

---

## Schema Definitions

### Layer 1 Detection Response

**Reference:** `functions/src/ai-pipeline/layer1/schemas/detection-result.ts:60-66`

```typescript
interface Layer1DetectionResponse {
  objects: DetectedObject[];
  reasoning?: string;
}

interface DetectedObject {
  groupId: string;              // UUID for multi-image grouping
  label: string;                // "Apple Mac Mini M2"
  category: string;             // "electronics"
  box_2d: [number, number, number, number];  // [ymin, xmin, ymax, xmax] 0-1000
  image_index: number;          // Which image (0-indexed)
  confidence?: 'high' | 'medium' | 'low';
  attributes?: {
    color?: string;
    material?: string;
    condition?: string;
    brand?: string;
  };
}
```

### Layer 2 Catalog Item

**Reference:** `functions/src/ai-pipeline/gemini/schemas/catalog-item.ts:14-27`

```typescript
interface CatalogItem {
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

---

## Vertex AI Configuration

### Authentication

**Reference:** `functions/src/ai-pipeline/gemini/vertexai-config.ts:81-84`

```typescript
export function createVertexAIClient(): GoogleGenAI {
  const config = getVertexAIConfig();
  return new GoogleGenAI(config);
}
```

Gemini 3 Preview models require Vertex AI authentication (not API keys):
- Cloud Functions: Automatic via Application Default Credentials (service account)
- Local development: `gcloud auth application-default login`

### Project ID Resolution

**Reference:** `functions/src/ai-pipeline/gemini/vertexai-config.ts:25-45`

Priority:
1. `GOOGLE_CLOUD_PROJECT` env var
2. `GCLOUD_PROJECT` env var (Cloud Functions v1)
3. Firebase Admin SDK `getApp().options.projectId` (Cloud Functions v2)

### Location

Default: `global` (recommended for Gemini 3 models)
Override: `GOOGLE_CLOUD_LOCATION` env var

---

## Error Handling

### Layer 1 Error Codes

**Reference:** `functions/src/triggers/onSessionCreated.ts:273-281`

| Code | Meaning |
|------|---------|
| `INVALID_DOCUMENT` | Missing required fields (userId) |
| `NO_IMAGES` | Empty originalImageUrls array |
| `UNAUTHORIZED_BUCKET` | Image URL from non-allowed bucket |
| `TIMEOUT` | API call exceeded timeout |
| `QUOTA_EXCEEDED` | Rate limit or quota hit |
| `INVALID_INPUT` | Malformed request |
| `PERMISSION_DENIED` | Authentication/authorization failure |
| `NOT_FOUND` | Resource not found |
| `INTERNAL_ERROR` | Unclassified error |

### Layer 1 Retryable Errors

**Reference:** `functions/src/ai-pipeline/layer1/layer1-service.ts:36-42`

```typescript
const RETRYABLE_ERROR_CODES = [
  'UNAVAILABLE',
  'DEADLINE_EXCEEDED',
  'RESOURCE_EXHAUSTED',
  'INTERNAL',
  'UNKNOWN'
];
```

Retry strategy: Exponential backoff (1s, 2s, 4s) with max 2 retries.

### Layer 2 Error Handling

**Reference:** `functions/src/ai-pipeline/gemini/orchestrator.ts:96-110`

On failure:
- Update document with `status: 'failed'`
- Record error message
- Log structured error for monitoring

---

## UX Design Principles

### Background Processing

Layer 1 processing happens in the background without blocking the camera UI:

1. **After capture:** User immediately returns to live camera preview
2. **Processing indicator:** Small, non-intrusive badge or status
3. **Results appear in Catalog View:** User navigates to Catalog tab
4. **No approval at capture time:** Detection just happens

**Anti-pattern:** Full-screen "Detecting..." overlay that blocks the camera.

### Catalog Approval in Catalog View

The "Catalog" button (Layer 2 trigger) lives in the **Catalog View**, not Camera:

- User sees pre-catalogued items with: thumbnail, name, brand, category, "Pre-catalogued" badge
- Tap item -> Detail view with "Catalog" button to trigger Layer 2
- User can edit fields manually, add photos, or accept as-is

---

## Storage Architecture

### What Gets Stored

| Content | Storage Location | Lifecycle |
|---------|------------------|-----------|
| Original captures | GCS temp bucket | Deleted after Layer 1 |
| Cropped objects | Firebase Storage | Permanent (user's inventory) |
| Signed URLs | Firestore (item doc) | 24-hour expiration |
| Layer 1 metadata | Firestore (session doc) | Permanent |
| Layer 2 metadata | Firestore (item doc) | Permanent |

### Storage Paths

```
gs://abundance-mvp.firebasestorage.app/
└── users/{userId}/items/
    ├── {groupId}_crop_0.jpg    (cropped object, angle 1)
    ├── {groupId}_crop_1.jpg    (cropped object, angle 2)
    └── ...
```

---

## Multi-Image Handling

### Single Request for Burst Captures

When user captures multiple angles of the same scene:

1. All images sent in ONE session document
2. Gemini Flash sees all images simultaneously
3. Visual grouping: "Images 1, 2, 3 show the same mug -> groupId: abc"
4. Creates separate crops per image, linked by groupId
5. Single Firestore document per unique object

**Rationale:** Gemini Flash can visually determine "same object, different angle" when it sees all images at once.

### Bounding Box Format

**Reference:** `functions/src/ai-pipeline/layer1/prompts.ts:36-39`

```
box_2d: [ymin, xmin, ymax, xmax]
- Values normalized to 0-1000
- ymin: top edge, ymax: bottom edge
- xmin: left edge, xmax: right edge
```

---

## Cost Model

### Layer 1 (Gemini 3 Flash)

| Component | Cost |
|-----------|------|
| Gemini 3 Flash API | ~$0.001/request |
| GCS storage (crops) | ~$0.001/item |
| **Total** | ~$0.002/item |

### Layer 2 (Gemini 3 Pro + Tools)

| Component | Cost |
|-----------|------|
| Gemini 3 Pro API | ~$0.004/request |
| Google Lens (SerpAPI) | ~$0.015/call |
| Barcode Lookup (UPCitemdb) | ~$0.005/call |
| Web Search (grounded) | ~$0.014/call |
| **Total (typical)** | ~$0.04/item |

**Reference:** `functions/src/ai-pipeline/gemini/orchestrator.ts:137-152`

---

## File Reference Index

| File | Purpose |
|------|---------|
| `functions/src/triggers/onSessionCreated.ts` | Layer 1 Firestore trigger |
| `functions/src/triggers/onItemCreatedGemini3.ts` | Layer 2 Firestore trigger |
| `functions/src/ai-pipeline/layer1/prompts.ts` | Layer 1 model config & prompts |
| `functions/src/ai-pipeline/layer1/layer1-service.ts` | Layer 1 detection service |
| `functions/src/ai-pipeline/layer1/schemas/detection-result.ts` | Layer 1 response schema |
| `functions/src/ai-pipeline/gemini/prompts.ts` | Layer 2 model config, prompts, tools |
| `functions/src/ai-pipeline/gemini/gemini-service.ts` | Layer 2 service with tool loop |
| `functions/src/ai-pipeline/gemini/orchestrator.ts` | Layer 2 orchestration |
| `functions/src/ai-pipeline/gemini/schemas/catalog-item.ts` | Layer 2 output schema |
| `functions/src/ai-pipeline/gemini/vertexai-config.ts` | Vertex AI client setup |
| `functions/src/ai-pipeline/tools/tool-executor.ts` | Tool call dispatcher |
| `functions/src/ai-pipeline/tools/google-lens.ts` | Google Lens via SerpAPI |
| `functions/src/ai-pipeline/tools/barcode-lookup.ts` | UPC lookup via UPCitemdb |
| `functions/src/ai-pipeline/tools/web-search.ts` | Price search via Search Grounding |

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-17 | 1.0 | Initial spec from architecture discussion |
| 2026-01-18 | 2.0 | Updated with implementation details, code references, tool definitions, thought signature requirements |

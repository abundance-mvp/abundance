# SPEC-PIPE-001: Layer 1 Object Detection

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## Table of Contents

1. [Overview](#1-overview)
2. [Model Configuration](#2-model-configuration)
3. [System Prompt](#3-system-prompt)
4. [Detection Schema](#4-detection-schema)
5. [Multi-Image Handling](#5-multi-image-handling)
6. [Cropping Flow](#6-cropping-flow)
7. [Error Handling](#7-error-handling)
8. [Cost Estimates](#8-cost-estimates)
9. [Trigger Integration](#9-trigger-integration)

---

## 1. Overview

Layer 1 is the **object detection** stage of the Abundance AI pipeline. It uses **Gemini 3 Flash** to identify and localize catalogable objects within uploaded images.

### Purpose

- Detect all physical objects suitable for home inventory cataloging
- Generate precise bounding boxes for each detected object
- Group the same object appearing across multiple images (burst mode)
- Extract object crops for downstream processing (Layer 2 analysis)

### Pipeline Position

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Image Upload   │────▶│   Layer 1       │────▶│   Layer 2       │
│  (GCS temp)     │     │   Detection     │     │   Analysis      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                              │
                              ▼
                        ┌─────────────────┐
                        │  Crop & Upload  │
                        │  (GCS permanent)│
                        └─────────────────┘
```

### Key Capabilities

| Capability | Description |
|------------|-------------|
| Single-image detection | Detect multiple objects in one photo |
| Multi-image grouping | Link same object across different angles |
| Server-side cropping | Extract object regions using Sharp |
| Structured output | JSON schema-constrained responses |

---

## 2. Model Configuration

### Model ID

```typescript
export const LAYER1_MODEL_ID = 'gemini-3-flash-preview';
```

### Generation Configuration

```typescript
export const LAYER1_GENERATION_CONFIG = {
  temperature: 0.1,
  topP: 0.95,
  maxOutputTokens: 4096,
  responseMimeType: 'application/json',
  responseSchema: LAYER1_DETECTION_SCHEMA,
  thinkingConfig: {
    thinkingLevel: ThinkingLevel.LOW  // Optimized for detection speed
  }
};
```

### Configuration Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `temperature` | `0.1` | Low temperature for deterministic detection |
| `topP` | `0.95` | Nucleus sampling threshold |
| `maxOutputTokens` | `4096` | Maximum response length for complex scenes |
| `responseMimeType` | `application/json` | Force JSON output |
| `thinkingLevel` | `LOW` | Balance speed vs reasoning depth |

### Why Gemini 3 Flash?

- **Speed**: Optimized for low-latency inference
- **Thinking Config**: Native `thinkingLevel` support for reasoning control
- **Vision**: Strong multimodal capabilities for object detection
- **Structured Output**: Native `responseSchema` enforcement
- **Cost**: ~$0.002 per image (see [Cost Estimates](#8-cost-estimates))

---

## 3. System Prompt

The full system prompt guides the model's detection behavior:

```typescript
export const LAYER1_SYSTEM_PROMPT = `You are an object detection system for a home inventory app.

TASK: Analyze the provided image(s) and identify all distinct physical objects suitable for cataloging.

DETECTION RULES:
1. Detect objects that could be inventoried (furniture, electronics, appliances, tools, books, clothing, etc.)
2. Ignore: walls, floors, ceilings, windows, built-in fixtures, people, pets
3. For each object, provide a bounding box as [ymin, xmin, ymax, xmax] normalized to 0-1000
4. Provide a specific label (e.g., "leather armchair" not just "chair")

MULTI-IMAGE RULES:
When given multiple images:
1. Identify if the SAME object appears in multiple photos (different angles)
2. Assign matching objects the same groupId
3. Different objects get different groupIds
4. Use visual similarity, position context, and reasoning to group

BOUNDING BOX FORMAT:
- box_2d: [ymin, xmin, ymax, xmax] where values are 0-1000
- ymin: top edge, ymax: bottom edge
- xmin: left edge, xmax: right edge

IF NO CATALOGABLE OBJECTS FOUND:
Return an empty array with a "reasoning" field explaining why. Examples:
- "The image contains only built-in fixtures (cabinets, countertops) which are not catalogable."
- "Only people and pets are visible in this image."
- "The image is too blurry/dark to identify distinct objects."

OUTPUT: Return valid JSON array matching the schema.`;
```

### Prompt Design Principles

1. **Clear Task Definition**: Explicit scope (home inventory cataloging)
2. **Exclusion Rules**: Built-in fixtures, people, pets excluded
3. **Label Specificity**: Encourages descriptive labels ("leather armchair" vs "chair")
4. **Bounding Box Format**: Explicit coordinate system documentation
5. **Multi-Image Logic**: Clear grouping instructions for burst mode
6. **Empty Result Handling**: Requires reasoning when no objects found

---

## 4. Detection Schema

### TypeScript Interfaces

```typescript
/**
 * Confidence level for object detection
 */
export type DetectionConfidence = 'high' | 'medium' | 'low';

/**
 * Bounding box in Gemini format: [ymin, xmin, ymax, xmax] normalized to 0-1000
 */
export type BoundingBox = [number, number, number, number];

/**
 * Optional attributes detected for an object
 */
export interface DetectedAttributes {
  color?: string;
  material?: string;
  condition?: string;
  brand?: string;
}

/**
 * Single detection from Layer 1
 */
export interface DetectedObject {
  /** UUID for grouping same object across images */
  groupId: string;

  /** Specific descriptive name (e.g., 'Apple Mac Mini M2') */
  label: string;

  /** High-level category (electronics, furniture, kitchen, etc.) */
  category: string;

  /** [ymin, xmin, ymax, xmax] normalized 0-1000 */
  box_2d: BoundingBox;

  /** Optional attributes */
  attributes?: DetectedAttributes;

  /** Which image this detection is from (0-indexed) */
  image_index: number;

  /** Detection confidence */
  confidence?: DetectionConfidence;
}

/**
 * Layer 1 detection response from Gemini 3 Flash
 */
export interface Layer1DetectionResponse {
  /** Detected objects array */
  objects: DetectedObject[];

  /** Explanation when no objects detected, or grouping logic for multi-image */
  reasoning?: string;
}
```

### Bounding Box Format: `box_2d`

The bounding box uses **Gemini's native format**:

```
box_2d: [ymin, xmin, ymax, xmax]
```

| Index | Field | Description | Range |
|-------|-------|-------------|-------|
| 0 | `ymin` | Top edge (y-coordinate) | 0-1000 |
| 1 | `xmin` | Left edge (x-coordinate) | 0-1000 |
| 2 | `ymax` | Bottom edge (y-coordinate) | 0-1000 |
| 3 | `xmax` | Right edge (x-coordinate) | 0-1000 |

**Normalization**: Values are normalized to a 0-1000 scale regardless of actual image dimensions. This allows consistent representation across different image sizes.

**Example**:
```json
{
  "box_2d": [100, 200, 400, 600]
}
```
This represents a box with:
- Top-left corner at (20%, 10%) of image
- Bottom-right corner at (60%, 40%) of image

### JSON Schema for Gemini

```typescript
export const LAYER1_DETECTION_SCHEMA = {
  type: 'object',
  properties: {
    objects: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          groupId: {
            type: 'string',
            description: 'UUID for grouping same object across images'
          },
          label: {
            type: 'string',
            description: 'Specific descriptive name (e.g., "Apple Mac Mini M2")'
          },
          category: {
            type: 'string',
            description: 'High-level category (electronics, furniture, kitchen, etc.)'
          },
          box_2d: {
            type: 'array',
            items: { type: 'integer' },
            minItems: 4,
            maxItems: 4,
            description: '[ymin, xmin, ymax, xmax] normalized 0-1000'
          },
          attributes: {
            type: 'object',
            properties: {
              color: { type: 'string' },
              material: { type: 'string' },
              condition: { type: 'string' },
              brand: { type: 'string' }
            }
          },
          image_index: {
            type: 'integer',
            description: 'Which image this detection is from (0-indexed)'
          },
          confidence: {
            type: 'string',
            enum: ['high', 'medium', 'low']
          }
        },
        required: ['groupId', 'label', 'category', 'box_2d', 'image_index']
      }
    },
    reasoning: {
      type: 'string',
      description: 'Explanation when no objects detected, or grouping logic for multi-image'
    }
  },
  required: ['objects']
};
```

### Validation Function

```typescript
export function validateDetectionResponse(response: Layer1DetectionResponse): ValidationResult {
  const errors: string[] = [];

  if (!response.objects || !Array.isArray(response.objects)) {
    errors.push('Response must contain an objects array');
    return { valid: false, errors };
  }

  for (let i = 0; i < response.objects.length; i++) {
    const obj = response.objects[i];
    const prefix = `objects[${i}]`;

    if (!obj.groupId || typeof obj.groupId !== 'string') {
      errors.push(`${prefix}.groupId is required and must be a string`);
    }
    if (!obj.label || typeof obj.label !== 'string') {
      errors.push(`${prefix}.label is required and must be a string`);
    }
    if (!obj.category || typeof obj.category !== 'string') {
      errors.push(`${prefix}.category is required and must be a string`);
    }
    if (!Array.isArray(obj.box_2d) || obj.box_2d.length !== 4) {
      errors.push(`${prefix}.box_2d must be an array of 4 numbers`);
    } else {
      for (let j = 0; j < 4; j++) {
        const val = obj.box_2d[j];
        if (typeof val !== 'number' || val < 0 || val > 1000) {
          errors.push(`${prefix}.box_2d[${j}] must be a number between 0 and 1000`);
        }
      }
    }
    if (typeof obj.image_index !== 'number' || obj.image_index < 0) {
      errors.push(`${prefix}.image_index is required and must be a non-negative number`);
    }
    if (obj.confidence && !['high', 'medium', 'low'].includes(obj.confidence)) {
      errors.push(`${prefix}.confidence must be 'high', 'medium', or 'low'`);
    }
  }

  return { valid: errors.length === 0, errors };
}
```

---

## 5. Multi-Image Handling

### groupId Linking

When processing multiple images (burst mode), the model assigns the **same `groupId`** to detections of the same physical object across different images.

```
Image 1: Chair (front view)    ─┬─▶ groupId: "chair-abc123"
Image 2: Chair (side view)     ─┘
Image 3: Table (top view)      ───▶ groupId: "table-def456"
```

### Detection Grouping Logic

The model uses several heuristics to determine if objects match:

1. **Visual Similarity**: Color, shape, material, brand logos
2. **Position Context**: Relative position to other objects
3. **Size Consistency**: Objects should be similar size across angles
4. **Attribute Matching**: Brand, condition, material should match

### Bounding Box Per-Image Tracking

Each detection includes an `image_index` field indicating which image the bounding box applies to:

```typescript
interface DetectedObject {
  groupId: string;
  box_2d: BoundingBox;
  image_index: number;  // 0-indexed
  // ...
}
```

**Example Multi-Image Response**:
```json
{
  "objects": [
    {
      "groupId": "chair-001",
      "label": "Blue fabric armchair",
      "category": "furniture",
      "box_2d": [200, 100, 800, 600],
      "image_index": 0
    },
    {
      "groupId": "chair-001",
      "label": "Blue fabric armchair",
      "category": "furniture",
      "box_2d": [150, 200, 750, 700],
      "image_index": 1
    }
  ],
  "reasoning": "The same armchair was detected in images 1 and 2 from different angles."
}
```

### CroppedObject Result Structure

After cropping, objects are grouped with all their crops:

```typescript
export interface CroppedObject {
  groupId: string;
  label: string;
  category: string;
  confidence?: string;
  attributes?: Record<string, string>;

  /** URLs to cropped images in GCS */
  croppedImageUrls: string[];

  /** Bounding boxes for each image */
  boundingBoxes: Array<{
    imageIndex: number;
    box_2d: [number, number, number, number];
  }>;
}
```

---

## 6. Cropping Flow

### Overview

After detection, Layer 1 crops each detected object from the original images and uploads to permanent storage.

```
Detection Response
        │
        ▼
┌───────────────────┐
│  Group by groupId │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ For each detection│
│  1. Validate bbox │
│  2. Get image     │
│  3. Convert coords│
│  4. Add padding   │
│  5. Crop with     │
│     Sharp         │
│  6. Upload to GCS │
└───────────────────┘
        │
        ▼
   Cropped URLs
```

### Sharp Library Usage

The [Sharp](https://sharp.pixelplumbing.com/) library handles server-side image cropping:

```typescript
// Dynamic import for sharp (ESM module)
let sharp: typeof import('sharp') | null = null;

async function getSharp() {
  if (!sharp) {
    sharp = (await import('sharp')).default;
  }
  return sharp;
}
```

**Crop Operation**:
```typescript
const croppedBuffer = await sharpLib(imageBuffer)
  .extract({
    left: paddedCoords.x1,
    top: paddedCoords.y1,
    width: paddedCoords.width,
    height: paddedCoords.height
  })
  .jpeg({ quality: 85 })
  .toBuffer();
```

### Coordinate Conversion

The bounding box utilities convert from Gemini's 0-1000 normalized coordinates to absolute pixel coordinates:

```typescript
/**
 * Convert Gemini box_2d format to absolute pixel coordinates
 *
 * @param box_2d - Bounding box in Gemini format [ymin, xmin, ymax, xmax]
 * @param imageWidth - Image width in pixels
 * @param imageHeight - Image height in pixels
 * @returns Absolute pixel coordinates for cropping
 */
export function boxToAbsolute(
  box_2d: BoundingBox,
  imageWidth: number,
  imageHeight: number
): AbsoluteCoordinates {
  const [ymin, xmin, ymax, xmax] = box_2d;

  const x1 = Math.round((xmin / 1000) * imageWidth);
  const y1 = Math.round((ymin / 1000) * imageHeight);
  const x2 = Math.round((xmax / 1000) * imageWidth);
  const y2 = Math.round((ymax / 1000) * imageHeight);

  return {
    x1,
    y1,
    x2,
    y2,
    width: x2 - x1,
    height: y2 - y1
  };
}
```

### Padding Addition

A 5% padding is added around detected objects for better crop quality:

```typescript
/**
 * Add padding to absolute coordinates (for better cropping)
 *
 * @param coords - Absolute coordinates
 * @param padding - Padding as percentage (0.0-1.0), default 0.05 (5%)
 * @param imageWidth - Image width for bounds checking
 * @param imageHeight - Image height for bounds checking
 * @returns Padded coordinates clamped to image bounds
 */
export function addPadding(
  coords: AbsoluteCoordinates,
  padding: number = 0.05,
  imageWidth: number,
  imageHeight: number
): AbsoluteCoordinates {
  const padX = Math.round(coords.width * padding);
  const padY = Math.round(coords.height * padding);

  const x1 = Math.max(0, coords.x1 - padX);
  const y1 = Math.max(0, coords.y1 - padY);
  const x2 = Math.min(imageWidth, coords.x2 + padX);
  const y2 = Math.min(imageHeight, coords.y2 + padY);

  return {
    x1,
    y1,
    x2,
    y2,
    width: x2 - x1,
    height: y2 - y1
  };
}
```

### Bounding Box Validation

```typescript
export function isValidBoundingBox(box_2d: BoundingBox): boolean {
  if (!Array.isArray(box_2d) || box_2d.length !== 4) {
    return false;
  }

  const [ymin, xmin, ymax, xmax] = box_2d;

  // Check all values are numbers in valid range
  for (const val of box_2d) {
    if (typeof val !== 'number' || val < 0 || val > 1000) {
      return false;
    }
  }

  // Check min < max
  if (ymin >= ymax || xmin >= xmax) {
    return false;
  }

  // Check minimum size (at least 10 units = 1%)
  if (ymax - ymin < 10 || xmax - xmin < 10) {
    return false;
  }

  return true;
}
```

### Upload to Permanent Storage

Cropped images are uploaded to permanent GCS storage with signed URLs:

```typescript
// Upload to GCS
const cropPath = `users/${userId}/items/${groupId}_crop_${croppedUrls.length}.jpg`;
const bucket = storage.bucket();
const file = bucket.file(cropPath);

await file.save(croppedBuffer, {
  metadata: {
    contentType: 'image/jpeg',
    metadata: {
      sessionId,
      groupId,
      label: obj.label,
      imageIndex: obj.image_index.toString()
    }
  }
});

// Generate signed URL with 24-hour expiration (security: no public access)
const [signedUrl] = await file.getSignedUrl({
  action: 'read',
  expires: Date.now() + 24 * 60 * 60 * 1000, // 24 hours
  version: 'v4'
});
```

---

## 7. Error Handling

### Timeout Configuration

```typescript
export const LAYER1_TIMEOUTS = {
  /** Gemini Flash API timeout (30 seconds) */
  GEMINI_FLASH_TIMEOUT_MS: 30000,

  /** Max retries for transient failures */
  GEMINI_FLASH_MAX_RETRIES: 2,

  /** Per-image fetch timeout (10 seconds) */
  IMAGE_FETCH_TIMEOUT_MS: 10000,

  /** Per-crop operation timeout (5 seconds) */
  CROP_OPERATION_TIMEOUT_MS: 5000,

  /** Total function timeout (120 seconds) */
  FUNCTION_TIMEOUT_SECONDS: 120,

  /** Client-side max wait for detection results (45 seconds) */
  MAX_WAIT_FOR_DETECTION_MS: 45000
};
```

### Retryable Error Codes

```typescript
const RETRYABLE_ERROR_CODES = [
  'UNAVAILABLE',
  'DEADLINE_EXCEEDED',
  'RESOURCE_EXHAUSTED',
  'INTERNAL',
  'UNKNOWN'
];
```

### Exponential Backoff Retry

```typescript
export async function callGeminiFlashWithRetry(
  imageBase64s: string[],
  maxRetries: number = LAYER1_TIMEOUTS.GEMINI_FLASH_MAX_RETRIES
): Promise<Layer1DetectionResponse> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await callGeminiFlash(imageBase64s);
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));

      // If error is not retryable, fail immediately
      if (!isRetryableError(lastError)) {
        throw lastError;
      }

      logger.warn('Gemini Flash attempt failed', {
        attempt: attempt + 1,
        maxAttempts: maxRetries + 1,
        error: lastError.message
      });

      // Apply exponential backoff before next retry (except on last attempt)
      if (attempt < maxRetries) {
        const backoffMs = 1000 * Math.pow(2, attempt); // 1s, 2s, 4s
        logger.info('Retrying Gemini Flash', { backoffMs });
        await sleep(backoffMs);
      }
    }
  }

  throw lastError ?? new Error('Gemini Flash failed with unknown error');
}
```

### Error Code Mapping

```typescript
function determineErrorCode(error: unknown): string {
  if (error instanceof Error) {
    if (error.message.includes('timeout')) return 'TIMEOUT';
    if (error.message.includes('quota')) return 'QUOTA_EXCEEDED';
    if (error.message.includes('invalid')) return 'INVALID_INPUT';
    if (error.message.includes('permission')) return 'PERMISSION_DENIED';
    if (error.message.includes('not found')) return 'NOT_FOUND';
  }
  return 'INTERNAL_ERROR';
}
```

### Session Error Codes

| Error Code | Description | Cause |
|------------|-------------|-------|
| `INVALID_DOCUMENT` | Session document missing required fields | Missing `userId` |
| `NO_IMAGES` | No images provided | Empty `originalImageUrls` array |
| `UNAUTHORIZED_BUCKET` | Image from non-allowed bucket | Security violation |
| `TIMEOUT` | Operation exceeded time limit | Slow API or network |
| `QUOTA_EXCEEDED` | API quota limit reached | Rate limiting |
| `INVALID_INPUT` | Malformed request | Bad image data |
| `PERMISSION_DENIED` | Access denied | Auth/IAM issue |
| `NOT_FOUND` | Resource not found | Missing file |
| `INTERNAL_ERROR` | Unknown failure | Catch-all |

---

## 8. Cost Estimates

### Gemini 3 Flash Pricing (Estimated)

| Component | Cost | Notes |
|-----------|------|-------|
| Input (image) | ~$0.001/image | Medium resolution |
| Input (text) | ~$0.0001/1K tokens | System prompt + user message |
| Output | ~$0.0004/1K tokens | JSON response (~500 tokens) |
| **Total per item** | **~$0.002** | Average single-image detection |

### Cost Breakdown by Session Type

| Session Type | Images | Detection Cost | Crop Cost* | Total |
|--------------|--------|----------------|------------|-------|
| Single photo | 1 | ~$0.002 | ~$0.0005 | ~$0.0025 |
| Burst (3 photos) | 3 | ~$0.004 | ~$0.001 | ~$0.005 |
| Burst (5 photos) | 5 | ~$0.006 | ~$0.002 | ~$0.008 |

*Crop cost includes GCS storage and compute overhead.

### Monthly Cost Projections

| Usage Level | Sessions/Month | Est. Monthly Cost |
|-------------|----------------|-------------------|
| Light | 100 | ~$0.25-0.50 |
| Medium | 1,000 | ~$2.50-5.00 |
| Heavy | 10,000 | ~$25-50 |

### Cost Optimization Strategies

1. **Medium Resolution**: Images processed at medium resolution (not full quality)
2. **thinkingLevel: LOW**: Reduces token usage vs HIGH/MEDIUM
3. **JSON Schema**: Constrains output size
4. **Batch Processing**: Multiple images in single API call

---

## 9. Trigger Integration

### Firestore Trigger: `onSessionCreated`

The `onSessionCreated` trigger orchestrates Layer 1 detection:

```typescript
export const onSessionCreated = onDocumentUpdated(
  {
    document: 'sessions/{sessionId}',
    region: 'us-central1',
    memory: '1GiB',  // Need more memory for sharp image processing
    timeoutSeconds: LAYER1_TIMEOUTS.FUNCTION_TIMEOUT_SECONDS,
  },
  async (event) => { /* ... */ }
);
```

### Trigger Conditions

The function triggers when:

1. **Status change**: `uploading` -> `detecting` (client signals ready)
2. **All images uploaded**: `imagesUploaded === expectedImageCount`

```typescript
const shouldProcess =
  // Case 1: Status changed from uploading to detecting (client set ready)
  (beforeData?.status === 'uploading' && afterData.status === 'detecting') ||
  // Case 2: All expected images uploaded
  (afterData.status === 'uploading' &&
    imagesUploaded === afterData.expectedImageCount &&
    imagesUploaded > 0);
```

### Session Validation

Before processing, the session document is validated:

```typescript
export async function validateSessionDocument(
  sessionData: Record<string, unknown>,
  sessionRef: FirebaseFirestore.DocumentReference
): Promise<ValidationResult> {
  // 1. Validate userId exists and is a non-empty string
  // 2. Validate originalImageUrls is a non-empty array
  // 3. Validate all URLs are from allowed buckets
}
```

**Allowed Buckets**:
```typescript
const ALLOWED_BUCKETS = ['abundance-temp', 'abundance-dev-temp', 'abundance-staging-temp'];
```

### Session Status Flow

```
┌───────────┐     ┌───────────┐     ┌───────────┐
│ uploading │────▶│ detecting │────▶│ detected  │
└───────────┘     └───────────┘     └───────────┘
      │                 │
      │                 ▼
      │           ┌───────────┐
      └──────────▶│  failed   │
                  └───────────┘
```

### Final Session Document Structure

```typescript
interface CaptureSession {
  id: string;
  userId: string;
  captureMode: 'single' | 'burst';
  status: 'uploading' | 'detecting' | 'detected' | 'failed';
  createdAt: Timestamp;
  detectedAt?: Timestamp;
  originalImageUrls: string[];
  imagesUploaded?: number;
  expectedImageCount?: number;
  detectedObjects?: Array<{
    groupId: string;
    label: string;
    category: string;
    attributes: Record<string, string>;
    confidence: string;
    croppedImageUrls: string[];
    boundingBoxes: Array<{
      imageIndex: number;
      box_2d: [number, number, number, number];
    }>;
  }>;
  reasoning?: string;
  error?: string;
  errorCode?: string;
}
```

---

## Appendix A: File References

| File | Purpose |
|------|---------|
| `functions/src/ai-pipeline/layer1/prompts.ts` | Model config, system prompt, timeouts |
| `functions/src/ai-pipeline/layer1/layer1-service.ts` | Core detection and cropping logic |
| `functions/src/ai-pipeline/layer1/schemas/detection-result.ts` | TypeScript interfaces and JSON schema |
| `functions/src/ai-pipeline/layer1/utils/bbox-converter.ts` | Coordinate conversion utilities |
| `functions/src/triggers/onSessionCreated.ts` | Firestore trigger orchestration |

---

## Appendix B: Example Detection Response

```json
{
  "objects": [
    {
      "groupId": "obj-a1b2c3d4",
      "label": "Apple MacBook Pro 14-inch",
      "category": "electronics",
      "box_2d": [120, 200, 450, 800],
      "image_index": 0,
      "confidence": "high",
      "attributes": {
        "color": "Space Gray",
        "brand": "Apple",
        "material": "aluminum"
      }
    },
    {
      "groupId": "obj-e5f6g7h8",
      "label": "Black leather office chair",
      "category": "furniture",
      "box_2d": [300, 50, 900, 400],
      "image_index": 0,
      "confidence": "medium",
      "attributes": {
        "color": "black",
        "material": "leather"
      }
    }
  ],
  "reasoning": "Detected 2 distinct catalogable objects: a laptop and an office chair."
}
```

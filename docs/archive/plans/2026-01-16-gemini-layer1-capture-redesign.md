# Gemini Layer 1 Capture Redesign

**Date:** 2026-01-16
**Status:** Approved
**Supersedes:** Stage 3.5 Multi-Image Capture Plan (partial)
**Estimated Effort:** 12 days

---

## Executive Summary

Replace on-device YOLOv11n object detection with Gemini 3 Flash for Layer 1 detection. This addresses fundamental limitations of the COCO-trained model (only 18 household classes) and enables proper multi-image object grouping.

**Key Changes:**
- Remove real-time YOLO detection from iOS client
- New UX: Double-tap (single photo), Long-press (burst capture)
- Gemini 3 Flash for object detection + bounding boxes
- Server-side cropping with sharp
- Preserve client-side fingerprinting for deduplication

**Benefits:**
- Detect ANY household object (vs 18 COCO classes)
- Native multi-image reasoning and grouping
- Reduced on-device compute and battery usage
- ~$0.04-0.05 per item (within budget)

---

## Problem Statement

### Current Architecture Limitations

The existing Layer 1 uses YOLOv11n trained on COCO 80 classes, with only 18 whitelisted as "household":

```
backpack, handbag, suitcase, umbrella, bottle, cup, fork, knife,
spoon, bowl, wine glass, chair, bed, dining table, tie, couch,
potted plant, toilet
```

**Missing categories:** Electronics (phones, laptops, TVs), kitchen appliances, books, toys, tools, sporting goods, most furniture, clothing, decor, etc.

**Root cause:** YOLOv11n is a closed-vocabulary detector. It cannot detect objects it wasn't trained on. The implementation is correct; the model is fundamentally unsuited for home inventory.

---

## Solution: Gemini 3 Flash for Layer 1

### Model Selection

| Model | Role | Cost | Rationale |
|-------|------|------|-----------|
| **Gemini 3 Flash** | Layer 1 (Detection) | ~$0.001/batch | Fast, cheap, open-vocabulary detection |
| **Gemini 3 Pro** | Layer 2 (Cataloging) | ~$0.04/item | Complex reasoning, tool calling |

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         NEW ARCHITECTURE                         │
│                                                                  │
│  iOS Client                                                      │
│  ├─ Camera preview (no live detection)                          │
│  ├─ Double-tap → capture single photo                           │
│  ├─ Long-press → burst capture (2-8 photos)                     │
│  ├─ Upload to GCS                                               │
│  ├─ Listen for Firestore updates                                │
│  └─ Fingerprint returned crops (VNFeaturePrint)                 │
│                                                                  │
│  Cloud Functions                                                 │
│  ├─ onSessionCreated                                            │
│  │   ├─ Fetch images from GCS                                   │
│  │   ├─ Call Gemini 3 Flash                                     │
│  │   ├─ Parse detections (box_2d format)                        │
│  │   ├─ Crop objects with sharp                                 │
│  │   └─ Update session doc                                      │
│  │                                                               │
│  └─ onItemCreated                                               │
│      ├─ Fetch crops from GCS                                    │
│      ├─ Call Gemini 3 Pro with tools                            │
│      └─ Update item with catalog data                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## UX Design

### Capture Modes

**Double-Tap (Single Photo)**
```
1. User sees camera preview (no live detection boxes)
2. User double-taps screen
3. Haptic feedback (impact) + camera shutter sound
4. Screen freezes on captured frame
5. "Scanning..." overlay with pulsing animation
6. Photo uploads to GCS (1-2s)
7. Gemini 3 Flash detects objects (1-2s)
8. Results appear: object cards with bounding boxes
9. User taps object → Layer 2 catalogs → Item created

Total latency: ~3-5 seconds from tap to seeing detected objects
```

**Long-Press (Burst Mode)**
```
1. User long-presses (>0.5s)
2. Haptic pulse begins (repeats every 0.5s)
3. Camera captures frame every 0.5s while pressed
4. Counter shows "3 photos..." "4 photos..."
5. User releases → "Analyzing..."
6. All photos upload in parallel
7. Gemini analyzes batch, groups same objects
8. Results: grouped object cards (multiple angles shown)
9. User confirms groupings → Layer 2 → Items created

Captures: 2-8 photos (1s min hold, 4s max hold)
```

### Visual States

| State | UI Treatment |
|-------|--------------|
| **Idle** | Clean camera preview, no overlays |
| **Capturing** | Brief flash + frozen frame |
| **Uploading** | Progress ring in center |
| **Analyzing** | Pulsing scan lines animation |
| **Results** | Object cards with bounding box overlays |
| **Cataloging** | Individual card shows spinner |
| **Complete** | Card shows checkmark |

### Results Screen

```
┌─────────────────────────────────────────────────────────────────┐
│  [Captured photo with bounding boxes]                           │
│                                                                  │
│      ┌──────────┐         ┌──────────┐                          │
│      │ Object 1 │         │ Object 2 │   ← Tappable boxes       │
│      │ "Lamp"   │         │ "Book"   │                          │
│      └──────────┘         └──────────┘                          │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  Detected Objects (2)                          [Catalog All]    │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────┐  Lamp                               [Catalog]          │
│  │ 📷  │  Gemini: "Table lamp, brass"                           │
│  └─────┘                                                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────┐  Book                               [Catalog]          │
│  │ 📷  │  Gemini: "Hardcover book"                              │
│  └─────┘                                                        │
├─────────────────────────────────────────────────────────────────┤
│            [Retake]                    [Done]                    │
└─────────────────────────────────────────────────────────────────┘
```

### Multi-Image Results (Burst Mode)

```
┌─────────────────────────────────────────────────────────────────┐
│  ┌─────┐ ┌─────┐ ┌─────┐  Mac Mini (3 angles)    [Catalog]     │
│  │Front│ │Back │ │Side │  Gemini: "Apple Mac Mini M2"          │
│  └─────┘ └─────┘ └─────┘  "Grouped from photos 1, 2, 4"         │
└─────────────────────────────────────────────────────────────────┘
```

### No Objects Detected

When Gemini detects no catalogable objects, it provides reasoning:

```json
{
  "objects": [],
  "reasoning": "The image shows a kitchen with built-in cabinets, countertops, and a window. These are permanent fixtures and not catalogable inventory items."
}
```

UI shows Gemini's explanation with tips and "Retake Photo" button. No manual entry option.

---

## Technical Specifications

### Gemini 3 Bounding Box Format

Gemini returns bounding boxes as `[ymin, xmin, ymax, xmax]` scaled to 0-1000:

```typescript
// Convert to absolute pixel coordinates
const absCoords = {
  x1: Math.round((box_2d[1] / 1000) * imageWidth),   // xmin
  y1: Math.round((box_2d[0] / 1000) * imageHeight),  // ymin
  x2: Math.round((box_2d[3] / 1000) * imageWidth),   // xmax
  y2: Math.round((box_2d[2] / 1000) * imageHeight)   // ymax
};
```

### Layer 1 System Prompt

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

### Layer 1 Response Schema

```typescript
export const LAYER1_DETECTION_SCHEMA = {
  type: "object",
  properties: {
    objects: {
      type: "array",
      items: {
        type: "object",
        properties: {
          groupId: {
            type: "string",
            description: "UUID for grouping same object across images"
          },
          label: {
            type: "string",
            description: "Specific descriptive name (e.g., 'Apple Mac Mini M2')"
          },
          category: {
            type: "string",
            description: "High-level category (electronics, furniture, kitchen, etc.)"
          },
          box_2d: {
            type: "array",
            items: { type: "integer" },
            minItems: 4,
            maxItems: 4,
            description: "[ymin, xmin, ymax, xmax] normalized 0-1000"
          },
          attributes: {
            type: "object",
            properties: {
              color: { type: "string" },
              material: { type: "string" },
              condition: { type: "string" },
              brand: { type: "string" }
            }
          },
          image_index: {
            type: "integer",
            description: "Which image this detection is from (0-indexed)"
          },
          confidence: {
            type: "string",
            enum: ["high", "medium", "low"]
          }
        },
        required: ["groupId", "label", "category", "box_2d", "image_index"]
      }
    },
    reasoning: {
      type: "string",
      description: "Explanation when no objects detected, or grouping logic for multi-image"
    }
  },
  required: ["objects"]
};
```

### Layer 1 API Configuration

```typescript
export const LAYER1_MODEL_ID = 'gemini-3-flash-preview';

export const LAYER1_CONFIG = {
  response_mime_type: 'application/json',
  response_json_schema: LAYER1_DETECTION_SCHEMA,
  thinking_config: {
    thinking_level: 'low'  // Optimized for detection speed
  }
};

// Per-part media resolution for cost optimization (560 tokens/image)
export function createImagePart(imageBase64: string, mimeType: string = 'image/jpeg') {
  return {
    inline_data: {
      mime_type: mimeType,
      data: imageBase64
    },
    media_resolution: { level: 'media_resolution_medium' }
  };
}
```

### Firestore Session Document

```typescript
interface CaptureSession {
  id: string;
  userId: string;
  captureMode: 'single' | 'burst';
  status: 'uploading' | 'detecting' | 'detected' | 'failed';
  createdAt: Timestamp;
  detectedAt?: Timestamp;

  originalImageUrls: string[];  // GCS temp bucket

  detectedObjects?: Array<{
    groupId: string;
    label: string;
    category: string;
    attributes: Record<string, string>;
    confidence: string;
    croppedImageUrls: string[];  // GCS items bucket
    boundingBoxes: Array<{
      imageIndex: number;
      box_2d: [number, number, number, number];
    }>;
  }>;

  reasoning?: string;  // For empty results
  error?: string;
  errorCode?: string;
}
```

### GCS Bucket Structure

```
gs://abundance-temp/                    # Auto-delete after 24h
└── {sessionId}/
    ├── original_0.jpg
    ├── original_1.jpg
    └── original_2.jpg

gs://abundance-items/                   # Permanent storage
└── {userId}/
    ├── {groupId}_crop_0.jpg
    ├── {groupId}_crop_1.jpg
    └── {groupId}_crop_2.jpg
```

---

## Fingerprinting Integration

Fingerprinting remains client-side using VNFeaturePrint:

```
1. Server returns cropped images in session doc
2. iOS downloads first crop per object
3. Convert to CVPixelBuffer
4. Generate VNFeaturePrint (existing ObjectDeduplicator)
5. Check against local cache (5-min TTL)
   └─► If match: Query Firestore for item with same fingerprint
6. If duplicate found:
   └─► Show "Already cataloged" badge
   └─► [Catalog] becomes [Add Photos] (links to existing)
7. If new:
   └─► Cache fingerprint
   └─► [Catalog] creates new item
```

---

## Error Handling

### Error States & Recovery

| Stage | Error | Recovery |
|-------|-------|----------|
| Upload | Network timeout | Retry 3x with backoff |
| Upload | Auth expired | Refresh token, retry |
| Layer 1 | Gemini timeout (>30s) | Retry 1x, then fail |
| Layer 1 | No objects detected | Show reasoning, offer retake |
| Layer 1 | Invalid JSON | Retry 1x, then fail |
| Cropping | Invalid bounding box | Skip that object |
| Cropping | sharp error | Skip that crop |
| Layer 2 | Gemini timeout | Mark "pending", retry |
| Layer 2 | Tool failure | Continue without tool |
| Fingerprint | VNFeaturePrint fails | Continue without fingerprint |

### Timeout Configuration

```typescript
export const TIMEOUTS = {
  GEMINI_FLASH_TIMEOUT_MS: 30000,      // 30s per batch
  GEMINI_FLASH_MAX_RETRIES: 2,
  IMAGE_FETCH_TIMEOUT_MS: 10000,       // 10s per image
  CROP_OPERATION_TIMEOUT_MS: 5000,     // 5s per crop
  GEMINI_PRO_TIMEOUT_MS: 60000,        // 60s (includes tools)
  FUNCTION_TIMEOUT_SECONDS: 120,       // 2 minutes total
  MAX_WAIT_FOR_DETECTION_MS: 45000,    // Client-side timeout
};
```

---

## Cost Analysis

### Per-Request Costs

**Layer 1 (Gemini 3 Flash):**
- Single image: ~$0.00138
- Burst (4 images): ~$0.00252

**Layer 2 (Gemini 3 Pro + Tools):**
- Per object: ~$0.04

### Monthly Projections

| Usage | Items/Month | Cost |
|-------|-------------|------|
| Light | 100 | ~$4 |
| Moderate | 500 | ~$21 |
| Heavy | 2,000 | ~$83 |
| Power | 5,000 | ~$208 |

**Budget:** $554/month → Supports up to ~13,000 items/month

### Cost Optimizations

| Strategy | Savings |
|----------|---------|
| Context caching | 90% on repeated prompts |
| Resolution tuning | 50% on simple scenes |
| Skip tools for duplicates | $0.029/item |
| `thinking_budget=0` | 10-20% on Layer 1 |

---

## Implementation Plan

### Phase 1: Cloud Functions + Gemini Flash (3 days)

**Files to create:**
```
functions/src/ai-pipeline/layer1/
├── layer1-service.ts
├── prompts.ts
├── schemas/detection-result.ts
└── utils/bbox-converter.ts

functions/src/triggers/
└── onSessionCreated.ts
```

**Tasks:**
- [ ] Create Gemini 3 Flash client with `thinking_level: low`
- [ ] Create detection prompt and schema
- [ ] Implement `onSessionCreated` Cloud Function
- [ ] Implement server-side cropping with `sharp`
- [ ] Add GCS temp bucket with 24h lifecycle rule
- [ ] Write unit tests

### Phase 2: iOS Capture Flow Refactor (3 days)

**Files to create/modify:**
```
Sources/CameraFeature/
├── ViewModels/CaptureSessionViewModel.swift    # NEW
├── Views/CaptureView.swift                     # REPLACE
├── Views/CaptureOverlay.swift                  # NEW
├── Models/DetectedObjectVM.swift               # NEW
└── Models/CaptureError.swift                   # NEW
```

**Tasks:**
- [ ] Create `CaptureSessionViewModel` with upload logic
- [ ] Implement double-tap gesture handler
- [ ] Implement long-press burst capture
- [ ] Add Firestore listener for session updates
- [ ] Create scanning/uploading animations
- [ ] Remove YOLO frame processing code

### Phase 3: Results UI + Fingerprinting (2 days)

**Files to create:**
```
Sources/CameraFeature/Views/
├── DetectionResultsView.swift
├── DetectedObjectCard.swift
├── BoundingBoxOverlay.swift
└── NoObjectsDetectedView.swift
```

**Tasks:**
- [ ] Create results view with object cards
- [ ] Implement bounding box overlay
- [ ] Add thumbnail strip for multi-angle objects
- [ ] Integrate fingerprinting on crop download
- [ ] Create empty state view with Gemini reasoning

### Phase 4: Layer 2 Updates + Testing (2 days)

**Tasks:**
- [ ] Update `onItemCreated` for new item schema
- [ ] Ensure Layer 2 handles multiple crop URLs
- [ ] Test full pipeline: single photo → catalog
- [ ] Test full pipeline: burst → catalog
- [ ] Test duplicate detection + linking

### Phase 5: Polish + Edge Cases (2 days)

**Tasks:**
- [ ] Error handling for all failure modes
- [ ] Timeout handling with user feedback
- [ ] Haptic feedback tuning
- [ ] Animation polish
- [ ] Remove unused YOLO code
- [ ] Write ADR for architecture change

---

## Migration Checklist

**Before deployment:**
- [ ] Deploy Cloud Functions to staging
- [ ] Test with TestFlight build
- [ ] Verify GCS bucket permissions
- [ ] Confirm Vertex AI quotas
- [ ] Set up cost monitoring alerts

**Cleanup (after stable):**
- [ ] Remove `HouseholdItemDetector.swift`
- [ ] Remove `YOLOv11n.mlmodelc` from bundle
- [ ] Remove `ImageQualityAssessor.swift`
- [ ] Archive old `CameraDetectionViewModel.swift`

---

## Success Criteria

| Metric | Target |
|--------|--------|
| Object detection coverage | Any household item |
| Single photo latency | < 6 seconds end-to-end |
| Burst (4 photos) latency | < 8 seconds end-to-end |
| Detection accuracy | > 90% for common items |
| Grouping accuracy | > 85% same-object matching |
| Cost per item | < $0.05 |
| Error rate | < 2% |

---

## References

- Gemini 3 Object Detection Spec: `docs/specs/Abundance_Gemini3_Object_Detection_Spec.md`
- Gemini 3 Pipeline Design: `docs/plans/2026-01-13-gemini-3-pipeline-design.md`
- Stage 3.5 Multi-Image Plan: `docs/plans/2026-01-14-stage-3.5-multi-image-capture-plan.md`

---

**Approved:** 2026-01-16

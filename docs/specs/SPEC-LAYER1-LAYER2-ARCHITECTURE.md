# SPEC: Layer 1 / Layer 2 Pipeline Architecture

**Created:** 2026-01-17
**Status:** Active
**Author:** System Design Session

---

## Overview

This document captures architectural decisions for the two-layer AI cataloging pipeline:

- **Layer 1 (Standard):** Gemini 3 Flash - Object detection, cropping, and basic cataloging
- **Layer 2 (Premium):** Gemini 3 Pro - Enhanced accuracy, condition assessment, valuation

---

## Tier Model

### Standard Tier (Layer 1 Only)

**Trigger:** Automatic on capture
**Model:** Gemini 3 Flash
**Cost:** ~$0.002/item

**Capabilities:**
- Object detection with bounding boxes
- Multi-image grouping (same object, different angles)
- Server-side cropping
- Basic cataloging:
  - Name/label (specific: "Apple Mac Mini M2")
  - Brand
  - Model
  - Category
  - Sub-category
  - Color
  - Material (when visible)
  - Confidence score

**Output:** Pre-catalogued items visible in Catalog View

### Premium Tier (Layer 2)

**Trigger:** User taps "Catalog" button (manual)
**Model:** Gemini 3 Pro with tool calling
**Cost:** ~$0.04/item (includes Google Lens, barcode lookup, web search)

**Capabilities (additive to Layer 1):**
- Condition assessment (new, like-new, good, fair, poor)
- Estimated value/price range
- Improved accuracy (model reasoning)
- Product identification via:
  - Google Lens visual search
  - Barcode lookup (UPC/EAN)
  - Web search for pricing
- Processing notes/reasoning

**Output:** Fully catalogued items with valuation

---

## UX Design Principles

### Background Processing (No Blocking UI)

**Critical:** Layer 1 processing should happen in the background without blocking the camera UI:

1. **After capture:** User immediately returns to live camera preview
2. **Processing indicator:** Small, non-intrusive badge or status (not a modal/overlay)
3. **Results appear in Catalog View:** User navigates to Catalog tab to see detected items
4. **No approval needed at capture time:** The detection just happens

**Anti-pattern to avoid:** A full-screen "Detecting..." overlay that blocks the camera. Users want to keep capturing.

### Catalog Approval in Catalog View (Not Camera)

The "Catalog" button (Layer 2 trigger) lives in the **Catalog View**, not the Camera View:

- User sees pre-catalogued items in Catalog tab
- Each item card shows: thumbnail, name, brand, category, "Pre-catalogued" badge
- Tap item → Detail view with "Catalog" button to trigger Layer 2 (Premium)
- User can also edit fields manually, add photos, or accept as-is

**Rationale:** Separating capture from review allows faster capture sessions and thoughtful review later.

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  iOS App: Capture                                                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  User captures photo(s) in burst mode                                        │
│       ↓                                                                      │
│  HTTP POST to Cloud Function (images in body, NO Firebase Storage)           │
│       │                                                                      │
│       ├── Images: [image1, image2, image3] (base64 or multipart)            │
│       ├── Fingerprints: [fp1, fp2, fp3] (for cross-session dedup)           │
│       ├── userId: string                                                     │
│       └── metadata: { deviceModel, captureTimestamp, etc. }                  │
│                                                                              │
│  Original images: NEVER stored (discarded after processing)                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  Cloud Function: Layer 1 (Gemini 3 Flash)                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. Receive images directly (no Storage fetch)                               │
│  2. Call Gemini 3 Flash for detection + basic cataloging                     │
│  3. Extract:                                                                 │
│       - Bounding boxes (groupId, box_2d, image_index)                        │
│       - Object details (name, brand, model, category, subCategory, color)    │
│       - Confidence level                                                     │
│  4. Crop detected objects with sharp                                         │
│  5. Upload ONLY cropped images to Firebase Storage                           │
│  6. Create Firestore documents:                                              │
│       - items/{itemId} with status="pre-catalogued"                          │
│       - Full Layer 1 data stored                                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  iOS App: Catalog View (Review)                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  User sees pre-catalogued items with:                                        │
│       - Cropped thumbnail                                                    │
│       - Name, brand, category (from Layer 1)                                 │
│       - "Pre-catalogued" badge                                               │
│                                                                              │
│  User actions:                                                               │
│       - Edit any field manually                                              │
│       - Add more photos (HTTP POST → Layer 1 again)                          │
│       - Tap "Catalog" button → triggers Layer 2 (Premium)                    │
│       - Accept as-is (remains pre-catalogued)                                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓ (User taps "Catalog")
┌─────────────────────────────────────────────────────────────────────────────┐
│  Cloud Function: Layer 2 (Gemini 3 Pro) - PREMIUM                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Trigger: HTTP call when user taps "Catalog" button                          │
│           (NOT automatic Firestore trigger)                                  │
│                                                                              │
│  1. Fetch cropped image(s) from Firebase Storage                             │
│  2. Call Gemini 3 Pro with tool calling:                                     │
│       - google_lens_search (visual product matching)                         │
│       - barcode_lookup (if barcode detected)                                 │
│       - web_search (pricing, product details)                                │
│  3. Extract enhanced data:                                                   │
│       - Refined name/brand/model                                             │
│       - Condition assessment                                                 │
│       - Estimated value range                                                │
│       - Processing notes                                                     │
│  4. Update Firestore document:                                               │
│       - status="complete"                                                    │
│       - Merge Layer 2 data with Layer 1                                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Layer 1 Schema (Pre-Catalogue)

Items created by Layer 1 should include:

```typescript
interface PreCataloguedItem {
  // Identity
  id: string;
  userId: string;
  status: 'pre-catalogued';

  // Layer 1 Detection
  groupId: string;                    // For multi-image grouping
  croppedImageUrls: string[];         // Firebase Storage URLs
  boundingBoxes: BoundingBox[];       // Original detection boxes

  // Layer 1 Cataloging (Gemini Flash extracts these)
  name: string;                       // Specific: "Apple Mac Mini M2"
  brand: string | null;               // "Apple", "Samsung", etc.
  model: string | null;               // "Mac Mini M2", "Galaxy S24"
  category: string;                   // "electronics", "furniture"
  subCategory: string | null;         // "computers", "seating"
  color: string | null;               // "silver", "black"
  material: string | null;            // "aluminum", "leather"
  confidence: 'high' | 'medium' | 'low';

  // Metadata
  fingerprints: string[];             // iOS VNFeaturePrint hashes
  capturedAt: Timestamp;
  createdAt: Timestamp;
  updatedAt: Timestamp;

  // Layer 2 fields (null until premium cataloging)
  condition: string | null;           // Filled by Layer 2
  estimatedValue: number | null;      // Filled by Layer 2
  processingNotes: string | null;     // Filled by Layer 2
}
```

---

## Multi-Image Handling

### Single HTTP Request for Burst Captures

When user captures multiple angles of the same scene:

1. All images sent in ONE HTTP request
2. Gemini Flash sees all images simultaneously
3. Visual grouping: "Images 1, 2, 3 show the same mug → groupId: abc"
4. Creates separate crops per image, linked by groupId
5. Single Firestore document per unique object (not per image)

**Rationale:** Gemini Flash can visually determine "same object, different angle" when it sees all images at once. Separate requests would require unreliable post-hoc reconciliation.

### Add More Photos Flow

When user adds photos to an existing pre-catalogued item:

1. HTTP POST with new images + existing itemId
2. Layer 1 processes new images only
3. New crops appended to existing item's `croppedImageUrls`
4. Layer 1 data may be updated if new images provide better view
5. Optional: Hard limit of N photos per item (e.g., 5)

**Note:** We do NOT re-process all images. We only detect on new images and append crops.

---

## Storage Architecture

### What Gets Stored

| Content | Storage Location | Lifecycle |
|---------|------------------|-----------|
| Original captures | **NEVER STORED** | Discarded after Layer 1 |
| Cropped objects | Firebase Storage | Permanent (user's inventory) |
| Fingerprint hashes | Firestore (item doc) | Permanent |
| Layer 1 metadata | Firestore (item doc) | Permanent |
| Layer 2 metadata | Firestore (item doc) | Permanent |

### Storage Path

```
gs://abundance-mvp.firebasestorage.app/
└── users/{userId}/items/
    ├── {groupId}_crop_0.jpg    (cropped object, angle 1)
    ├── {groupId}_crop_1.jpg    (cropped object, angle 2)
    └── ...
```

---

## Future Considerations (Not Implemented Now)

### Premium vs Standard Settings

- Setting to auto-trigger Layer 2 without manual tap
- Premium subscription management
- Usage limits/quotas per tier

### Optimizations

- iOS-side image compression before upload (reduce transfer)
- WebP format for crops (30% smaller than JPEG)
- Lifecycle policy for temporary storage (if any)

---

## Open Questions

1. **Hard limit on photos per item?** Suggested: 5 photos max
2. **Re-detection on add-more-photos?** Decision: Only detect new, append crops
3. **Fingerprint storage format?** Decision: SHA256 hash string from iOS

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-17 | 1.0 | Initial spec from architecture discussion |

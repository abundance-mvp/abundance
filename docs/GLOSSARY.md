# Abundance Terminology Glossary

> **Source of truth** for terminology across UI, code, and documentation.
> See [ADR-027](adr/ADR-027-terminology-standardization.md) for rationale.

---

## Quick Reference: Term Mapping Matrix

| Concept | User Sees | Swift Code | Backend/Pipeline | Forbidden Aliases |
|---------|-----------|------------|-----------------|-------------------|
| User's items | **Collection** | `CollectionFeature`, `CollectionView`, `CollectionViewModel` | — | ~~inventory~~, ~~catalog~~ (as noun) |
| Camera tab | **Scan** | `ScanFeature`, `CaptureView` | — | ~~camera~~ (as tab label) |
| Single photo | **Photo** | `CaptureMode.single` | — | |
| Multi-photo | **Burst** | `CaptureMode.burst` | — | |
| Pan + segment | **Sweep** | `CaptureMode.sweep`, `EdgeTAMFeature` | EdgeTAM segmentation | |
| User account | **Profile** | `ProfileFeature`, `ProfileView` | — | |
| AI processing (first time) | **Analyzing...** | `ItemStatus.processing` | Layer 1 Detection → Layer 2 Cataloging | |
| AI re-run on existing images | **Refresh** | `refreshItem()` | Layer 2 re-run | ~~deep scan~~, ~~super scan~~, ~~re-catalog~~, ~~super catalog~~ |
| New photo + AI re-run | **Rescan** | `rescanItem()` | New capture → Layer 1 → Layer 2 | |
| AI done | **Ready** | `ItemStatus.complete` | `complete` | |
| AI failed | **Try Again** | `ItemStatus.failed` | `failed` | |
| Single cataloged object | **Item** | `Item` | Firestore `items/{id}` | |

---

## Two Domains

### User Domain (UI, product copy, onboarding, support)

These are the ONLY terms users should ever see:

| Term | Where It Appears | Meaning |
|------|-----------------|---------|
| **Collection** | Tab bar label, empty states, onboarding | The user's set of cataloged items |
| **Scan** | Tab bar label, mode picker area | The camera/capture experience |
| **Photo** | Mode selector | Single-capture mode (double-tap) |
| **Burst** | Mode selector | Multi-capture mode (long-press, 2-8 photos) |
| **Sweep** | Mode selector (iPhone 15 Pro+) | Pan-and-select segmentation mode |
| **Profile** | Tab bar label | User account and settings |
| **Item** | Cards, detail views | One cataloged object |
| **Refresh** | Button on item detail | Re-run AI analysis on existing photos |
| **Rescan** | Button/prompt on item detail | Take new photo and re-analyze |
| **Analyzing...** | Status indicator | AI is processing (first time or refresh) |
| **Ready** | Status badge | AI processing complete |
| **Try Again** | Status badge + action | AI processing failed |

### Machine Domain (code internals, pipeline specs, architecture docs)

These terms are used in backend code, pipeline documentation, and architecture discussions. They MUST NOT appear in UI strings.

| Term | Meaning | Used In |
|------|---------|---------|
| **Layer 1 Detection** | Gemini Flash object detection (bounding boxes, crops) | `SPEC-PIPE-001`, Cloud Functions |
| **Layer 2 Cataloging** | Gemini Pro product identification with tool calling | `SPEC-PIPE-002`, Cloud Functions |
| **Layer 2a** | Initial Gemini Pro analysis (visual only) | Firestore status field |
| **Layer 2b** | Extended Gemini Pro analysis (Lens + barcode + web search) | Firestore status field |
| **EdgeTAM** | On-device segmentation model (Meta SAM, CoreML) | `EdgeTAMFeature`, `SPEC-PIPE-004` |
| **Segment** | Individual object mask from EdgeTAM | `SegmentedObject` model |
| **CatalogService** | Internal service orchestrating Layer 1→2 pipeline | `CameraFeature/Services/` |
| **CaptureSession** | Firestore document tracking a capture event | `sessions/{id}` collection |
| **DetectedObject** | Layer 1 output: bounding box + label + confidence | `ServerDetectedObject` |

---

## Capture Modes: Full Specification

| Mode | User Label | Gesture | Output | Code |
|------|-----------|---------|--------|------|
| **Photo** | "Photo" | Double-tap | 1 photo | `CaptureMode.single` |
| **Burst** | "Burst" | Long-press (1-4s) | 2-8 photos | `CaptureMode.burst` |
| **Sweep** | "Sweep" | Pan camera + tap segments | N segments → N items | `CaptureMode.sweep` |

---

## Item Lifecycle: User Terms → Pipeline Stages

```
User action          User sees            Pipeline (hidden)
─────────────        ─────────            ─────────────────
Scan item        →   "Analyzing..."   →   Upload → Layer 1 Detection → Layer 2 Cataloging
                 →   "Ready"          →   Item complete with metadata
                 →   "Try Again"      →   Pipeline error

Refresh item     →   "Analyzing..."   →   Layer 2 re-run on existing images
                 →   "Ready"          →   Updated metadata

Rescan item      →   Camera opens     →   New photo captured
                 →   "Analyzing..."   →   Upload → Layer 1 → Layer 2
                 →   "Ready"          →   Updated metadata + new photo
```

---

## Navigation Structure

| Tab | Icon | Label | Module |
|-----|------|-------|--------|
| 1 | `square.grid.2x2` | **Collection** | `CollectionFeature` |
| 2 | `camera` | **Scan** | `CameraFeature` → `ScanFeature` |
| 3 | `person` | **Profile** | `ProfileFeature` |

---

## Code Rename Guide

When creating new code, use these conventions:

### Views and ViewModels
```
CollectionView          (was: InventoryView)
CollectionViewModel     (was: InventoryViewModel)
ItemDetailView          (unchanged)
ItemCard                (unchanged)
CaptureView             (unchanged — internal, not user-facing)
```

### Methods
```
refreshItem()           (was: requestDeepScan(), recatalogItem())
rescanItem()            (unchanged)
```

### Properties
```
refreshRequested: Bool  (was: deepScanRequested)
isRefreshing: Bool      (was: isDeepScanning)
```

### Firestore Fields (DO NOT RENAME — use code aliases)
```
// Firestore field: "deepScanRequested"
// Swift property: "refreshRequested"
// Map via CodingKeys or computed property
```

---

## Anti-Patterns

**Never do this:**
- Show "Layer 1" or "Layer 2" in any UI text
- Use "inventory" in user-facing strings
- Use "deep scan" or "super scan" anywhere (code or UI)
- Use "catalog" as a noun for the user's collection (it's "Collection")
- Use "camera" as a tab label (it's "Scan")

**Always do this:**
- Use "Collection" for the items tab
- Use "Scan" for the camera tab
- Use "Refresh" for AI re-run on existing images
- Use "Rescan" for new photo + AI re-run
- Use "Analyzing..." for any AI processing status
- Use "Item" for a single cataloged object

# SPEC-PIPE-004-A: Camera Sweep Cataloging — EdgeTAM Option

**Created:** 2026-02-07
**Status:** Draft (Pending ADR)
**Author:** Claude Code
**Depends On:** SPEC-PIPE-001, SPEC-UI-001, SPEC-ARCH-002
**Device Target:** iPhone 15 Pro+ (A17 Pro, 35 TOPS Neural Engine)

---

## 1. Overview

### What This Is

A new capture mode ("Sweep Mode") where the user points their camera at a shelf and pans across it. EdgeTAM — a CoreML port of Meta's on-device segment-anything model — runs per-frame segmentation, showing real-time object contours as the user pans. The user taps segments to select items for cataloging, then the selected crops flow through the existing Layer 1 (Flash) → Layer 2 (Pro) pipeline.

### What This Is NOT

- Not a replacement for the existing double-tap / burst capture flow (SPEC-UI-001)
- Not a replacement for Layer 1 Gemini Flash detection — EdgeTAM provides on-device pre-processing only
- Not a tracking system — EdgeTAM runs per-frame segmentation (no memory bank in CoreML export)

### Why EdgeTAM

| Property | EdgeTAM | VNGenerateForegroundInstanceMaskRequest |
|----------|---------|----------------------------------------|
| Promptable | Yes (points, boxes, masks) | No (automatic foreground only) |
| Multi-instance | Yes (separate masks per object) | Yes (via `allInstances` IndexSet) |
| Quality (DAVIS J&F) | 87.7 | Not published (lower) |
| Model size | ~20 MB (3 CoreML packages) | Built-in (0 MB) |
| CoreML maturity | Early (community-contributed) | Production (Apple first-party) |
| Claimed FPS (iPhone 15 Pro) | 16 FPS (paper) | 12-20 FPS (estimated from 50-80ms) |
| Real-world FPS (unvalidated) | **1-16 FPS (unknown — must benchmark)** | 8-12 FPS (realistic estimate) |

### Critical Risk

**The EdgeTAM paper's 16 FPS claim may exclude image encoder time.** GitHub Issue #24 reports that including the encoder drops performance ~15x. Real-world FPS could be 1-2 FPS. This spec assumes the worst case and designs the UX to be viable at 1 FPS.

A **Day 1 benchmark spike** (Section 9) is required before committing to full implementation.

---

## 2. Architecture

### Pipeline Position

```
                        NEW (on-device)                    EXISTING (cloud)
                    ┌─────────────────────┐          ┌─────────────────────┐
                    │   Sweep Mode        │          │   Layer 1           │
Camera frames ────▶ │   EdgeTAM CoreML    │──crops──▶│   Gemini 3 Flash    │
  (30 FPS)          │   (1-16 FPS)        │          │   (detection)       │
                    └─────────────────────┘          └─────────────────────┘
                              │                                │
                        User taps to                     ┌─────────────────────┐
                        select segments                  │   Layer 2           │
                                                         │   Gemini 3 Pro      │
                                                         │   (cataloging)      │
                                                         └─────────────────────┘
```

### Component Diagram

```
┌─ CameraFeature ──────────────────────────────────────────────────────────┐
│                                                                           │
│  CameraService.framePublisher (CVPixelBuffer stream, 30 FPS)             │
│       │                                                                   │
│       ▼                                                                   │
│  ┌─ EdgeTAMFeature (NEW SPM target) ────────────────────────────────┐    │
│  │                                                                    │    │
│  │  EdgeTAMService                                                    │    │
│  │  ├─ Loads 3 CoreML models (~20 MB total)                          │    │
│  │  ├─ Runs image encoder on keyframes (not every frame)             │    │
│  │  ├─ Runs prompt encoder + mask decoder per user tap               │    │
│  │  └─ Returns: [SegmentedObject] with mask + bounding box           │    │
│  │                                                                    │    │
│  │  Resources/                                                        │    │
│  │  ├─ edgetam_image_encoder.mlpackage    (~10 MB)                   │    │
│  │  ├─ edgetam_prompt_encoder.mlpackage   (~2 MB)                    │    │
│  │  └─ edgetam_mask_decoder.mlpackage     (~8 MB)                    │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│       │                                                                   │
│       ▼                                                                   │
│  SweepCaptureViewModel (state machine)                                    │
│  ├─ Manages segment selection state                                       │
│  ├─ Drives overlay rendering                                              │
│  └─ Triggers crop + upload for selected segments                          │
│       │                                                                   │
│       ▼                                                                   │
│  SweepCaptureView (SwiftUI overlay)                                       │
│  ├─ Renders segment masks as translucent overlays                         │
│  ├─ Tap gesture → select/deselect                                         │
│  └─ Selection tray at bottom                                              │
│                                                                           │
└─ VisionCore ──────────────────────────────────────────────────────────────┘
   ├─ ObjectDeduplicator (VNFeaturePrint — prevents double-selection)
   ├─ BarcodeDetector (runs in parallel during sweep)
   └─ PixelBufferCropper (crops selected segments for upload)
```

---

## 3. EdgeTAM CoreML Integration

### Model Components

| Component | Input | Output | Size |
|-----------|-------|--------|------|
| Image Encoder | 1024×1024 RGB image | 256-channel feature map (64×64) | ~10 MB |
| Prompt Encoder | Up to 4 points + 1 box + 1 mask | Sparse + dense embeddings | ~2 MB |
| Mask Decoder | Encoder features + prompt embeddings | Segmentation mask + IoU score | ~8 MB |

### Inference Strategy

**Key insight:** The image encoder is the bottleneck (~60-900ms depending on device). The prompt encoder + mask decoder are fast (~5-15ms). So:

1. **Encode once per keyframe** — Run image encoder when the camera moves to a new region (every 0.5-1s, or when frame difference exceeds threshold)
2. **Decode on tap** — When user taps a point, run prompt encoder + mask decoder on the cached features (~15ms, feels instant)
3. **Auto-segment on keyframe** — Optionally run a grid of prompt points on each keyframe to show "candidate segments" before the user taps

```
Camera frame (30 FPS)
    │
    ├─ Every frame: check motion delta (is camera moving?)
    │
    ├─ On keyframe (every 0.5-1s or on stabilization):
    │   └─ Run image encoder → cache features
    │   └─ Run grid prompts (4×4 grid) → show candidate segments
    │
    └─ On user tap:
        └─ Run prompt encoder + mask decoder on cached features → instant mask
```

### Model Loading

```swift
/// EdgeTAM model manager — loads CoreML models lazily
public actor EdgeTAMService {

    private var imageEncoder: MLModel?
    private var promptEncoder: MLModel?
    private var maskDecoder: MLModel?
    private var cachedFeatures: MLMultiArray?

    /// Load models on first use. ~200ms cold start.
    /// Call during sweep mode entry, not app launch.
    public func warmup() async throws {
        let config = MLModelConfiguration()
        config.computeUnits = .all  // CPU + GPU + Neural Engine

        imageEncoder = try MLModel(contentsOf: /* bundled URL */, configuration: config)
        promptEncoder = try MLModel(contentsOf: /* bundled URL */, configuration: config)
        maskDecoder = try MLModel(contentsOf: /* bundled URL */, configuration: config)
    }

    /// Encode a frame's features. This is the slow operation.
    public func encodeFrame(_ pixelBuffer: CVPixelBuffer) async throws -> MLMultiArray {
        // Resize to 1024×1024, normalize, run encoder
        // Cache result for subsequent prompt decoding
    }

    /// Decode a mask from a tap point. This is fast (~15ms).
    public func decodeMask(
        at point: CGPoint,
        features: MLMultiArray
    ) async throws -> SegmentedObject {
        // Run prompt encoder with single point
        // Run mask decoder
        // Return mask + bounding box + IoU confidence
    }
}
```

### Device Eligibility

```swift
/// Check if device supports EdgeTAM sweep mode
public static var isSweepModeAvailable: Bool {
    // Require A17 Pro or later (iPhone 15 Pro, 15 Pro Max, 16 Pro, etc.)
    var sysinfo = utsname()
    uname(&sysinfo)
    let machine = String(bytes: Data(bytes: &sysinfo.machine,
                                      count: Int(_SYS_NAMELEN)),
                         encoding: .ascii)?
        .trimmingCharacters(in: .controlCharacters) ?? ""

    // iPhone16,1 = iPhone 15 Pro, iPhone16,2 = iPhone 15 Pro Max
    // iPhone17,x = iPhone 16 Pro family
    let proModels = ["iPhone16,1", "iPhone16,2", "iPhone17,1",
                     "iPhone17,2", "iPhone17,3", "iPhone17,4"]
    return proModels.contains(machine) || machine >= "iPhone17,"
}
```

---

## 4. UX Design

### Entry Point

Sweep mode is a **third capture mode** alongside double-tap (single) and long-press (burst). It is accessed via a mode toggle in the camera UI, visible only on eligible devices.

```
┌─────────────────────────────────────┐
│          Camera Preview              │
│                                      │
│   (segments appear as user pans)     │
│                                      │
│      ╭───────╮    ╭───────╮         │
│      │ Mug ✓ │    │ Book  │         │
│      ╰───────╯    ╰───────╯         │
│                                      │
│         ╭───────╮                    │
│         │ Lamp  │                    │
│         ╰───────╯                    │
│                                      │
├──────────────────────────────────────┤
│  Selected: 1 of 3          [Catalog] │
├──────────────────────────────────────┤
│  ┌─────┐                             │
│  │ Mug │  ← selection tray           │
│  └─────┘                             │
├──────────────────────────────────────┤
│  [Photo]   [Burst]   [● Sweep]      │
└──────────────────────────────────────┘
```

### Visual States

| State | Camera Preview | Overlays | Bottom Bar |
|-------|---------------|----------|------------|
| **Scanning** | Live feed | Candidate segments appear/disappear as camera moves | "Pan across items..." |
| **Segment visible** | Live feed | Translucent colored overlay on each detected segment | Object count |
| **Segment selected** | Live feed | Selected segments get solid border + checkmark | Selection tray + "Catalog" button |
| **Processing** | Frozen on last frame | Selected segments highlighted | "Uploading N items..." |
| **Complete** | Returns to live | Segments fade out | "N items cataloged ✓" |

### Segment Appearance

**Unselected segment:**
- Translucent white overlay (20% opacity) following the mask contour
- Thin white border (1pt)
- Subtle pulsing animation (opacity 15-25%, 2s cycle)

**Selected segment:**
- Translucent blue overlay (30% opacity)
- Solid blue border (2pt)
- Checkmark badge in top-right corner
- Thumbnail added to selection tray

**Duplicate segment (already selected from different angle):**
- Translucent yellow overlay (20% opacity)
- "Already selected" badge
- Tapping shows the original selection in the tray

### Feedback Signals

| Event | Haptic | Visual | Audio |
|-------|--------|--------|-------|
| New segment appears | `.light` impact (throttled: max 1 per 500ms) | Segment fades in over 200ms | — |
| Segment tapped (select) | `.medium` impact | Blue highlight + checkmark, thumbnail slides into tray | Soft "tick" |
| Segment tapped (deselect) | `.light` impact | Highlight removed, thumbnail slides out of tray | — |
| Duplicate detected | `.warning` notification | Yellow highlight + "Already selected" | — |
| Catalog initiated | `.success` notification | Selected segments pulse, progress bar appears | — |

### Performance-Adaptive UX

If EdgeTAM runs slower than expected, the UX degrades gracefully:

| FPS | Experience |
|-----|-----------|
| **10-16 FPS** | Premium: segments update smoothly as camera pans, feels like AR |
| **4-9 FPS** | Good: segments appear with slight lag, noticeable but usable |
| **1-3 FPS** | Acceptable: segments appear in "snapshots" every ~1s. Camera preview stays smooth (30 FPS). Segments catch up when user pauses. A "Scanning..." indicator pulses to set expectations. |
| **<1 FPS** | Fallback: auto-switch to "tap to scan" mode. User taps a region → EdgeTAM processes that single frame → segments appear for selection. No continuous scanning. |

---

## 5. Deduplication

### Problem

User pans right across shelf, then pans left back over it. The same coffee mug appears in frame 12 and frame 89 from slightly different angles.

### Solution: Tiered Deduplication

**Tier 1 — VNFeaturePrint (existing, fast)**

Already in `ObjectDeduplicator.swift`. Cosine distance on perceptual hashes. Works for same-angle re-detection (overlapping frames from a single pan).

**Tier 2 — ARKit spatial position (if ARSession available)**

If the device runs an `ARWorldTrackingConfiguration` during sweep mode, each segment gets a 3D world coordinate. Segments within 15cm of each other in world space are the same object regardless of visual appearance.

```swift
/// Project segment center to 3D world position
func worldPosition(for segment: SegmentedObject,
                   frame: ARFrame) -> simd_float3? {
    let center = segment.boundingBox.center  // normalized 2D
    let screenPoint = CGPoint(
        x: CGFloat(center.x) * frame.camera.imageResolution.width,
        y: CGFloat(center.y) * frame.camera.imageResolution.height
    )
    // Raycast into scene mesh or point cloud
    guard let result = frame.raycastQuery(
        from: screenPoint,
        allowing: .estimatedPlane,
        alignment: .any
    ) else { return nil }
    return result.worldTransform.columns.3.xyz
}
```

**Tier 3 — Temporal + spatial heuristic**

If no ARSession: segments near opposite frame edges in consecutive frames that have similar VNFeaturePrint distances are likely the same object (camera panning).

### Multi-Angle Grouping

When the user walks around an object and taps it from multiple angles, the system must group those taps as views of the same item:

1. If ARKit is active: same world position → same object → add crop as additional view
2. If no ARKit: VNFeaturePrint + MobileCLIP embedding comparison → group if similarity > threshold
3. All crops for a grouped object are sent together to Layer 1 Flash with context: "These images show the same object from different angles"

---

## 6. Integration with Existing Pipeline

### Upload Flow

Selected segments flow into the existing pipeline with minimal changes:

```
User taps "Catalog"
    │
    ▼
For each selected segment:
    ├─ PixelBufferCropper crops the region from the original frame
    ├─ JPEG encode at 85% quality
    ├─ Upload to GCS temp bucket: gs://abundance-temp/{sessionId}/sweep_crop_{n}.jpg
    │
    ▼
Create Firestore session document:
    {
        captureMode: "sweep",           // NEW value
        originalImageUrls: [...],       // Full frames (for context)
        sweepCrops: [                   // NEW field
            {
                cropUrl: "gs://...",
                boundingBox: [y1, x1, y2, x2],
                frameIndex: 12,
                groupId: "uuid-...",    // Dedup group
                worldPosition: [x, y, z]  // If ARKit available
            }
        ],
        status: "detecting"
    }
    │
    ▼
onSessionCreated trigger fires
    ├─ Detects captureMode === "sweep"
    ├─ Skips Layer 1 bounding box detection (crops are pre-provided)
    ├─ Runs Layer 1 Flash for LABELING only (not detection):
    │   "Here are pre-cropped objects. Label each with name, category, attributes."
    ├─ Creates items in Firestore
    │
    ▼
onItemCreated trigger fires (existing Layer 2 — no changes)
```

### Cloud Function Changes

**`onSessionCreated.ts`** — Add `sweep` branch:

```typescript
if (session.captureMode === 'sweep') {
    // Crops are already provided — skip detection, do labeling only
    const labels = await labelPrecroppedObjects(session.sweepCrops);
    // Create items with labels
} else {
    // Existing single/burst flow — detect + crop + label
    const detections = await detectObjectsWithGemini(session.originalImageUrls);
    // ...
}
```

**Cost impact:** Sweep mode is *cheaper* per item for Layer 1 because detection is skipped — only labeling runs (~50% of Flash cost).

---

## 7. New Files

### SPM Target: `EdgeTAMFeature`

```
Sources/EdgeTAMFeature/
├── Models/
│   ├── EdgeTAMConfiguration.swift      # Model paths, FPS targets, device check
│   ├── SegmentedObject.swift           # Mask, bounding box, thumbnail, IoU
│   └── SweepSessionState.swift         # State enum for sweep mode
├── Services/
│   ├── EdgeTAMService.swift            # CoreML model loading + inference
│   ├── EdgeTAMServiceProtocol.swift    # Protocol for testing
│   ├── FrameScheduler.swift            # Decides when to run encoder (keyframe logic)
│   └── GridPromptGenerator.swift       # Generates 4×4 grid prompts for auto-segment
└── Resources/
    ├── edgetam_image_encoder.mlpackage
    ├── edgetam_prompt_encoder.mlpackage
    └── edgetam_mask_decoder.mlpackage
```

### CameraFeature Additions

```
Sources/CameraFeature/
├── ViewModels/
│   └── SweepCaptureViewModel.swift     # Sweep state machine, selection management
├── Views/
│   ├── SweepCaptureView.swift          # SwiftUI sweep mode UI
│   ├── SegmentOverlayView.swift        # Renders masks on camera preview
│   ├── SegmentSelectionTray.swift      # Bottom selection strip
│   └── SweepModeToggle.swift           # Mode picker (Photo / Burst / Sweep)
└── Models/
    └── SweepCaptureSession.swift       # Firestore model for sweep sessions
```

### Package.swift Changes

```swift
.target(
    name: "EdgeTAMFeature",
    dependencies: ["VisionCore"],
    resources: [
        .process("Resources/edgetam_image_encoder.mlpackage"),
        .process("Resources/edgetam_prompt_encoder.mlpackage"),
        .process("Resources/edgetam_mask_decoder.mlpackage")
    ],
    swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
    ]
),
.testTarget(
    name: "EdgeTAMFeatureTests",
    dependencies: ["EdgeTAMFeature"]
),

// Update CameraFeature dependency
.target(
    name: "CameraFeature",
    dependencies: [
        "Persistence",
        "VisionCore",
        "EdgeTAMFeature",  // NEW
        .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
    ],
    // ...
),
```

---

## 8. Known Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| **FPS is 1-2, not 16** | High | UX designed to work at 1 FPS (Section 4). Day 1 benchmark validates. |
| **CoreML export has conversion errors** | Medium | Pin `numpy<2.4.0` during conversion. Apple fix merged to coremltools main, awaiting release. One-time export — doesn't affect runtime. |
| **No existing iOS reference app** | Medium | Use `huggingface/sam2-studio` (macOS SwiftUI) and `AlessandroToschi/SegmentAnythingMobile` (iOS MobileSAM) as reference implementations. |
| **20 MB model bloats app bundle** | Low | Only downloaded on eligible devices via ODR (On-Demand Resources), or always bundled (20 MB is acceptable for an ML feature). |
| **Memory bank not in CoreML** | None | Not needed. Per-frame segmentation + deduplication is the correct architecture for shelf scanning (stationary objects, moving camera). |
| **EdgeTAM produces inaccurate masks** | Medium | Masks are for UX feedback only. Actual crops are sent to Gemini Flash which doesn't rely on mask precision. |

---

## 9. Implementation Plan

### Phase 0: Benchmark Spike (1 day) ← GATE

**Before any other work:**

1. Export EdgeTAM CoreML models (run Python script on Mac)
2. Create minimal Xcode project loading all 3 models
3. Benchmark end-to-end on iPhone 15 Pro:
   - Image encoder alone: how many ms?
   - Full pipeline (encode + prompt + decode): how many ms?
   - With camera running simultaneously: what's the real FPS?
4. Compare against `VNGenerateForegroundInstanceMaskRequest` on same device

**Gate criteria:**
- If ≥4 FPS: Proceed with EdgeTAM (good real-time experience)
- If 1-3 FPS: Proceed with EdgeTAM but use "tap to scan" fallback UX
- If <1 FPS: Abort EdgeTAM. Fall back to Option B (VNForegroundInstanceMask-only approach)

### Phase 1: EdgeTAM SPM Target (3 days)

- Create `EdgeTAMFeature` target with model loading
- Implement `EdgeTAMService` with encode/decode split
- Implement `FrameScheduler` keyframe logic
- Write unit tests with mock models

### Phase 2: Sweep UI (3 days)

- Create `SweepCaptureView` with segment overlay rendering
- Create `SweepCaptureViewModel` state machine
- Implement tap-to-select/deselect with haptics
- Create selection tray UI
- Add mode toggle to camera view

### Phase 3: Deduplication + ARKit (2 days)

- Extend `ObjectDeduplicator` with spatial dedup
- Add optional `ARWorldTrackingConfiguration` during sweep
- Implement multi-angle grouping logic

### Phase 4: Pipeline Integration (2 days)

- Add `sweep` capture mode to session model
- Update `onSessionCreated` Cloud Function for sweep branch
- Implement crop + upload flow for selected segments
- Test end-to-end: sweep → crop → Layer 1 → Layer 2

### Phase 5: Polish (2 days)

- Performance-adaptive UX (FPS detection → adjust overlay behavior)
- Animation polish (segment appear/disappear, selection transitions)
- Error handling (model load failure, memory pressure)
- Device eligibility gating

**Total estimated effort: 13 days** (including 1-day benchmark gate)

---

## 10. Success Criteria

| Metric | Target |
|--------|--------|
| Segments visible within | < 1s of pointing camera at objects |
| Tap-to-select latency | < 100ms (mask decode only) |
| Deduplication accuracy | > 90% (same object not selected twice) |
| End-to-end sweep → catalog | < 15s for 5 items |
| App size increase | < 25 MB |
| Memory usage during sweep | < 400 MB |
| Battery impact (5-min sweep) | < 5% battery drain |
| Device eligibility | iPhone 15 Pro+ only |

---

## References

- [EdgeTAM GitHub](https://github.com/facebookresearch/EdgeTAM)
- [EdgeTAM Paper (CVPR 2025)](https://arxiv.org/html/2501.07256v1)
- [EdgeTAM CoreML Export Issue #14](https://github.com/facebookresearch/EdgeTAM/issues/14)
- [SAM2 Studio (macOS SwiftUI reference)](https://github.com/huggingface/sam2-studio)
- [SegmentAnythingMobile (iOS reference)](https://github.com/AlessandroToschi/SegmentAnythingMobile)
- [Apple CoreML SAM2 Models](https://huggingface.co/collections/apple/core-ml-segment-anything-2-66e4571a7234dc2560c3db26)
- SPEC-PIPE-001: Layer 1 Detection
- SPEC-UI-001: Camera Capture Flow
- docs/archive/plans/2026-01-16-gemini-layer1-capture-redesign.md (YOLO removal rationale)

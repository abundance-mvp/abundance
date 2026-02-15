# SPEC-PIPE-004-B: Camera Sweep Cataloging — Apple Native APIs Option

**Created:** 2026-02-07
**Status:** Draft (Pending ADR)
**Author:** Claude Code
**Depends On:** SPEC-PIPE-001, SPEC-UI-001, SPEC-ARCH-002
**Device Target:** iPhone 15 Pro+ (primary), iPhone 13+ (degraded)

---

## 1. Overview

### What This Is

A new capture mode ("Sweep Mode") using exclusively Apple-native Vision framework APIs for real-time object detection and segmentation. No third-party ML models. The system uses `VNGenerateForegroundInstanceMaskRequest` — already in the codebase and validated at 50-80ms — as the primary segmentation engine, augmented by `VNGenerateObjectnessBasedSaliencyImageRequest` for fast ambient feedback.

### Why This Option Exists

The project has a documented history with on-device ML models:

1. **YOLOv11n was tried and removed** (commits `10b7354` → `85413ea`, Jan 2026). Root cause: COCO's 80 classes only covered 18 household items (23% relevance). The model couldn't detect most household objects.
2. **EdgeTAM (Option A) carries FPS risk.** The claimed 16 FPS may be 1-2 FPS in practice. The CoreML export is community-contributed with known conversion issues.

This option uses **zero third-party models** and **zero additional app bundle size**. Everything runs on APIs already shipping in iOS 17+.

### Key Insight: Detection vs Segmentation

The YOLO failure was about **detection** (labeling what something is). But for sweep mode UX, we don't need labels — we need to answer "there is a distinct object here." Apple's `VNGenerateForegroundInstanceMaskRequest` answers exactly that question. It segments every foreground object without needing to know what they are. Labels come later from Gemini.

| Problem | YOLO's Answer | VNForegroundInstanceMask's Answer |
|---------|--------------|-----------------------------------|
| "Is there an object here?" | Only if it's one of 80 COCO classes | Yes — any foreground object |
| "What is it?" | "bottle" (if it's in COCO) | No answer (just a mask) |
| "Where exactly is it?" | Bounding box only | Pixel-accurate contour mask |

For sweep mode, "is there an object here?" + "where exactly is it?" is all the on-device layer needs. "What is it?" is Gemini's job.

---

## 2. Architecture

### Pipeline Position

```
                      NEW (on-device, Apple native)           EXISTING (cloud)
                    ┌──────────────────────────────┐    ┌─────────────────────┐
                    │  Sweep Mode                   │    │   Layer 1           │
Camera frames ────▶ │  Tier 1: Saliency (every      │──▶│   Gemini 3 Flash    │
  (30 FPS)          │          frame, <10ms)         │    │   (labeling only)   │
                    │  Tier 2: Instance Mask (on     │    └─────────────────────┘
                    │          stabilization, ~60ms)  │              │
                    │  Tier 3: Tap-to-select         │    ┌─────────────────────┐
                    └──────────────────────────────┘    │   Layer 2           │
                              │                          │   Gemini 3 Pro      │
                        User taps to                     │   (cataloging)      │
                        select segments                  └─────────────────────┘
```

### Tiered Processing Model

The core design principle: **different APIs at different speeds for different purposes.**

```
Camera frame arrives (every 33ms at 30 FPS)
    │
    ├──▶ Tier 1: VNGenerateObjectnessBasedSaliencyImageRequest
    │    └─ Runs: every frame (~5-10ms on A17 Pro)
    │    └─ Output: 64×64 heat map of "objectness"
    │    └─ UX: ambient glow overlay showing dense object regions
    │
    ├──▶ Tier 2: VNGenerateForegroundInstanceMaskRequest
    │    └─ Runs: on keyframes (when camera stabilizes for >0.3s)
    │    └─ Output: pixel-accurate instance masks for all foreground objects
    │    └─ UX: organic contour borders appear around each object
    │    └─ Already in codebase: SubjectMaskGenerator.swift (50-80ms validated)
    │
    └──▶ Tier 3: User Tap → Crop Selection
         └─ Runs: on demand (user taps a mask region)
         └─ Output: cropped image of selected object
         └─ UX: selected object gets blue border + checkmark
```

### Component Diagram

```
┌─ CameraFeature ──────────────────────────────────────────────────────────┐
│                                                                           │
│  CameraService.framePublisher (CVPixelBuffer stream, 30 FPS)             │
│       │                                                                   │
│       ├──▶ SaliencyProcessor (NEW, lightweight)                          │
│       │    └─ VNGenerateObjectnessBasedSaliencyImageRequest              │
│       │    └─ Produces: CIImage heat map overlay (64×64 upscaled)        │
│       │    └─ Runs: every frame, <10ms                                   │
│       │                                                                   │
│       ├──▶ InstanceMaskProcessor (extends existing SubjectMaskGenerator)  │
│       │    └─ VNGenerateForegroundInstanceMaskRequest                     │
│       │    └─ Produces: [InstanceSegment] with mask + bbox + index       │
│       │    └─ Runs: on keyframes only (stabilization trigger)            │
│       │                                                                   │
│       └──▶ KeyframeDetector (NEW)                                        │
│            └─ Frame differencing to detect camera motion                  │
│            └─ Triggers Tier 2 when motion drops below threshold          │
│                                                                           │
│  SweepCaptureViewModel (state machine)                                    │
│  ├─ Manages saliency overlay state                                        │
│  ├─ Manages instance segment state                                        │
│  ├─ Manages selection state                                               │
│  └─ Triggers crop + upload for selected segments                          │
│       │                                                                   │
│       ▼                                                                   │
│  SweepCaptureView (SwiftUI overlay)                                       │
│  ├─ Saliency heat map layer (always visible, subtle)                     │
│  ├─ Instance mask contour layer (visible when segments detected)          │
│  ├─ Tap gesture → select/deselect via instanceAtPoint()                  │
│  └─ Selection tray at bottom                                              │
│                                                                           │
└─ VisionCore ──────────────────────────────────────────────────────────────┘
   ├─ SubjectMaskGenerator (EXISTING — Tier 2 engine)
   ├─ ObjectDeduplicator (EXISTING — prevents double-selection)
   ├─ BarcodeDetector (EXISTING — runs in parallel during sweep)
   └─ PixelBufferCropper (EXISTING — crops selected segments for upload)
```

---

## 3. Tier 1: Saliency Heat Map (Real-Time Ambient Feedback)

### API: VNGenerateObjectnessBasedSaliencyImageRequest

**Available since iOS 13.** Produces a 64×64 heat map where bright regions indicate likely objects. Designed to be fast (small output, lightweight model).

### How It Works

```swift
public actor SaliencyProcessor {

    /// Process a single frame for saliency heat map
    /// Target: <10ms per frame on A17 Pro
    public nonisolated func processSaliency(
        pixelBuffer: CVPixelBuffer
    ) async -> CIImage? {
        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            options: [:]
        )

        do {
            try handler.perform([request])
            guard let observation = request.results?.first
                    as? VNSaliencyImageObservation else {
                return nil
            }

            // Convert saliency pixel buffer to CIImage for overlay
            let saliencyMap = CIImage(cvPixelBuffer: observation.pixelBuffer)

            // Apply color tint (warm orange glow) and adjust opacity
            let tinted = saliencyMap
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: 1.0, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: 0.6, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: 0.2, w: 0),
                    "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.15)
                ])

            return tinted
        } catch {
            return nil
        }
    }
}
```

### UX Effect

The saliency heat map produces a subtle, diffused warm glow over regions containing objects. Because it's only 64×64 pixels upscaled to screen resolution, the glow is naturally soft — it looks intentional, like a thermal camera effect.

- When user points at empty wall → no glow
- When user points at a shelf of objects → warm glow concentrates on the items
- As user pans, the glow shifts in real-time (30 FPS)

This provides the "the system sees something" signal before any detailed segmentation runs.

### Performance Budget

| Device | Expected Latency | FPS Impact |
|--------|------------------|------------|
| iPhone 15 Pro (A17 Pro) | ~5ms | None (runs within frame budget) |
| iPhone 14 Pro (A16) | ~8ms | None |
| iPhone 13 (A15) | ~12ms | Minimal (may skip every 3rd frame) |

---

## 4. Tier 2: Instance Mask Segmentation (On Stabilization)

### API: VNGenerateForegroundInstanceMaskRequest

**Already in codebase:** `SubjectMaskGenerator.swift`, validated at 50-80ms per mask on iPhone 15 Pro.

### Extended Usage for Sweep Mode

The existing `SubjectMaskGenerator` runs on a single region of interest. For sweep mode, we run it on the **full frame** (no ROI constraint) to get **all** foreground instances at once.

```swift
public actor InstanceMaskProcessor {

    /// Process a full frame for all foreground instances
    /// Runs on keyframes only (~60ms per invocation)
    public nonisolated func processInstances(
        pixelBuffer: CVPixelBuffer
    ) async -> [InstanceSegment]? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        // No regionOfInterest set → processes entire frame
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            options: [:]
        )

        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                return nil
            }

            // Extract individual instances
            var segments: [InstanceSegment] = []
            for index in observation.allInstances {
                let mask = try observation.createScaledMask(
                    for: IndexSet(integer: index),
                    croppedToInstancesContent: false
                )
                let croppedMask = try observation.createScaledMask(
                    for: IndexSet(integer: index),
                    croppedToInstancesContent: true
                )

                segments.append(InstanceSegment(
                    instanceIndex: index,
                    fullMask: mask,         // For overlay rendering
                    croppedMask: croppedMask, // For crop extraction
                    observation: observation  // For hit testing
                ))
            }

            return segments
        } catch {
            return nil
        }
    }
}
```

### Keyframe Trigger Logic

Don't run Tier 2 on every frame (too slow). Run it when the camera stabilizes:

```swift
public actor KeyframeDetector {

    private var previousFrameHash: UInt64 = 0
    private var stableFrameCount: Int = 0
    private let stabilityThreshold: Int = 10  // ~0.33s at 30 FPS

    /// Returns true when the camera has been stable enough to warrant
    /// a new instance mask computation
    public func shouldProcessKeyframe(
        pixelBuffer: CVPixelBuffer
    ) -> Bool {
        let hash = computePerceptualHash(pixelBuffer)
        let delta = hash ^ previousFrameHash
        let motionScore = delta.nonzeroBitCount  // Hamming distance

        previousFrameHash = hash

        if motionScore < 5 {
            // Camera is mostly still
            stableFrameCount += 1
        } else {
            // Camera is moving
            stableFrameCount = 0
        }

        if stableFrameCount == stabilityThreshold {
            stableFrameCount = 0  // Reset to avoid re-triggering
            return true
        }

        return false
    }
}
```

### Instance Hit Testing

When the user taps the screen, map the tap to a specific instance:

```swift
/// Map a screen tap to a specific foreground instance
func instanceAtTap(
    _ tapPoint: CGPoint,
    in viewSize: CGSize,
    observation: VNInstanceMaskObservation
) -> Int? {
    // Convert screen coordinates to Vision normalized coordinates
    // Vision uses lower-left origin, normalized 0-1
    let normalizedPoint = CGPoint(
        x: tapPoint.x / viewSize.width,
        y: 1.0 - (tapPoint.y / viewSize.height)  // Flip Y
    )

    let instance = observation.instanceAtPoint(normalizedPoint)
    return instance == 0 ? nil : instance  // 0 = background
}
```

---

## 5. UX Design

### Entry Point

Same as Option A: a third capture mode toggle, visible on devices running iOS 17+.

```
┌─────────────────────────────────────┐
│          Camera Preview              │
│                                      │
│   ░░░░░░░░░   ← saliency glow       │
│   ░░░░░░░░░      (always visible,    │
│   ░░░░░░░░░       subtle warmth)     │
│                                      │
│      ╭───────╮    ╭───────╮         │
│      │ ○ ✓   │    │ ○     │ ← instance masks │
│      │       │    │       │   (appear on       │
│      ╰───────╯    ╰───────╯    stabilization)  │
│                                      │
├──────────────────────────────────────┤
│  2 objects found · 1 selected        │
├──────────────────────────────────────┤
│  ┌─────┐                  [Catalog]  │
│  │crop1│  ← selection tray           │
│  └─────┘                             │
├──────────────────────────────────────┤
│  [Photo]   [Burst]   [● Sweep]      │
└──────────────────────────────────────┘
```

### Visual Layering

The display composites three layers on top of the camera preview:

```
Layer 3 (top): Selection UI — checkmarks, tray, count badge
Layer 2: Instance mask contours — organic borders around each object
Layer 1: Saliency heat map — subtle warm glow over object-dense regions
Layer 0 (bottom): Camera preview — 30 FPS live feed
```

**Layer 1 (Saliency)** updates every frame. It's always visible but very subtle — 15% opacity warm tint. The user may not consciously notice it, but it creates an ambient "the system is alive and scanning" feeling.

**Layer 2 (Instance masks)** appears when the camera stabilizes. Objects get organic contour borders that fade in over 200ms. When the camera starts moving again, the borders fade out over 300ms (they become stale as the view changes).

**Layer 3 (Selection)** is triggered by user taps. Selected objects get promoted with a solid border, checkmark, and thumbnail in the tray.

### Visual States

| State | Saliency (Tier 1) | Instance Masks (Tier 2) | Selection (Tier 3) |
|-------|-------------------|------------------------|-------------------|
| **Panning** | Active — glow follows camera | Hidden — stale masks fade out | Selections persist (badges follow estimated position) |
| **Stabilizing** | Active | Processing — "Scanning..." pulse | Selections persist |
| **Stable** | Active (fades to 5% when masks visible) | Visible — contours with instance borders | Tap to select/deselect |
| **Tap registered** | Active | Tapped instance highlighted | Blue border + checkmark + tray thumbnail |
| **Cataloging** | Disabled | Selected segments highlighted | Progress indicators per item |

### Feedback Signals

| Event | Haptic | Visual | Audio |
|-------|--------|--------|-------|
| Saliency glow intensifies | — | Heat map brightens in object-dense regions | — |
| Camera stabilizes → masks appear | `.light` impact | Instance borders fade in (200ms) + object count badge | — |
| Camera starts moving → masks stale | — | Instance borders fade out (300ms) | — |
| Object tapped (select) | `.medium` impact | Blue highlight + checkmark + thumbnail in tray | Soft "tick" |
| Object tapped (deselect) | `.light` impact | Highlight removed + thumbnail removed | — |
| Duplicate object tapped | `.warning` notification | Yellow highlight + "Already selected" toast | — |
| "Catalog" tapped | `.success` notification | Selected items pulse → progress bar | — |

### Performance-Adaptive UX

Unlike EdgeTAM, there's no FPS variability risk. Apple's APIs have consistent performance:

| Device | Tier 1 (Saliency) | Tier 2 (Instance Mask) | Overall UX |
|--------|-------------------|----------------------|------------|
| iPhone 15 Pro (A17 Pro) | 30 FPS (~5ms) | ~50ms per keyframe | Premium |
| iPhone 14 Pro (A16) | 30 FPS (~8ms) | ~65ms per keyframe | Great |
| iPhone 13 (A15) | 25 FPS (~12ms) | ~90ms per keyframe | Good |
| iPhone 12 (A14) | Not supported (iOS 17 required for instance masks) | — | — |

**Degraded mode for non-Pro devices:** Tier 1 saliency runs at slightly lower frame rate. Tier 2 instance masks take longer but still sub-100ms. No functional difference — just slightly slower mask appearance.

---

## 6. Deduplication

Identical to Option A (Section 5):

- **Tier 1:** VNFeaturePrint cosine distance (existing `ObjectDeduplicator`)
- **Tier 2:** ARKit spatial position (optional, same implementation)
- **Tier 3:** Temporal + spatial heuristic (same implementation)

The deduplication layer is model-agnostic — it operates on cropped pixel buffers, not on segmentation method.

---

## 7. Integration with Existing Pipeline

Identical to Option A (Section 6). The upload flow, Firestore session model, and `onSessionCreated` Cloud Function changes are the same regardless of whether EdgeTAM or Apple native APIs produced the crops.

The only difference: Apple's `VNInstanceMaskObservation.createScaledMask(croppedToInstancesContent: true)` provides a tight crop with alpha channel. EdgeTAM provides a binary mask that needs manual cropping via `PixelBufferCropper`. The cloud function receives JPEG crops either way.

---

## 8. New Files

### No New SPM Target Required

All new code lives in existing targets. No model files to bundle.

### VisionCore Additions

```
Sources/VisionCore/
├── Services/
│   ├── SaliencyProcessor.swift         # NEW — Tier 1 heat map
│   ├── SaliencyProcessorProtocol.swift # NEW — protocol for testing
│   ├── InstanceMaskProcessor.swift     # NEW — Tier 2 full-frame instance masks
│   ├── InstanceMaskProcessorProtocol.swift # NEW — protocol for testing
│   └── KeyframeDetector.swift          # NEW — motion-based keyframe trigger
└── Models/
    └── InstanceSegment.swift           # NEW — mask + bbox + index model
```

### CameraFeature Additions

```
Sources/CameraFeature/
├── ViewModels/
│   └── SweepCaptureViewModel.swift     # NEW — sweep state machine
├── Views/
│   ├── SweepCaptureView.swift          # NEW — sweep mode UI
│   ├── SaliencyOverlayView.swift       # NEW — heat map overlay layer
│   ├── InstanceMaskOverlayView.swift   # NEW — contour overlay layer
│   ├── SegmentSelectionTray.swift      # NEW — bottom selection strip
│   └── SweepModeToggle.swift           # NEW — mode picker
└── Models/
    └── SweepCaptureSession.swift       # NEW — Firestore model
```

### Package.swift Changes

None — all code goes into existing `VisionCore` and `CameraFeature` targets. Zero dependency additions. Zero model files.

---

## 9. Advantages Over Option A (EdgeTAM)

| Dimension | Option A (EdgeTAM) | Option B (Apple Native) |
|-----------|-------------------|------------------------|
| **FPS risk** | High — 1-16 FPS unknown | None — validated 50-80ms |
| **App size increase** | +20 MB (model files) | 0 MB |
| **New SPM target** | Yes (`EdgeTAMFeature`) | No |
| **CoreML conversion** | Required (known issues) | N/A |
| **Reference implementations** | None for iOS | Apple's own API — documented, supported |
| **Device support** | iPhone 15 Pro+ only | iPhone 13+ (iOS 17+) |
| **Maintenance burden** | Community CoreML export, may break with OS updates | Apple maintains the API |
| **Mask quality** | Higher (87.7 J&F) | Lower (unpublished, but sufficient for UX) |
| **Promptable** | Yes (can segment specific point) | No (auto-detects all foreground) |
| **Implementation time** | 13 days (incl. benchmark) | 10 days |

### Where Option A Wins

1. **Mask quality:** EdgeTAM produces more precise masks, especially for overlapping objects. Apple's instance mask sometimes merges adjacent objects.
2. **Promptability:** EdgeTAM can segment a specific point, which enables "tap anywhere to segment exactly that object." Apple's API segments all foreground objects — you select from the set, you can't refine.
3. **Differentiation:** Saying "we use Meta's EdgeTAM" is a more compelling technical story than "we use Apple's built-in Vision APIs."

### Where Option B Wins

1. **Reliability:** No FPS risk, no conversion issues, no third-party dependency.
2. **Broader device support:** Works on any iOS 17+ device, not just Pro models.
3. **Shipping speed:** No benchmark gate, no model export, no new SPM target.
4. **Maintenance:** Apple updates it. You don't.

---

## 10. Limitations & Mitigations

| Limitation | Impact | Mitigation |
|------------|--------|------------|
| **Not promptable** | Can't segment a specific point — must choose from auto-detected instances | User taps an instance region → `instanceAtPoint()` selects it. For objects Apple misses, user can use existing double-tap capture mode as fallback. |
| **Merges adjacent objects** | Two coffee mugs touching may appear as one instance | Show "Split" button allowing user to draw a dividing line. Or accept the merged crop — Gemini Flash can identify multiple objects in one crop. |
| **No custom model** | Can't train on household-specific data | Irrelevant — the API is class-agnostic. It segments foreground objects regardless of category. This was YOLO's weakness, not Vision's. |
| **Background confusion** | Objects that blend with background may not be segmented | Saliency heat map (Tier 1) still shows "something is here" even if instance mask fails. User can use double-tap mode for tricky objects. |
| **iOS 17+ required** | Excludes iOS 16 and below | App already targets iOS 18+ (`Package.swift` line 6). Not a constraint. |

---

## 11. Implementation Plan

### Phase 1: Saliency Processor + Keyframe Detector (2 days)

- Implement `SaliencyProcessor` with `VNGenerateObjectnessBasedSaliencyImageRequest`
- Implement `KeyframeDetector` with perceptual hash frame differencing
- Benchmark saliency on iPhone 15 Pro (target: <10ms per frame)
- Write unit tests

### Phase 2: Instance Mask Processor (2 days)

- Implement `InstanceMaskProcessor` extending `SubjectMaskGenerator` patterns
- Full-frame instance mask extraction (no ROI constraint)
- Instance hit testing via `instanceAtPoint()`
- Per-instance mask extraction via `createScaledMask(for:croppedToInstancesContent:)`
- Write unit tests with real images

### Phase 3: Sweep UI (3 days)

- Create `SweepCaptureView` with three-layer compositing
- Create `SaliencyOverlayView` (CIImage → SwiftUI overlay)
- Create `InstanceMaskOverlayView` (mask contours rendered as SwiftUI shapes)
- Create `SweepCaptureViewModel` state machine
- Implement tap-to-select with `instanceAtPoint()` + haptics
- Create `SegmentSelectionTray`

### Phase 4: Pipeline Integration (2 days)

- Add `sweep` capture mode to session model
- Update `onSessionCreated` Cloud Function for sweep branch
- Implement crop + upload flow using `createScaledMask(croppedToInstancesContent: true)`
- Test end-to-end: sweep → crop → Layer 1 → Layer 2

### Phase 5: Polish (1 day)

- Saliency → instance mask transition animation
- Fade in/out behavior for masks during camera motion
- Error states (no objects found, mask failure)
- Mode toggle integration

**Total estimated effort: 10 days**

---

## 12. Success Criteria

| Metric | Target |
|--------|--------|
| Saliency overlay FPS | ≥25 FPS (indistinguishable from camera feed) |
| Time from stabilization → masks visible | < 200ms |
| Tap-to-select latency | < 50ms (`instanceAtPoint` is a lookup) |
| Deduplication accuracy | > 90% |
| End-to-end sweep → catalog | < 15s for 5 items |
| App size increase | 0 MB |
| Memory usage during sweep | < 200 MB |
| Battery impact (5-min sweep) | < 3% battery drain |
| Device support | Any iOS 17+ device (broader than Option A) |

---

## References

- [VNGenerateForegroundInstanceMaskRequest — Apple Developer](https://developer.apple.com/documentation/vision/vngenerateforegroundinstancemaskrequest)
- [VNGenerateObjectnessBasedSaliencyImageRequest — Apple Developer](https://developer.apple.com/documentation/vision/vngenerateobjectnessbasedsaliencyimagerequest)
- [WWDC 2023: Lift subjects from images in your app](https://developer.apple.com/videos/play/wwdc2023/10176/)
- [Saliency Analysis in iOS — Kodeco](https://www.kodeco.com/5807038-saliency-analysis-in-ios-using-vision)
- Sources/VisionCore/Services/SubjectMaskGenerator.swift (existing, validated)
- Sources/VisionCore/Services/ObjectDeduplicator.swift (existing, validated)
- SPEC-PIPE-001: Layer 1 Detection
- SPEC-UI-001: Camera Capture Flow
- docs/archive/plans/2026-01-16-gemini-layer1-capture-redesign.md (YOLO removal rationale)
- docs/archive/research/RESEARCH-003-layer-1-household-item-detection.md (COCO class analysis)

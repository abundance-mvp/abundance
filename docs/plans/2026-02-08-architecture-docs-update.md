# Plan: Architecture Documentation Update for EdgeTAM Sweep Mode

**Created:** 2026-02-08
**Status:** In Progress
**Author:** Claude Code
**Target File:** `docs/architecture/catalog-pipeline.md`

---

## Objective

Update `docs/architecture/catalog-pipeline.md` to reflect the new EdgeTAM sweep mode features that have been merged. The existing document covers the two-layer AI pipeline (Layer 1 detection via Gemini Flash, Layer 2 cataloging via Gemini Pro) but does not mention the new on-device pre-processing step that sweep mode introduces.

---

## Changes Required

### 1. New Section: "2.5 On-Device Pre-Processing (Sweep Mode)"

Add a new section between "System Architecture" (Section 2) and "Photo Capture & Upload" (Section 3) covering:

- **EdgeTAM CoreML integration** -- Three-model architecture (image encoder, prompt encoder, mask decoder), ~20 MB total, uses `.all` compute units (CPU + GPU + Neural Engine)
- **Device eligibility** -- A17 Pro+ required (iPhone 15 Pro/Max, iPhone 16 Pro family, future iPhone 18+). Checked via `DeviceEligibility.isSweepModeAvailable`. Always returns true in Simulator.
- **FrameScheduler for keyframe timing** -- Actor-isolated scheduler that runs image encoder on keyframes (default 0.5s interval), not every camera frame. Between keyframes, cached features are reused for fast mask decoding.
- **SweepCaptureViewModel** -- `@MainActor @Observable` ViewModel managing the sweep state machine: `inactive -> loading -> scanning -> reviewing -> uploading -> processing -> complete`. Handles segment selection with haptic feedback and drives the catalog flow.
- **Spatial deduplication via ObjectDeduplicator** -- Two-tier dedup: (1) VNFeaturePrint perceptual hashing with 90% similarity threshold and 2-minute TTL cache, (2) ARKit spatial positions with 15cm distance threshold. Prevents the same object from being selected twice when user pans back over it.
- **ARKit session for spatial awareness** -- Optional `ARWorldTrackingConfiguration` via `SweepARSessionManager`. Provides 6DOF camera pose and 3D world coordinates via raycasting. Falls back gracefully to visual-only dedup if ARKit is unavailable.
- **Performance-adaptive UX tiers** -- Four tiers based on measured EdgeTAM inference FPS: premium (10+ FPS), good (4-10 FPS), acceptable (1-4 FPS), fallback (<1 FPS, tap-to-scan mode).
- **Memory pressure handling** -- `EdgeTAMService` monitors `UIApplication.didReceiveMemoryWarningNotification`. On warning, clears feature cache but keeps models loaded. Feature cache is capped at 3 entries and 200 MB.

### 2. Update Section 2 "System Architecture"

- Add **EdgeTAMFeature** module to the iOS App component list, describing it as the on-device segmentation module for sweep capture mode.

### 3. Update Section 3 "Photo Capture & Upload"

- Add sweep mode row to the Capture Modes table:
  `| Sweep | Toggle sweep mode | Real-time on-device segmentation, user taps segments to select |`
- Add `"sweep"` to the `captureMode` field in the session document schema.
- Add `sweepCrops` field to the session document schema for sweep-specific crop metadata.

### 4. Update Section 4 "`onSessionCreated` Cloud Function"

- Document the sweep branch: when `captureMode === "sweep"`, the function skips Layer 1 bounding box detection (crops are pre-provided by EdgeTAM) and runs Gemini Flash for labeling only.

### 5. Update Session Data Model (Section 9)

- Add `"sweep"` to the `captureMode` allowed values.
- Add `sweepCrops` field (array of objects with `cropUrl`, `boundingBox`, `frameIndex`, `groupId`).

### 6. Update "Key Source Files" Appendix

Add all new EdgeTAM and sweep-related source files:

| Component | Source File |
|-----------|------------|
| EdgeTAM service | `Sources/EdgeTAMFeature/Services/EdgeTAMService.swift` |
| EdgeTAM config | `Sources/EdgeTAMFeature/Models/EdgeTAMConfiguration.swift` |
| Frame scheduler | `Sources/EdgeTAMFeature/Services/FrameScheduler.swift` |
| Device eligibility | `Sources/EdgeTAMFeature/Utilities/DeviceEligibility.swift` |
| Sweep view model | `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift` |
| Sweep capture view | `Sources/CameraFeature/Views/SweepCaptureView.swift` |
| Sweep mode toggle | `Sources/CameraFeature/Views/SweepModeToggle.swift` |
| Object deduplicator | `Sources/VisionCore/Services/ObjectDeduplicator.swift` |
| Sweep AR session | `Sources/CameraFeature/Services/SweepARSessionManager.swift` |

---

## Constraints

- Do NOT delete or rewrite existing content -- only add and extend
- Maintain the existing document structure, numbering, and formatting style
- Keep Mermaid/ASCII diagrams consistent with existing style
- Reference actual implementations (not spec pseudocode) since the code has been merged

---

## Verification

After edits, confirm:
- [ ] Table of Contents updated with new section
- [ ] All new source files listed in appendix
- [ ] Session schema includes sweep fields
- [ ] Cloud function description mentions sweep branch
- [ ] Capture modes table includes sweep
- [ ] No existing content removed or altered

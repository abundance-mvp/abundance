---
title: "Fix Sweep Mode: Segment Persistence, Tappability, Catalog Button, and Logging"
status: Draft
created: 2026-02-09
author: Claude
priority: P1
scope: CameraFeature, EdgeTAMFeature, Core
estimated_effort: 4-6 hours
references:
  - docs/specs/SPEC-PIPE-004-camera-sweep-option-a-edgetam.md
  - docs/plans/2026-02-07-camera-sweep-edgetam.md
---

# Fix Sweep Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make sweep mode functional — segments persist across frames, are tappable, enable the action button, and emit structured logs for device debugging.

**Architecture:** IoU-based segment matching replaces the current per-frame wholesale replacement. Each frame's new segments are matched to existing persistent segments by bounding box overlap (IoU > 0.3). Unmatched segments get new stable UUIDs. Segments not re-detected for 10 frames are evicted. AppLogger events replace bare os.Logger calls for JSONL persistence.

**Tech Stack:** SwiftUI, @Observable MVVM, os.log + AppLogger (JSONL), EdgeTAMFeature (CoreML segmentation)

---

## Problem Summary

Device testing revealed 5 interrelated bugs:

1. `processFrame()` line 383 does `self.segments = newSegments` — wholesale replaces segments every frame with new UUIDs, causing SwiftUI to destroy/recreate overlays each cycle
2. Overlays exist for ~100ms (one frame) — untappable by humans (~300ms reaction time)
3. Catalog button requires selection, selection requires tapping — blocked by #2
4. `SweepCaptureViewModel` uses `os.Logger` at `.debug` level instead of `AppLogger` — no JSONL output
5. Button label says "Catalog" — violates ADR-027 terminology ("Collection" not "Catalog")

---

### Task 1: Add Sweep LogEvent Cases to AppLogger

**Files:**
- Modify: `Sources/Core/Logging/AppLogger.swift` (add cases to `LogEvent` enum + computed properties)
- Test: `Tests/CoreTests/AppLoggerTests.swift` (if exists, otherwise skip — logging is infrastructure)

**Step 1: Add sweep event cases**

Add to `LogEvent` enum in `Sources/Core/Logging/AppLogger.swift`, after the `screenshotTaken` case:

```swift
// MARK: - Sweep Mode Events
case sweepStarted
case sweepFrameProcessed(segmentCount: Int, duplicateCount: Int, fps: Double)
case sweepSegmentAppeared(segmentId: String, frameIndex: Int)
case sweepSegmentLost(segmentId: String, framesVisible: Int)
case sweepSegmentSelected(segmentId: String)
case sweepSegmentDeselected(segmentId: String)
case sweepCatalogStarted(selectedCount: Int)
case sweepStopped(totalSegmentsSeen: Int, totalSelected: Int)
case sweepError(error: String)
```

**Step 2: Update `category` computed property**

Add to the switch in `category`:

```swift
case .sweepStarted, .sweepFrameProcessed, .sweepSegmentAppeared, .sweepSegmentLost,
     .sweepSegmentSelected, .sweepSegmentDeselected, .sweepCatalogStarted, .sweepStopped,
     .sweepError:
    return "sweep"
```

**Step 3: Update `severity` computed property**

Add to the switch in `severity`:

```swift
case .sweepError:
    return .error
```

(All other sweep cases fall through to the `default: return .info` at the bottom.)

**Step 4: Update `message` computed property**

Add to the switch in `message`:

```swift
case .sweepStarted:
    return "Sweep scanning started"
case .sweepFrameProcessed(let segmentCount, let duplicateCount, let fps):
    return "Sweep frame: \(segmentCount) segments (\(duplicateCount) dupes) at \(String(format: "%.1f", fps)) FPS"
case .sweepSegmentAppeared(let segmentId, let frameIndex):
    return "Sweep segment appeared: \(segmentId) at frame \(frameIndex)"
case .sweepSegmentLost(let segmentId, let framesVisible):
    return "Sweep segment lost: \(segmentId) after \(framesVisible) frames"
case .sweepSegmentSelected(let segmentId):
    return "Sweep segment selected: \(segmentId)"
case .sweepSegmentDeselected(let segmentId):
    return "Sweep segment deselected: \(segmentId)"
case .sweepCatalogStarted(let selectedCount):
    return "Sweep catalog started: \(selectedCount) items"
case .sweepStopped(let totalSegmentsSeen, let totalSelected):
    return "Sweep stopped: \(totalSegmentsSeen) seen, \(totalSelected) selected"
case .sweepError(let error):
    return "Sweep error: \(error)"
```

**Step 5: Update `metadata` computed property**

Add to the switch in `metadata`:

```swift
case .sweepFrameProcessed(let segmentCount, let duplicateCount, let fps):
    meta["segmentCount"] = segmentCount
    meta["duplicateCount"] = duplicateCount
    meta["fps"] = fps
case .sweepSegmentAppeared(let segmentId, let frameIndex):
    meta["segmentId"] = segmentId
    meta["frameIndex"] = frameIndex
case .sweepSegmentLost(let segmentId, let framesVisible):
    meta["segmentId"] = segmentId
    meta["framesVisible"] = framesVisible
case .sweepStopped(let totalSeen, let totalSelected):
    meta["totalSegmentsSeen"] = totalSeen
    meta["totalSelected"] = totalSelected
case .sweepError(let error):
    meta["error"] = error
```

(Other sweep cases don't need extra metadata beyond the default timestamp + category.)

**Step 6: Build to verify compilation**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 7: Commit**

```bash
git add Sources/Core/Logging/AppLogger.swift
git commit -m "feat: add sweep mode LogEvent cases to AppLogger"
```

---

### Task 2: Add IoU Helper and PersistentSegment Model

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift`
- Create: `Tests/CameraFeatureTests/SweepSegmentPersistenceTests.swift`

**Step 1: Write failing tests for IoU calculation**

Create `Tests/CameraFeatureTests/SweepSegmentPersistenceTests.swift`:

```swift
import Testing
import Foundation
@testable import CameraFeature

@Suite("Sweep Segment Persistence")
struct SweepSegmentPersistenceTests {

    // MARK: - IoU Tests

    @Test("IoU: no overlap returns 0")
    func iouNoOverlap() {
        let a = CGRect(x: 0, y: 0, width: 0.1, height: 0.1)
        let b = CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1)
        #expect(SweepCaptureViewModel.iou(a, b) == 0)
    }

    @Test("IoU: identical rects returns 1")
    func iouIdentical() {
        let r = CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        #expect(SweepCaptureViewModel.iou(r, r) == 1.0)
    }

    @Test("IoU: partial overlap returns value between 0 and 1")
    func iouPartialOverlap() {
        let a = CGRect(x: 0, y: 0, width: 0.4, height: 0.4)
        let b = CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
        let result = SweepCaptureViewModel.iou(a, b)
        #expect(result > 0)
        #expect(result < 1)
    }

    @Test("IoU: zero-area rect returns 0")
    func iouZeroArea() {
        let a = CGRect(x: 0, y: 0, width: 0, height: 0.1)
        let b = CGRect(x: 0, y: 0, width: 0.1, height: 0.1)
        #expect(SweepCaptureViewModel.iou(a, b) == 0)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SweepSegmentPersistenceTests 2>&1 | tail -10`
Expected: FAIL — `iou` is not accessible / doesn't exist

**Step 3: Add IoU function and PersistentSegment to SweepCaptureViewModel**

In `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift`, add inside the class:

```swift
// MARK: - Persistent Segment Tracking

/// Tracks a segment across frames with a stable identity
struct PersistentSegment {
    var segment: SegmentedObject
    var lastSeenFrame: Int
    var firstSeenFrame: Int
}

/// All segments tracked across frames, keyed by stable UUID
private var persistentSegments: [UUID: PersistentSegment] = [:]

/// Frames a segment can be absent before eviction
private let segmentTTLFrames = 10

/// Monotonic frame counter
private var frameCounter: Int = 0

/// Intersection over Union for two rectangles. Exposed for testing.
static func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
    let intersection = a.intersection(b)
    guard !intersection.isNull else { return 0 }
    let intersectionArea = intersection.width * intersection.height
    let unionArea = a.width * a.height + b.width * b.height - intersectionArea
    guard unionArea > 0 else { return 0 }
    return intersectionArea / unionArea
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter SweepSegmentPersistenceTests 2>&1 | tail -10`
Expected: 4 tests passed

**Step 5: Commit**

```bash
git add Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift Tests/CameraFeatureTests/SweepSegmentPersistenceTests.swift
git commit -m "feat: add IoU helper and PersistentSegment model for sweep tracking"
```

---

### Task 3: Implement Segment Accumulation in processFrame()

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift` (replace lines 382-385 in `processFrame()`)

**Step 1: Add a `mergeSegments` method**

Add this method to `SweepCaptureViewModel`:

```swift
/// Match new frame segments to persistent store via IoU, add new, evict stale.
private func mergeSegments(_ newSegments: [SegmentedObject]) {
    frameCounter += 1
    var matched = Set<UUID>() // persistent IDs that got matched this frame

    for newSeg in newSegments {
        // Find best IoU match among existing persistent segments
        var bestId: UUID?
        var bestIoU: CGFloat = 0.3 // minimum threshold

        for (id, persistent) in persistentSegments {
            let overlap = Self.iou(newSeg.boundingBox, persistent.segment.boundingBox)
            if overlap > bestIoU {
                bestIoU = overlap
                bestId = id
            }
        }

        if let matchedId = bestId {
            // Update existing segment — reconstruct with stable UUID (id is `let`)
            let stableId = persistentSegments[matchedId]!.segment.id
            let updated = SegmentedObject(
                id: stableId,
                boundingBox: newSeg.boundingBox,
                maskData: newSeg.maskData,
                maskWidth: newSeg.maskWidth,
                maskHeight: newSeg.maskHeight,
                iouScore: newSeg.iouScore,
                frameIndex: newSeg.frameIndex,
                timestamp: newSeg.timestamp
            )
            persistentSegments[matchedId]!.segment = updated
            persistentSegments[matchedId]!.lastSeenFrame = frameCounter
            matched.insert(matchedId)
        } else {
            // New segment — assign fresh stable identity
            let id = newSeg.id
            persistentSegments[id] = PersistentSegment(
                segment: newSeg,
                lastSeenFrame: frameCounter,
                firstSeenFrame: frameCounter
            )
            AppLogger.log(.sweepSegmentAppeared(
                segmentId: id.uuidString.prefix(8).description,
                frameIndex: frameCounter
            ))
        }
    }

    // Evict stale segments
    let staleIds = persistentSegments.filter { $0.value.lastSeenFrame < frameCounter - segmentTTLFrames }.map(\.key)
    for id in staleIds {
        let framesVisible = persistentSegments[id].map { $0.lastSeenFrame - $0.firstSeenFrame + 1 } ?? 0
        // Remove from selections if selected
        selectedSegmentIds.remove(id)
        persistentSegments.removeValue(forKey: id)
        AppLogger.log(.sweepSegmentLost(
            segmentId: id.uuidString.prefix(8).description,
            framesVisible: framesVisible
        ))
    }

    // Update published segments array
    self.segments = persistentSegments.values.map(\.segment)
    canCatalog = !selectedSegmentIds.isEmpty
}
```

**Step 2: Replace wholesale assignment in processFrame()**

In `processFrame()`, replace lines 382-385:

```swift
// OLD:
self.measuredFPS = fps
self.segments = newSegments
self.duplicateSegmentIds = duplicates
self.sweepState = .scanning(segmentCount: newSegments.count)
```

With:

```swift
// NEW: accumulate across frames with stable IDs
self.measuredFPS = fps
self.duplicateSegmentIds = duplicates
mergeSegments(newSegments)
self.sweepState = .scanning(segmentCount: self.segments.count)
```

**Step 3: Add AppLogger calls at key state transitions**

Replace existing `logger.info("Sweep scanning started")` (around line 228) with:

```swift
self.sweepState = .scanning(segmentCount: 0)
self.logger.info("Sweep scanning started")
AppLogger.log(.sweepStarted)
```

Replace existing `logger.debug("Frame processed: ...")` (around line 397) with:

```swift
logger.info("Frame processed: \(self.segments.count) segments (\(duplicates.count) dupes) at \(String(format: "%.1f", fps)) FPS")
AppLogger.log(.sweepFrameProcessed(
    segmentCount: self.segments.count,
    duplicateCount: duplicates.count,
    fps: fps
))
```

Replace `logger.error("Frame processing failed: ...")` (around line 400) with:

```swift
logger.error("Frame processing failed: \(error.localizedDescription)")
AppLogger.log(.sweepError(error: error.localizedDescription))
```

**Step 4: Add `import Core` if not already present**

Check the imports at top of `SweepCaptureViewModel.swift`. `AppLogger` is in `Core` module. The file already imports `Core` is **not** present — it imports `EdgeTAMFeature`, `VisionCore`, `Persistence`. Add:

```swift
import Core
```

The file has no `import Core` but CameraFeature already depends on Core in Package.swift (verified). Just add the import.

**Step 5: Build to verify compilation**

Run: `swift build 2>&1 | tail -10`
Expected: Build succeeded

**Step 6: Commit**

```bash
git add Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift
git commit -m "feat: accumulate sweep segments across frames with IoU matching"
```

---

### Task 4: Make Segment Overlays Tappable

**Files:**
- Modify: `Sources/CameraFeature/Views/SegmentOverlayView.swift`

**Step 1: Add `.contentShape(Rectangle())` for larger tap target**

In `SegmentOverlayView.swift`, the `body` has a `ZStack` with `.onTapGesture`. Add `.contentShape(Rectangle())` before the tap gesture so the entire bounding box area is tappable (not just the mask shape fill):

Change line 50-53 from:

```swift
.position(x: frame.midX, y: frame.midY)
.onTapGesture {
    onTap()
}
```

To:

```swift
.frame(width: frame.width, height: frame.height)
.contentShape(Rectangle())
.position(x: frame.midX, y: frame.midY)
.onTapGesture {
    onTap()
}
```

Note: Remove the duplicate `.frame(width:height:)` from inside `segmentShape()` since it's now on the ZStack. Actually — the `.frame` inside `segmentShape` sets the shape size, and the ZStack uses `.position` for placement. The `.contentShape` goes on the ZStack to make the full area tappable. Keep both `.frame` calls (one sizes the shape, one sizes the hit area).

**Step 2: Animate bounding box position changes smoothly**

Add animation for position changes so segments slide rather than jump:

```swift
.position(x: frame.midX, y: frame.midY)
.animation(.linear(duration: 0.15), value: segment.boundingBox)
```

This uses a fast linear animation so position updates from frame-to-frame tracking feel smooth but not laggy.

**Step 3: Build to verify compilation**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 4: Commit**

```bash
git add Sources/CameraFeature/Views/SegmentOverlayView.swift
git commit -m "fix: make segment overlays tappable with contentShape and animate position"
```

---

### Task 5: Fix Catalog Button Label (ADR-027 Terminology)

**Files:**
- Modify: `Sources/CameraFeature/Views/SweepCaptureView.swift`

**Step 1: Rename button label**

In `SweepCaptureView.swift` line 236, change:

```swift
Label("Catalog \(viewModel.selectedSegments.count)", systemImage: "checkmark.circle")
```

To:

```swift
Label("Add \(viewModel.selectedSegments.count)", systemImage: "plus.circle")
```

**Step 2: Update accessibility label**

In line 242, change:

```swift
.accessibilityLabel("Catalog \(viewModel.selectedSegments.count) items")
```

To:

```swift
.accessibilityLabel("Add \(viewModel.selectedSegments.count) items to collection")
```

**Step 3: Update accessibility hint**

In line 243, change:

```swift
.accessibilityHint(viewModel.canCatalog ? "Double tap to catalog selected items" : "Select items first")
```

To:

```swift
.accessibilityHint(viewModel.canCatalog ? "Double tap to add selected items" : "Select items first")
```

**Step 4: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 5: Commit**

```bash
git add Sources/CameraFeature/Views/SweepCaptureView.swift
git commit -m "fix: rename sweep Catalog button to Add per ADR-027 terminology"
```

---

### Task 6: Wire Up Selection Logging and Reset Cleanup

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift`

**Step 1: Add AppLogger to toggleSelection()**

In `toggleSelection()` (line 128-138), add logging after the toggle:

```swift
public func toggleSelection(_ segmentId: UUID) {
    let wasSelected = selectedSegmentIds.contains(segmentId)
    if wasSelected {
        selectedSegmentIds.remove(segmentId)
        AppLogger.log(.sweepSegmentDeselected(segmentId: segmentId.uuidString.prefix(8).description))
    } else {
        selectedSegmentIds.insert(segmentId)
        AppLogger.log(.sweepSegmentSelected(segmentId: segmentId.uuidString.prefix(8).description))
    }
    canCatalog = !selectedSegmentIds.isEmpty

    haptics?.playImpact(style: wasSelected ? .light : .medium)
}
```

**Step 2: Update reset() to clear persistent state**

In `reset()` (line 147-157), add cleanup for new properties:

```swift
public func reset() {
    let totalSeen = persistentSegments.count
    let totalSelected = selectedSegmentIds.count
    stopScanning()
    sweepState = .inactive
    segments = []
    persistentSegments = [:]
    frameCounter = 0
    selectedSegmentIds = []
    duplicateSegmentIds = []
    canCatalog = false
    measuredFPS = 0
    keyframeBuffers.removeAll()
    memoryWarningCount = 0
    if totalSeen > 0 {
        AppLogger.log(.sweepStopped(totalSegmentsSeen: totalSeen, totalSelected: totalSelected))
    }
}
```

**Step 3: Add AppLogger to catalogSelectedSegments()**

At the start of `catalogSelectedSegments()` (line 417), add:

```swift
AppLogger.log(.sweepCatalogStarted(selectedCount: selected.count))
```

**Step 4: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 5: Run all tests**

Run: `swift test 2>&1 | tail -10`
Expected: All tests pass

**Step 6: Commit**

```bash
git add Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift
git commit -m "feat: add AppLogger instrumentation to sweep selection, reset, and catalog"
```

---

### Task 7: Verify on Device

**Not automatable — manual verification steps:**

1. Build and deploy: `xcrun devicectl device install app --device w-16e --path <app-path>`
2. Launch app, navigate to Scan tab, enter sweep mode
3. Pan camera across objects on a shelf
4. **Check:** Segment count increments and stays stable (no flickering to 0)
5. **Check:** Can tap a segment overlay — it turns salmon with checkmark
6. **Check:** "Add N" button enables after selecting segments
7. **Check:** Cancel returns to single capture mode
8. Take a screenshot on device for log correlation
9. Pull logs: `xcrun devicectl device copy from --device w-16e --domain-type appDataContainer --domain-identifier com.abundance.mvp --source "Documents/.debug/logs/" --destination /tmp/device-logs/`
10. Verify JSONL contains `sweepStarted`, `sweepFrameProcessed`, `sweepSegmentAppeared` events

---

## Files Changed Summary

| File | Change |
|------|--------|
| `Sources/Core/Logging/AppLogger.swift` | Add 9 sweep `LogEvent` cases + category/severity/message/metadata |
| `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift` | Add `PersistentSegment`, `iou()`, `mergeSegments()`, replace wholesale segment assignment, add AppLogger calls, fix reset cleanup |
| `Sources/CameraFeature/Views/SegmentOverlayView.swift` | Add `.contentShape(Rectangle())` for tap target, `.animation` for position |
| `Sources/CameraFeature/Views/SweepCaptureView.swift` | Rename "Catalog" → "Add" button label + a11y |
| `Tests/CameraFeatureTests/SweepSegmentPersistenceTests.swift` | New: IoU unit tests |

## Non-Goals

- Deduplication improvements (VNFeaturePrint, ARKit spatial) — separate scope
- Performance/FPS optimization — tier system works, this fixes UX
- Selection tray changes — already implemented, works once segments tappable
- Cloud Function changes — catalog upload flow is correct

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| IoU matching too slow | <20 segments per frame; O(N*M) with N,M<20 is trivial |
| TTL too short (segments flash away) | 10 frames at 4-10 FPS = 1-2.5s; tune on device |
| TTL too long (ghost segments) | 10 frames is conservative; reduce to 5 if stale overlays appear |
| `SegmentedObject.id` is `let` (immutable) | Reconstruct with `SegmentedObject(id: stableId, ...)` instead of mutating (plan updated) |
| CameraFeature depends on Core | Verified: already in Package.swift — no change needed |

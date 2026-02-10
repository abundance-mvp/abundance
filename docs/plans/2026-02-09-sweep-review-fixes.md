---
title: "Fix Sweep Mode Review Findings (P0 + P1)"
status: In Progress
created: 2026-02-09
author: Claude
priority: P0
scope: CameraFeature, Core
references:
  - docs/plans/2026-02-09-sweep-mode-fixes.md
---

# Fix Sweep Mode Review Findings

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 8 issues found during code review of commit 27a50ae — 3 P0 (a11y, memory, logic bug) and 5 P1 (logging, concurrency, a11y hint, duplicate badge, terminology).

**Architecture:** Minimal targeted fixes — no structural changes. Each fix is 1-10 lines.

**Tech Stack:** SwiftUI, @Observable MVVM, Combine, os.log + AppLogger

---

## P2 Dispositions (Not Fixing)

| # | Finding | Disposition |
|---|---------|-------------|
| 6 | IoU O(n*m) | Drop — 100 IoU calcs at 0.1μs = 0.01ms. Spatial bucketing adds 40 LOC for zero measurable gain. |
| 7 | mergeSegments() tests | Drop — private @MainActor method. IoU math tested. Merge logic validated by device testing. |
| 8 | iouScore bounds | Drop — passthrough value not used in merge decisions or UI. Clamping defends nothing. |
| 9 | Touch target < 44pt | Drop — minWidth/minHeight causes hit target overlap in dense scenes. User moves closer for small objects. |

---

### Task 1: Fix many-to-one matching bug in mergeSegments() (P0)

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift:148-192`

The plan specified a `var matched = Set<UUID>()` to prevent multiple new segments from matching the same persistent segment. It was dropped during implementation. Without it, when two new segments A and B both overlap persistent segment P (IoU > 0.3), B overwrites A's match — silently losing segment A.

**Step 1: Add matched set and guard**

In `mergeSegments()`, after `frameCounter += 1` (line 149), add:

```swift
var matched = Set<UUID>()
```

In the inner loop at line 156, add a guard:

```swift
for (id, persistent) in persistentSegments {
    guard !matched.contains(id) else { continue }
    let overlap = Self.iou(newSeg.boundingBox, persistent.segment.boundingBox)
```

After `persistentSegments[matchedId]!.lastSeenFrame = frameCounter` (line 178), add:

```swift
matched.insert(matchedId)
```

**Step 2: Build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 3: Run tests**

Run: `swift test --filter SweepSegmentPersistence 2>&1 | tail -10`
Expected: 4 tests pass

**Step 4: Commit**

```bash
git add Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift
git commit -m "fix: prevent many-to-one segment matching in mergeSegments"
```

---

### Task 2: Fix duplicate badge using wrong UUID domain (P0)

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift:447-488`

The deduplication pass at lines 447-478 inserts ephemeral new-frame segment UUIDs into `duplicates`. After `mergeSegments()` runs, `self.segments` contains persistent UUIDs. The view checks `duplicateSegmentIds.contains(segment.id)` — but `segment.id` is now a persistent UUID, never matching the ephemeral ones. Result: "Already scanned" badge never shows after the first frame.

**Step 1: Map ephemeral duplicate IDs to persistent IDs after merge**

After `mergeSegments(newSegments)` at line 487, add a mapping step. The simplest approach: build a reverse map inside `mergeSegments()` and use it to translate.

Add a return value to `mergeSegments()`:

Change signature from:
```swift
private func mergeSegments(_ newSegments: [SegmentedObject]) {
```
To:
```swift
/// Returns mapping from new segment UUID → persistent segment UUID
@discardableResult
private func mergeSegments(_ newSegments: [SegmentedObject]) -> [UUID: UUID] {
```

Build the mapping as segments are matched/added. At the end, return it:

```swift
var ephemeralToPersistent: [UUID: UUID] = [:]

// In the matched branch (after matched.insert):
ephemeralToPersistent[newSeg.id] = stableId

// In the new segment branch:
ephemeralToPersistent[newSeg.id] = newSeg.id

// Before return:
return ephemeralToPersistent
```

**Step 2: Use the mapping in processFrame()**

At line 486-487, change:

```swift
self.duplicateSegmentIds = duplicates
mergeSegments(newSegments)
```

To:

```swift
let idMapping = mergeSegments(newSegments)
self.duplicateSegmentIds = Set(duplicates.compactMap { idMapping[$0] })
```

**Step 3: Build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 4: Commit**

```bash
git add Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift
git commit -m "fix: map duplicate segment IDs to persistent UUIDs"
```

---

### Task 3: Fix animation ignoring Reduce Motion (P0)

**Files:**
- Modify: `Sources/CameraFeature/Views/SegmentOverlayView.swift:53`

**Step 1: Add reduceMotion check to bounding box animation**

In `SegmentOverlayView.swift` line 53, change:

```swift
.animation(.linear(duration: 0.15), value: segment.boundingBox)
```

To:

```swift
.animation(reduceMotion ? .brandReducedMotion : .linear(duration: 0.15), value: segment.boundingBox)
```

`reduceMotion` is already captured at line 21 via `@Environment(\.accessibilityReduceMotion)`.

**Step 2: Build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/CameraFeature/Views/SegmentOverlayView.swift
git commit -m "fix: respect reduceMotion for segment bounding box animation"
```

---

### Task 4: Add deinit to SweepCaptureViewModel (P0)

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift`

**Step 1: Add deinit after init (line 215)**

After the closing brace of `init(haptics:)`, add:

```swift
deinit {
    frameSubscription?.cancel()
    sessionSubscription?.cancel()
    memoryWarningSubscription?.cancel()
    scanningTask?.cancel()
}
```

This mirrors `stopScanning()` lines 353-360 but without model unload (can't await in deinit).

**Step 2: Build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift
git commit -m "fix: add deinit to SweepCaptureViewModel for subscription cleanup"
```

---

### Task 5: Downgrade per-frame logging to debug (P1)

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift:500-505`

**Step 1: Change os.Logger level from info to debug**

Line 500, change:

```swift
logger.info("Frame processed: \(self.segments.count) segments (\(duplicates.count) dupes) at \(String(format: "%.1f", fps)) FPS")
```

To:

```swift
logger.debug("Frame processed: \(self.segments.count) segments (\(duplicates.count) dupes) at \(String(format: "%.1f", fps)) FPS")
```

**Step 2: Gate AppLogger per-frame call behind frame sampling**

Lines 501-505, change:

```swift
AppLogger.log(.sweepFrameProcessed(
    segmentCount: self.segments.count,
    duplicateCount: duplicates.count,
    fps: fps
))
```

To:

```swift
// Log every 10th frame to reduce disk I/O (4-10 FPS → 0.4-1 log/s)
if frameCounter % 10 == 0 {
    AppLogger.log(.sweepFrameProcessed(
        segmentCount: self.segments.count,
        duplicateCount: duplicates.count,
        fps: fps
    ))
}
```

**Step 3: Build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 4: Commit**

```bash
git add Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift
git commit -m "fix: reduce sweep per-frame logging frequency"
```

---

### Task 6: Fix Combine sink → Task concurrency pattern (P1)

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift:336-347`

**Step 1: Add [weak self] to inner Task**

Lines 336-347, change:

```swift
.sink { [weak self] pixelBuffer in
    guard let self else { return }
    Task { @MainActor in
        await self.processFrame(
            pixelBuffer,
            edgeTAMService: edgeTAMService,
            frameScheduler: frameScheduler,
            deduplicator: deduplicator,
            arSessionManager: arSessionManager
        )
    }
}
```

To:

```swift
.sink { [weak self] pixelBuffer in
    guard let self else { return }
    Task { @MainActor [weak self] in
        guard let self else { return }
        await self.processFrame(
            pixelBuffer,
            edgeTAMService: edgeTAMService,
            frameScheduler: frameScheduler,
            deduplicator: deduplicator,
            arSessionManager: arSessionManager
        )
    }
}
```

**Step 2: Build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 3: Run tests**

Run: `swift test --filter CameraFeatureTests 2>&1 | tail -10`
Expected: All tests pass

**Step 4: Commit**

```bash
git add Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift
git commit -m "fix: add weak self to inner Task in frame subscription sink"
```

---

### Task 7: Simplify accessibility hint on Add button (P1)

**Files:**
- Modify: `Sources/CameraFeature/Views/SweepCaptureView.swift:243`

**Step 1: Replace conditional hint with constant**

Line 243, change:

```swift
.accessibilityHint(viewModel.canCatalog ? "Double tap to add selected items" : "Select items first")
```

To:

```swift
.accessibilityHint("Double tap to add selected items to your collection")
```

The `.disabled()` modifier at line 241 already communicates unavailability to VoiceOver — a dimmed button says "disabled" automatically.

**Step 2: Build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/CameraFeature/Views/SweepCaptureView.swift
git commit -m "fix: simplify sweep Add button accessibility hint"
```

---

### Task 8: Fix remaining "Catalog" terminology (P1)

**Files:**
- Modify: `Sources/CameraFeature/Views/SweepCaptureView.swift:9, 177, 214`

**Step 1: Fix doc comment**

Line 9, change:

```swift
/// and a "Catalog" action button when items are selected.
```

To:

```swift
/// and an "Add" action button when items are selected.
```

**Step 2: Fix status bar complete state**

Line 177, change:

```swift
Label("\(count) items cataloged", systemImage: "checkmark.circle")
```

To:

```swift
Label("\(count) items added", systemImage: "checkmark.circle")
```

**Step 3: Fix accessibility label for complete state**

Line 214, change:

```swift
return "\(count) items cataloged"
```

To:

```swift
return "\(count) items added"
```

**Step 4: Build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 5: Commit**

```bash
git add Sources/CameraFeature/Views/SweepCaptureView.swift
git commit -m "fix: replace remaining Catalog terminology per ADR-027"
```

---

### Task 9: Verify

**Step 1: Build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

**Step 2: Run all sweep tests**

Run: `swift test --filter CameraFeatureTests 2>&1 | tail -10`
Expected: All tests pass

---

## Files Changed Summary

| File | Changes |
|------|---------|
| `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift` | matched set in mergeSegments, duplicate ID mapping, deinit, logging frequency, weak self |
| `Sources/CameraFeature/Views/SegmentOverlayView.swift` | reduceMotion check on animation |
| `Sources/CameraFeature/Views/SweepCaptureView.swift` | a11y hint, "cataloged" → "added", doc comment |

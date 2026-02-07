# Detection Selection & Liquid Glass Catalog Button

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace per-item "Catalog" buttons with checkmark selection toggles (all checked by default), and add a single Liquid Glass "Catalog" button anchored above the tab bar to batch-catalog selected items.

**Architecture:** Add a `selectedObjectIds: Set<String>` state to `DetectionResultsView` (initialized with all detected object groupIds). Replace `DetectedObjectCard.catalogButton` with a checkmark toggle. Replace `bottomActions` with a single Liquid Glass "Catalog" button. Remove `onCatalogObject` single-item callback from `DetectionResultsView`; keep `onCatalogAll` but repurpose it as `onCatalogSelected` with a `Set<String>` parameter. The `CaptureSessionViewModel.catalogAllObjects()` method gains a filter parameter.

**Tech Stack:** SwiftUI, iOS 26 Liquid Glass (`glassEffect`), SF Symbols (`checkmark.circle.fill` / `circle`)

---

## Current State Summary

- **`DetectionResultsView`** (`:DetectionResultsView.swift`): Shows image + bounding boxes (top 55%) and object card list (bottom 45%) with per-item "Catalog" buttons and bottom "Retake"/"Done" bar.
- **`DetectedObjectCard`** (same file): Each card has a `catalogButton` ViewBuilder that shows "Catalog" / spinner / checkmark based on cataloging state.
- **`CaptureSessionViewModel`**: `catalogObject(_:)` catalogs one item; `catalogAllObjects()` loops all uncataloged items.
- **`CaptureView`**: Passes `onCatalogObject` and `onCatalogAll` closures to `DetectionResultsView`.

## Scope

Only the **results state** (after layer 1 bounding boxes are drawn and the popup of detected items appears). No changes to capture flow, camera preview, or upload/analyze states.

---

### Task 1: Add `selectedObjectIds` State to `DetectionResultsView`

**Files:**
- Modify: `Sources/CameraFeature/Views/DetectionResultsView.swift:16` (add state)
- Modify: `Sources/CameraFeature/Views/DetectionResultsView.swift:38-50` (init selected set on appear)

**Step 1: Add `@State` property for selection**

Add below the existing `selectedObjectId` line (line 16):

```swift
@State private var selectedObjectIds: Set<String> = []
```

**Step 2: Initialize all objects as selected on appear**

Wrap the `GeometryReader` body in an `.onAppear` that seeds the selection set:

```swift
public var body: some View {
    GeometryReader { geometry in
        VStack(spacing: 0) {
            imageWithBoundingBoxes(geometry: geometry)
                .frame(height: geometry.size.height * 0.55)

            objectList
                .frame(maxHeight: geometry.size.height * 0.45)
        }
    }
    .onAppear {
        if selectedObjectIds.isEmpty {
            selectedObjectIds = Set(detectedObjects.map(\.groupId))
        }
    }
}
```

**Step 3: Build to verify no regressions**

Run: `swift build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 4: Commit**

```
feat(camera): add selectedObjectIds state to DetectionResultsView
```

---

### Task 2: Replace `DetectedObjectCard.catalogButton` with Checkmark Toggle

**Files:**
- Modify: `Sources/CameraFeature/Views/DetectionResultsView.swift` — `DetectedObjectCard` struct

**Step 1: Add selection binding and toggle callback to `DetectedObjectCard`**

Replace the `onCatalog` property with selection properties. The card struct becomes:

```swift
struct DetectedObjectCard: View {
    let object: ServerDetectedObject
    let isSelected: Bool
    let isChecked: Bool
    let isCataloging: Bool
    let isCataloged: Bool
    let onToggleCheck: () -> Void
```

Remove the old `onCatalog: () -> Void` property entirely.

**Step 2: Replace `catalogButton` ViewBuilder**

Replace the entire `catalogButton` computed property (lines 434-451) with:

```swift
@ViewBuilder
private var catalogButton: some View {
    if isCataloged {
        Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            .foregroundStyle(Color.successColor)
            .accessibilityLabel("Cataloged")
    } else if isCataloging {
        ProgressView()
            .accessibilityLabel("Cataloging in progress")
    } else {
        Button(action: onToggleCheck) {
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isChecked ? Color.accentPrimary : .secondary)
        }
        .accessibilityLabel(isChecked ? "Selected for cataloging" : "Not selected")
        .accessibilityHint("Double tap to \(isChecked ? "deselect" : "select") this item")
        .accessibilityIdentifier("detection.toggleCheck.\(object.groupId)")
    }
}
```

**Step 3: Update card background to reflect checked state**

Update `backgroundFillColor` to use `isChecked` instead of `isSelected` for the highlight:

```swift
private var backgroundFillColor: Color {
    if isSelected {
        return Color.accentPrimary.opacity(0.1)
    } else {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
}
```

(No change needed here — `isSelected` still controls the visual highlight from tapping the card in the image/list. `isChecked` only affects the checkmark button.)

**Step 4: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: Build errors from callers — we'll fix those in the next task.

---

### Task 3: Update `DetectionResultsView` Card Instantiation and Remove Per-Item Catalog

**Files:**
- Modify: `Sources/CameraFeature/Views/DetectionResultsView.swift` — `objectList` and related sections

**Step 1: Update `ForEach` in `objectList` to pass new properties**

Replace the `DetectedObjectCard` instantiation (lines 136-144) with:

```swift
DetectedObjectCard(
    object: object,
    isSelected: selectedObjectId == object.groupId,
    isChecked: selectedObjectIds.contains(object.groupId),
    isCataloging: catalogingObjectIds.contains(object.groupId),
    isCataloged: catalogedObjectIds.contains(object.groupId),
    onToggleCheck: {
        if selectedObjectIds.contains(object.groupId) {
            selectedObjectIds.remove(object.groupId)
        } else {
            selectedObjectIds.insert(object.groupId)
        }
    }
)
```

**Step 2: Update `objectListHeader` — replace "Catalog All" with select/deselect all**

Replace the header (lines 198-213) with:

```swift
private var objectListHeader: some View {
    HStack {
        Text("Detected Objects (\(detectedObjects.count))")
            .font(.system(.headline, design: .rounded))

        Spacer()

        if !detectedObjects.isEmpty {
            let allSelected = uncatalogedObjects.allSatisfy { selectedObjectIds.contains($0.groupId) }
            Button(allSelected ? "Deselect All" : "Select All") {
                if allSelected {
                    // Deselect all uncataloged objects
                    for obj in uncatalogedObjects {
                        selectedObjectIds.remove(obj.groupId)
                    }
                } else {
                    // Select all uncataloged objects
                    for obj in uncatalogedObjects {
                        selectedObjectIds.insert(obj.groupId)
                    }
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentPrimary)
            .accessibilityIdentifier("detection.selectAllButton")
        }
    }
}
```

**Step 3: Add helper computed property for uncataloged objects**

Add below `selectedObjectIds`:

```swift
private var uncatalogedObjects: [ServerDetectedObject] {
    detectedObjects.filter { !catalogedObjectIds.contains($0.groupId) && !catalogingObjectIds.contains($0.groupId) }
}

private var selectedCount: Int {
    uncatalogedObjects.filter { selectedObjectIds.contains($0.groupId) }.count
}
```

**Step 4: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: Errors from `DetectionResultsView.init` signature mismatch — fixed in next task.

---

### Task 4: Replace `bottomActions` with Liquid Glass "Catalog" Button

**Files:**
- Modify: `Sources/CameraFeature/Views/DetectionResultsView.swift` — `bottomActions` and `objectList`

**Step 1: Replace `bottomActions` with Liquid Glass Catalog button**

Replace the entire `bottomActions` computed property (lines 236-253) with:

```swift
@ViewBuilder
private var bottomActions: some View {
    HStack(spacing: 16) {
        Button(action: onRetake) {
            Label("Retake", systemImage: "arrow.counterclockwise")
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("detection.retakeButton")

        Spacer()

        if #available(iOS 26.0, macOS 26.0, *) {
            Button {
                onCatalogSelected(selectedObjectIds)
            } label: {
                Label("Catalog", systemImage: "plus.circle.fill")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .glassEffect(.regular.interactive())
            .disabled(selectedCount == 0)
            .opacity(selectedCount == 0 ? 0.5 : 1.0)
            .accessibilityIdentifier("detection.catalogSelectedButton")
            .accessibilityLabel("Catalog \(selectedCount) items")
            .accessibilityHint(selectedCount == 0 ? "No items selected" : "Double tap to catalog selected items")
        } else {
            Button {
                onCatalogSelected(selectedObjectIds)
            } label: {
                Label("Catalog", systemImage: "plus.circle.fill")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedCount == 0)
            .opacity(selectedCount == 0 ? 0.5 : 1.0)
            .accessibilityIdentifier("detection.catalogSelectedButton")
            .accessibilityLabel("Catalog \(selectedCount) items")
        }

        Button(action: onDone) {
            Text("Done")
                .fontWeight(.semibold)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("detection.doneButton")
    }
}
```

**Step 2: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: Errors — `onCatalogSelected` doesn't exist yet. Fixed in next task.

---

### Task 5: Update `DetectionResultsView` Init Signature and `CaptureView` Callsite

**Files:**
- Modify: `Sources/CameraFeature/Views/DetectionResultsView.swift` — init and properties
- Modify: `Sources/CameraFeature/Views/CaptureView.swift` — `resultsView`

**Step 1: Update `DetectionResultsView` properties and init**

Replace `onCatalogObject` and `onCatalogAll` with a single `onCatalogSelected`:

```swift
public struct DetectionResultsView: View {
    let capturedImage: Data?
    let detectedObjects: [ServerDetectedObject]
    let catalogingObjectIds: Set<String>
    let catalogedObjectIds: Set<String>
    let onCatalogSelected: (Set<String>) -> Void
    let onRetake: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedObjectId: String?
    @State private var selectedObjectIds: Set<String> = []

    private var uncatalogedObjects: [ServerDetectedObject] {
        detectedObjects.filter { !catalogedObjectIds.contains($0.groupId) && !catalogingObjectIds.contains($0.groupId) }
    }

    private var selectedCount: Int {
        uncatalogedObjects.filter { selectedObjectIds.contains($0.groupId) }.count
    }

    public init(
        capturedImage: Data?,
        detectedObjects: [ServerDetectedObject],
        catalogingObjectIds: Set<String>,
        catalogedObjectIds: Set<String>,
        onCatalogSelected: @escaping (Set<String>) -> Void,
        onRetake: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        self.capturedImage = capturedImage
        self.detectedObjects = detectedObjects
        self.catalogingObjectIds = catalogingObjectIds
        self.catalogedObjectIds = catalogedObjectIds
        self.onCatalogSelected = onCatalogSelected
        self.onRetake = onRetake
        self.onDone = onDone
    }
```

**Step 2: Update `CaptureView.resultsView` to use new signature**

Replace the `DetectionResultsView(...)` call in `CaptureView.swift` (lines 181-207) with:

```swift
DetectionResultsView(
    capturedImage: viewModel.lastCapturedPhoto,
    detectedObjects: viewModel.detectedObjects,
    catalogingObjectIds: viewModel.catalogingObjectIds,
    catalogedObjectIds: viewModel.catalogedObjectIds,
    onCatalogSelected: { selectedIds in
        Task {
            await viewModel.catalogSelectedObjects(selectedIds)
        }
    },
    onRetake: {
        viewModel.retake()
        frozenFrame = nil
    },
    onDone: {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        viewModel.retake()
        onDone()
    }
)
```

**Step 3: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: Error — `catalogSelectedObjects` doesn't exist on ViewModel. Fixed in next task.

---

### Task 6: Add `catalogSelectedObjects` to `CaptureSessionViewModel`

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift` — add method

**Step 1: Add `catalogSelectedObjects` method**

Add after `catalogAllObjects()` (line 483):

```swift
/// Catalog only the selected detected objects
/// - Parameter selectedIds: Set of groupId strings for objects to catalog
public func catalogSelectedObjects(_ selectedIds: Set<String>) async {
    for object in detectedObjects {
        if selectedIds.contains(object.groupId) &&
           !catalogingObjectIds.contains(object.groupId) &&
           !catalogedObjectIds.contains(object.groupId) {
            await catalogObject(object)
        }
    }
}
```

**Step 2: Build to verify everything compiles**

Run: `swift build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 3: Commit**

```
feat(camera): replace per-item catalog with checkmark selection and Liquid Glass batch button
```

---

### Task 7: Update Preview and Verify Visually

**Files:**
- Modify: `Sources/CameraFeature/Views/DetectionResultsView.swift` — `#Preview` block

**Step 1: Update preview to use new init signature**

Replace the preview (lines 517-530) with:

```swift
#Preview("With Objects") {
    DetectionResultsView(
        capturedImage: nil,
        detectedObjects: [
            ServerDetectedObject(groupId: "1", label: "Table Lamp", category: "lighting",
                attributes: ["color": "brass"], confidence: "high", croppedImageUrls: [],
                boundingBoxes: [BoundingBoxInfo(imageIndex: 0, box2d: [100, 200, 400, 600])]),
            ServerDetectedObject(groupId: "2", label: "Book", category: "books",
                attributes: [:], confidence: "medium", croppedImageUrls: [],
                boundingBoxes: [BoundingBoxInfo(imageIndex: 0, box2d: [500, 100, 700, 300])])
        ],
        catalogingObjectIds: [], catalogedObjectIds: [],
        onCatalogSelected: { ids in print("Catalog: \(ids)") },
        onRetake: { }, onDone: { })
}
```

**Step 2: Build and run in simulator to verify**

Run: `swift build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 3: Commit**

```
chore(camera): update detection results preview for new selection API
```

---

### Task 8: Update Bounding Box Overlay to Reflect Selection

**Files:**
- Modify: `Sources/CameraFeature/Views/DetectionResultsView.swift` — `BoundingBoxOverlay` and `imageWithBoundingBoxes`

**Step 1: Add `isChecked` to `BoundingBoxOverlay`**

Add to BoundingBoxOverlay:

```swift
struct BoundingBoxOverlay: View {
    let object: ServerDetectedObject
    let isSelected: Bool
    let isChecked: Bool
    let isCataloging: Bool
    let isCataloged: Bool
```

**Step 2: Update `borderColor` to dim unchecked items**

```swift
private var borderColor: Color {
    if isCataloged {
        return .successColor
    } else if isCataloging {
        return .cream
    } else if isSelected {
        return .accentPrimary
    } else if !isChecked {
        return .white.opacity(0.3)
    } else {
        return .white.opacity(0.8)
    }
}
```

**Step 3: Add checkmark/unchecked indicator to `labelBadge`**

Update `labelBadge` to show check state:

```swift
private var labelBadge: some View {
    HStack(spacing: 4) {
        if isCataloged {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
        } else if isCataloging {
            ProgressView()
                .scaleEffect(0.5)
        } else {
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
        }

        Text(object.label)
            .font(.caption2.weight(.semibold))
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 6)
    .padding(.vertical, 3)
    .background(
        Capsule()
            .fill(borderColor)
            .shadow(radius: 2)
    )
}
```

**Step 4: Update caller in `imageWithBoundingBoxes`**

Update the `BoundingBoxOverlay` instantiation (lines 73-78):

```swift
BoundingBoxOverlay(
    object: object,
    isSelected: selectedObjectId == object.groupId,
    isChecked: selectedObjectIds.contains(object.groupId),
    isCataloging: catalogingObjectIds.contains(object.groupId),
    isCataloged: catalogedObjectIds.contains(object.groupId)
)
```

**Step 5: Make tapping bounding box toggle check state**

Update the `.onTapGesture` on the bounding box overlay (lines 85-89):

```swift
.onTapGesture {
    withAnimation(reduceMotion ? nil : .brandPress) {
        selectedObjectId = selectedObjectId == object.groupId ? nil : object.groupId
        // Toggle check state
        if selectedObjectIds.contains(object.groupId) {
            selectedObjectIds.remove(object.groupId)
        } else {
            selectedObjectIds.insert(object.groupId)
        }
    }
}
```

Update the accessibility hint to reflect the toggle behavior:

```swift
.accessibilityHint(
    selectedObjectIds.contains(object.groupId) ? "Double tap to deselect" : "Double tap to select"
)
```

**Step 6: Build and verify**

Run: `swift build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 7: Commit**

```
feat(camera): reflect check selection state in bounding box overlays
```

---

## Summary of Changes

| File | What Changes |
|------|-------------|
| `DetectionResultsView.swift` | New `selectedObjectIds` state, `onCatalogSelected` replaces `onCatalogObject`+`onCatalogAll`, checkmark toggle on cards, Liquid Glass catalog button in bottom bar, bounding box overlays reflect check state, "Select All"/"Deselect All" replaces "Catalog All" |
| `CaptureView.swift` | Updated `resultsView` callsite for new `onCatalogSelected` signature |
| `CaptureSessionViewModel.swift` | New `catalogSelectedObjects(_:)` method |

## UX Flow (After Changes)

1. User captures photo → layer 1 runs → results appear
2. All detected items are **checked by default** (filled checkmark circles)
3. User **taps checkmark** on card (or taps bounding box) to deselect items they don't want
4. Header shows "Select All" / "Deselect All" toggle
5. User taps **Liquid Glass "Catalog" button** at bottom to batch-catalog all checked items
6. Button is disabled when 0 items selected
7. Items transition to spinner → green checkmark as cataloging completes
8. "Done" button still available to dismiss

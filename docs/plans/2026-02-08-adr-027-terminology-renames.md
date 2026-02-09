# ADR-027 Terminology Standardization: Code Renames Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename modules, types, methods, properties, and UI strings to match the canonical terminology defined in ADR-027 and `docs/GLOSSARY.md`.

**Architecture:** This is a pure refactoring operation across the iOS SPM codebase. The module `InventoryFeature` becomes `CollectionFeature`. All `deepScan`/`recatalog` methods merge into a single `refreshItem()` action. UI tab labels change from "Catalog"/"Camera" to "Collection"/"Scan". Firestore field names (`deepScanRequested`) are NOT renamed -- Swift CodingKeys aliases map the new property names to the existing Firestore fields.

**Tech Stack:** Swift 6.0 (SPM), SwiftUI, Firebase Firestore, Swift Testing

**Branch:** `refactor/adr-027-terminology-renames`

---

## Scope Summary

| Category | Old | New | Files Affected |
|----------|-----|-----|---------------|
| Module | `InventoryFeature` | `CollectionFeature` | `Package.swift`, all imports |
| View | `InventoryView` | `CollectionView` | Source + Tests + App |
| ViewModel | `InventoryViewModel` | `CollectionViewModel` | Source + Tests + App |
| Module file | `InventoryFeature.swift` | `CollectionFeature.swift` | Module declaration |
| Protocol method | `requestDeepScan(id:)` | `refreshItem(id:)` | `ItemService.swift`, protocol, all mocks |
| ViewModel method | `requestDeepScan(_:)` | `refreshItem(_:)` | `CollectionViewModel` |
| ViewModel method | `recatalogItem(_:)` | `refreshItem(_:)` (merge) | `CollectionViewModel` |
| Model property | `deepScanRequested` | `refreshRequested` | `Item.swift` (with CodingKeys alias) |
| View state | `isDeepScanning` | `isRefreshing` | `ItemDetailView.swift` |
| View state | `showDeepScanConfirmation` | `showRefreshConfirmation` | `ItemDetailView.swift` |
| Callback | `onDeepScan` | `onRefresh` | `ItemDetailView.swift`, `CollectionView.swift` |
| Callback | `onRecatalog` | removed (merged into `onRefresh`) | `ItemDetailView.swift`, `CollectionView.swift` |
| Error property | `recatalogError` | `refreshError` | `CollectionViewModel` |
| Tab label | "Catalog" | "Collection" | `MainTabView.swift`, `DebugMainTabView.swift`, `E2ETestMainTabView.swift` |
| Tab label | "Camera" | "Scan" | Same 3 tab views |
| Tab enum | `Tab.catalog` / `Tab.camera` | `Tab.collection` / `Tab.scan` | Same 3 tab views |
| Nav title | "Inventory" | "Collection" | `CollectionView.swift` |
| Button | "Re-catalog" | "Refresh" | `ItemCard.swift`, `ItemDetailView.swift` |
| Button | "Deep Scan" / "Start Deep Scan" | "Refresh" / "Start Refresh" | `ItemDetailView.swift` |
| Callback param | `onNavigateToCatalog` | `onNavigateToCollection` | `CameraTabView.swift`, `MainTabView.swift` |
| A11y IDs | `inventory.*` | `collection.*` | `CollectionView.swift` |
| A11y IDs | `detail.deepScanButton` | `detail.refreshButton` | `ItemDetailView.swift` |
| A11y IDs | `detail.recatalogButton` | removed (merged) | `ItemDetailView.swift` |
| A11y IDs | `tab.catalog` / `tab.camera` | `tab.collection` / `tab.scan` | Tab views |

---

## Constraints

1. **Firestore field `deepScanRequested`** -- CANNOT rename. Use CodingKeys alias in `Item.swift` so `item.refreshRequested` reads from/writes to `deepScanRequested`.
2. **Build must pass after each task's commit.** Each task is designed to be self-contained.
3. **No "Catalog" verb renames** -- `CatalogService`, `catalogDetectedObject()`, `catalogObject()` stay as-is per ADR-027 (Machine Domain).
4. **`CaptureView` `onDone` callback** -- stays unchanged; only `CameraTabView.onNavigateToCatalog` renames.
5. **Archived docs** (`docs/archive/`) are NOT updated -- they are historical records.

---

## Task 1: Create Branch and Rename Module Directory

**Files:**
- Rename: `Sources/InventoryFeature/` -> `Sources/CollectionFeature/`
- Rename: `Tests/InventoryFeatureTests/` -> `Tests/CollectionFeatureTests/`

**Step 1: Create branch from main**

```bash
git checkout main && git pull
git checkout -b refactor/adr-027-terminology-renames
```

**Step 2: Move the source directory**

```bash
mv Sources/InventoryFeature Sources/CollectionFeature
mv Tests/InventoryFeatureTests Tests/CollectionFeatureTests
```

**Step 3: Rename source files inside the module**

```bash
mv Sources/CollectionFeature/InventoryFeature.swift Sources/CollectionFeature/CollectionFeature.swift
mv Sources/CollectionFeature/InventoryView.swift Sources/CollectionFeature/CollectionView.swift
mv Sources/CollectionFeature/InventoryViewModel.swift Sources/CollectionFeature/CollectionViewModel.swift
```

**Step 4: Rename test files**

```bash
mv Tests/CollectionFeatureTests/InventoryViewTests.swift Tests/CollectionFeatureTests/CollectionViewTests.swift
mv Tests/CollectionFeatureTests/InventoryViewModelTests.swift Tests/CollectionFeatureTests/CollectionViewModelTests.swift
mv Tests/CollectionFeatureTests/InventoryViewSearchTests.swift Tests/CollectionFeatureTests/CollectionViewSearchTests.swift
mv Tests/CollectionFeatureTests/InventoryNavigationIntegrationTests.swift Tests/CollectionFeatureTests/CollectionNavigationIntegrationTests.swift
```

**Step 5: Rename AXe test file**

```bash
mv Tests/AXeTests/InventoryView_AXeTests.swift Tests/AXeTests/CollectionView_AXeTests.swift
```

**Step 6: Commit directory renames**

```bash
git add -A
git commit -m "refactor(collection): rename InventoryFeature directory to CollectionFeature

Rename module directory, source files, and test files per ADR-027.
Code contents not yet updated -- build will not pass until Task 2."
```

---

## Task 2: Update Package.swift Target Definitions

**Files:**
- Modify: `Package.swift`

**Step 1: Update Package.swift**

Replace every occurrence of `InventoryFeature` with `CollectionFeature` and `InventoryFeatureTests` with `CollectionFeatureTests` in `Package.swift`. There are 10 occurrences:

1. Line 10: `.library(name: "InventoryFeature"...)` -> `.library(name: "CollectionFeature"...)`
2. Line 66: `.target(name: "InventoryFeature"...)` -> `.target(name: "CollectionFeature"...)`
3. Line 77: `.testTarget(name: "InventoryFeatureTests"...)` -> `.testTarget(name: "CollectionFeatureTests"...)`
4. Line 79: `"InventoryFeature"` dependency -> `"CollectionFeature"`
5. Line 164: PipelineTests dependency `"InventoryFeature"` -> `"CollectionFeature"`
6. Line 173: AbundanceApp dependency `"InventoryFeature"` -> `"CollectionFeature"`

**Step 2: Verify the file parses**

```bash
swift package dump-package > /dev/null
```

Expected: exits 0 with no error.

**Step 3: Commit**

```bash
git add Package.swift
git commit -m "refactor(collection): update Package.swift targets InventoryFeature -> CollectionFeature"
```

---

## Task 3: Rename Types Inside CollectionFeature Module

**Files:**
- Modify: `Sources/CollectionFeature/CollectionFeature.swift`
- Modify: `Sources/CollectionFeature/CollectionView.swift`
- Modify: `Sources/CollectionFeature/CollectionViewModel.swift`

**Step 1: Update CollectionFeature.swift module comment**

Replace contents with:

```swift
// CollectionFeature module
// Provides collection list view and item detail view for displaying cataloged items
```

**Step 2: Rename types in CollectionViewModel.swift**

Find and replace all occurrences (there are ~5):
- `class InventoryViewModel` -> `class CollectionViewModel`
- `/// ViewModel for Inventory list view` -> `/// ViewModel for Collection list view`
- `/// Initialize InventoryViewModel` -> `/// Initialize CollectionViewModel`
- `recatalogError` -> `refreshError` (5 occurrences in ViewModel + View)
- `recatalogItem(_ item:)` -> the method body stays but is replaced (see Task 5)

For now, just rename the class and doc comments:

```swift
/// ViewModel for Collection list view
@MainActor
@Observable
public final class CollectionViewModel {
```

And rename `recatalogError` to `refreshError`:
- Line 17: `public var recatalogError: String?` -> `public var refreshError: String?`
- Line 145: `recatalogError = "Failed to re-catalog...` -> `refreshError = "Failed to refresh...`
- Line 155: `recatalogError = "Failed to start deep scan...` -> `refreshError = "Failed to refresh...`

**Step 3: Merge `recatalogItem` and `requestDeepScan` into `refreshItem`**

Remove both methods and replace with a single `refreshItem`:

```swift
    /// Refresh an item by re-running AI analysis on existing images
    /// Replaces both recatalogItem() and requestDeepScan() per ADR-027
    public func refreshItem(_ item: Item) async {
        do {
            try await itemRepository.refreshItem(id: item.id)
        } catch {
            refreshError = "Failed to refresh item: \(error.localizedDescription)"
        }
    }
```

Note: `itemRepository.refreshItem(id:)` does not exist yet -- it will be created in Task 4. For now, leave this referencing the new method name.

**Step 4: Rename types in CollectionView.swift**

Find and replace all occurrences:
- `public struct InventoryView` -> `public struct CollectionView`
- `@Bindable var viewModel: InventoryViewModel` -> `@Bindable var viewModel: CollectionViewModel`
- `viewModel: InventoryViewModel = InventoryViewModel()` -> `viewModel: CollectionViewModel = CollectionViewModel()`
- `.navigationTitle("Inventory")` -> `.navigationTitle("Collection")`
- `EmptyInventoryView` -> `EmptyCollectionView` (2 occurrences)
- `showRecatalogErrorAlert` -> `showRefreshErrorAlert`
- `"Re-catalog Failed"` -> `"Refresh Failed"`
- `viewModel.recatalogError` -> `viewModel.refreshError` (4 occurrences)
- All `onRecatalog` -> `onRefresh` (but this merges with `onDeepScan` -- see below)
- All `onDeepScan` -> remove (merged into `onRefresh`)
- All `inventory.*` accessibility identifiers -> `collection.*`

Merge the two callbacks into one `onRefresh` in `ItemGridView`:
- Remove `let onRecatalog: (Item) -> Void`
- Remove `let onDeepScan: (Item) -> Void`
- Add `let onRefresh: (Item) -> Void`
- In `ItemGridView` body, pass `onRefresh: { onRefresh(item) }` to `ItemDetailView`
- In the `InventoryView` (now `CollectionView`) body, the `ItemGridView` init changes:

```swift
ItemGridView(
    items: viewModel.filteredItems,
    isSelectionMode: isSelectionMode,
    selectedItemIds: $selectedItemIds,
    onRefresh: { item in
        Task { await viewModel.refreshItem(item) }
    },
    onDeletePhoto: { item, index in
        Task { await viewModel.deletePhoto(from: item, at: index) }
    },
    onDelete: { item in
        itemToDelete = item
        showDeleteConfirmation = true
    }
)
```

Update the `ItemGridView` private struct:

```swift
private struct ItemGridView: View {
    let items: [Item]
    let isSelectionMode: Bool
    @Binding var selectedItemIds: [String: Bool]
    let onRefresh: (Item) -> Void
    let onDeletePhoto: (Item, Int) -> Void
    let onDelete: (Item) -> Void
    // ...
```

In the NavigationLink inside ItemGridView, pass single `onRefresh`:

```swift
ItemDetailView(
    item: item,
    onRefresh: { onRefresh(item) },
    onDeletePhoto: { index in onDeletePhoto(item, index) }
)
```

**Step 5: Verify build compiles (will fail until Task 4 updates protocols)**

This step is deferred -- the build will not pass until Tasks 4-7 are done. That is OK for this commit.

**Step 6: Commit**

```bash
git add Sources/CollectionFeature/
git commit -m "refactor(collection): rename InventoryView/ViewModel to CollectionView/ViewModel

- Merge recatalogItem() + requestDeepScan() into refreshItem()
- Rename recatalogError -> refreshError
- Update navigation title to 'Collection'
- Merge onRecatalog + onDeepScan callbacks into onRefresh
- Update accessibility identifiers inventory.* -> collection.*"
```

---

## Task 4: Rename Protocol Method and Item Model Property

**Files:**
- Modify: `Sources/Persistence/Firebase/ItemService.swift`
- Modify: `Sources/Persistence/Models/Item.swift`

**Step 1: Rename `deepScanRequested` property in Item.swift**

Change the property name but keep the Firestore field name via manual decoding (Item already uses manual decoding in `ItemService.decodeItem`):

```swift
// MARK: - Refresh (was: Deep Scan)

/// Whether a refresh has been requested (Firestore field: deepScanRequested)
public var refreshRequested: Bool?

/// When refresh completed (Firestore field: deepScanCompletedAt)
public var refreshCompletedAt: Date?
```

Also rename in the initializer:
- Parameter `deepScanRequested` -> `refreshRequested`
- Parameter `deepScanCompletedAt` -> `refreshCompletedAt`
- `self.deepScanRequested = deepScanRequested` -> `self.refreshRequested = refreshRequested`
- `self.deepScanCompletedAt = deepScanCompletedAt` -> `self.refreshCompletedAt = refreshCompletedAt`

Update comments on `productUrl`, `upcCode`, `marketPriceRange`, `originalRetailPrice`:
- `/// Product URL from deep scan` -> `/// Product URL from refresh analysis`
- Similar for all four.

**Step 2: Rename protocol method in ItemService.swift**

In the `ItemWriteRepository` protocol:

```swift
/// Request a refresh for an item (re-run AI on existing images)
/// - Parameter id: The item document ID
func refreshItem(id: String) async throws
```

(Remove the old `requestDeepScan(id:)` declaration.)

In the `ItemService` class implementation:

```swift
// MARK: - Refresh (was: Deep Scan)

/// Request a refresh for an item (sets deepScanRequested=true, status=pending)
/// Note: Firestore field name remains "deepScanRequested" for backward compatibility
public func refreshItem(id: String) async throws {
    let itemRef = db.collection("items").document(id)
    try await itemRef.updateData([
        "deepScanRequested": true,  // Firestore field name preserved
        "status": "pending",
        "updatedAt": FieldValue.serverTimestamp()
    ])
    os_log(.info, log: .default, "Requested refresh for item id=%{public}@", id)
}
```

Update `recatalogWithPhotos` to call `refreshItem` instead of `requestDeepScan`:

```swift
public func recatalogWithPhotos(id: String) async throws {
    try await refreshItem(id: id)
}
```

**Step 3: Update `decodeItem` to use new property names**

In the `decodeItem` method, update the property names but keep reading from the same Firestore fields:

```swift
// Parse refresh completion timestamp (Firestore field: deepScanCompletedAt)
let refreshCompletedAt = (data["deepScanCompletedAt"] as? Timestamp)?.dateValue()
```

And in the `Item(...)` constructor call:

```swift
refreshRequested: data["deepScanRequested"] as? Bool,
refreshCompletedAt: refreshCompletedAt,
```

**Step 4: Update `rescanItem` method**

In `rescanItem`, update the comment but keep the Firestore field name:

```swift
"deepScanRequested": false, // Reset stale refresh state
```

**Step 5: Commit**

```bash
git add Sources/Persistence/
git commit -m "refactor(persistence): rename requestDeepScan -> refreshItem, deepScanRequested -> refreshRequested

Firestore field names preserved via manual decoding aliases.
Protocol method renamed in ItemWriteRepository."
```

---

## Task 5: Update ItemDetailView

**Files:**
- Modify: `Sources/CollectionFeature/ItemDetailView.swift`

**Step 1: Replace `onDeepScan` and `onRecatalog` with single `onRefresh`**

```swift
public var onRefresh: (() -> Void)?
```

Remove:
- `public var onRecatalog: (() -> Void)?`
- `public var onDeepScan: (() -> Void)?`

Update init:

```swift
public init(
    item: Item,
    onRefresh: (() -> Void)? = nil,
    onDeletePhoto: ((Int) -> Void)? = nil
) {
    self.item = item
    self.onRefresh = onRefresh
    self.onDeletePhoto = onDeletePhoto
}
```

**Step 2: Rename state properties**

- `showDeepScanConfirmation` -> `showRefreshConfirmation`
- `isDeepScanning` -> `isRefreshing`
- `showRecatalogConfirmation` -> remove (merged into `showRefreshConfirmation`)
- `isRecataloging` -> remove (merged into `isRefreshing`)
- `isProcessing` computed property -> uses `isRefreshing` instead

```swift
@State private var showRefreshConfirmation = false
@State private var isRefreshing = false

private var isProcessing: Bool {
    isRefreshing || item.status == .processing
}
```

**Step 3: Merge the two action buttons into one Refresh button**

Replace the two separate buttons (recatalog + deep scan) with a single Refresh button:

```swift
if onRefresh != nil {
    Button {
        showRefreshConfirmation = true
    } label: {
        Group {
            if isProcessing {
                ProgressView()
            } else {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
        }
        .font(.title3)
        .foregroundStyle(isProcessing ? .secondary : .primary)
        .frame(minWidth: 44, minHeight: 44)
    }
    .disabled(isProcessing)
    .accessibilityIdentifier("detail.refreshButton")
    .accessibilityLabel(isProcessing ? "Refresh in progress" : "Refresh item")
}
```

**Step 4: Update the confirmation dialog**

Replace both confirmation dialogs with one:

```swift
.confirmationDialog(
    "Refresh Item",
    isPresented: $showRefreshConfirmation,
    titleVisibility: .visible
) {
    Button("Refresh") {
        isRefreshing = true
        onRefresh?()
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This will re-process the item through the AI pipeline. Existing metadata will be replaced with new results.")
}
```

**Step 5: Update the status change handler**

```swift
.onChange(of: item.status) { _, newStatus in
    if newStatus != .processing {
        isRefreshing = false
    }
}
```

**Step 6: Update "Deep Scan Details" section**

Rename to "Refresh Details":

```swift
// Refresh Details
if item.refreshRequested == true || item.refreshCompletedAt != nil {
    Divider()
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.softTeal)
                .accessibilityHidden(true)
            Text("Refresh Details")
                .font(.subheadline.weight(.semibold))
        }

        if item.refreshCompletedAt != nil {
            // ... grid unchanged
        } else if isRefreshing {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Refreshing...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } else {
            // ... placeholder grid unchanged
        }
    }
}
```

**Step 7: Update processing banner text**

```swift
Text("Refreshing with AI...")
```

**Step 8: Commit**

```bash
git add Sources/CollectionFeature/ItemDetailView.swift
git commit -m "refactor(collection): merge recatalog + deep scan into single Refresh action in ItemDetailView

- Replace onRecatalog + onDeepScan with onRefresh
- Rename isDeepScanning/isRecataloging -> isRefreshing
- Update UI strings: 'Deep Scan' -> 'Refresh', 'Re-catalog' -> 'Refresh'
- Update accessibility identifiers"
```

---

## Task 6: Update ItemCard Context Menu

**Files:**
- Modify: `Sources/CollectionFeature/ItemCard.swift`

**Step 1: Rename context menu label**

Change `Label("Re-catalog", ...)` to `Label("Refresh", ...)`:

```swift
if let onRecatalog = onRecatalog {
    Button {
        onRecatalog()
    } label: {
        Label("Refresh", systemImage: "arrow.triangle.2.circlepath")
    }
}
```

**Step 2: Commit**

```bash
git add Sources/CollectionFeature/ItemCard.swift
git commit -m "refactor(collection): rename 'Re-catalog' context menu label to 'Refresh' in ItemCard"
```

---

## Task 7: Update Tab Views in App/

**Files:**
- Modify: `App/MainTabView.swift`
- Modify: `App/DebugMainTabView.swift`
- Modify: `App/E2ETestMainTabView.swift`
- Modify: `App/CameraTabView.swift`

**Step 1: Update MainTabView.swift**

Replace `import InventoryFeature` with `import CollectionFeature`.

Rename Tab enum:
```swift
enum Tab {
    case collection
    case scan
    case profile
}
```

Update all `Tab.catalog` -> `Tab.collection`, `Tab.camera` -> `Tab.scan`.

Update tab labels:
```swift
Label("Collection", systemImage: "square.grid.2x2.fill")
Label("Scan", systemImage: "camera.fill")
```

Update accessibility identifiers:
```swift
.accessibilityIdentifier("tab.collection")
.accessibilityIdentifier("tab.scan")
```

Update `selectedTab` default: `.collection`.

Update `InventoryView` -> `CollectionView`:
```swift
CollectionView(onOpenCamera: {
    selectedTab = .scan
})
```

Update `CameraTabView` callback:
```swift
CameraTabView(onNavigateToCollection: {
    selectedTab = .collection
})
```

**Step 2: Update DebugMainTabView.swift**

Same pattern as MainTabView:
- `import InventoryFeature` -> `import CollectionFeature`
- `InventoryViewModel` -> `CollectionViewModel`
- `inventoryViewModel` -> `collectionViewModel`
- Tab enum values: `.catalog` -> `.collection`, `.camera` -> `.scan`
- Tab labels: `"Catalog"` -> `"Collection"`, `"Camera"` -> `"Scan"`
- `InventoryView(` -> `CollectionView(`
- Accessibility IDs: `tab.catalog` -> `tab.collection`, `tab.camera` -> `tab.scan`
- `.navigationTitle("Camera")` -> `.navigationTitle("Scan")` (in simulator placeholder)

**Step 3: Update E2ETestMainTabView.swift**

Same pattern:
- `import InventoryFeature` -> `import CollectionFeature`
- Tab enum values, labels, accessibility IDs
- `InventoryView(` -> `CollectionView(`

**Step 4: Update CameraTabView.swift**

Rename callback:
```swift
let onNavigateToCollection: () -> Void
```

Update body:
```swift
CaptureView(cameraService: cameraService, onDone: onNavigateToCollection)
```

**Step 5: Commit**

```bash
git add App/
git commit -m "refactor(app): update tab labels Catalog->Collection, Camera->Scan per ADR-027

- Rename Tab.catalog -> Tab.collection, Tab.camera -> Tab.scan
- Update imports InventoryFeature -> CollectionFeature
- Rename InventoryView -> CollectionView, InventoryViewModel -> CollectionViewModel
- Rename onNavigateToCatalog -> onNavigateToCollection"
```

---

## Task 8: Update All Mock ItemRepository Implementations (Protocol Conformance)

**Files:**
- Modify: `Tests/CollectionFeatureTests/Mocks/MockItemRepository.swift`
- Modify: `Tests/CollectionFeatureTests/CollectionViewSearchTests.swift` (inline mock)
- Modify: `Tests/CollectionFeatureTests/EditFlow/EditItemViewModelTests.swift` (inline mock)
- Modify: `Tests/CameraFeatureTests/Mocks/MockItemService.swift`
- Modify: `Tests/ProfileFeatureTests/ProfileFeatureTests.swift` (inline mock)
- Modify: `Tests/ProfileFeatureTests/ProfileViewTests.swift` (inline mock)
- Modify: `Sources/CollectionFeature/EditFlow/RescanCameraView.swift` (preview mock)
- Modify: `Sources/CollectionFeature/EditFlow/RescanPromptSheet.swift` (preview mock)

**Step 1: Update MockItemRepository.swift**

Replace `@testable import InventoryFeature` with `@testable import CollectionFeature`.

Rename tracking properties:
- `requestDeepScanCalled` -> `refreshItemCalled`
- `lastDeepScanId` -> `lastRefreshItemId`

Rename method:
```swift
func refreshItem(id: String) async throws {
    refreshItemCalled = true
    lastRefreshItemId = id
}
```

**Step 2: Update MockSearchTestItemRepository in CollectionViewSearchTests.swift**

Replace `@testable import InventoryFeature` with `@testable import CollectionFeature`.

Rename `func requestDeepScan(id:)` -> `func refreshItem(id:)`.

**Step 3: Update inline mock in EditItemViewModelTests.swift**

Replace `@testable import InventoryFeature` with `@testable import CollectionFeature`.

Rename `func requestDeepScan(id:)` -> `func refreshItem(id:)`.

**Step 4: Update MockItemService in CameraFeatureTests**

Rename `func requestDeepScan(id:)` -> `func refreshItem(id:)`.

**Step 5: Update ProfileFeatureTests inline mocks**

In both `ProfileFeatureTests.swift` and `ProfileViewTests.swift`:

Rename `func requestDeepScan(id:)` -> `func refreshItem(id:)`.

**Step 6: Update preview mocks in EditFlow**

In `RescanCameraView.swift` and `RescanPromptSheet.swift`:

Rename `func requestDeepScan(id:)` -> `func refreshItem(id:)`.

**Step 7: Commit**

```bash
git add Tests/ Sources/CollectionFeature/EditFlow/RescanCameraView.swift Sources/CollectionFeature/EditFlow/RescanPromptSheet.swift
git commit -m "refactor(tests): update all mock ItemRepository implementations for refreshItem rename

All requestDeepScan(id:) -> refreshItem(id:) across 8 mock implementations."
```

---

## Task 9: Update Test Files for Type Renames

**Files:**
- Modify: `Tests/CollectionFeatureTests/CollectionViewModelTests.swift`
- Modify: `Tests/CollectionFeatureTests/CollectionViewTests.swift`
- Modify: `Tests/CollectionFeatureTests/CollectionViewSearchTests.swift`
- Modify: `Tests/CollectionFeatureTests/CollectionNavigationIntegrationTests.swift`
- Modify: `Tests/CollectionFeatureTests/ItemDetailViewTests.swift`
- Modify: `Tests/CollectionFeatureTests/ItemCardTests.swift`
- Modify: `Tests/CollectionFeatureTests/EmptyStateCardTests.swift`
- Modify: `Tests/CollectionFeatureTests/SimulatorDebugItemTests.swift`
- Modify: `Tests/CollectionFeatureTests/Components/FloatingTabBarTests.swift`
- Modify: `Tests/CollectionFeatureTests/Components/SearchBarTests.swift`
- Modify: `Tests/CollectionFeatureTests/Helpers/AsyncImageLoadingTests.swift`
- Modify: `Tests/AXeTests/CollectionView_AXeTests.swift`

**Step 1: Bulk-rename import statements**

In every test file listed above, replace:
```swift
@testable import InventoryFeature
```
with:
```swift
@testable import CollectionFeature
```

**Step 2: Update CollectionViewModelTests.swift**

- `@Suite("InventoryViewModel Tests")` -> `@Suite("CollectionViewModel Tests")`
- `struct InventoryViewModelTests` -> `struct CollectionViewModelTests`
- All `InventoryViewModel(` -> `CollectionViewModel(`

**Step 3: Update CollectionViewTests.swift**

- `@Suite("InventoryView Tests")` -> `@Suite("CollectionView Tests")`
- `struct InventoryViewTests` -> `struct CollectionViewTests`

**Step 4: Update CollectionViewSearchTests.swift**

- `@Suite("InventoryView Search Tests")` -> `@Suite("CollectionView Search Tests")`
- `struct InventoryViewSearchTests` -> `struct CollectionViewSearchTests`
- All `InventoryViewModel(` -> `CollectionViewModel(`
- Comment: `"Separate mock to avoid conflicts with existing mock in InventoryViewModelTests"` -> `"Separate mock to avoid conflicts with existing mock in CollectionViewModelTests"`

**Step 5: Update CollectionNavigationIntegrationTests.swift**

- `@Suite("Inventory Navigation Integration Tests")` -> `@Suite("Collection Navigation Integration Tests")`
- `struct InventoryNavigationIntegrationTests` -> `struct CollectionNavigationIntegrationTests`
- Comment references to "inventory" -> "collection"

**Step 6: Update CollectionView_AXeTests.swift**

- `@Suite("AXe: InventoryView")` -> `@Suite("AXe: CollectionView")`
- `struct InventoryView_AXeTests` -> `struct CollectionView_AXeTests`
- `"Sources/InventoryFeature/InventoryView.swift"` -> `"Sources/CollectionFeature/CollectionView.swift"`
- `"No system colors in InventoryView"` -> `"No system colors in CollectionView"`
- All `inventory\\.` accessibility ID patterns -> `collection\\.`

**Step 7: Commit**

```bash
git add Tests/
git commit -m "refactor(tests): rename all InventoryView/ViewModel test references to CollectionView/ViewModel

Update imports, suite names, struct names, and accessibility ID assertions."
```

---

## Task 10: Update PipelineTests Dependency

**Files:**
- Modify: `Tests/PipelineTests/PipelineIntegrationTests.swift` (if it imports InventoryFeature)

**Step 1: Check if PipelineTests references InventoryFeature**

PipelineTests depends on `InventoryFeature` in Package.swift (already renamed to `CollectionFeature` in Task 2). The source file `PipelineIntegrationTests.swift` does NOT import InventoryFeature, so no source changes needed.

Verify no stale imports:

```bash
rg "InventoryFeature" Tests/PipelineTests/
```

Expected: no matches.

**Step 2: Commit (if any changes needed)**

Skip if no changes.

---

## Task 11: Build and Fix Any Remaining Compilation Errors

**Step 1: Build the project**

```bash
swift build 2>&1 | head -50
```

**Step 2: Fix any remaining references**

Search for any remaining `InventoryView`, `InventoryViewModel`, `InventoryFeature`, `requestDeepScan`, `deepScanRequested`, `isDeepScanning`, `recatalogItem`, `recatalogError` in source files:

```bash
rg "InventoryView|InventoryViewModel|InventoryFeature|requestDeepScan\b|deepScanRequested|isDeepScanning|recatalogItem|recatalogError" Sources/ Tests/ App/ --glob '*.swift'
```

Fix any found references.

**Step 3: Commit fixes**

```bash
git add -A
git commit -m "fix(collection): resolve remaining compilation errors from terminology rename"
```

---

## Task 12: Run Tests and Verify

**Step 1: Run full test suite**

```bash
swift test 2>&1 | tail -30
```

Expected: all tests pass.

**Step 2: Fix any test failures**

If tests fail due to assertion strings mentioning old names (e.g., `"Authentication required"` -- this stays unchanged), or accessibility ID mismatches, fix them.

**Step 3: Commit fixes (if any)**

```bash
git add -A
git commit -m "fix(tests): resolve test failures from terminology rename"
```

---

## Task 13: Update Non-Archived Documentation References

**Files:**
- Modify: `docs/view-specs/inventory-view.md` (rename file and update content)
- Modify: `docs/testing/AXE-TEST-SCENARIOS.md`
- Modify: `docs/specs/SPEC-UI-002-catalog-inventory-flow.md` (update references)
- Modify: `docs/specs/SPEC-ARCH-001-system-overview.md` (update module table)

**Step 1: Rename view spec file**

```bash
mv docs/view-specs/inventory-view.md docs/view-specs/collection-view.md
```

Update its content: `InventoryView` -> `CollectionView`, `InventoryFeature` -> `CollectionFeature`, etc.

**Step 2: Update AXE-TEST-SCENARIOS.md**

Replace `### Inventory Screen (\`InventoryView\`)` with `### Collection Screen (\`CollectionView\`)`.

**Step 3: Update SPEC-ARCH-001**

Replace the module table entry:
```
| `InventoryViewModel` | `InventoryFeature/InventoryViewModel.swift` | ... |
```
with:
```
| `CollectionViewModel` | `CollectionFeature/CollectionViewModel.swift` | ... |
```

**Step 4: Do NOT update docs in `docs/archive/`**

Archived docs are historical records and must not be modified.

**Step 5: Commit**

```bash
git add docs/
git commit -m "docs: update non-archived documentation for ADR-027 terminology renames

Rename view spec file, update spec references. Archive docs left unchanged."
```

---

## Task 14: Final Verification and Cleanup

**Step 1: Full build + test**

```bash
swift build && swift test
```

**Step 2: Search for any remaining forbidden terms in source code**

```bash
rg "deep.?scan|Deep.?Scan|requestDeepScan|recatalogItem|recatalogError|InventoryView|InventoryViewModel|InventoryFeature" Sources/ Tests/ App/ --glob '*.swift'
```

Expected: no matches (except comments mentioning "was: deep scan" for context).

**Step 3: Search for remaining "Inventory" or "Camera" tab labels**

```bash
rg '"Inventory"|"Camera"' Sources/ App/ --glob '*.swift'
```

Expected: Only `"Camera"` appears in non-tab-label contexts (e.g., "Camera Unavailable" placeholder text, `camera.fill` SF Symbol names) which are acceptable.

**Step 4: Verify git status is clean**

```bash
git status
```

**Step 5: Final commit if needed**

```bash
git add -A
git commit -m "refactor(collection): final cleanup for ADR-027 terminology standardization"
```

---

## Summary of Commits

| # | Message | Scope |
|---|---------|-------|
| 1 | `refactor(collection): rename InventoryFeature directory to CollectionFeature` | Directory/file renames |
| 2 | `refactor(collection): update Package.swift targets` | Package manifest |
| 3 | `refactor(collection): rename InventoryView/ViewModel to CollectionView/ViewModel` | Module source types |
| 4 | `refactor(persistence): rename requestDeepScan -> refreshItem` | Protocol + ItemService |
| 5 | `refactor(collection): merge recatalog + deep scan into Refresh` | ItemDetailView |
| 6 | `refactor(collection): rename Re-catalog -> Refresh in ItemCard` | ItemCard context menu |
| 7 | `refactor(app): update tab labels Catalog->Collection, Camera->Scan` | App tab views |
| 8 | `refactor(tests): update all mock ItemRepository implementations` | Mock protocol conformance |
| 9 | `refactor(tests): rename test references` | Test suites |
| 10 | (skip if no changes) | PipelineTests check |
| 11 | `fix(collection): resolve remaining compilation errors` | Catch-all fixes |
| 12 | `fix(tests): resolve test failures` | Test fixes |
| 13 | `docs: update non-archived documentation` | Docs |
| 14 | `refactor(collection): final cleanup` | Final sweep |

---

## Risk Mitigations

1. **Build breakage**: Tasks 1-3 intentionally break the build mid-stream. The build is restored by completing Tasks 4-8 together. If working incrementally, squash Tasks 1-8 into a single commit for CI.

2. **Firestore field names**: `deepScanRequested` and `deepScanCompletedAt` are preserved as Firestore field strings in `ItemService.swift`. Only the Swift property names change. The `decodeItem` method already uses manual decoding (not Codable auto-synthesis), so this is safe.

3. **`CatalogService` stays unchanged**: Per ADR-027, "catalog" as a verb is Machine Domain terminology and does NOT get renamed. The `catalogDetectedObject()`, `catalogAllObjects()`, `catalogService` names remain.

4. **E2E Test "Catalog" button**: The `E2ETestMainTabView` has a "Catalog" button in the results section (for cataloging detected objects). This is Machine Domain usage (cataloging = AI pipeline verb) and stays as-is per ADR-027.

5. **DetectionResultsView "Catalog" button**: Same rationale -- this is the verb "catalog" (send to AI pipeline), not the noun. Stays unchanged.

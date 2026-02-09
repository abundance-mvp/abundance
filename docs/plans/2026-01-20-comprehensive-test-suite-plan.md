---
date: 2026-01-20
status: Draft
type: implementation-plan
component: ios
related-specs:
  - SPEC-UI-001-camera-capture-flow.md
  - SPEC-UI-002-catalog-inventory-flow.md
  - SPEC-DATA-002-storage-architecture.md
parallel-agents: 5
---

# Comprehensive Test Suite Implementation Plan

## Overview

This plan covers implementation of a comprehensive test suite for the iOS app, targeting 80%+ code coverage across critical user flows. Tests will use **Swift Testing** framework for unit tests (fast, no simulator) and **XCUITest** for UI integration tests.

## Test Domains

| Domain | Files to Test | Test Type | Agent |
|--------|---------------|-----------|-------|
| Camera Preview | `CameraPreviewView.swift`, `CameraService.swift` | Unit | Agent 1 |
| Inventory CRUD | `CollectionView.swift`, `CollectionViewModel.swift`, `ItemDetailView.swift` | Unit + UI | Agent 2 |
| Thumbnail Rendering | `ItemCard.swift`, thumbnail loading | Unit | Agent 3 |
| Storage Permissions | `StorageService.swift`, upload flows | Unit (mocked) | Agent 4 |
| Capture Modes | `CaptureSessionViewModel.swift` | Unit | Agent 5 |

---

## Agent 1: Camera Preview Tests

**Scope:** `Sources/CameraFeature/Views/CameraPreviewView.swift`, `Sources/CameraFeature/Services/CameraService.swift`

**Existing Tests:** `Tests/CameraFeatureTests/Views/CameraPreviewViewTests.swift` (10 tests)

### Additional Tests Needed

#### CameraService Unit Tests

| Test | Purpose |
|------|---------|
| `testCheckAuthorization_authorized_returnsAuthorized` | Permission granted flow |
| `testCheckAuthorization_denied_returnsDenied` | Permission denied flow |
| `testCheckAuthorization_notDetermined_requestsAccess` | First-time permission request |
| `testStartSession_configuresSessionCorrectly` | Session has input/output after start |
| `testStartSession_publishes_runningState` | State transitions correctly |
| `testStopSession_stopsRunningSession` | Session stops on demand |
| `testCapturePhoto_returnsImageData` | Photo capture returns valid JPEG |
| `testCapturePhoto_whileNotRunning_throwsError` | Guard against capture before start |
| `testCapturePhoto_captureInProgress_throwsError` | Prevents concurrent captures |
| `testSessionInterruption_publishes_interruptedState` | Phone call interruption handling |
| `testSessionInterruptionEnded_resumesSession` | Auto-resume after interruption |

#### CameraPreviewView Integration Tests

| Test | Purpose |
|------|---------|
| `testPreviewView_displaysLivePreview_whenSessionRunning` | Integration with real session |
| `testPreviewView_handlesOrientationChange` | Rotation handling |

### Implementation Notes

- Use `@MainActor` for all camera tests (UI thread requirement)
- Mock `AVCaptureSession` for unit tests where possible
- CameraPreviewUIView tests require iOS target (use `#if os(iOS)`)
- Test session queue threading (verify not on main thread)

### Files to Create

```
Tests/CameraFeatureTests/
├── Views/
│   └── CameraPreviewViewTests.swift  (EXISTS - 10 tests)
└── Services/
    └── CameraServiceTests.swift      (NEW - 11 tests)
```

### Estimated Tests: 21 total (10 existing + 11 new)

---

## Agent 2: Inventory CRUD Tests

**Scope:** `Sources/CollectionFeature/CollectionView.swift`, `CollectionViewModel.swift`, `ItemDetailView.swift`, `EditItemViewModel.swift`

### CollectionViewModel Unit Tests

| Test | Purpose |
|------|---------|
| `testLoadItems_populatesItemsArray` | Initial load from repository |
| `testLoadItems_setsLoadingState` | Loading indicator management |
| `testLoadItems_handlesError` | Error state on failure |
| `testDeleteItem_removesFromList` | Optimistic deletion |
| `testDeleteItem_rollbacksOnError` | Rollback on failure |
| `testDeleteItems_batchDelete` | Multi-select delete |
| `testDeleteItems_partialFailure_rollbacksAll` | Atomic batch behavior |
| `testRealTimeUpdates_syncsChanges` | Firestore listener updates |

### CollectionView UI Tests

| Test | Purpose |
|------|---------|
| `testEmptyState_showsAddButton` | Empty inventory UX |
| `testGrid_displaysItemCards` | Grid layout rendering |
| `testSearch_filtersItems` | Search functionality |
| `testSelectionMode_togglesCorrectly` | Multi-select entry/exit |
| `testSelectionMode_selectsMultipleItems` | Checkbox behavior |
| `testDeleteConfirmation_showsAlert` | Delete confirmation dialog |
| `testDeleteConfirmation_deletesOnConfirm` | Delete flow completion |
| `testNavigation_toItemDetail` | Card tap navigation |

### ItemDetailView Unit Tests

| Test | Purpose |
|------|---------|
| `testDetailView_displaysAllMetadata` | Metadata rendering |
| `testDetailView_displaysHeroImage` | Image loading |
| `testEditButton_triggersEditFlow` | Edit flow initiation |
| `testStatusBadge_correctColors` | Status indicator colors |

### EditItemViewModel Unit Tests

| Test | Purpose |
|------|---------|
| `testStartEditFlow_movesToPromptingRescan` | State machine start |
| `testBeginRescan_movesToCapturing` | Rescan flow |
| `testCancelFlow_resetsToIdle` | Cancel behavior |
| `testHandleCapturedImage_uploadsAndAnalyzes` | Rescan processing |
| `testHandleCapturedImage_timeout_showsError` | 30s timeout handling |
| `testAcceptRescanResult_savesNewData` | Accept rescan |
| `testUnlockManualEdit_movesToEditing` | Manual edit entry |
| `testSaveManualEdits_validatesFields` | Validation execution |
| `testValidation_name_maxLength` | Name 100 char limit |
| `testValidation_estimatedValue_range` | Value 0-1M range |
| `testValidation_quantity_range` | Quantity 1-1000 range |
| `testUpdateField_tracksEditedFields` | Edit tracking |

### Files to Create

```
Tests/CollectionFeatureTests/
├── ViewModels/
│   ├── CollectionViewModelTests.swift     (NEW - 8 tests)
│   └── EditItemViewModelTests.swift      (NEW - 12 tests)
├── Views/
│   ├── CollectionViewTests.swift          (NEW - 8 UI tests)
│   └── ItemDetailViewTests.swift         (NEW - 4 tests)
└── Mocks/
    └── MockItemRepository.swift          (NEW - test double)
```

### Estimated Tests: 32 total

---

## Agent 3: Thumbnail Rendering Tests

**Scope:** `Sources/CollectionFeature/ItemCard.swift`, image loading and caching

### ItemCard Unit Tests

| Test | Purpose |
|------|---------|
| `testItemCard_displaysName` | Name label rendering |
| `testItemCard_displaysBrandAndColor` | Metadata subtitle |
| `testItemCard_conditionBadge_correctColor` | Condition colors (green/yellow/red) |
| `testItemCard_statusBadge_processingState` | Processing indicator |
| `testItemCard_statusBadge_analyzedState` | Analyzed indicator |
| `testItemCard_statusBadge_completeState` | Complete indicator |
| `testItemCard_statusBadge_failedState` | Failed indicator |
| `testItemCard_selectionMode_showsCheckmark` | Selection overlay |
| `testItemCard_selectionMode_hidesContextMenu` | Context menu hidden |
| `testItemCard_contextMenu_showsEditDelete` | Context menu options |
| `testItemCard_imageHeight_regular` | 160pt height default |
| `testItemCard_imageHeight_xxxLarge` | 120pt for large text |
| `testItemCard_accessibilityLabel_complete` | Full accessibility description |
| `testItemCard_tapCallback_fires` | onTap handler |
| `testItemCard_fallbackName_usesCategory` | Category fallback when name nil |

### AsyncImage Loading Tests

| Test | Purpose |
|------|---------|
| `testAsyncImage_loadsFromURL` | Remote image loading |
| `testAsyncImage_showsPlaceholder_whileLoading` | Loading state |
| `testAsyncImage_showsError_onFailure` | Error state |

### Files to Create

```
Tests/CollectionFeatureTests/
├── Views/
│   └── ItemCardTests.swift               (NEW - 15 tests)
└── Helpers/
    └── AsyncImageLoadingTests.swift      (NEW - 3 tests)
```

### Estimated Tests: 18 total

---

## Agent 4: Storage Permission Tests

**Scope:** `Sources/Persistence/Firebase/StorageService.swift`

### StorageService Unit Tests

| Test | Purpose |
|------|---------|
| `testUploadCroppedObject_success_returnsURL` | Happy path upload |
| `testUploadCroppedObject_compressesToJPEG` | 80% quality compression |
| `testUploadCroppedObject_correctPath` | Path format: `users/{uid}/items/{id}.jpg` |
| `testUploadCroppedObject_setsMetadata` | Required metadata fields |
| `testUploadCroppedObject_timeout_throwsError` | 60s timeout handling |
| `testUploadCroppedObject_networkError_throwsError` | Network failure handling |
| `testUploadLivePhotoMotion_success_returnsURL` | MOV upload |
| `testUploadLivePhotoMotion_correctPath` | Path: `users/{uid}/items/{id}/motion.mov` |
| `testUploadLivePhotoMotion_correctContentType` | video/quicktime |

### Mock Firebase Storage

| Test | Purpose |
|------|---------|
| `testStorageService_usesInjectedReference` | DI for testability |
| `testStorageService_handlesAuthenticationError` | Permission denied |

### Files to Create

```
Tests/PersistenceTests/
├── Firebase/
│   └── StorageServiceTests.swift         (NEW - 11 tests)
└── Mocks/
    └── MockStorageReference.swift        (NEW - test double)
```

### Estimated Tests: 11 total

---

## Agent 5: Capture Mode Tests

**Scope:** `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift`

### Single Capture (Double-Tap) Tests

| Test | Purpose |
|------|---------|
| `testHandleDoubleTap_changesStateToCapturing` | State transition |
| `testHandleDoubleTap_createsSession` | Session service called |
| `testHandleDoubleTap_uploadsPhoto` | Storage upload |
| `testHandleDoubleTap_marksReadyForDetection` | Detection trigger |
| `testHandleDoubleTap_networkError_showsError` | Network failure |
| `testHandleDoubleTap_detectionTimeout_showsError` | 45s timeout |

### Burst Capture (Long-Press) Tests

| Test | Purpose |
|------|---------|
| `testStartBurstCapture_setsIsCapturing` | Capture flag |
| `testStartBurstCapture_incrementsBurstCount` | Counter increments |
| `testBurstCapture_interval_500ms` | 500ms between captures |
| `testBurstCapture_minDuration_1second` | Minimum burst length |
| `testBurstCapture_maxDuration_4seconds` | Maximum burst length |
| `testBurstCapture_maxPhotos_8` | Max 8 photos |
| `testEndBurstCapture_stopsCapturing` | Stop flag |
| `testEndBurstCapture_uploadsAllPhotos` | Batch upload |
| `testCancelBurstCapture_discardsPhotos` | Cancel behavior |

### State Machine Tests

| Test | Purpose |
|------|---------|
| `testUIState_idle_initial` | Initial state |
| `testUIState_capturing_duringCapture` | Capture state |
| `testUIState_uploading_duringUpload` | Upload state with progress |
| `testUIState_analyzing_duringDetection` | Analysis state |
| `testUIState_results_afterDetection` | Results state |
| `testUIState_error_onFailure` | Error state |

### Cataloging Tests

| Test | Purpose |
|------|---------|
| `testCatalogObject_addsToProcessingSet` | Tracking state |
| `testCatalogObject_idempotent` | Prevents duplicate submissions |
| `testCatalogObject_success_movesToCataloged` | Success tracking |
| `testCatalogObject_failure_remainsInProcessing` | Error handling |
| `testCatalogAllObjects_catalogsAll` | Bulk catalog |

### Files to Create

```
Tests/CameraFeatureTests/
├── ViewModels/
│   └── CaptureSessionViewModelTests.swift  (NEW - 27 tests)
└── Mocks/
    ├── MockSessionService.swift            (NEW - test double)
    ├── MockStorageService.swift            (NEW - test double)
    └── MockCatalogService.swift            (NEW - test double)
```

### Estimated Tests: 27 total

---

## Summary

| Agent | Domain | New Tests | Files |
|-------|--------|-----------|-------|
| 1 | Camera Preview | 11 | 1 new file |
| 2 | Inventory CRUD | 32 | 5 new files |
| 3 | Thumbnail Rendering | 18 | 2 new files |
| 4 | Storage Permissions | 11 | 2 new files |
| 5 | Capture Modes | 27 | 4 new files |
| **Total** | | **99** | **14 new files** |

Plus 10 existing CameraPreviewViewTests = **109 total tests**

---

## Implementation Strategy

### Phase 1: Mock Infrastructure (All Agents)

Each agent creates necessary mocks first:

```swift
// Protocol-based mocking pattern
protocol ItemRepositoryProtocol: Sendable {
    func getItems() async throws -> [Item]
    func deleteItem(_ id: String) async throws
}

final class MockItemRepository: ItemRepositoryProtocol, @unchecked Sendable {
    var itemsToReturn: [Item] = []
    var deleteError: Error?
    var deletedIds: [String] = []

    func getItems() async throws -> [Item] { itemsToReturn }
    func deleteItem(_ id: String) async throws {
        if let error = deleteError { throw error }
        deletedIds.append(id)
    }
}
```

### Phase 2: Unit Tests (Swift Testing)

Use Swift Testing framework for speed:

```swift
import Testing
@testable import CollectionFeature

@Suite("CollectionViewModel Tests")
struct CollectionViewModelTests {

    @Test("loadItems populates items array")
    @MainActor
    func loadItems_populatesItemsArray() async {
        let repo = MockItemRepository()
        repo.itemsToReturn = [Item.mock()]
        let vm = CollectionViewModel(repository: repo)

        await vm.loadItems()

        #expect(vm.items.count == 1)
    }
}
```

### Phase 3: UI Tests (XCUITest)

For CollectionView navigation and interaction:

```swift
import XCTest

final class InventoryUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-UI-Testing"]
        app.launch()
    }

    func testGrid_displaysItemCards() {
        let grid = app.collectionViews["inventoryGrid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(grid.cells.count, 0)
    }
}
```

### Phase 4: Verification

Each agent runs tests before completing:

```bash
# Run specific test suite
swift test --filter CameraServiceTests

# Run all tests for feature
swift test --filter CameraFeatureTests
```

---

## Dependencies

### Existing Test Infrastructure

- [x] `Tests/` directory structure
- [x] `CameraFeatureTests` target
- [ ] `CollectionFeatureTests` target (create)
- [ ] `PersistenceTests` target (create)

### Mock Data

Create `Tests/Shared/MockData.swift`:

```swift
extension Item {
    static func mock(
        id: String = UUID().uuidString,
        name: String = "Test Item",
        status: ItemStatus = .complete
    ) -> Item {
        Item(id: id, name: name, status: status, ...)
    }
}
```

---

## Acceptance Criteria

1. **All 109 tests pass** on iOS Simulator
2. **Code coverage >= 80%** for tested files
3. **No flaky tests** - all use condition-based waiting, no `sleep()`
4. **Swift 6 compliant** - no Sendable warnings
5. **Parallel execution** - tests run concurrently where safe

---

## Agent Dispatch Commands

After plan approval, dispatch with:

```
Task(description="Agent 1: Camera Preview Tests", subagent_type="general-purpose", prompt="...")
Task(description="Agent 2: Inventory CRUD Tests", subagent_type="general-purpose", prompt="...")
Task(description="Agent 3: Thumbnail Rendering Tests", subagent_type="general-purpose", prompt="...")
Task(description="Agent 4: Storage Permission Tests", subagent_type="general-purpose", prompt="...")
Task(description="Agent 5: Capture Mode Tests", subagent_type="general-purpose", prompt="...")
```

All agents run in parallel with independent scopes.

# Background Processing UX Implementation Plan

**Date:** 2026-01-18
**Status:** Draft
**Priority:** P2
**Issue:** docs/issues/2026-01-18-background-processing-ux-redesign.md
**Author:** Claude (swiftui-architecture-auditor)

---

## Executive Summary

Redesign the capture flow to move Layer 1 processing to background with immediate catalog navigation. This eliminates 3-8 seconds of blocking UI during "Scanning...", "Uploading...", "Analyzing..." overlays.

### Current Flow (Blocking)
1. User captures → blocking overlays for 3-8 seconds → results in camera view

### New Flow (Non-Blocking)
1. **Capture Phase:** Double-tap → haptic → immediate navigation to Catalog
2. **Catalog View:** Shows pending items with "Processing..." → Layer 1 results appear when ready
3. **Layer 2:** User explicitly taps "Catalog" button per object (cost control)

---

## Architecture Audit Results

### Current State Analysis

**Files Audited:**
- `Sources/CameraFeature/Views/CaptureView.swift`
- `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift`
- `Sources/CameraFeature/Views/DetectionResultsView.swift`

### Issues Identified

| Priority | Issue | Location | Description |
|----------|-------|----------|-------------|
| HIGH | Blocking Results Screen | CaptureView.swift:103-165 | User blocked in camera view for 3-8 seconds during Layer 1 analysis |
| HIGH | Synchronous State Waiting | CaptureSessionViewModel.swift:360-380 | `waitForDetection()` polls until Layer 1 completes |
| MEDIUM | No Pending Item State | Catalog | Cannot show items during processing |
| MEDIUM | Automatic Layer 2 Trigger | DetectionResultsView.swift:145-162 | No cost optimization; all objects cataloged together |
| LOW | Lifecycle Management | DetectionResultsView | Firestore observers not cleaned up on dismiss |

---

## New Architecture Design

### State Machine

```
CAPTURE VIEW:
  Idle Camera Preview
    ↓ (double-tap/long-press)
  Capturing
    ↓
  Uploading [frozen frame]
    ↓
  Analyzing [brief overlay, 1-2s max]
    ↓
  *** NAVIGATE TO CATALOG ***

CATALOG VIEW:
  Show Pending Session with "Processing..."
    ↓ (background: Layer 1 continues)
  Detected Objects Appear as Layer 1 Completes
    ↓
  User taps "Catalog" on object
    ↓
  Layer 2 Triggered ("Cataloging..." state)
    ↓
  Object Updates with Full Catalog Data
```

### Key Components

#### 1. PendingSessionManager (NEW)
Shared manager tracking in-flight capture sessions.

```swift
@Observable
final class PendingSessionManager {
    private(set) var pendingSessions: [PendingSession] = []

    func addSession(_ session: PendingSession)
    func removeSession(id: String)
    func updateSessionStatus(id: String, status: SessionStatus)
}
```

#### 2. PendingSession Model (NEW)
Represents a capture session during Layer 1 processing.

```swift
@Observable
final class PendingSession: Identifiable {
    let id: String
    let capturedAt: Date
    let originalImageURL: URL?
    var status: SessionStatus
    var detectedObjects: [DetectedObject] = []
    var error: Error?
}

enum SessionStatus {
    case uploading
    case detecting
    case detected
    case failed(Error)
}
```

#### 3. PendingSessionCard (NEW)
UI component for displaying pending items in Catalog.

```swift
struct PendingSessionCard: View {
    @Bindable var session: PendingSession

    var body: some View {
        // Shows progress indicator while detecting
        // Shows detected objects when ready
        // Per-object "Catalog" button for Layer 2
    }
}
```

---

## Implementation Phases

### Phase 1: Pending Session Infrastructure (2 days)

**Create New Files:**
- `Sources/CameraFeature/Models/PendingSessionState.swift`
- `Sources/CameraFeature/Models/PendingSessionManager.swift`

**Tasks:**
1. Define `PendingSession` observable class
2. Define `SessionStatus` enum with all states
3. Create `PendingSessionManager` with add/remove/update methods
4. Add Firestore listener for session document updates
5. Write unit tests for state transitions

### Phase 2: Modify Capture Flow (2 days)

**Modify Files:**
- `Sources/CameraFeature/Views/CaptureView.swift`
- `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift`

**Tasks:**
1. Remove `DetectionResultsView` from CaptureView body
2. Add `isReadyForNavigation` property to ViewModel
3. Remove `waitForDetection()` polling
4. Add navigation trigger after upload starts
5. Pass session to PendingSessionManager before navigation

### Phase 3: Catalog Pending Section (2 days)

**Create New Files:**
- `Sources/CatalogFeature/Views/PendingSessionCard.swift`
- `Sources/CatalogFeature/Models/PendingItemModel.swift`

**Modify Files:**
- `Sources/CatalogFeature/Views/CatalogView.swift`
- `Sources/CatalogFeature/ViewModels/CatalogViewModel.swift`

**Tasks:**
1. Add "Processing" section at top of CatalogView
2. Create PendingSessionCard with progress UI
3. Show detected objects as they arrive from Firestore
4. Add per-object "Catalog" button for Layer 2 trigger
5. Handle transition from pending → cataloged item

### Phase 4: Layer 2 Explicit Trigger (1 day)

**Modify Files:**
- `Sources/CatalogFeature/Views/PendingSessionCard.swift`
- `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift`

**Tasks:**
1. Add "Catalog" button to each detected object card
2. Implement Layer 2 trigger function (calls existing flow)
3. Show "Cataloging..." state during Layer 2
4. Update item with full catalog data on completion

### Phase 5: Navigation Integration (1.5 days)

**Modify Files:**
- `Sources/App/ContentView.swift` (or navigation coordinator)
- `Sources/CatalogFeature/Views/CatalogView.swift`

**Tasks:**
1. Add programmatic navigation from Camera to Catalog
2. Pass pending session context during navigation
3. Auto-scroll to pending section on arrival
4. Handle deep link to specific pending session

### Phase 6: Testing & Polish (1.5 days)

**Tasks:**
1. Write integration tests for capture → catalog flow
2. Test edge cases (network failure, timeout, concurrent captures)
3. Add haptic feedback for capture confirmation
4. Polish animations and transitions
5. Update UI specs documentation

---

## Files Summary

### New Files
| File | Purpose |
|------|---------|
| `Sources/CameraFeature/Models/PendingSessionState.swift` | PendingSession class and SessionStatus enum |
| `Sources/CameraFeature/Models/PendingSessionManager.swift` | Manages pending session lifecycle |
| `Sources/CatalogFeature/Views/PendingSessionCard.swift` | UI for pending items in Catalog |
| `Sources/CatalogFeature/Models/PendingItemModel.swift` | ViewModel for pending items display |

### Modified Files
| File | Changes |
|------|---------|
| `Sources/CameraFeature/Views/CaptureView.swift` | Remove results view, add navigation trigger |
| `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift` | Remove polling, add navigation signal |
| `Sources/CatalogFeature/Views/CatalogView.swift` | Add pending items section |
| `Sources/CatalogFeature/ViewModels/CatalogViewModel.swift` | Track pending sessions |
| `Sources/Persistence/Models/Item.swift` | Add sourceSessionId field (optional) |

### Archived Files
| File | Reason |
|------|--------|
| `Sources/CameraFeature/Views/DetectionResultsView.swift` | Functionality moves to Catalog |

---

## Key Design Decisions

### Decision 1: When to Navigate
**Chosen:** Navigate after upload + Layer 1 starts (~2-3s)
- Users see brief context overlay confirming capture
- Faster than waiting for Layer 1 complete (3-8s)
- Better than immediate nav with confusing empty state

### Decision 2: Layer 2 Trigger Pattern
**Chosen:** Explicit per-object button
- User controls cost by choosing which objects to catalog
- Can batch multiple objects in parallel
- Aligns with goal: "give user control over cataloging"

### Decision 3: Pending Session Persistence
**Chosen:** In-memory only (not persisted locally)
- Simpler architecture
- Firestore is source of truth
- Future enhancement: persist if app termination during processing is common

### Decision 4: Manager Location
**Chosen:** Shared manager injected into Camera + Catalog
- Single source of truth for pending sessions
- Both features observe same data
- Cleaner than passing session through navigation

---

## Success Criteria

| Criterion | Target | Measure |
|-----------|--------|---------|
| User blocked time after capture | < 3 seconds | Timer from capture to navigation |
| Pending items visible in Catalog | < 500ms after navigation | Firestore listener latency |
| Layer 1 results appear | < 8 seconds total | E2E timing |
| User can browse while processing | Yes | Manual testing |
| Layer 2 cost control | Per-object trigger works | Functional test |
| Zero regressions | Pass all existing tests | CI |

---

## Rollback Plan

1. **Feature Flag:** `ENABLE_BACKGROUND_PROCESSING_UX`
   - `false` → reverts to old blocking results screen
   - No code changes needed for rollback

2. **Data Safety:**
   - No migration needed
   - Existing CaptureSession documents remain valid
   - Pending sessions are in-memory only

---

## Testing Strategy

### Unit Tests
- `PendingSessionManagerTests` - Session lifecycle management
- `SessionStatusTransitionTests` - State machine transitions
- `PendingSessionTests` - Model behavior

### Integration Tests
- `CaptureToNavigationFlowTests` - End-to-end capture → navigation
- `FirestoreListenerIntegrationTests` - Real-time updates in Catalog

### UI Tests
- `PendingSessionCardUITests` - Progress indicator display
- `Layer2TriggerUITests` - "Catalog" button functionality
- `E2ECaptureToCatalogFlow` - Full user journey

---

## Related Documentation

- **Issue:** `docs/issues/2026-01-18-background-processing-ux-redesign.md`
- **Current Design:** `docs/plans/2026-01-16-gemini-layer1-capture-redesign.md`
- **UI Spec:** `docs/specs/SPEC-UI-001-camera-capture-flow.md` (update needed)
- **Catalog Spec:** `docs/specs/SPEC-UI-002-catalog-inventory-flow.md` (update needed)

---

## Estimated Timeline

| Phase | Duration |
|-------|----------|
| Phase 1: Pending Session Infrastructure | 2 days |
| Phase 2: Modify Capture Flow | 2 days |
| Phase 3: Catalog Pending Section | 2 days |
| Phase 4: Layer 2 Explicit Trigger | 1 day |
| Phase 5: Navigation Integration | 1.5 days |
| Phase 6: Testing & Polish | 1.5 days |
| **Total** | **10 days** |

---

## Next Steps

1. [ ] Review and approve this plan
2. [ ] Create feature branch from main
3. [ ] Begin Phase 1: Pending Session Infrastructure
4. [ ] Regular check-ins at each phase completion

# BUG-003: Inventory Camera Button Unresponsive

**Status**: Triaged
**Severity**: High
**Type**: Silent Failure
**Created**: 2025-11-17
**Original Issue**: .debug/issues/triaged/issue-001.md

---

## Description

When a user is viewing the empty inventory screen and taps the "Open Camera" button, nothing happens. The button is completely unresponsive, providing no feedback to the user.

This is a critical user experience issue because:
1. The empty state is the first thing new users see
2. The call-to-action (CTA) button is the primary way to start using the app
3. There is no error message or alternative path for the user

---

## Expected Behavior

According to **DESIGN-028-catalog-view-specification.md** (Section: Empty State, Line 421):

> **CTA Button**: "Capture Item" (PrimaryButton, Bright Blue glow)

When the user taps the "Open Camera" button:
1. The app should switch to the Camera tab
2. The camera view should open, ready to catalog items
3. User should be able to start capturing items immediately

The spec shows this implementation pattern:
```swift
CatalogEmptyState {
    viewModel.selectedTab = .camera
}
```

---

## Actual Behavior

From log analysis (session-20251117-055805.log):
- Build failed due to missing entitlements file (line 74)
- App attempted to install but failed with error `0xe8000067` (line 138)
- However, the core issue exists in the source code

From source code analysis:
- `Sources/InventoryFeature/InventoryView.swift:63` - Empty state button has a TODO comment
- `Sources/InventoryFeature/InventoryView.swift:63` - Action closure is empty: `{ /* TODO: Switch to camera tab */ }`

**Result**: Button tap does nothing. No navigation, no error, no feedback.

---

## Root Cause

### Primary Cause: Unimplemented Feature

**File**: `Sources/InventoryFeature/InventoryView.swift`
**Line**: 63

```swift
EmptyStateCard(
    iconName: "tray",
    headline: "No Items Yet",
    description: "Capture items with the camera to get started",
    buttonTitle: "Open Camera",
    action: { /* TODO: Switch to camera tab */ }  // ← EMPTY ACTION
)
```

The button action is a no-op closure. The TODO comment indicates this was intentionally left unimplemented.

### Contributing Issues

1. **Missing Tab Selection State**:
   - The `InventoryView` does not have access to the parent tab selection state
   - No binding to switch tabs programmatically
   - Unlike the spec's `CatalogView` which has `@Binding var selectedTab`

2. **Spec Drift**:
   - Spec calls for `FloatingTabBar` with tab selection state (DESIGN-028, line 462)
   - Current implementation uses `InventoryView` without tab bar integration
   - No navigation coordinator or tab switching mechanism

3. **Build Issues** (Secondary):
   - Missing entitlements file prevents app from running on device
   - Cannot manually test the button to discover this issue

---

## Affected Files

### Primary Files (Direct Bug)
1. `Sources/InventoryFeature/InventoryView.swift` (line 63)
   - Empty state button action needs implementation

### Related Files (Needed for Fix)
2. Parent view that hosts `InventoryView` with tab bar
   - Needs to pass tab selection binding
   - Location TBD (not found in codebase yet)

3. Tab bar implementation
   - May not exist yet (spec calls for `FloatingTabBar`)
   - Needs to expose tab selection state

### Build Issues (Blocking Testing)
4. Missing entitlements file
   - `/Users/w/code/abundance-mvp-xcode/Abundance/Abundance/Abundance.entitlements`
   - Prevents device deployment

---

## Suggested Fix

### Approach 1: Quick Fix (Tab Binding)

If a tab bar exists, pass tab selection binding to InventoryView:

**File**: `Sources/InventoryFeature/InventoryView.swift`

```swift
public struct InventoryView: View {
    @StateObject var viewModel: InventoryViewModel
    @Binding var selectedTab: Tab  // ← ADD THIS

    public init(
        viewModel: InventoryViewModel = InventoryViewModel(),
        selectedTab: Binding<Tab>  // ← ADD THIS
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTab = selectedTab  // ← ADD THIS
    }

    // ... rest of code ...
}

private struct EmptyInventoryView: View {
    @Binding var selectedTab: Tab  // ← ADD THIS

    var body: some View {
        EmptyStateCard(
            iconName: "tray",
            headline: "No Items Yet",
            description: "Capture items with the camera to get started",
            buttonTitle: "Open Camera",
            action: { selectedTab = .camera }  // ← FIX THIS
        )
        .padding()
    }
}
```

### Approach 2: Navigation Coordinator (Recommended)

Implement a proper navigation coordinator per DESIGN-028 architecture:

1. Create a `TabCoordinator` or `AppCoordinator`
2. Use an `@EnvironmentObject` for tab selection
3. Inject into all views that need tab switching

This aligns with the spec's approach and is more scalable.

---

## Test Plan

### Unit Tests
- [ ] Create `InventoryViewModelTests.swift`
  - Test that tab selection state can be modified
  - Test that empty state action triggers tab change

### Integration Tests
- [ ] Create `InventoryViewIntegrationTests.swift`
  - Test that tapping "Open Camera" button switches to camera tab
  - Verify camera view appears after tap
  - Verify correct analytics event is logged

### Manual Testing
- [ ] Fix entitlements issue to enable device deployment
- [ ] Launch app on device
- [ ] Navigate to inventory (should be empty for new user)
- [ ] Tap "Open Camera" button
- [ ] Verify camera tab becomes active
- [ ] Verify camera view is ready to capture

### Regression Testing
- [ ] Verify button works when inventory has items (if applicable)
- [ ] Test on both iPhone and iPad
- [ ] Test with VoiceOver enabled
- [ ] Test with Reduce Motion enabled

---

## Implementation Plan

### Phase 1: Investigate Tab Architecture (30 min)
1. Search codebase for existing tab bar implementation
2. Identify if `FloatingTabBar` from spec exists
3. Determine current navigation architecture

### Phase 2: Implement Fix (1-2 hours)
**Option A**: If tab bar exists
1. Update `InventoryView` to accept tab binding
2. Pass binding from parent view
3. Update empty state to use binding

**Option B**: If tab bar doesn't exist
1. Create navigation coordinator (follows DESIGN-028)
2. Implement tab selection state management
3. Update `InventoryView` to use coordinator
4. Update empty state to use coordinator

### Phase 3: Testing (1 hour)
1. Write unit tests
2. Write integration tests
3. Fix entitlements issue
4. Manual device testing

### Phase 4: Documentation (30 min)
1. Update DESIGN-028 if spec drift detected
2. Document navigation architecture
3. Add code comments explaining tab switching

---

## Related Issues

### Build Failure (Blocking Testing)
**Error**: Missing entitlements file
**Log Location**: session-20251117-055805.log:74
**Impact**: Cannot deploy to device for manual testing
**Fix**: Create or restore `Abundance.entitlements` file

### Potential Spec Drift
**Issue**: Current implementation does not match DESIGN-028 specification
**Details**:
- Spec calls for `CatalogView` with integrated `FloatingTabBar`
- Current code has `InventoryView` without tab bar
- Naming mismatch: "Catalog" vs "Inventory"

**Action**: Investigate if this is intentional renaming or incomplete implementation

---

## References

- **Spec**: docs/design/DESIGN-028-catalog-view-specification.md
  - Section: Empty State (lines 385-435)
  - Section: Floating Tab Bar (lines 437-515)
  - Section: SwiftUI Implementation Pattern (lines 737-797)
- **Source**: Sources/InventoryFeature/InventoryView.swift:63
- **Source**: Sources/InventoryFeature/EmptyStateCard.swift:35
- **Log**: .debug/logs/session-20251117-055805.log

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2025-11-17 | Triage Agent | Initial bug report created |

---

**Priority**: P1 (High) - Blocks primary user flow for new users
**Estimated Effort**: Small (2-4 hours with testing)
**Suggested Branch**: `fix/inventory-camera-button-navigation`

# Liquid Glass Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate all legacy SwiftUI material backgrounds (.ultraThinMaterial, .thickMaterial, etc.) to the unified `.adaptiveGlass()` modifier for iOS 26+ Liquid Glass support with proper iOS 17-25 fallbacks.

**Architecture:** Uses existing `LiquidGlassHelpers.swift` infrastructure which provides `AdaptiveGlassModifier` for automatic iOS version detection and `reduceTransparency` accessibility support. All migrations replace direct material usage with `.adaptiveGlass(cornerRadius:tint:)` or `.adaptiveGlass(in:tint:)` for custom shapes.

**Tech Stack:** SwiftUI 6.0, iOS 26+ `.glassEffect()`, iOS 17-25 `.thickMaterial` fallback, WCAG 2.2 AA accessibility compliance

**References:**
- Design Spec: `docs/archive/ios-pre-superpowers/design/DESIGN-031-swiftui-component-library.md`
- Color System: `docs/archive/ios-pre-superpowers/design/DESIGN-032-color-system-design-tokens.md`
- Existing Helper: `Sources/Core/DesignSystem/Extensions/LiquidGlassHelpers.swift`
- Axiom Skill: `axiom-liquid-glass` (loaded - Regular vs Clear variants, navigation layer patterns)

---

## Pre-Flight Checklist

Before starting, verify:
- [ ] Xcode project builds successfully: `./scripts/sim.sh --device w-16e`
- [ ] All tests pass: `swift test`
- [ ] On feature branch: `git checkout -b feature/liquid-glass-migration`

---

## Task 1: FloatingTabBar - Outer Background

**Files:**
- Modify: `Sources/InventoryFeature/Components/FloatingTabBar.swift:37`

**Step 1: Read current implementation**

```swift
// Current (line 37):
Capsule()
    .fill(.ultraThickMaterial)
```

**Step 2: Replace with adaptiveGlass**

```swift
// Updated:
Color.clear
    .adaptiveGlass(in: Capsule())
```

**Step 3: Verify in Simulator**

Run: `./scripts/sim.sh --device w-16e`
Expected: Tab bar renders with glass effect on iOS 26+, thick material on iOS 25

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/Components/FloatingTabBar.swift
git commit -m "refactor(ui): migrate FloatingTabBar outer background to adaptiveGlass"
```

---

## Task 2: FloatingTabBar - Selection Indicator

**Files:**
- Modify: `Sources/InventoryFeature/Components/FloatingTabBar.swift:76`

**Step 1: Read current implementation**

```swift
// Current (line 76):
Capsule()
    .fill(.thickMaterial)
    .matchedGeometryEffect(id: "selectedTab", in: tabNamespace)
```

**Step 2: Replace with adaptiveGlass**

```swift
// Updated:
Color.clear
    .adaptiveGlass(in: Capsule())
    .matchedGeometryEffect(id: "selectedTab", in: tabNamespace)
```

**Step 3: Verify tab selection animation**

Run: `./scripts/sim.sh --device w-16e`
Expected: Selection pill animates smoothly with glass effect

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/Components/FloatingTabBar.swift
git commit -m "refactor(ui): migrate FloatingTabBar selection indicator to adaptiveGlass"
```

---

## Task 3: InventoryView - Selection Toolbar

**Files:**
- Modify: `Sources/InventoryFeature/InventoryView.swift:174`

**Step 1: Read current implementation**

```swift
// Current (line 174):
.background(.ultraThinMaterial)
```

**Step 2: Replace with adaptiveGlass**

```swift
// Updated:
.adaptiveGlass(cornerRadius: 16)
```

**Step 3: Verify selection mode toolbar**

Run: `./scripts/sim.sh --device w-16e`
- Enter selection mode by tapping "Select"
- Expected: Toolbar at bottom renders with glass effect

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/InventoryView.swift
git commit -m "refactor(ui): migrate InventoryView selection toolbar to adaptiveGlass"
```

---

## Task 4: EditItemSheet - Saving Overlay

**Files:**
- Modify: `Sources/InventoryFeature/EditFlow/EditItemSheet.swift:338`

**Step 1: Read current implementation**

```swift
// Current (line 338):
.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
```

**Step 2: Replace with adaptiveGlass**

```swift
// Updated:
.adaptiveGlass(cornerRadius: 16)
```

**Step 3: Verify saving state overlay**

Run: `./scripts/sim.sh --device w-16e`
- Edit an item and tap Save
- Expected: Saving overlay shows glass effect

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/EditFlow/EditItemSheet.swift
git commit -m "refactor(ui): migrate EditItemSheet saving overlay to adaptiveGlass"
```

---

## Task 5: RescanComparisonSheet - Bottom Action Bar

**Files:**
- Modify: `Sources/InventoryFeature/EditFlow/RescanComparisonSheet.swift:98`

**Step 1: Read current implementation**

```swift
// Current (line 98):
.background(.ultraThinMaterial)
```

**Step 2: Replace with adaptiveGlass**

```swift
// Updated:
.adaptiveGlass(cornerRadius: 16)
```

**Step 3: Verify comparison sheet action bar**

Run: `./scripts/sim.sh --device w-16e`
- Navigate to rescan comparison flow
- Expected: Action bar at bottom renders with glass effect

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/EditFlow/RescanComparisonSheet.swift
git commit -m "refactor(ui): migrate RescanComparisonSheet action bar to adaptiveGlass"
```

---

## Task 6: RescanCameraView - Instruction Text Background

**Files:**
- Modify: `Sources/InventoryFeature/EditFlow/RescanCameraView.swift:54`

**Step 1: Read current implementation**

```swift
// Current (line 54):
Capsule()
    .fill(.ultraThinMaterial)
```

**Step 2: Replace with adaptiveGlass (Clear variant for camera overlay)**

Per Axiom liquid-glass skill: Use Clear variant over camera preview where photo accuracy matters.

```swift
// Updated:
Color.clear
    .adaptiveGlass(in: Capsule())
```

**Note:** The `.adaptiveGlass()` helper uses Regular variant by default. For camera overlays, this is acceptable as the adaptive behavior handles light/dark switching appropriately. If clearer transparency is needed later, consider adding `.adaptiveGlass(in: Capsule(), variant: .clear)` support.

**Step 3: Verify instruction text over camera**

Run: `./scripts/sim.sh --device w-16e`
- Enter rescan camera flow
- Expected: Instruction text pill renders with glass effect over live camera

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/EditFlow/RescanCameraView.swift
git commit -m "refactor(ui): migrate RescanCameraView instruction background to adaptiveGlass"
```

---

## Task 7: RescanCameraView - Processing Overlay

**Files:**
- Modify: `Sources/InventoryFeature/EditFlow/RescanCameraView.swift:153`

**Step 1: Read current implementation**

```swift
// Current (line 153):
RoundedRectangle(cornerRadius: 20)
    .fill(.ultraThinMaterial)
```

**Step 2: Replace with adaptiveGlass**

```swift
// Updated:
Color.clear
    .adaptiveGlass(cornerRadius: 20)
```

**Step 3: Verify processing overlay**

Run: `./scripts/sim.sh --device w-16e`
- Capture photo in rescan flow
- Expected: Processing overlay renders with glass effect

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/EditFlow/RescanCameraView.swift
git commit -m "refactor(ui): migrate RescanCameraView processing overlay to adaptiveGlass"
```

---

## Task 8: SignInView - Error Background

**Files:**
- Modify: `Sources/OnboardingFeature/SignInView.swift:143`

**Step 1: Read current implementation**

```swift
// Current (line 143):
RoundedRectangle(cornerRadius: 8)
    .fill(.ultraThinMaterial)
```

**Step 2: Replace with adaptiveGlass**

```swift
// Updated:
Color.clear
    .adaptiveGlass(cornerRadius: 8)
```

**Step 3: Verify error display**

Run: `./scripts/sim.sh --device w-16e`
- Trigger sign-in error (use invalid credentials)
- Expected: Error message container renders with glass effect

**Step 4: Commit**

```bash
git add Sources/OnboardingFeature/SignInView.swift
git commit -m "refactor(ui): migrate SignInView error background to adaptiveGlass"
```

---

## Task 9: PrimaryButton - Material Background

**Files:**
- Modify: `Sources/Core/DesignSystem/Components/PrimaryButton.swift:68`

**Step 1: Read current implementation**

```swift
// Current (line 68):
private var backgroundMaterial: AnyShapeStyle {
    reduceTransparency ? AnyShapeStyle(Color.backgroundDefault) : AnyShapeStyle(.thinMaterial)
}

// Used at line 42:
.background(backgroundMaterial, in: Capsule())
```

**Step 2: Replace with adaptiveGlass**

Remove `backgroundMaterial` computed property and update line 42:

```swift
// Updated (line 42):
.adaptiveGlass(in: Capsule())
```

**Note:** `AdaptiveGlassModifier` already handles `reduceTransparency` internally, so the manual check is no longer needed.

**Step 3: Remove unused backgroundMaterial property**

Delete lines 67-70:
```swift
// DELETE:
private var backgroundMaterial: AnyShapeStyle {
    reduceTransparency ? AnyShapeStyle(Color.backgroundDefault) : AnyShapeStyle(.thinMaterial)
}
```

**Step 4: Verify all PrimaryButton usages**

Run: `./scripts/sim.sh --device w-16e`
- Check: Onboarding buttons, Save buttons, Export buttons
- Expected: All primary buttons render with glass effect
- Verify: Reduce Transparency accessibility setting shows opaque background

**Step 5: Commit**

```bash
git add Sources/Core/DesignSystem/Components/PrimaryButton.swift
git commit -m "refactor(ui): migrate PrimaryButton to adaptiveGlass, remove duplicate reduceTransparency check"
```

---

## Task 10: InventoryView - Select Button Toolbar Styling

**Files:**
- Modify: `Sources/InventoryFeature/InventoryView.swift:83-93`

**Step 1: Read current implementation**

```swift
// Current:
ToolbarItem(placement: .primaryAction) {
    if !viewModel.items.isEmpty && !viewModel.isLoading {
        Button(isSelectionMode ? "Done" : "Select") {
            withAnimation(.brandSnappy) {
                isSelectionMode.toggle()
                if !isSelectionMode {
                    selectedItemIds.removeAll()
                }
            }
        }
    }
}
```

**Step 2: Add .borderedProminent + .tint() styling**

Per Axiom liquid-glass skill: Use `.buttonStyle(.borderedProminent)` + `.tint()` for primary toolbar actions.

```swift
// Updated:
ToolbarItem(placement: .primaryAction) {
    if !viewModel.items.isEmpty && !viewModel.isLoading {
        Button(isSelectionMode ? "Done" : "Select") {
            withAnimation(.brandSnappy) {
                isSelectionMode.toggle()
                if !isSelectionMode {
                    selectedItemIds.removeAll()
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.accentPrimary)
    }
}
```

**Step 3: Verify toolbar button appearance**

Run: `./scripts/sim.sh --device w-16e`
- Navigate to Catalog view with items
- Expected: "Select" button shows bordered prominent style with blue tint

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/InventoryView.swift
git commit -m "style(ui): add borderedProminent + tint to InventoryView Select button"
```

---

## Task 11: EditItemSheet - Save Button Toolbar Styling

**Files:**
- Modify: `Sources/InventoryFeature/EditFlow/EditItemSheet.swift:204-214`

**Step 1: Read current implementation**

```swift
// Current:
ToolbarItem(placement: .confirmationAction) {
    Button("Save") {
        Task {
            try? await viewModel.saveManualEdits()
            if viewModel.state == .idle {
                dismiss()
            }
        }
    }
    .disabled(!viewModel.validationErrors.isEmpty || viewModel.state == .saving)
}
```

**Step 2: Add .borderedProminent + .tint() styling**

```swift
// Updated:
ToolbarItem(placement: .confirmationAction) {
    Button("Save") {
        Task {
            try? await viewModel.saveManualEdits()
            if viewModel.state == .idle {
                dismiss()
            }
        }
    }
    .buttonStyle(.borderedProminent)
    .tint(Color.successColor)
    .disabled(!viewModel.validationErrors.isEmpty || viewModel.state == .saving)
}
```

**Step 3: Verify save button appearance**

Run: `./scripts/sim.sh --device w-16e`
- Open edit sheet for any item
- Expected: "Save" button shows bordered prominent style with green tint

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/EditFlow/EditItemSheet.swift
git commit -m "style(ui): add borderedProminent + tint to EditItemSheet Save button"
```

---

## Post-Migration Verification

### Step 1: Run full test suite

```bash
swift test
```
Expected: All tests pass

### Step 2: Run SwiftLint

```bash
swiftlint
```
Expected: Zero warnings

### Step 3: Check architecture drift

```bash
# Use check-drift command if available
/check-drift
```
Expected: No P0/P1 violations

### Step 4: Visual regression test (manual)

Test on Simulator with these configurations:
- [ ] Light mode, standard settings
- [ ] Dark mode (if supported)
- [ ] Reduce Transparency ON
- [ ] Increase Contrast ON
- [ ] Reduce Motion ON
- [ ] Dynamic Type (Large, xLarge, xxxLarge)

### Step 5: Final commit with summary

```bash
git add -A
git commit -m "feat(ui): complete Liquid Glass migration

Migrated 9 material backgrounds to .adaptiveGlass():
- FloatingTabBar (2 locations)
- InventoryView selection toolbar
- EditItemSheet saving overlay
- RescanComparisonSheet action bar
- RescanCameraView (2 locations)
- SignInView error background
- PrimaryButton

Added toolbar styling improvements:
- InventoryView Select button: .borderedProminent + .tint(.blue)
- EditItemSheet Save button: .borderedProminent + .tint(.green)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Files Modified | 7 |
| Material Migrations | 9 |
| Toolbar Enhancements | 2 |
| Lines Changed (est.) | ~50 |
| Commits | 12 |

## Rollback Plan

If issues arise, revert to previous state:

```bash
git revert HEAD~12..HEAD
```

Or cherry-pick specific commits to keep.

---

## Related Documentation

- **Axiom Liquid Glass Skill:** Comprehensive patterns for Regular vs Clear variants, navigation layer patterns
- **DESIGN-031:** SwiftUI Component Library with material specifications
- **DESIGN-032:** Color system with WCAG 2.2 AA compliance
- **LiquidGlassHelpers.swift:** Existing `.adaptiveGlass()` infrastructure

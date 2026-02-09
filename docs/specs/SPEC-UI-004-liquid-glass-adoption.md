# SPEC-UI-004: Liquid Glass Navigation Adoption

**Status:** Draft
**Created:** 2026-02-06
**References:** Brand Bible v3.0 (Section 1.7 Two-Layer Strategy),
               axiom-liquid-glass-ref, axiom-swiftui-26-ref
**Code Refs:** App/AbundanceApp.swift, Sources/CollectionFeature/,
              Sources/CameraFeature/, Sources/Core/DesignSystem/

---

## 1. Overview

This spec defines the adoption of iOS 26 Liquid Glass for navigation-layer elements in the Abundance app. It implements the Two-Layer Strategy from the brand bible: Navigation Layer = Liquid Glass, Content Layer = Opaque Brand Fills.

**Scope:** Tab bar, navigation bars, search bar, modals/sheets, toolbar items. Content-layer components are covered in SPEC-UI-003.

**Prerequisite:** SPEC-UI-003 must be completed first (color palette migration).

---

## 2. Tab Bar

### 2.1 Current State

`App/DebugMainTabView.swift` uses a standard `TabView` with 3 tabs and `.tint(Color.salmon)`. Tab labels follow ADR-027 terminology: "Collection" (not "Catalog"), "Scan" (not "Camera"), "Profile".

The custom `FloatingTabBar` component still exists in `Sources/CollectionFeature/Components/FloatingTabBar.swift` but is not used in the main app tab bar. It may be used in other contexts.

### 2.2 Implemented State

```swift
TabView(selection: $selectedTab) {
    CollectionView(viewModel: collectionViewModel, onOpenCamera: { selectedTab = .scan })
        .tabItem { Label("Collection", systemImage: "square.grid.2x2.fill") }
        .tag(Tab.collection)
    // Camera / Placeholder
        .tabItem { Label("Scan", systemImage: "camera.fill") }
        .tag(Tab.scan)
    ProfileView(viewModel: profileViewModel)
        .tabItem { Label("Profile", systemImage: "person.fill") }
        .tag(Tab.profile)
}
.tint(Color.salmon)
```

**iOS 26 automatic behavior:**
- Tab bar automatically adopts Liquid Glass (`.glassEffect(.regular)`)
- Active tab icon tinted Salmon via `.tint(Color.salmon)`
- Inactive icons use `.secondary` vibrancy (system default)
- Tab icons use `.fill` variants for visual weight

**Reduce Transparency fallback:**
- System automatically makes glass frostier
- No custom code needed for standard TabView

### 2.3 FloatingTabBar Status

The main app tab bar now uses the standard `TabView` with `.tint(Color.salmon)`. The custom `FloatingTabBar.swift` component still exists in `Sources/CollectionFeature/Components/FloatingTabBar.swift` and uses `.adaptiveGlass(in: Capsule())` for its styling. It is not used for the primary app navigation but may serve other UI contexts. It can be removed when confirmed unused.

---

## 3. Navigation Bar

### 3.1 Target State

All `NavigationStack` instances automatically get Liquid Glass navigation bars when compiled with iOS 26 SDK. No code changes required.

**Brand rules:**
- Navigation bar title: System `.primary` vibrancy (auto on glass)
- Navigation bar background: `.glassEffect(.regular)` (automatic)
- Back button: System default
- Toolbar items: System Liquid Glass treatment

### 3.2 Audit Status

No custom `.toolbarBackground()` calls exist in the codebase. Navigation bars use system defaults, which enables Liquid Glass behavior automatically on iOS 26.

---

## 4. Search Bar

### 4.1 Current State

`Sources/CollectionFeature/Components/SearchBar.swift` is a custom search implementation.

### 4.2 Target State

**Option A (Recommended):** Use `.searchable(text:)` modifier on the list. iOS 26 automatically provides a glass capsule search bar.

```swift
NavigationStack {
    List { ... }
        .searchable(text: $searchText)
}
```

**Option B:** Keep custom SearchBar but ensure it:
- Uses `.glassEffect(.regular)` when inactive (navigation layer)
- Transitions to opaque WarmWhite when active/focused (content layer)
- Uses DeepPlum text, Salmon cursor

### 4.3 Scroll Edge Effects

Add scroll edge effects for content scrolling under navigation:

```swift
.scrollEdgeEffectStyle(.soft, for: .top)
.scrollEdgeEffectStyle(.soft, for: .bottom)
```

**Note:** Never use `.hard` style on iOS per brand bible / HIG.

---

## 5. Sheets and Modals

### 5.1 Current Sheet Usage

- `EditItemSheet` — full edit form
- `RescanPromptSheet` — medium detent
- `RescanComparisonSheet` — comparison view

### 5.2 Target State

**Partial-height sheets (medium detent):**
- Use `.glassEffect(.regular)` — system manages automatically
- No custom background needed

**Full-height sheets:**
- System transitions from glass to opaque automatically
- Use `Color.warmWhite` as content background

**Close button:** Use new iOS 26 `Button(role: .close)` for dismiss:
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button(role: .close) { dismiss() }
    }
}
```

### 5.3 Cleanup Status

No custom `.presentationBackground()` calls exist in the codebase. Sheets use system defaults, enabling automatic Liquid Glass behavior on iOS 26.

---

## 6. Contextual Menus

### 6.1 Target State

Context menus use system Liquid Glass automatically. Ensure:
- Long-press on item cards shows: Edit, Share, Delete
- Menu anchored to touch point (system default)
- Destructive actions use `role: .destructive`

```swift
.contextMenu {
    Button("Edit", systemImage: "pencil") { edit() }
    Button("Share", systemImage: "square.and.arrow.up") { share() }
    Divider()
    Button("Delete", systemImage: "trash", role: .destructive) { delete() }
}
```

---

## 7. Current Glass Effect Usage

The following source files use glass effects (via `.glassEffect()` or `.adaptiveGlass()`):

**Camera Feature (direct `.glassEffect()`):**
- `CaptureView.swift` - Mode indicator and instruction label capsules
- `CaptureOverlays.swift` - Capture, uploading overlays (with `.ultraThinMaterial` fallback)
- `DetectionResultsView.swift` - Catalog buttons, bottom bar
- `ErrorRecoveryView.swift` - Error card, OfflineModeIndicator

**Camera Feature (`.adaptiveGlass()`):**
- `SweepCaptureView.swift` - Sweep UI controls
- `SweepModeToggle.swift` - Mode selector pill

**Collection Feature (`.adaptiveGlass()`):**
- `SearchBar.swift` - Search capsule
- `FloatingTabBar.swift` - Tab bar and tab items
- `PhotoCarouselView.swift` - Photo counter
- `EditItemSheet.swift` - Primary photo label
- `RescanCameraView.swift` - Camera UI
- `AddPhotoCameraView.swift` - Camera UI

**Onboarding Feature (direct `.glassEffect()`):**
- `SignInView.swift` - Sign-in button

**Note:** For custom floating UI with multiple glass elements, use `GlassEffectContainer` for performance:
```swift
GlassEffectContainer {
    HStack {
        Button("Action 1") { }.glassEffect()
        Button("Action 2") { }.glassEffect()
    }
}
```

---

## 8. Implementation Status

| Step | Item | Status |
|------|------|--------|
| 1 | **Tab bar** — Standard TabView with `.tint(.salmon)` | Completed |
| 2 | **FloatingTabBar** — Evaluate removal | Pending (component exists but not used for main tab bar) |
| 3 | **Navigation bars** — No custom backgrounds | Completed (none found) |
| 4 | **Search** — Custom SearchBar with `.adaptiveGlass()` | In use (`.searchable()` migration pending evaluation) |
| 5 | **Sheets** — No custom backgrounds | Completed (none found) |
| 6 | **Scroll edge effects** — `.scrollEdgeEffectStyle(.soft)` | Not yet implemented |
| 7 | **Context menus** — Consistent menu items | Completed (Edit, Refresh, Delete via `SelectionModeContextMenuModifier`) |

---

## 9. Testing

### 9.1 Visual Verification

For each navigation element:
- [ ] Default appearance: Liquid Glass visible
- [ ] Warm content below tints glass naturally
- [ ] Reduce Transparency: glass becomes frostier (automatic)
- [ ] Reduce Motion: no interactive glass effects
- [ ] Scrolling: content blurs smoothly under glass bars
- [ ] Tab minimization: tab bar recedes on scroll down

### 9.2 Compatibility

- [ ] Compiled with Xcode 26 SDK
- [ ] Tested on iOS 26 simulator
- [ ] No `UIDesignRequiresCompatibility` key in Info.plist
- [ ] No custom toolbar/tabbar backgrounds interfering

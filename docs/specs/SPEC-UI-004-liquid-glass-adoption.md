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

`App/DebugMainTabView.swift` uses a basic `TabView` with 3 tabs and a custom `FloatingTabBar` component in `Sources/CollectionFeature/Components/FloatingTabBar.swift`.

### 2.2 Target State

```swift
TabView {
    CollectionView()
        .tabItem { Label("Catalog", systemImage: "square.grid.2x2") }
    CameraView()
        .tabItem { Label("Scan", systemImage: "camera") }
    ProfileView()
        .tabItem { Label("Profile", systemImage: "person") }
}
.tint(Color.salmon)
```

**iOS 26 automatic behavior:**
- Tab bar automatically adopts Liquid Glass (`.glassEffect(.regular)`)
- Active tab icon tinted Salmon via `.tint(Color.salmon)`
- Inactive icons use `.secondary` vibrancy (system default)
- Tab bar minimizes on scroll (add `.tabBarMinimizeBehavior(.onScrollDown)`)

**Reduce Transparency fallback:**
- System automatically makes glass frostier
- No custom code needed for standard TabView

### 2.3 FloatingTabBar Decision

The custom `FloatingTabBar.swift` should be evaluated:
- If it duplicates standard TabView behavior → remove it, use system TabView
- If it provides custom functionality → audit for Liquid Glass compatibility

**Recommendation:** Remove `FloatingTabBar.swift` and use standard TabView. iOS 26 tab bars are already floating capsule-shaped. Custom implementation adds maintenance burden and may conflict with system Liquid Glass behavior.

---

## 3. Navigation Bar

### 3.1 Target State

All `NavigationStack` instances automatically get Liquid Glass navigation bars when compiled with iOS 26 SDK. No code changes required.

**Brand rules:**
- Navigation bar title: System `.primary` vibrancy (auto on glass)
- Navigation bar background: `.glassEffect(.regular)` (automatic)
- Back button: System default
- Toolbar items: System Liquid Glass treatment

### 3.2 Audit Items

Remove any custom navigation bar backgrounds:
```swift
// REMOVE if found
.toolbarBackground(.visible, for: .navigationBar)
.toolbarBackground(Color.someColor, for: .navigationBar)
```

These will interfere with Liquid Glass.

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

### 5.3 Cleanup

Remove any custom sheet backgrounds:
```swift
// REMOVE
.presentationBackground(.ultraThinMaterial)
.presentationBackground(Color.someColor)
```

Let system handle sheet appearance.

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

## 7. GlassEffectContainer for Custom Glass

If any custom floating UI elements need glass (e.g., floating action buttons, custom overlays), wrap them in `GlassEffectContainer` for performance:

```swift
GlassEffectContainer {
    HStack {
        Button("Action 1") { }.glassEffect()
        Button("Action 2") { }.glassEffect()
    }
}
```

---

## 8. Implementation Order

1. **Tab bar** — Switch to standard TabView with `.tint(.salmon)`
2. **Remove FloatingTabBar** — Use system tab bar
3. **Navigation bars** — Remove custom backgrounds, let system manage
4. **Search** — Evaluate `.searchable()` vs custom SearchBar
5. **Sheets** — Remove custom backgrounds, add `Button(role: .close)`
6. **Scroll edge effects** — Add `.scrollEdgeEffectStyle(.soft, for:)`
7. **Context menus** — Ensure consistent menu items

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

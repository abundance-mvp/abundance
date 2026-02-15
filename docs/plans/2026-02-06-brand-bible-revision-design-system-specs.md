# Brand Bible Revision & Design System Specs — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Revise the brand bible to remove on-device AI content, align with the actual codebase and specs, and produce actionable implementation specs for bringing the UI into compliance with the design system.

**Architecture:** Three-phase approach: (1) Create a revised brand bible focused purely on visual identity and UI specifications, (2) Create a SPEC-UI-003 design system spec that maps brand bible rules to concrete codebase changes, (3) Create a SPEC-UI-004 Liquid Glass adoption spec for iOS 26 navigation/glass patterns.

**Tech Stack:** SwiftUI, iOS 26 Liquid Glass APIs, SF Symbols, Asset Catalogs

---

## Context: Current State Analysis

### What the Brand Bible Specifies vs What Exists

| Area | Brand Bible Says | Codebase Has | Gap |
|------|-----------------|--------------|-----|
| **Primary Accent** | Salmon `#E8907A` (opaque fill) | `brandBrightBlue` `#4381DF` (glass + glow) | Complete mismatch |
| **Text Color** | DeepPlum `#3B2E3A` everywhere | `textPrimary` = `#3B2E3A` (correct value, wrong name) | Naming mismatch |
| **Card Background** | Cream `#F0DCC0` opaque | Glass material (`.adaptiveGlass()`) | Wrong approach |
| **Card Border** | Peach `#EDBE9E` 1px stroke | Blue stroke (`.brandBrightBlue`) | Wrong color |
| **Button Style** | Opaque Salmon capsule, DeepPlum text | Glass capsule with blue glow/stroke | Wrong style |
| **Animations** | `.spring(response: 0.5, dampingFraction: 0.6)` | `.spring(response: 0.3, dampingFraction: 0.6)` (brandSnappy) | Close but not matching |
| **Color Assets** | 15 named color sets in xcassets | Zero xcassets colors (all hardcoded hex) | Missing entirely |
| **Navigation** | 5 tabs: Catalog, Scan, Share, Trade, Profile | 3 tabs (debug: Inventory, Camera, Profile) | Different count |
| **Behind-Glass Variants** | SalmonBehindGlass, PeachBehindGlass, TealBehindGlass | None | Missing |
| **Accessibility Fallbacks** | Reduce Transparency, Motion, Contrast all specified | Partial (reduceTransparency in some views, reduceMotion in camera) | Incomplete |
| **Two-Layer Strategy** | Navigation = Glass, Content = Opaque brand fills | Cards use glass (wrong layer), buttons use glass (wrong) | Inverted |

### On-Device AI Content to Remove

The brand bible's Part IV (On-Device Intelligence) covers Foundation Models, Core ML, and Vision pipeline details that:
- Duplicate content in SPEC-PIPE-001/002/003 (server-side AI pipeline)
- Reference iOS 26 Foundation Models framework (not yet in the app — AI runs server-side via Gemini)
- Confuse the design system document with implementation architecture

### What's Correct in the Brand Bible

These sections are well-aligned and should be preserved:
- Part I: Brand Identity (aesthetic, colors, materials, lighting, mood) — **keep as-is**
- Section 1.6: App Icon Specification — **keep as-is**
- Section 1.7: Two-Layer Strategy — **keep, but annotate current vs target state**
- Part II: Design System Specs (shapes, layout, typography, components) — **keep, align with codebase**
- Section 2.5: Accessibility Fallbacks — **keep, these are mandatory**
- Part V: Implementation Reference (minus scanner overlay which is aspirational) — **keep, update**
- Appendices A/B/C — **keep as-is**

---

## Phase 1: Revised Brand Bible

### Task 1: Create Revised Brand Bible v3.0

**Files:**
- Create: `docs/brand/abundance-brand-bible-v3-2026-02-06.md`
- Reference: `docs/brand/abundance-brand-bible-ondevice-2026-02-06.md` (current v2.0)

**Step 1: Write the revised brand bible**

The new document should contain the following structure (changes from v2.0 noted):

```markdown
# Abundance Brand Bible & Design System v3.0

> **Target:** iOS 26 / iPadOS 26 / macOS 26 with Liquid Glass
> **Supersedes:** v2.0 (February 2026 "on-device" edition). Removes on-device AI
>   content (now covered by SPEC-PIPE-* specs). Aligns with current codebase.
> **Last Updated:** February 2026

## How to Use This Document
[KEEP from v2.0 — no changes needed]

## Part I: Corrected Brand Identity
### 1.1 Aesthetic Classification
[KEEP from v2.0 — claymorphism definition is correct]

### 1.2 Color Palette
[KEEP from v2.0 — all hex values and roles are correct]
[ADD: "Current Implementation Status" callout noting Color+Brand.swift uses
 different colors and needs migration per SPEC-UI-003]

### 1.3 Material Language
[KEEP from v2.0]

### 1.4 Lighting Model
[KEEP from v2.0]

### 1.5 Brand Mood
[KEEP from v2.0]

### 1.6 App Icon Specification
[KEEP from v2.0]

### 1.7 The Two-Layer Strategy
[KEEP from v2.0]
[ADD: "Current Implementation Note" — the codebase currently uses glass effects
 on content-layer elements (cards, buttons). SPEC-UI-003 defines the migration
 to opaque content-layer fills.]

## Part II: Design System Specifications
### 2.1 Shape System
[KEEP from v2.0]

### 2.2 Layout Rules
[KEEP from v2.0]

### 2.3 Typography
[KEEP from v2.0]

### 2.4 Component State & Material Matrix
[KEEP from v2.0]
[UPDATE: Add "Current State" column showing what the codebase actually does today
 for each component, cross-referencing SPEC-UI-003 for migration tasks]

### 2.5 Mandatory Accessibility Fallback States
[KEEP from v2.0 — these are non-negotiable requirements]

## Part III: Core UX Flows
### 3.1 Splash Screen
[KEEP from v2.0]

### 3.2 Onboarding
[KEEP from v2.0 — aspirational but well-defined]

### 3.3 Navigation
[KEEP floating tab bar spec from v2.0]
[UPDATE: Note that current app has 3 tabs (Inventory, Camera, Profile).
 Share and Trade tabs are future features. Brand bible defines the target
 navigation but implementation should match current feature set.]

### 3.4 Scanner
[KEEP viewfinder spec from v2.0]
[REMOVE: "On-Device Recognition Pipeline" subsection (lines 447-453)]
[REPLACE WITH: "Recognition Pipeline" that says:
 "Object detection and cataloging are handled server-side via the AI pipeline.
  See SPEC-PIPE-001 (Layer 1 detection) and SPEC-PIPE-002 (Layer 2 cataloging)
  for implementation details. The scanner UI captures photos and uploads them
  for server processing per SPEC-UI-001."]
[KEEP success/error state specs]

### 3.5 Catalog
[KEEP item card spec, grid layout, empty states from v2.0]

## Part IV: [REMOVED — On-Device Intelligence]
[ENTIRE PART IV REMOVED. Add a note:]
"Part IV (On-Device Intelligence) from v2.0 has been removed from the brand
 bible. AI pipeline architecture is documented in:
 - SPEC-PIPE-001: Layer 1 Detection (Gemini Flash)
 - SPEC-PIPE-002: Layer 2 Cataloging (Gemini Pro)
 - SPEC-PIPE-003: Session Persistence
 - SPEC-ARCH-002: Layer 1/Layer 2 Pipeline Architecture

 On-device Foundation Models integration is a future capability tracked
 separately from the design system."

## Part V: Implementation Reference  [RENUMBERED to Part IV]
### 4.1 SwiftUI Environment Variables
[KEEP from v2.0 section 5.1]

### 4.2 SwiftUI Implementation Blueprints
[KEEP from v2.0 section 5.2]
[UPDATE: Cross-reference SPEC-UI-003 for each blueprint, noting which
 ones are implemented vs which need migration]

### 4.3 Asset Catalog Setup
[KEEP from v2.0 section 5.3]
[ADD: Note that xcassets color sets do not yet exist — implementation
 tracked in SPEC-UI-003 Task 1]

### 4.4 Performance Rules
[KEEP from v2.0 section 5.4]

### 4.5 Cross-Platform Behavior
[KEEP from v2.0 section 5.5]

## Appendix A: WWDC25 Session Index
[KEEP — remove rows for Foundation Models sessions 286/301]

## Appendix B: Documentation URLs
[KEEP — remove Foundation Models URL]

## Appendix C: Quick Decision Reference
[KEEP from v2.0]
```

**Step 2: Verify the document is self-consistent**

Check that:
- No references to Foundation Models, `@Generable`, `@Guide`, `LanguageModelSession`
- No references to Core ML models or `SneakerClassifier`
- No references to `MarketLookupTool` or Tool protocol
- All color hex values match the palette table
- Cross-references to SPEC-UI-003 and SPEC-UI-004 are consistent

**Step 3: Commit**

```bash
git add docs/brand/abundance-brand-bible-v3-2026-02-06.md
git commit -m "docs(brand): create brand bible v3.0 — remove on-device AI, align with codebase"
```

---

## Phase 2: Design System Implementation Spec

### Task 2: Create SPEC-UI-003 — Design System Implementation

This is the core deliverable: a spec document that tells an engineer exactly what to change in the codebase to align with the brand bible.

**Files:**
- Create: `docs/specs/SPEC-UI-003-design-system.md`

**Step 1: Write the spec**

```markdown
# SPEC-UI-003: Design System Implementation

**Status:** Draft
**Created:** 2026-02-06
**References:** Brand Bible v3.0, SPEC-UI-001, SPEC-UI-002
**Code Refs:** Sources/Core/DesignSystem/, Sources/CollectionFeature/,
              Sources/CameraFeature/, Sources/ProfileFeature/, App/

---

## 1. Overview

This spec defines the concrete codebase changes required to align the Abundance
iOS app with the Brand Bible v3.0 design system. Each section maps a brand bible
rule to specific file changes.

**Scope:** Color palette migration, component restyling, accessibility fallbacks,
asset catalog creation. Does NOT cover Liquid Glass navigation adoption (see
SPEC-UI-004).

---

## 2. Color Palette Migration

### 2.1 Current State

`Sources/Core/DesignSystem/Extensions/Color+Brand.swift` defines colors from
a prior design iteration that do not match the brand bible:

| Current Name | Current Hex | Brand Bible Name | Brand Bible Hex |
|-------------|-------------|-----------------|----------------|
| `brandBrightBlue` | `#4381DF` | *(no equivalent — remove)* | — |
| `brandCoralOrange` | `#FF9A6F` | *(no equivalent — remove)* | — |
| `brandSalmonPink` | `#FFC4B4` | *(similar but wrong)* | Salmon `#E8907A` |
| `brandCreamYellow` | `#FFEDB9` | *(no equivalent — remove)* | — |
| `brandMintGreen` | `#B3FFE1` | MutedSage `#9DC4A8` | different |
| `textBrightBlue` | `#2D5FA3` | *(remove)* | — |
| `textCoralOrange` | `#CC5D3A` | *(remove)* | — |
| `textMintGreen` | `#008057` | *(remove)* | — |
| `textPrimary` | `#3B2E3A` | DeepPlum `#3B2E3A` | **Match** |
| `backgroundDefault` | `#FCFCFF` | WarmWhite `#FAF6F0` | close but wrong |

### 2.2 Target State

Replace `Color+Brand.swift` with brand bible-compliant colors:

```swift
// Sources/Core/DesignSystem/Extensions/Color+Brand.swift

import SwiftUI

public extension Color {
    // MARK: - Hex Initializer
    init(hex: String) {
        // [keep existing hex initializer unchanged]
    }

    // MARK: - Primary Brand Colors
    static let salmon = Color(hex: "E8907A")
    static let peach = Color(hex: "EDBE9E")
    static let cream = Color(hex: "F0DCC0")
    static let softTeal = Color(hex: "8ECAC0")
    static let mutedSage = Color(hex: "9DC4A8")

    // MARK: - Text Colors
    static let deepPlum = Color(hex: "3B2E3A")
    static let darkPlum = Color(hex: "2D2226")
    static let ultraDarkPlum = Color(hex: "1A1218")

    // MARK: - Background Colors
    static let backgroundTeal = Color(hex: "5BB8C9")
    static let warmWhite = Color(hex: "FAF6F0")

    // MARK: - Behind-Glass Pre-Saturated Variants
    static let salmonBehindGlass = Color(hex: "E87A60")
    static let peachBehindGlass = Color(hex: "EDB085")
    static let tealBehindGlass = Color(hex: "7AC4B8")

    // MARK: - Semantic Aliases
    static let accentPrimary = Color.salmon
    static let accentSecondary = Color.peach
    static let textPrimary = Color.deepPlum
    static let successColor = Color.mutedSage
    static let errorColor = Color.salmon
    static let backgroundDefault = Color.warmWhite
}
```

### 2.3 Migration Checklist

Every file using the old color names must be updated:

| File | Old Reference | New Reference |
|------|--------------|---------------|
| `Sources/Core/DesignSystem/Components/PrimaryButton.swift` | `brandBrightBlue` (glow, stroke) | Remove glow; use `.salmon` fill |
| `Sources/CollectionFeature/ItemCard.swift` | `.adaptiveGlass()` background | `.cream` opaque fill, `.peach` stroke |
| `Sources/CollectionFeature/SearchBar.swift` | Check for blue references | `.salmon` cursor, glass search styling |
| `Sources/CollectionFeature/EmptyStateCard.swift` | Check color usage | `.salmon` CTA, `.deepPlum` text |
| `Sources/CollectionFeature/ItemDetailView.swift` | Check color usage | `.deepPlum` text, `.cream` metadata bg |
| `Sources/CameraFeature/Views/DetectionResultsView.swift` | `.blue` on catalog button | `.salmon` accent |
| `Sources/CameraFeature/Views/CaptureOverlays.swift` | `.white` text | Keep (camera is dark context) |
| `Sources/ProfileFeature/ProfileView.swift` | Check color usage | `.deepPlum` text, `.warmWhite` bg |
| `Sources/ProfileFeature/Components/UserInfoCard.swift` | Check color usage | `.cream` card, `.peach` border |
| `App/DebugMainTabView.swift` | Check tab styling | `.salmon` tint |

**Rule:** Search codebase for all instances of: `brandBrightBlue`, `brandCoralOrange`,
`brandSalmonPink`, `brandCreamYellow`, `brandMintGreen`, `textBrightBlue`,
`textCoralOrange`, `textMintGreen`, `accentPrimary`, `accentSecondary`,
`successColor`, `warningColor`, `errorColor`, `backgroundDefault`, `successGlow`,
`textLink`. Each must be remapped to the new palette.

---

## 3. Component Restyling

### 3.1 PrimaryButton

**File:** `Sources/Core/DesignSystem/Components/PrimaryButton.swift`

**Current:** Glass capsule with blue glow and blue stroke
**Target:** Opaque Salmon capsule, DeepPlum text, no glow, press scale 0.97

```swift
public var body: some View {
    Button(action: handleTap) {
        ZStack {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.deepPlum)
                .opacity(isLoading ? 0 : 1)

            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.deepPlum)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
    .background(
        Color.salmon.opacity(isEnabled ? 1.0 : 0.4),
        in: Capsule()
    )
    .foregroundColor(
        Color.deepPlum.opacity(isEnabled ? 1.0 : 0.5)
    )
    .scaleEffect(isPressed ? 0.97 : 1.0)
    .animation(
        reduceMotion
            ? .easeInOut(duration: 0.1)
            : .spring(response: 0.3, dampingFraction: 0.6),
        value: isPressed
    )
    .disabled(!isEnabled || isLoading)
    .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
    .accessibilityLabel(title)
    .accessibilityAddTraits(.isButton)
}
```

**Key changes:**
- Remove `.adaptiveGlass(in: Capsule())` — buttons are content layer (opaque)
- Remove `.shadow(color: .brandBrightBlue...)` — no glow in brand bible
- Remove `.overlay { Capsule().stroke(.brandBrightBlue...) }` — no blue stroke
- Add `Color.salmon` background in Capsule
- Add `Color.deepPlum` foreground
- Add `@Environment(\.accessibilityReduceMotion)` check
- Scale: 0.97 (not 0.96)

### 3.2 SecondaryButton (NEW)

**File:** Create `Sources/Core/DesignSystem/Components/SecondaryButton.swift`

Brand bible defines a secondary button: Salmon stroke outline, clear fill, Salmon text.

```swift
public struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.salmon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(
            isPressed ? Color.salmon.opacity(0.15) : Color.clear,
            in: Capsule()
        )
        .overlay(Capsule().stroke(Color.salmon, lineWidth: 1))
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(
            reduceMotion
                ? .easeInOut(duration: 0.1)
                : .spring(response: 0.3, dampingFraction: 0.6),
            value: isPressed
        )
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}
```

### 3.3 ItemCard Restyling

**File:** `Sources/CollectionFeature/ItemCard.swift`

**Current:** Uses `.adaptiveGlass()` (glass material background)
**Target:** Opaque Cream background, Peach 1px border, DeepPlum text

The card must follow the Content Layer rules:
- Background: `Color.cream` in `RoundedRectangle(cornerRadius: 16, style: .continuous)`
- Border: `Color.peach` 1px stroke
- Title: `.headline` weight, `Color.deepPlum`
- Description: `.subheadline`, `Color.deepPlum.opacity(0.6)`
- Price: `.headline`, `Color.salmon`
- Pressed state: Background becomes `Color.peach`, `scaleEffect(0.98)`

### 3.4 AbundanceCard Container (NEW)

**File:** Create `Sources/Core/DesignSystem/Components/AbundanceCard.swift`

Reusable card container matching brand bible Section 5.2:

```swift
public struct AbundanceCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16

    @Environment(\.colorSchemeContrast) private var contrast

    public init(
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(12)
            .background(
                Color.cream,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        Color.peach,
                        lineWidth: contrast == .increased ? 2 : 1
                    )
            )
    }
}
```

### 3.5 Toast/Snackbar Styles

Brand bible defines:
- Success: MutedSage capsule, DeepPlum text, checkmark icon
- Error: Salmon capsule, DeepPlum text, warning icon

These don't exist in the codebase yet. Create when toast functionality is needed.

---

## 4. Animation Alignment

### 4.1 Current State

`Sources/Core/DesignSystem/Extensions/Animation+Brand.swift` defines:

| Current | Response | Damping | Brand Bible Equivalent |
|---------|----------|---------|----------------------|
| `brandSnappy` | 0.3 | 0.6 | Button press (matches) |
| `brandDefault` | 0.4 | 0.7 | *(no equivalent)* |
| `brandBouncy` | 0.5 | 0.5 | *(close to success: 0.5/0.6)* |
| `brandGentle` | 0.6 | 0.8 | *(no equivalent)* |

### 4.2 Target State

```swift
public extension Animation {
    /// Default brand animation (most transitions)
    /// Brand Bible: .spring(response: 0.5, dampingFraction: 0.6)
    static let brandDefault = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Button press animation
    /// Brand Bible: .spring(response: 0.3, dampingFraction: 0.6)
    static let brandPress = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Reduce Motion fallback
    /// Brand Bible: .easeInOut(duration: 0.2)
    static let brandReducedMotion = Animation.easeInOut(duration: 0.2)
}
```

**Changes:** Rename `brandSnappy` to `brandPress`, update `brandDefault` to
match brand bible values (0.5/0.6 instead of 0.4/0.7), remove `brandBouncy`
and `brandGentle` (YAGNI — not specified in brand bible).

---

## 5. Accessibility Implementation

### 5.1 Current State

- `reduceTransparency` is checked in: DetectionResultsView, CaptureOverlays,
  LiquidGlassHelpers (AdaptiveGlassModifier)
- `reduceMotion` is checked in: CaptureOverlays (AnalyzingOverlay)
- `colorSchemeContrast` is NOT checked anywhere
- `dynamicTypeSize` is NOT checked for layout reflow

### 5.2 Required Changes

**Every view that uses brand colors or animation must check:**

```swift
@Environment(\.accessibilityReduceTransparency) private var reduceTransparency
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@Environment(\.colorSchemeContrast) private var contrast
```

**Increase Contrast rules (not yet implemented):**
- `Color.deepPlum` → `Color.ultraDarkPlum` when `contrast == .increased`
- Border widths: 1px → 2px when `contrast == .increased`
- `Color.salmon` → darkened `#C0705A` when `contrast == .increased`

**Files requiring Increase Contrast support:**
- `PrimaryButton.swift` — darken salmon, use ultraDarkPlum text
- `ItemCard.swift` — 2px border, darker colors
- `ItemDetailView.swift` — darker text
- Any view using brand colors for interactive elements

### 5.3 Accessibility Color Extension

**File:** Add to `Color+Brand.swift`

```swift
// MARK: - Increase Contrast Variants
static let salmonHighContrast = Color(hex: "C0705A")
static let deepPlumHighContrast = Color.ultraDarkPlum
```

---

## 6. Asset Catalog (Future Task)

The brand bible specifies 15+ color sets in an xcassets catalog with light/dark
mode variants. This is deferred because:

1. The app currently uses an SPM package structure without an xcassets bundle
2. Color+Brand.swift with hex values works for MVP
3. Dark mode design is explicitly noted as "requires design validation"

**When to implement:** When dark mode support is prioritized. Track in a
separate issue/spec.

---

## 7. LiquidGlassHelpers.swift Updates

### 7.1 Changes

The `AdaptiveGlassModifier` currently falls back to `Color.backgroundDefault`
(wrong hex `#FCFCFF`) for Reduce Transparency. Update to use `Color.cream`
or `Color.warmWhite` per brand bible:

- Navigation glass fallback: `Color.cream` (brand bible Section 2.5)
- Content containers: Already opaque after migration (no glass to fall back from)

### 7.2 Cleanup

After content-layer elements are migrated to opaque fills, `AdaptiveGlassModifier`
is only needed for navigation-layer elements. Content components should NOT
use `.adaptiveGlass()` — they should use `AbundanceCard` or direct opaque fills.

Remove any `.adaptiveGlass()` calls on content-layer views (cards, buttons,
text fields) during the component migration.

---

## 8. Testing Requirements

### 8.1 Visual Regression

For each restyled component, verify in Xcode Preview:
- Default state matches brand bible specification
- Pressed/focused state matches brand bible specification
- Reduce Transparency: glass → opaque fallback works
- Reduce Motion: spring → easeInOut fallback works
- Increase Contrast: colors darken, borders thicken
- Dynamic Type at AX3: layout doesn't break

### 8.2 Automated Tests

Add unit tests for Color+Brand.swift to verify hex values match brand bible:

```swift
func testSalmonColor() {
    let salmon = Color.salmon
    // Verify components match #E8907A
}
```

Add snapshot tests for PrimaryButton, SecondaryButton, and AbundanceCard
in all accessibility states if snapshot testing is set up.

---

## 9. Implementation Order

1. **Color+Brand.swift** — Replace palette (everything depends on this)
2. **Animation+Brand.swift** — Update presets
3. **PrimaryButton.swift** — Restyle to opaque Salmon
4. **Create SecondaryButton.swift** — New component
5. **Create AbundanceCard.swift** — New container
6. **ItemCard.swift** — Migrate from glass to opaque Cream/Peach
7. **Remaining views** — Update color references across all features
8. **Accessibility** — Add Increase Contrast support
9. **LiquidGlassHelpers.swift** — Clean up, update fallback colors
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-UI-003-design-system.md
git commit -m "docs(spec): add SPEC-UI-003 design system implementation spec"
```

---

## Phase 3: Liquid Glass Adoption Spec

### Task 3: Create SPEC-UI-004 — Liquid Glass Navigation Adoption

**Files:**
- Create: `docs/specs/SPEC-UI-004-liquid-glass-adoption.md`

**Step 1: Write the spec**

```markdown
# SPEC-UI-004: Liquid Glass Navigation Adoption

**Status:** Draft
**Created:** 2026-02-06
**References:** Brand Bible v3.0 (Section 1.7 Two-Layer Strategy),
               axiom-liquid-glass-ref, axiom-swiftui-26-ref
**Code Refs:** App/AbundanceApp.swift, Sources/CollectionFeature/,
              Sources/CameraFeature/, Sources/Core/DesignSystem/

---

## 1. Overview

This spec defines the adoption of iOS 26 Liquid Glass for navigation-layer
elements in the Abundance app. It implements the Two-Layer Strategy from the
brand bible: Navigation Layer = Liquid Glass, Content Layer = Opaque Brand Fills.

**Scope:** Tab bar, navigation bars, search bar, modals/sheets, toolbar items.
Content-layer components are covered in SPEC-UI-003.

**Prerequisite:** SPEC-UI-003 must be completed first (color palette migration).

---

## 2. Tab Bar

### 2.1 Current State

`App/DebugMainTabView.swift` uses a basic `TabView` with 3 tabs and a custom
`FloatingTabBar` component in `Sources/CollectionFeature/Components/FloatingTabBar.swift`.

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

**Recommendation:** Remove `FloatingTabBar.swift` and use standard TabView.
iOS 26 tab bars are already floating capsule-shaped. Custom implementation
adds maintenance burden and may conflict with system Liquid Glass behavior.

---

## 3. Navigation Bar

### 3.1 Target State

All `NavigationStack` instances automatically get Liquid Glass navigation bars
when compiled with iOS 26 SDK. No code changes required.

**Brand rules:**
- Navigation bar title: System `.primary` vibrancy (auto on glass)
- Navigation bar background: `.glassEffect(.regular)` (automatic)
- Back button: System default
- Toolbar items: System Liquid Glass treatment

### 3.2 Audit Items

Remove any custom navigation bar backgrounds:
```swift
// ❌ REMOVE if found
.toolbarBackground(.visible, for: .navigationBar)
.toolbarBackground(Color.someColor, for: .navigationBar)
```

These will interfere with Liquid Glass.

---

## 4. Search Bar

### 4.1 Current State

`Sources/CollectionFeature/Components/SearchBar.swift` is a custom search
implementation.

### 4.2 Target State

**Option A (Recommended):** Use `.searchable(text:)` modifier on the list.
iOS 26 automatically provides a glass capsule search bar.

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
// ❌ REMOVE
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

If any custom floating UI elements need glass (e.g., floating action buttons,
custom overlays), wrap them in `GlassEffectContainer` for performance:

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
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-UI-004-liquid-glass-adoption.md
git commit -m "docs(spec): add SPEC-UI-004 Liquid Glass navigation adoption spec"
```

---

## Phase 4: Update Doc Index

### Task 4: Register New Documents

**Files:**
- Modify: `docs/.doc-index.json`

**Step 1: Add entries for new documents**

Add to the `specs.docs` section:

```json
"SPEC-UI-003-design-system.md": {
    "status": "Draft",
    "code_refs": [
        "Sources/Core/DesignSystem/",
        "Sources/CollectionFeature/",
        "Sources/CameraFeature/",
        "Sources/ProfileFeature/"
    ],
    "updated": "2026-02-06"
},
"SPEC-UI-004-liquid-glass-adoption.md": {
    "status": "Draft",
    "code_refs": [
        "App/",
        "Sources/Core/DesignSystem/",
        "Sources/CollectionFeature/Components/"
    ],
    "updated": "2026-02-06"
}
```

Add to a new `brand` directory entry (or note the brand bible location):

The brand bible lives in `docs/brand/` which is not currently tracked in the
doc index. Either add a `brand` directory entry or note that brand bibles
are tracked separately.

**Step 2: Commit**

```bash
git add docs/.doc-index.json
git commit -m "docs: register SPEC-UI-003, SPEC-UI-004 in doc index"
```

---

## Summary of Deliverables

| Document | Purpose | Location |
|----------|---------|----------|
| **Brand Bible v3.0** | Design system source of truth (no AI content) | `docs/brand/abundance-brand-bible-v3-2026-02-06.md` |
| **SPEC-UI-003** | Design system implementation spec (colors, components, accessibility) | `docs/specs/SPEC-UI-003-design-system.md` |
| **SPEC-UI-004** | Liquid Glass navigation adoption spec | `docs/specs/SPEC-UI-004-liquid-glass-adoption.md` |

### Dependency Graph

```
Brand Bible v3.0 (reference document)
    ↓
SPEC-UI-003 (content layer: colors, cards, buttons, text)
    ↓
SPEC-UI-004 (navigation layer: tab bar, nav bar, search, sheets)
    ↓
Implementation (code changes tracked per spec)
```

SPEC-UI-003 must be implemented before SPEC-UI-004 because the navigation
layer's warm-tinted glass effect depends on the content layer having the
correct opaque warm backgrounds beneath it.

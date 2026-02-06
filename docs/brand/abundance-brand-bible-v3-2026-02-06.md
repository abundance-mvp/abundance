# Abundance Brand Bible & Design System v3.0

> **Target:** iOS 26 / iPadOS 26 / macOS 26 with Liquid Glass
> **Supersedes:** v2.0 (February 2026 "on-device" edition). Removes on-device AI
>   content (now covered by SPEC-PIPE-* specs). Aligns with current codebase.
> **Last Updated:** February 2026

---

## How to Use This Document

This document is the **single source of truth** for the Abundance visual identity and design system. It defines:

1. **Brand Identity** (Part I) — Colors, materials, mood, app icon
2. **Design System Specifications** (Part II) — Shapes, layout, typography, components, accessibility
3. **Core UX Flows** (Part III) — Splash, onboarding, navigation, scanner, catalog
4. **Implementation Reference** (Part IV) — SwiftUI blueprints, asset catalog, performance

**For implementation details, see:**
- **SPEC-UI-003** — Design system implementation (color migration, component restyling)
- **SPEC-UI-004** — Liquid Glass navigation adoption (tab bar, nav bar, sheets)

**For AI pipeline architecture, see:**
- SPEC-PIPE-001 (Layer 1 Detection), SPEC-PIPE-002 (Layer 2 Cataloging), SPEC-PIPE-003 (Session Persistence)

---

## Part I: Brand Identity

### 1.1 Aesthetic Classification

Abundance occupies a unique aesthetic intersection: **claymorphism meets retro-futurism meets Liquid Glass**.

The brand's visual DNA draws from:
- **Claymorphism:** Soft, rounded forms with subtle depth — the "friendly premium" feel
- **Retro-futurism:** 1980s advertising mood, warm color palette, nostalgic optimism
- **Liquid Glass:** Apple's iOS 26 design language — translucent, refractive, layered

The synthesis: UI elements feel like carefully crafted objects made from warm-tinted glass, floating above rich, textured backgrounds. The brand is **playful, stylish, premium, and approachable**.

### 1.2 Color Palette

The Abundance palette is warm, inviting, and deliberately muted compared to typical "vaporwave" palettes. Every color has a functional role.

#### Primary Brand Colors

| Name | Hex | Role | Usage |
|------|-----|------|-------|
| **Salmon** | `#E8907A` | Primary accent | Buttons, CTAs, active states, price highlights |
| **Peach** | `#EDBE9E` | Secondary accent | Card borders, hover states, secondary elements |
| **Cream** | `#F0DCC0` | Content surface | Card backgrounds, content containers |
| **Soft Teal** | `#8ECAC0` | Complementary accent | Category highlights, decorative elements |
| **Muted Sage** | `#9DC4A8` | Success | Success toasts, validation feedback |

#### Text Colors

| Name | Hex | Contrast vs White | Usage |
|------|-----|-------------------|-------|
| **DeepPlum** | `#3B2E3A` | 12.52:1 (AAA) | All body text, headlines, primary labels |
| **DarkPlum** | `#2D2226` | 14.8:1 (AAA) | High-emphasis text, large titles |
| **UltraDarkPlum** | `#1A1218` | 17.4:1 (AAA) | Increase Contrast mode text |

#### Background Colors

| Name | Hex | Usage |
|------|-----|-------|
| **BackgroundTeal** | `#5BB8C9` | Splash/onboarding gradient base |
| **WarmWhite** | `#FAF6F0` | Screen backgrounds, sheet content areas |

#### Behind-Glass Pre-Saturated Variants

When colors appear beneath Liquid Glass, the glass desaturates them. These pre-saturated variants compensate, ensuring the intended color shows through the glass layer.

| Name | Hex | Compensates For |
|------|-----|-----------------|
| **SalmonBehindGlass** | `#E87A60` | Salmon through glass |
| **PeachBehindGlass** | `#EDB085` | Peach through glass |
| **TealBehindGlass** | `#7AC4B8` | Soft Teal through glass |

#### Increase Contrast Variants

Used when `colorSchemeContrast == .increased` to ensure stronger visual definition.

| Name | Hex | Replaces |
|------|-----|----------|
| **SalmonHighContrast** | `#C0705A` | Salmon (interactive elements) |
| **DeepPlumHighContrast** | `#1A1218` | DeepPlum (text) |

> **Current Implementation Status:** `Sources/Core/DesignSystem/Extensions/Color+Brand.swift` uses a different color palette from a prior design iteration (blue-based: `#4381DF`, `#FF9A6F`, etc.). Migration to the brand bible palette is tracked in SPEC-UI-003 Section 2.

### 1.3 Material Language

Abundance uses a **two-material vocabulary**:

1. **Liquid Glass** (navigation layer) — Tab bars, navigation bars, search bars, toolbars. These use iOS 26 `.glassEffect()` which provides translucency, refraction, and dynamic adaptation.

2. **Opaque Brand Fills** (content layer) — Cards, buttons, text fields, content containers. These use solid brand colors (Cream, Salmon, WarmWhite) to create warmth and legibility.

The key insight: **glass is for chrome, not content**. Navigation elements get the refractive glass treatment. Content elements get warm, opaque brand fills that create the rich background visible through the glass above.

### 1.4 Lighting Model

The Abundance lighting model creates warmth and depth:

- **Warm ambient light:** The Cream/Peach palette creates a warm undertone visible through glass elements
- **Subtle top-left light source:** Consistent with iOS shadow conventions
- **No neon glow effects:** The prior blue glow (`#4381DF` underglow) is removed in v3.0. Depth is communicated through layering and subtle shadows, not colored glows.

### 1.5 Brand Mood

**Four pillars define the Abundance mood:**

| Pillar | Expression |
|--------|-----------|
| **Playful** | Bouncy spring animations, friendly rounded shapes, warm colors |
| **Stylish** | Smooth 60fps transitions, careful typography, consistent spacing |
| **Premium** | Quality materials (glass + opaque), attention to detail, subtle depth |
| **Approachable** | Warm palette, clear hierarchy, accessible by default, forgiving interactions |

### 1.6 App Icon Specification

The Abundance app icon is a multi-layered composition created with Apple's Icon Composer:

- **Concept:** A miniature display case / cabinet of curiosities
- **Layers:** Background gradient (warm), midground shelf/case, foreground floating inventory items
- **Color:** Warm teal-to-cream gradient with Salmon accent lighting
- **Style:** 3D rendered, claymorphic objects with subtle glass refraction on the case
- **Treatment:** Designed to work with iOS 26 icon tinting and Liquid Glass icon effects

The icon communicates the core promise: **your beautiful collection, organized and displayed**.

### 1.7 The Two-Layer Strategy

The Two-Layer Strategy is the architectural principle governing where glass and opaque treatments are applied:

```
┌──────────────────────────────────────────────┐
│  NAVIGATION LAYER (Liquid Glass)             │
│  Tab bar, nav bar, search, toolbars          │
│  → .glassEffect(.regular)                    │
│  → Tinted with .salmon for active states     │
│  → System manages translucency               │
├──────────────────────────────────────────────┤
│  CONTENT LAYER (Opaque Brand Fills)          │
│  Cards, buttons, text, images, forms         │
│  → Color.cream backgrounds                   │
│  → Color.salmon button fills                 │
│  → Color.deepPlum text                       │
│  → Warm, legible, brand-consistent           │
└──────────────────────────────────────────────┘
```

**Rule:** Navigation-layer elements use Liquid Glass. Content-layer elements use opaque brand fills. Never apply glass to content-layer elements (cards, buttons, text fields).

**Why:** The warm opaque content creates the rich background that makes the glass navigation layer look beautiful. Glass on glass creates visual noise. Opaque content ensures legibility without accessibility workarounds.

> **Current Implementation Note:** The codebase currently uses glass effects on content-layer elements (cards use `.adaptiveGlass()`, buttons use glass with blue glow). SPEC-UI-003 defines the migration to opaque content-layer fills. SPEC-UI-004 defines the Liquid Glass navigation adoption.

---

## Part II: Design System Specifications

### 2.1 Shape System

Abundance follows the iOS 26 shape system with three primary shape types:

| Shape Type | Corner Radius | Usage |
|-----------|--------------|-------|
| **Capsule** | height/2 (automatic) | Primary buttons, pills, tags, tab bar items |
| **Concentric Rounded Rectangle** | Parent radius - padding | Cards, containers, grouped content |
| **Fixed Rounded Rectangle** | 16pt (default) | Cards, sheets, modals |

**Concentricity rule:** Nested elements subtract their padding from the parent's corner radius. A card with 16pt radius containing a 12pt-padded inner element uses 16 - 12 = 4pt inner radius.

**Style:** Always use `.continuous` corner style for smooth, superelliptical corners:
```swift
RoundedRectangle(cornerRadius: 16, style: .continuous)
```

### 2.2 Layout Rules

| Property | Value | Notes |
|----------|-------|-------|
| **Screen padding** | 16pt horizontal | Standard content inset |
| **Card padding** | 12pt | Inner content padding |
| **Card spacing** | 12pt | Between cards in a grid/list |
| **Section spacing** | 24pt | Between major content sections |
| **Minimum tap target** | 44x44pt | iOS HIG requirement |
| **Grid columns** | 2 (iPhone), 3-4 (iPad) | Adaptive grid |

### 2.3 Typography

Abundance uses the system font (San Francisco) with rounded design for a friendly feel:

| Style | Font | Weight | Size | Usage |
|-------|------|--------|------|-------|
| **Large Title** | `.largeTitle, .rounded` | Bold | 34pt | Screen titles |
| **Title** | `.title2, .rounded` | Semibold | 22pt | Section headers |
| **Headline** | `.headline, .rounded` | Semibold | 17pt | Card titles, button text |
| **Body** | `.body` | Regular | 17pt | Descriptions, body text |
| **Subheadline** | `.subheadline` | Regular | 15pt | Secondary text, metadata |
| **Caption** | `.caption` | Regular | 12pt | Timestamps, small labels |

**Color rules:**
- Primary text: `Color.deepPlum`
- Secondary text: `Color.deepPlum.opacity(0.6)`
- Price/value text: `Color.salmon` (headline weight)
- On dark backgrounds (camera): `.white`

### 2.4 Component State & Material Matrix

| Component | State | Background | Text Color | Border | Animation |
|-----------|-------|-----------|------------|--------|-----------|
| **PrimaryButton** | Default | `Color.salmon` (Capsule) | `Color.deepPlum` | None | — |
| | Pressed | `Color.salmon` (Capsule) | `Color.deepPlum` | None | scale(0.97), brandPress |
| | Disabled | `Color.salmon.opacity(0.4)` | `Color.deepPlum.opacity(0.5)` | None | — |
| | Loading | `Color.salmon` (Capsule) | Hidden (spinner) | None | — |
| **SecondaryButton** | Default | Clear (Capsule) | `Color.salmon` | `Color.salmon` 1px | — |
| | Pressed | `Color.salmon.opacity(0.15)` | `Color.salmon` | `Color.salmon` 1px | scale(0.97), brandPress |
| **ItemCard** | Default | `Color.cream` (RoundedRect 16) | `Color.deepPlum` | `Color.peach` 1px | — |
| | Pressed | `Color.peach` (RoundedRect 16) | `Color.deepPlum` | `Color.peach` 1px | scale(0.98) |
| **Toast (Success)** | Shown | `Color.mutedSage` (Capsule) | `Color.deepPlum` | None | slide + fade |
| **Toast (Error)** | Shown | `Color.salmon` (Capsule) | `Color.deepPlum` | None | slide + fade |
| **Tab Bar** | — | Liquid Glass (system) | System vibrancy | — | System |
| | Active tab | — | `Color.salmon` tint | — | System |
| **Navigation Bar** | — | Liquid Glass (system) | System vibrancy | — | System |

> **Current State:** The codebase uses glass backgrounds and blue accents for PrimaryButton and ItemCard. See SPEC-UI-003 for the migration plan for each component.

### 2.5 Mandatory Accessibility Fallback States

These accessibility accommodations are **non-negotiable requirements**, not optional enhancements.

#### Reduce Transparency (`accessibilityReduceTransparency`)
When enabled, all Liquid Glass effects are replaced with opaque brand fills:
- Navigation glass → `Color.cream` opaque background
- Any remaining glass surfaces → `Color.warmWhite` opaque

#### Reduce Motion (`accessibilityReduceMotion`)
When enabled, all spring/bouncy animations are replaced:
- Spring animations → `.easeInOut(duration: 0.2)`
- Scale effects → instant (no animation)
- Parallax effects → disabled
- Confetti/particle effects → simple fade

#### Increase Contrast (`colorSchemeContrast == .increased`)
When enabled, visual weight is increased:
- `Color.deepPlum` → `Color.ultraDarkPlum` for text
- `Color.salmon` → `Color.salmonHighContrast` for interactive elements
- Border widths: 1px → 2px
- Background contrast increased

#### Dynamic Type
All text must support Dynamic Type up to AX5:
- Layouts reflow from horizontal to vertical at AX1+
- Images scale proportionally
- Minimum tap targets maintained at all sizes
- No text truncation — use `ScrollView` for overflow

**Implementation pattern:**
```swift
@Environment(\.accessibilityReduceTransparency) private var reduceTransparency
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@Environment(\.colorSchemeContrast) private var contrast
@Environment(\.dynamicTypeSize) private var dynamicTypeSize
```

---

## Part III: Core UX Flows

### 3.1 Splash Screen

- **Background:** Warm gradient (BackgroundTeal to WarmWhite)
- **Foreground:** "Abundance" logotype, brand icon
- **Animation:** Gentle fade-in, no complex motion (respects Reduce Motion)
- **Duration:** Matches system launch time, no artificial delay

### 3.2 Onboarding

The onboarding flow introduces the brand's personality:

1. **Welcome Screen:** Hero illustration with floating inventory items, warm background. Bold, left-aligned headline. "Get Started" primary button (Salmon capsule).
2. **Camera Permission:** Friendly explanation with 3D camera icon. Non-threatening copy. Grant/Skip options.
3. **First Scan Guide:** Visual tutorial showing capture gesture. Animated hand with item.

**Style:** Warm backgrounds, large friendly illustrations, clear typography, strong CTAs.

### 3.3 Navigation

The app uses a standard iOS tab bar with the following structure:

| Tab | Icon (SF Symbol) | Label |
|-----|------------------|-------|
| Catalog | `square.grid.2x2` | Catalog |
| Scan | `camera` | Scan |
| Profile | `person` | Profile |

**Navigation rules:**
- Tab bar uses system Liquid Glass (iOS 26 automatic)
- Active tab tinted `Color.salmon`
- Each tab contains a `NavigationStack` for push navigation
- Navigation bars use system Liquid Glass (no custom backgrounds)

> **Current State:** The app has 3 tabs (Inventory, Camera, Profile) in `DebugMainTabView.swift`. The brand bible target is Catalog, Scan, Profile — labels may be updated when feature naming is finalized. Share and Trade tabs are future features.

### 3.4 Scanner

#### Viewfinder
- **Overlay:** Soft corner brackets (not chrome), subtle scanning grid animation
- **Status indicators:** Glass-style floating pills showing detection state
- **Capture button:** Large, centered, with haptic feedback

#### Recognition Pipeline
Object detection and cataloging are handled server-side via the AI pipeline. See SPEC-PIPE-001 (Layer 1 detection) and SPEC-PIPE-002 (Layer 2 cataloging) for implementation details. The scanner UI captures photos and uploads them for server processing per SPEC-UI-001.

#### Success State
- Item highlighted with branded frame
- Celebratory animation (confetti in brand colors, respects Reduce Motion)
- "Add to Catalog" CTA in Salmon capsule

#### Error State
- Friendly illustration (soft pulsing question mark)
- Encouraging copy ("Try again" / "Adjust angle")
- Retry button in Salmon capsule

### 3.5 Catalog

#### Item Card Grid
- 2-column adaptive grid (iPhone), 3-4 columns (iPad)
- Cards use `AbundanceCard` container (Cream background, Peach border)
- Item image (top), title (headline, DeepPlum), description (subheadline, muted), price (Salmon)
- Long-press for context menu (Edit, Share, Delete)

#### Empty State
- Warm illustration of empty display cases
- Inviting copy ("Start scanning to build your collection")
- Prominent "Scan First Item" CTA in Salmon capsule
- Floating plus icons as visual encouragement

---

## Part IV: Implementation Reference

*Renumbered from Part V in v2.0. Part IV (On-Device Intelligence) from v2.0 has been removed from the brand bible. AI pipeline architecture is documented in:*
- *SPEC-PIPE-001: Layer 1 Detection (Gemini Flash)*
- *SPEC-PIPE-002: Layer 2 Cataloging (Gemini Pro)*
- *SPEC-PIPE-003: Session Persistence*
- *SPEC-ARCH-002: Layer 1/Layer 2 Pipeline Architecture*

*On-device Foundation Models integration is a future capability tracked separately from the design system.*

### 4.1 SwiftUI Environment Variables

Every view that uses brand styling must observe these environment values:

```swift
// Accessibility
@Environment(\.accessibilityReduceTransparency) private var reduceTransparency
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@Environment(\.colorSchemeContrast) private var contrast
@Environment(\.dynamicTypeSize) private var dynamicTypeSize

// Layout
@Environment(\.horizontalSizeClass) private var sizeClass
```

### 4.2 SwiftUI Implementation Blueprints

#### Brand Card (Content Layer)
```swift
AbundanceCard {
    VStack(alignment: .leading, spacing: 8) {
        Text("Item Title")
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundColor(.deepPlum)
        Text("Description text")
            .font(.subheadline)
            .foregroundColor(.deepPlum.opacity(0.6))
    }
}
```
**Status:** `AbundanceCard` component needs to be created. See SPEC-UI-003 Section 3.4.

#### Primary Button (Content Layer)
```swift
PrimaryButton(title: "Get Started", action: { })
```
**Status:** Exists but needs restyling from glass+blue to opaque Salmon. See SPEC-UI-003 Section 3.1.

#### Tab Bar (Navigation Layer)
```swift
TabView {
    CatalogView()
        .tabItem { Label("Catalog", systemImage: "square.grid.2x2") }
    ScanView()
        .tabItem { Label("Scan", systemImage: "camera") }
    ProfileView()
        .tabItem { Label("Profile", systemImage: "person") }
}
.tint(Color.salmon)
```
**Status:** Tab bar implementation needs Salmon tint. See SPEC-UI-004 Section 2.

### 4.3 Asset Catalog Setup

The brand bible specifies color sets in an xcassets catalog for each brand color, with light and dark mode variants.

**Specified color sets:**
- Salmon, Peach, Cream, SoftTeal, MutedSage
- DeepPlum, DarkPlum, UltraDarkPlum
- BackgroundTeal, WarmWhite
- SalmonBehindGlass, PeachBehindGlass, TealBehindGlass
- SalmonHighContrast

> **Note:** xcassets color sets do not yet exist. The app uses `Color+Brand.swift` with hex initializers, which works for MVP. Asset catalog implementation is tracked in SPEC-UI-003 Section 6 and deferred until dark mode support is prioritized.

### 4.4 Performance Rules

- **Profile with Instruments:** Monitor GPU usage during scrolling and animations
- **Materials are expensive:** Avoid deep stacks of multiple glass layers
- **Use `GlassEffectContainer`:** When multiple glass elements are siblings, wrap in a container for batched rendering
- **Test on target hardware:** Validate on iPhone 15 (baseline) through current devices
- **Lazy loading:** Use `LazyVGrid` / `LazyVStack` for content lists

### 4.5 Cross-Platform Behavior

The design system is built with SwiftUI for cross-platform consistency:

| Platform | Adaptation |
|----------|-----------|
| **iPhone** | 2-column grid, tab bar at bottom, compact layout |
| **iPad** | 3-4 column grid, sidebar navigation option, spacious layout |
| **macOS** | Window-based, sidebar navigation, keyboard shortcuts |

All three platforms share the same color palette, typography scale, component library, and animation presets. Layout adapts via `horizontalSizeClass` and `containerSize`.

---

## Appendix A: WWDC25 Session Index

| Session | Title | Relevance |
|---------|-------|-----------|
| 356 | Get to know the new design system | Shape system, concentricity, layout |
| 357 | Applying Liquid Glass | `.glassEffect()` API, tinting, containers |
| 269 | What's new in SwiftUI | iOS 26 view APIs, scroll effects |
| 251 | Elevate your tab and sidebar experience | TabView updates, minimization |
| 228 | Build a SwiftUI app with the new design | End-to-end Liquid Glass app |

## Appendix B: Documentation URLs

| Resource | URL |
|----------|-----|
| Liquid Glass HIG | developer.apple.com/design/human-interface-guidelines/liquid-glass |
| Materials HIG | developer.apple.com/design/human-interface-guidelines/materials |
| SwiftUI Glass Effect | developer.apple.com/documentation/swiftui/view/glasseffect |
| Color HIG | developer.apple.com/design/human-interface-guidelines/color |

## Appendix C: Quick Decision Reference

| Question | Answer |
|----------|--------|
| Glass or opaque? | Navigation = glass, Content = opaque |
| Which accent color? | Salmon `#E8907A` for primary actions |
| Which text color? | DeepPlum `#3B2E3A` for all text |
| Which card background? | Cream `#F0DCC0` |
| Which border color? | Peach `#EDBE9E` at 1px |
| Which animation? | `.spring(response: 0.5, dampingFraction: 0.6)` default |
| Button press animation? | `.spring(response: 0.3, dampingFraction: 0.6)` + scale(0.97) |
| Reduce Motion fallback? | `.easeInOut(duration: 0.2)` |
| Reduce Transparency fallback? | `Color.cream` opaque background |
| Increase Contrast? | Darken colors, thicken borders (2px) |
| Dark mode? | Deferred — requires design validation |
| Asset catalog? | Deferred — hex values in Color+Brand.swift for MVP |

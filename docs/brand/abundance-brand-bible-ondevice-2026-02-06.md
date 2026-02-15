# Abundance Brand Bible & Design System v2.0

> **Target:** iOS 26 / iPadOS 26 / macOS 26 with Liquid Glass
> **Supersedes:** June 2025 brand bible. All references to "retro-futuristic vaporwave," "chrome," "high-gloss," and "terrazzo" in prior documents are incorrect and replaced herein.
> **Last Updated:** February 2026

---

## How to Use This Document

This brand bible is structured for agent-driven development. Each section provides:

1. **Design rules** — what to do and what NOT to do
2. **Exact values** — hex colors, spacing, radius, font weights
3. **SwiftUI code** — copy-pasteable implementation patterns
4. **Decision logic** — if/then rules for choosing between options

When implementing any Abundance UI, check these sections in order:

1. [Color Palette](#12-color-palette) for exact hex values and asset names
2. [Two-Layer Strategy](#17-the-two-layer-strategy) to determine if the element belongs to content or navigation layer
3. [Component Matrix](#24-component-state--material-matrix) for the exact specification of each component
4. [Accessibility States](#25-mandatory-accessibility-fallback-states) for all three fallback modes
5. [SwiftUI Blueprints](#52-swiftui-implementation-blueprints) for implementation code

---

## Part I: Corrected Brand Identity

### 1.1 Aesthetic Classification

**The Abundance visual identity is claymorphism (soft 3D illustration).**

Claymorphism is a design trend where digital elements appear crafted from soft, pliable clay. Its five defining characteristics — all visible in the Abundance loading screen — are:

| Characteristic | Abundance Expression |
|---|---|
| **Matte/satin surfaces** | Zero specular highlights, zero chrome, zero metallic finishes anywhere |
| **Warm-to-cool pastel palette** | Salmon, peach, cream, soft teal, muted sage in split-complementary harmony |
| **Soft diffused ambient lighting** | No directional light, no hard shadows, no caustics. Ambient occlusion only |
| **Rounded 3D rendered elements** | Controllers, sneakers, bones, eggs, arrows, rings, squiggles, boxes, cylinders, donuts |
| **Toy-like tactility** | Objects feel like physical miniatures. Mood: playful, warm, approachable |

**Acceptable synonyms:** soft 3D illustration, clay-render aesthetic, toy-like miniature aesthetic.

**DO NOT use these terms anywhere:**
- ❌ "Vaporwave" or "retro-futuristic"
- ❌ "Chrome" or "metallic" or "high-gloss"
- ❌ "Neon" or "underglow"
- ❌ "1980s advertising"
- ❌ "Terrazzo"
- ❌ "Display case" (for the app icon)

### 1.2 Color Palette

#### Primary Brand Colors

| Name | Hex | Swift Asset | Role | Contrast vs DeepPlum |
|---|---|---|---|---|
| Salmon | `#E8907A` | `"Salmon"` | Primary warm accent, CTAs, active states | 5.31:1 AA ✓ |
| Peach | `#EDBE9E` | `"Peach"` | Secondary warm, card borders, hover states | 6.94:1 AA ✓ |
| Cream | `#F0DCC0` | `"Cream"` | Card backgrounds, reduce-transparency fallback | 9.59:1 AAA ✓ |
| Soft Teal | `#8ECAC0` | `"SoftTeal"` | Primary cool accent, backgrounds, balance | 6.01:1 AA ✓ |
| Muted Sage | `#9DC4A8` | `"MutedSage"` | Success states, secondary cool, categories | 5.89:1 AA ✓ |

#### Text Colors

| Name | Hex | Swift Asset | Use |
|---|---|---|---|
| Deep Plum | `#3B2E3A` | `"DeepPlum"` | **All primary text.** Passes WCAG AA on every palette color. |
| Dark Plum | `#2D2226` | `"DarkPlum"` | Increase Contrast accessibility fallback (~8.5:1 on teal) |
| Ultra-Dark Plum | `#1A1218` | `"UltraDarkPlum"` | Maximum contrast fallback for extreme accessibility |

#### Background & Environmental Colors

| Name | Hex | Swift Asset | Use |
|---|---|---|---|
| Background Teal | `#5BB8C9` | `"BackgroundTeal"` | App background, splash screen, loading screen |
| Warm White | `#FAF6F0` | `"WarmWhite"` | Content layer environmental background. Warmer than pure white. |

#### App Icon Colors (icon only — not for general UI)

| Name | Hex | Swift Asset | Use |
|---|---|---|---|
| Icon Gradient Top | `#E8A090` | `"IconGradientTop"` | Top stop of app icon gradient |
| Icon Gradient Bottom | `#A8D0C8` | `"IconGradientBottom"` | Bottom stop of app icon gradient |
| Letterform Cream | `#F0DCC0` | `"Letterform"` | App icon "A" letterform |

#### Behind-Glass Pre-Saturated Variants

Liquid Glass desaturates and cools colors beneath it. Use these pre-saturated variants for content that appears behind navigation glass so colors read correctly after glass processing.

| Standard | Behind-Glass Variant | Swift Asset | Saturation Boost |
|---|---|---|---|
| `#E8907A` Salmon | `#E87A60` | `"SalmonBehindGlass"` | +15% |
| `#EDBE9E` Peach | `#EDB085` | `"PeachBehindGlass"` | +12% |
| `#8ECAC0` Soft Teal | `#7AC4B8` | `"TealBehindGlass"` | +10% |

#### Color Rules

```
RULE: Never use white text on any Abundance brand color.
      White fails WCAG on every palette color (all ratios < 2.41:1).

RULE: Deep Plum #3B2E3A is the ONLY approved primary text color.

RULE: No pastel-on-pastel text combinations. Ever.

RULE: Salmon #E8907A is the ONLY approved accent/CTA color.

RULE: When in doubt about which background to use for content:
      → Cards and containers: Cream #F0DCC0
      → Full-screen content backgrounds: Warm White #FAF6F0
      → App-level background: Background Teal #5BB8C9 (splash only)
```

### 1.3 Material Language

The Abundance material language has four properties:

| Property | Specification | What It Is NOT |
|---|---|---|
| **Surface finish** | Matte to satin. Soft light absorption, minimal reflection. Slightly powdery, like lightly sanded modeling clay. | Not glossy, not chrome, not metallic, not reflective |
| **Shadow model** | Dual shadows: inner highlight + outer shadow. Ambient occlusion at contact points. Soft, diffused outer shadows. | Not hard-edged, not long cast shadows, not drop shadows |
| **Dimensionality** | Genuine 3D volume. Solid and holdable, not inflated. Proportional thickness. | Not paper-thin, not hollow, not inflated/balloon-like |
| **Color application** | Color IS the material (clay IS that color). Even distribution, no surface-coating gradients on individual objects. | Not painted-on, not gradient-washed, not textured |

### 1.4 Lighting Model

| Property | Specification |
|---|---|
| **Light type** | Diffused hemisphere/environment light. Like overcast daylight or large softbox studio setup. |
| **Direction** | No point lights, no directional spotlights. Light comes from everywhere equally. |
| **Shadows** | Soft, short, close to objects. Ambient occlusion darkens contact points. |
| **Highlights** | No specular highlights. At most, extremely subtle matte brightening on upward-facing surfaces. |
| **Color temperature** | Neutral to slightly warm. Does not shift objects toward blue or orange. |

### 1.5 Brand Mood

| Attribute | Expression | NOT This |
|---|---|---|
| Playful | Bouncy animations, toy-like objects, warm colors, rounded shapes | Not childish, not cartoonish |
| Warm | Salmon/peach palette, matte textures, soft lighting, cream backgrounds | Not hot/energetic, not red-dominant |
| Approachable | Soft edges, inviting empty states, friendly copy | Not patronizing, not dumbed-down |
| Premium | Consistent quality, careful composition, restrained palette | Not luxury/exclusive, not gold/black |
| Tactile | Objects feel holdable, clay surfaces, weight and dimension | Not flat, not literally textured UI |

**One-line summary:** "A premium toy store where every object is handcrafted from the same beautiful clay, lit by soft morning light."

### 1.6 App Icon Specification

Built with **Icon Composer** (Xcode 26+, WWDC25-361).

| Layer | Content | File Format |
|---|---|---|
| **Background** | Salmon-to-teal linear gradient (top `#E8A090` → bottom `#A8D0C8`). Flat, opaque. | PNG/SVG |
| **Foreground** | Simplified flat cream "A" letterform (`#F0DCC0`). No baked shadows or highlights. | PNG/SVG |
| **Midground** | Optional: subtle soft shadow for A depth. Test in all 6 appearance modes first. | PNG/SVG |

```
RULE: Keep source artwork flat, opaque, and simple.
      Icon Composer adds glass shimmer, specular highlights, and depth dynamically.
      DO NOT bake in embossing, shadows, gloss, or glass effects.
      The system generates these across all 6 appearance modes:
      Default, Dark, Clear Light, Clear Dark, Tinted Light, Tinted Dark.
```

### 1.7 The Two-Layer Strategy

**This is the foundational architecture for reconciling claymorphism with Liquid Glass.**

Apple's iOS 26 divides the interface into two explicit layers (WWDC25 Meet with Apple Session 208; confirmed by Crumbl, Lowe's, CardPointers case studies at `developer.apple.com/design/new-design-gallery/`):

```
┌─────────────────────────────────────────────┐
│  NAVIGATION LAYER (top)                     │
│  • Liquid Glass lives here                  │
│  • Tab bars, toolbars, nav bars             │
│  • System-managed — use .glassEffect()      │
│  • Warm content below tints glass naturally  │
├─────────────────────────────────────────────┤
│  CONTENT LAYER (bottom)                     │
│  • Abundance claymorphism identity here     │
│  • Opaque warm backgrounds                 │
│  • Matte 3D illustrations                  │
│  • Brand colors, Deep Plum text            │
│  • Fully opaque, fully branded             │
└─────────────────────────────────────────────┘
```

**Decision rule for every UI element:**

```
IF element is a system navigation control (tab bar, nav bar, toolbar, action sheet):
    → Navigation Layer → Use .glassEffect(.regular) → Let system handle
    → Abundance content below will naturally tint the glass warm

ELSE IF element is app content (cards, text, illustrations, buttons, inputs):
    → Content Layer → Use opaque brand fills (Cream, Warm White, Salmon)
    → Deep Plum text → No glass effects

ELSE IF element is a modal/overlay:
    → Partial height: .glassEffect(.regular) (system manages)
    → Full height: Transition to opaque Warm White
```

#### Translation Matrix

| Brand Attribute | iOS 26 Translation | Layer | SwiftUI |
|---|---|---|---|
| Matte clay surfaces | Opaque warm backgrounds; glass nav absorbs warmth | Content | `.background(Color("WarmWhite"))` |
| Warm pastels | Pre-saturated behind-glass variants; `.tint()` on selective CTAs | Both | `.glassEffect(.regular.tint(Color("Salmon").opacity(0.3)))` |
| Soft ambient lighting | System glass lighting for nav; content retains soft lighting in illustrations | Nav: System / Content: Brand | Default `.glassEffect()` behavior |
| 3D clay objects | Illustrations in onboarding, empty states, categories — content only | Content | Image assets, not UI components |
| Deep Plum text | Primary text on all surfaces; auto-vibrant on glass | Both | `.foregroundStyle(.primary)` on glass; `Color("DeepPlum")` on content |
| Salmon accent | CTA fills, tinted glass, interactive highlights | Both | `.tint(Color("Salmon"))` |
| Solid teal background | Environmental color tinting glass from below | Content | `.background(Color("BackgroundTeal"))` on root |

---

## Part II: Design System Specifications

### 2.1 Shape System

iOS 26 uses "quiet geometry" driven by concentricity (WWDC25-356).

| Shape Type | Radius Rule | Abundance Use | SwiftUI |
|---|---|---|---|
| **Capsule** | radius = height / 2 | Buttons, search bar, tab items, toggles, sliders | `Capsule()` |
| **Concentric** | radius = parent radius − padding | Item cards, category cards, modals, grouped lists | `ContainerRelativeShape` |
| **Fixed** | constant radius | Thumbnails, avatars, decorative elements | `RoundedRectangle(cornerRadius: N, style: .continuous)` |

```
RULE: Always use .continuous curve style. Never .circular.

RULE: Default corner radius for standalone cards: 16pt
RULE: Default corner radius for nested elements: parent radius - 8pt (padding)
RULE: Minimum touch target: 44x44pt
```

### 2.2 Layout Rules

| Rule | Value |
|---|---|
| Minimum card-to-card spacing | 16pt |
| Internal card padding | 12pt |
| Screen horizontal padding | 16pt |
| Section header bottom margin | 8pt |
| Grid columns (iPhone) | 2-column adaptive |
| Grid columns (iPad) | 3–4 column adaptive |
| Grid columns (Mac) | 4+ column, window-resizable |

### 2.3 Typography

Use system San Francisco via SwiftUI text styles. Apply brand color.

| Level | Style | Weight | Color | Use |
|---|---|---|---|---|
| Display | `.largeTitle` | Bold | `#3B2E3A` | Onboarding hero, splash |
| Title | `.title` | Semibold | `#3B2E3A` | Screen titles, section headers |
| Headline | `.headline` | Semibold | `#3B2E3A` | Card titles, list headers |
| Body | `.body` | Regular | `#3B2E3A` | Primary content, descriptions |
| Subheadline | `.subheadline` | Regular | `#3B2E3A` 60% opacity | Secondary info, metadata |
| Caption | `.caption` | Regular | `#3B2E3A` 45% opacity | Tertiary metadata, legal |
| Price | `.headline` | Semibold | `#E8907A` (Salmon) | Price displays |

```
RULE: All text on material backgrounds must meet WCAG 2.2:
      → 4.5:1 for body text
      → 3:1 for large text (18pt+) and UI components

RULE: On glass surfaces → .foregroundStyle(.primary) (auto-adjusts)
RULE: On opaque content → Color("DeepPlum") #3B2E3A (passes AA everywhere)

RULE: Bold, left-aligned headings per iOS 26 typography refinements (WWDC25-356)
```

### 2.4 Component State & Material Matrix

This is the definitive specification for every component. **Liquid Glass governs navigation; opaque fills govern content.**

| Component | State | Shape | Surface | Foreground | Accent/Note |
|---|---|---|---|---|---|
| **Tab Bar** | Default | Capsule (system) | `.glassEffect(.regular)` | `.primary` / `.secondary` vibrancy | Salmon tint on active icon |
| **Tab Bar** | Minimized | Capsule (system) | `.glassEffect(.regular)` | `.primary` | Salmon dot indicator |
| **Nav Bar** | Default | System | `.glassEffect(.regular)` | `.primary` vibrancy | — |
| **Primary Button** | Default | Capsule | Opaque `#E8907A` Salmon | `#3B2E3A` DeepPlum | Solid fill, no glass |
| **Primary Button** | Pressed | Capsule | `#D6806A` (darkened Salmon) | `#3B2E3A` DeepPlum | `scaleEffect(0.97)` + spring |
| **Primary Button** | Disabled | Capsule | `#E8907A` 40% opacity | `#3B2E3A` 50% opacity | — |
| **Secondary Button** | Default | Capsule | 1px `#E8907A` Salmon stroke, clear fill | `#E8907A` Salmon | Outline style |
| **Secondary Button** | Pressed | Capsule | `#E8907A` 15% opacity fill | `#D6806A` | `scaleEffect(0.97)` |
| **Item Card** | Default | Concentric | Opaque `#F0DCC0` Cream | DeepPlum: title `.headline`, desc `.subheadline` 60% | 1px `#EDBE9E` Peach border |
| **Item Card** | Pressed | Concentric | Opaque `#EDBE9E` Peach | DeepPlum `.primary` | `scaleEffect(0.98)` |
| **Category Card** | Default | Concentric | Opaque `#FAF6F0` WarmWhite | DeepPlum `.primary` | Salmon left accent bar (4px) |
| **Modal Sheet** | Partial | Concentric | `.glassEffect(.regular)` (system) | `.primary` vibrancy | System managed |
| **Modal Sheet** | Full | Rectangle | Opaque `#FAF6F0` WarmWhite | DeepPlum | System transition from glass to opaque |
| **Search Bar** | Inactive | Capsule | `.glassEffect(.regular)` | `.secondary` vibrancy placeholder | — |
| **Search Bar** | Active | Capsule/Expanded | Opaque `#FAF6F0` WarmWhite | DeepPlum `.primary` | Salmon cursor/highlight |
| **Alert** | Active | Concentric | `.glassEffect(.regular)` (system) | `.primary` vibrancy | Salmon for destructive |
| **Text Field** | Default | Concentric | Opaque `#F0DCC0` Cream | DeepPlum | 1px `#EDBE9E` Peach border |
| **Text Field** | Focused | Concentric | Opaque `#F0DCC0` Cream | DeepPlum | 2px `#E8907A` Salmon border |
| **Empty State** | — | N/A | Content layer: 3D clay illustration | DeepPlum body text | Salmon CTA button |
| **Toast/Snackbar** | Success | Capsule | Opaque `#9DC4A8` MutedSage | DeepPlum | Checkmark icon |
| **Toast/Snackbar** | Error | Capsule | Opaque `#E8907A` Salmon | DeepPlum | Warning icon |

### 2.5 Mandatory Accessibility Fallback States

These are NOT optional. They are core design states.

#### Reduce Transparency

**Detection:** `@Environment(\.accessibilityReduceTransparency) var reduceTransparency`

**Behavior:** All glass becomes frostier (auto for system components). For custom elements:

| Component | Default | Reduce Transparency Fallback |
|---|---|---|
| Tab Bar | `.glassEffect(.regular)` | Opaque `#F0DCC0` Cream fill |
| Nav Bar | `.glassEffect(.regular)` | Opaque `#FAF6F0` WarmWhite fill |
| Modal (partial) | `.glassEffect(.regular)` | Opaque `#FAF6F0` WarmWhite fill |
| Custom glass | `.glassEffect(.regular)` | `.glassEffect(.identity)` + opaque brand fill |
| Search bar | `.glassEffect(.regular)` | Opaque `#F0DCC0` Cream fill |

```swift
.glassEffect(reduceTransparency ? .identity : .regular)
.background(reduceTransparency ? Color("Cream") : .clear)
```

> **Note:** Reduce Transparency mode makes the app MORE aligned with its claymorphism identity. Design it as a first-class experience.

#### Reduce Motion

**Detection:** `@Environment(\.accessibilityReduceMotion) var reduceMotion`

| Default | Reduce Motion Fallback |
|---|---|
| `.spring(response: 0.5, dampingFraction: 0.6)` | `.easeInOut(duration: 0.2)` |
| Bouncy confetti celebration | Simple checkmark with fade-in |
| Parallax/lensing effects | Disabled |
| `.glassEffect(.regular.interactive())` | `.glassEffect(.regular)` (no interactive) |
| Scroll-based tab bar minimize | Instant transition, no animation |

```swift
withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.6)) {
    // state change
}
```

#### Increase Contrast

**Detection:** `@Environment(\.colorSchemeContrast) var contrast`

| Default | Increase Contrast Fallback |
|---|---|
| DeepPlum `#3B2E3A` text | UltraDarkPlum `#1A1218` text |
| 1px borders | 2px borders with higher contrast |
| Salmon accent | Darkened Salmon `#C0705A` |
| Standard palette | All colors darkened ~15% |

```swift
.foregroundColor(contrast == .increased ? Color("UltraDarkPlum") : Color("DeepPlum"))
```

#### Dynamic Type

All layouts must accommodate up to AX5 (xxxLarge). Cards reflow to single-column at accessibility sizes. Truncation never hides critical information (prices, titles).

---

## Part III: Core UX Flows

### 3.1 Splash Screen

| Element | Specification |
|---|---|
| Background | Solid `#5BB8C9` BackgroundTeal. No pattern, no texture, no terrazzo. |
| Central element | App icon (gradient square with cream A) at 120pt, centered |
| Surrounding objects | Animated 3D clay objects in brand palette. Matte finish. Slow drift. |
| Logotype | "Abundance" in DeepPlum, `.title` weight, centered below icon |
| Reduce Motion | Static. No drift. Simple fade-in of icon and logotype. |

### 3.2 Onboarding

All screens use bold, left-aligned typography. Content layer has full-bleed 3D clay illustrations. Navigation is system Liquid Glass.

| Screen | Illustration | Text | CTA |
|---|---|---|---|
| Welcome | Clay scene of scattered collectibles | "Your collection, beautifully organized." | "Get Started" (Salmon capsule) |
| Scan | Clay camera/phone | "Point. Scan. Done." | "Scan Your First Item" (Salmon) |
| Organize | Clay grid of organized items | "Smart categories. Instant sorting." | "Continue" (Salmon) |
| Permissions | System permission dialogs | Camera, notifications | System concentric shapes |

### 3.3 Navigation

#### Floating Tab Bar (WWDC25-356)

```swift
TabView {
    CatalogView()
        .tabItem { Label("Catalog", systemImage: "square.grid.2x2") }
    ScannerView()
        .tabItem { Label("Scan", systemImage: "camera") }
    ShareView()
        .tabItem { Label("Share", systemImage: "square.and.arrow.up") }
    TradeView()
        .tabItem { Label("Trade", systemImage: "arrow.triangle.2.circlepath") }
    ProfileView()
        .tabItem { Label("Profile", systemImage: "person") }
}
.tint(Color("Salmon"))
.tabBarMinimizeBehavior(.onScrollDown)
```

- Material: `.glassEffect(.regular)` — system default
- 5 tabs: Catalog, Scan, Share, Trade, Profile
- Active icon: Salmon fill. Inactive: `.secondary` vibrancy
- Includes Search tab per iOS 26 standard
- Reduce Transparency: Opaque Cream fill, DeepPlum icons

#### Contextual Menus

Menus spring from source action (WWDC25-356). System Liquid Glass material.

- **Item card long-press:** Edit, Share, List for Sale, Delete. Anchored to touch point.
- **Toolbar overflow:** Morphs from overflow button. System behavior.

#### Search

- **Resting:** Glass capsule in tab bar (system Search tab)
- **Active:** Full-screen, Warm White background, DeepPlum text, Salmon cursor
- **Suggestions:** Concentric-shape pills animating in
- **Scroll-edge:** Soft style (default iOS, WWDC25-219). Never hard style on iOS.

### 3.4 Scanner

#### Viewfinder

| Element | Specification |
|---|---|
| Corner indicators | Rounded corner marks in Cream `#F0DCC0` at 60% opacity. Subtle pulse when active. |
| Detection feedback | Thin Salmon border around detected objects. Soft-edged. |
| Background | Raw camera feed, NO overlay tint. Scanner is utilitarian. |
| Reduce Motion | No pulse animation. Static corner marks. |

#### On-Device Recognition Pipeline

```
1. VNRecognizeTextRequest        → Read text (brand, model, title)
2. VNDetectBarcodesRequest       → QR codes, barcodes
3. Custom Core ML model          → Object type classification
4. DetectLensSmudgeRequest       → Camera quality check (iOS 26)
5. DetectDocumentSegmentationRequest → Receipt/warranty isolation (iOS 26)
```

All processing on-device. No cloud. No user data leaves the phone.

#### Success State

- Salmon border highlights item
- Clay confetti particles (small spheres/squiggles in brand palette) burst and settle
- Animation: `.spring(response: 0.5, dampingFraction: 0.6)`
- Reduce Motion: Simple checkmark icon with `.easeInOut` fade-in

#### Error State

- Soft pulsating Cream question mark icon
- Text: "We couldn't quite catch that. Try again?"
- Salmon "Retry" button
- No jarring red. No aggressive error styling.

### 3.5 Catalog

#### Item Cards

```swift
struct ItemCard: View {
    let item: CatalogItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image
            AsyncImage(url: item.imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color("Cream")
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Title
            Text(item.title)
                .font(.headline)
                .foregroundColor(Color("DeepPlum"))
            
            // Description
            Text(item.description)
                .font(.subheadline)
                .foregroundColor(Color("DeepPlum").opacity(0.6))
                .lineLimit(2)
            
            // Price
            Text(item.formattedPrice)
                .font(.headline)
                .foregroundColor(Color("Salmon"))
        }
        .padding(12)
        .background(
            Color("Cream"),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color("Peach"), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.category), valued at \(item.formattedPrice)")
    }
}
```

#### Grid Layout

```swift
ScrollView {
    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 160), spacing: 16)],
        spacing: 16
    ) {
        ForEach(items) { item in
            ItemCard(item: item)
        }
    }
    .padding(.horizontal, 16)
}
.scrollEdgeEffectStyle(.soft, for: .top)
.scrollEdgeEffectStyle(.soft, for: .bottom)
```

#### Empty States (Content Layer — fully branded)

| State | Illustration | Text | CTA |
|---|---|---|---|
| New user | Clay display shelves + floating plus icons in SoftTeal glow | "Your collection starts here." | "Scan Your First Item" (Salmon) |
| Empty category | Single clay shelf with category icon | "Nothing here yet." | — |
| No search results | Clay magnifying glass | "No matches found. Try different keywords." | — |

---

## Part IV: On-Device Intelligence

### 4.1 Intelligent Cataloging — Foundation Models

After Vision extracts scan data, Foundation Models generates structured inventory entries entirely on-device (WWDC25-286, WWDC25-301).

```swift
import FoundationModels

@Generable
struct CatalogItem {
    @Guide(description: "Concise marketable title, under 60 characters")
    var title: String
    
    @Guide(description: "2-3 sentence description of condition and key features")
    var description: String
    
    @Guide(description: "One of: sneakers, electronics, books, kitchen, collectibles, clothing, other")
    var category: String
    
    @Guide(description: "Estimated market value in USD based on item type and condition, or nil if unknown")
    var estimatedValue: Double?
    
    @Guide(description: "Condition: mint, excellent, good, fair, poor")
    var condition: String
}

// Usage
func catalogScannedItem(visionData: ScanResult) async throws -> CatalogItem {
    let session = LanguageModelSession()
    let prompt = """
        Based on the following scan data, generate a CatalogItem:
        Object type: \(visionData.objectType)
        Recognized text: \(visionData.recognizedText)
        Barcode data: \(visionData.barcodeData ?? "none")
        """
    return try await session.generate(CatalogItem.self, prompt: prompt)
}
```

**Hardware requirement:** iPhone 15 Pro+ (A17 Pro, 8GB RAM) or M1+ iPad/Mac. Users on older hardware get manual entry + basic Vision scanning.

### 4.2 Precision Recognition — Core ML

For specialist categories (collectible sneakers, designer goods, rare books), custom Core ML models add expert-level identification.

```swift
// Load model
let model = try SneakerClassifier(configuration: MLModelConfiguration())

// Predict
let prediction = try model.prediction(image: pixelBuffer)
let itemType = prediction.classLabel        // e.g., "Nike Air Max 90 Infrared"
let confidence = prediction.classProbability // e.g., ["Nike Air Max 90 Infrared": 0.94]
```

- Models converted to `.mlmodel` via Core ML Tools from TensorFlow/PyTorch
- Executes across CPU/GPU/Neural Engine (Core ML auto-selects)
- Triggered when initial scan classifies into specialist category

### 4.3 Dynamic Valuation — Tool Calling

Real-time market data via Foundation Models' Tool protocol (WWDC25-301).

```swift
struct MarketLookupTool: Tool {
    let name = "lookupMarketPrice"
    let description = "Fetch current market prices for a cataloged item"
    
    struct Input: Codable {
        let itemName: String
        let category: String
        let condition: String
    }
    
    struct Output: Codable {
        let lowPrice: Double
        let highPrice: Double
        let trend: String   // "up", "down", "stable"
        let recentSalesCount: Int
    }
    
    func call(_ input: Input) async throws -> Output {
        return try await AbundanceAPI.fetchMarketPrice(
            name: input.itemName,
            category: input.category,
            condition: input.condition
        )
    }
}
```

Valuation UI: Opaque WarmWhite card (content layer). Price in DeepPlum `.title`. Trend: Salmon (up), SoftTeal (down), Peach (stable).

### 4.4 Technology Integration Matrix

| Feature | Framework | Key API | Hardware Minimum |
|---|---|---|---|
| Intelligent Cataloging | Foundation Models | `LanguageModelSession`, `@Generable`, `@Guide` | iPhone 15 Pro+ / M1+ |
| Precision Recognition | Core ML | `MLModel`, Core ML Tools | Any iOS 26 device |
| Lens Quality Check | Vision | `DetectLensSmudgeRequest` | Any iOS 26 device |
| Live Market Valuation | Foundation Models | `Tool` protocol | iPhone 15 Pro+ / M1+ |
| Text Recognition | Vision | `VNRecognizeTextRequest` | Any iOS 26 device |
| Barcode Scanning | Vision | `VNDetectBarcodesRequest` | Any iOS 26 device |
| Document Reading | Vision | `RecognizeDocumentsRequest` | Any iOS 26 device |
| Document Segmentation | Vision | `DetectDocumentSegmentationRequest` | Any iOS 26 device |

---

## Part V: Implementation Reference

### 5.1 SwiftUI Environment Variables to Always Check

```swift
// ALWAYS read these in views that use glass or animation:
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion
@Environment(\.colorSchemeContrast) var contrast
@Environment(\.dynamicTypeSize) var dynamicTypeSize
@Environment(\.colorScheme) var colorScheme  // light/dark mode
```

### 5.2 SwiftUI Implementation Blueprints

#### Adaptive Glass Effect

```swift
extension View {
    func abundanceGlass() -> some View {
        modifier(AbundanceGlassModifier())
    }
}

struct AbundanceGlassModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .glassEffect(.identity)
                .background(Color("Cream"))
        } else {
            content
                .glassEffect(.regular)
        }
    }
}
```

#### Adaptive Animation

```swift
extension View {
    func abundanceSpring() -> Animation {
        // Call site should check reduceMotion from environment
        .spring(response: 0.5, dampingFraction: 0.6)
    }
    
    static var abundanceFallback: Animation {
        .easeInOut(duration: 0.2)
    }
}

// Usage pattern:
withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.6)) {
    showConfetti = true
}
```

#### Content-Layer Card Container

```swift
struct AbundanceCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(12)
            .background(
                Color("Cream"),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color("Peach"), lineWidth: 1)
            )
    }
}
```

#### Primary Button

```swift
struct AbundancePrimaryButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color("DeepPlum"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(Color("Salmon"), in: Capsule())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(
            reduceMotion ? .easeInOut(duration: 0.1) : .spring(response: 0.3, dampingFraction: 0.6),
            value: isPressed
        )
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
```

#### Scanner Overlay

```swift
struct ScannerOverlay: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Corner indicators
            ForEach(Corner.allCases, id: \.self) { corner in
                CornerMark(corner: corner)
                    .foregroundColor(Color("Cream").opacity(0.6))
                    .opacity(isPulsing ? 1.0 : 0.6)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
```

### 5.3 Asset Catalog Setup

Create these color sets in `Assets.xcassets`:

```
Assets.xcassets/
├── Colors/
│   ├── DeepPlum.colorset/          → #3B2E3A (Any) / #F0DCC0 (Dark)
│   ├── DarkPlum.colorset/          → #2D2226
│   ├── UltraDarkPlum.colorset/     → #1A1218
│   ├── Salmon.colorset/            → #E8907A
│   ├── Peach.colorset/             → #EDBE9E
│   ├── Cream.colorset/             → #F0DCC0 (Any) / #3B2E3A (Dark)
│   ├── SoftTeal.colorset/          → #8ECAC0
│   ├── MutedSage.colorset/         → #9DC4A8
│   ├── BackgroundTeal.colorset/    → #5BB8C9
│   ├── WarmWhite.colorset/         → #FAF6F0 (Any) / #2D2226 (Dark)
│   ├── IconGradientTop.colorset/   → #E8A090
│   ├── IconGradientBottom.colorset/→ #A8D0C8
│   ├── Letterform.colorset/        → #F0DCC0
│   ├── SalmonBehindGlass.colorset/ → #E87A60
│   ├── PeachBehindGlass.colorset/  → #EDB085
│   └── TealBehindGlass.colorset/   → #7AC4B8
└── AppIcon.icon/                   → Built with Icon Composer
```

> **Dark Mode Note:** Dark mode color mappings shown above are initial recommendations. DeepPlum and Cream swap roles (light text on dark backgrounds). Full dark mode palette requires design validation.

### 5.4 Performance Rules

```
RULE: Never stack more than 2 glass layers.
RULE: Prefer opaque content backgrounds to reduce GPU compositing.
RULE: When glass is needed on content, prefer .ultraThickMaterial (less GPU work).
RULE: Reduce Motion = automatic performance improvement (disable .interactive() and springs).
RULE: Profile with Instruments. Target 60fps on all supported devices.
RULE: Test on oldest target device (iPhone SE 3 / A15, iPad 9th gen).
```

### 5.5 Cross-Platform Behavior

| Element | iOS | iPadOS | macOS |
|---|---|---|---|
| Tab Bar | Floating bottom, minimizes on scroll | Floating bottom, larger targets | Sidebar navigation |
| Sidebar | N/A | Inset + `.backgroundExtensionEffect()` | Inset + Liquid Glass |
| Item Grid | 2-col adaptive | 3–4 col adaptive | 4+ col, resizable window |
| Scanner | Full camera overlay | Larger viewfinder | Webcam or file import |
| Scroll Edge | Soft style only | Soft style only | Hard style for pinned headers |
| Glass interactive | `.interactive()` supported | `.interactive()` supported | `.interactive()` NOT available |

---

## Appendix A: WWDC25 Session Index

| Session | Title | Key Topics for Abundance |
|---|---|---|
| WWDC25-219 | Meet Liquid Glass | Core principles, accessibility auto-behavior, tinting, scroll-edge |
| WWDC25-356 | Get to know the new design system | Shapes, geometry, typography, tab bar, sidebar, layout |
| WWDC25-323 | Build a SwiftUI app with the new design | `.glassEffect()`, `.interactive()`, GlassEffectContainer |
| WWDC25-284 | Build a UIKit app with the new design | UIKit adoption, background extension |
| WWDC25-361 | Create icons with Icon Composer | Multi-layer icons, 6 appearance modes |
| WWDC25-286 | Meet the Foundation Models framework | `LanguageModelSession`, `@Generable`, `@Guide` |
| WWDC25-301 | Deep dive into Foundation Models | `Tool` protocol, streaming, sessions |
| WWDC25-272 | Read documents using Vision | `RecognizeDocumentsRequest`, `DetectLensSmudgeRequest` |
| Meet w/ Apple 208 | Apps integrating Liquid Glass | Brand-in-content-layer strategy, case studies |

## Appendix B: Documentation URLs

| Resource | URL |
|---|---|
| Adopting Liquid Glass | `developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass` |
| Liquid Glass Overview | `developer.apple.com/documentation/technologyoverviews/liquid-glass` |
| Glass on Custom Views | `developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views` |
| HIG Materials | `developer.apple.com/design/human-interface-guidelines/materials` |
| Design Gallery | `developer.apple.com/design/new-design-gallery/` |
| Foundation Models | `developer.apple.com/documentation/FoundationModels` |
| Vision Framework | `developer.apple.com/documentation/vision/` |
| Core ML | `developer.apple.com/documentation/coreml/` |
| Icon Composer | `developer.apple.com/icon-composer/` |
| Landmarks Sample | `developer.apple.com/documentation/SwiftUI/Landmarks-Building-an-app-with-Liquid-Glass` |

## Appendix C: Quick Decision Reference

```
Q: Should this element use Liquid Glass?
A: Is it a system navigation control (tab bar, nav bar, toolbar, alert, action sheet)?
   → YES: Use .glassEffect(.regular). Let system manage.
   → NO: Use opaque brand fill (Cream, WarmWhite, Salmon).

Q: What text color should I use?
A: Is the text on a glass surface?
   → YES: .foregroundStyle(.primary) — system auto-adjusts
   → NO: Color("DeepPlum") #3B2E3A — passes AA on every brand color

Q: What background for this card/container?
A: → Cards: Cream #F0DCC0
   → Full-screen views: WarmWhite #FAF6F0
   → Splash/loading: BackgroundTeal #5BB8C9

Q: What animation curve?
A: → Default: .spring(response: 0.5, dampingFraction: 0.6)
   → Reduce Motion: .easeInOut(duration: 0.2)
   → Button press: .spring(response: 0.3, dampingFraction: 0.6)

Q: How do I handle accessibility?
A: → ALWAYS check reduceTransparency, reduceMotion, contrast, dynamicTypeSize
   → Reduce Transparency: replace glass with opaque Cream/WarmWhite
   → Reduce Motion: replace springs with easeInOut, disable parallax
   → Increase Contrast: use UltraDarkPlum, 2px borders, darken palette 15%

Q: What shape should this be?
A: → Interactive control (button, toggle): Capsule
   → Container (card, modal, group): Concentric (radius = parent - padding)
   → Static element (thumbnail, avatar): Fixed radius RoundedRectangle

Q: Can I use white text?
A: → NO. Never. Not on any Abundance color.

Q: Can I use chrome, gloss, metallic, or neon effects?
A: → NO. Never. The brand is claymorphism: matte, warm, clay-like.
```

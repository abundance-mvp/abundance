# DESIGN-033: Typography Specifications

**Created**: 2025-11-10
**Stage**: 2.6 - iOS UI/UX Design & Liquid Glass Integration
**Status**: Approved
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.6.md
- docs/validation/RESEARCH-VALIDATION-stage-2.6.md
- docs/design/DESIGN-031-swiftui-component-library.md
- docs/design/DESIGN-032-color-system-design-tokens.md
- shared/abundance-brand/abundance-core-style-guidelines.md

---

## Overview

This document defines the complete typography system for the Abundance iOS app, implementing SF Pro Rounded across all UI elements with full Dynamic Type support. The system balances brand aesthetic (friendly, approachable rounded letterforms) with accessibility (WCAG 2.2 compliant, Dynamic Type scaling) and iOS platform conventions (semantic text styles).

**Core Principles**:
1. **SF Pro Rounded for Everything**: All text uses `.rounded` design variant for brand consistency
2. **Dynamic Type Support**: All text scales with system accessibility settings (xSmall → xxxLarge)
3. **Semantic Text Styles**: Use SwiftUI text styles (.largeTitle, .body, etc.) instead of fixed point sizes
4. **Weight Hierarchy**: Bold for headlines, Semibold for emphasis, Regular for body
5. **Accessibility-First**: Text readable at all Dynamic Type sizes, supports screen readers

**Technology Stack**:
- SF Pro Rounded (system font, iOS 13+)
- SwiftUI Dynamic Type (automatic scaling)
- Font weights: Regular, Semibold, Bold
- Line height and letter spacing: System-managed

---

## Type Scale

All text styles use SwiftUI's semantic text styles with `.rounded` design variant. This ensures automatic Dynamic Type support and iOS platform consistency.

| Style | Default Size | Weight | Usage | Dynamic Type |
|-------|--------------|--------|-------|--------------|
| **Large Title** | 34pt | Bold | Screen titles, hero headlines, onboarding | ✅ Scales |
| **Title 1** | 28pt | Bold | Section headers, major divisions | ✅ Scales |
| **Title 2** | 22pt | Bold | Subsection headers, modal titles | ✅ Scales |
| **Title 3** | 20pt | Semibold | Card headers, list section headers | ✅ Scales |
| **Headline** | 17pt | Semibold | Emphasized body text, list items | ✅ Scales |
| **Body** | 17pt | Regular | Primary body text, descriptions | ✅ Scales |
| **Callout** | 16pt | Regular | Metadata, secondary descriptions | ✅ Scales |
| **Subheadline** | 15pt | Regular | Tertiary text, less important info | ✅ Scales |
| **Footnote** | 13pt | Regular | Captions, timestamps, hints | ✅ Scales |
| **Caption 1** | 12pt | Regular | Small metadata, fine print | ✅ Scales |
| **Caption 2** | 11pt | Regular | Smallest readable text, legal | ✅ Scales |

**Swift Extension**:

```swift
import SwiftUI

extension Font {
    // MARK: - Abundance Typography System

    // MARK: Headlines & Titles
    /// Large title for screen headers and hero sections
    /// - Default: 34pt Bold
    /// - Usage: Onboarding headlines, screen titles
    static let abundanceLargeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)

    /// Title 1 for major section headers
    /// - Default: 28pt Bold
    /// - Usage: Section headers, major divisions
    static let abundanceTitle1 = Font.system(.title, design: .rounded, weight: .bold)

    /// Title 2 for subsection headers
    /// - Default: 22pt Bold
    /// - Usage: Modal titles, subsection headers
    static let abundanceTitle2 = Font.system(.title2, design: .rounded, weight: .bold)

    /// Title 3 for card headers
    /// - Default: 20pt Semibold
    /// - Usage: Card headers, list section headers
    static let abundanceTitle3 = Font.system(.title3, design: .rounded, weight: .semibold)

    /// Headline for emphasized text
    /// - Default: 17pt Semibold
    /// - Usage: List items, emphasized body text
    static let abundanceHeadline = Font.system(.headline, design: .rounded, weight: .semibold)

    // MARK: Body Text
    /// Body text for primary content
    /// - Default: 17pt Regular
    /// - Usage: Descriptions, paragraphs, primary text
    static let abundanceBody = Font.system(.body, design: .rounded)

    /// Body text with semibold weight
    /// - Default: 17pt Semibold
    /// - Usage: Item names, emphasized labels
    static let abundanceBodySemibold = Font.system(.body, design: .rounded, weight: .semibold)

    /// Callout for metadata
    /// - Default: 16pt Regular
    /// - Usage: Metadata, secondary descriptions
    static let abundanceCallout = Font.system(.callout, design: .rounded)

    /// Subheadline for tertiary text
    /// - Default: 15pt Regular
    /// - Usage: Less important info, tertiary labels
    static let abundanceSubheadline = Font.system(.subheadline, design: .rounded)

    // MARK: Small Text
    /// Footnote for captions and hints
    /// - Default: 13pt Regular
    /// - Usage: Timestamps, captions, hints
    static let abundanceFootnote = Font.system(.footnote, design: .rounded)

    /// Caption 1 for small metadata
    /// - Default: 12pt Regular
    /// - Usage: Small metadata, fine print
    static let abundanceCaption1 = Font.system(.caption, design: .rounded)

    /// Caption 2 for smallest text
    /// - Default: 11pt Regular
    /// - Usage: Legal text, smallest readable size
    static let abundanceCaption2 = Font.system(.caption2, design: .rounded)

    // MARK: Specialized Styles

    /// Button label (body weight semibold)
    /// - Default: 17pt Semibold
    /// - Usage: Button labels, CTAs
    static let abundanceButton = Font.system(.body, design: .rounded, weight: .semibold)

    /// Tab label (caption2 weight medium)
    /// - Default: 11pt Medium
    /// - Usage: Tab bar labels
    static let abundanceTab = Font.system(.caption2, design: .rounded, weight: .medium)
}
```

---

## Font Weight Usage

SF Pro Rounded supports 9 weights, but Abundance uses 3 primary weights for clarity and consistency:

| Weight | Usage | Examples |
|--------|-------|----------|
| **Bold** | Headlines, screen titles, major emphasis | "Welcome to Abundance", "Catalog", "Edit Item" |
| **Semibold** | Subheadings, buttons, tabs, card titles | "Get Started", item names, section headers |
| **Regular** | Body text, descriptions, metadata | Descriptions, timestamps, secondary labels |

**Swift Implementation**:

```swift
// Bold: Headlines and screen titles
Text("Welcome to Abundance")
    .font(.abundanceLargeTitle) // 34pt Bold

// Semibold: Item names and buttons
Text("Vintage Lamp")
    .font(.abundanceBodySemibold) // 17pt Semibold

// Regular: Descriptions and metadata
Text("Scanned 2 hours ago")
    .font(.abundanceFootnote) // 13pt Regular
```

---

## Dynamic Type Support

All text styles automatically scale with system Dynamic Type settings. Users can adjust text size in Settings → Accessibility → Display & Text Size → Larger Text.

### Dynamic Type Sizes

| Size Category | Multiplier | Use Case |
|---------------|------------|----------|
| **xSmall** | 0.82x | User prefers very compact UI |
| **Small** | 0.88x | Slightly smaller than default |
| **Medium** | 0.94x | Just below default |
| **Large (Default)** | 1.0x | System default |
| **xLarge** | 1.12x | Comfortable reading size |
| **xxLarge** | 1.24x | Larger text for accessibility |
| **xxxLarge** | 1.35x | Maximum recommended size |
| **Accessibility 1-5** | 1.4x - 1.9x | Extreme accessibility sizes |

**Layout Considerations**:

When users enable very large text sizes (xxxLarge and above), layouts may break. Use these strategies:

1. **Cap at xxxLarge for Cards**: Prevent layout overflow in constrained spaces
2. **Multiline Wrapping**: Allow text to wrap to multiple lines
3. **Scrollable Content**: Enable scrolling for overflow
4. **Dynamic Spacing**: Adjust padding based on text size

**Swift Implementation**:

```swift
import SwiftUI

struct ItemCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: dynamicSpacing) {
            Text(item.name)
                .font(.abundanceBodySemibold)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Cap at xxxLarge
                .lineLimit(2)

            Text(item.category)
                .font(.abundanceFootnote)
                .foregroundStyle(.secondary)
        }
        .padding(dynamicPadding)
    }

    // Adjust spacing based on Dynamic Type size
    private var dynamicSpacing: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large:
            return 8
        case .xLarge, .xxLarge, .xxxLarge:
            return 12
        default:
            return 16 // Accessibility sizes
        }
    }

    // Adjust padding based on Dynamic Type size
    private var dynamicPadding: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large:
            return 16
        case .xLarge, .xxLarge, .xxxLarge:
            return 20
        default:
            return 24 // Accessibility sizes
        }
    }
}
```

---

## Line Height & Letter Spacing

SF Pro Rounded's line height and letter spacing are **system-managed** for optimal readability. SwiftUI automatically adjusts these values based on:
- Text style (.body, .title, etc.)
- Dynamic Type size
- Multiline vs. single-line text

**Custom Tracking (Advanced Use Only)**:

For large display text (34pt+), custom tracking can improve visual balance:

```swift
Text("Welcome")
    .font(.system(size: 48, design: .rounded, weight: .bold))
    .tracking(-0.4) // Tighten tracking for large display text
```

**Guidelines**:
- **Default (0)**: Use for all body text and standard headings
- **Tight (-0.4 to -0.8)**: Large display text (48pt+), hero headlines
- **Wide (+0.5 to +1.0)**: All-caps labels, buttons (use sparingly)

**Example**:

```swift
// ✅ Good: Default tracking for body text
Text("Scan items with your camera")
    .font(.abundanceBody) // No tracking adjustment

// ✅ Good: Tight tracking for large hero text
Text("Abundance")
    .font(.system(size: 60, design: .rounded, weight: .bold))
    .tracking(-0.6)

// ⚠️ Advanced: Wide tracking for all-caps labels
Text("NEW")
    .font(.abundanceCaption1)
    .textCase(.uppercase)
    .tracking(1.0)
```

---

## Text Color & Vibrancy

Combine typography with color tokens from DESIGN-032 for accessible, brand-consistent text:

| Text Type | Color Token | Contrast Ratio | Usage |
|-----------|-------------|----------------|--------|
| **Primary Text** | `.primary` (vibrancy) or `Color.textPrimary` | 12.52:1 | All body text, headlines, descriptions |
| **Secondary Text** | `.secondary` (vibrancy) | ~7:1 | Metadata, timestamps, captions |
| **Tertiary Text** | `.tertiary` (vibrancy) | ~4.5:1 | Placeholders, hints, disabled text |
| **Link Text** | `Color.textLink` | 7.2:1 | Interactive text, navigation labels |
| **Success Text** | `Color.successColor` | 4.8:1 | Success messages, validation |
| **Warning Text** | `Color.warningColor` | 5.1:1 | Warning messages, alerts |
| **Error Text** | `Color.errorColor` | 5.1:1 | Error messages, validation failures |

**Swift Implementation**:

```swift
// Primary text (headline)
Text("Vintage Lamp")
    .font(.abundanceBodySemibold)
    .foregroundStyle(.primary) // Uses vibrancy on materials

// Secondary text (metadata)
Text("Lighting")
    .font(.abundanceFootnote)
    .foregroundStyle(.secondary)

// Link text
Text("Learn more")
    .font(.abundanceCallout)
    .foregroundStyle(Color.textLink)
    .underline()

// Success text
Text("Item saved successfully")
    .font(.abundanceBody)
    .foregroundStyle(Color.successColor)
```

---

## Typography Hierarchy Examples

### Onboarding Screen

```swift
VStack(spacing: 16) {
    // Large title (hero headline)
    Text("Welcome to Abundance")
        .font(.abundanceLargeTitle) // 34pt Bold
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)

    // Body (tagline)
    Text("Own More, Waste Less")
        .font(.abundanceBody) // 17pt Regular
        .foregroundStyle(.secondary)
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────┐
│                                     │
│      Welcome to Abundance           │ ← 34pt Bold, .primary
│                                     │
│       Own More, Waste Less          │ ← 17pt Regular, .secondary
│                                     │
└─────────────────────────────────────┘
```

### Item Card

```swift
VStack(alignment: .leading, spacing: 4) {
    // Item name (semibold)
    Text("Vintage Lamp")
        .font(.abundanceBodySemibold) // 17pt Semibold
        .foregroundStyle(.primary)
        .lineLimit(2)

    // Category (footnote)
    Text("Lighting")
        .font(.abundanceFootnote) // 13pt Regular
        .foregroundStyle(.secondary)

    HStack {
        Spacer()
        // Price (caption, bold)
        Text("$45.00")
            .font(.system(.caption, design: .rounded, weight: .bold)) // 12pt Bold
            .foregroundStyle(Color.successColor)
    }
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────┐
│                                     │
│  Vintage Lamp                       │ ← 17pt Semibold, .primary
│  Lighting                           │ ← 13pt Regular, .secondary
│                          $45.00     │ ← 12pt Bold, successColor
│                                     │
└─────────────────────────────────────┘
```

### Modal Title

```swift
NavigationStack {
    content
        .navigationTitle("Edit Item") // Automatic Large Title style
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { } // System button style
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Save") { }
                    .fontWeight(.semibold) // Override to Semibold
            }
        }
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────┐
│  Cancel              Save           │ ← 17pt Regular, 17pt Semibold
│                                     │
│  Edit Item                          │ ← 34pt Bold (Large Title)
│  ─────────                          │
│                                     │
│  [Form Content]                     │
│                                     │
└─────────────────────────────────────┘
```

### Empty State

```swift
VStack(spacing: 8) {
    // Headline
    Text("No Items Yet")
        .font(.abundanceTitle2) // 22pt Bold
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)

    // Description
    Text("Start building your catalog by scanning your first item.")
        .font(.abundanceBody) // 17pt Regular
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────┐
│                                     │
│          No Items Yet               │ ← 22pt Bold, .primary
│                                     │
│   Start building your catalog by    │ ← 17pt Regular, .secondary
│  scanning your first item.          │   multiline, centered
│                                     │
└─────────────────────────────────────┘
```

---

## Accessibility Guidelines

### VoiceOver Support

All text is automatically read by VoiceOver with proper pronunciation and context. Enhance with:

```swift
// Combine multiple text elements for concise VoiceOver
ItemCard(item: item)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(item.name), \(item.category), $\(item.estimatedValue ?? 0)")

// Provide context for icon-only elements
Image(systemName: "camera")
    .accessibilityLabel("Camera")
    .accessibilityHint("Opens camera to scan items")
```

### Dynamic Type Testing

Test all screens at extreme sizes:

1. **Settings → Accessibility → Display & Text Size → Larger Text**
2. **Enable Larger Accessibility Sizes**
3. **Drag slider to maximum (Accessibility 5)**
4. **Verify**: Text doesn't truncate, layouts don't break, content scrollable

**Testing Matrix**:

| Screen | xSmall | Large (Default) | xxxLarge | Accessibility 5 |
|--------|--------|----------------|----------|----------------|
| Onboarding | ✅ Readable | ✅ Optimal | ✅ Larger padding | ✅ Scrollable |
| Camera View | ✅ Readable | ✅ Optimal | ✅ Buttons larger | ✅ Safe area respected |
| Catalog Grid | ✅ 2 columns | ✅ 2 columns | ✅ 1 column (dynamic) | ✅ Single column |
| Item Detail | ✅ Readable | ✅ Optimal | ✅ Scrollable | ✅ Larger tap targets |
| Modal Forms | ✅ Readable | ✅ Optimal | ✅ Form scrollable | ✅ Keyboard aware |

**Dynamic Layout Example**:

```swift
struct CatalogView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var columns: [GridItem] {
        // Switch to single column at extreme sizes
        if dynamicTypeSize >= .accessibility1 {
            return [GridItem(.flexible())]
        } else if dynamicTypeSize >= .xxxLarge {
            return [GridItem(.flexible())]
        } else {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { item in
                ItemCard(item: item)
            }
        }
    }
}
```

---

## Typography Anti-Patterns

### ❌ Don't: Use Fixed Point Sizes

```swift
// ❌ Bad: Fixed size doesn't scale with Dynamic Type
Text("Item Name")
    .font(.system(size: 17, design: .rounded))
```

**Why**: Text won't scale with accessibility settings.

**Fix**:

```swift
// ✅ Good: Semantic text style scales automatically
Text("Item Name")
    .font(.abundanceBody)
```

---

### ❌ Don't: Truncate Text at Small Sizes

```swift
// ❌ Bad: Truncates important text
Text("This is a very long item description that gets cut off")
    .lineLimit(1)
```

**Why**: Critical information lost for accessibility users.

**Fix**:

```swift
// ✅ Good: Allow multiline wrapping
Text("This is a very long item description")
    .lineLimit(nil) // Allow unlimited lines
    .fixedSize(horizontal: false, vertical: true)
```

---

### ❌ Don't: Override System Line Height

```swift
// ❌ Bad: Custom line height breaks accessibility
Text("Body text")
    .lineSpacing(2.0) // Custom spacing
```

**Why**: Overrides system-optimized readability.

**Fix**:

```swift
// ✅ Good: Use default line spacing
Text("Body text")
    .font(.abundanceBody) // System-managed line height
```

---

### ❌ Don't: Mix Font Designs

```swift
// ❌ Bad: Inconsistent font design
VStack {
    Text("Title").font(.system(.title, design: .rounded))
    Text("Body").font(.system(.body, design: .default)) // Not rounded!
}
```

**Why**: Breaks visual consistency.

**Fix**:

```swift
// ✅ Good: Consistent .rounded design
VStack {
    Text("Title").font(.abundanceTitle1)
    Text("Body").font(.abundanceBody)
}
```

---

## Global Font Design Override

To apply SF Pro Rounded globally across the entire app, use the `.fontDesign(.rounded)` modifier at the app root:

```swift
import SwiftUI

@main
struct AbundanceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .fontDesign(.rounded) // Apply .rounded to all text
        }
    }
}
```

**Effect**: All text (system buttons, navigation titles, form labels, etc.) automatically use SF Pro Rounded without explicit `.font()` modifiers.

**Benefits**:
- Reduces boilerplate code
- Ensures 100% consistency
- Automatically applies to system UI elements (alerts, sheets, pickers)

**Note**: Custom `.font()` modifiers still override this global setting when needed.

---

## Testing Guidelines

### Manual Testing Checklist

- [ ] **Visual Audit**: Review all screens for font consistency (.rounded design)
- [ ] **Dynamic Type Testing**: Test at xSmall, Large, xxxLarge, Accessibility 5
- [ ] **VoiceOver Testing**: Navigate all screens with VoiceOver enabled
- [ ] **Layout Breaks**: Verify no text truncation or layout overflow at extreme sizes
- [ ] **Color Contrast**: Verify all text meets WCAG AA contrast ratios (4.5:1 minimum)

### Automated Testing

```swift
import XCTest
import SwiftUI
@testable import Abundance

final class TypographyTests: XCTestCase {
    func testAllTextUsesRoundedDesign() {
        let fonts: [Font] = [
            .abundanceLargeTitle,
            .abundanceTitle1,
            .abundanceTitle2,
            .abundanceTitle3,
            .abundanceBody,
            .abundanceCallout,
            .abundanceFootnote,
            .abundanceCaption1
        ]

        for font in fonts {
            XCTAssertTrue(
                font.description.contains("rounded"),
                "Font \(font) should use .rounded design"
            )
        }
    }

    func testDynamicTypeScaling() {
        let sizes: [DynamicTypeSize] = [.xSmall, .large, .xxxLarge, .accessibility5]

        for size in sizes {
            // Verify text scales appropriately
            let scaledFont = Font.abundanceBody.scaled(for: size)
            XCTAssertNotNil(scaledFont)
        }
    }

    func testTextColorContrast() {
        let background = Color.backgroundDefault
        let textColors: [Color] = [.textPrimary, .textLink, .successColor, .warningColor]

        for color in textColors {
            let contrast = color.contrastRatio(against: background)
            XCTAssertGreaterThanOrEqual(
                contrast,
                4.5,
                "Text color \(color) fails WCAG AA (4.5:1): \(contrast):1"
            )
        }
    }
}
```

---

## Usage Examples

### Screen Title

```swift
NavigationStack {
    content
        .navigationTitle("Catalog") // Automatic Large Title (34pt Bold)
        .navigationBarTitleDisplayMode(.large)
}
```

### Button Labels

```swift
PrimaryButton(title: "Get Started") // 17pt Semibold (abundanceButton)

Button("Cancel") { } // System button (17pt Regular)
    .foregroundStyle(.secondary)

Button("Save") { }
    .fontWeight(.semibold) // 17pt Semibold override
```

### Form Labels

```swift
Form {
    Section("Details") {
        TextField("Name", text: $name)
            .font(.abundanceBody) // 17pt Regular

        Picker("Category", selection: $category) {
            ForEach(categories) { category in
                Text(category.name)
                    .font(.abundanceBody)
            }
        }
    }
}
```

### List Items

```swift
List {
    ForEach(items) { item in
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(.abundanceBodySemibold) // 17pt Semibold

            Text(item.category)
                .font(.abundanceFootnote) // 13pt Regular
                .foregroundStyle(.secondary)
        }
    }
}
```

### Alerts & Toasts

```swift
// Success toast
Text("Item saved successfully")
    .font(.abundanceCallout) // 16pt Regular
    .foregroundStyle(Color.successColor)
    .padding()
    .background(Color.successGlow.opacity(0.2), in: Capsule())

// Error alert
Alert(
    title: Text("Error"), // System alert title (17pt Bold)
    message: Text("Failed to save item. Please try again."), // System message (13pt Regular)
    dismissButton: .default(Text("OK")) // System button (17pt Semibold)
)
```

---

## Performance Considerations

### Font Caching

SwiftUI automatically caches system fonts. No manual optimization needed for SF Pro Rounded.

### Custom Fonts (Future)

If custom fonts are added in future phases:

1. **Register fonts**: Add to Info.plist under "Fonts provided by application"
2. **Preload fonts**: Load in `AppDelegate.didFinishLaunching`
3. **Fallback to system**: Gracefully handle missing fonts

```swift
// Future custom font support
extension Font {
    static func customOrFallback(name: String, size: CGFloat, design: Font.Design = .rounded) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        } else {
            return .system(size: size, design: design)
        }
    }
}
```

---

## Resources

### Internal Documents
- docs/design/DESIGN-031-swiftui-component-library.md (component text usage)
- docs/design/DESIGN-032-color-system-design-tokens.md (text color tokens)
- docs/design/DESIGN-034-animation-motion-specifications.md (animated text)
- shared/abundance-brand/abundance-core-style-guidelines.md (typography section)

### Apple Documentation
- SF Pro Font Family: https://developer.apple.com/fonts/
- Font.Design.rounded: https://developer.apple.com/documentation/swiftui/font/design/rounded
- Dynamic Type: https://developer.apple.com/design/human-interface-guidelines/typography#Dynamic-Type
- Text Styles: https://developer.apple.com/design/human-interface-guidelines/typography#Text-Styles
- Accessibility Typography: https://developer.apple.com/design/human-interface-guidelines/accessibility#Typography

### External Resources
- SF Pro User Guide: https://developer.apple.com/fonts/
- iOS Typography Best Practices: https://www.smashingmagazine.com/2022/06/guide-designing-better-mobile-apps-typography/
- Dynamic Type Testing: https://a11y-guidelines.orange.com/en/mobile/ios/development/text-size/

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial typography system with Dynamic Type support | iOS UI/UX Designer & SwiftUI Specialist |

---

**Status**: ✅ **APPROVED**

**Next Steps**: Apply typography tokens across all screens and components in Stage 3.1 iOS Implementation

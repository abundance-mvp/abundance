# DESIGN-035: Accessibility Implementation Guide

**Created**: 2025-11-10
**Stage**: 2.6 - iOS UI/UX Design & Liquid Glass Integration
**Status**: Approved
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.6.md
- docs/validation/RESEARCH-VALIDATION-stage-2.6.md
- docs/design/DESIGN-026-onboarding-flow-ui-specification.md
- docs/design/DESIGN-027-camera-capture-view-specification.md
- docs/design/DESIGN-028-catalog-view-specification.md
- docs/design/DESIGN-029-item-detail-view-specification.md
- docs/design/DESIGN-030-profile-export-view-specification.md
- docs/design/DESIGN-031-swiftui-component-library.md
- docs/design/DESIGN-032-color-system-design-tokens.md
- docs/design/DESIGN-033-typography-specifications.md
- docs/design/DESIGN-034-animation-motion-specifications.md
- shared/abundance-brand/abundance-brand-bible.md

---

## Overview

This document provides the complete accessibility implementation guide for the Abundance iOS app, ensuring WCAG 2.2 Level AA compliance and adherence to Apple Human Interface Guidelines for Accessibility. Accessibility is a non-negotiable brand requirement per the Abundance Brand Bible: "Aesthetic appeal never comes at the cost of usability."

**Core Accessibility Commitment**:
- All interactive elements are accessible via VoiceOver
- Full Dynamic Type support from .xSmall to Accessibility 5 (200% scale)
- Reduce Transparency: Opaque fallbacks for all glass materials
- Reduce Motion: Simplified animations replace complex spring physics
- Keyboard navigation support for external keyboards

**Target Compliance**:
- WCAG 2.2 Level AA (4.5:1 contrast for text, 3:1 for UI components)
- Apple App Store Review Guidelines Section 2.5.1 (Accessibility)
- Platform: iOS 26.0+, iOS 25.0+ (fallback)

**Technology Stack**:
- SwiftUI 6.0 Accessibility APIs
- UIAccessibility (UIKit interop where needed)
- AccessibilityNotification for dynamic announcements
- Environment values: `accessibilityReduceTransparency`, `accessibilityReduceMotion`

---

## Accessibility Feature 1: VoiceOver Support

### Overview

VoiceOver is Apple's screen reader, allowing blind and low-vision users to navigate the app via audio descriptions and gestures. Every interactive element in Abundance must be properly labeled, grouped, and announced.

### Implementation Principles

1. **Descriptive Labels**: All icon-only buttons and image elements have `.accessibilityLabel()`
2. **Semantic Grouping**: Complex UI cards use `.accessibilityElement(children: .combine)` to avoid excessive navigation
3. **Custom Actions**: Multi-step interactions expose individual actions via `.accessibilityAction()`
4. **Trait Usage**: Proper traits (`.isButton`, `.isHeader`, `.isImage`) inform VoiceOver of element purpose
5. **Navigation Order**: Logical top-to-bottom, left-to-right reading order via automatic or explicit ordering
6. **Dynamic Announcements**: Success/error states announced via `AccessibilityNotification.announcement`

### Component-Specific Implementations

#### 1.1 PrimaryButton (DESIGN-031)

**Default SwiftUI Behavior**: Button text is automatically used as accessibility label.

**Icon-Only Variant** (e.g., Camera capture button):

```swift
Button {
    capturePhoto()
} label: {
    Image(systemName: "camera.circle.fill")
        .font(.system(size: 60))
        .foregroundStyle(.primary)
}
.accessibilityLabel("Capture photo")
.accessibilityHint("Opens camera to scan household items")
.accessibilityAddTraits(.isButton)
.sensoryFeedback(.impact(weight: .medium), trigger: isCapturing)
```

**Loading State Announcement**:

```swift
Button(action: saveItem) {
    ZStack {
        Text("Save Item")
            .opacity(isLoading ? 0 : 1)

        if isLoading {
            ProgressView()
        }
    }
}
.accessibilityLabel(isLoading ? "Saving item, please wait" : "Save item")
.accessibilityValue(isLoading ? "In progress" : nil)
.disabled(isLoading)
```

#### 1.2 ItemCard (DESIGN-031)

**Problem**: Card contains multiple text elements (name, category, price). VoiceOver would announce each separately, creating verbose navigation.

**Solution**: Combine children into single accessibility element.

```swift
struct ItemCard: View {
    let item: CatalogItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: item.imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(height: 160)
            .clipShape(ConcentricRectangle(cornerRadius: 12, inset: 4))
            .accessibilityHidden(true) // Image is decorative, name conveys info

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))

                Text(item.category)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack {
                    Spacer()
                    if let value = item.estimatedValue {
                        Text("$\(value, specifier: "%.2f")")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.brandMintGreen)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(.thickMaterial, in: ConcentricRectangle(cornerRadius: 16, inset: 0))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityCardLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to view item details")
    }

    private var accessibilityCardLabel: String {
        var label = item.name
        label += ", \(item.category)"
        if let value = item.estimatedValue {
            label += ", estimated value $\(Int(value))"
        }
        return label
    }
}
```

**Result**: VoiceOver announces "Vintage Camera, Electronics, estimated value $120. Button. Double tap to view item details."

#### 1.3 FloatingTabBar (DESIGN-031)

**Implementation**:

```swift
struct FloatingTabBar: View {
    @Binding var selectedTab: Tab

    enum Tab: String, CaseIterable {
        case catalog = "Catalog"
        case camera = "Camera"
        case profile = "Profile"

        var accessibilityLabel: String {
            switch self {
            case .catalog: return "Catalog tab"
            case .camera: return "Camera tab"
            case .profile: return "Profile tab"
            }
        }

        var iconName: String {
            switch self {
            case .catalog: return "square.grid.2x2"
            case .camera: return "camera"
            case .profile: return "person"
            }
        }
    }

    var body: some View {
        HStack(spacing: 24) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 24))
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)

                        Text(tab.rawValue)
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(selectedTab == tab ? .primary : .tertiary)
                    }
                }
                .accessibilityLabel(tab.accessibilityLabel)
                .accessibilityAddTraits(selectedTab == tab ? [.isButton, .isSelected] : .isButton)
                .sensoryFeedback(.selection, trigger: selectedTab == tab)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .accessibilityElement(children: .contain) // Allow individual tab selection
    }
}
```

#### 1.4 GlassModal (DESIGN-031)

**Implementation**: Announce modal title when presented.

```swift
struct GlassModal<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @ViewBuilder let content: Content
    let primaryAction: () -> Void
    let primaryActionTitle: String

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .accessibilityLabel("Cancel")
                        .accessibilityHint("Closes modal without saving")
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button(primaryActionTitle, action: primaryAction)
                            .fontWeight(.semibold)
                            .accessibilityLabel(primaryActionTitle)
                    }
                }
        }
        .presentationDetents([.large])
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .presentationBackground(.ultraThickMaterial)
        .presentationCornerRadius(24)
        .accessibilityAddTraits(.isModal)
        .onAppear {
            // Announce modal title when presented
            AccessibilityNotification.Announcement("\(title) modal")
                .post()
        }
    }
}
```

#### 1.5 Camera Capture View (DESIGN-027)

**Challenge**: Real-time Vision Framework detection must be announced without overwhelming VoiceOver user.

**Solution**: Announce only when new object is detected, debounce rapid changes.

```swift
struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel
    @State private var lastAnnouncedObject: String?

    var body: some View {
        ZStack {
            CameraPreviewView(session: viewModel.captureSession)
                .edgesIgnoringSafeArea(.all)
                .accessibilityLabel("Camera viewfinder")
                .accessibilityValue(viewModel.detectedObjects.isEmpty ?
                    "No objects detected" :
                    "\(viewModel.detectedObjects.count) objects detected")

            // Bounding boxes
            ForEach(viewModel.detectedObjects) { obj in
                Rectangle()
                    .stroke(Color.brandBrightBlue, lineWidth: 2)
                    .frame(width: obj.bounds.width, height: obj.bounds.height)
                    .position(x: obj.bounds.midX, y: obj.bounds.midY)
                    .accessibilityHidden(true) // Visual indicator only
            }

            VStack {
                Spacer()

                if let barcode = viewModel.detectedBarcode {
                    Text("Barcode detected: \(barcode)")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .padding()
                        .background(.regularMaterial, in: Capsule())
                        .accessibilityLabel("Barcode detected: \(barcode)")
                }

                Button {
                    viewModel.capturePhoto()
                } label: {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Capture photo")
                .accessibilityHint(viewModel.detectedObjects.isEmpty ?
                    "Position item in frame and tap to scan" :
                    "Tap to capture detected items")
                .padding(.bottom, 40)
            }
        }
        .onChange(of: viewModel.detectedObjects.first?.label) { oldValue, newValue in
            announceDetectedObject(newValue)
        }
    }

    private func announceDetectedObject(_ label: String?) {
        guard let label = label, label != lastAnnouncedObject else { return }

        lastAnnouncedObject = label
        AccessibilityNotification.Announcement("Detected \(label)")
            .post()
    }
}
```

### Custom Actions for Complex Interactions

**Use Case**: Item card supports multiple actions (view, edit, share, delete).

**Implementation**: Expose actions via `.accessibilityAction()`.

```swift
struct ItemCard: View {
    let item: CatalogItem
    let onTap: () -> Void
    let onEdit: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void

    var body: some View {
        // ... card UI ...
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button("Edit", systemImage: "pencil", action: onEdit)
            Button("Share", systemImage: "square.and.arrow.up", action: onShare)
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityCardLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "View details", onTap)
        .accessibilityAction(named: "Edit item", onEdit)
        .accessibilityAction(named: "Share item", onShare)
        .accessibilityAction(named: "Delete item", onDelete)
    }
}
```

**VoiceOver Behavior**: Swipe up/down on card to hear "Actions available" → Swipe to hear each action → Double-tap to execute.

### Dynamic Content Announcements

**Use Case**: AI metadata progressively populates after photo capture (DESIGN-020).

**Implementation**: Announce when metadata updates.

```swift
struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel

    var body: some View {
        ScrollView {
            // ... UI ...

            if viewModel.isLoadingAI {
                ProgressView("AI analyzing item...")
                    .accessibilityLabel("AI analyzing item, please wait")
            }
        }
        .onChange(of: viewModel.item.aiMetadata) { oldValue, newValue in
            if newValue != nil && oldValue == nil {
                AccessibilityNotification.Announcement("AI analysis complete")
                    .post()
            }
        }
    }
}
```

### Navigation Order Optimization

**Default Behavior**: SwiftUI automatically orders elements top-to-bottom, left-to-right within each container.

**Manual Override** (if needed):

```swift
VStack {
    headerView
        .accessibilitySortPriority(3)

    contentView
        .accessibilitySortPriority(2)

    footerView
        .accessibilitySortPriority(1)
}
```

**Result**: VoiceOver navigates: header → content → footer (descending priority).

### VoiceOver Testing Checklist

- [ ] Enable VoiceOver: Settings → Accessibility → VoiceOver → On
- [ ] Navigate through all screens using swipe gestures
- [ ] Verify all interactive elements are focusable and labeled
- [ ] Test custom actions (swipe up/down on item cards)
- [ ] Verify dynamic announcements (item scanned, metadata loaded)
- [ ] Test with screen curtain (triple-tap with 3 fingers) to simulate blind user experience
- [ ] Verify modals announce their title when presented
- [ ] Test form validation error announcements

---

## Accessibility Feature 2: Dynamic Type Support

### Overview

Dynamic Type allows users to adjust text size system-wide (Settings → Display & Text Size → Larger Text). Abundance supports all 11 Dynamic Type sizes from `.xSmall` (0.82x) to `.accessibility5` (1.9x / 200% scale), ensuring layouts remain functional at extreme sizes.

### Dynamic Type Size Scale

| Size Category | Scale Factor | Notes |
|---------------|--------------|-------|
| .xSmall | 0.82x | Compact devices, younger users |
| .small | 0.88x | |
| .medium | 0.94x | |
| .large | 1.0x | **Default** |
| .xLarge | 1.12x | |
| .xxLarge | 1.24x | |
| .xxxLarge | 1.36x | **Layout threshold** (switch to single-column) |
| .accessibility1 | 1.48x | Accessibility sizes (Settings toggle required) |
| .accessibility2 | 1.62x | |
| .accessibility3 | 1.76x | |
| .accessibility4 | 1.86x | |
| .accessibility5 | 1.9x | **Maximum** |

### Implementation Strategy

1. **Use Text Styles**: Always use `.font(.system(.body, design: .rounded))` instead of fixed sizes
2. **Layout Adjustments**: Switch to single-column layouts at `.xxxLarge` and above
3. **Increase Spacing**: Add vertical padding at larger sizes for breathing room
4. **Cap Extreme Sizes**: For critical UI elements (item cards), cap at `.xxxLarge` to prevent layout breaks
5. **Test at All Sizes**: Use Xcode Accessibility Inspector to preview all 11 sizes

### Component-Specific Implementations

#### 2.1 Typography with Dynamic Type (DESIGN-033)

**Correct Usage**:

```swift
Text("Item Name")
    .font(.system(.headline, design: .rounded, weight: .semibold))
// Automatically scales with Dynamic Type
```

**Incorrect Usage** (DO NOT USE):

```swift
Text("Item Name")
    .font(.system(size: 18, design: .rounded, weight: .semibold))
// Fixed size, does not scale
```

**Custom Font Scaling** (for brand logotype):

```swift
extension Font {
    static func brandLogotype(for textStyle: Font.TextStyle = .largeTitle) -> Font {
        .custom("AbundanceScript-Regular", size: UIFont.preferredFont(forTextStyle: UIFont.TextStyle(textStyle)).pointSize, relativeTo: textStyle)
    }
}

Text("Abundance")
    .font(.brandLogotype(for: .largeTitle))
// Custom font with Dynamic Type scaling
```

#### 2.2 ItemCard Layout Adjustments

**Problem**: At `.accessibility5` (1.9x), text overflows card, image becomes too large.

**Solution**: Cap at `.xxxLarge`, adjust layout for larger sizes.

```swift
struct ItemCard: View {
    let item: CatalogItem
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing) {
            AsyncImage(url: item.imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(height: adaptiveImageHeight)
            .clipShape(ConcentricRectangle(cornerRadius: 12, inset: 4))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .lineLimit(adaptiveLineLimit)

                Text(item.category)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)

                if let value = item.estimatedValue {
                    HStack {
                        Spacer()
                        Text("$\(value, specifier: "%.2f")")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.brandMintGreen)
                    }
                }
            }
            .padding(.horizontal, adaptivePadding)
            .padding(.bottom, adaptivePadding)
        }
        .background(.thickMaterial, in: ConcentricRectangle(cornerRadius: 16, inset: 0))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Cap at xxxLarge
    }

    private var isLargeSize: Bool {
        dynamicTypeSize >= .xxxLarge
    }

    private var adaptiveImageHeight: CGFloat {
        isLargeSize ? 200 : 160
    }

    private var adaptiveSpacing: CGFloat {
        isLargeSize ? 16 : 12
    }

    private var adaptivePadding: CGFloat {
        isLargeSize ? 16 : 12
    }

    private var adaptiveLineLimit: Int {
        isLargeSize ? 3 : 2
    }
}
```

#### 2.3 Catalog Grid Column Count

**Problem**: At large text sizes, 2-column grid becomes cramped.

**Solution**: Switch to single-column at `.xxxLarge` and above.

```swift
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(viewModel.items) { item in
                    ItemCard(item: item)
                        .onTapGesture {
                            viewModel.selectItem(item)
                        }
                }
            }
            .padding()
        }
    }

    private var gridColumns: [GridItem] {
        let columnCount = dynamicTypeSize >= .xxxLarge ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
    }
}
```

**Result**: At default size, 2 columns. At `.xxxLarge`+, 1 column for maximum readability.

#### 2.4 Button Sizing with Dynamic Type

**PrimaryButton** already supports Dynamic Type (uses `.body` text style).

**Additional Consideration**: Minimum tap target.

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .frame(minHeight: 44) // Ensures 44pt minimum even at .xSmall
        }
        .background(.thinMaterial, in: Capsule())
    }
}
```

#### 2.5 Navigation Title Scaling

**SwiftUI Default**: Navigation titles automatically scale.

**Custom Large Title** (Onboarding hero):

```swift
struct OnboardingWelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to Abundance")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .dynamicTypeSize(...DynamicTypeSize.accessibility3) // Cap at accessibility3

            Text("Your personal inventory vault")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

### Testing Dynamic Type

**Xcode Accessibility Inspector**:
1. Open Xcode → Run app in Simulator
2. Xcode menu → Open Developer Tool → Accessibility Inspector
3. Select target device
4. Settings tab → Text Size slider
5. Preview all 11 sizes

**Real Device Testing**:
1. Settings → Display & Text Size → Larger Text
2. Enable "Larger Accessibility Sizes" toggle
3. Drag slider to test all sizes
4. Navigate through all app screens

**Automated Testing**:

```swift
import XCTest

class DynamicTypeTests: XCTestCase {
    func testCatalogViewAtAllSizes() {
        let sizes: [DynamicTypeSize] = [
            .xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge,
            .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5
        ]

        for size in sizes {
            let view = CatalogView(viewModel: CatalogViewModel())
                .environment(\.dynamicTypeSize, size)

            let controller = UIHostingController(rootView: view)
            // Verify view renders without layout errors
            XCTAssertNotNil(controller.view)
        }
    }
}
```

### Dynamic Type Testing Checklist

- [ ] Test all screens at .xSmall (minimum)
- [ ] Test all screens at .large (default)
- [ ] Test all screens at .xxxLarge (layout threshold)
- [ ] Test all screens at .accessibility5 (maximum)
- [ ] Verify single-column layouts activate at .xxxLarge
- [ ] Verify no text truncation at any size
- [ ] Verify buttons maintain 44pt minimum tap target
- [ ] Verify item cards don't break at extreme sizes
- [ ] Test navigation between screens at .accessibility5

---

## Accessibility Feature 3: Reduce Transparency Support

### Overview

Reduce Transparency (Settings → Accessibility → Display & Text Size → Reduce Transparency) replaces translucent materials with opaque backgrounds, improving legibility for users with visual sensitivities or in bright environments.

**Requirement**: Per Abundance Brand Bible, "Aesthetic appeal never comes at the cost of usability." All glass materials MUST have opaque fallbacks.

### Implementation Strategy

1. **Environment Value**: `@Environment(\.accessibilityReduceTransparency) var reduceTransparency`
2. **Material Replacements**:
   - `.thinMaterial` → `Color.backgroundDefault` (#FCFCFF)
   - `.regularMaterial` → `Color.backgroundDefault`
   - `.thickMaterial` → `Color.backgroundDefault`
   - `.ultraThickMaterial` → `Color.surfaceElevated` (#F5F5F7)
3. **Border Addition**: Opaque surfaces need borders for visual definition
4. **Shadow Preservation**: Soft shadows maintained for depth perception

### Color Token Definitions

From DESIGN-032:

```swift
extension Color {
    // MARK: - Accessibility Fallback Colors
    static let backgroundDefault = Color(hex: "#FCFCFF")      // Off-white base
    static let surfaceElevated = Color(hex: "#F5F5F7")        // Slightly darker elevated surface
    static let borderSubtle = Color(hex: "#E5E5E7")           // Light gray border
    static let borderDefault = Color(hex: "#D1D1D6")          // Medium gray border
}
```

### Component-Specific Implementations

#### 3.1 PrimaryButton with Reduce Transparency

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
        }
        .background {
            Capsule()
                .fill(reduceTransparency ? Color.backgroundDefault : .thinMaterial)
                .shadow(color: Color.brandBrightBlue.opacity(0.5), radius: 12, x: 0, y: 4)
        }
        .overlay {
            Capsule()
                .stroke(Color.brandBrightBlue, lineWidth: reduceTransparency ? 3 : 2)
        }
    }
}
```

**Changes when Reduce Transparency enabled**:
- `.thinMaterial` → `Color.backgroundDefault`
- Border width 2pt → 3pt (stronger definition)
- Shadow preserved for depth

#### 3.2 ItemCard with Reduce Transparency

```swift
struct ItemCard: View {
    let item: CatalogItem

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ... content ...
        }
        .background {
            if reduceTransparency {
                ConcentricRectangle(cornerRadius: 16, inset: 0)
                    .fill(Color.surfaceElevated)
                    .overlay {
                        ConcentricRectangle(cornerRadius: 16, inset: 0)
                            .stroke(Color.borderDefault, lineWidth: 1)
                    }
            } else {
                ConcentricRectangle(cornerRadius: 16, inset: 0)
                    .fill(.thickMaterial)
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
```

**Changes when Reduce Transparency enabled**:
- `.thickMaterial` → `Color.surfaceElevated`
- Border added for visual separation
- Shadow preserved

#### 3.3 FloatingTabBar with Reduce Transparency

```swift
struct FloatingTabBar: View {
    @Binding var selectedTab: Tab
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 24) {
            // ... tab buttons ...
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background {
            if reduceTransparency {
                Capsule()
                    .fill(Color.backgroundDefault)
                    .overlay {
                        Capsule()
                            .stroke(Color.borderDefault, lineWidth: 1)
                    }
            } else {
                Capsule()
                    .fill(.regularMaterial)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 40)
        .padding(.bottom, 16)
    }
}
```

#### 3.4 GlassModal with Reduce Transparency

```swift
struct GlassModal<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .toolbar {
                    // ... toolbar items ...
                }
        }
        .presentationDetents([.large])
        .presentationBackground(reduceTransparency ?
            Color.backgroundDefault :
            .ultraThickMaterial)
        .presentationCornerRadius(24)
    }
}
```

**Note**: SwiftUI's `.presentationBackground()` automatically handles borders for modal sheets.

### Reusable ViewModifier

**Create AccessibilityMaterialModifier for consistent usage**:

```swift
struct AccessibilityMaterialModifier: ViewModifier {
    let material: Material
    let opaqueColor: Color
    let shape: AnyShape
    let addBorder: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init<S: Shape>(
        material: Material,
        opaqueColor: Color,
        shape: S,
        addBorder: Bool = true
    ) {
        self.material = material
        self.opaqueColor = opaqueColor
        self.shape = AnyShape(shape)
        self.addBorder = addBorder
    }

    func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency {
                    shape
                        .fill(opaqueColor)
                        .overlay {
                            if addBorder {
                                shape.stroke(Color.borderDefault, lineWidth: 1)
                            }
                        }
                } else {
                    shape.fill(material)
                }
            }
    }
}

extension View {
    func accessibilityMaterial<S: Shape>(
        _ material: Material,
        opaqueColor: Color,
        shape: S,
        addBorder: Bool = true
    ) -> some View {
        modifier(AccessibilityMaterialModifier(
            material: material,
            opaqueColor: opaqueColor,
            shape: shape,
            addBorder: addBorder
        ))
    }
}
```

**Usage**:

```swift
VStack {
    // content
}
.accessibilityMaterial(
    .thickMaterial,
    opaqueColor: .surfaceElevated,
    shape: RoundedRectangle(cornerRadius: 16)
)
```

### Testing Reduce Transparency

**Enable on Device**:
1. Settings → Accessibility → Display & Text Size
2. Toggle "Reduce Transparency" ON
3. Navigate through all app screens
4. Verify all glass materials replaced with opaque backgrounds
5. Verify borders added for visual separation

**Simulator Testing**:
1. Accessibility Inspector → Settings → Reduce Transparency toggle
2. Preview changes in real-time

**Automated Testing**:

```swift
func testReduceTransparencyFallback() {
    let view = PrimaryButton(title: "Save", action: {})
        .environment(\.accessibilityReduceTransparency, true)

    let controller = UIHostingController(rootView: view)
    // Verify opaque background rendered
    XCTAssertNotNil(controller.view)
}
```

### Reduce Transparency Checklist

- [ ] All `.material` backgrounds have opaque `Color` fallbacks
- [ ] Opaque surfaces include borders for visual definition
- [ ] Shadows preserved for depth perception
- [ ] Test all screens with Reduce Transparency enabled
- [ ] Verify navigation bars replace blur with solid backgrounds
- [ ] Verify modals (sheets, alerts) use opaque backgrounds
- [ ] Test in bright sunlight (outdoor use case)

---

## Accessibility Feature 4: Reduce Motion Support

### Overview

Reduce Motion (Settings → Accessibility → Motion → Reduce Motion) replaces complex spring animations with simple cross-fade transitions, preventing motion sickness and improving usability for users with vestibular disorders.

**Requirement**: All spring-based animations, parallax effects, and continuous animations MUST respect this setting.

### Implementation Strategy

1. **Environment Value**: `@Environment(\.accessibilityReduceMotion) var reduceMotion`
2. **Animation Replacements**:
   - Spring animations → `nil` (instant) or `.easeInOut(duration: 0.2)`
   - Parallax effects → Disabled
   - Continuous animations → Static states
   - `.scaleEffect()`, `.offset()` transitions → `.opacity` only
3. **Preserve Feedback**: Visual feedback (color change, opacity) still occurs, just without motion

### Component-Specific Implementations

#### 4.1 PrimaryButton Tap Animation

**Without Reduce Motion** (default):

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    @State private var isPressed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: handleTap) {
            Text(title)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
        }
        .background(.thinMaterial, in: Capsule())
        .scaleEffect(isPressed && !reduceMotion ? 0.95 : 1.0)
        .opacity(isPressed ? 0.7 : 1.0)
        .animation(animation, value: isPressed)
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
    }

    private func handleTap() {
        isPressed = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
            action()
        }
    }

    private var animation: Animation? {
        reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6)
    }
}
```

**With Reduce Motion**: Only opacity changes (0.7 → 1.0), no scale animation.

#### 4.2 ItemCard Tap Animation

```swift
struct ItemCard: View {
    let item: CatalogItem
    let onTap: () -> Void

    @State private var isPressed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ... content ...
        }
        .background(.thickMaterial, in: ConcentricRectangle(cornerRadius: 16, inset: 0))
        .scaleEffect(isPressed && !reduceMotion ? 0.97 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(animation, value: isPressed)
        .onTapGesture {
            isPressed = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        }
    }

    private var animation: Animation? {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.7)
    }
}
```

**With Reduce Motion**: Simple 0.2s ease transition instead of bouncy spring.

#### 4.3 Modal Sheet Presentation

**Without Reduce Motion**: Sheet slides up with spring physics.

**With Reduce Motion**: Sheet appears instantly or with simple fade.

```swift
struct CatalogView: View {
    @State private var isPresentingDetail: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack {
            // ... catalog content ...
        }
        .sheet(isPresented: $isPresentingDetail) {
            ItemDetailView()
                .transition(reduceMotion ? .opacity : .move(edge: .bottom))
        }
    }
}
```

#### 4.4 Camera Bounding Box Animation

**Problem**: Bounding boxes pulse/glow when object detected.

**Solution**: Static glow when Reduce Motion enabled.

```swift
struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CameraPreviewView(session: viewModel.captureSession)

            ForEach(viewModel.detectedObjects) { obj in
                BoundingBox(object: obj, reduceMotion: reduceMotion)
            }
        }
    }
}

struct BoundingBox: View {
    let object: DetectedObject
    let reduceMotion: Bool

    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        Rectangle()
            .stroke(Color.brandBrightBlue, lineWidth: 2)
            .frame(width: object.bounds.width, height: object.bounds.height)
            .position(x: object.bounds.midX, y: object.bounds.midY)
            .opacity(reduceMotion ? 1.0 : pulseOpacity)
            .onAppear {
                guard !reduceMotion else { return }

                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.5
                }
            }
    }
}
```

**With Reduce Motion**: Bounding box stays at 100% opacity (no pulse).

#### 4.5 Success Animation (Item Scanned)

**Without Reduce Motion**: Checkmark scales up with bouncy spring, confetti particles.

**With Reduce Motion**: Checkmark fades in, no confetti.

```swift
struct ScanSuccessView: View {
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.brandMintGreen)
                .scaleEffect(reduceMotion ? 1.0 : 1.2)
                .onAppear {
                    guard !reduceMotion else { return }

                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        // Bouncy scale animation
                    }
                }

            Text("Item Scanned!")
                .font(.system(.title, design: .rounded, weight: .bold))

            if !reduceMotion {
                // Confetti particles only when motion enabled
                ConfettiView()
            }
        }
        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
        .padding()
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}
```

#### 4.6 Parallax Scroll Effect (Item Detail Hero Image)

**Without Reduce Motion**: Hero image scrolls at different rate than content.

**With Reduce Motion**: Hero image scrolls normally.

```swift
struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                AsyncImage(url: viewModel.item.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: 300)
                        .offset(y: reduceMotion ? 0 : scrollOffset * 0.5) // Parallax effect
                        .clipped()
                }
            }
            .frame(height: 300)

            // ... metadata content ...
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
    }
}
```

**With Reduce Motion**: `offset(y: 0)` → no parallax.

### Reusable Animation Helpers

```swift
extension Animation {
    static func accessible(
        reduceMotion: Bool,
        normal: Animation = .spring(response: 0.4, dampingFraction: 0.7),
        reduced: Animation? = .easeInOut(duration: 0.2)
    ) -> Animation? {
        reduceMotion ? reduced : normal
    }
}

// Usage
.animation(.accessible(reduceMotion: reduceMotion), value: isPresented)
```

### Testing Reduce Motion

**Enable on Device**:
1. Settings → Accessibility → Motion
2. Toggle "Reduce Motion" ON
3. Navigate through all app screens
4. Verify no spring animations, parallax, or continuous motion

**Simulator Testing**:
1. Accessibility Inspector → Settings → Reduce Motion toggle

**Automated Testing**:

```swift
func testReduceMotionDisablesSpringAnimation() {
    let button = PrimaryButton(title: "Test", action: {})
        .environment(\.accessibilityReduceMotion, true)

    let controller = UIHostingController(rootView: button)
    // Verify animation is nil or simple
    XCTAssertNotNil(controller.view)
}
```

### Reduce Motion Checklist

- [ ] All spring animations respect `accessibilityReduceMotion`
- [ ] Parallax effects disabled when enabled
- [ ] Continuous animations (pulse, spin) disabled or simplified
- [ ] Transitions use `.opacity` instead of `.scale` or `.offset`
- [ ] Success/celebratory animations simplified (no confetti, bouncy scales)
- [ ] Camera overlays static (no pulsing bounding boxes)
- [ ] Test all screens with Reduce Motion enabled
- [ ] Verify no motion sickness triggers (rapid movement, rotation)

---

## Accessibility Feature 5: Keyboard Navigation

### Overview

External keyboard support allows iPad users and assistive technology users to navigate the app without touch. All interactive elements must be reachable via Tab key, and common actions should have keyboard shortcuts.

### Implementation Principles

1. **Tab Order**: Top-to-bottom, left-to-right navigation
2. **Focus Management**: `.focused()` modifier for manual focus control
3. **Keyboard Shortcuts**: `UIKeyCommand` for common actions (iOS 15+)
4. **Escape Key**: Dismiss modals/sheets
5. **Return Key**: Submit forms, trigger primary actions

### Tab Order (Default Behavior)

SwiftUI automatically creates logical tab order. Verify by:
1. Connect external keyboard to iPad
2. Press Tab key repeatedly
3. Ensure focus moves logically through interactive elements

**Manual Override** (if needed):

```swift
VStack {
    Button("First", action: {})
        .focusable()

    Button("Second", action: {})
        .focusable()

    Button("Third", action: {})
        .focusable()
}
```

### Focus Management

**Use Case**: After saving item, return focus to "Add Item" button.

```swift
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel
    @FocusState private var focusedButton: FocusableButton?

    enum FocusableButton {
        case addItem
        case searchField
    }

    var body: some View {
        VStack {
            TextField("Search items...", text: $viewModel.searchQuery)
                .focused($focusedButton, equals: .searchField)
                .textFieldStyle(.roundedBorder)
                .padding()

            // ... catalog grid ...

            Button("Add Item") {
                viewModel.presentCamera()
            }
            .focused($focusedButton, equals: .addItem)
        }
        .onAppear {
            focusedButton = .searchField // Auto-focus search on appear
        }
        .onChange(of: viewModel.itemSaved) { _, saved in
            if saved {
                focusedButton = .addItem // Return focus after save
            }
        }
    }
}
```

### Keyboard Shortcuts

**Implementation**: Use `.keyboardShortcut()` modifier (SwiftUI) or `UIKeyCommand` (UIKit).

```swift
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel

    var body: some View {
        VStack {
            // ... catalog content ...
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Item") {
                    viewModel.presentCamera()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
```

**Common Shortcuts**:
- `Cmd+N`: Add new item (open camera)
- `Cmd+F`: Focus search field
- `Cmd+S`: Save item (in edit modal)
- `Cmd+W`: Close modal/sheet
- `Escape`: Dismiss modal
- `Return`: Submit form

**Full Example**:

```swift
struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            // ... item detail content ...

            Button("Save Changes") {
                viewModel.saveItem()
            }
            .keyboardShortcut("s", modifiers: [.command])

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape)
        }
    }
}
```

### Return Key Submission

**Use Case**: Press Return to submit form.

```swift
struct EditItemView: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @FocusState private var focusedField: Field?

    enum Field {
        case name
        case category
    }

    var body: some View {
        Form {
            TextField("Item Name", text: $viewModel.itemName)
                .focused($focusedField, equals: .name)
                .onSubmit {
                    focusedField = .category // Move to next field
                }

            TextField("Category", text: $viewModel.itemCategory)
                .focused($focusedField, equals: .category)
                .onSubmit {
                    viewModel.saveItem() // Submit on last field
                }
        }
    }
}
```

### Testing Keyboard Navigation

**External Keyboard (iPad)**:
1. Connect keyboard to iPad
2. Press Tab to navigate between elements
3. Press Return/Space to activate buttons
4. Press Escape to dismiss modals
5. Test keyboard shortcuts (Cmd+N, Cmd+S, etc.)

**Accessibility Inspector**:
- Verify tab order is logical
- Ensure all interactive elements are focusable

**Automated Testing**:

```swift
func testKeyboardNavigation() {
    let app = XCUIApplication()
    app.launch()

    // Simulate Tab key presses (XCUITest API)
    app.typeKey("\t", modifierFlags: [])
    XCTAssertTrue(app.buttons["Add Item"].hasFocus)
}
```

### Keyboard Navigation Checklist

- [ ] All interactive elements reachable via Tab key
- [ ] Tab order is logical (top-to-bottom, left-to-right)
- [ ] Return key submits forms
- [ ] Escape key dismisses modals/sheets
- [ ] Common actions have keyboard shortcuts (Cmd+N, Cmd+S)
- [ ] Focus indicators visible (system default highlight)
- [ ] Test on iPad with external keyboard
- [ ] Verify VoiceOver works with keyboard navigation

---

## Accessibility Patterns & Utilities

### 1. AccessibilityWrapper ViewModifier

**Purpose**: Combine Reduce Transparency and Reduce Motion in single modifier.

```swift
struct AccessibilityWrapper: ViewModifier {
    let material: Material
    let opaqueColor: Color
    let normalAnimation: Animation
    let reducedAnimation: Animation?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .background(reduceTransparency ? opaqueColor : material)
            .animation(reduceMotion ? reducedAnimation : normalAnimation, value: UUID())
    }
}

extension View {
    func accessibilityAdaptive(
        material: Material,
        opaqueColor: Color,
        normalAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.7),
        reducedAnimation: Animation? = .easeInOut(duration: 0.2)
    ) -> some View {
        modifier(AccessibilityWrapper(
            material: material,
            opaqueColor: opaqueColor,
            normalAnimation: normalAnimation,
            reducedAnimation: reducedAnimation
        ))
    }
}
```

**Usage**:

```swift
VStack {
    // content
}
.accessibilityAdaptive(
    material: .thickMaterial,
    opaqueColor: .surfaceElevated
)
```

### 2. AccessibilityAnnouncer Utility

**Purpose**: Queue announcements to avoid overwhelming VoiceOver.

```swift
@MainActor
class AccessibilityAnnouncer: ObservableObject {
    private var queue: [String] = []
    private var isAnnouncing: Bool = false

    func announce(_ message: String) {
        queue.append(message)
        processQueue()
    }

    private func processQueue() {
        guard !isAnnouncing, let message = queue.first else { return }

        isAnnouncing = true
        queue.removeFirst()

        AccessibilityNotification.Announcement(message).post()

        // Wait 2 seconds before next announcement
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isAnnouncing = false
            self.processQueue()
        }
    }
}

// Usage
class CameraViewModel: ObservableObject {
    let announcer = AccessibilityAnnouncer()

    func didDetectObject(_ label: String) {
        announcer.announce("Detected \(label)")
    }
}
```

### 3. AccessibilityTesting Protocol

**Purpose**: Automated checks for accessibility compliance.

```swift
protocol AccessibilityTesting {
    func hasAccessibilityLabel() -> Bool
    func hasMinimumTapTarget() -> Bool
    func hasAccessibilityTraits() -> Bool
}

extension View {
    func verifyAccessibility() -> Bool {
        // Runtime checks (use in development/debug builds)
        let hasLabel = accessibilityLabel != nil
        let hasTraits = accessibilityTraits.contains(.isButton) ||
                        accessibilityTraits.contains(.isHeader)

        return hasLabel && hasTraits
    }
}

// Unit test helper
func assertAccessibilityCompliance<V: View>(_ view: V) {
    let controller = UIHostingController(rootView: view)
    let renderedView = controller.view!

    // Check for accessibility label
    XCTAssertNotNil(renderedView.accessibilityLabel, "View missing accessibility label")

    // Check for minimum tap target (44x44pt)
    XCTAssertGreaterThanOrEqual(renderedView.frame.height, 44)
    XCTAssertGreaterThanOrEqual(renderedView.frame.width, 44)
}
```

---

## Testing Guide

### Manual Testing Checklist

**VoiceOver Navigation** (All Screens):
- [ ] Enable VoiceOver (triple-click side button)
- [ ] Navigate Onboarding: Swipe through all elements, verify labels
- [ ] Navigate Camera: Verify viewfinder, capture button, cancel button announced
- [ ] Navigate Catalog: Verify item cards announce name, category, price
- [ ] Navigate Item Detail: Verify hero image, metadata fields, edit button
- [ ] Navigate Profile: Verify settings list, export button
- [ ] Test custom actions: Swipe up/down on item cards to access Edit/Share/Delete
- [ ] Test dynamic announcements: Scan item, verify "Detected [object]" announced
- [ ] Test modal presentations: Verify modal title announced on appear

**Dynamic Type** (All Sizes):
- [ ] Set to .xSmall: Verify all text readable, layouts not cramped
- [ ] Set to .large (default): Verify standard layouts
- [ ] Set to .xxxLarge: Verify single-column layouts activate
- [ ] Set to .accessibility5: Verify text caps at xxxLarge where appropriate
- [ ] Test all screens at each size: Onboarding, Camera, Catalog, Item Detail, Profile

**Reduce Transparency**:
- [ ] Enable Reduce Transparency
- [ ] Verify all glass materials replaced with opaque backgrounds
- [ ] Verify borders added to surfaces for visual definition
- [ ] Verify modals use opaque backgrounds
- [ ] Test in bright outdoor environment

**Reduce Motion**:
- [ ] Enable Reduce Motion
- [ ] Verify no spring animations on button taps
- [ ] Verify no parallax scroll effects
- [ ] Verify no pulsing/continuous animations
- [ ] Verify success animations simplified (no confetti, bouncy scales)
- [ ] Test all transitions (modal presentations, navigation)

**Keyboard Navigation** (iPad):
- [ ] Connect external keyboard
- [ ] Press Tab: Verify logical focus order through all screens
- [ ] Press Return: Verify activates buttons, submits forms
- [ ] Press Escape: Verify dismisses modals
- [ ] Test shortcuts: Cmd+N (add item), Cmd+S (save), Cmd+F (search)
- [ ] Verify focus indicators visible

### Automated Testing Patterns

#### XCUITest Accessibility Queries

```swift
import XCTest

class AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        app = XCUIApplication()
        app.launch()
    }

    func testVoiceOverLabels() {
        // Verify all buttons have accessibility labels
        let buttons = app.buttons.allElementsBoundByIndex

        for button in buttons {
            XCTAssertFalse(button.label.isEmpty, "Button missing accessibility label")
        }
    }

    func testMinimumTapTargets() {
        let buttons = app.buttons.allElementsBoundByIndex

        for button in buttons {
            XCTAssertGreaterThanOrEqual(button.frame.height, 44,
                "Button \(button.label) tap target too small: \(button.frame.height)pt")
            XCTAssertGreaterThanOrEqual(button.frame.width, 44,
                "Button \(button.label) tap target too small: \(button.frame.width)pt")
        }
    }

    func testDynamicTypeScaling() {
        // Test at different Dynamic Type sizes
        let sizes: [UIContentSizeCategory] = [
            .small, .large, .xxxLarge, .accessibilityExtraLarge
        ]

        for size in sizes {
            app.launchArguments = ["-UIPreferredContentSizeCategory", size.rawValue]
            app.launch()

            // Verify all screens render without errors
            XCTAssertTrue(app.otherElements["CatalogView"].exists)
        }
    }

    func testReduceTransparencyFallback() {
        // Enable Reduce Transparency
        app.launchArguments = ["-UIAccessibilityReduceTransparency", "1"]
        app.launch()

        // Verify app renders correctly
        XCTAssertTrue(app.otherElements["CatalogView"].exists)
    }

    func testReduceMotionFallback() {
        // Enable Reduce Motion
        app.launchArguments = ["-UIAccessibilityReduceMotion", "1"]
        app.launch()

        // Verify app renders correctly
        XCTAssertTrue(app.otherElements["CatalogView"].exists)
    }
}
```

#### Unit Test Accessibility Helpers

```swift
import XCTest
import SwiftUI

class AccessibilityUnitTests: XCTestCase {
    func testPrimaryButtonAccessibility() {
        let button = PrimaryButton(title: "Save", action: {})
        let controller = UIHostingController(rootView: button)

        // Render view
        _ = controller.view

        // Verify minimum tap target
        XCTAssertGreaterThanOrEqual(controller.view.frame.height, 44)
    }

    func testItemCardAccessibilityLabel() {
        let item = CatalogItem(
            id: "1",
            name: "Test Item",
            category: "Electronics",
            estimatedValue: 100.0
        )

        let card = ItemCard(item: item)
        let controller = UIHostingController(rootView: card)

        // Verify accessibility label includes all info
        let label = controller.view.accessibilityLabel
        XCTAssertNotNil(label)
        XCTAssertTrue(label!.contains("Test Item"))
        XCTAssertTrue(label!.contains("Electronics"))
        XCTAssertTrue(label!.contains("100"))
    }
}
```

### Real Device Testing Requirements

**VoiceOver Gestures** (vary by device):
- iPhone: Swipe left/right to navigate, double-tap to activate
- iPad: Same as iPhone, or use external keyboard + VoiceOver
- Magic Keyboard: Tab to navigate, Return/Space to activate

**Dynamic Type Testing**:
- Test on smallest device (iPhone SE): Verify layouts don't break
- Test on largest device (iPhone 15 Pro Max): Verify spacing appropriate
- Test on iPad: Verify grid layouts adapt to larger screen

**Performance Testing**:
- Test Reduce Transparency on older devices (iPhone 13): Verify no frame drops
- Test Material performance in low-power mode
- Test VoiceOver responsiveness with large catalogs (100+ items)

---

## App Store Review Considerations

### Required Accessibility Features

Apple App Store Review Guidelines Section 2.5.1:

1. **VoiceOver Support**: All functionality accessible via VoiceOver
2. **Dynamic Type Support**: Text scales with system text size settings
3. **Reduce Transparency**: Translucent materials replaced with opaque backgrounds
4. **Reduce Motion**: Animations simplified or disabled
5. **Sufficient Contrast**: WCAG 2.2 AA compliance (4.5:1 for text)

### App Store Connect Accessibility Fields

When submitting to App Store, fill out:

1. **Accessibility Description**: "Abundance is fully accessible to VoiceOver users, supports Dynamic Type scaling to 200%, respects Reduce Transparency and Reduce Motion system settings, and meets WCAG 2.2 Level AA contrast requirements."

2. **Compatibility Limitations**: "None. All features are accessible."

3. **Support Contact**: Provide email for accessibility-related issues

### Screenshots with Accessibility Features

Include App Store screenshots demonstrating:
- Large text size (Dynamic Type at .xxxLarge)
- VoiceOver focus indicators (accessibility mode)
- High contrast mode (if applicable)

### Privacy Policy Accessibility Statement

Add to Privacy Policy:

> **Accessibility Commitment**
>
> Abundance is designed to be inclusive and accessible to all users. We support VoiceOver screen reader navigation, Dynamic Type text scaling, Reduce Transparency and Reduce Motion system settings, and meet WCAG 2.2 Level AA accessibility standards. If you encounter accessibility barriers, please contact support@abundance.app.

---

## References

### Apple Documentation

- **SwiftUI Accessibility**: https://developer.apple.com/documentation/swiftui/accessibility
- **Human Interface Guidelines - Accessibility**: https://developer.apple.com/design/human-interface-guidelines/accessibility
- **accessibilityReduceTransparency**: https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducetransparency
- **accessibilityReduceMotion**: https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion
- **VoiceOver Programming Guide**: https://developer.apple.com/documentation/uikit/accessibility/supporting_voiceover_in_your_app
- **Dynamic Type**: https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically

### WCAG 2.2 Guidelines

- **WCAG 2.2 Overview**: https://www.w3.org/WAI/WCAG22/quickref/
- **1.4.3 Contrast (Minimum)**: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
- **2.1 Keyboard Accessible**: https://www.w3.org/WAI/WCAG21/Understanding/keyboard-accessible
- **2.5 Input Modalities**: https://www.w3.org/WAI/WCAG21/Understanding/input-modalities

### WWDC Sessions

- **WWDC 2025 Session 247**: What's new in SwiftUI (Accessibility improvements)
- **WWDC 2024 Session 10073**: Build accessible apps with SwiftUI and UIKit
- **WWDC 2023 Session 10036**: The practice of inclusive design

### Abundance Design Specs

- **DESIGN-031**: SwiftUI Component Library (VoiceOver labels, tap targets)
- **DESIGN-032**: Color System & Design Tokens (WCAG-compliant text variants)
- **DESIGN-033**: Typography Specifications (Dynamic Type support)
- **DESIGN-034**: Animation & Motion Specifications (Reduce Motion patterns)

### Validation Reports

- **RESEARCH-VALIDATION-stage-2.6.md**: Verified accessibility API availability
- **PLAN-SUMMARY-stage-2.6.md**: Accessibility requirements and implementation strategy

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial accessibility implementation guide | iOS UI/UX Designer & SwiftUI Specialist |

---

**Status**: ✅ **APPROVED**

**Next Steps**:
1. Implement accessibility modifiers in all components (DESIGN-031)
2. Create DESIGN-036: WCAG 2.2 Compliance Checklist
3. Test all screens with VoiceOver, Dynamic Type, Reduce Transparency, Reduce Motion
4. Conduct accessibility audit before Stage 3.1 iOS implementation

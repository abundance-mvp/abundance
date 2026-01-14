# DESIGN-034: Animation & Motion Specifications

**Created**: 2025-11-10
**Stage**: 2.6 - iOS UI/UX Design & Liquid Glass Integration
**Status**: Approved
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.6.md
- docs/validation/RESEARCH-VALIDATION-stage-2.6.md
- docs/design/DESIGN-031-swiftui-component-library.md
- docs/design/DESIGN-032-color-system-design-tokens.md
- docs/design/DESIGN-033-typography-specifications.md
- shared/abundance-brand/abundance-core-style-guidelines.md

---

## Overview

This document defines the complete animation and motion system for the Abundance iOS app, implementing fluid, physics-based animations that embody the brand's "Refractive Retro-Futurism" aesthetic. All animations use spring-based physics with preset timing curves and sensory feedback, ensuring consistency across the app while respecting accessibility preferences (Reduce Motion).

**Core Principles**:
1. **Spring Physics for Everything**: All animations use `.spring()` for natural, fluid motion
2. **Sensory Feedback on Interactions**: Haptic feedback reinforces visual animations
3. **Accessibility-First**: Reduce Motion fallbacks replace complex animations with simple fades
4. **Performance-Conscious**: 60 FPS target, optimized for iPhone 13 and above
5. **Purpose-Driven Motion**: Every animation serves a functional purpose (feedback, navigation, attention)

**Technology Stack**:
- iOS 26.0+ (primary), iOS 25.0+ (fallback)
- SwiftUI spring animations (response/dampingFraction)
- Sensory feedback (iOS 17+)
- Reduce Motion support (accessibility)

---

## Spring Animation Presets

All animations use spring physics with predefined presets for consistency. Presets differ by response time (how fast) and damping fraction (how bouncy).

**Physics Parameters**:
- **Response**: How quickly the spring reaches its target (seconds). Lower = faster.
- **Damping Fraction**: How much the spring oscillates. Lower = more bouncy. 1.0 = no bounce (critically damped).
- **Blend Duration**: Smooths transitions between animations. Default: 0 (instant).

### Brand Presets

| Preset | Response | Damping | Bounce Level | Use Case |
|--------|----------|---------|--------------|----------|
| **brandSnappy** | 0.3s | 0.6 | Medium bounce | Button taps, tab switches, quick interactions |
| **brandDefault** | 0.4s | 0.7 | Subtle bounce | Screen transitions, card entrance, standard animations |
| **brandBouncy** | 0.5s | 0.5 | High bounce | Celebratory moments, success animations, playful feedback |
| **brandGentle** | 0.6s | 0.8 | Minimal bounce | Background updates, subtle state changes, non-distracting |

**Swift Extension**:

```swift
import SwiftUI

extension Animation {
    // MARK: - Abundance Animation Presets

    /// Snappy animation for quick interactions
    /// - Response: 0.3s (fast)
    /// - Damping: 0.6 (medium bounce)
    /// - Usage: Button taps, tab switches, immediate feedback
    static let brandSnappy = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Default animation for standard transitions
    /// - Response: 0.4s (balanced)
    /// - Damping: 0.7 (subtle bounce)
    /// - Usage: Screen transitions, card entrance, modal presentation
    static let brandDefault = Animation.spring(response: 0.4, dampingFraction: 0.7)

    /// Bouncy animation for celebratory moments
    /// - Response: 0.5s (slower)
    /// - Damping: 0.5 (high bounce)
    /// - Usage: Success animations, scan completion, save confirmation
    static let brandBouncy = Animation.spring(response: 0.5, dampingFraction: 0.5)

    /// Gentle animation for subtle updates
    /// - Response: 0.6s (slow)
    /// - Damping: 0.8 (minimal bounce)
    /// - Usage: Background updates, Firestore sync, non-critical changes
    static let brandGentle = Animation.spring(response: 0.6, dampingFraction: 0.8)
}
```

**Usage Examples**:

```swift
// Button press (snappy feedback)
Button("Save") { }
    .scaleEffect(isPressed ? 0.96 : 1.0)
    .animation(.brandSnappy, value: isPressed)

// Card entrance (default transition)
ItemCard(item: item)
    .opacity(isVisible ? 1.0 : 0.0)
    .scaleEffect(isVisible ? 1.0 : 0.9)
    .animation(.brandDefault, value: isVisible)

// Success celebration (bouncy)
Image(systemName: "checkmark.circle.fill")
    .scaleEffect(showSuccess ? 1.2 : 0.0)
    .animation(.brandBouncy, value: showSuccess)

// Background update (gentle, non-distracting)
Text("\(itemCount) items")
    .opacity(isLoading ? 0.5 : 1.0)
    .animation(.brandGentle, value: isLoading)
```

---

## Sensory Feedback Types

Haptic feedback reinforces visual animations, providing tactile confirmation of interactions. All feedback uses SwiftUI's `.sensoryFeedback()` modifier (iOS 17+).

**Available Feedback Types**:

| Type | Weight/Intensity | Use Case | Example |
|------|------------------|----------|---------|
| **impact(weight:)** | .light, .medium, .heavy | Button presses, taps, physical interactions | Primary button tap (.medium) |
| **selection** | N/A | Tab switches, picker changes, segmented control | Tab bar selection |
| **success** | N/A | Successful actions, validation passes, save complete | Item saved successfully |
| **warning** | N/A | Destructive actions, caution prompts | Delete confirmation |
| **error** | N/A | Validation failures, network errors | Form validation fails |

**Swift Implementation**:

```swift
import SwiftUI

// MARK: - Button Press (Impact)
Button("Capture Photo") {
    capturePhoto()
}
.sensoryFeedback(.impact(weight: .medium), trigger: isCapturing)

// MARK: - Tab Switch (Selection)
FloatingTabBar(selectedTab: $selectedTab)
// Tab button implementation:
Button {
    selectedTab = tab
} label: {
    // ...
}
.sensoryFeedback(.selection, trigger: selectedTab == tab)

// MARK: - Success Feedback
Button("Save Item") {
    saveItem()
}
.sensoryFeedback(.success, trigger: isSaved)

// MARK: - Warning Feedback (Destructive Action)
Button("Delete Item", role: .destructive) {
    deleteItem()
}
.sensoryFeedback(.warning, trigger: isDeleting)

// MARK: - Error Feedback
TextField("Name", text: $name)
    .onChange(of: name) { oldValue, newValue in
        if newValue.isEmpty {
            isInvalid = true
        }
    }
    .sensoryFeedback(.error, trigger: isInvalid)
```

**Platform Note**: iPad does NOT support haptic feedback. Sensory feedback triggers silently on iPad but works on iPhone.

---

## Transition Styles

SwiftUI transitions for presenting/dismissing views, with spring animation curves.

### Navigation Transitions

| Transition | Animation | Use Case |
|------------|-----------|----------|
| **Push/Pop** | `.brandDefault` | Screen navigation (Catalog → Item Detail) |
| **Sheet** | `.brandDefault` | Modal presentation (Edit Item, Export Options) |
| **Fullscreen Cover** | `.brandDefault` | Full takeover (Camera Capture, Onboarding) |
| **Fade** | `.brandGentle` | Content updates, loading states |
| **Scale** | `.brandSnappy` | Button feedback, contextual popovers |

**Swift Implementation**:

```swift
// MARK: - Push Navigation
NavigationLink(destination: ItemDetailView(item: item)) {
    ItemCard(item: item)
}
// Uses default NavigationStack transition with .brandDefault curve

// MARK: - Sheet Presentation
.sheet(isPresented: $showEditModal) {
    EditItemView(item: $item)
        .presentationDetents([.large])
        .presentationBackground(.ultraThickMaterial)
}
// Spring curve automatically applied by SwiftUI

// MARK: - Fade Transition
if isLoading {
    ProgressView()
        .transition(.opacity)
        .animation(.brandGentle, value: isLoading)
}

// MARK: - Scale Transition
if showPopover {
    ContextMenu {
        // Menu items
    }
    .transition(.scale.combined(with: .opacity))
    .animation(.brandSnappy, value: showPopover)
}
```

---

## Microinteractions Catalog

Small, purposeful animations that provide feedback and delight.

### 1. Button Press Feedback

**Visual**: Scale down + opacity reduction
**Haptic**: .impact(weight: .medium)
**Duration**: 150ms (.brandSnappy)

```swift
struct PrimaryButton: View {
    @State private var isPressed = false

    var body: some View {
        Button(action: handleTap) {
            Text("Save")
                .padding()
                .background(Color.accentPrimary, in: Capsule())
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.brandSnappy, value: isPressed)
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
    }

    func handleTap() {
        isPressed = true
        // Perform action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isPressed = false
        }
    }
}
```

**Visual Mockup**:

```
Normal State:          Pressed State:
┌──────────┐          ┌─────────┐
│   Save   │    →     │  Save   │  (96% scale, 80% opacity)
└──────────┘          └─────────┘
```

---

### 2. Card Entrance Animation

**Visual**: Slide up + fade in + scale
**Haptic**: None (passive animation)
**Duration**: 400ms (.brandDefault)

```swift
struct ItemCard: View {
    @State private var isVisible = false

    var body: some View {
        cardContent
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .offset(y: isVisible ? 0 : 20)
            .animation(.brandDefault, value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}
```

**Visual Mockup**:

```
Initial (0ms):        Mid (200ms):          Final (400ms):
   [Hidden]              [Fading]            ┌─────────┐
   20pt below            10pt below          │  Card   │
   90% scale             95% scale           │ Content │
   0% opacity            50% opacity         └─────────┘
                                             0pt offset
                                             100% scale
                                             100% opacity
```

---

### 3. Loading Shimmer Effect

**Visual**: Animated gradient sweep (left to right)
**Haptic**: None (passive)
**Duration**: Continuous loop

```swift
struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask {
                RoundedRectangle(cornerRadius: 12)
                    .fill()
                    .offset(x: phase)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}
```

**Visual Mockup**:

```
0s:                   0.75s:                1.5s (loop):
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│▓░░░░░░░░░░░░░│  →   │░░░░░▓░░░░░░░░│  →   │░░░░░░░░░░▓░░░│
└──────────────┘      └──────────────┘      └──────────────┘
Gradient sweeps left to right continuously
```

---

### 4. Success Checkmark Animation

**Visual**: Scale up + bounce + rotate
**Haptic**: .success
**Duration**: 500ms (.brandBouncy)

```swift
struct SuccessCheckmark: View {
    @State private var showCheckmark = false

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 64))
            .foregroundStyle(Color.successColor)
            .scaleEffect(showCheckmark ? 1.0 : 0.0)
            .rotationEffect(.degrees(showCheckmark ? 0 : -90))
            .animation(.brandBouncy, value: showCheckmark)
            .sensoryFeedback(.success, trigger: showCheckmark)
            .onAppear {
                showCheckmark = true
            }
    }
}
```

**Visual Mockup**:

```
0ms:       150ms:     300ms:     500ms:
 [none]      ╱        ✓✓       ✓
           ╱         (overshoot) (settle)
         0.3 scale   1.2 scale   1.0 scale
         -90° rot    -20° rot    0° rot
```

---

### 5. Error Shake Animation

**Visual**: Horizontal oscillation (shake)
**Haptic**: .error
**Duration**: 400ms (custom shake)

```swift
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {
    func shake(trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }
}

// Usage:
TextField("Name", text: $name)
    .shake(trigger: shakeCount)
    .sensoryFeedback(.error, trigger: shakeCount)
    .onChange(of: isInvalid) { _, invalid in
        if invalid {
            shakeCount += 1
        }
    }
```

**Visual Mockup**:

```
0ms:           100ms:        200ms:        300ms:        400ms:
┌────────┐     ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│  Name  │  →  │ Name   │ →  │ Name   │ →  │  Name  │ →  │  Name  │
└────────┘     └────────┘    └────────┘    └────────┘    └────────┘
   Center      +10pt right   -10pt left    +5pt right     Center

Horizontal oscillation (3 shakes) with damping
```

---

### 6. Pull-to-Refresh Animation

**Visual**: Spinner rotation + scale
**Haptic**: .selection (on trigger)
**Duration**: Continuous while loading

```swift
struct PullToRefreshView: View {
    @State private var isRefreshing = false
    @State private var rotation: Double = 0

    var body: some View {
        ScrollView {
            VStack {
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .rotationEffect(.degrees(rotation))
                        .sensoryFeedback(.selection, trigger: isRefreshing)
                        .onAppear {
                            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                }

                // Content
            }
            .refreshable {
                isRefreshing = true
                await refreshData()
                isRefreshing = false
            }
        }
    }
}
```

---

### 7. Badge Pulse Animation

**Visual**: Scale pulse (1.0 → 1.1 → 1.0)
**Haptic**: None (passive)
**Duration**: 1.5s continuous loop

```swift
struct PulseBadge: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(Color.errorColor)
            .frame(width: 12, height: 12)
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}
```

**Visual Mockup**:

```
0s:        0.75s:      1.5s:
  ●    →     ●●    →     ●
 1.0       1.1        1.0
scale     scale      scale
```

---

## Reduce Motion Fallbacks

When users enable Reduce Motion (Settings → Accessibility → Motion → Reduce Motion), all animations must simplify to avoid motion sickness or distraction.

**Fallback Strategy**:
- ❌ Replace: Spring animations, parallax, continuous loops, bounces
- ✅ Keep: Simple fades, instant state changes, static positions

### Implementation Pattern

```swift
import SwiftUI

@Environment(\.accessibilityReduceMotion) private var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .brandDefault
}

// Usage:
Text("Content")
    .scaleEffect(isActive ? 1.1 : 1.0)
    .animation(animation, value: isActive) // nil = instant, no animation
```

### Reduce Motion Mapping

| Standard Animation | Reduce Motion Fallback |
|-------------------|------------------------|
| Spring scale + fade | Instant fade only |
| Bouncy success checkmark | Instant appearance |
| Shake error animation | Red border flash (instant) |
| Parallax scroll effect | Static background |
| Continuous shimmer | Static placeholder |
| Pull-to-refresh rotation | Static spinner |
| Badge pulse | Static badge |

**Example: Button Press**

```swift
struct PrimaryButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    var body: some View {
        Button(action: handleTap) {
            Text("Save")
        }
        .scaleEffect(reduceMotion ? 1.0 : (isPressed ? 0.96 : 1.0))
        .opacity(isPressed ? 0.8 : 1.0) // Opacity still animates (instant fade)
        .animation(reduceMotion ? nil : .brandSnappy, value: isPressed)
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
    }
}
```

**Example: Card Entrance**

```swift
struct ItemCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var body: some View {
        cardContent
            .opacity(isVisible ? 1.0 : 0.0) // Fade works in both modes
            .scaleEffect(reduceMotion ? 1.0 : (isVisible ? 1.0 : 0.9)) // Scale disabled
            .offset(y: reduceMotion ? 0 : (isVisible ? 0 : 20)) // Slide disabled
            .animation(reduceMotion ? .linear(duration: 0.2) : .brandDefault, value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}
```

---

## Performance Guidelines

### 60 FPS Target

All animations must maintain 60 FPS (16.67ms per frame) on target devices (iPhone 13 and above).

**Performance Optimization Strategies**:

1. **Limit Material Layers**: Max 3 layered materials per screen (GPU intensive)
2. **Use DrawingGroup**: For complex compositing (shadows, blurs)
3. **Avoid Layout Animations**: Animate transforms (scale, offset) instead of frame/padding
4. **Batch Animations**: Use single `.animation()` modifier for multiple properties
5. **Profile with Instruments**: Use Core Animation tool to identify bottlenecks

**Example: Optimized Button Animation**

```swift
// ✅ Good: Animates transform (GPU-accelerated)
Button("Save")
    .scaleEffect(isPressed ? 0.96 : 1.0)
    .animation(.brandSnappy, value: isPressed)

// ❌ Bad: Animates layout (CPU-heavy)
Button("Save")
    .padding(isPressed ? 14 : 16) // Forces layout recalculation
    .animation(.brandSnappy, value: isPressed)
```

**Example: DrawingGroup for Complex Shadows**

```swift
// ✅ Good: DrawingGroup optimizes multi-layer rendering
ItemCard(item: item)
    .shadow(color: .black.opacity(0.1), radius: 8)
    .shadow(color: Color.accentPrimary.opacity(0.3), radius: 12)
    .drawingGroup() // Composites shadows into single layer
```

---

## Animation Testing Guidelines

### Manual Testing Checklist

- [ ] **Visual Smoothness**: All animations feel fluid, no janky frame drops
- [ ] **Timing Consistency**: Same animation types use same preset across app
- [ ] **Haptic Feedback**: Haptics trigger at correct moment, feel appropriate
- [ ] **Reduce Motion**: All animations disabled or simplified when enabled
- [ ] **Performance**: Maintain 60 FPS on iPhone 13 with 20+ cards on screen
- [ ] **Battery Impact**: Animations don't drain battery (test with Instruments Energy Log)

### Reduce Motion Testing

1. **Enable Reduce Motion**: Settings → Accessibility → Motion → Reduce Motion
2. **Navigate all screens**: Verify complex animations are disabled
3. **Check critical feedback**: Ensure button taps still provide visual feedback (opacity change)
4. **Test loading states**: Verify static placeholders replace animated shimmers

### Automated Testing

```swift
import XCTest
@testable import Abundance

final class AnimationTests: XCTestCase {
    func testReduceMotionDisablesSpringAnimations() {
        let view = PrimaryButton(title: "Save", action: {})
        let hostingController = UIHostingController(rootView: view)

        // Enable Reduce Motion
        hostingController.view.accessibilityReduceMotion = true

        // Verify animations are nil
        XCTAssertNil(view.animation)
    }

    func testSensoryFeedbackTriggersOnInteraction() {
        let view = PrimaryButton(title: "Save", action: {})
        let expectation = XCTestExpectation(description: "Haptic triggered")

        // Simulate button tap
        view.handleTap()

        // Verify sensory feedback triggered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }
}
```

---

## Common Patterns

### Pattern 1: Button Tap Feedback

```swift
struct AnimatedButton: View {
    @State private var isPressed = false

    var body: some View {
        Button(action: handleTap) {
            Text("Tap Me")
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.brandSnappy, value: isPressed)
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
    }

    func handleTap() {
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isPressed = false
        }
    }
}
```

---

### Pattern 2: Conditional Appearance

```swift
struct ConditionalView: View {
    @State private var isVisible = false

    var body: some View {
        if isVisible {
            contentView
                .transition(.scale.combined(with: .opacity))
                .animation(.brandDefault, value: isVisible)
        }
    }
}
```

---

### Pattern 3: List Item Staggered Entrance

```swift
struct StaggeredList: View {
    @State private var visibleIndices: Set<Int> = []

    var body: some View {
        List {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ItemCard(item: item)
                    .opacity(visibleIndices.contains(index) ? 1.0 : 0.0)
                    .offset(y: visibleIndices.contains(index) ? 0 : 20)
                    .animation(.brandDefault.delay(Double(index) * 0.05), value: visibleIndices)
                    .onAppear {
                        visibleIndices.insert(index)
                    }
            }
        }
    }
}
```

---

### Pattern 4: Skeleton Loading

```swift
struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 160)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 20)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 16)
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}
```

---

## Animation Anti-Patterns

### ❌ Don't: Overuse Bounce

```swift
// ❌ Bad: Every element bounces (chaotic)
VStack {
    Text("Title").animation(.brandBouncy, value: isVisible)
    Text("Body").animation(.brandBouncy, value: isVisible)
    Button("CTA") { }.animation(.brandBouncy, value: isPressed)
}
```

**Why**: Too much bounce is distracting and unprofessional.

**Fix**: Use bounce sparingly for celebratory moments only.

---

### ❌ Don't: Animate Layout Properties

```swift
// ❌ Bad: Animating padding (CPU-heavy)
Text("Content")
    .padding(isActive ? 20 : 16)
    .animation(.brandDefault, value: isActive)
```

**Why**: Forces layout recalculation, drops frames.

**Fix**: Animate transforms instead.

```swift
// ✅ Good: Animate scale (GPU-accelerated)
Text("Content")
    .scaleEffect(isActive ? 1.1 : 1.0)
    .animation(.brandDefault, value: isActive)
```

---

### ❌ Don't: Ignore Reduce Motion

```swift
// ❌ Bad: Always animates, ignores accessibility
Text("Content")
    .scaleEffect(isActive ? 1.1 : 1.0)
    .animation(.brandBouncy, value: isActive) // Always animates
```

**Why**: Violates accessibility, causes motion sickness.

**Fix**: Check Reduce Motion environment variable.

```swift
// ✅ Good: Respects Reduce Motion
@Environment(\.accessibilityReduceMotion) var reduceMotion

Text("Content")
    .scaleEffect(isActive ? 1.1 : 1.0)
    .animation(reduceMotion ? nil : .brandBouncy, value: isActive)
```

---

## Resources

### Internal Documents
- docs/design/DESIGN-031-swiftui-component-library.md (component animations)
- docs/design/DESIGN-032-color-system-design-tokens.md (color transitions)
- docs/design/DESIGN-033-typography-specifications.md (text animations)
- shared/abundance-brand/abundance-core-style-guidelines.md (motion principles)

### Apple Documentation
- Spring Animations: https://developer.apple.com/documentation/swiftui/animation/spring(response:dampingfraction:blendduration:)
- Sensory Feedback: https://developer.apple.com/documentation/swiftui/sensoryfeedback
- Reduce Motion: https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion
- Transitions: https://developer.apple.com/documentation/swiftui/view/transition(_:)
- GeometryEffect: https://developer.apple.com/documentation/swiftui/geometryeffect

### External Resources
- iOS Animation Principles: https://www.nngroup.com/articles/animation-usability/
- Spring Physics Calculator: https://springsimulator.com/
- Motion Design Guidelines: https://m3.material.io/styles/motion/overview

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial animation system with spring presets and Reduce Motion support | iOS UI/UX Designer & SwiftUI Specialist |

---

**Status**: ✅ **APPROVED**

**Next Steps**: Implement animations across all components and screens in Stage 3.1 iOS Implementation

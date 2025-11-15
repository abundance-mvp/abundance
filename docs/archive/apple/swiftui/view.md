# SwiftUI View Protocol: Complete API Reference

**Source**: https://sosumi.ai/documentation/swiftui/view
**Fetched**: 2025-11-02

## Overview

The `View` protocol is the foundational type for creating custom user interfaces in SwiftUI. It provides a mechanism to define reusable interface components and offers a comprehensive set of modifiers for configuring their appearance and behavior.

**Definition:** `@MainActor @preconcurrency protocol View`

## Availability

Supported across all Apple platforms:
- iOS 13.0+
- iPadOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+
- visionOS 1.0+
- Mac Catalyst 13.0+

## Core Requirements

### Required Property: `body`

The `body` computed property is mandatory for any type conforming to `View`. It defines the view's content and structure.

```swift
var body: some View { ... }
```

### Associated Type: `Body`

Represents the concrete type returned by the `body` property, enabling SwiftUI's type-safe view composition system.

## Basic Pattern: Creating Custom Views

```swift
struct MyView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

## View Composition Strategy

Views are constructed by combining built-in SwiftUI components (like `Text`, `Image`, `Button`) with custom views into a hierarchical structure. This compositional approach enables:

- **Reusability:** Define once, use throughout your app
- **Modularity:** Break complex UIs into manageable pieces
- **Maintainability:** Update components in isolation

## Modifier System

The `View` protocol provides default protocol methods that wrap view instances. Modifiers follow a chainable pattern:

```swift
Text("Hello, World!")
    .opacity(0.5)
    .foregroundColor(.blue)
```

Each modifier returns a new view with applied characteristics, enabling fluent composition.

## Modifier Categories

### Layout & Sizing
Configure frame, padding, alignment, spacing, and view positioning within hierarchies.

### Appearance
Control foreground/background styles, visibility, and visual rendering.

### Accessibility
Make interfaces inclusive through semantic descriptions and interaction information.

### Text & Symbols
Manage text rendering, selection, formatting, and symbol appearance.

### Interactivity
Define gesture handlers, state management, and event responses.

### Presentation
Control modals, popovers, sheets, and conditional view display.

### Graphics & Rendering
Apply transformations, effects, masking, and custom drawing.

### Auxiliary Views
Add toolbars, context menus, and supporting interface elements.

## Main Actor Isolation

Types conforming to `View` inherit `@preconcurrency @MainActor` isolation by default, ensuring UI operations execute on the main thread. To opt out, declare conformance in an extension rather than the original type declaration.

## Practical Usage Considerations

- **View State:** Use `@State`, `@StateObject`, and other property wrappers to manage data
- **Reusability:** Extract repeated view patterns into custom view types
- **Performance:** Leverage `EquatableView` and `@ViewBuilder` for optimization
- **Preview Support:** Use `#Preview` macro for iterative development in Xcode

## Inheritance Hierarchy

The `View` protocol is inherited by several other protocols including `Shape`, `DynamicViewContent`, and representable types for platform-specific integration (`UIViewRepresentable`, `NSViewRepresentable`).

Hundreds of concrete types conform to `View`, from basic components (`Text`, `Button`, `Image`) to complex containers (`List`, `NavigationStack`, `Form`).

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*

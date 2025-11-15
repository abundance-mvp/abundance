# @State Property Wrapper API Documentation

**Source**: https://sosumi.ai/documentation/swiftui/state
**Fetched**: 2025-11-02

## Overview

The `@State` property wrapper is a SwiftUI mechanism for managing view-local state. As Apple's documentation notes, it serves as "a property wrapper type that can read and write a value managed by SwiftUI."

## Availability

Supported across iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, and watchOS 6.0+.

## Declaration

```swift
@frozen @propertyWrapper struct State<Value>
```

## Purpose and Core Concepts

State serves as the authoritative source for value-type data within a view hierarchy. When a state property changes, SwiftUI automatically updates dependent views.

### Primary Use Cases

- Storing local view data
- Managing simple value types (Bool, String, Int, etc.)
- Single-view ownership of state

## Usage Patterns

### Basic State Declaration

```swift
struct PlayButton: View {
    @State private var isPlaying: Bool = false

    var body: some View {
        Button(isPlaying ? "Pause" : "Play") {
            isPlaying.toggle()
        }
    }
}
```

Key guideline: Always declare state as `private` to prevent external initialization conflicts.

### Sharing State with Subviews

Pass bindings (prefixed with `$`) to enable child views to modify state:

```swift
struct PlayerView: View {
    @State private var isPlaying: Bool = false

    var body: some View {
        PlayButton(isPlaying: $isPlaying)
    }
}
```

## Storage and Access

- **wrappedValue**: Direct access to the underlying value
- **projectedValue**: Binding representation, accessed via `$` prefix
- Swift enables shorthand access directly to state instances

## Working with Observable Objects

State can store objects decorated with the `@Observable` macro:

```swift
@Observable
class Library {
    var name = "My library"
}

struct ContentView: View {
    @State private var library = Library()

    var body: some View {
        LibraryView(library: library)
    }
}
```

### Performance Considerations

Avoid expensive initialization operations. Defer object creation using `.task()` modifiers when performance matters.

## Important Limitations

The documentation emphasizes that storing `ObservableObject` protocol conformers in state has drawbacks. Views update only when the reference itself changes, not when published properties update. Use `@StateObject` for proper change tracking instead.

## Thread Safety

State properties can be safely mutated from any thread.

## Protocols Conformed To

- DynamicProperty
- Sendable
- SendableMetatype

## Initialization Methods

- `init(wrappedValue:)` — Stores an initial wrapped value
- `init(initialValue:)` — Stores an initial value
- `init()` — Creates state without an initial value

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*

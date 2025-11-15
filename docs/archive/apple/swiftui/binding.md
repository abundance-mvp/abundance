# @Binding Property Wrapper - API Reference

**Source**: https://sosumi.ai/documentation/swiftui/binding
**Fetched**: 2025-11-02

## Overview

`@Binding` is a property wrapper enabling two-way connections between data storage and view display. It references a source of truth elsewhere rather than storing data directly.

**Definition:** *"A property wrapper type that can read and write a value owned by a source of truth."*

## Availability

- iOS 13.0+
- iPadOS 13.0+
- Mac Catalyst 13.0+
- macOS 10.15+
- tvOS 13.0+
- visionOS 1.0+
- watchOS 6.0+

## Core Pattern: Two-Way Data Flow

### Child Component with @Binding

A child view declares a binding property to receive data changes:

```swift
struct PlayButton: View {
    @Binding var isPlaying: Bool

    var body: some View {
        Button(isPlaying ? "Pause" : "Play") {
            isPlaying.toggle()
        }
    }
}
```

### Parent Component with @State

The parent establishes the source of truth using `@State`:

```swift
struct PlayerView: View {
    var episode: Episode
    @State private var isPlaying: Bool = false

    var body: some View {
        VStack {
            Text(episode.title)
                .foregroundStyle(isPlaying ? .primary : .secondary)
            PlayButton(isPlaying: $isPlaying)
        }
    }
}
```

## $ Prefix for Binding Projection

Applying the `$` prefix to a state property returns its projected value—specifically, *"a binding to the value"* for state properties. This establishes the two-way connection.

## Key Methods for Creating Bindings

- **`init(get:set:)`** – Creates a binding with custom read/write closures
- **`constant(_:)`** – Creates a binding with an immutable value
- **`init(_:)`** – Projects base values to hashable values
- **`init(projectedValue:)`** – Derives bindings from other bindings

## Concurrency Considerations

Bindings conform to `Sendable` when their wrapped value type does. While safe to pass between concurrency domains, reading/writing from different domains may require careful handling. SwiftUI issues runtime warnings for potentially unsafe access patterns.

## Related Property Wrappers

For types conforming to the `Observable` protocol, use `@Bindable` instead of `@Binding`.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*

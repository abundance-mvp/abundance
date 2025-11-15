# NSPersistentContainer API Documentation

**Source**: https://sosumi.ai/documentation/coredata/nspersistentcontainer
**Fetched**: 2025-11-02

## Overview

`NSPersistentContainer` is a foundational Core Data class that encapsulates and simplifies management of the Core Data stack. It abstracts away the complexity of initializing and coordinating three essential components: the managed object model, persistent store coordinator, and managed object context.

**Availability:** iOS 10.0+, iPadOS 10.0+, Mac Catalyst 13.1+, macOS 10.12+, tvOS 10.0+, visionOS 1.0+, watchOS 3.0+

## Class Hierarchy

- **Inherits from:** NSObject
- **Inherited by:** NSPersistentCloudKitContainer
- **Conforms to:** CVarArg, CustomDebugStringConvertible, CustomStringConvertible, Equatable, Hashable, NSObjectProtocol, Sendable, SendableMetatype

## Initialization Methods

### Creating Instances

```swift
init(name:)
// Creates a container with the specified name
```

```swift
init(name:managedObjectModel:)
// Establishes a container using a provided name and custom managed object model
```

## Core Properties

### Configuration Access

| Property | Purpose |
|----------|---------|
| `name` | The container's identifier |
| `managedObjectModel` | The underlying data model defining entities and relationships |
| `persistentStoreCoordinator` | The coordinator managing persistent store interactions |

### Store Management

| Property | Purpose |
|----------|---------|
| `persistentStoreDescriptions` | Configuration details for all persistent stores |
| `defaultDirectoryURL` (type property/method) | Directory location where persistent stores are stored |

### Context Access

| Property | Purpose |
|----------|---------|
| `viewContext` | Main-thread managed object context for UI operations |

## Key Methods

### Store Initialization

```swift
loadPersistentStores(completionHandler:)
// Initializes and prepares persistent stores for use
```

### Context Management

```swift
newBackgroundContext()
// Generates a new managed object context operating on a private queue
```

```swift
performBackgroundTask(_:)
// Executes a closure with an ephemeral managed object context on a private queue
```

## Concurrency Support

The container implements `Sendable`, enabling safe use across concurrent contexts. It provides:
- **Main queue context** via `viewContext` for UI updates
- **Private queue contexts** via `newBackgroundContext()` for background operations
- **Ephemeral contexts** through `performBackgroundTask(_:)` for temporary work

## Usage Pattern

Typical initialization follows this flow:
1. Create container instance
2. Configure `persistentStoreDescriptions` if needed
3. Call `loadPersistentStores()` to initialize the stack
4. Access `viewContext` for main-thread operations
5. Use `newBackgroundContext()` or `performBackgroundTask()` for background work

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*

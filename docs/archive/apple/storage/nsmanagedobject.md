# NSManagedObject API Reference

**Source**: https://sosumi.ai/documentation/coredata/nsmanagedobject
**Fetched**: 2025-11-02

## Overview

NSManagedObject serves as the foundational class for all Core Data model objects. Each managed object maintains an associated entity description providing metadata about attributes and relationships, plus a reference to its managed object context for tracking changes.

**Key principle**: "The base class that all Core Data model objects inherit from."

## Availability

- iOS 3.0+
- iPadOS 3.0+
- macOS 10.4+
- Mac Catalyst 13.1+
- tvOS (undefined+)
- visionOS 1.0+
- watchOS 2.0+

## Declaration

```swift
nonisolated class NSManagedObject
```

## Core Concepts

### Data Storage Pattern

NSManagedObject functions similarly to a dictionary—a generic container providing efficient storage for entity-defined properties. It supports common attribute types (string, date, number) but requires transformable attributes or custom subclasses for unsupported types like colors or C structures.

### Faulting Mechanism

Managed objects may exist as "faults"—objects whose property values haven't been loaded from the persistent store. Accessing persistent properties automatically triggers fault resolution, potentially incurring performance costs. Safe operations that don't fire faults include equality checks, hash operations, and accessing metadata like entity, objectID, and context.

## Initialization Methods

### Creating Managed Objects

```swift
init(entity: NSEntityDescription, insertInto: NSManagedObjectContext?)
// Designated initializer - required for direct instantiation

init(context: NSManagedObjectContext)
// Convenience initializer for subclasses
```

**Important constraint**: Must use designated initializer when instantiating directly. Changes made in `init(entity:insertInto:)` may not be tracked by the context.

## Identity and State Properties

### Getting Identity

| Property | Purpose |
|----------|---------|
| `entity` | The entity description of the managed object |
| `objectID` | Unique object identifier |
| `entity()` | Returns entity description for the subclass |

### State Information

| Property | Description |
|----------|-------------|
| `managedObjectContext` | Associated context managing this object |
| `hasChanges` | Boolean indicating insertions, deletions, or unsaved changes |
| `isInserted` | Boolean for insertion in context |
| `isUpdated` | Boolean for unsaved changes |
| `isDeleted` | Boolean for pending deletion on next save |
| `isFault` | Boolean indicating unloaded fault state |
| `faultingState` | Detailed fault status |
| `hasPersistentChangedValues` | Boolean for persistent-store changes |

## Lifecycle Hooks

### Initialization Phases

```swift
awakeFromInsert()      // After initial object creation
awakeFromFetch()       // After loading from persistent store
awake(fromSnapshotEvents:)  // When fulfilling from snapshot
```

### Save Operations

```swift
willSave()    // Before context save operation
didSave()     // After successful save completion
```

### Deletion

```swift
prepareForDeletion()   // Before removal from store
```

### Fault Conversion

```swift
willTurnIntoFault()    // Before fault conversion
didTurnIntoFault()     // After becoming a fault
```

**Critical guidance**: Implement lifecycle methods by calling superclass implementations first. Use `didTurnIntoFault()` instead of `dealloc` for cleanup operations.

## Change Tracking

### Accessing Changes

```swift
changedValues()                    // Dictionary of changed properties
changedValuesForCurrentEvent()      // Current event changes
committedValues(forKeys:)           // Last fetched/saved values
```

## Validation Methods

### Validation Patterns

```swift
validateValue(_:forKey:)    // Validates single property
validateForInsert()          // Pre-insertion validation
validateForUpdate()          // Pre-update validation
validateForDelete()          // Pre-deletion validation
```

**Implementation pattern**: Implement custom validators as `validate<Key>:error:` methods rather than overriding `validateValue(_:forKey:)`. When validating multiple properties, collect errors in an array using the `NSDetailedErrorsKey`.

## Key-Value Coding Support

```swift
value(forKey:)             // Get property value
setValue(_:forKey:)        // Set property value
primitiveValue(forKey:)    // Access internal storage directly
setPrimitiveValue(_:forKey:)  // Modify internal storage
```

## Critical Override Constraints

### Methods You Must Not Override

Core Data requires exclusive control over these methods and properties:

- `primitiveValue(forKey:)` / `setPrimitiveValue(_:forKey:)`
- `isEqual(_:)`, `hash`, `superclass`
- `self()`, `class`, `isProxy`
- `isKind(of:)`, `isMember(of:)`, `conforms(to:)`, `responds(to:)`
- `managedObjectContext`, `entity`, `objectID`
- `isInserted`, `isUpdated`, `isDeleted`, `isFault`
- Memory management selectors (`alloc`, `allocWithZone:`, `new`)
- Method introspection (`instancesRespond(to:)`, `method(for:)`, etc.)

### Methods You Shouldn't Override

Avoid overriding these to prevent unpredictable behavior:

- Key-value observing methods (`willChangeValue(forKey:)`, `didChangeValue(forKey:)`)
- `description` (custom implementations may fire faults during debugging)
- `init(entity:insertInto:)` / `dealloc` (lifecycle management)

## Custom Instance Variables

When defining custom instance variables for derived or transient properties, perform cleanup in `didTurnIntoFault()` rather than `dealloc`. This accounts for the deferred deallocation of faulted objects.

## Relationship Operations

```swift
hasFault(forRelationshipNamed:)     // Check if relationship is a fault
objectIDs(forRelationshipNamed:)    // Get related object identifiers
```

## Key-Value Observing Support

```swift
willAccessValue(forKey:)   // Pre-access notification
didAccessValue(forKey:)    // Post-access notification
observationInfo()          // Retrieve observation metadata
setObservationInfo(_:)     // Set observation metadata
```

**Default behavior**: Managed properties don't automatically notify observers (`automaticallyNotifiesObservers` = `false`), while unmanaged properties do (`true`).

## Conformance

NSManagedObject conforms to:
- NSObjectProtocol, NSFetchRequestResult
- CVarArg, Equatable, Hashable
- Copyable, CustomStringConvertible, CustomDebugStringConvertible
- ObservableObject (Combine framework)

## Related Types

- `NSEntityDescription` — Entity metadata
- `NSAttributeDescription` — Attribute specifications
- Validation error codes for handling validation failures

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*

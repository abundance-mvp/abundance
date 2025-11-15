# NSFetchRequest API Documentation

**Source**: https://sosumi.ai/documentation/coredata/nsfetchrequest
**Fetched**: 2025-11-02

## Overview

`NSFetchRequest` is a Core Data class that encapsulates search criteria for retrieving data from a persistent store. It collects information about which entities to fetch, how to filter them, and how to order the results.

**Generic Declaration:**
```swift
class NSFetchRequest<ResultType> where ResultType : NSFetchRequestResult
```

## Availability

- iOS 3.0+
- iPadOS 3.0+
- macOS 10.4+
- Mac Catalyst 13.1+
- tvOS (unspecified version)+
- visionOS 1.0+
- watchOS 2.0+

## Core Purpose

According to the documentation, this class is used to "describe search criteria used to retrieve data from a persistent store." When executed, it always accesses underlying persistent stores to get the most current results.

## Initialization Methods

| Method | Purpose |
|--------|---------|
| `init()` | Creates a new fetch request without entity configuration |
| `init(entityName:)` | Initializes with a specified entity name |

## Key Properties

### Entity Configuration
- **entityName**: The name of the entity to fetch
- **entity**: The `NSEntityDescription` for the fetch request
- **includesSubentities**: Boolean controlling whether subentities appear in results

### Query Constraints
- **predicate**: An `NSPredicate` specifying filter conditions (e.g., filtering by last name)
- **fetchLimit**: Maximum number of objects to return
- **fetchOffset**: Number of results to skip before returning
- **fetchBatchSize**: Batch size for object retrieval optimization
- **affectedStores**: Array of persistent stores to query

### Result Ordering
- **sortDescriptors**: Array of `NSSortDescriptor` objects defining sort order (supports multiple properties)

### Result Configuration
- **resultType**: Controls what the fetch returns (`NSFetchRequestResultType` constants)
- **propertiesToFetch**: Specifies which attributes/relationships to retrieve
- **includesPendingChanges**: Boolean determining whether unsaved context changes are included
- **includesPropertyValues**: Boolean controlling whether property data loads from the store
- **returnsObjectsAsFaults**: Boolean for returning lightweight fault objects
- **shouldRefreshRefetchedobjects**: Boolean to update property values with current persistent store values
- **returnsDistinctResults**: Boolean filtering for unique values only

### Advanced Operations
- **relationshipKeyPathsForPrefetching**: Relationships to eagerly load with the entity
- **propertiesToGroupBy**: Attributes for GROUP BY SQL operations
- **havingPredicate**: Filter predicate for grouped results

## Result Types

The framework supports multiple result formats through `NSFetchRequestResultType`:
- Managed objects (default)
- Managed object IDs
- Dictionary representations
- Count values

## Execution Patterns

### Direct Execution
```swift
let results = try request.execute()
```

### SwiftUI Integration
Use the `@FetchRequest` property wrapper to automatically execute and observe fetch results:

```swift
@FetchRequest(fetchRequest: request) private var items: FetchedResults<ShoppingItem>
```

### Manual Context Execution
Call `perform(_:)` on the managed object context for thread-safe execution.

## Common Configuration Example

```swift
let request = Entity.fetchRequest()
request.fetchLimit = 100
request.predicate = NSPredicate(format: "isChecked = false")
request.sortDescriptors = [NSSortDescriptor(keyPath: \.name, ascending: true)]
```

## Related Classes

- `NSAsynchronousFetchRequest`: For background fetching
- `NSFetchedResultsController`: For managing and displaying dynamic result sets
- `NSAsynchronousFetchResult`: Result container for async operations

## Important Constraints

Fetch requests always access underlying persistent stores when executed, ensuring data freshness. Predefine requests in `NSManagedObjectModel` to create reusable templates with runtime variable substitution.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*

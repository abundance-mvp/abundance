# CODE-EXAMPLE-001: Swift 6 Concurrency Patterns

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**Purpose**: Reference implementations for Swift 6 concurrency in Abundance iOS app

---

## Overview

This document provides Swift 6 concurrency patterns for the Abundance iOS app, following ADR-012 (State Management Strategy) and incorporating Apple best practices from WWDC25/268.

**Key Patterns**:
1. `@MainActor` ViewModels with async/await
2. Task groups for parallel operations
3. Actor isolation for shared state
4. Sendable conformance for data models

---

## Pattern 1: @MainActor ViewModel with async/await

### Purpose
ViewModels update UI state, so they must run on the main thread. `@MainActor` ensures all ViewModel code executes on MainActor, preventing data races.

### Implementation

```swift
import SwiftUI
import Combine

// MARK: - @MainActor ViewModel Example

@MainActor
class CatalogViewModel: ObservableObject {
    // MARK: - Published Properties (trigger UI updates)

    @Published var items: [CatalogItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // MARK: - Dependencies

    private let repository: CatalogRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(repository: CatalogRepository) {
        self.repository = repository
    }

    // MARK: - async/await Methods

    /// Fetch catalog items asynchronously
    /// - Note: This method is async and runs on MainActor
    func fetchItems() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Repository call is async, may run on background thread
            items = try await repository.fetchItems()
        } catch {
            // Error assignment happens on MainActor (UI thread)
            self.error = error
        }
    }

    /// Delete item asynchronously
    /// - Parameter id: Item ID to delete
    func deleteItem(id: String) async {
        do {
            try await repository.deleteItem(id: id)

            // Remove from local array on MainActor
            items.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    /// Refresh items (pull-to-refresh)
    func refresh() async {
        await fetchItems()
    }
}
```

### SwiftUI Usage

```swift
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel

    init(repository: CatalogRepository = FirestoreCatalogRepository()) {
        _viewModel = StateObject(wrappedValue: CatalogViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading items...")
                } else if viewModel.items.isEmpty {
                    ContentUnavailableView("No items", systemImage: "tray")
                } else {
                    List(viewModel.items) { item in
                        CatalogItemRow(item: item)
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteItem(id: item.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Catalog")
            .task {
                // .task runs on MainActor, cancels when view disappears
                await viewModel.fetchItems()
            }
            .refreshable {
                // Pull-to-refresh
                await viewModel.refresh()
            }
            .alert(error: $viewModel.error) // Show error alerts
        }
    }
}
```

### Key Points

✅ **@MainActor on class**: All methods and properties run on main thread
✅ **async methods**: Use `async/await` for asynchronous operations
✅ **@Published updates**: Automatically trigger SwiftUI view updates
✅ **.task modifier**: SwiftUI runs async code, cancels on view disappear
✅ **Error handling**: `do-catch` with error property for UI display

---

## Pattern 2: Task Groups for Parallel Operations

### Purpose
Fetch multiple independent resources concurrently to improve performance.

### Implementation

```swift
import Foundation

// MARK: - Task Group Example

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var catalogItems: [CatalogItem] = []
    @Published var userProfile: User?
    @Published var stats: UserStats?
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let catalogRepository: CatalogRepository
    private let userRepository: UserRepository
    private let statsRepository: StatsRepository

    init(
        catalogRepository: CatalogRepository,
        userRepository: UserRepository,
        statsRepository: StatsRepository
    ) {
        self.catalogRepository = catalogRepository
        self.userRepository = userRepository
        self.statsRepository = statsRepository
    }

    /// Load dashboard data with parallel requests
    func loadDashboard() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Execute 3 API calls in parallel using Task Group
            try await withThrowingTaskGroup(of: DashboardData.self) { group in
                // Task 1: Fetch catalog items
                group.addTask {
                    let items = try await self.catalogRepository.fetchItems()
                    return .catalogItems(items)
                }

                // Task 2: Fetch user profile
                group.addTask {
                    let profile = try await self.userRepository.fetchProfile()
                    return .userProfile(profile)
                }

                // Task 3: Fetch user stats
                group.addTask {
                    let stats = try await self.statsRepository.fetchStats()
                    return .userStats(stats)
                }

                // Collect results as they complete
                for try await result in group {
                    switch result {
                    case .catalogItems(let items):
                        self.catalogItems = items
                    case .userProfile(let profile):
                        self.userProfile = profile
                    case .userStats(let stats):
                        self.stats = stats
                    }
                }
            }
        } catch {
            self.error = error
        }
    }
}

// MARK: - Task Group Result Enum

enum DashboardData: Sendable {
    case catalogItems([CatalogItem])
    case userProfile(User)
    case userStats(UserStats)
}
```

### Key Points

✅ **withThrowingTaskGroup**: Run multiple async tasks concurrently
✅ **group.addTask**: Add independent tasks to the group
✅ **for try await**: Collect results as tasks complete
✅ **Sendable enum**: Results must conform to Sendable for cross-actor passing
✅ **Error handling**: Any task failure throws, cancels remaining tasks

### Performance Benefit

**Sequential** (slow):
```swift
let items = try await catalogRepository.fetchItems()      // 500ms
let profile = try await userRepository.fetchProfile()     // 300ms
let stats = try await statsRepository.fetchStats()        // 200ms
// Total: 1000ms
```

**Parallel** (fast):
```swift
try await withThrowingTaskGroup { ... }
// Total: ~500ms (slowest task)
```

---

## Pattern 3: Actor for Shared State Management

### Purpose
Actors provide thread-safe access to mutable state without manual locking.

### Implementation

```swift
import UIKit

// MARK: - Actor for Image Cache

actor ImageCacheActor {
    // MARK: - Private State (actor-isolated)

    private var cache: [String: UIImage] = [:]
    private var maxCacheSize: Int = 100

    // MARK: - Public Methods (async, actor-isolated)

    /// Get cached image for URL
    /// - Parameter url: Image URL
    /// - Returns: Cached UIImage, or nil if not cached
    func image(for url: URL) async -> UIImage? {
        return cache[url.absoluteString]
    }

    /// Store image in cache
    /// - Parameters:
    ///   - image: UIImage to cache
    ///   - url: Image URL key
    func setImage(_ image: UIImage, for url: URL) async {
        // Evict oldest entry if cache full
        if cache.count >= maxCacheSize {
            let oldestKey = cache.keys.first
            cache.removeValue(forKey: oldestKey!)
        }

        cache[url.absoluteString] = image
    }

    /// Clear all cached images
    func clearCache() async {
        cache.removeAll()
    }

    /// Get cache statistics
    /// - Returns: Cache size and memory usage
    func cacheStats() async -> (count: Int, size: String) {
        let count = cache.count
        let bytes = cache.values.reduce(0) { total, image in
            guard let data = image.pngData() else { return total }
            return total + data.count
        }
        let megabytes = Double(bytes) / 1024 / 1024
        return (count, String(format: "%.2f MB", megabytes))
    }
}
```

### Usage in ViewModel

```swift
@MainActor
class ImageLoaderViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading: Bool = false

    private let imageCache: ImageCacheActor

    init(imageCache: ImageCacheActor = .shared) {
        self.imageCache = imageCache
    }

    func loadImage(url: URL) async {
        isLoading = true
        defer { isLoading = false }

        // Check cache first (async call to actor)
        if let cached = await imageCache.image(for: url) {
            self.image = cached
            return
        }

        // Download if not cached
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let downloaded = UIImage(data: data) else { return }

            // Store in cache (async call to actor)
            await imageCache.setImage(downloaded, for: url)

            self.image = downloaded
        } catch {
            // Handle error
        }
    }
}

// MARK: - Shared Instance

extension ImageCacheActor {
    static let shared = ImageCacheActor()
}
```

### Key Points

✅ **actor keyword**: Automatically provides actor isolation (thread-safety)
✅ **async methods**: All actor methods are async (await when calling)
✅ **Private state**: Actor-isolated properties cannot be accessed outside actor
✅ **No locks needed**: Actor isolation prevents data races at compile time
✅ **Sendable conformance**: Actors are Sendable by default

---

## Pattern 4: Sendable Conformance for Data Models

### Purpose
Sendable types can be safely passed across actor boundaries without data races.

### Implementation

```swift
import Foundation

// MARK: - Sendable Structs (value types)

struct CatalogItem: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var category: String
    var location: String?
    var estimatedValue: Double?
    var imageURL: URL?
    var barcodeValue: String?
    var aiAnalysis: AIAnalysis?
    let createdAt: Date
    var updatedAt: Date
    let userId: String
}

struct AIAnalysis: Codable, Sendable {
    var layer1: Layer1Result?  // On-device Vision
    var layer2a: Layer2aResult? // Gemini attributes
    var layer2b: Layer2bResult? // Product ID (barcode/SerpAPI)
    var layer3: Layer3Result?   // Claude synthesis
}

struct User: Codable, Identifiable, Sendable {
    let id: String
    let email: String?
    let displayName: String?
    let subscriptionStatus: SubscriptionStatus
    let createdAt: Date
}

enum SubscriptionStatus: String, Codable, Sendable {
    case free
    case trial
    case premium
}
```

### Conditional Sendable for Generic Types

```swift
// Generic Result type with conditional Sendable
struct AsyncResult<Success, Failure: Error>: Sendable where Success: Sendable, Failure: Sendable {
    let value: Result<Success, Failure>
    let timestamp: Date
}

// Usage
typealias CatalogResult = AsyncResult<[CatalogItem], CatalogError>
// ✅ CatalogResult is Sendable because [CatalogItem] and CatalogError are Sendable
```

### Non-Sendable Types (Classes with Mutable State)

```swift
// ❌ NOT Sendable (class with mutable state)
class NonSendableCache {
    var items: [String: CatalogItem] = [:]

    func get(id: String) -> CatalogItem? {
        return items[id]
    }

    func set(item: CatalogItem) {
        items[item.id] = item
    }
}

// ✅ Use Actor instead for thread-safe shared state
actor SendableCache {
    private var items: [String: CatalogItem] = [:]

    func get(id: String) async -> CatalogItem? {
        return items[id]
    }

    func set(item: CatalogItem) async {
        items[item.id] = item
    }
}
```

### Key Points

✅ **Structs are Sendable**: Value types (struct, enum) are automatically Sendable if all properties are Sendable
✅ **Classes require @unchecked**: Classes must use `@unchecked Sendable` (unsafe) or be actors
✅ **Conditional conformance**: Generic types can be Sendable if type parameters are Sendable
✅ **Actors are Sendable**: Actors provide safe shared mutable state across actors
✅ **Swift 6 enforces**: Strict concurrency mode checks Sendable at compile time

---

## Swift 6 Strict Concurrency Rules

### Enable in Xcode

**Build Settings → Swift Compiler - Concurrency Checking**:
- Set to "Complete" (Swift 6 mode)

### Common Warnings and Fixes

#### Warning 1: "Capture of 'self' with non-sendable type in a `@Sendable` closure"

```swift
// ❌ Warning
Task {
    self.items = try await repository.fetchItems()
}

// ✅ Fix: Use @MainActor
@MainActor
class CatalogViewModel: ObservableObject {
    func fetchItems() async {
        // Now safe: fetchItems() runs on MainActor
        self.items = try await repository.fetchItems()
    }
}
```

#### Warning 2: "Reference to property 'items' is not concurrency-safe"

```swift
// ❌ Warning: items accessed from background thread
func fetchItems() {
    Task {
        let fetched = try await repository.fetchItems()
        self.items = fetched // ⚠️ MainActor property updated from background
    }
}

// ✅ Fix: Mark method @MainActor or use MainActor.run
@MainActor
func fetchItems() async {
    let fetched = try await repository.fetchItems()
    self.items = fetched // ✅ Safe: method is @MainActor
}
```

#### Warning 3: "Passing non-sendable parameter to function expecting '@Sendable'"

```swift
// ❌ Warning: ViewModel is not Sendable
Task {
    await someFunction(viewModel)
}

// ✅ Fix: Make type Sendable (use actor or struct)
actor ViewModelActor {
    var items: [CatalogItem] = []
}
```

---

## Best Practices Summary

### ✅ DO

1. **Mark ViewModels with @MainActor** - Ensures UI updates on main thread
2. **Use async/await for asynchronous operations** - Cleaner than callbacks
3. **Use Task groups for parallel operations** - Improve performance
4. **Use Actors for shared mutable state** - Thread-safe without locks
5. **Make data models Sendable** - Allow safe cross-actor passing
6. **Enable Swift 6 strict concurrency** - Catch data races at compile time

### ❌ DON'T

1. **Don't access MainActor properties from background threads** - Use @MainActor
2. **Don't use DispatchQueue.main.async with async/await** - Use await MainActor.run { }
3. **Don't make classes Sendable with mutable state** - Use actors instead
4. **Don't ignore concurrency warnings** - Fix them before shipping
5. **Don't use global mutable state** - Use actors or @MainActor singletons

---

## References

### Apple Documentation
- MainActor: https://developer.apple.com/documentation/swift/mainactor/
- Actor: https://developer.apple.com/documentation/swift/actor/
- Adopting strict concurrency in Swift 6: https://developer.apple.com/documentation/swift/adoptingswift6/

### WWDC Sessions
- WWDC25/268: Core Swift concurrency concepts
- WWDC25/266: SwiftUI and Swift concurrency
- WWDC24/10169: Swift 6 migration in action

### Related ADRs
- ADR-010: SwiftUI Architecture Pattern (MVVM with @MainActor)
- ADR-012: State Management Strategy (Combine + async/await)

---

## Verification

✅ All code examples use Swift 6 syntax
✅ @MainActor used for ViewModels
✅ Task groups demonstrated for parallel operations
✅ Actors used for shared mutable state
✅ Data models conform to Sendable
✅ Best practices follow WWDC25/268 guidance

---

**Status**: ✅ Complete

**Next**: CODE-EXAMPLE-002 (Catalog MVVM Implementation)

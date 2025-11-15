# ADR-012: State Management Strategy

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Approved
**Decision**: Combine + async/await Hybrid

---

## Context

The Abundance iOS app requires state management for:
- **Asynchronous operations** (network calls, AI processing, Firestore queries)
- **Real-time data sync** (Firestore listeners for catalog updates)
- **UI state updates** (loading, error, success states)
- **Complex async flows** (Camera → Vision → Upload → API → Firestore → UI)

**Options Considered**:
1. **Combine** (reactive publishers, `@Published` properties)
2. **async/await** (Swift 6 structured concurrency)
3. **@Observable** (Swift 6 macro, SwiftUI-native)
4. **Combine + async/await Hybrid** (use both where each excels)

---

## Decision

**We will use Combine + async/await Hybrid** for state management.

**Pattern**:
- Use **Combine** (`@Published`) for reactive UI state (ViewModels publish changes → SwiftUI views react)
- Use **async/await** for asynchronous operations (network calls, Firestore queries, Vision processing)
- Use **Combine** for real-time streams (Firestore listeners, long-lived subscriptions)

---

## Rationale

### Why Hybrid (Combine + async/await)?

1. **Best of Both Worlds**:
   - Combine: Reactive UI updates (`@Published` triggers SwiftUI view re-renders)
   - async/await: Modern concurrency (structured, easy to read, no callback hell)

2. **SwiftUI Integration**:
   - `@Published` properties work seamlessly with SwiftUI (`@StateObject`, `@ObservedObject`)
   - async/await works with `.task { }` modifier (SwiftUI-native async operations)

3. **Firestore Real-Time Listeners**:
   - Firestore `addSnapshotListener` returns a stream of updates → natural fit for Combine publishers
   - Converting to async sequence is verbose → Combine is simpler

4. **Network Calls**:
   - REST API calls are request-response (async/await is cleaner than Combine)
   - No need for publishers/subjects for one-shot operations

5. **Industry Adoption**:
   - Apple is transitioning from Combine to async/await (but `@Published` remains best for reactive UI)
   - Hybrid approach uses the right tool for each job

### Why Not Combine Only?

**Combine-Only Weaknesses**:
- ❌ Callback-style code (`.sink`, `.map`, `.flatMap`) less readable than async/await
- ❌ Memory management complexity (`weak self`, `store(in: &cancellables)`)
- ❌ Error handling is verbose (`.catch`, `.replaceError`)
- ❌ Testing async chains is harder than testing async functions

**Verdict**: Combine is excellent for reactive streams (Firestore listeners), but async/await is simpler for one-shot operations (API calls).

### Why Not async/await Only?

**async/await-Only Weaknesses**:
- ❌ No native `@Published` alternative (would need manual `objectWillChange.send()`)
- ❌ Converting Firestore listeners to async sequences is verbose
- ❌ Lose Combine operators (`map`, `filter`, `debounce`, `throttle`)

**Verdict**: async/await is great for async operations, but Combine is still best for reactive UI updates.

### Why Not @Observable Only?

**@Observable Weaknesses**:
- ❌ New Swift 6 feature (less mature, fewer examples)
- ❌ Doesn't replace Combine for streams (still need publishers for Firestore listeners)
- ❌ Still requires async/await for async operations

**Verdict**: @Observable may replace `@Published` in future, but Combine + async/await is proven today.

---

## Implementation Pattern

### Pattern 1: Reactive UI State (Combine)

Use `@Published` properties in ViewModels for state that triggers UI updates.

```swift
import SwiftUI
import Combine

@MainActor
class CatalogViewModel: ObservableObject {
    // Combine: Reactive UI state
    @Published var items: [CatalogItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let repository: CatalogRepository
    private var cancellables = Set<AnyCancellable>()

    init(repository: CatalogRepository) {
        self.repository = repository
    }
}

// SwiftUI View observes ViewModel
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel

    var body: some View {
        // View automatically re-renders when @Published properties change
        if viewModel.isLoading {
            ProgressView()
        } else {
            List(viewModel.items) { item in
                Text(item.name)
            }
        }
    }
}
```

**Why**: `@Published` + SwiftUI = automatic view updates (no manual `objectWillChange.send()`)

---

### Pattern 2: Asynchronous Operations (async/await)

Use async/await for network calls, Firestore queries, Vision processing.

```swift
@MainActor
class CatalogViewModel: ObservableObject {
    @Published var items: [CatalogItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let repository: CatalogRepository

    // async/await: Network call (one-shot operation)
    func fetchItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await repository.fetchItems()
        } catch {
            self.error = error
        }
    }

    // async/await: Create item (POST request)
    func createItem(_ item: CatalogItem) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let created = try await repository.createItem(item)
            items.append(created)
        } catch {
            self.error = error
        }
    }
}

// SwiftUI View calls async functions
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task { // SwiftUI async modifier
            await viewModel.fetchItems()
        }
    }
}
```

**Why**: async/await is cleaner than Combine for one-shot async operations (no `.sink`, no cancellables)

---

### Pattern 3: Real-Time Streams (Combine)

Use Combine publishers for Firestore listeners (long-lived subscriptions).

```swift
@MainActor
class CatalogViewModel: ObservableObject {
    @Published var items: [CatalogItem] = []
    private var cancellables = Set<AnyCancellable>()

    private let repository: CatalogRepository

    // Combine: Real-time Firestore listener
    func observeItems() {
        repository.observeItems()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }

    func stopObserving() {
        cancellables.removeAll()
    }
}

// Repository returns Combine publisher
class FirestoreCatalogRepository: CatalogRepository {
    private let db = Firestore.firestore()

    func observeItems() -> AnyPublisher<[CatalogItem], Never> {
        let subject = PassthroughSubject<[CatalogItem], Never>()

        let listener = db.collection("items")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    subject.send([])
                    return
                }

                let items = snapshot.documents.compactMap { doc -> CatalogItem? in
                    try? doc.data(as: CatalogItem.self)
                }

                subject.send(items)
            }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }
}
```

**Why**: Combine is simpler for real-time streams than async sequences (no `for await` loop in ViewModel)

---

### Pattern 4: Complex Async Flows (async/await with Task)

Use async/await with `Task` for complex multi-step flows (Camera → Vision → Upload → API).

```swift
@MainActor
class CameraViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var detectedObjects: [DetectedObject] = []
    @Published var error: Error?

    private let visionService: VisionService
    private let storageService: StorageService
    private let apiClient: APIClient

    // Complex async flow: Camera → Vision → Upload → API
    func processCapturedImage(_ image: UIImage) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            // Step 1: Detect objects with Vision Framework
            let objects = try await visionService.detectObjects(in: image)
            detectedObjects = objects

            // Step 2: Upload cropped images to Firebase Storage
            var uploadedURLs: [URL] = []
            for object in objects {
                let croppedImage = cropImage(image, boundingBox: object.boundingBox)
                let url = try await storageService.uploadImage(croppedImage, itemId: UUID().uuidString)
                uploadedURLs.append(url)
            }

            // Step 3: Create items via API (Layer 2/3 cloud AI)
            for (index, url) in uploadedURLs.enumerated() {
                let item = CatalogItem(
                    id: UUID().uuidString,
                    name: objects[index].label,
                    category: "Unknown",
                    imageURL: url
                )
                try await apiClient.createItem(item)
            }
        } catch {
            self.error = error
        }
    }
}
```

**Why**: async/await makes multi-step flows readable (sequential code, no nested `.flatMap`)

---

## Error Handling

### Combine Error Handling

```swift
repository.observeItems()
    .receive(on: DispatchQueue.main)
    .catch { error -> Just<[CatalogItem]> in
        print("Error observing items: \(error)")
        return Just([]) // Emit empty array on error
    }
    .sink { [weak self] items in
        self?.items = items
    }
    .store(in: &cancellables)
```

### async/await Error Handling

```swift
func fetchItems() async {
    do {
        items = try await repository.fetchItems()
    } catch {
        self.error = error
        print("Error fetching items: \(error)")
    }
}
```

**Verdict**: async/await error handling is simpler (try/catch vs `.catch` operator)

---

## Testing Strategy

### Testing async/await Functions

```swift
func testFetchItemsSuccess() async {
    // Given
    let mockRepo = MockCatalogRepository(stubbedItems: [testItem])
    let viewModel = CatalogViewModel(repository: mockRepo)

    // When
    await viewModel.fetchItems()

    // Then
    XCTAssertEqual(viewModel.items.count, 1)
    XCTAssertFalse(viewModel.isLoading)
}
```

### Testing Combine Publishers

```swift
func testObserveItemsRealTimeUpdates() {
    // Given
    let mockRepo = MockCatalogRepository()
    let viewModel = CatalogViewModel(repository: mockRepo)
    let expectation = XCTestExpectation(description: "Items updated")

    // When
    viewModel.observeItems()
    mockRepo.sendItems([testItem])

    // Then
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        XCTAssertEqual(viewModel.items.count, 1)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
}
```

---

## Consequences

### Positive Consequences

✅ **Best of Both Worlds**: Combine for reactive UI, async/await for async operations
✅ **SwiftUI Integration**: `@Published` works seamlessly with SwiftUI
✅ **Readable Code**: async/await is cleaner than callback chains
✅ **Real-Time Support**: Combine publishers for Firestore listeners
✅ **Modern**: Aligns with Apple's async/await push (while keeping Combine for reactivity)

### Negative Consequences

⚠️ **Two Paradigms**: Developers must understand both Combine and async/await
⚠️ **Cancellables Management**: Must store Combine subscriptions in `cancellables` set
⚠️ **Memory Management**: Weak self required in Combine closures (not needed in async/await)

### Mitigations

**For Two Paradigms**:
- Document clear guidelines (Combine for streams, async/await for one-shot)
- Provide code examples for both patterns

**For Cancellables Management**:
- Create base `BaseViewModel` with `cancellables` property
- Auto-cancel on ViewModel deinit

**For Memory Management**:
- Use `[weak self]` in all Combine closures
- Use `@MainActor` to avoid data races

---

## Alternatives Considered

### Option 1: Combine Only

**Pros**: Single paradigm, powerful operators
**Cons**: Callback-style, complex error handling, verbose
**Verdict**: Rejected (async/await is simpler for one-shot operations)

### Option 2: async/await Only

**Pros**: Modern, readable, structured concurrency
**Cons**: No `@Published` alternative, verbose for streams
**Verdict**: Rejected (Combine is still best for reactive UI)

### Option 3: @Observable Only

**Pros**: SwiftUI-native, simple
**Cons**: Doesn't replace Combine for streams, less mature
**Verdict**: Rejected (not ready for production)

### Option 4: Redux/Unidirectional

**Pros**: Predictable state, time-travel debugging
**Cons**: Massive boilerplate, over-engineered for MVP
**Verdict**: Rejected (TCA was already rejected in ADR-010)

---

## References

- **Implementation Plan**: docs/plans/2025-11-08-stage-2.2-ios-client-architecture.md (Task 3)
- **Tech Stack**: docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Combine, Swift 6)
- **Related ADRs**:
  - ADR-010-swiftui-architecture-pattern.md (MVVM pattern)
  - ADR-013-dependency-injection-strategy.md (Constructor injection)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial ADR, Combine + async/await hybrid | iOS Architecture Expert |

---

**Decision**: ✅ **Combine + async/await Hybrid**

**Justification**: Use Combine for reactive UI (`@Published`) and real-time streams (Firestore listeners). Use async/await for async operations (network, Vision). Best of both worlds.

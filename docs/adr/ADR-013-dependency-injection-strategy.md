# ADR-013: Dependency Injection Strategy

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Approved
**Decision**: Constructor Injection

---

## Context

The Abundance iOS app requires a dependency injection (DI) strategy for:
- **Testability** (inject mocks in unit tests)
- **Flexibility** (swap implementations without modifying ViewModels)
- **Explicit Dependencies** (clear what each ViewModel needs)
- **Type Safety** (compiler checks dependencies at compile time)

**Dependencies to Inject**:
- Repositories (`CatalogRepository`, `UserRepository`)
- Services (`VisionService`, `StorageService`, `AnalyticsService`, `APIClient`)
- Networking (`APIClient`)
- Firebase (`FirestoreService`, `AuthService`)

**Options Considered**:
1. **Constructor Injection** (manual, pass dependencies via `init`)
2. **@EnvironmentObject** (SwiftUI environment, pass down view hierarchy)
3. **Property Wrappers** (custom `@Injected` wrapper, service locator pattern)
4. **Dependency Injection Framework** (Swinject, Needle, Factory)

---

## Decision

**We will use Constructor Injection** (manual dependency passing via `init`).

---

## Rationale

### Why Constructor Injection?

1. **Explicit Dependencies**: Clear what each ViewModel needs (no hidden dependencies)
2. **Type-Safe**: Compiler verifies dependencies at compile time (no runtime crashes)
3. **Testable**: Easy to inject mocks via `init` in unit tests
4. **No Magic**: No property wrappers, no service locator, no global state
5. **Simple**: No third-party framework (no learning curve, no maintenance burden)
6. **Refactorable**: Xcode "Find References" shows all usages of a dependency
7. **SwiftUI-Compatible**: Works with `@StateObject(wrappedValue:)` pattern

### Why Not @EnvironmentObject?

**@EnvironmentObject Weaknesses**:
- ❌ Implicit dependencies (ViewModels don't declare what they need)
- ❌ Runtime crashes (if environment object not provided, app crashes)
- ❌ Hard to test (must inject via `.environmentObject()` modifier in tests)
- ❌ Global state (environment objects accessible from any view in hierarchy)

**Example of @EnvironmentObject Fragility**:
```swift
// ViewModel doesn't declare dependency on repository
class CatalogViewModel: ObservableObject {
    @EnvironmentObject var repository: CatalogRepository // ❌ Implicit

    func fetchItems() async {
        // Crashes at runtime if repository not in environment
        items = try await repository.fetchItems()
    }
}

// Test crashes if environment object not provided
func testFetchItems() async {
    let viewModel = CatalogViewModel() // ❌ No error, crashes at runtime
    await viewModel.fetchItems() // 💥 Crash: repository not found in environment
}
```

**Verdict**: @EnvironmentObject is useful for app-wide state (theme, locale), but not for ViewModels (dependencies should be explicit).

### Why Not Property Wrappers (@Injected)?

**Property Wrapper Weaknesses**:
- ❌ Hidden dependencies (no explicit `init` parameters)
- ❌ Service locator pattern (global registry of dependencies)
- ❌ Hard to refactor (can't see all usages of a dependency)
- ❌ Testing complexity (must register mocks in global container)

**Example of Property Wrapper Fragility**:
```swift
// Custom @Injected property wrapper
@propertyWrapper
struct Injected<T> {
    let wrappedValue: T

    init() {
        // ❌ Global service locator (hidden dependency)
        wrappedValue = ServiceLocator.shared.resolve(T.self)!
    }
}

// ViewModel uses @Injected
class CatalogViewModel: ObservableObject {
    @Injected var repository: CatalogRepository // ❌ Hidden dependency

    func fetchItems() async {
        items = try await repository.fetchItems()
    }
}

// Test requires global registration
func testFetchItems() async {
    // ❌ Must register mock in global service locator
    ServiceLocator.shared.register(MockCatalogRepository.self, as: CatalogRepository.self)

    let viewModel = CatalogViewModel()
    await viewModel.fetchItems()

    // ❌ Must unregister to avoid affecting other tests
    ServiceLocator.shared.unregister(CatalogRepository.self)
}
```

**Verdict**: Property wrappers hide dependencies and require global state (anti-pattern for testability).

### Why Not Dependency Injection Framework?

**DI Framework Weaknesses** (Swinject, Needle, Factory):
- ❌ Third-party dependency (maintenance burden, breaking changes)
- ❌ Learning curve (new developers must learn framework)
- ❌ Boilerplate (container setup, registration, resolution)
- ❌ Over-engineered for MVP (single developer, 5-10 screens)

**Verdict**: DI frameworks are useful for large teams and massive apps (50+ dependencies). Abundance MVP is small enough for manual constructor injection.

---

## Implementation Pattern

### Pattern 1: Protocol + Constructor Injection

Define protocols for dependencies, inject via `init`.

```swift
// MARK: - Protocol (Abstraction)
protocol CatalogRepository {
    func fetchItems() async throws -> [CatalogItem]
    func createItem(_ item: CatalogItem) async throws -> CatalogItem
    func deleteItem(id: String) async throws
}

// MARK: - Real Implementation (Firestore)
class FirestoreCatalogRepository: CatalogRepository {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetchItems() async throws -> [CatalogItem] {
        let snapshot = try await db.collection("items").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: CatalogItem.self) }
    }

    func createItem(_ item: CatalogItem) async throws -> CatalogItem {
        try db.collection("items").document(item.id).setData(from: item)
        return item
    }

    func deleteItem(id: String) async throws {
        try await db.collection("items").document(id).delete()
    }
}

// MARK: - ViewModel (Constructor Injection)
@MainActor
class CatalogViewModel: ObservableObject {
    @Published var items: [CatalogItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let repository: CatalogRepository // ✅ Explicit dependency

    // ✅ Constructor injection (dependency passed via init)
    init(repository: CatalogRepository) {
        self.repository = repository
    }

    func fetchItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await repository.fetchItems()
        } catch {
            self.error = error
        }
    }
}
```

---

### Pattern 2: View Creates ViewModel with Real Dependency

Views create ViewModels with real implementations (default parameter).

```swift
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel

    // ✅ Default parameter (real implementation for production)
    init(repository: CatalogRepository = FirestoreCatalogRepository()) {
        _viewModel = StateObject(wrappedValue: CatalogViewModel(repository: repository))
    }

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task {
            await viewModel.fetchItems()
        }
    }
}
```

**Production Usage**: View uses default parameter (real Firestore repository).
```swift
NavigationLink(destination: CatalogView()) { // ✅ Uses FirestoreCatalogRepository
    Text("Catalog")
}
```

---

### Pattern 3: Tests Inject Mock Dependency

Tests inject mocks via `init`.

```swift
import XCTest
@testable import Abundance

class CatalogViewModelTests: XCTestCase {
    var sut: CatalogViewModel!
    var mockRepository: MockCatalogRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockCatalogRepository()
        sut = CatalogViewModel(repository: mockRepository) // ✅ Inject mock
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func testFetchItemsSuccess() async {
        // Given
        let expectedItems = [
            CatalogItem(id: "1", name: "Drill", category: "Tools")
        ]
        mockRepository.stubbedItems = expectedItems

        // When
        await sut.fetchItems()

        // Then
        XCTAssertEqual(sut.items, expectedItems)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func testCreateItemSuccess() async {
        // Given
        let newItem = CatalogItem(id: "2", name: "Tent", category: "Camping")

        // When
        await sut.createItem(newItem)

        // Then
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items.first?.name, "Tent")
        XCTAssertTrue(mockRepository.didCallCreateItem)
    }
}

// MARK: - Mock Repository
class MockCatalogRepository: CatalogRepository {
    var stubbedItems: [CatalogItem] = []
    var shouldFail: Bool = false
    var didCallCreateItem: Bool = false
    var didCallDeleteItem: Bool = false

    func fetchItems() async throws -> [CatalogItem] {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return stubbedItems
    }

    func createItem(_ item: CatalogItem) async throws -> CatalogItem {
        didCallCreateItem = true
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        stubbedItems.append(item)
        return item
    }

    func deleteItem(id: String) async throws {
        didCallDeleteItem = true
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        stubbedItems.removeAll { $0.id == id }
    }
}
```

---

### Pattern 4: Multiple Dependencies

ViewModels with multiple dependencies inject all via `init`.

```swift
@MainActor
class CameraViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var detectedObjects: [DetectedObject] = []
    @Published var error: Error?

    private let visionService: VisionService
    private let storageService: StorageService
    private let apiClient: APIClient
    private let analyticsService: AnalyticsService

    // ✅ Constructor injection (all dependencies explicit)
    init(
        visionService: VisionService,
        storageService: StorageService,
        apiClient: APIClient,
        analyticsService: AnalyticsService
    ) {
        self.visionService = visionService
        self.storageService = storageService
        self.apiClient = apiClient
        self.analyticsService = analyticsService
    }

    func processCapturedImage(_ image: UIImage) async {
        // Use all injected dependencies
        analyticsService.logEvent("camera_capture")

        do {
            let objects = try await visionService.detectObjects(in: image)
            detectedObjects = objects

            for object in objects {
                let croppedImage = cropImage(image, boundingBox: object.boundingBox)
                let url = try await storageService.uploadImage(croppedImage)
                let item = CatalogItem(name: object.label, imageURL: url)
                try await apiClient.createItem(item)
            }
        } catch {
            self.error = error
        }
    }
}

// View creates ViewModel with real dependencies
struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel

    init(
        visionService: VisionService = VisionService(),
        storageService: StorageService = StorageService(),
        apiClient: APIClient = FirebaseAPIClient(),
        analyticsService: AnalyticsService = FirebaseAnalyticsService()
    ) {
        _viewModel = StateObject(wrappedValue: CameraViewModel(
            visionService: visionService,
            storageService: storageService,
            apiClient: apiClient,
            analyticsService: analyticsService
        ))
    }

    var body: some View {
        // Camera UI
    }
}
```

---

## Testing Strategy

### Unit Test Pattern

1. Create mock implementations of protocols
2. Inject mocks via ViewModel `init`
3. Test ViewModel behavior with mocks

```swift
func testProcessImageSuccess() async {
    // Given
    let mockVision = MockVisionService(stubbedObjects: [testObject])
    let mockStorage = MockStorageService(stubbedURL: testURL)
    let mockAPI = MockAPIClient()
    let mockAnalytics = MockAnalyticsService()

    let viewModel = CameraViewModel(
        visionService: mockVision,
        storageService: mockStorage,
        apiClient: mockAPI,
        analyticsService: mockAnalytics
    )

    // When
    await viewModel.processCapturedImage(testImage)

    // Then
    XCTAssertEqual(viewModel.detectedObjects.count, 1)
    XCTAssertTrue(mockVision.didCallDetectObjects)
    XCTAssertTrue(mockStorage.didCallUploadImage)
    XCTAssertTrue(mockAPI.didCallCreateItem)
    XCTAssertTrue(mockAnalytics.didLogEvent)
}
```

**Test Coverage Target**: 90%+ for ViewModels (achievable with constructor injection)

---

## Consequences

### Positive Consequences

✅ **Explicit Dependencies**: Clear what each ViewModel needs (no hidden dependencies)
✅ **Type-Safe**: Compiler verifies dependencies at compile time (no runtime crashes)
✅ **Testable**: Easy to inject mocks in unit tests (no global state)
✅ **Simple**: No frameworks, no property wrappers, no magic
✅ **Refactorable**: Xcode "Find References" shows all usages
✅ **SwiftUI-Compatible**: Works with `@StateObject(wrappedValue:)` pattern

### Negative Consequences

⚠️ **Manual Wiring**: Must manually pass dependencies in production views
⚠️ **Init Boilerplate**: ViewModels with many dependencies have long `init` signatures
⚠️ **No Auto-Wiring**: No automatic dependency resolution (must pass explicitly)

### Mitigations

**For Manual Wiring**:
- Use default parameters in View `init` (production uses defaults, tests pass mocks)
- Example: `init(repository: CatalogRepository = FirestoreCatalogRepository())`

**For Init Boilerplate**:
- Limit dependencies per ViewModel (max 3-5 dependencies)
- If ViewModel has 6+ dependencies, split into smaller ViewModels

**For No Auto-Wiring**:
- For MVP (5-10 screens), manual wiring is manageable
- If codebase grows to 20+ screens, consider lightweight DI framework (Factory, not Swinject)

---

## Alternatives Considered

### Option 1: @EnvironmentObject

**Pros**: SwiftUI-native, minimal boilerplate
**Cons**: Implicit dependencies, runtime crashes, hard to test
**Verdict**: Rejected (too fragile for ViewModels)

### Option 2: Property Wrappers (@Injected)

**Pros**: Concise syntax, auto-resolution
**Cons**: Hidden dependencies, global state, hard to refactor
**Verdict**: Rejected (anti-pattern for testability)

### Option 3: Dependency Injection Framework (Swinject)

**Pros**: Auto-wiring, container-based resolution
**Cons**: Third-party dependency, learning curve, over-engineered for MVP
**Verdict**: Rejected (too complex for 5-10 screens)

### Option 4: Factory Pattern (Manual Factories)

**Pros**: Centralized creation logic
**Cons**: Boilerplate factory classes, not significantly simpler than constructor injection
**Verdict**: Rejected (constructor injection is simpler)

---

## References

- **Implementation Plan**: docs/plans/2025-11-08-stage-2.2-ios-client-architecture.md (Task 4)
- **Tech Stack**: docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Swift 6, SwiftUI)
- **Related ADRs**:
  - ADR-010-swiftui-architecture-pattern.md (MVVM pattern)
  - ADR-011-ios-module-structure.md (Modular packages)
  - ADR-012-state-management-strategy.md (Combine + async/await)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial ADR, constructor injection pattern | iOS Architecture Expert |

---

**Decision**: ✅ **Constructor Injection**

**Justification**: Explicit dependencies, type-safe, testable, simple. No frameworks, no magic. Best balance of simplicity and testability for Abundance MVP.

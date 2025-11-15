# ADR-010: SwiftUI Architecture Pattern

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Approved
**Decision**: MVVM (Model-View-ViewModel)

---

## Context

The Abundance iOS app requires an architecture pattern that supports:
- Clean separation of concerns (UI, data, business logic)
- Testability (80% unit test coverage target from TEST-STRATEGY-001)
- Maintainability (single developer initially, future team growth)
- SwiftUI compatibility (leverage framework strengths)
- Async/await support (Swift 6 concurrency for network, AI, Firestore)

**Options Considered**:
1. **MVVM (Model-View-ViewModel)** - Standard iOS pattern with `@Published` properties
2. **TCA (The Composable Architecture)** - Point-Free's unidirectional data flow pattern
3. **MV (Model-View)** - Simplified SwiftUI-native approach with `@Observable`

---

## Decision

**We will use MVVM (Model-View-ViewModel)** for the Abundance iOS app.

---

## Rationale

### Why MVVM?

1. **Team Size**: Single developer initially → MVVM is familiar, well-documented, widely adopted
2. **Testability**: ViewModels are plain Swift objects (POJO) → easy to unit test with mocks (target: 80% coverage achievable)
3. **SwiftUI Alignment**: Native property wrappers (`@Published`, `@StateObject`, `@ObservedObject`) integrate seamlessly
4. **Async/Await Support**: MVVM works well with Swift 6 structured concurrency (async functions in ViewModels)
5. **Maintainability**: Standard pattern → easier to onboard future developers (no learning curve for TCA)
6. **Not Over-Engineered**: TCA is overkill for MVP (5-10 screens, single developer, no massive shared state)
7. **Not Under-Engineered**: MV is too simple for complex state (real-time Firestore sync, multi-layer AI processing, async operations)
8. **Industry Adoption**: MVVM is the de facto standard for SwiftUI apps (abundant resources, examples, community support)

### Why Not TCA?

**TCA Strengths**:
- ✅ Excellent testability (pure functions, reducers are easy to test)
- ✅ Unidirectional data flow (predictable state changes, time-travel debugging)
- ✅ Composability (feature modules combine cleanly)
- ✅ Built-in dependency injection (`@Dependency` property wrapper)

**TCA Weaknesses for Abundance MVP**:
- ❌ Steep learning curve (functional programming concepts, Effect system, Reducer composition)
- ❌ Boilerplate overhead (State, Action, Reducer, Environment for EVERY feature)
- ❌ Over-engineered for MVP (single developer, 5-10 screens, moderate complexity)
- ❌ Third-party dependency (adds maintenance burden, library updates, breaking changes)
- ❌ Slower iteration speed (more code to write per feature)

**Verdict**: TCA is a great pattern for large teams and complex apps (10+ developers, 50+ screens). For Abundance MVP (1 developer, 5-10 screens), MVVM provides better velocity without sacrificing testability.

### Why Not MV (Model-View)?

**MV Strengths**:
- ✅ Simplest pattern (minimal boilerplate)
- ✅ SwiftUI-native (`@Observable` macro in Swift 6)
- ✅ Fast iteration (less code to write)

**MV Weaknesses for Abundance**:
- ⚠️ Less separation (model contains both data + logic, can become bloated)
- ⚠️ Not widely adopted yet (Swift 6 `@Observable` is new, fewer examples/resources)
- ⚠️ Complex state management (real-time Firestore listeners, AI processing, async operations may clutter model)

**Verdict**: MV might be viable for very simple apps (2-3 screens, CRUD-only). Abundance has moderate complexity (real-time sync, multi-layer AI, async operations) → MVVM provides better structure.

---

## Implementation Pattern

### MVVM Structure

```
Model (Data)
    ↓
ViewModel (Business Logic + State)
    ↓
View (UI)
```

### Example: CatalogViewModel

```swift
import SwiftUI
import Combine

// MARK: - Model (Data)
struct CatalogItem: Codable, Identifiable {
    let id: String
    var name: String
    var category: String
    var location: String?
    var estimatedValue: Double?
}

// MARK: - ViewModel (Business Logic + State)
@MainActor
class CatalogViewModel: ObservableObject {
    // Published properties (trigger UI updates)
    @Published var items: [CatalogItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let repository: CatalogRepository
    private var cancellables = Set<AnyCancellable>()

    init(repository: CatalogRepository) {
        self.repository = repository
    }

    // Async/await for network calls
    func fetchItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await repository.fetchItems()
        } catch {
            self.error = error
        }
    }

    // Combine for real-time Firestore listeners
    func observeItems() {
        repository.observeItems()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }

    func deleteItem(id: String) async {
        do {
            try await repository.deleteItem(id: id)
            items.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }
}

// MARK: - View (UI)
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
                    List {
                        ForEach(viewModel.items) { item in
                            NavigationLink(value: item) {
                                CatalogItemRow(item: item)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteItem(id: viewModel.items[index].id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Catalog")
            .task {
                await viewModel.fetchItems()
            }
            .onAppear {
                viewModel.observeItems() // Start real-time sync
            }
            .alert(error: $viewModel.error) // Show error alerts
        }
    }
}
```

---

## Testing Strategy

### Unit Testing ViewModels

ViewModels are easy to test because they are plain Swift objects with injectable dependencies.

```swift
import XCTest
@testable import Abundance

class CatalogViewModelTests: XCTestCase {
    var sut: CatalogViewModel!
    var mockRepository: MockCatalogRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockCatalogRepository()
        sut = CatalogViewModel(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func testFetchItemsSuccess() async {
        // Given
        let expectedItems = [
            CatalogItem(id: "1", name: "Drill", category: "Tools"),
            CatalogItem(id: "2", name: "Tent", category: "Camping")
        ]
        mockRepository.stubbedItems = expectedItems

        // When
        await sut.fetchItems()

        // Then
        XCTAssertEqual(sut.items, expectedItems)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func testFetchItemsFailure() async {
        // Given
        mockRepository.shouldFail = true

        // When
        await sut.fetchItems()

        // Then
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testDeleteItemSuccess() async {
        // Given
        sut.items = [
            CatalogItem(id: "1", name: "Drill", category: "Tools"),
            CatalogItem(id: "2", name: "Tent", category: "Camping")
        ]

        // When
        await sut.deleteItem(id: "1")

        // Then
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items.first?.id, "2")
        XCTAssertTrue(mockRepository.didCallDeleteItem)
    }

    func testObserveItemsRealTimeUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "Items updated")
        let newItems = [CatalogItem(id: "1", name: "New Item", category: "Test")]

        // When
        sut.observeItems()
        mockRepository.sendItems(newItems)

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.items, newItems)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}

// Mock Repository
class MockCatalogRepository: CatalogRepository {
    var stubbedItems: [CatalogItem] = []
    var shouldFail: Bool = false
    var didCallDeleteItem: Bool = false

    private let itemsSubject = PassthroughSubject<[CatalogItem], Never>()

    func fetchItems() async throws -> [CatalogItem] {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return stubbedItems
    }

    func observeItems() -> AnyPublisher<[CatalogItem], Never> {
        return itemsSubject.eraseToAnyPublisher()
    }

    func sendItems(_ items: [CatalogItem]) {
        itemsSubject.send(items)
    }

    func deleteItem(id: String) async throws {
        didCallDeleteItem = true
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
    }
}
```

**Test Coverage Target**: 90%+ for ViewModels (aligns with TEST-STRATEGY-001's 80% overall unit test target)

---

## Consequences

### Positive Consequences

✅ **Fast Development**: Standard pattern → no learning curve → faster MVP iteration
✅ **Testable**: ViewModels are POJO → easy to mock dependencies → 80% coverage achievable
✅ **Maintainable**: Well-documented pattern → easy to onboard future developers
✅ **SwiftUI-Native**: `@Published`, `@StateObject` work seamlessly with SwiftUI
✅ **Flexible**: Works with both Combine (real-time listeners) and async/await (network calls)

### Negative Consequences

⚠️ **Boilerplate**: Every feature needs a ViewModel (can be mitigated with code generation tools like Sourcery)
⚠️ **Shared State**: ViewModels don't naturally share state (can use singleton repositories or dependency injection)
⚠️ **Not Unidirectional**: State updates can come from multiple sources (View actions, Firestore listeners, network responses) → requires discipline

### Mitigations

**For Boilerplate**:
- Create base `BaseViewModel` class with common `@Published` properties (`isLoading`, `error`)
- Use Sourcery for code generation (ViewModels, mocks)

**For Shared State**:
- Use singleton repositories (e.g., `FirestoreCatalogRepository.shared`)
- Pass shared ViewModels via `@EnvironmentObject` when needed

**For State Management Complexity**:
- Follow strict pattern: View actions → ViewModel methods → Repository calls → Update `@Published` properties
- Document state flow in each ViewModel

---

## Alternatives Considered

### Option 1: TCA (The Composable Architecture)

**Pros**: Excellent testability, unidirectional data flow, composability
**Cons**: Steep learning curve, boilerplate overhead, over-engineered for MVP
**Verdict**: Rejected (over-engineered for single developer, 5-10 screens)

### Option 2: MV (Model-View with @Observable)

**Pros**: Simplest pattern, fast iteration, SwiftUI-native
**Cons**: Less separation, not widely adopted yet, complex state may clutter model
**Verdict**: Rejected (too simple for real-time sync + multi-layer AI processing)

### Option 3: VIPER (View-Interactor-Presenter-Entity-Router)

**Pros**: Extreme separation of concerns, highly testable
**Cons**: Massive boilerplate (5 layers per feature), over-engineered, outdated for SwiftUI
**Verdict**: Rejected (not designed for SwiftUI, too complex for MVP)

---

## References

- **Implementation Plan**: docs/plans/2025-11-08-stage-2.2-ios-client-architecture.md (Task 1)
- **Test Strategy**: docs/test/TEST-STRATEGY-001-mvp-testing-approach.md (80/15/5 pyramid)
- **Tech Stack**: docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Swift 6, SwiftUI)
- **Related ADRs**:
  - ADR-012-state-management-strategy.md (Combine + async/await hybrid)
  - ADR-013-dependency-injection-strategy.md (Constructor injection for ViewModels)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial ADR, MVVM pattern selected | iOS Architecture Expert |

---

**Decision**: ✅ **MVVM (Model-View-ViewModel)**

**Justification**: Best balance of testability, maintainability, and development velocity for Abundance MVP. Not over-engineered (TCA), not under-engineered (MV).

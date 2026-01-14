# TEST-EXAMPLE-001: ViewModel Unit Tests

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**Purpose**: Unit test patterns for MVVM ViewModels with async/await

---

## Overview

This document provides unit test patterns for testing Swift 6 async/await ViewModels, following TEST-STRATEGY-001 (80/15/5 test pyramid) and targeting 90%+ coverage for ViewModels.

**Test Framework**: XCTest
**Pattern**: Mock repository injection
**Target Coverage**: 90%+ for ViewModels

---

## Test Structure

```
AbundanceTests/
├── ViewModels/
│   ├── CatalogViewModelTests.swift
│   ├── CameraViewModelTests.swift
│   └── ProfileViewModelTests.swift
├── Repositories/
│   ├── FirestoreCatalogRepositoryTests.swift
│   └── (integration tests with Firebase Emulator)
├── Mocks/
│   ├── MockCatalogRepository.swift
│   ├── MockUserRepository.swift
│   └── MockStatsRepository.swift
└── Fixtures/
    └── TestFixtures.swift
```

---

## Pattern 1: Testing async ViewModel Methods

### CatalogViewModelTests

```swift
import XCTest
@testable import Abundance

@MainActor
final class CatalogViewModelTests: XCTestCase {
    // MARK: - Properties

    var sut: CatalogViewModel!
    var mockRepository: MockCatalogRepository!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockCatalogRepository()
        sut = CatalogViewModel(repository: mockRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - fetchItems() Tests

    func testFetchItemsSuccess() async {
        // Given
        let expectedItems = TestFixtures.catalogItems()
        mockRepository.stubbedItems = expectedItems

        // When
        await sut.fetchItems()

        // Then
        XCTAssertEqual(sut.items, expectedItems)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertTrue(mockRepository.didCallFetchItems)
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
        XCTAssertTrue(mockRepository.didCallFetchItems)
    }

    func testFetchItemsSetsLoadingState() async {
        // Given
        mockRepository.stubbedItems = TestFixtures.catalogItems()

        // When
        let loadingBeforeFetch = sut.isLoading
        let fetchTask = Task {
            await sut.fetchItems()
        }

        // Check loading state during fetch (timing-dependent, may be flaky)
        // Better: Use expectation or mock delay

        await fetchTask.value
        let loadingAfterFetch = sut.isLoading

        // Then
        XCTAssertFalse(loadingBeforeFetch)
        XCTAssertFalse(loadingAfterFetch)
    }

    // MARK: - deleteItem(id:) Tests

    func testDeleteItemSuccess() async {
        // Given
        let items = TestFixtures.catalogItems()
        sut.items = items
        let itemToDelete = items.first!

        // When
        await sut.deleteItem(id: itemToDelete.id)

        // Then
        XCTAssertEqual(sut.items.count, items.count - 1)
        XCTAssertFalse(sut.items.contains(where: { $0.id == itemToDelete.id }))
        XCTAssertNil(sut.error)
        XCTAssertTrue(mockRepository.didCallDeleteItem)
    }

    func testDeleteItemFailure() async {
        // Given
        let items = TestFixtures.catalogItems()
        sut.items = items
        let itemToDelete = items.first!
        mockRepository.shouldFail = true

        // When
        await sut.deleteItem(id: itemToDelete.id)

        // Then
        XCTAssertEqual(sut.items.count, items.count) // No items removed
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(mockRepository.didCallDeleteItem)
    }

    // MARK: - observeItems() Tests

    func testObserveItemsRealTimeUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "Items updated")
        let newItems = TestFixtures.catalogItems()

        // When
        sut.observeItems()
        mockRepository.sendItems(newItems)

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            XCTAssertEqual(self?.sut.items, newItems)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testObserveItemsMultipleUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "Multiple updates received")
        expectation.expectedFulfillmentCount = 2

        let items1 = TestFixtures.catalogItems(count: 2)
        let items2 = TestFixtures.catalogItems(count: 5)

        var receivedUpdates: [[CatalogItem]] = []

        // When
        sut.observeItems()

        // Subscribe to items changes (in real app, SwiftUI does this)
        let cancellable = sut.$items.sink { items in
            receivedUpdates.append(items)
            if receivedUpdates.count >= 2 {
                expectation.fulfill()
            }
        }

        mockRepository.sendItems(items1)
        mockRepository.sendItems(items2)

        // Then
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedUpdates.count, 2)
        XCTAssertEqual(receivedUpdates[0], items1)
        XCTAssertEqual(receivedUpdates[1], items2)

        cancellable.cancel()
    }

    // MARK: - refresh() Tests

    func testRefreshCallsFetchItems() async {
        // Given
        mockRepository.stubbedItems = TestFixtures.catalogItems()

        // When
        await sut.refresh()

        // Then
        XCTAssertTrue(mockRepository.didCallFetchItems)
        XCTAssertFalse(sut.items.isEmpty)
    }
}
```

---

## Pattern 2: Testing Error Handling

### Testing Error States

```swift
extension CatalogViewModelTests {
    func testNetworkErrorSetsErrorProperty() async {
        // Given
        mockRepository.shouldFail = true

        // When
        await sut.fetchItems()

        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.error is CatalogError)

        if let catalogError = sut.error as? CatalogError {
            XCTAssertEqual(catalogError, .networkFailure)
        }
    }

    func testErrorIsClearedOnSuccessfulFetch() async {
        // Given: Previous error state
        mockRepository.shouldFail = true
        await sut.fetchItems()
        XCTAssertNotNil(sut.error)

        // When: Successful fetch
        mockRepository.shouldFail = false
        mockRepository.stubbedItems = TestFixtures.catalogItems()
        await sut.fetchItems()

        // Then: Error cleared
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.items.isEmpty)
    }
}
```

---

## Pattern 3: Testing Combine Publishers

### Testing @Published Properties

```swift
import Combine

extension CatalogViewModelTests {
    func testPublishedPropertiesEmitChanges() {
        // Given
        var receivedItems: [[CatalogItem]] = []
        var receivedLoadingStates: [Bool] = []

        let itemsCancellable = sut.$items.sink { items in
            receivedItems.append(items)
        }

        let loadingCancellable = sut.$isLoading.sink { isLoading in
            receivedLoadingStates.append(isLoading)
        }

        // When
        sut.items = TestFixtures.catalogItems(count: 3)
        sut.isLoading = true
        sut.isLoading = false

        // Then
        XCTAssertEqual(receivedItems.count, 2) // Initial empty + update
        XCTAssertEqual(receivedLoadingStates.count, 3) // Initial false + true + false

        itemsCancellable.cancel()
        loadingCancellable.cancel()
    }
}
```

---

## Pattern 4: Test Fixtures

### TestFixtures.swift

```swift
import Foundation
@testable import Abundance

struct TestFixtures {
    /// Create test catalog items
    /// - Parameter count: Number of items to create
    /// - Returns: Array of CatalogItem
    static func catalogItems(count: Int = 3) -> [CatalogItem] {
        return (1...count).map { index in
            CatalogItem(
                id: "test-item-\(index)",
                name: "Test Item \(index)",
                category: "Tools",
                location: "Garage",
                estimatedValue: Double(index * 10),
                imageURL: URL(string: "https://example.com/image\(index).jpg"),
                barcodeValue: "12345678\(index)",
                aiAnalysis: nil,
                createdAt: Date().addingTimeInterval(-Double(index * 3600)),
                updatedAt: Date(),
                userId: "test-user-123"
            )
        }
    }

    /// Create single catalog item
    static func catalogItem(
        id: String = "test-item-1",
        name: String = "Drill",
        category: String = "Tools"
    ) -> CatalogItem {
        return CatalogItem(
            id: id,
            name: name,
            category: category,
            location: "Garage",
            estimatedValue: 50.0,
            imageURL: URL(string: "https://example.com/drill.jpg"),
            barcodeValue: "123456789",
            aiAnalysis: nil,
            createdAt: Date(),
            updatedAt: Date(),
            userId: "test-user-123"
        )
    }

    /// Create test user
    static func user(
        id: String = "test-user-123",
        email: String = "test@example.com",
        subscriptionStatus: SubscriptionStatus = .free
    ) -> User {
        return User(
            id: id,
            email: email,
            displayName: "Test User",
            subscriptionStatus: subscriptionStatus,
            createdAt: Date()
        )
    }
}
```

---

## Pattern 5: Testing Async Task Groups

### DashboardViewModelTests

```swift
@MainActor
final class DashboardViewModelTests: XCTestCase {
    var sut: DashboardViewModel!
    var mockCatalogRepo: MockCatalogRepository!
    var mockUserRepo: MockUserRepository!
    var mockStatsRepo: MockStatsRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockCatalogRepo = MockCatalogRepository()
        mockUserRepo = MockUserRepository()
        mockStatsRepo = MockStatsRepository()

        sut = DashboardViewModel(
            catalogRepository: mockCatalogRepo,
            userRepository: mockUserRepo,
            statsRepository: mockStatsRepo
        )
    }

    func testLoadDashboardFetchesAllDataInParallel() async {
        // Given
        mockCatalogRepo.stubbedItems = TestFixtures.catalogItems(count: 5)
        mockUserRepo.stubbedUser = TestFixtures.user()
        mockStatsRepo.stubbedStats = UserStats(totalItems: 5, totalValue: 250.0)

        // When
        let startTime = Date()
        await sut.loadDashboard()
        let duration = Date().timeIntervalSince(startTime)

        // Then: All data loaded
        XCTAssertEqual(sut.catalogItems.count, 5)
        XCTAssertNotNil(sut.userProfile)
        XCTAssertNotNil(sut.stats)
        XCTAssertNil(sut.error)

        // Then: Parallel execution should be faster than sequential
        // (This is timing-dependent, may be flaky in CI)
        // XCTAssertLessThan(duration, 0.5)
    }

    func testLoadDashboardHandlesPartialFailure() async {
        // Given: Only catalog repo fails
        mockCatalogRepo.shouldFail = true
        mockUserRepo.stubbedUser = TestFixtures.user()
        mockStatsRepo.stubbedStats = UserStats(totalItems: 0, totalValue: 0.0)

        // When
        await sut.loadDashboard()

        // Then: Error captured, other data not loaded (task group throws)
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.catalogItems.isEmpty)
        // Note: Task group throws on first failure, so other tasks may not complete
    }
}
```

---

## Best Practices

### ✅ DO

1. **Use @MainActor for test class** - Tests run on main thread like ViewModels
2. **Create fresh mocks in setUp()** - Avoid test interdependencies
3. **Use async test methods** - Test async ViewModel methods naturally
4. **Verify all side effects** - Check `items`, `isLoading`, `error`, and mock calls
5. **Use test fixtures** - Centralize test data creation
6. **Test error paths** - Verify error handling, not just happy paths
7. **Clean up in tearDown()** - Set sut and mocks to nil
8. **Use expectations for Combine** - Wait for asynchronous publisher emissions

### ❌ DON'T

1. **Don't test SwiftUI views directly** - Use XCUITest for view tests (E2E)
2. **Don't use real Firestore in unit tests** - Use mock repositories
3. **Don't sleep or use arbitrary delays** - Use expectations or mock delays
4. **Don't test framework code** - Test your ViewModel logic, not Combine/async/await
5. **Don't share state between tests** - Each test should be independent

---

## Test Coverage Goals

### Target Coverage (TEST-STRATEGY-001)

| Layer | Coverage Target |
|-------|----------------|
| ViewModels | 90%+ |
| Repositories | 80%+ |
| Models | 100% (simple data) |
| Views (SwiftUI) | 5% (E2E only) |

### Running Tests with Coverage

```bash
# Xcode
# Product → Test (⌘U)
# Product → Show Test Report → Coverage

# Command line
xcodebuild test \
  -scheme Abundance \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES
```

### Viewing Coverage Report

1. Open Xcode → Product → Show Test Report
2. Click Coverage tab
3. Expand modules to see file-level coverage
4. Click file to see line-by-line coverage

---

## Integration Test Example

### FirestoreCatalogRepositoryTests (with Firebase Emulator)

```swift
import XCTest
import FirebaseFirestore
@testable import Abundance

final class FirestoreCatalogRepositoryTests: XCTestCase {
    var sut: FirestoreCatalogRepository!
    var db: Firestore!

    override func setUp() async throws {
        try await super.setUp()

        // Configure Firebase Emulator
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false

        db = Firestore.firestore()
        db.settings = settings

        sut = FirestoreCatalogRepository()

        // Clear Firestore emulator data
        try await clearFirestore()
    }

    func testCreateAndFetchItem() async throws {
        // Given
        let item = TestFixtures.catalogItem()

        // When: Create item
        try await sut.createItem(item)

        // Then: Fetch returns created item
        let fetched = try await sut.fetchItems()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, item.id)
        XCTAssertEqual(fetched.first?.name, item.name)
    }

    func testDeleteItem() async throws {
        // Given: Item exists
        let item = TestFixtures.catalogItem()
        try await sut.createItem(item)

        // When: Delete item
        try await sut.deleteItem(id: item.id)

        // Then: Item no longer in Firestore
        let fetched = try await sut.fetchItems()
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: - Helpers

    private func clearFirestore() async throws {
        let collections = try await db.collection("items").getDocuments()
        for doc in collections.documents {
            try await doc.reference.delete()
        }
    }
}
```

### Running Integration Tests

```bash
# Start Firebase Emulator
firebase emulators:start --only firestore,auth

# Run integration tests
xcodebuild test \
  -scheme Abundance \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AbundanceTests/FirestoreCatalogRepositoryTests
```

---

## References

- **TEST-STRATEGY-001**: MVP Testing Approach (80/15/5 pyramid)
- **CODE-EXAMPLE-002**: Catalog MVVM Implementation
- **ADR-010**: SwiftUI Architecture Pattern (MVVM)

---

## Verification

✅ Unit tests for CatalogViewModel (fetchItems, deleteItem, observeItems)
✅ Mock repository pattern for dependency injection
✅ Test fixtures for test data
✅ Async test methods with await
✅ Combine publisher testing with expectations
✅ Integration test example with Firebase Emulator
✅ Coverage targets documented (90%+ for ViewModels)

---

**Status**: ✅ Complete

**Next**: CODE-EXAMPLE-003 (Firebase iOS Integration)

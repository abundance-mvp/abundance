# TEST-EXAMPLE-002: iOS Testing Patterns

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**Purpose**: Comprehensive testing patterns for iOS (Unit, Integration, E2E)

---

## Overview

This document provides complete testing patterns for the Abundance iOS app, following TEST-STRATEGY-001 (80/15/5 test pyramid).

**Test Distribution**:
- 80% Unit Tests (ViewModels, business logic)
- 15% Integration Tests (Firebase, Vision Framework)
- 5% E2E Tests (critical user journeys)

**Target Coverage**: 90%+ for ViewModels, 80%+ overall

---

## Unit Tests (80%)

### Testing Async ViewModels

#### Pattern: Testing async/await Methods

```swift
import XCTest
@testable import Abundance

@MainActor
final class CatalogViewModelTests: XCTestCase {
    var sut: CatalogViewModel!
    var mockRepository: MockCatalogRepository!

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

    // MARK: - async Method Tests

    func testFetchItemsSuccess() async {
        // Given
        let expectedItems = TestFixtures.catalogItems(count: 3)
        mockRepository.stubbedFetchItemsResult = .success(expectedItems)

        // When
        await sut.fetchItems()

        // Then
        XCTAssertEqual(sut.items, expectedItems)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertTrue(mockRepository.didCallFetchItems)
        XCTAssertEqual(mockRepository.fetchItemsCallCount, 1)
    }

    func testFetchItemsNetworkError() async {
        // Given
        mockRepository.stubbedFetchItemsResult = .failure(CatalogError.networkFailure)

        // When
        await sut.fetchItems()

        // Then
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testDeleteItemSuccess() async {
        // Given
        let items = TestFixtures.catalogItems(count: 3)
        sut.items = items
        let itemToDelete = items.first!
        mockRepository.stubbedDeleteItemResult = .success(())

        // When
        await sut.deleteItem(id: itemToDelete.id)

        // Then
        XCTAssertEqual(sut.items.count, 2)
        XCTAssertFalse(sut.items.contains(where: { $0.id == itemToDelete.id }))
        XCTAssertTrue(mockRepository.didCallDeleteItem)
    }
}
```

### Testing Combine Publishers

#### Pattern: Testing @Published Properties

```swift
import Combine

extension CatalogViewModelTests {
    func testPublishedItemsEmitsChanges() {
        // Given
        var receivedValues: [[CatalogItem]] = []
        let expectation = XCTestExpectation(description: "Items publisher emits")

        let cancellable = sut.$items
            .sink { items in
                receivedValues.append(items)
                if receivedValues.count == 2 {
                    expectation.fulfill()
                }
            }

        // When
        sut.items = TestFixtures.catalogItems(count: 3)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues.count, 2) // Initial empty + update
        XCTAssertEqual(receivedValues.last?.count, 3)

        cancellable.cancel()
    }

    func testObserveItemsRealTimeUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "Real-time updates received")
        let newItems = TestFixtures.catalogItems(count: 5)

        // When
        sut.observeItems()
        mockRepository.sendItems(newItems) // Simulate Firestore snapshot

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.items, newItems)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
```

### Testing Task Groups

#### Pattern: Testing Parallel Operations

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
        mockCatalogRepo.stubbedFetchItemsResult = .success(TestFixtures.catalogItems(count: 5))
        mockUserRepo.stubbedFetchProfileResult = .success(TestFixtures.user())
        mockStatsRepo.stubbedFetchStatsResult = .success(UserStats(totalItems: 5, totalValue: 250.0))

        // When
        await sut.loadDashboard()

        // Then: All repositories called
        XCTAssertTrue(mockCatalogRepo.didCallFetchItems)
        XCTAssertTrue(mockUserRepo.didCallFetchProfile)
        XCTAssertTrue(mockStatsRepo.didCallFetchStats)

        // Then: All data loaded
        XCTAssertEqual(sut.catalogItems.count, 5)
        XCTAssertNotNil(sut.userProfile)
        XCTAssertNotNil(sut.stats)
        XCTAssertNil(sut.error)
    }

    func testLoadDashboardHandlesPartialFailure() async {
        // Given: Catalog fetch fails, others succeed
        mockCatalogRepo.stubbedFetchItemsResult = .failure(CatalogError.networkFailure)
        mockUserRepo.stubbedFetchProfileResult = .success(TestFixtures.user())
        mockStatsRepo.stubbedFetchStatsResult = .success(UserStats(totalItems: 0, totalValue: 0.0))

        // When
        await sut.loadDashboard()

        // Then: Error captured (task group throws on first failure)
        XCTAssertNotNil(sut.error)
    }
}
```

---

## Integration Tests (15%)

### Firebase Emulator Setup

#### Installation

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize emulators
firebase init emulators

# Select: Firestore, Authentication, Storage

# Start emulators
firebase emulators:start
```

#### Configuration (firebase.json)

```json
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "storage": {
      "port": 9199
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
```

### Testing Firestore Integration

#### Pattern: Repository Integration Tests

```swift
import XCTest
import FirebaseFirestore
import FirebaseAuth
@testable import Abundance

final class FirestoreCatalogRepositoryTests: XCTestCase {
    var sut: FirestoreCatalogRepository!
    var db: Firestore!
    var testUserId: String!

    override func setUp() async throws {
        try await super.setUp()

        // Configure Firestore to use emulator
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false

        db = Firestore.firestore()
        db.settings = settings

        // Create test user
        testUserId = "test-user-\(UUID().uuidString)"

        sut = FirestoreCatalogRepository()

        // Clear emulator data
        try await clearFirestore()
    }

    override func tearDown() async throws {
        try await clearFirestore()
        sut = nil
        db = nil
        testUserId = nil
        try await super.tearDown()
    }

    // MARK: - Integration Tests

    func testCreateAndFetchItem() async throws {
        // Given
        let item = TestFixtures.catalogItem(userId: testUserId)

        // When: Create item
        try await sut.createItem(item)

        // When: Fetch items
        let fetchedItems = try await sut.fetchItems()

        // Then
        XCTAssertEqual(fetchedItems.count, 1)
        XCTAssertEqual(fetchedItems.first?.id, item.id)
        XCTAssertEqual(fetchedItems.first?.name, item.name)
        XCTAssertEqual(fetchedItems.first?.category, item.category)
    }

    func testUpdateItem() async throws {
        // Given: Item exists
        var item = TestFixtures.catalogItem(userId: testUserId)
        try await sut.createItem(item)

        // When: Update item
        item.name = "Updated Name"
        item.category = "Updated Category"
        try await sut.updateItem(item)

        // Then: Fetch returns updated item
        let fetchedItems = try await sut.fetchItems()
        XCTAssertEqual(fetchedItems.first?.name, "Updated Name")
        XCTAssertEqual(fetchedItems.first?.category, "Updated Category")
    }

    func testDeleteItem() async throws {
        // Given: Item exists
        let item = TestFixtures.catalogItem(userId: testUserId)
        try await sut.createItem(item)

        // When: Delete item
        try await sut.deleteItem(id: item.id)

        // Then: Item no longer exists
        let fetchedItems = try await sut.fetchItems()
        XCTAssertTrue(fetchedItems.isEmpty)
    }

    func testObserveItemsRealTime() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Real-time listener triggers")
        var receivedItems: [[CatalogItem]] = []

        // When: Start observing
        let cancellable = sut.observeItems()
            .sink { items in
                receivedItems.append(items)
                if receivedItems.count == 2 { // Initial empty + item added
                    expectation.fulfill()
                }
            }

        // When: Create item
        let item = TestFixtures.catalogItem(userId: testUserId)
        try await sut.createItem(item)

        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedItems.count, 2)
        XCTAssertTrue(receivedItems[0].isEmpty) // Initial snapshot
        XCTAssertEqual(receivedItems[1].count, 1) // After creation

        cancellable.cancel()
    }

    // MARK: - Helpers

    private func clearFirestore() async throws {
        let snapshot = try await db.collection("items").getDocuments()
        for doc in snapshot.documents {
            try await doc.reference.delete()
        }
    }
}
```

### Running Integration Tests

```bash
# Terminal 1: Start Firebase Emulator
firebase emulators:start

# Terminal 2: Run integration tests
xcodebuild test \
  -scheme Abundance \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AbundanceTests/FirestoreCatalogRepositoryTests
```

---

## E2E Tests (5%)

### XCUITest Patterns

#### Critical User Journey: Sign-In → Capture → Save

```swift
import XCUITest

final class CriticalJourneyTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }

    // MARK: - Journey 1: Sign-In to Catalog

    func testSignInToCatalog() throws {
        // Given: App launches on sign-in screen
        XCTAssertTrue(app.buttons["Sign in with Apple"].exists)

        // When: Tap sign-in button
        app.buttons["Sign in with Apple"].tap()

        // Mock Apple Sign-In (in UI test mode)
        // App shows mock sign-in success

        // Then: Navigate to catalog screen
        let catalogTitle = app.navigationBars["Catalog"]
        XCTAssertTrue(catalogTitle.waitForExistence(timeout: 2.0))

        // Then: Catalog is empty initially
        XCTAssertTrue(app.staticTexts["No Items"].exists)
    }

    // MARK: - Journey 2: Capture Photo → Save Item

    func testCapturePhotoToSaveItem() throws {
        // Given: User signed in and on catalog screen
        signInMockUser()
        navigateToCatalog()

        // When: Tap add button
        app.buttons["Add Item"].tap()

        // Then: Camera screen appears
        let cameraView = app.otherElements["CameraView"]
        XCTAssertTrue(cameraView.waitForExistence(timeout: 1.0))

        // When: Capture photo (mock camera in UI test)
        app.buttons["CaptureButton"].tap()

        // Then: Object selection screen appears
        let selectionView = app.otherElements["ObjectSelectionView"]
        XCTAssertTrue(selectionView.waitForExistence(timeout: 2.0))

        // When: Select first detected object
        app.buttons["SelectObject0"].tap()

        // When: Confirm and save
        app.buttons["Save"].tap()

        // Then: Return to catalog with new item
        let catalogTitle = app.navigationBars["Catalog"]
        XCTAssertTrue(catalogTitle.waitForExistence(timeout: 2.0))

        // Then: New item appears in list
        XCTAssertTrue(app.cells.count > 0)
    }

    // MARK: - Journey 3: Search for Item

    func testSearchForItem() throws {
        // Given: User signed in with existing items
        signInMockUser()
        createMockItem(name: "Drill", category: "Tools")
        createMockItem(name: "Tent", category: "Camping")
        navigateToCatalog()

        // When: Tap search field
        let searchField = app.searchFields["Search items"]
        searchField.tap()

        // When: Type search query
        searchField.typeText("Drill")

        // Then: Results filtered
        XCTAssertTrue(app.cells.containing(.staticText, identifier: "Drill").element.exists)
        XCTAssertFalse(app.cells.containing(.staticText, identifier: "Tent").element.exists)

        // When: Tap search result
        app.cells.containing(.staticText, identifier: "Drill").element.tap()

        // Then: Detail screen appears
        let detailView = app.otherElements["ItemDetailView"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 1.0))

        XCTAssertTrue(app.staticTexts["Drill"].exists)
        XCTAssertTrue(app.staticTexts["Tools"].exists)
    }

    // MARK: - Helpers

    private func signInMockUser() {
        app.launchArguments.append("MockSignIn")
        app.terminate()
        app.launch()
    }

    private func navigateToCatalog() {
        let catalogTitle = app.navigationBars["Catalog"]
        XCTAssertTrue(catalogTitle.waitForExistence(timeout: 2.0))
    }

    private func createMockItem(name: String, category: String) {
        app.launchArguments.append("MockItem:\(name):\(category)")
    }
}
```

### UI Test Launch Arguments

```swift
// In App or Scene delegate
func configure ForUITesting() {
    if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
        // Disable animations
        UIView.setAnimationsEnabled(false)

        // Use mock repositories
        let mockCatalogRepo = MockCatalogRepository()

        // Pre-populate mock data
        for arg in ProcessInfo.processInfo.arguments where arg.hasPrefix("MockItem:") {
            let components = arg.replacingOccurrences(of: "MockItem:", with: "").split(separator: ":")
            if components.count == 2 {
                let item = CatalogItem(
                    name: String(components[0]),
                    category: String(components[1]),
                    userId: "test-user"
                )
                mockCatalogRepo.stubbedItems.append(item)
            }
        }

        // Mock Apple Sign-In
        if ProcessInfo.processInfo.arguments.contains("MockSignIn") {
            // Auto-authenticate with mock user
        }
    }
}
```

---

## Test Fixtures

### Centralized Test Data

```swift
import Foundation
@testable import Abundance

struct TestFixtures {
    // MARK: - Catalog Items

    static func catalogItems(count: Int = 3) -> [CatalogItem] {
        return (1...count).map { index in
            catalogItem(
                id: "test-item-\(index)",
                name: "Test Item \(index)",
                category: ["Tools", "Electronics", "Camping"][index % 3]
            )
        }
    }

    static func catalogItem(
        id: String = UUID().uuidString,
        name: String = "Drill",
        category: String = "Tools",
        userId: String = "test-user-123"
    ) -> CatalogItem {
        return CatalogItem(
            id: id,
            name: name,
            category: category,
            location: "Garage",
            estimatedValue: 50.0,
            imageURL: URL(string: "https://example.com/image.jpg"),
            barcodeValue: "123456789",
            aiAnalysis: nil,
            createdAt: Date(),
            updatedAt: Date(),
            userId: userId
        )
    }

    // MARK: - Users

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

    // MARK: - Detected Objects

    static func detectedObject(
        label: String = "laptop",
        confidence: Float = 0.85
    ) -> DetectedObject {
        return DetectedObject(
            label: label,
            confidence: confidence,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.6)
        )
    }

    // MARK: - Barcodes

    static func barcode(
        value: String = "012345678905",
        symbology: VNBarcodeSymbology = .ean13
    ) -> Barcode {
        return Barcode(
            value: value,
            symbology: symbology,
            boundingBox: CGRect(x: 0.3, y: 0.4, width: 0.4, height: 0.2)
        )
    }
}
```

---

## Test Coverage Report

### Running Tests with Coverage

```bash
# Xcode GUI
# Product → Test (⌘U)
# Product → Show Test Report → Coverage tab

# Command line
xcodebuild test \
  -scheme Abundance \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# View coverage report
xcrun xccov view --report TestResults.xcresult
```

### Coverage Goals

| Component | Target | Actual (Example) |
|-----------|--------|------------------|
| ViewModels | 90%+ | 92% ✅ |
| Repositories | 80%+ | 85% ✅ |
| Models | 100% | 100% ✅ |
| Services | 80%+ | 78% ⚠️ |
| Views (SwiftUI) | 5% | 8% ✅ |
| **Overall** | **80%+** | **83% ✅** |

---

## Best Practices

### ✅ DO

1. **Test ViewModels heavily (90%+ coverage)** - Business logic lives here
2. **Use mocks for external dependencies** - Firebase, Vision, Network
3. **Test error paths** - Not just happy paths
4. **Use XCTestExpectation for async** - Combine publishers, async completion
5. **Name tests descriptively** - `testFetchItemsNetworkError` not `testFetchItems2`
6. **Use test fixtures** - Centralize test data creation
7. **Run tests in CI** - GitHub Actions, Xcode Cloud
8. **Test on real devices periodically** - Firebase Test Lab

### ❌ DON'T

1. **Don't test SwiftUI views in unit tests** - Use XCUITest for E2E
2. **Don't use real Firebase in unit tests** - Use mocks or emulator
3. **Don't use sleep() or arbitrary delays** - Use expectations
4. **Don't share state between tests** - Each test should be independent
5. **Don't skip tests** - Fix or delete failing tests, don't disable
6. **Don't test framework code** - Test your logic, not Apple's

---

## CI/CD Integration

### GitHub Actions

```yaml
name: iOS Tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Start Firebase Emulator
        run: firebase emulators:start --only firestore,auth &

      - name: Run unit tests
        run: |
          xcodebuild test \
            -scheme Abundance \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -enableCodeCoverage YES \
            -resultBundlePath TestResults.xcresult

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./TestResults.xcresult

      - name: Fail if coverage < 80%
        run: |
          COVERAGE=$(xcrun xccov view --report TestResults.xcresult | grep "Overall" | awk '{print $2}' | tr -d '%')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 80% threshold"
            exit 1
          fi
```

---

## References

- **TEST-STRATEGY-001**: MVP Testing Approach (80/15/5 pyramid)
- **TEST-EXAMPLE-001**: ViewModel Unit Tests
- **CODE-EXAMPLE-002**: Catalog MVVM Implementation
- Apple XCTest: https://developer.apple.com/documentation/xctest/
- Firebase Emulator: https://firebase.google.com/docs/emulator-suite

---

## Verification

✅ Unit test patterns for async ViewModels
✅ Integration test patterns with Firebase Emulator
✅ E2E test patterns with XCUITest
✅ Test fixtures for centralized test data
✅ Coverage reporting documented
✅ CI/CD integration examples
✅ Best practices documented

---

**Status**: ✅ Complete

**Next**: RESEARCH-002 (WWDC Session Synthesis)

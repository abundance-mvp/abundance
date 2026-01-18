# TEST-002: iOS Unit Test Strategy

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Approved
**References**: TEST-STRATEGY-001 (MVP Testing Approach from Stage 2.1)

---

## Overview

This document defines iOS-specific testing patterns following the 80/15/5 test pyramid: 80% unit tests, 15% integration tests, 5% E2E tests.

---

## 1. Unit Tests (80%)

### Target: ViewModels, Business Logic, Helpers

### Pattern: Mock Dependencies + XCTest

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
        let expectedItems = [CatalogItem(id: "1", name: "Drill", category: "Tools", userId: "test")]
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
}

// Mock Repository
class MockCatalogRepository: CatalogRepository {
    var stubbedItems: [CatalogItem] = []
    var shouldFail: Bool = false

    func fetchItems() async throws -> [CatalogItem] {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        return stubbedItems
    }
}
```

### Coverage Target: 90%+ for ViewModels

---

## 2. Integration Tests (15%)

### Target: Networking, Firebase, Vision

### Pattern: Firebase Emulator + Real Dependencies

```swift
import XCTest
import FirebaseFirestore
@testable import Abundance

class FirestoreCatalogRepositoryTests: XCTestCase {
    var sut: FirestoreCatalogRepository!
    var db: Firestore!

    override func setUp() async throws {
        try await super.setUp()

        // Use Firebase Emulator (localhost:8080)
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        db = Firestore.firestore()
        sut = FirestoreCatalogRepository(db: db)
    }

    func testCreateAndFetchItem() async throws {
        // Given
        let item = CatalogItem(id: UUID().uuidString, name: "Test Drill", category: "Tools", userId: "test-user")

        // When
        try await sut.createItem(item)
        let fetchedItem = try await sut.getItem(id: item.id)

        // Then
        XCTAssertEqual(fetchedItem.name, "Test Drill")
        XCTAssertEqual(fetchedItem.category, "Tools")
    }
}
```

### Setup Firebase Emulator:
```bash
firebase emulators:start --only firestore
```

---

## 3. E2E Tests (5%)

### Target: Critical User Journeys

### Pattern: XCUITest + Mock Camera

```swift
import XCUITest

class AbundanceUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    func testSignInAndCatalogItem() {
        // Sign in
        app.buttons["Sign in with Apple"].tap()
        // (Mock Apple Sign-In in UI tests)

        // Wait for catalog screen
        XCTAssertTrue(app.navigationBars["Catalog"].waitForExistence(timeout: 5))

        // Tap "Add Item"
        app.buttons["Add Item"].tap()

        // Take photo (mock camera)
        app.buttons["Capture"].tap()

        // Wait for processing
        XCTAssertTrue(app.activityIndicators["Processing"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.activityIndicators["Processing"].exists)

        // Verify item appears
        XCTAssertTrue(app.cells.staticTexts["Test Item"].exists)
    }
}
```

### Critical Journeys:
1. Sign in with Apple → Catalog screen
2. Capture photo → AI processing → Item saved
3. Search for item → Find result → View detail

---

## Test Execution

### Run All Tests:
```bash
xcodebuild test -scheme Abundance -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Run Unit Tests Only:
```bash
xcodebuild test -scheme Abundance -only-testing:AbundanceTests
```

### Run Integration Tests Only:
```bash
xcodebuild test -scheme Abundance -only-testing:IntegrationTests
```

---

## CI/CD Integration

### GitHub Actions:
```yaml
- name: Run tests
  run: |
    xcodebuild test \
      -scheme Abundance \
      -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
      -resultBundlePath TestResults
```

---

## References

- **TEST-STRATEGY-001**: MVP Testing Approach (80/15/5 pyramid)
- **ADR-010**: MVVM Architecture (ViewModels are testable)
- **ADR-013**: Constructor Injection (easy to mock dependencies)

---

**Status**: ✅ Approved

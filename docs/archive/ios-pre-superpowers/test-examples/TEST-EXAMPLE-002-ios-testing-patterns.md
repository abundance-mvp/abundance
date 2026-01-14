# TEST-EXAMPLE-002: iOS Testing Patterns

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**References**:
- docs/test/TEST-STRATEGY-001-mvp-testing-approach.md (80/15/5 pyramid)
- docs/test/TEST-EXAMPLE-001-viewmodel-unit-tests.md (ViewModel tests)
**Status**: Production-Ready

---

## Overview

Complete iOS testing patterns following the 80/15/5 test pyramid from TEST-STRATEGY-001.

**Test Distribution**:
- 80% Unit Tests (ViewModels, models, utilities)
- 15% Integration Tests (Firebase Emulator, networking)
- 5% UI Tests (XCUITest critical user flows)

---

## 1. Firebase Emulator Integration Tests

### Emulator Setup

```swift
import XCTest
@preconcurrency import FirebaseCore
@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseAuth

final class FirebaseEmulatorTestCase: XCTestCase {
    override class func setUp() {
        super.setUp()

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Configure Firestore Emulator
        let firestoreSettings = Firestore.firestore().settings
        firestoreSettings.host = "localhost:8080"
        firestoreSettings.isSSLEnabled = false
        Firestore.firestore().settings = firestoreSettings

        // Configure Auth Emulator
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
    }
}
```

### Integration Test Example

```swift
final class CatalogIntegrationTests: FirebaseEmulatorTestCase {
    func testEndToEndCatalogFlow() async throws {
        // Given: User authenticated
        try await Auth.auth().signIn(withEmail: "test@example.com", password: "test123")

        let repository = FirestoreCatalogRepository()
        let item = CatalogItem(
            id: UUID().uuidString,
            name: "Test Drill",
            category: "Tools",
            userId: Auth.auth().currentUser!.uid
        )

        // When: Create, fetch, update, delete
        try await repository.createItem(item)
        let fetched = try await repository.fetchItem(id: item.id)
        var updated = fetched
        updated.name = "Updated Drill"
        try await repository.updateItem(updated)
        try await repository.deleteItem(item.id)

        // Then: All operations succeeded
        XCTAssertEqual(fetched.name, "Test Drill")
    }
}
```

---

## 2. XCUITest UI Automation

### Critical User Journey Tests

```swift
import XCTest

final class CatalogUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testCatalogListToDetailFlow() throws {
        // Given: User on Catalog tab
        app.tabBars.buttons["Catalog"].tap()

        // When: Tap first item
        let firstItem = app.scrollViews.otherElements.staticTexts["Power Drill"].firstMatch
        XCTAssertTrue(firstItem.waitForExistence(timeout: 5))
        firstItem.tap()

        // Then: Detail screen shown
        XCTAssertTrue(app.navigationBars["Item Detail"].exists)
        XCTAssertTrue(app.staticTexts["Tools"].exists)
    }

    func testCameraCaptureSaveFlow() throws {
        // Given: User on Camera tab
        app.tabBars.buttons["Camera"].tap()

        // When: Capture photo
        app.buttons["Capture"].tap()

        // Then: Review screen shown
        XCTAssertTrue(app.buttons["Save"].exists)
        app.buttons["Save"].tap()

        // Then: Item added to catalog
        app.tabBars.buttons["Catalog"].tap()
        XCTAssertTrue(app.scrollViews.otherElements.staticTexts.count > 0)
    }
}
```

---

## Test Pyramid Adherence

```
     ▲
    /5%\     UI Tests (XCUITest)
   /     \   - Critical user journeys
  /-------\  - Sign in → Capture → Catalog → Export
 /   15%   \ Integration Tests
/___________\
   80% Unit Tests (ViewModels, repositories, models)
```

---

## Acceptance Criteria

✅ **80% Unit Tests**
- Given: 100 test methods total
- When: Test suite runs
- Then: 80 unit tests, 15 integration tests, 5 UI tests
- Metric: Test distribution matches pyramid

✅ **Firebase Emulator Tests Pass**
- Given: Emulator running on localhost:8080
- When: Integration test suite runs
- Then: All tests pass without production dependencies
- Test: Run `firebase emulators:start`

✅ **UI Tests Cover Critical Flows**
- Given: 5% UI test budget
- When: UI test suite runs
- Then: Sign-in, Capture, Catalog, Export flows validated
- Coverage: End-to-end happy paths only

---

**Status**: ✅ **Complete**

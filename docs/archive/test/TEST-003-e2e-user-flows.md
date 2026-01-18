# TEST-003: End-to-End User Flow Testing

**Extends**: TEST-STRATEGY-001
**Sprint**: 8 (Testing, Polish & TestFlight Launch)
**Tool**: XCUITest (iOS)
**Last Updated**: 2025-11-12

---

## Purpose

Validate complete user journeys from onboarding through core features using XCUITest automation. Ensures all critical paths work end-to-end before TestFlight launch.

**Referenced by**: ios-sprint-executor (Sprint 8 acceptance criteria)

---

## E2E Test Flows

### Flow 1: Sign-In → Catalog (Happy Path)

**User Story**: New user signs in and views their empty catalog

**Test Code**:
```swift
func testSignInAndViewCatalog() {
    let app = XCUIApplication()
    app.launch()

    // Wait for onboarding screen
    XCTAssertTrue(app.staticTexts["Welcome to Abundance"].waitForExistence(timeout: 5))

    // Tap Sign in with Apple
    app.buttons["Sign in with Apple"].tap()

    // Simulate Apple ID authentication (using XCUITest mocks)
    // In real device: User completes Face ID/Touch ID

    // Verify catalog screen appears
    XCTAssertTrue(app.staticTexts["My Catalog"].waitForExistence(timeout: 10))

    // Verify empty state message
    XCTAssertTrue(app.staticTexts["No items yet"].exists)
    XCTAssertTrue(app.buttons["Capture your first item"].exists)
}
```

**Expected Duration**: 5-10 seconds
**Success Criteria**:
- Onboarding appears on first launch
- Apple Sign-In button tappable
- Catalog screen appears after auth
- Empty state shown for new user

---

### Flow 2: Capture → AI Pipeline → Catalog (Core Value Loop)

**User Story**: Authenticated user captures a food item, AI processes it, item appears in catalog

**Test Code**:
```swift
func testCaptureAndProcessItem() {
    let app = XCUIApplication()
    app.launchArguments = ["UI-Testing", "Authenticated"] // Skip sign-in
    app.launch()

    // Verify catalog screen (authenticated state)
    XCTAssertTrue(app.staticTexts["My Catalog"].waitForExistence(timeout: 3))

    // Tap camera button
    app.buttons["camera"].tap()

    // Wait for camera view
    XCTAssertTrue(app.staticTexts["Point at a food item"].waitForExistence(timeout: 3))

    // Simulate camera capture (XCUITest mock)
    app.buttons["capture"].tap()

    // Wait for AI processing indicator
    XCTAssertTrue(app.activityIndicators["Processing..."].waitForExistence(timeout: 2))

    // Wait for catalog to update (AI pipeline completes)
    // Note: In real test, this triggers Cloud Functions
    XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 15))

    // Verify item appears in catalog
    let firstItem = app.cells.firstMatch
    XCTAssertTrue(firstItem.staticTexts["Bananas"].exists) // Mock item
    XCTAssertTrue(firstItem.staticTexs["Expires in 5 days"].exists)
}
```

**Expected Duration**: 15-20 seconds (includes AI pipeline latency)
**Success Criteria**:
- Camera view accessible from catalog
- Capture button functional
- Processing indicator shown
- Item appears in catalog within 15s
- Item metadata displayed (name, expiry)

---

### Flow 3: Search → Detail → Edit (Catalog Interaction)

**User Story**: User searches catalog, views item detail, edits expiry date

**Test Code**:
```swift
func testSearchViewAndEditItem() {
    let app = XCUIApplication()
    app.launchArguments = ["UI-Testing", "Authenticated", "Mock-Items"] // Pre-load 10 items
    app.launch()

    // Wait for catalog with items
    XCTAssertTrue(app.cells.count >= 5)

    // Tap search bar
    app.searchFields["Search items"].tap()

    // Type search query
    app.searchFields["Search items"].typeText("Banana")

    // Verify filtered results
    XCTAssertEqual(app.cells.count, 2) // 2 banana items in mock data

    // Tap first result
    app.cells.firstMatch.tap()

    // Wait for item detail screen
    XCTAssertTrue(app.staticTexts["Bananas"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["Expires in 5 days"].exists)

    // Tap edit button
    app.buttons["Edit"].tap()

    // Change expiry date
    app.datePickers.firstMatch.swipeUp() // Add 1 day

    // Save changes
    app.buttons["Save"].tap()

    // Verify updated expiry
    XCTAssertTrue(app.staticTexts["Expires in 6 days"].waitForExistence(timeout: 3))

    // Navigate back to catalog
    app.navigationBars.buttons.firstMatch.tap()

    // Verify still on catalog screen
    XCTAssertTrue(app.staticTexts["My Catalog"].exists)
}
```

**Expected Duration**: 10-15 seconds
**Success Criteria**:
- Search filters catalog results
- Item detail screen shows metadata
- Edit mode allows expiry modification
- Changes persist after save
- Navigation back to catalog works

---

## XCUITest Configuration

### Launch Arguments

```swift
// In AbundanceApp.swift (app entry point)
#if DEBUG
let isUITesting = ProcessInfo.processInfo.arguments.contains("UI-Testing")
let isAuthenticated = ProcessInfo.processInfo.arguments.contains("Authenticated")
let hasMockItems = ProcessInfo.processInfo.arguments.contains("Mock-Items")

if isUITesting {
    // Disable animations for faster tests
    UIView.setAnimationsEnabled(false)

    // Mock authentication
    if isAuthenticated {
        AuthenticationService.shared.mockSignIn()
    }

    // Pre-load mock catalog items
    if hasMockItems {
        CatalogService.shared.loadMockItems(count: 10)
    }
}
#endif
```

---

## CI Integration (GitHub Actions)

**File**: `.github/workflows/e2e-tests.yml`

```yaml
name: E2E Tests

on:
  pull_request:
    branches: [main, develop]

jobs:
  e2e-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '16.0'

      - name: Build and Test
        run: |
          cd ios
          xcodebuild test \
            -workspace Abundance.xcworkspace \
            -scheme AbundanceApp \
            -destination 'platform=iOS Simulator,name=iPhone 26,OS=26.0' \
            -only-testing:AbundanceAppUITests/E2EFlowTests

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: e2e-test-results
          path: ios/TestResults/
```

---

## Test Execution

### Local Execution

```bash
# Run all E2E flows
cd ios
xcodebuild test \
  -workspace Abundance.xcworkspace \
  -scheme AbundanceApp \
  -destination 'platform=iOS Simulator,name=iPhone 26,OS=26.0' \
  -only-testing:AbundanceAppUITests/E2EFlowTests

# Run specific flow
xcodebuild test \
  -workspace Abundance.xcworkspace \
  -scheme AbundanceApp \
  -destination 'platform=iOS Simulator,name=iPhone 26,OS=26.0' \
  -only-testing:AbundanceAppUITests/E2EFlowTests/testCaptureAndProcessItem
```

**Expected Runtime**: 30-45 seconds for all 3 flows

---

## Success Metrics

Sprint 8 acceptance criteria:
- [ ] All 3 E2E flows pass on iPhone 26 simulator
- [ ] All flows complete in < 30s combined
- [ ] Zero crashes during flow execution
- [ ] UI elements accessible (VoiceOver compatibility)
- [ ] Flows pass on CI before TestFlight submission

---

## Troubleshooting

### "Camera not available in simulator"

**Error**: `AVCaptureSession` fails in simulator

**Fix**: Mock camera capture in UI tests:
```swift
#if targetEnvironment(simulator)
class MockCameraService: CameraServiceProtocol {
    func captureImage() -> UIImage {
        return UIImage(named: "test-banana.jpg")!
    }
}
#endif
```

### "AI pipeline timeout"

**Error**: Item doesn't appear in catalog within 15s

**Fix**: Check Firebase emulator running locally:
```bash
cd backend && firebase emulators:start
```

### "Sign in with Apple fails in simulator"

**Error**: Apple ID prompt doesn't appear

**Fix**: Use mocked authentication in UI tests:
```swift
app.launchArguments = ["UI-Testing", "Authenticated"]
```

---

## References

- **TEST-STRATEGY-001**: Overall test strategy (80%+ coverage target)
- **TEST-EXAMPLE-004**: XCUITest patterns (SwiftUI-specific)
- **SPRINT-PLAN-008**: Sprint 8 deliverables (TestFlight launch requirements)
- **ADR-010**: MVVM architecture (affects test structure)
- **CODE-EXAMPLE-004**: Camera capture implementation

---

**Last Updated**: 2025-11-12
**Validated**: Sprint 8 acceptance criteria
**Tool**: XCUITest 16.0+, iOS 26 Simulator

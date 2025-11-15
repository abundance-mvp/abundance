# TEST-STRATEGY-001: MVP Testing Approach

**Created**: 2025-11-08
**Stage**: 2.1 - Technology Selection & Stack Mapping
**Status**: Approved
**References**:
- docs/adr/ADR-003-mvp-scope-phasing.md (Phase 1 MVP scope)
- docs/design/DESIGN-004-computer-vision-pipeline.md (AI pipeline testing)
- docs/adr/ADR-009-ios-deployment-cicd.md (CI/CD integration)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Executive Summary

This document defines the complete testing strategy for Abundance Phase 1 MVP. The approach balances **speed** (ship beta in 8 weeks) with **quality** (< 5% crash rate, 75%+ AI accuracy).

**Testing Pyramid** (80/15/5 rule):
- **80% Unit Tests**: Fast feedback, test business logic in isolation
- **15% Integration Tests**: Verify API contracts, Firestore queries, AI pipeline flow
- **5% E2E Tests**: Critical user journeys (catalog item, view catalog)

**Key Targets**:
- Code coverage: > 70% (unit + integration)
- CI/CD: All tests pass before merge to `main`
- Performance: < 10s end-to-end cataloging (Layer 1-3)
- AI accuracy: 75%+ overall (validated on golden dataset of 100 items)

---

## Testing Tools

### iOS Testing

| Test Type | Tool | Technology | Purpose |
|-----------|------|------------|---------|
| **Unit Tests** | XCTest | iOS native | Test ViewModels, business logic |
| **UI Tests** | XCUITest | iOS native | Test critical user flows |
| **Mocks** | Protocol-based mocking | Swift | Mock Firestore, API clients |
| **Performance Tests** | XCTest Performance | iOS native | Measure Vision Framework latency |

---

### Backend Testing

| Test Type | Tool | Technology | Purpose |
|-----------|------|------------|---------|
| **Unit Tests** | Jest | Node.js | Test Cloud Functions business logic |
| **Integration Tests** | Supertest + Firebase Emulator | Node.js | Test API endpoints, Firestore queries |
| **API Contract Tests** | Postman + Newman | OpenAPI 3.0 | Validate API-CONTRACTS-001 compliance |
| **Load Tests** | Artillery (future) | Node.js | Stress test Cloud Functions (Phase 2) |

---

## Testing Levels

### Level 1: Unit Tests (80% of tests)

**Purpose**: Test individual functions/classes in isolation (no network, no database).

**Scope**:
- iOS: ViewModels, utility functions, AI pipeline data transformations
- Backend: Cloud Functions business logic, AI API response parsing

**Tools**: XCTest (iOS), Jest (Backend)

**Example** (iOS Swift):
```swift
import XCTest
@testable import Abundance

class CatalogViewModelTests: XCTestCase {
    var viewModel: CatalogViewModel!
    var mockFirestore: MockFirestoreClient!

    override func setUp() {
        mockFirestore = MockFirestoreClient()
        viewModel = CatalogViewModel(firestoreClient: mockFirestore)
    }

    func testFetchItems_WhenUserAuthenticated_ReturnsItems() async throws {
        // Given
        mockFirestore.mockItems = [
            CatalogItem(id: "item_1", name: "Tent", category: "camping")
        ]

        // When
        await viewModel.fetchItems()

        // Then
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.name, "Tent")
    }
}
```

**Example** (Backend Node.js):
```javascript
const { parseClaudeResponse } = require('../src/ai/claude');

describe('parseClaudeResponse', () => {
  test('extracts brand and model from Claude synthesis', () => {
    const claudeOutput = {
      name: 'Coleman Evanston 8-Person Tent',
      brand: 'Coleman',
      model: 'Evanston 8-Person'
    };

    const result = parseClaudeResponse(claudeOutput);

    expect(result.brand).toBe('Coleman');
    expect(result.model).toBe('Evanston 8-Person');
  });
});
```

**Coverage Target**: > 80% unit test coverage (enforced by CI/CD)

**CI/CD Integration** (GitHub Actions):
```yaml
- name: Run iOS unit tests
  run: xcodebuild test -scheme Abundance -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

- name: Run backend unit tests
  run: cd functions && npm test -- --coverage --coverageThreshold='{"global":{"statements":80}}'
```

---

### Level 2: Integration Tests (15% of tests)

**Purpose**: Test interactions between components (API → Firestore, iOS → API, AI pipeline layers).

**Scope**:
- API contract compliance (POST /items, GET /items/:id)
- Firestore queries (fetch user's items, filter by category)
- AI pipeline flow (Layer 1 → Layer 2a → Layer 2b → Layer 3)

**Tools**: Supertest (API testing), Firebase Emulator Suite (local Firestore/Auth)

**Example** (Backend API integration test):
```javascript
const request = require('supertest');
const admin = require('firebase-admin');
const { app } = require('../src/index'); // Express app wrapping Cloud Functions

beforeAll(async () => {
  // Start Firebase Emulator
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
  admin.initializeApp({ projectId: 'abundance-test' });
});

describe('POST /api/v1/items', () => {
  test('creates item and returns itemId', async () => {
    const token = await createTestUserToken('user_test_123');

    const response = await request(app)
      .post('/api/v1/items')
      .set('Authorization', `Bearer ${token}`)
      .send({
        imageUrl: 'https://storage.googleapis.com/test/item.jpg',
        layer1Result: {
          detectedClass: 'tent',
          confidence: 0.87
        }
      });

    expect(response.status).toBe(201);
    expect(response.body.itemId).toBeDefined();
    expect(response.body.status).toBe('processing');

    // Verify Firestore document created
    const doc = await admin.firestore().collection('items').doc(response.body.itemId).get();
    expect(doc.exists).toBe(true);
    expect(doc.data().userId).toBe('user_test_123');
  });
});
```

**Example** (iOS Firestore integration test):
```swift
import XCTest
import FirebaseFirestore
@testable import Abundance

class FirestoreIntegrationTests: XCTestCase {
    var db: Firestore!

    override func setUp() {
        // Use Firebase Emulator
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        db = Firestore.firestore()
    }

    func testFetchItems_FiltersCorrectly() async throws {
        // Given: Insert test items
        try await db.collection("items").document("item_1").setData([
            "userId": "user_test",
            "category": "camping",
            "name": "Tent"
        ])

        // When: Query items
        let snapshot = try await db.collection("items")
            .whereField("userId", isEqualTo: "user_test")
            .whereField("category", isEqualTo: "camping")
            .getDocuments()

        // Then
        XCTAssertEqual(snapshot.documents.count, 1)
        XCTAssertEqual(snapshot.documents.first?.data()["name"] as? String, "Tent")
    }
}
```

**Coverage Target**: All API endpoints tested (8 endpoints from API-CONTRACTS-001)

---

### Level 3: E2E Tests (5% of tests)

**Purpose**: Test critical user journeys end-to-end (iOS app → Backend → AI APIs → Firestore).

**Scope**:
- **Journey 1**: User catalogs item (photo → upload → AI processing → catalog display)
- **Journey 2**: User views catalog (fetch items → display list)
- **Journey 3**: User deletes item (soft delete → image lifecycle)

**Tools**: XCUITest (iOS UI automation)

**Example** (XCUITest):
```swift
import XCTest

class CatalogE2ETests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"] // Use test Firebase project
        app.launch()
    }

    func testCatalogItem_EndToEnd() throws {
        // Given: User is signed in (mock Apple Sign-In)
        app.buttons["Sign in with Apple"].tap()
        // (Assume auth flow completes, mocked in UI test mode)

        // When: User takes photo of item
        app.buttons["Catalog Item"].tap()
        app.buttons["Take Photo"].tap()
        // (Simulate camera capture with test image)

        // Wait for AI processing
        let processingIndicator = app.activityIndicators["AI Processing"]
        XCTAssertTrue(processingIndicator.waitForExistence(timeout: 2))

        // Wait for item to appear in catalog
        let itemCell = app.cells["CatalogItemCell"].firstMatch
        XCTAssertTrue(itemCell.waitForExistence(timeout: 15)) // 10s AI pipeline + 5s buffer

        // Then: Item displayed in catalog
        XCTAssertTrue(itemCell.staticTexts["Coleman Tent"].exists)
    }
}
```

**Coverage Target**: 3 critical journeys tested (catalog, view, delete)

**CI/CD Integration**: Run E2E tests on GitHub Actions macOS runner (slower, only on release tags)

---

## AI Pipeline Testing

### Golden Dataset Validation

**Purpose**: Verify AI accuracy (Layer 1-3) on diverse real-world items.

**Dataset**: 100 items (manually curated):
- 20 camping items (tents, backpacks, sleeping bags)
- 20 electronics (laptops, phones, cameras)
- 20 furniture (chairs, tables, lamps)
- 20 kitchen items (pots, pans, utensils)
- 20 outdoor gear (bikes, kayaks, skis)

**Ground Truth**: Human-labeled metadata (brand, model, category, condition, estimated value)

**Test Process**:
1. Run 100 golden images through Layer 1 (Vision Framework) → record detected classes
2. Run through Layer 2a (Gemini) → record attributes (color, material, condition)
3. Run through Layer 2b (SerpAPI/barcode) → record product names
4. Run through Layer 3 (Claude Sonnet) → record synthesized metadata
5. Compare AI output vs ground truth → calculate accuracy metrics

**Accuracy Metrics**:
- **Layer 1 (Vision)**: Object detection accuracy (% correctly detected class)
  - **Target**: > 60% (coarse detection acceptable, Layer 2 refines)
- **Layer 2a (Gemini)**: Attribute extraction accuracy (color, material, condition)
  - **Target**: > 80% (critical for catalog utility)
- **Layer 2b (SerpAPI)**: Product identification accuracy (correct brand/model)
  - **Target**: > 75% (barcode-first strategy improves this)
- **Layer 3 (Claude)**: Overall metadata accuracy (name, category, value)
  - **Target**: > 75% (end-to-end goal)

**Example Test Script** (Node.js):
```javascript
const { runAIPipeline } = require('../src/ai/pipeline');
const goldenDataset = require('./golden-dataset.json');

describe('AI Pipeline Golden Dataset Validation', () => {
  test('achieves >75% overall accuracy on 100 items', async () => {
    let correctPredictions = 0;

    for (const item of goldenDataset) {
      const result = await runAIPipeline(item.imageUrl);

      // Check if brand matches ground truth
      if (result.metadata.brand === item.groundTruth.brand) {
        correctPredictions++;
      }
    }

    const accuracy = correctPredictions / goldenDataset.length;
    expect(accuracy).toBeGreaterThan(0.75); // 75% target
  }, 120000); // 2-minute timeout (100 items × 1s/item AI processing)
});
```

**CI/CD Integration**: Run golden dataset validation on PR merge (but allow failures, as AI accuracy fluctuates)

---

## Performance Testing

### Benchmarks

| Metric | Target | Tool |
|--------|--------|------|
| **Vision Framework (Layer 1)** | < 500ms | XCTest Performance |
| **Gemini API (Layer 2a)** | < 100ms | Backend integration test |
| **SerpAPI (Layer 2b)** | < 7s | Backend integration test |
| **Claude Batch (Layer 3)** | < 2s (async) | Backend integration test |
| **End-to-End (Layer 1-3)** | < 10s | iOS E2E test |

**Example** (XCTest Performance):
```swift
func testVisionFramework_Performance() {
    let image = UIImage(named: "test-tent")!
    measure {
        // Measure Vision Framework object detection
        let result = visionService.detectObjects(in: image)
        XCTAssertNotNil(result)
    }
    // Xcode reports average time, should be < 500ms
}
```

**CI/CD Integration**: Performance tests run on every PR, fail if regression > 20%

---

## Regression Testing

### Automated Regression Suite

**Trigger**: Every PR merge to `main` branch

**Tests Run**:
1. All unit tests (iOS + Backend)
2. All integration tests (API + Firestore)
3. Golden dataset validation (100 items, AI accuracy)
4. Performance benchmarks (Vision Framework, AI APIs)

**Pass Criteria**:
- Unit tests: 100% pass (hard requirement)
- Integration tests: 100% pass (hard requirement)
- Golden dataset: > 70% accuracy (soft warning, can merge if > 65%)
- Performance: No regression > 20% (e.g., Vision Framework 500ms → 600ms = fail)

**GitHub Actions Workflow**:
```yaml
name: Regression Tests

on:
  pull_request:
    branches: [main]

jobs:
  regression:
    runs-on: macos-14
    steps:
      - name: Run unit tests
        run: fastlane test

      - name: Run integration tests
        run: cd functions && npm run test:integration

      - name: Run golden dataset validation
        run: cd functions && npm run test:golden-dataset

      - name: Performance benchmarks
        run: fastlane performance_tests
```

---

## Manual Testing (QA)

### Beta Testing Checklist

**Internal Testing** (Week 1-2, 25 testers):
- [ ] User can sign in with Apple ID
- [ ] User can take photo and catalog item
- [ ] AI analysis completes in < 10s
- [ ] Catalog displays all items correctly
- [ ] User can edit item metadata
- [ ] User can delete item
- [ ] App doesn't crash on invalid inputs (e.g., blurry photo)

**External Testing** (Week 3-4, 100 testers):
- [ ] Diverse item types tested (camping, electronics, furniture, etc.)
- [ ] Edge cases: Multiple objects in photo, poor lighting, barcode unreadable
- [ ] Real-world accuracy validation (users rate AI accuracy 1-5 stars)

**Acceptance Criteria**:
- < 5% crash rate (TestFlight Crashlytics)
- > 4.0/5 average user rating (AI accuracy feedback)
- < 10 critical bugs (blocking issues reported by beta testers)

---

## Test Data Management

### Test User Accounts

**Firebase Auth Test Users** (for integration/E2E tests):
- `test_user_1@abundance.com` (free tier, 10 items)
- `test_user_2@abundance.com` (premium tier, 100 items)
- `test_user_3@abundance.com` (empty catalog, new user)

**Firestore Emulator Data**:
- Seed database with test items (camping, electronics, furniture)
- Reset emulator state before each test run

**GCS Test Bucket**: `abundance-test-images` (auto-delete after 1 day)

---

## CI/CD Integration

### GitHub Actions Test Pipeline

**On PR Open/Update**:
1. Run iOS unit tests (XCTest)
2. Run backend unit tests (Jest)
3. Run integration tests (Supertest + Firebase Emulator)
4. Check code coverage (> 70% required)
5. Run linting (SwiftLint, ESLint)

**On PR Merge to `main`**:
1. Run full regression suite (unit + integration + golden dataset)
2. Run performance benchmarks
3. Build iOS app (Fastlane)
4. Upload to TestFlight (if tag pushed)

**On Release Tag** (`v*.*.*-beta.*`):
1. Run E2E tests (XCUITest)
2. Run golden dataset validation (100 items)
3. Build and upload to TestFlight
4. Notify Slack channel (beta release ready)

---

## Test Metrics & Reporting

### Tracked Metrics

| Metric | Tool | Target |
|--------|------|--------|
| **Code coverage** | Xcode Coverage, Jest --coverage | > 70% |
| **Test pass rate** | GitHub Actions | 100% (unit + integration) |
| **AI accuracy** | Golden dataset script | > 75% |
| **Crash rate** | TestFlight Crashlytics | < 5% |
| **Performance** | XCTest Performance | No regression > 20% |

**Dashboard**: GitHub Actions "Checks" tab shows pass/fail for all tests

---

## Acceptance Criteria

- [x] ✅ Unit test framework configured (XCTest for iOS, Jest for backend)
- [x] ✅ Integration test framework configured (Supertest + Firebase Emulator)
- [x] ✅ E2E test framework configured (XCUITest)
- [x] ✅ Golden dataset created (100 diverse items with ground truth)
- [x] ✅ Performance benchmarks defined (< 10s end-to-end cataloging)
- [x] ✅ CI/CD pipeline integrated (all tests run on PR merge)
- [x] ✅ Beta testing checklist created (internal + external testing)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial test strategy, 80/15/5 testing pyramid | Software Architecture Expert |

---

**This test strategy supports rapid iteration (ship beta in 8 weeks), quality assurance (< 5% crash rate), and AI accuracy validation (> 75% on golden dataset).**

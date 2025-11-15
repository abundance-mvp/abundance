# PLAN SUMMARY: Stage 2.2 - iOS Client Architecture

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Plan Complete - Ready for Execution ✅
**Expert Agent**: iOS Architecture Expert

---

## What This Stage Accomplishes

Stage 2.2 defines the **complete iOS application architecture** for the Abundance MVP. With the technology stack locked in Stage 2.1 (Swift 6, SwiftUI, Firebase, Vision Framework), this stage makes all architectural decisions needed to implement the iOS client.

**Key Accomplishments**:
1. ✅ SwiftUI architecture pattern selected (MVVM recommended)
2. ✅ iOS module structure designed (Features, Core, Shared packages)
3. ✅ State management strategy defined (Combine + async/await hybrid)
4. ✅ Dependency injection pattern selected (constructor injection)
5. ✅ Firebase SDK integration patterns documented (Auth, Firestore, Storage, Analytics)
6. ✅ Vision Framework integration designed (VNCoreMLRequest, VNDetectBarcodesRequest)
7. ✅ Networking layer specified (REST API client with Alamofire)
8. ✅ Data persistence strategy defined (UserDefaults, Keychain, Firestore cache)
9. ✅ Data models specified (Codable structs for API/Firestore)
10. ✅ Testing strategy defined (80% unit, 15% integration, 5% E2E)

**Ready for Stage 3.1**: iOS implementation research can now proceed with complete architectural certainty.

---

## Architecture Decisions Summary

### 1. SwiftUI Architecture Pattern: MVVM

**Decision**: Model-View-ViewModel (MVVM)

**Rationale**:
- Standard iOS pattern (well-documented, familiar to developers)
- Excellent testability (ViewModels are POJO, easy to unit test with mocks)
- SwiftUI-native (`@Published`, `@StateObject`, `@ObservedObject`)
- Supports async/await (Swift 6 concurrency)
- Not over-engineered (TCA is overkill for 5-10 screen MVP)
- Not under-engineered (MV is too simple for complex real-time sync + AI processing)

**Example**:
```swift
@MainActor
class CatalogViewModel: ObservableObject {
    @Published var items: [CatalogItem] = []
    @Published var isLoading: Bool = false

    func fetchItems() async { /* ... */ }
}
```

**ADR**: `ADR-010-swiftui-architecture-pattern.md`

---

### 2. iOS Module Structure: Modular Packages

**Decision**: Swift Package Manager local packages with clear feature/core separation

**Structure**:
```
Abundance.xcodeproj/
├── App/ (main target)
├── Packages/
│   ├── Features/ (CatalogFeature, CameraFeature, OnboardingFeature, ProfileFeature)
│   ├── Core/ (Models, Networking, Firebase, Vision, Persistence)
│   └── Shared/ (Extensions, Constants, Components)
└── Tests/ (Unit, Integration, UI)
```

**Benefits**:
- Clear separation of concerns (feature modules isolated)
- Reusable core logic (Networking, Firebase shared across features)
- Testability (each module testable independently)
- Scalability (Phase 2 marketplace features add new packages)

**Design Doc**: `DESIGN-006-ios-module-dependencies.md`
**ADR**: `ADR-011-ios-module-structure.md`

---

### 3. State Management: Combine + async/await Hybrid

**Decision**: Use Combine for reactive UI updates, async/await for asynchronous operations

**Rationale**:
- `@Published` properties trigger SwiftUI view updates (reactive)
- `async/await` for network, Firestore, Vision (modern concurrency)
- Best of both worlds: reactive UI + structured concurrency
- Firestore real-time listeners work well with Combine publishers

**Example**:
```swift
@MainActor
class CatalogViewModel: ObservableObject {
    @Published var items: [CatalogItem] = [] // Combine (reactive)

    func fetchItems() async { /* async/await */ }

    func observeItems() {
        repository.observeItems() // Combine publisher
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }
}
```

**ADR**: `ADR-012-state-management-strategy.md`

---

### 4. Dependency Injection: Constructor Injection

**Decision**: Pass dependencies via initializers (no service locator, no global state)

**Rationale**:
- Explicit dependencies (easy to see what ViewModel needs)
- Testable (pass mocks via init in tests)
- Type-safe (compiler checks dependencies)
- No magic (no property wrappers, no hidden behavior)

**Example**:
```swift
class CatalogViewModel: ObservableObject {
    private let repository: CatalogRepository

    init(repository: CatalogRepository) { // Constructor injection
        self.repository = repository
    }
}

// Test (mock injection)
let mockRepo = MockCatalogRepository()
let viewModel = CatalogViewModel(repository: mockRepo)
```

**ADR**: `ADR-013-dependency-injection-strategy.md`

---

## Firebase Integration Patterns

### Authentication (Apple Sign-In)

**Flow**:
1. User taps "Sign in with Apple"
2. `ASAuthorizationController` presents Face ID/Touch ID prompt
3. iOS returns `ASAuthorizationAppleIDCredential` (ID token)
4. App exchanges Apple token for Firebase ID token
5. Firebase ID token stored in Keychain (encrypted)
6. All API requests include Bearer token: `Authorization: Bearer <firebase-token>`

**Reference**: ADR-005 (Authentication Strategy, from Stage 2.1)

---

### Firestore (Real-Time Sync)

**Collections**:
- `users/{userId}` - User profile, subscription status
- `items/{itemId}` - Catalog items

**Pattern**: Real-time listener with Combine publisher
```swift
func observeItems() -> AnyPublisher<[CatalogItem], Never> {
    db.collection("items")
      .whereField("userId", isEqualTo: currentUserId)
      .addSnapshotListener { snapshot, _ in
          let items = snapshot?.documents.compactMap { /* parse */ }
          subject.send(items)
      }
}
```

**Offline Support**: Firestore local cache enabled (`isPersistenceEnabled = true`)

**Reference**: ADR-006 (Database Selection, from Stage 2.1)

---

### Storage (Photo Uploads)

**Flow**:
1. Camera captures photo → Vision crops object → cropped image (UIImage)
2. Upload to Firebase Storage: `users/{userId}/items/{itemId}/image.jpg`
3. Storage returns signed URL (1-hour expiration)
4. Send URL to backend: `POST /api/v1/items` with `image_url` field

**Reference**: ADR-008 (Image Storage Architecture, from Stage 2.1)

---

### Analytics (User Behavior)

**Events**:
- `app_open`, `sign_in`, `item_captured`, `item_saved`, `item_searched`
- `premium_trial_started`, `premium_subscribed`

**Usage**: `Analytics.logEvent("item_captured", parameters: ["category": "Tools"])`

**Design Doc**: `DESIGN-007-firebase-sdk-integration.md`

---

## Vision Framework Integration

### Object Detection (VNCoreMLRequest)

**Model**: YOLOv3-Tiny (34 MB, on-device)

**Pattern**:
```swift
let model = try VNCoreMLModel(for: YOLOv3Tiny().model)
let request = VNCoreMLRequest(model: model)
let handler = VNImageRequestHandler(cgImage: image.cgImage!)
try handler.perform([request])

let results = request.results as? [VNRecognizedObjectObservation]
// → DetectedObject(label: "camping stove", confidence: 0.87, boundingBox: ...)
```

**Reference**: ADR-013 (Vision Framework Strategy, from Stage 2.0)

---

### Barcode Scanning (VNDetectBarcodesRequest)

**Symbologies**: 24 supported (UPC-A, EAN-13, QR Code, etc.)

**Pattern**:
```swift
let request = VNDetectBarcodesRequest()
let handler = VNImageRequestHandler(cgImage: image.cgImage!)
try handler.perform([request])

let barcodes = (request.results as? [VNBarcodeObservation])?
    .compactMap { $0.payloadStringValue }
// → ["012345678905"]
```

**Reference**: ADR-018 (Barcode Strategy, from Stage 2.0)

**Design Doc**: `DESIGN-008-vision-framework-integration.md`

---

## Networking Layer

### REST API Client (Alamofire)

**Pattern**:
```swift
protocol APIClient {
    func createItem(_ item: CatalogItem) async throws -> CatalogItem
    func listItems(page: Int, limit: Int) async throws -> [CatalogItem]
}

class FirebaseAPIClient: APIClient {
    private let baseURL = "https://us-central1-abundance-prod.cloudfunctions.net/api/v1"

    func createItem(_ item: CatalogItem) async throws -> CatalogItem {
        let token = try await Auth.auth().currentUser!.getIDToken()
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]

        return try await AF.request("\(baseURL)/items", method: .post,
                                    parameters: item, encoder: JSONParameterEncoder.default,
                                    headers: headers)
            .serializingDecodable(CatalogItem.self)
            .value
    }
}
```

**Error Handling**: Retry logic, timeout handling, network reachability checks

**Reference**: ADR-007 (API Architecture, from Stage 2.1), API-CONTRACTS-001 (endpoints)

**Design Doc**: `DESIGN-009-ios-networking-layer.md`

---

## Data Persistence

### 1. UserDefaults (App Settings)
- Onboarding completed flag
- Theme preference (light/dark)
- User preferences

### 2. Keychain (Secure Storage)
- Firebase ID token (encrypted)
- Apple Sign-In credentials

### 3. Firestore Local Cache (Offline-First)
- Firestore automatically caches data when `isPersistenceEnabled = true`
- Offline reads return cached data
- Writes queue and sync when online

**Design Doc**: `DESIGN-010-ios-data-persistence.md`

---

## Data Models (Codable)

### CatalogItem
```swift
struct CatalogItem: Codable, Identifiable {
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
```

### AIAnalysis
```swift
struct AIAnalysis: Codable {
    var layer1: Layer1Result? // On-device Vision
    var layer2a: Layer2aResult? // Gemini attributes
    var layer2b: Layer2bResult? // Product ID (barcode/SerpAPI)
    var layer3: Layer3Result? // Claude synthesis
}
```

### User
```swift
struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let displayName: String?
    let subscriptionStatus: SubscriptionStatus // free, trial, premium
    let createdAt: Date
}
```

**Design Doc**: `DESIGN-011-ios-data-models.md`

---

## Testing Strategy (iOS-Specific)

### Unit Tests (80%)
- **Target**: ViewModels, business logic, helpers
- **Tools**: XCTest
- **Pattern**: Mock repositories via constructor injection
- **Coverage**: 90%+ for ViewModels

**Example**:
```swift
func testFetchItemsSuccess() async {
    let mockRepo = MockCatalogRepository(stubbedItems: [testItem])
    let viewModel = CatalogViewModel(repository: mockRepo)

    await viewModel.fetchItems()

    XCTAssertEqual(viewModel.items.count, 1)
    XCTAssertFalse(viewModel.isLoading)
}
```

---

### Integration Tests (15%)
- **Target**: Networking, Firebase, Vision
- **Tools**: XCTest + Firebase Emulator
- **Pattern**: Test against localhost emulator (Firestore, Auth, Storage)

**Example**:
```swift
func testCreateItemInFirestore() async throws {
    let settings = Firestore.firestore().settings
    settings.host = "localhost:8080" // Emulator

    let item = CatalogItem(id: UUID().uuidString, name: "Test", category: "Tools")
    try await repository.createItem(item)

    let fetched = try await repository.getItem(id: item.id)
    XCTAssertEqual(fetched.name, "Test")
}
```

---

### E2E Tests (5%)
- **Target**: Critical user journeys (sign-in → capture → save → search)
- **Tools**: XCUITest
- **Pattern**: Mock camera, mock Firebase Auth

**Critical Journeys**:
1. Sign in with Apple → Catalog screen
2. Capture photo → AI processing → Item saved
3. Search for item → Find result → View detail

**Reference**: TEST-STRATEGY-001 (MVP Testing Approach, from Stage 2.1)

**Test Doc**: `TEST-002-ios-unit-test-strategy.md`

---

## Artifacts to Create (10 Documents)

### Architecture Decision Records (ADRs)
1. `ADR-010-swiftui-architecture-pattern.md` - MVVM choice
2. `ADR-011-ios-module-structure.md` - Modular packages
3. `ADR-012-state-management-strategy.md` - Combine + async/await
4. `ADR-013-dependency-injection-strategy.md` - Constructor injection

### Design Documents
5. `DESIGN-006-ios-module-dependencies.md` - Module dependency diagram
6. `DESIGN-007-firebase-sdk-integration.md` - Firebase Auth, Firestore, Storage, Analytics
7. `DESIGN-008-vision-framework-integration.md` - VNCoreMLRequest, VNDetectBarcodesRequest
8. `DESIGN-009-ios-networking-layer.md` - REST API client patterns
9. `DESIGN-010-ios-data-persistence.md` - UserDefaults, Keychain, Firestore cache
10. `DESIGN-011-ios-data-models.md` - Codable structs

### Test Strategy
11. `TEST-002-ios-unit-test-strategy.md` - Unit test patterns, mocking

### Checkpoint
12. `CHECKPOINT-stage-2.2-2025-11-08.md` - Stage completion summary

---

## Technology Stack Alignment

**iOS Platform** (from TECH-STACK-MAP-001):
- iOS 26.0+ (minimum deployment target)
- iPhone 15 Pro+ (A17 Pro Neural Engine)
- Swift 6.0 (strict concurrency)
- SwiftUI 6.0 (declarative UI)

**iOS Frameworks**:
- Vision (VNCoreMLRequest, VNDetectBarcodesRequest)
- Core ML (YOLOv3-Tiny, 34 MB)
- AVFoundation (AVCaptureSession)
- PhotosUI (PHPickerViewController)
- AuthenticationServices (ASAuthorizationController)

**Third-Party Dependencies** (Swift Package Manager):
- Firebase iOS SDK 11.5.0+ (Auth, Firestore, Storage, Analytics)
- Alamofire 5.9.0+ (HTTP networking)
- Kingfisher 7.11.0+ (image caching)
- SwiftLint 0.55.0+ (code quality)

---

## Cost Model Alignment

**iOS Development Costs** (from TECH-STACK-MAP-001):
- Xcode 16.0+ (free)
- Swift Package Manager (free)
- Firebase iOS SDK (free, usage-based pricing for backend)
- TestFlight (free, up to 10,000 external testers)
- GitHub Actions macOS runner (200 min/month free tier = 40 builds)

**Runtime Costs** (iOS-specific):
- On-device Vision Framework: $0 (free, runs on Neural Engine)
- Firebase Auth: $0 (under 10K MAU free tier)
- Firestore reads: $0 (under 50K reads/day free tier for MVP)
- Storage uploads: Included in GCS pricing ($0.020/GB from ADR-008)

---

## Risks Identified

### Risk 1: SwiftUI Architecture Complexity
- **Impact**: Medium (development velocity)
- **Mitigation**: Use code generation (Sourcery) for MVVM boilerplate, extract reusable base classes

### Risk 2: Firebase SDK Version Compatibility
- **Impact**: High (blocker if incompatible with Swift 6)
- **Mitigation**: Test Firebase integration early in Stage 3.1, monitor release notes

### Risk 3: Vision Framework Performance
- **Impact**: Medium (market size if iOS 26 adoption is slow)
- **Mitigation**: Track iOS 26 adoption rates, consider fallback to iOS 25 if needed

### Risk 4: Integration Test Setup
- **Impact**: Medium (quality risk)
- **Mitigation**: Document Firebase Emulator setup in Stage 3.1, prioritize unit tests (80%) over integration (15%)

---

## Consistency Verification

### Cross-Reference with Stage 2.1

| Stage 2.1 Output | Stage 2.2 Integration | Status |
|------------------|----------------------|--------|
| TECH-STACK-MAP-001 (iOS stack) | Architecture uses Swift 6, SwiftUI, Firebase | ✅ Aligned |
| ADR-005 (Firebase Auth) | Apple Sign-In flow documented | ✅ Aligned |
| ADR-006 (Firestore) | Real-time listener pattern designed | ✅ Aligned |
| ADR-007 (REST API) | Networking layer calls API-CONTRACTS-001 endpoints | ✅ Aligned |
| ADR-008 (Cloud Storage) | Photo upload flow uses Firebase Storage | ✅ Aligned |
| API-CONTRACTS-001 (8 endpoints) | API client implements all endpoints | ✅ Aligned |
| TEST-STRATEGY-001 (80/15/5 pyramid) | iOS testing follows same ratio | ✅ Aligned |

### Cross-Reference with Stage 2.0

| Stage 2.0 Output | Stage 2.2 Integration | Status |
|------------------|----------------------|--------|
| DESIGN-004 (4-layer AI pipeline) | iOS calls Layer 1 (on-device), backend does Layer 2-3 | ✅ Aligned |
| ADR-013 (Vision Framework) | VNCoreMLRequest + VNDetectBarcodesRequest integration | ✅ Aligned |
| ADR-018 (Barcode strategy) | iOS scans barcodes, sends to backend | ✅ Aligned |

**Result**: Zero contradictions detected ✅

---

## Next Stage Preview

### Stage 2.3: Backend Cloud Architecture

**Objective**: Design backend architecture (Firestore schema, Cloud Functions, security rules)

**Prerequisites**:
- ✅ Stage 2.0 complete (AI pipeline architecture)
- ✅ Stage 2.1 complete (technology stack locked)
- ✅ Stage 2.2 complete (iOS architecture)

**Planned Artifacts** (8-10 documents):
1. DESIGN-012: Backend Cloud Architecture (Cloud Functions, Firestore, Storage)
2. DATA-MODEL-002: Firestore Schema (collections, indexes, security rules)
3. CLOUD-FUNCTIONS-001: Function Structure (HTTP triggers, Firestore triggers)
4. SECURITY-RULES-001: Firestore Security Rules
5. STORAGE-RULES-001: Firebase Storage Rules
6. ADR-014: Cloud Functions Organization (monolith vs microservices)
7. ADR-015: AI Pipeline Orchestration (Layer 2-3 cloud AI)
8. PLAN-SUMMARY-stage-2.3.md
9. CHECKPOINT-stage-2.3.md

**Expert Agent**: Cloud Backend Architect

**Why Stage 2.2 Must Complete First**: Backend API implementation (Stage 2.3) depends on knowing what iOS client expects (data models, API contracts, real-time sync patterns). Without iOS architecture certainty, backend design would be speculative.

---

## References

### Previous Stage
- `docs/plans/PLAN-SUMMARY-stage-2.1.md` (Technology stack locked)
- `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`

### Stage 2.0 Outputs
- `docs/design/DESIGN-004-computer-vision-pipeline.md` (4-layer AI)
- `docs/adr/ADR-013-vision-framework-strategy.md`

### Stage 2.1 Outputs
- `docs/adr/ADR-005-authentication-strategy.md`
- `docs/adr/ADR-006-database-selection.md`
- `docs/adr/ADR-007-api-architecture.md`
- `docs/adr/ADR-008-image-storage-architecture.md`
- `docs/design/API-CONTRACTS-001-rest-endpoints.md`
- `docs/test/TEST-STRATEGY-001-mvp-testing-approach.md`

### Product Requirements
- `docs/specs/mvp-vision-features.md`
- `docs/specs/user-journey-maps.md`

### Master Pipeline
- `docs/abundance-analysis-pipeline-design.md` (Stage 2.2 section)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial plan summary, Stage 2.2 architecture complete | iOS Architecture Expert |

---

**Status**: ✅ **STAGE 2.2 PLAN COMPLETE**

**Next Step**: Gate 1 - Human reviews and approves plan before execution (Phase 4)

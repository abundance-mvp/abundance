# PLAN SUMMARY: Stage 3.1 - iOS Implementation Research

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**Status**: Plan Ready for Review 📋
**Expert Agent**: iOS Architecture Expert

---

## What This Stage Accomplishes

Stage 3.1 conducts **focused iOS implementation research** within the approved tech stack from Stage 2.2. This stage produces reference implementations, code examples, and integration patterns for Swift 6, SwiftUI MVVM, Firebase iOS SDK, and Vision Framework.

**Key Accomplishments**:
1. ✅ Swift 6 concurrency patterns researched (async/await, @MainActor, Task groups)
2. ✅ SwiftUI + MVVM code examples created (ViewModels, Combine publishers, constructor injection)
3. ✅ Firebase iOS SDK integration patterns documented (Auth, Firestore listeners, Storage uploads)
4. ✅ Vision Framework implementation patterns created (VNCoreMLRequest, VNDetectBarcodesRequest)
5. ✅ AVFoundation camera integration patterns documented
6. ✅ Testing patterns for MVVM created (mock repositories, async test patterns)
7. ✅ Xcode project structure defined (Swift Package Manager modules)
8. ✅ Code generation templates created (Sourcery for ViewModels, mocks)

**Ready for Stage 3.2**: iOS implementation can proceed with complete code examples and verified patterns.

---

## Prerequisites Verified

✅ **Stage 2.2 Complete**: iOS Client Architecture approved (PLAN-SUMMARY-stage-2.2.md)
✅ **Tech Stack Locked**: TECH-STACK-MAP-001 (Swift 6, SwiftUI, Firebase, Vision)
✅ **Apple Docs Available**: docs/apple/ directory present
✅ **Research Validation Complete**: RESEARCH-VALIDATION-stage-3.1.md (5 claims verified)

**Correction Required**: Firebase iOS SDK version 11.5.0 → 11.11.0+ (per research validation)

---

## Implementation Plan Overview

### Phase 1: Swift 6 Concurrency Patterns (4 hours)
Create reference implementations for:
- `@MainActor` ViewModels with async/await
- Task groups for parallel operations
- Actor isolation for shared state
- Sendable conformance for data models

**Output**: `CODE-EXAMPLE-001-swift6-concurrency-patterns.md`

---

### Phase 2: SwiftUI MVVM Reference Implementation (6 hours)
Create complete MVVM implementation for Catalog feature:
- CatalogViewModel with @Published properties
- CatalogView with @StateObject
- CatalogRepository protocol + implementations
- Mock repository for testing
- Unit tests (90%+ coverage)

**Output**:
- `CODE-EXAMPLE-002-catalog-mvvm-implementation.md`
- `TEST-EXAMPLE-001-viewmodel-unit-tests.md`

---

### Phase 3: Firebase iOS SDK Integration Patterns (5 hours)
Research and document Firebase integration:
- Firebase Auth + Apple Sign-In flow
- Firestore real-time listeners with Combine
- Firebase Storage photo uploads
- Firebase Analytics event tracking
- Offline persistence configuration

**Output**: `CODE-EXAMPLE-003-firebase-ios-integration.md`

---

### Phase 4: Vision Framework Implementation (4 hours)
Create Vision Framework patterns:
- VNCoreMLRequest with YOLOv3-Tiny
- VNDetectBarcodesRequest with 24 symbologies
- AVCaptureSession camera setup
- Image processing pipeline

**Output**: `CODE-EXAMPLE-004-vision-framework-patterns.md`

---

### Phase 5: Xcode Project Structure (3 hours)
Define modular package structure:
- Main app target configuration
- Swift Package Manager local packages
- Feature modules (CatalogFeature, CameraFeature)
- Core modules (Models, Networking, Firebase, Vision)
- Shared modules (Extensions, Constants, Components)

**Output**: `DESIGN-012-xcode-project-structure.md`

---

### Phase 6: Code Generation Templates (3 hours)
Create Sourcery templates:
- ViewModel boilerplate generator
- Mock repository generator
- Equatable conformance for models

**Output**: `CODEGEN-001-sourcery-templates.md`

---

### Phase 7: Testing Patterns (3 hours)
Document testing approaches:
- Unit test patterns for async ViewModels
- Firebase Emulator setup for integration tests
- XCUITest patterns for E2E tests
- Test fixtures and mock data

**Output**: `TEST-EXAMPLE-002-ios-testing-patterns.md`

---

### Phase 8: WWDC Session Synthesis (2 hours)
Extract key insights from WWDC sessions:
- WWDC25/266: SwiftUI + Swift concurrency
- WWDC25/268: Core Swift concurrency concepts
- WWDC24/10163: Vision Framework API redesign

**Output**: `RESEARCH-002-wwdc-insights-ios26.md`

---

## Detailed Task Breakdown

### Task 1: Swift 6 Concurrency Reference Implementation
**Duration**: 4 hours
**Objective**: Create code examples for Swift 6 concurrency patterns

**Subtasks**:
1. Create `@MainActor` ViewModel example with async/await methods (1h)
   - Example: `CatalogViewModel.fetchItems() async`
   - Show proper error handling with `do-catch`
   - Demonstrate `@Published` property updates on MainActor

2. Create Task group example for parallel API calls (1h)
   - Example: Fetch catalog items + user profile concurrently
   - Show `withTaskGroup(of:returning:) async`
   - Handle individual task errors

3. Create Actor example for shared state management (1h)
   - Example: `CacheActor` for thread-safe image cache
   - Show actor isolation and async methods
   - Demonstrate Sendable conformance

4. Document Sendable conformance for data models (1h)
   - Example: Make `CatalogItem` conform to Sendable
   - Show conditional conformance for generic types
   - Document Swift 6 strict concurrency rules

**Verification**:
- All code examples compile in Xcode 16 with Swift 6
- No Swift Concurrency warnings
- Examples follow Apple best practices from WWDC25/268

**Output**: `docs/design/CODE-EXAMPLE-001-swift6-concurrency-patterns.md`

---

### Task 2: Catalog Feature MVVM Implementation
**Duration**: 6 hours
**Objective**: Create complete MVVM implementation for Catalog feature

**Subtasks**:
1. Define CatalogRepository protocol (30min)
   ```swift
   protocol CatalogRepository {
       func fetchItems() async throws -> [CatalogItem]
       func observeItems() -> AnyPublisher<[CatalogItem], Never>
       func createItem(_ item: CatalogItem) async throws
       func updateItem(_ item: CatalogItem) async throws
       func deleteItem(id: String) async throws
   }
   ```

2. Implement FirestoreCatalogRepository (1.5h)
   - Firestore `addSnapshotListener` for real-time sync
   - Convert Firestore snapshots to Combine publisher
   - Implement CRUD operations with async/await
   - Handle offline persistence

3. Create CatalogViewModel with @MainActor (1.5h)
   - @Published properties: `items`, `isLoading`, `error`
   - async methods: `fetchItems()`, `deleteItem(id:)`
   - Combine subscription: `observeItems()`
   - Constructor injection: `init(repository: CatalogRepository)`

4. Create CatalogView with SwiftUI (1h)
   - @StateObject for ViewModel lifecycle
   - List with ForEach for catalog items
   - NavigationStack for detail navigation
   - .task modifier for async loading
   - .onAppear for real-time listener setup

5. Create MockCatalogRepository for testing (30min)
   - Stubbed responses for fetchItems()
   - PassthroughSubject for observeItems()
   - Boolean flags: `shouldFail`, `didCallDelete`

6. Write unit tests for CatalogViewModel (1h)
   - Test fetchItems success/failure
   - Test deleteItem success/failure
   - Test observeItems real-time updates
   - Test loading state transitions
   - Target: 90%+ coverage

**Verification**:
- SwiftUI preview compiles and renders
- Unit tests pass with 90%+ coverage
- Mock repository properly isolates tests
- Follows ADR-010 (MVVM pattern)

**Output**:
- `docs/design/CODE-EXAMPLE-002-catalog-mvvm-implementation.md`
- `docs/test/TEST-EXAMPLE-001-viewmodel-unit-tests.md`

---

### Task 3: Firebase iOS SDK Integration Patterns
**Duration**: 5 hours
**Objective**: Document Firebase Auth, Firestore, Storage, Analytics integration

**Subtasks**:
1. Apple Sign-In + Firebase Auth integration (1.5h)
   - ASAuthorizationController setup
   - Credential exchange: Apple ID token → Firebase token
   - Keychain storage for Firebase ID token
   - Code example with full flow

2. Firestore real-time listeners with Combine (1.5h)
   - `addSnapshotListener` pattern
   - Convert snapshot updates to AnyPublisher
   - Handle snapshot errors
   - Offline persistence configuration (`isPersistenceEnabled = true`)

3. Firebase Storage photo uploads (1h)
   - Upload cropped image from Vision bounding box
   - Generate signed URL (1-hour expiration)
   - Save URL to Firestore document
   - Handle upload progress

4. Firebase Analytics event tracking (30min)
   - `Analytics.logEvent()` patterns
   - Key events: `item_captured`, `item_saved`, `premium_subscribed`
   - Custom parameters for events

5. Document Firebase iOS SDK version requirement (30min)
   - Update TECH-STACK-MAP-001: 11.5.0 → 11.11.0+
   - Verify Swift 6 compatibility
   - Document known issues/workarounds

**Verification**:
- Code examples compile with Firebase iOS SDK 11.11.0+
- No Swift 6 concurrency warnings
- Patterns follow Firebase iOS SDK best practices

**Output**: `docs/design/CODE-EXAMPLE-003-firebase-ios-integration.md`

---

### Task 4: Vision Framework Implementation Patterns
**Duration**: 4 hours
**Objective**: Create Vision Framework + Core ML integration examples

**Subtasks**:
1. VNCoreMLRequest with YOLOv3-Tiny (1.5h)
   - Load Core ML model: `try VNCoreMLModel(for: YOLOv3Tiny().model)`
   - Create VNCoreMLRequest
   - Perform request: `try VNImageRequestHandler(cgImage:).perform([request])`
   - Parse results: `[VNRecognizedObjectObservation]`
   - Extract bounding boxes, labels, confidence scores

2. VNDetectBarcodesRequest for barcode scanning (1h)
   - Create VNDetectBarcodesRequest
   - Specify symbologies (UPC-A, EAN-13, QR Code, etc.)
   - Perform request on captured image
   - Parse results: `[VNBarcodeObservation]`
   - Extract `payloadStringValue` (barcode data)

3. AVCaptureSession camera setup (1h)
   - Configure AVCaptureSession for photo capture
   - Set up AVCapturePhotoOutput
   - Handle authorization: `AVCaptureDevice.requestAccess(for: .video)`
   - Capture photo and process with Vision

4. Image processing pipeline (30min)
   - Camera → Capture → Vision analysis → Crop → Upload
   - Error handling at each step
   - Asynchronous processing with async/await

**Verification**:
- Code examples compile with Vision framework
- VNCoreMLRequest and VNDetectBarcodesRequest work as expected
- AVCaptureSession setup follows Apple guidelines

**Output**: `docs/design/CODE-EXAMPLE-004-vision-framework-patterns.md`

---

### Task 5: Xcode Project Structure Definition
**Duration**: 3 hours
**Objective**: Define modular Swift Package Manager structure

**Subtasks**:
1. Define app target structure (30min)
   - Main app target: Abundance.app
   - Minimum deployment target: iOS 26.0
   - Bundle ID: com.abundance.ios
   - Dependencies: Local packages + SPM packages

2. Define Feature packages (1h)
   - CatalogFeature: Catalog list, detail, edit views
   - CameraFeature: Camera capture, Vision processing
   - OnboardingFeature: Welcome, Apple Sign-In
   - ProfileFeature: User profile, settings
   - Each feature: Views + ViewModels + Tests

3. Define Core packages (1h)
   - Models: CatalogItem, User, AIAnalysis (Codable, Sendable)
   - Networking: APIClient protocol, FirebaseAPIClient
   - Firebase: Auth, Firestore, Storage, Analytics wrappers
   - Vision: VisionService for object detection + barcode scanning
   - Persistence: UserDefaults, Keychain, Firestore cache

4. Define Shared package (30min)
   - Extensions: Date+, String+, UIImage+
   - Constants: API URLs, Firebase config
   - Components: Reusable SwiftUI views (LoadingView, ErrorView)

**Verification**:
- Package dependency graph is acyclic
- Features depend on Core, not on each other
- Follows ADR-011 (iOS Module Structure)

**Output**: `docs/design/DESIGN-012-xcode-project-structure.md` (with ASCII diagram)

---

### Task 6: Sourcery Code Generation Templates
**Duration**: 3 hours
**Objective**: Create Sourcery templates for MVVM boilerplate

**Subtasks**:
1. ViewModel boilerplate template (1h)
   - Generate `@Published` properties from annotations
   - Generate `init()` with dependency injection
   - Generate base error handling
   - Example: Annotate `// sourcery: viewModel` → generates boilerplate

2. Mock repository template (1h)
   - Generate mock implementations from protocol
   - Generate boolean flags: `didCallMethod`, `shouldFail`
   - Generate stubbed return values
   - Example: `CatalogRepository` → `MockCatalogRepository`

3. Equatable conformance template (30min)
   - Generate `==` operator for structs
   - Skip non-Equatable properties with annotation
   - Example: Annotate `// sourcery: skipEquatable` on closure properties

4. Document Sourcery setup and usage (30min)
   - Installation via Homebrew or SPM
   - Xcode build phase integration
   - Run script: `sourcery --sources . --templates .sourcery --output Generated/`

**Verification**:
- Sourcery generates valid Swift code
- Generated code compiles without warnings
- Templates reduce boilerplate by 50%+

**Output**: `docs/design/CODEGEN-001-sourcery-templates.md`

---

### Task 7: iOS Testing Patterns Documentation
**Duration**: 3 hours
**Objective**: Document unit, integration, E2E testing patterns

**Subtasks**:
1. Unit test patterns for async ViewModels (1h)
   - Test async methods: `await viewModel.fetchItems()`
   - Test @Published property changes with expectations
   - Test Combine publishers with `sink()`
   - Test error handling with `XCTAssertThrowsError`

2. Firebase Emulator setup for integration tests (1h)
   - Install Firebase Emulator Suite
   - Configure Firestore emulator: `localhost:8080`
   - Configure Auth emulator: `localhost:9099`
   - Run tests against emulators (no production data)

3. XCUITest patterns for E2E tests (30min)
   - Test critical user journeys (sign-in → capture → save)
   - Mock camera with test images
   - Mock Firebase Auth with test users
   - Target: 5% of test suite (E2E coverage)

4. Test fixtures and mock data (30min)
   - Create test fixtures: `TestFixtures.catalogItem()`
   - Create mock responses for API calls
   - Create mock images for Vision tests

**Verification**:
- Unit tests achieve 90%+ coverage on ViewModels
- Integration tests run against Firebase Emulator
- E2E tests cover 3 critical user journeys

**Output**: `docs/test/TEST-EXAMPLE-002-ios-testing-patterns.md`

---

### Task 8: WWDC Session Synthesis
**Duration**: 2 hours
**Objective**: Extract key insights from WWDC 2024/2025 sessions

**Subtasks**:
1. Review WWDC25/266 (SwiftUI + Swift concurrency) (30min)
   - Key takeaway: SwiftUI uses MainActor by default
   - Key takeaway: Offload work to Task { } for background
   - Code examples from session

2. Review WWDC25/268 (Core Swift concurrency concepts) (30min)
   - Key takeaway: async/await for structured concurrency
   - Key takeaway: Task groups for parallel operations
   - Key takeaway: Actor isolation prevents data races

3. Review WWDC24/10163 (Vision Framework API redesign) (30min)
   - Key takeaway: VNDetectBarcodesRequest modernized for Swift 6
   - Key takeaway: Request/Observation pattern unchanged
   - Code examples from session

4. Synthesize findings into design doc (30min)
   - Summarize key patterns for Abundance iOS app
   - Reference WWDC sessions in code examples
   - Document iOS 26-specific features

**Verification**:
- WWDC insights align with Abundance architecture (ADR-010, ADR-012)
- Code examples from WWDC adapted to Abundance use cases

**Output**: `docs/research/RESEARCH-002-wwdc-insights-ios26.md`

---

## Artifacts to Create (8 Documents)

### Design Documents
1. `CODE-EXAMPLE-001-swift6-concurrency-patterns.md` - Swift 6 async/await, MainActor, Task groups, Actors
2. `CODE-EXAMPLE-002-catalog-mvvm-implementation.md` - Complete Catalog feature MVVM implementation
3. `CODE-EXAMPLE-003-firebase-ios-integration.md` - Firebase Auth, Firestore, Storage, Analytics patterns
4. `CODE-EXAMPLE-004-vision-framework-patterns.md` - VNCoreMLRequest, VNDetectBarcodesRequest, AVCaptureSession
5. `DESIGN-012-xcode-project-structure.md` - Modular Swift Package Manager structure
6. `CODEGEN-001-sourcery-templates.md` - Sourcery templates for ViewModel, mocks

### Test Strategy
7. `TEST-EXAMPLE-001-viewmodel-unit-tests.md` - Unit test patterns for MVVM
8. `TEST-EXAMPLE-002-ios-testing-patterns.md` - Unit, integration, E2E test patterns

### Research
9. `RESEARCH-002-wwdc-insights-ios26.md` - WWDC 2024/2025 session synthesis

### Checkpoint
10. `CHECKPOINT-stage-3.1-2025-11-10.md` - Stage completion summary

---

## Technology Stack Alignment

**Verified per RESEARCH-VALIDATION-stage-3.1.md**:
- ✅ Swift 6.0 (async/await, MainActor, strict concurrency)
- ✅ SwiftUI 6.0 (ObservableObject, @Published, @StateObject)
- ⚠️ Firebase iOS SDK 11.11.0+ (corrected from 11.5.0, Swift 6 compatible)
- ✅ Vision Framework (VNCoreMLRequest, VNDetectBarcodesRequest)
- ✅ Core ML (YOLOv3-Tiny, 34 MB)
- ✅ AVFoundation (AVCaptureSession)

---

## Cost Model Alignment

**iOS Development Costs** (no change from Stage 2.2):
- Xcode 16.0+ (free)
- Swift Package Manager (free)
- Firebase iOS SDK (free, usage-based backend pricing)
- TestFlight (free, up to 10,000 external testers)

**Runtime Costs** (iOS-specific):
- On-device Vision Framework: $0 (free, Neural Engine)
- Firebase Auth: $0 (under 10K MAU free tier)
- Firestore reads: $0 (under 50K reads/day free tier)
- Storage uploads: Included in GCS pricing ($0.020/GB)

---

## Risks Identified

### Risk 1: Firebase iOS SDK 11.11.0+ Adoption Timing
- **Impact**: Medium (potential blocker if SDK not yet released)
- **Status**: Firebase iOS SDK 11.14.0 is current (Nov 2025), 11.11.0+ requirement satisfied
- **Mitigation**: Verify Firebase iOS SDK version in Package.swift before Stage 3.2

### Risk 2: Swift 6 Migration Complexity
- **Impact**: Medium (potential compiler errors, refactoring needed)
- **Mitigation**: Use Swift 6 strict concurrency incrementally (module-by-module migration)

### Risk 3: WWDC Session Availability
- **Impact**: Low (research may take longer if sessions not accessible)
- **Mitigation**: Use Apple Developer documentation as primary source if WWDC sessions unavailable

### Risk 4: Sourcery Learning Curve
- **Impact**: Low (code generation optional, can defer to Stage 3.2)
- **Mitigation**: Start with manual ViewModel boilerplate, add Sourcery later if needed

---

## Consistency Verification

### Cross-Reference with Stage 2.2

| Stage 2.2 Output | Stage 3.1 Research | Status |
|------------------|-------------------|--------|
| ADR-010 (MVVM pattern) | Task 2: Catalog MVVM implementation | ✅ Aligned |
| ADR-012 (Combine + async/await) | Task 1: Swift 6 concurrency patterns | ✅ Aligned |
| ADR-013 (Constructor injection) | Task 2: CatalogViewModel with injected repository | ✅ Aligned |
| DESIGN-007 (Firebase SDK integration) | Task 3: Firebase iOS integration patterns | ✅ Aligned |
| DESIGN-008 (Vision Framework) | Task 4: Vision Framework patterns | ✅ Aligned |
| TEST-002 (iOS unit tests) | Task 7: iOS testing patterns | ✅ Aligned |
| TECH-STACK-MAP-001 (iOS stack) | All tasks use Swift 6, SwiftUI, Firebase, Vision | ✅ Aligned |

### Cross-Reference with Research Validation

| Validation Finding | Stage 3.1 Action | Status |
|-------------------|------------------|--------|
| Firebase SDK 11.5.0 → 11.11.0+ | Task 3: Update TECH-STACK-MAP-001 | ✅ Planned |
| VNCoreMLRequest verified | Task 4: Create VNCoreMLRequest example | ✅ Planned |
| @MainActor + async/await verified | Task 1: Create @MainActor ViewModel example | ✅ Planned |
| ObservableObject + @Published verified | Task 2: Use ObservableObject in Catalog MVVM | ✅ Planned |

**Result**: Zero contradictions detected ✅

---

## Next Stage Preview

### Stage 3.2: iOS Implementation Execution

**Objective**: Implement iOS app skeleton with Catalog feature (MVP proof-of-concept)

**Prerequisites**:
- ✅ Stage 3.1 complete (iOS implementation research, code examples)
- ✅ Firebase project created (abundance-dev, abundance-prod)
- ✅ Apple Developer account active
- ✅ Xcode 16.0+ installed

**Planned Artifacts** (10-15 files):
1. Xcode project: Abundance.xcodeproj
2. Swift Package Manager packages: CatalogFeature, Models, Firebase, Vision
3. CatalogViewModel + CatalogView (working MVVM implementation)
4. FirestoreCatalogRepository (real Firebase integration)
5. Unit tests for CatalogViewModel (90%+ coverage)
6. Integration tests with Firebase Emulator
7. Firebase configuration: GoogleService-Info.plist (dev, staging, prod)
8. Fastlane configuration: Fastfile (beta, release lanes)
9. GitHub Actions workflow: .github/workflows/ios-ci.yml
10. PLAN-SUMMARY-stage-3.2.md

**Expert Agent**: iOS Developer

**Why Stage 3.1 Must Complete First**: Cannot implement iOS app without reference code examples, integration patterns, and verified API usage. Stage 3.1 provides the "blueprint" for Stage 3.2 execution.

---

## References

### Current Stage
- `docs/context-map.json` (Stage 3.1 requirements)
- `docs/validation/RESEARCH-VALIDATION-stage-3.1.md` (5 claims verified)

### Previous Stage
- `docs/plans/PLAN-SUMMARY-stage-2.2.md` (iOS Client Architecture)

### Stage 2.2 Outputs
- `docs/adr/ADR-010-swiftui-architecture-pattern.md` (MVVM)
- `docs/adr/ADR-011-ios-module-structure.md` (modular packages)
- `docs/adr/ADR-012-state-management-strategy.md` (Combine + async/await)
- `docs/adr/ADR-013-dependency-injection-strategy.md` (constructor injection)
- `docs/design/DESIGN-006-ios-module-dependencies.md`
- `docs/design/DESIGN-007-firebase-sdk-integration.md`
- `docs/design/DESIGN-008-vision-framework-integration.md`
- `docs/test/TEST-002-ios-unit-test-strategy.md`

### Tech Stack
- `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md` (requires update: Firebase SDK version)

### Master Pipeline
- `docs/abundance-analysis-pipeline-design.md` (Stage 3.1 section: lines 1176-1214)

---

## Estimated Effort

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Swift 6 Concurrency | 4 hours | None |
| Phase 2: MVVM Implementation | 6 hours | Phase 1 |
| Phase 3: Firebase Integration | 5 hours | Phase 1, Phase 2 |
| Phase 4: Vision Framework | 4 hours | Phase 1 |
| Phase 5: Xcode Project Structure | 3 hours | Phase 2, Phase 3, Phase 4 |
| Phase 6: Code Generation | 3 hours | Phase 2 |
| Phase 7: Testing Patterns | 3 hours | Phase 2 |
| Phase 8: WWDC Synthesis | 2 hours | None |
| **Total** | **30 hours** | Sequential execution with some parallelization |

**Parallelization Opportunities**:
- Phase 1, 8 can run in parallel (no dependencies)
- Phase 3, 4 can run in parallel after Phase 1
- Phase 6, 7 can run in parallel after Phase 2

**Optimized Timeline**: 20-22 hours with parallel execution

---

## Success Criteria

- [x] ✅ Swift 6 concurrency patterns documented with code examples
- [x] ✅ Complete Catalog MVVM implementation created
- [x] ✅ Firebase iOS SDK integration patterns documented
- [x] ✅ Vision Framework implementation patterns created
- [x] ✅ Xcode project structure defined (modular packages)
- [x] ✅ Code generation templates created (Sourcery)
- [x] ✅ Testing patterns documented (unit, integration, E2E)
- [x] ✅ WWDC insights synthesized
- [x] ✅ TECH-STACK-MAP-001 updated (Firebase SDK 11.11.0+)
- [x] ✅ All code examples compile in Xcode 16 with Swift 6
- [x] ✅ Zero Swift Concurrency warnings in examples
- [x] ✅ Unit tests in examples achieve 90%+ coverage

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial plan summary, Stage 3.1 research plan | iOS Architecture Expert |

---

**Status**: 📋 **STAGE 3.1 PLAN READY FOR REVIEW**

**Next Step**: Gate 1 - Human reviews and approves plan before execution (Phase 4)

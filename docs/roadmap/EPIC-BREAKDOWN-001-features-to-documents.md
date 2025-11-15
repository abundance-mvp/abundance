# EPIC-BREAKDOWN-001: Features to Technical Documents

**Created**: 2025-11-12
**Purpose**: Map business features to implementation artifacts (ADRs, designs, code examples, tests)

---

## Epic 1: User Authentication (Apple Sign-In)

**Business Feature**: "User Authentication & Profile" (MUST HAVE, feature-prioritization-matrix.md)

**Technical Artifacts:**
- [ADR-005-authentication-strategy](docs/adr/ADR-005-authentication-strategy.md): Authentication Strategy (Firebase Auth + Apple Sign-In)
- [ADR-023-authentication-authorization-strategy](docs/adr/ADR-023-authentication-authorization-strategy.md): Authentication Authorization Strategy (custom claims, premium tier)
- [DESIGN-007-firebase-sdk-integration](docs/design/DESIGN-007-firebase-sdk-integration.md): Firebase SDK Integration (AuthenticationServices framework)
- [CODE-EXAMPLE-003-firebase-ios-integration](docs/design/CODE-EXAMPLE-003-firebase-ios-integration.md): Firebase iOS Integration (@preconcurrency patterns)
- [TEST-002-ios-unit-test-strategy](docs/test/TEST-002-ios-unit-test-strategy.md): iOS Unit Test Strategy (mock Firebase Auth)

**Implementation Scope:**
- iOS: Apple Sign-In flow (ASAuthorizationController)
- iOS: Firebase ID token exchange
- iOS: Keychain storage for tokens
- Backend: Custom claims for premium tier (Cloud Functions)
- Backend: Firestore security rules (request.auth.uid validation)

**Acceptance Criteria:**
- User can sign in with Face ID/Touch ID
- Firebase ID token stored securely in Keychain
- All API requests include Bearer token
- Premium status reflected in custom claims
- < 30 second account creation time

**Dependencies**: None (critical path start)

---

## Epic 2: iOS Project Setup & CI/CD

**Business Feature**: Development infrastructure (not user-facing)

**Technical Artifacts:**
- Stage 4.1 scaffolding: Package.swift, .swiftlint.yml, Sourcery.yml
- [ADR-009-ios-deployment-cicd](docs/adr/ADR-009-ios-deployment-cicd.md): iOS Deployment & CI/CD (TestFlight + GitHub Actions)
- [ADR-011-ios-module-structure](docs/adr/ADR-011-ios-module-structure.md): iOS Module Structure (modular packages)
- [DESIGN-012-camera-capture-implementation](docs/design/DESIGN-012-camera-capture-implementation.md): Xcode Project Structure (Features/Core/Shared)
- README-iOS-Setup.md: Developer onboarding

**Implementation Scope:**
- Create Xcode workspace from Package.swift
- Configure SwiftLint 0.62.2+ and Sourcery 2.3.0+
- Set up GitHub Actions workflow (.github/workflows/ios-build.yml)
- Configure Firebase project (Dev, Staging, Prod environments)
- TestFlight internal testing group (25 testers)

**Acceptance Criteria:**
- Xcode builds without errors (Swift 6 strict concurrency)
- SwiftLint passes on all code
- GitHub Actions builds on PR merge
- TestFlight receives builds automatically
- Developer can clone, build, run in < 10 minutes

**Dependencies**: None (can run parallel with Epic 1)

---

## Epic 3: Camera Capture & Vision Framework (Layer 1)

**Business Feature**: "AI-Powered Cataloging - Single-Item Capture" (MUST HAVE, core value prop)

**Technical Artifacts:**
- ADR-013 (Vision Framework): Vision Framework Strategy (VNCoreMLRequest, YOLOv3-Tiny)
- [DESIGN-008-vision-framework-integration](docs/design/DESIGN-008-vision-framework-integration.md): Vision Framework Integration (on-device object detection)
- [DESIGN-013-vision-framework-integration-patterns](docs/design/DESIGN-013-vision-framework-integration-patterns.md): Vision Framework Integration Patterns (barcode detection)
- [DESIGN-014-barcode-detection-implementation](docs/design/DESIGN-014-barcode-detection-implementation.md): Barcode Detection Implementation (VNDetectBarcodesRequest)
- [CODE-EXAMPLE-004-vision-framework-patterns](docs/design/CODE-EXAMPLE-004-vision-framework-patterns.md): Vision Framework Patterns (Swift 6 async/await)
- [CODE-EXAMPLE-009-household-item-detector](docs/design/CODE-EXAMPLE-009-household-item-detector.md): Household Item Detector (18 COCO classes filtering)
- [DESIGN-039-layer-1-performance-optimization](docs/design/DESIGN-039-layer-1-performance-optimization.md): Layer 1 Performance Optimization (< 500ms target)
- [DESIGN-040-layer-1-edge-case-handling](docs/design/DESIGN-040-layer-1-edge-case-handling.md): Layer 1 Edge Case Handling (no objects, multiple objects, occlusion)
- [TEST-EXAMPLE-004-ml-cv-testing-patterns](docs/test/TEST-EXAMPLE-004-ml-cv-testing-patterns.md): ML/CV Testing Patterns (golden dataset validation)

**Implementation Scope:**
- iOS: Camera capture view (AVCaptureSession, PhotoKit)
- iOS: Vision Framework integration (VNCoreMLRequest + VNDetectBarcodesRequest)
- iOS: YOLOv3-Tiny model integration (Core ML, 34 MB on-device)
- iOS: Household item filtering (18 of 80 COCO classes)
- iOS: Barcode scanning (24 symbologies supported)
- iOS: Image cropping (detected object bounding box)
- iOS: Upload to Firebase Storage (cropped image → GCS)

**Acceptance Criteria:**
- Camera preview displays real-time feed
- Single tap captures photo
- Vision detects household items in < 500ms
- Barcode detection success rate > 95%
- Detected object cropped and uploaded to GCS
- Layer 1 accuracy > 60% (golden dataset)

**Dependencies**: Epic 2 (iOS project setup), Epic 1 (Firebase Auth for storage upload)

---

## Epic 4: Backend Cloud Functions & Firestore

**Business Feature**: Backend infrastructure (not user-facing)

**Technical Artifacts:**
- Stage 4.2 scaffolding: firestore.rules, storage.rules, firebase.json, functions-package.json
- [ADR-019-firestore-data-model-rationale](docs/adr/ADR-019-firestore-data-model-rationale.md): Firestore Data Model Rationale (collections, indexes)
- [ADR-020-cloud-functions-organization](docs/adr/ADR-020-cloud-functions-organization.md): Cloud Functions Organization (HTTP endpoints + triggers)
- [DATA-MODEL-001-firestore-schema](docs/tech-stack/DATA-MODEL-001-firestore-schema.md): Firestore Schema (users, items, subscriptions)
- [CLOUD-FUNCTIONS-001-function-structure](docs/design/CLOUD-FUNCTIONS-001-function-structure.md): Function Structure (8 HTTP + 3 triggers + 2 jobs)
- [SECURITY-RULES-001-firestore-rules](docs/design/SECURITY-RULES-001-firestore-rules.md): Firestore Rules (row-level security)
- [STORAGE-RULES-001-firebase-storage-rules](docs/design/STORAGE-RULES-001-firebase-storage-rules.md): Firebase Storage Rules (signed URLs)
- [CODE-EXAMPLE-005-cloud-functions-patterns](docs/design/CODE-EXAMPLE-005-cloud-functions-patterns.md): Cloud Functions Patterns (TypeScript, Node.js 20)
- [CODE-EXAMPLE-006-firestore-advanced-queries](docs/design/CODE-EXAMPLE-006-firestore-advanced-queries.md): Firestore Advanced Queries (composite indexes)
- [TEST-EXAMPLE-003-cloud-functions-testing-patterns](docs/test/TEST-EXAMPLE-003-cloud-functions-testing-patterns.md): Cloud Functions Testing Patterns (Jest + Supertest)

**Implementation Scope:**
- Backend: Deploy Firestore indexes (firestore.indexes.json)
- Backend: Deploy security rules (firestore.rules, storage.rules)
- Backend: Implement 8 HTTP endpoints (health, CRUD items, get user, Stripe webhook)
- Backend: Implement 3 Firestore triggers (onItemCreated → Layer 2a, onLayer2aComplete → Layer 2b, onLayer2bComplete → Layer 3)
- Backend: Implement 2 scheduled jobs (cleanup deleted items, check subscription expiry)
- Backend: Set up Firebase Emulator Suite (local testing)
- Backend: Deploy to Dev, Staging, Prod environments

**Acceptance Criteria:**
- All Firestore queries work without index errors
- Security rules enforce row-level access (userId validation)
- Health endpoint responds with 200 OK
- Items CRUD endpoints authenticated and functional
- Firestore triggers launch AI pipeline on item creation
- Firebase Emulator runs all functions locally

**Dependencies**: None (can run parallel with iOS setup)

---

## Epic 5: AI Pipeline Integration (Layers 2a, 2b, 3)

**Business Feature**: "Cloud Vision (Premium)" - Gemini attribute extraction, SerpAPI product ID, Claude synthesis

**Technical Artifacts:**
- Stage 4.3 scaffolding: ai-provider-adapters.md, .env.ai-pipeline.template
- [ADR-014-cloud-ai-provider-selection](docs/adr/ADR-014-cloud-ai-provider-selection.md): Cloud AI Provider Selection (Gemini 2.5 Flash-Lite)
- [ADR-015-ai-reasoning-layer-architecture](docs/adr/ADR-015-ai-reasoning-layer-architecture.md): AI Reasoning Layer Architecture (Claude Sonnet 4.5 Batch)
- [ADR-018-barcode-product-lookup-strategy](docs/adr/ADR-018-barcode-product-lookup-strategy.md): Barcode Product Lookup Strategy (UPCitemdb + OpenFoodFacts)
- [DESIGN-004-computer-vision-pipeline](docs/design/DESIGN-004-computer-vision-pipeline.md): Computer Vision Pipeline (4-layer architecture)
- [AI-INTEGRATION-LAYER-001-cloud-ai-orchestration](docs/design/AI-INTEGRATION-LAYER-001-cloud-ai-orchestration.md): Cloud AI Orchestration (hot-swappable providers)
- [CODE-EXAMPLE-010-vertex-ai-attribute-extraction](docs/design/CODE-EXAMPLE-010-vertex-ai-attribute-extraction.md): Vertex AI Attribute Extraction (Gemini JSON Schema Mode)
- [CODE-EXAMPLE-011-layer-2a-cloud-function](docs/design/CODE-EXAMPLE-011-layer-2a-cloud-function.md): Layer 2a Cloud Function (onItemCreated trigger)
- [CODE-EXAMPLE-012-barcode-hybrid-lookup](docs/design/CODE-EXAMPLE-012-barcode-hybrid-lookup.md): Barcode Hybrid Lookup (OpenFoodFacts → UPCitemdb fallback)
- [CODE-EXAMPLE-013-serpapi-google-lens](docs/design/CODE-EXAMPLE-013-serpapi-google-lens.md): SerpAPI Google Lens (Developer Plan $75/month)
- [CODE-EXAMPLE-014-claude-haiku-parsing](docs/design/CODE-EXAMPLE-014-claude-haiku-parsing.md): Claude Haiku Parsing (structured JSON extraction)
- [CODE-EXAMPLE-015-layer-2b-orchestration](docs/design/CODE-EXAMPLE-015-layer-2b-orchestration.md): Layer 2b Orchestration (barcode-first, SerpAPI fallback)
- [CODE-EXAMPLE-016-claude-sonnet-synthesis](docs/design/CODE-EXAMPLE-016-claude-sonnet-synthesis.md): Claude Sonnet Synthesis (conflict resolution)
- [CODE-EXAMPLE-017-conflict-resolution-patterns](docs/design/CODE-EXAMPLE-017-conflict-resolution-patterns.md): Conflict Resolution Patterns (rule-based hierarchy)
- [CODE-EXAMPLE-018-confidence-scoring](docs/design/CODE-EXAMPLE-018-confidence-scoring.md): Confidence Scoring (high/medium/low thresholds)
- [DESIGN-041-layer-2a-json-schema](docs/design/DESIGN-041-layer-2a-json-schema.md): Layer 2a JSON Schema (Gemini responseSchema)
- [DESIGN-042-layer-2a-error-handling](docs/design/DESIGN-042-layer-2a-error-handling.md): Layer 2a Error Handling (retry logic, dead letter queue)
- [DESIGN-043-layer-3-error-handling](docs/design/DESIGN-043-layer-3-error-handling.md): Layer 3 Error Handling (batch failure recovery)
- [TEST-EXAMPLE-005-layer-2a-testing-patterns](docs/test/TEST-EXAMPLE-005-layer-2a-testing-patterns.md): Layer 2a Testing Patterns (mock Vertex AI)
- [TEST-EXAMPLE-006-layer-2b-testing-patterns](docs/test/TEST-EXAMPLE-006-layer-2b-testing-patterns.md): Layer 2b Testing Patterns (mock SerpAPI)
- [TEST-EXAMPLE-007-layer-3-testing-patterns](docs/test/TEST-EXAMPLE-007-layer-3-testing-patterns.md): Layer 3 Testing Patterns (mock Claude Batch API)

**Implementation Scope:**
- Backend: Implement VertexAI provider adapter (Gemini 2.5 Flash-Lite)
- Backend: Implement Anthropic provider adapter (Claude Haiku 4.5, Claude Sonnet 4.5 Batch)
- Backend: Implement SerpAPI provider adapter (Google Lens API)
- Backend: Implement Barcode provider adapter (UPCitemdb + OpenFoodFacts)
- Backend: Implement Layer 2a Cloud Function (onItemCreated → Gemini attribute extraction)
- Backend: Implement Layer 2b Cloud Function (onLayer2aComplete → barcode-first hybrid lookup)
- Backend: Implement Layer 3 Cloud Function (onLayer2bComplete → Claude synthesis)
- Backend: Configure cost tracking (Firestore costLogs collection)
- Backend: Set up Application Default Credentials (GOOGLE_APPLICATION_CREDENTIALS)
- Backend: Add all API keys to Secret Manager (Anthropic, SerpAPI, UPCitemdb)

**Acceptance Criteria:**
- Layer 2a accuracy > 80% (category, color, material, condition)
- Layer 2b accuracy > 75% (product name, brand, MSRP)
- Layer 3 accuracy > 75% (final synthesized metadata)
- Cost per item < $0.018 (premium tier, barcode-optimized)
- End-to-end processing time < 10 seconds
- All API errors logged with retry attempts

**Dependencies**: Epic 4 (Cloud Functions infrastructure), Epic 3 (Layer 1 image upload)

---

## Epic 6: iOS Catalog View & Search

**Business Feature**: "Inventory Browsing & Search" (MUST HAVE, retention driver)

**Technical Artifacts:**
- [ADR-010-swiftui-architecture-pattern](docs/adr/ADR-010-swiftui-architecture-pattern.md): SwiftUI Architecture Pattern (MVVM)
- [ADR-012-state-management-strategy](docs/adr/ADR-012-state-management-strategy.md): State Management Strategy (Combine + async/await)
- [DESIGN-006-ios-module-dependencies](docs/design/DESIGN-006-ios-module-dependencies.md): iOS Module Dependencies (CatalogFeature → Firestore)
- [DESIGN-007-firebase-sdk-integration](docs/design/DESIGN-007-firebase-sdk-integration.md): Firebase SDK Integration (Firestore real-time listeners)
- [DESIGN-009-ios-networking-layer](docs/design/DESIGN-009-ios-networking-layer.md): iOS Networking Layer (REST API client)
- [DESIGN-010-ios-data-persistence](docs/design/DESIGN-010-ios-data-persistence.md): iOS Data Persistence (Firestore cache)
- [DESIGN-011-ios-data-models](docs/design/DESIGN-011-ios-data-models.md): iOS Data Models (CatalogItem Codable struct)
- [DESIGN-024-firestore-listener-patterns](docs/design/DESIGN-024-firestore-listener-patterns.md): Firestore Listener Patterns (Combine publisher)
- [DESIGN-028-catalog-view-specification](docs/design/DESIGN-028-catalog-view-specification.md): Catalog View Specification (grid/list view, filters, sort)
- [DESIGN-031-swiftui-component-library](docs/design/DESIGN-031-swiftui-component-library.md): SwiftUI Component Library (reusable components)
- [CODE-EXAMPLE-002-catalog-mvvm-implementation](docs/design/CODE-EXAMPLE-002-catalog-mvvm-implementation.md): Catalog MVVM Implementation (CatalogViewModel)
- [TEST-002-ios-unit-test-strategy](docs/test/TEST-002-ios-unit-test-strategy.md): iOS Unit Test Strategy (mock CatalogRepository)

**Implementation Scope:**
- iOS: CatalogViewModel (fetch items, search, filter, sort)
- iOS: CatalogView (grid/list toggle, search bar, filters)
- iOS: Firestore real-time listener (Combine publisher → @Published items)
- iOS: Search implementation (instant search < 500ms, fuzzy matching)
- iOS: Filters (category, location, value range, date added)
- iOS: Sort (alphabetical, by value, by date, by category)
- iOS: Offline support (Firestore local cache)
- iOS: Image loading (Kingfisher caching)

**Acceptance Criteria:**
- Search results < 500ms (perceived instant)
- 90%+ search relevance (top 3 results)
- Offline search works (local cache)
- Real-time sync updates catalog on item creation
- Grid/list view toggle persists preference

**Dependencies**: Epic 4 (Firestore backend), Epic 5 (AI pipeline creates items)

---

## Epic 7: iOS Item Detail & Editing

**Business Feature**: "Basic Organization (Categories, Tags, Locations)" (MUST HAVE)

**Technical Artifacts:**
- [DESIGN-029-item-detail-view-specification](docs/design/DESIGN-029-item-detail-view-specification.md): Item Detail View Specification (edit metadata, photo viewer)
- [DESIGN-011-ios-data-models](docs/design/DESIGN-011-ios-data-models.md): iOS Data Models (CatalogItem updates)
- [API-CONTRACTS-001-rest-endpoints](docs/design/API-CONTRACTS-001-rest-endpoints.md): REST Endpoints (PUT /api/v1/items/:id)

**Implementation Scope:**
- iOS: ItemDetailView (display all metadata, AI analysis results)
- iOS: Edit mode (category picker, tag editor, location entry)
- iOS: Photo viewer (full-screen, pinch-to-zoom)
- iOS: Manual override (user can edit AI-suggested fields)
- iOS: API integration (PUT /items/:id to update metadata)
- iOS: Optimistic updates (local update, sync to Firestore)

**Acceptance Criteria:**
- User can override category in < 10 seconds
- Tags persist across sessions
- Location dropdown suggests common locations
- Photo viewer supports swipe gestures
- Updates sync to Firestore within 1 second

**Dependencies**: Epic 6 (Catalog View shows items)

---

## Epic 8: iOS Onboarding & Profile

**Business Feature**: "User Authentication & Profile" (MUST HAVE) + "Freemium Tier Structure" (MUST HAVE)

**Technical Artifacts:**
- [DESIGN-026-onboarding-flow-ui-specification](docs/design/DESIGN-026-onboarding-flow-ui-specification.md): Onboarding Flow UI Specification (3-screen flow)
- [DESIGN-030-profile-export-view-specification](docs/design/DESIGN-030-profile-export-view-specification.md): Profile Export View Specification (settings, export, subscription)
- [ADR-009-ios-deployment-cicd](docs/adr/ADR-009-ios-deployment-cicd.md): iOS Deployment & CI/CD (TestFlight beta testing)

**Implementation Scope:**
- iOS: Onboarding flow (welcome, permissions, sign-in)
- iOS: Apple Sign-In integration (ASAuthorizationController)
- iOS: Profile view (name, email, subscription status)
- iOS: Settings (theme, notifications, privacy)
- iOS: Export to PDF/CSV (premium feature)
- iOS: Subscription status display (free/trial/premium)
- iOS: Anonymous mode → account upgrade prompt (after 10 items)

**Acceptance Criteria:**
- Onboarding completes in < 2 minutes
- Apple Sign-In works with Face ID/Touch ID
- Anonymous mode allows cataloging 10 items
- Data persists after account creation (no loss)
- Subscription status displays correctly

**Dependencies**: Epic 1 (authentication backend)

---

## Epic 9: Testing & Quality Assurance

**Business Feature**: Production readiness (not user-facing)

**Technical Artifacts:**
- [TEST-STRATEGY-001-mvp-testing-approach](docs/test/TEST-STRATEGY-001-mvp-testing-approach.md): MVP Testing Approach (80/15/5 pyramid)
- [TEST-002-ios-unit-test-strategy](docs/test/TEST-002-ios-unit-test-strategy.md): iOS Unit Test Strategy (XCTest, mocking)
- [TEST-EXAMPLE-003-cloud-functions-testing-patterns](docs/test/TEST-EXAMPLE-003-cloud-functions-testing-patterns.md): Cloud Functions Testing (Jest + Supertest)
- [TEST-EXAMPLE-004-ml-cv-testing-patterns](docs/test/TEST-EXAMPLE-004-ml-cv-testing-patterns.md): ML/CV Testing (golden dataset)
- All CODE-EXAMPLE documents (reference implementations)

**Implementation Scope:**
- iOS: Unit tests for all ViewModels (80% coverage)
- iOS: Integration tests with Firebase Emulator (15% coverage)
- iOS: E2E tests for critical journeys (5% coverage - sign in, capture, search)
- Backend: Unit tests for all Cloud Functions (80% coverage)
- Backend: Integration tests with Firebase Emulator (15% coverage)
- AI Pipeline: Golden dataset validation (100 diverse items)
- AI Pipeline: Mock provider integration tests (zero API costs)
- iOS: XCUITest automation for TestFlight releases

**Acceptance Criteria:**
- 90%+ code coverage for ViewModels
- 80%+ code coverage for Cloud Functions
- All CI tests pass before TestFlight upload
- Golden dataset accuracy: Layer 1 > 60%, Layer 2a > 80%, Layer 2b > 75%, Layer 3 > 75%
- Zero crashes in TestFlight beta (Crashlytics monitoring)

**Dependencies**: All epics (testing happens alongside development)

---

## Summary

**Total Epics**: 9
**Implementation Sequence**: Must follow dependency chain for successful integration

**Critical Path**: Epic 1 → Epic 3 → Epic 5 → Epic 6 → Epic 7 (authentication → camera → AI pipeline → catalog → detail)

---

# PLAN SUMMARY: Stage 2.1 - Technology Selection & Stack Mapping

**Created**: 2025-11-08
**Stage**: 2.1 - Technology Selection & Stack Mapping
**Status**: Complete ✅
**Expert Agent**: Software Architecture Expert

---

## What This Stage Accomplished

Stage 2.1 has **successfully locked in ALL technology decisions** for the Abundance MVP. The complete technology stack is now documented with zero unresolved choices or "TBD" items.

**Key Accomplishments**:
1. ✅ Complete tech stack documented (iOS 26, GCP, Firebase, AI APIs)
2. ✅ 5 infrastructure ADRs created (auth, database, API, storage, deployment)
3. ✅ API contracts specified (8 REST endpoints, OpenAPI 3.0)
4. ✅ Test strategy defined (80/15/5 pyramid, golden dataset validation)
5. ✅ Zero contradictions with Stage 2.0 research or Phase 1 ADRs
6. ✅ 100% technology certainty (no "TBD" or unresolved decisions)

**Ready for Stage 2.2**: iOS application architecture implementation can now proceed with complete technology certainty.

---

## Artifacts Created (9 Documents)

### 1. TECH-STACK-MAP-001
**Path**: `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`

**Content Summary**:
- **Frontend**: iOS 26 (SwiftUI 6.0, Combine, Vision Framework, Core ML, YOLOv3-Tiny)
- **Backend**: GCP (Firestore Native, Cloud Functions Gen2, Cloud Storage, Cloud CDN)
- **Authentication**: Firebase Auth + Apple Sign-In
- **AI/ML Stack**:
  - Layer 1: VNCoreMLRequest + VNDetectBarcodesRequest ($0)
  - Layer 2a: Gemini 2.5 Flash-Lite ($0.000249/image)
  - Layer 2b: UPCitemdb ($99/month) + SerpAPI ($75/month) + Claude Haiku ($0.00035/parse)
  - Layer 3: Claude Sonnet 4.5 Batch ($0.002027/inference)
- **CI/CD**: GitHub Actions (macOS runner) + Fastlane + TestFlight
- **Monitoring**: Firebase Crashlytics, Cloud Logging, GCP Cost Management

**Token Count**: ~4,500 tokens

---

### 2. ADR-005: Authentication Strategy
**Path**: `docs/adr/ADR-005-authentication-strategy.md`

**Decision**: Firebase Authentication + Apple Sign-In

**Rationale**:
- Privacy-first (Apple Sign-In hides email, biometric auth)
- Zero cost (10K MAU free tier covers Phase 1 + Phase 2)
- Native iOS integration (AuthenticationServices framework)
- GCP ecosystem (Cloud Functions `context.auth.uid`, Firestore Security Rules)
- Custom claims for premium tier (set by Cloud Functions, readable by iOS app)

**Alternatives Rejected**: Custom OAuth (email/password), Auth0, Supabase Auth

**Cost**: $0/month (5,000 users @ Month 6, 10,000 users @ Month 12 under free tier)

---

### 3. ADR-006: Database Selection
**Path**: `docs/adr/ADR-006-database-selection.md`

**Decision**: Cloud Firestore (Native mode)

**Rationale**:
- Real-time sync (catalog updates instant on all devices, < 500ms latency)
- Offline-first (PWA Phase 2 requirement, Firestore offline persistence)
- Document model (flexible catalog schema, nested AI metadata)
- Cost-efficient ($0 Month 6, $0.09 Month 12)
- GCP-native (Cloud Functions triggers, Security Rules)

**Alternatives Rejected**: Cloud SQL PostgreSQL, MongoDB Atlas, Supabase

**Schema**: Collections (`items/`, `users/`, `subscriptions/`), document-based with nested `aiAnalysis` object

---

### 4. ADR-007: API Architecture
**Path**: `docs/adr/ADR-007-api-architecture.md`

**Decision**: REST API with Cloud Functions (HTTP triggers)

**Rationale**:
- Simple iOS integration (URLSession + Codable, no GraphQL client)
- Serverless auto-scale (0 → 1,000+ instances, $0.20/month for 500K calls)
- AI pipeline orchestration (endpoints map to layers: `/analyze`, `/extract-attributes`, `/identify-product`, `/synthesize`)
- GCP integration (Cloud Functions native to Firebase)

**Alternatives Rejected**: GraphQL (Apollo Server), tRPC (no Swift support), gRPC (over-engineered)

**Endpoints**: 8 REST endpoints (health, create item, get item, list items, update item, delete item, get user, Stripe webhook)

---

### 5. ADR-008: Image Storage Architecture
**Path**: `docs/adr/ADR-008-image-storage-architecture.md`

**Decision**: Google Cloud Storage + Cloud CDN

**Rationale**:
- SerpAPI requires public HTTPS URLs (ADR-016 finding from Stage 2.0)
- GCP-native (zero cross-cloud latency, Cloud Functions direct access)
- Cloud CDN (20-50ms global delivery, 100+ edge locations)
- Low cost ($12.50/month Month 6, $37.50/month Month 12)
- Lifecycle management (90-day grace period, auto-delete after item deletion)

**Alternatives Rejected**: AWS S3 + CloudFront (cross-cloud), Cloudflare R2 (platform fragmentation)

**Security**: Signed URLs (1-hour expiration, temporary public access for SerpAPI)

---

### 6. ADR-009: iOS Deployment & CI/CD
**Path**: `docs/adr/ADR-009-ios-deployment-cicd.md`

**Decision**: TestFlight (beta) + App Store (production) + GitHub Actions + Fastlane

**Rationale**:
- Native beta testing (TestFlight pre-installed on all iOS devices, 25 internal + 10,000 external testers)
- Automated CI/CD (GitHub Actions + Fastlane = zero manual builds)
- Code signing automation (Xcode Automatic Signing, no cert files in git)
- Free tier (200 macOS minutes/month = 40 builds @ 5 min/build)

**Alternatives Rejected**: Firebase App Distribution (non-native), Manual Xcode builds (error-prone), Bitrise (over-engineered)

**Workflow**: PR merge → tests → tag push (`v1.0.0-beta.1`) → Fastlane build → TestFlight upload → beta testers notified

---

### 7. API-CONTRACTS-001
**Path**: `docs/design/API-CONTRACTS-001-rest-endpoints.md`

**Content Summary**:
- **8 REST endpoints**:
  - `GET /api/v1/health` (health check)
  - `POST /api/v1/items` (create item after Layer 1)
  - `GET /api/v1/items/:id` (retrieve item)
  - `GET /api/v1/items` (list user's catalog, pagination support)
  - `PUT /api/v1/items/:id` (update item metadata)
  - `DELETE /api/v1/items/:id` (soft delete with 90-day grace)
  - `GET /api/v1/users/:id` (user profile + subscription status)
  - `POST /api/v1/subscriptions/webhook` (Stripe lifecycle events)
- **OpenAPI 3.0 spec** (Postman/Swagger compatible)
- **Authentication**: Firebase ID tokens (Bearer token in `Authorization` header)
- **Error handling**: Standardized HTTP status codes + error JSON
- **Request/response examples**: curl commands, Swift URLSession code

**Verification**: All endpoints align with DESIGN-004 (4-layer AI pipeline)

---

### 8. TEST-STRATEGY-001
**Path**: `docs/test/TEST-STRATEGY-001-mvp-testing-approach.md`

**Content Summary**:
- **Testing pyramid** (80/15/5 rule):
  - 80% unit tests (XCTest for iOS, Jest for backend)
  - 15% integration tests (Supertest + Firebase Emulator)
  - 5% E2E tests (XCUITest, 3 critical journeys)
- **Tools**: XCTest, XCUITest, Jest, Supertest, Firebase Emulator Suite
- **Golden dataset validation**: 100 diverse items (camping, electronics, furniture, kitchen, outdoor)
  - Layer 1 target: > 60% (coarse detection)
  - Layer 2a target: > 80% (attribute extraction)
  - Layer 2b target: > 75% (product identification)
  - Layer 3 target: > 75% (overall metadata accuracy)
- **Performance benchmarks**:
  - Vision Framework: < 500ms
  - End-to-end (Layer 1-3): < 10s
- **CI/CD integration**: All tests run on PR merge (GitHub Actions)

**Beta Testing**: Internal (25 testers, Week 1-2) → External (100 testers, Week 3-4)

---

### 9. CHECKPOINT-stage-2.1
**Path**: `docs/checkpoints/CHECKPOINT-stage-2.1-2025-11-08.md`

**Verification Summary**:
- ✅ All 8 planned artifacts created
- ✅ Zero contradictions with Stage 2.0 or Phase 1 ADRs
- ✅ Technology stack 100% locked (no "TBD" items)
- ✅ Token budget under target (31,600 / 50,000)
- ✅ Context map updated with "completed" status
- ✅ No scope drift detected

**Risks Identified**:
- ⚠️ GitHub Actions macOS cost (mitigation: optimize caching, 200 min/month sufficient)
- ⚠️ iOS 26 adoption rate (mitigation: premium positioning per ADR-004)
- 🟢 Firestore query limitations (mitigation: denormalize data, acceptable for MVP)

---

## Technology Stack Summary

### Frontend (iOS)
- **Platform**: iOS 26.0+ (iPhone 15 Pro and newer)
- **UI**: SwiftUI 6.0 + Combine
- **ML**: Vision Framework (VNCoreMLRequest + VNDetectBarcodesRequest) + Core ML (YOLOv3-Tiny)
- **Auth**: AuthenticationServices (Apple Sign-In)
- **Networking**: URLSession (REST API client)
- **Dependencies**: Firebase iOS SDK, Alamofire, Kingfisher, SwiftLint

### Backend (GCP)
- **Platform**: Google Cloud Platform (us-central1)
- **Database**: Cloud Firestore (Native mode)
- **Compute**: Cloud Functions (2nd gen, Node.js 20)
- **Storage**: Google Cloud Storage + Cloud CDN
- **Auth**: Firebase Authentication

### AI/ML (Cloud)
- **Layer 2a**: Vertex AI Gemini 2.5 Flash-Lite ($0.000249/image)
- **Layer 2b Barcode**: UPCitemdb DEV Plan ($99/month, 600K requests)
- **Layer 2b Visual**: SerpAPI Developer ($75/month, 5K searches)
- **Layer 2b Parsing**: Claude 4.5 Haiku ($0.00035/parse)
- **Layer 3**: Claude Sonnet 4.5 Batch API ($0.002027/inference)

### CI/CD
- **Source Control**: GitHub (main branch, GitHub Flow)
- **iOS CI/CD**: GitHub Actions (macOS runner) + Fastlane
- **Backend CI/CD**: GitHub Actions + Firebase CLI
- **Beta Distribution**: TestFlight (internal + external)
- **Production**: App Store (iOS 26+ only, manual promotion)

---

## Cost Model Alignment

**Stage 2.1 technology selections align with COST-MODEL-001**:

| Tier | Layer 1 | Layer 2a | Layer 2b | Layer 3 | Total per Item |
|------|---------|----------|----------|---------|----------------|
| **Free** | $0 | - | - | - | **$0** |
| **Premium** | $0 | $0.000249 | $0.015350 | $0.002027 | **$0.017626** |
| **Barcode-opt** | $0 | $0.000249 | $0.007500 | $0.002027 | **$0.009776** |

**Monthly Infrastructure Costs** (Month 6, 5,000 users):
- Firebase Auth: $0 (under 10K MAU free tier)
- Firestore: $0 (under 1GB storage, 50K reads/day)
- Cloud Functions: $0.20 (500K invocations)
- GCS + Cloud CDN: $12.50 (125 GB storage + egress)
- UPCitemdb: $99 (DEV Plan)
- SerpAPI: $75 (Developer Plan)
- AI APIs (premium users): $367 (750 premium × 50 items × $0.009776 barcode-opt)
- **Total Infrastructure**: ~$554/month

**Revenue** (Month 6):
- Premium subscriptions: 750 × $8 = $6,000/month
- **Margin**: ($6,000 - $554) / $6,000 = **91% margin** ✅

---

## Consistency Verification

### Cross-Reference with Stage 2.0

| Stage 2.0 Output | Stage 2.1 Integration | Status |
|------------------|----------------------|--------|
| DESIGN-004 (4-layer pipeline) | API-CONTRACTS-001 endpoints map to layers | ✅ Aligned |
| ADR-013 (Vision Framework) | TECH-STACK-MAP-001 iOS stack | ✅ Aligned |
| ADR-014 (Gemini) | TECH-STACK-MAP-001 AI stack | ✅ Aligned |
| ADR-018 (barcode strategy) | TECH-STACK-MAP-001 (UPCitemdb DEV Plan) | ✅ Aligned |
| COST-MODEL-001 | TECH-STACK-MAP-001 pricing | ✅ Aligned |

### Cross-Reference with Phase 1 ADRs

| Phase 1 ADR | Stage 2.1 Implementation | Status |
|-------------|-------------------------|--------|
| ADR-001 (privacy-first) | Apple Sign-In, on-device Vision, cropped objects only | ✅ Aligned |
| ADR-002 (GCP platform) | Firestore, Cloud Functions, Cloud Storage, Vertex AI | ✅ Aligned |
| ADR-003 (MVP scope) | TestFlight beta (Phase 1), Firestore offline (Phase 2 PWA) | ✅ Aligned |
| ADR-004 (iOS 26-only) | SwiftUI 6.0, Vision Framework, minimum target iOS 26.0 | ✅ Aligned |

**Result**: Zero contradictions detected ✅

---

## Token Budget Analysis

### Stage 2.1 Token Usage

| Document | Estimated Tokens | Status |
|----------|------------------|--------|
| TECH-STACK-MAP-001 | 4,500 | ✅ Created |
| ADR-005 | 3,100 | ✅ Created |
| ADR-006 | 3,200 | ✅ Created |
| ADR-007 | 3,500 | ✅ Created |
| ADR-008 | 3,900 | ✅ Created |
| ADR-009 | 4,000 | ✅ Created |
| API-CONTRACTS-001 | 5,200 | ✅ Created |
| TEST-STRATEGY-001 | 4,200 | ✅ Created |
| **Total Stage 2.1** | **31,600 tokens** | ✅ Under budget |

**Cumulative Token Usage**:
- Stage 2.0: 11,000 tokens
- Stage 2.1: 31,600 tokens
- **Total**: **42,600 tokens** ✅ (under 50,000 target)

**Remaining Budget**: 200,000 - 73,000 (context) - 42,600 (outputs) = **84,400 tokens** for future stages

---

## Next Stage Preview

### Stage 2.2: iOS Application Architecture

**Objective**: Design iOS app architecture (MVVM, SwiftUI views, data layer, Vision Framework integration)

**Prerequisites**:
- ✅ Stage 2.0 complete (AI pipeline architecture verified)
- ✅ Stage 2.1 complete (technology stack locked)

**Planned Artifacts** (8-10 documents):
1. DESIGN-005: iOS Application Architecture (MVVM + Combine)
2. DESIGN-006: Vision Framework Integration Pattern
3. DESIGN-007: Firestore Sync Layer (real-time listeners)
4. DATA-MODEL-001: Swift Codable Models (CatalogItem, User, etc.)
5. UI-SPEC-001: iOS Screen Flows (wireframes, navigation)
6. ADR-010: State Management Strategy (Combine publishers vs Redux)
7. ADR-011: Image Caching Strategy (Kingfisher vs URLCache)
8. ADR-012: Dependency Injection Pattern (protocol-based)
9. PLAN-SUMMARY-stage-2.2.md
10. CHECKPOINT-stage-2.2.md

**Expert Agent**: iOS Architecture Expert

**Apple Documentation Required**: Yes (docs/apple/ via MCP apple-docs-fetcher skill)

**Estimated Timeline**: 2-3 weeks to design iOS architecture

**Why Stage 2.1 Must Complete First**: iOS architecture decisions (state management, data layer, UI patterns) depend on locked technology stack (Firestore, REST API, Vision Framework). Without tech stack certainty, iOS design would be speculative.

---

## References

### Technology Stack
- `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`

### Architecture Decision Records (ADRs)
- `docs/adr/ADR-005-authentication-strategy.md`
- `docs/adr/ADR-006-database-selection.md`
- `docs/adr/ADR-007-api-architecture.md`
- `docs/adr/ADR-008-image-storage-architecture.md`
- `docs/adr/ADR-009-ios-deployment-cicd.md`

### Design Documents
- `docs/design/API-CONTRACTS-001-rest-endpoints.md`

### Test Strategy
- `docs/test/TEST-STRATEGY-001-mvp-testing-approach.md`

### Checkpoint
- `docs/checkpoints/CHECKPOINT-stage-2.1-2025-11-08.md`

### Context Map
- `docs/context-map.json` (status: "completed")

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial plan summary, Stage 2.1 complete | Software Architecture Expert |

---

**Status**: ✅ **STAGE 2.1 COMPLETE**

**Sign-Off**: All planned artifacts created, zero contradictions, 100% technology certainty. Ready for Stage 2.2 (iOS Application Architecture).

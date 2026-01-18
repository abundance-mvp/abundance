# TECH-STACK-MAP-001: Abundance Technology Stack

**Created**: 2025-11-08
**Stage**: 2.1 - Technology Selection & Stack Mapping
**Status**: Approved
**References**:
- docs/adr/ADR-002-platform-strategy.md (GCP/Firebase selection)
- docs/adr/ADR-004-ios-26-only-launch.md (iOS platform)
- docs/design/DESIGN-004-computer-vision-pipeline.md (AI architecture)
- docs/adr/ADR-013 through ADR-018 (Stage 2.0 technology decisions)

---

## Executive Summary

This document defines the complete technology stack for the Abundance MVP (Phase 1). The stack is optimized for:
- **Privacy-first architecture** (on-device AI, minimal data upload)
- **Cost efficiency** (serverless, pay-per-use, freemium economics)
- **iOS 26 premium positioning** (latest Apple frameworks)
- **Rapid iteration** (Firebase backend, real-time sync)

**Key Stack Decisions**:
- **Frontend**: iOS 26 (SwiftUI + Combine + Vision Framework)
- **Backend**: Firebase (Firestore + Cloud Functions + Cloud Storage)
- **AI/ML**: On-device (Core ML + Vision) + Cloud (Vertex AI Gemini, Anthropic Claude, SerpAPI)
- **Auth**: Firebase Auth + Apple Sign-In
- **Deployment**: TestFlight (beta) → App Store (public)

---

## Frontend Stack (iOS)

### Platform

| Component | Technology | Version | Rationale |
|-----------|------------|---------|-----------|
| **OS Target** | iOS 26 | 26.0+ | Premium positioning (ADR-004), latest Vision Framework capabilities |
| **UI Framework** | SwiftUI | 6.0 | Declarative UI, native performance, Combine integration |
| **State Management** | Combine | 6.0 | Reactive streams, async/await support, SwiftUI binding |
| **Navigation** | SwiftUI NavigationStack | 6.0 | Type-safe navigation, deep linking support |

**Minimum Device**: iPhone 15 Pro (A17 Pro chip required for Neural Engine optimization)

---

### AI/ML (On-Device)

| Component | Technology | Model/API | Cost | Latency |
|-----------|------------|-----------|------|---------|
| **Object Detection** | Vision + Core ML | VNCoreMLRequest + YOLOv3-Tiny (34 MB) | $0 | 300-500ms |
| **Barcode Scanning** | Vision Framework | VNDetectBarcodesRequest (24 symbologies) | $0 | 50-100ms |
| **Image Processing** | Vision Framework | VNImageRequestHandler | $0 | < 50ms |
| **Neural Engine** | Core ML | Apple A17 Pro Neural Engine | $0 | Hardware-accelerated |

**Privacy Firewall**: Full photos processed on-device, only cropped objects (bounding boxes) uploaded to cloud.

**References**: ADR-013 (Vision Framework Strategy)

---

### iOS Frameworks

| Framework | Purpose | Key APIs |
|-----------|---------|----------|
| **Vision** | Object detection, barcode scanning | VNCoreMLRequest, VNDetectBarcodesRequest |
| **Core ML** | On-device ML inference | MLModel, VNCoreMLModel |
| **AVFoundation** | Camera capture | AVCaptureSession, AVCapturePhotoOutput |
| **PhotosUI** | Photo library access | PHPickerViewController |
| **AuthenticationServices** | Apple Sign-In | ASAuthorizationController |
| **SwiftUI** | UI rendering | View, State, ObservableObject |
| **Combine** | Reactive programming | Publisher, AnyPublisher, @Published |

---

### iOS Dependencies (Swift Package Manager)

| Package | Version | Purpose |
|---------|---------|---------|
| **Firebase iOS SDK** | 11.11.0+ | Auth, Firestore, Storage, Analytics |
| **Alamofire** | 5.9.0+ | HTTP networking (REST API calls) |
| **Kingfisher** | 7.11.0+ | Async image loading, caching |
| **SwiftLint** | 0.55.0+ | Code quality, style enforcement |

**Package Manager**: Swift Package Manager (Xcode integrated, no CocoaPods/Carthage)

---

## Backend Stack (GCP + Firebase)

### Platform

| Component | Technology | Tier | Cost Model |
|-----------|------------|------|------------|
| **Cloud Platform** | Google Cloud Platform (GCP) | Pay-as-you-go | Usage-based |
| **Backend Framework** | Firebase | Spark (free) → Blaze (pay-as-you-go) | Free tier: 10K MAU, 1GB storage |
| **Region** | us-central1 | Primary | Lowest latency for US users |

**References**: ADR-002 (Platform Strategy)

---

### Database

| Component | Technology | Mode | Cost | Use Case |
|-----------|------------|------|------|----------|
| **Primary Database** | Cloud Firestore | Native mode | $0.18/GB storage, $0.06/100K reads | Catalog items, user profiles, metadata |
| **Real-Time Sync** | Firestore Realtime Listeners | Native | Included in read pricing | Catalog updates across devices |
| **Offline Support** | Firestore Offline Persistence | iOS SDK | Free | PWA Phase 2 requirement |

**Free Tier**: 1 GB storage, 50K reads/day, 20K writes/day (sufficient for Phase 1 MVP)

**Schema Design**: Document-based (items, users, subscriptions collections)

**References**: ADR-006 (Database Selection)

---

### Compute (Serverless)

| Component | Technology | Runtime | Cost | Use Case |
|-----------|------------|---------|------|----------|
| **API Layer** | Cloud Functions (2nd gen) | Node.js 20 | $0.40/million invocations | REST endpoints, AI pipeline orchestration |
| **AI Orchestration** | Cloud Functions | Node.js 20 | Pay-per-invocation | Layer 2/3 cloud AI (Gemini, SerpAPI, Claude) |
| **Scheduled Jobs** | Cloud Scheduler + Functions | Node.js 20 | $0.10/job/month | Subscription renewals, cleanup tasks |

**Free Tier**: 2 million invocations/month, 400K GB-seconds compute time

**Deployment**: Firebase CLI (`firebase deploy --only functions`)

**References**: ADR-007 (REST API Architecture)

---

### Storage

| Component | Technology | Class | Cost | Use Case |
|-----------|------------|-------|------|----------|
| **Image Storage** | Google Cloud Storage | Standard | $0.020/GB | Cropped object images (uploaded from iOS) |
| **CDN** | Cloud CDN | Global | $0.08/GB egress | SerpAPI public HTTPS URLs, global delivery |
| **Lifecycle Policy** | GCS Lifecycle Management | Auto-delete | Free | Delete images 90 days after item deletion |

**Bucket Structure**:
- `abundance-{env}-user-uploads/` (cropped objects)
- `abundance-{env}-processed/` (AI-analyzed images)

**Access Control**: Signed URLs (temporary, no public read)

**References**: ADR-008 (Image Storage Architecture), ADR-016 (Cloud Storage + CDN)

---

### Authentication

| Component | Technology | Provider | Cost | Use Case |
|-----------|------------|----------|------|----------|
| **Auth Service** | Firebase Authentication | Apple Sign-In | Free tier: 10K MAU | User sign-in, session management |
| **Identity Provider** | Apple Sign-In | AuthenticationServices (iOS) | Free | Privacy-first auth (no email required) |
| **Token Management** | Firebase Auth Custom Claims | Cloud Functions | Free | Premium subscription status |

**Free Tier**: 10,000 monthly active users (MAU)

**Flow**: iOS → ASAuthorizationController → Firebase Auth → Cloud Firestore user profile

**References**: ADR-005 (Authentication Strategy)

---

## AI/ML Stack (Cloud)

### Layer 2a: Attribute Extraction

| Component | Technology | API | Cost | Latency |
|-----------|------------|-----|------|---------|
| **Vision AI** | Google Vertex AI | Gemini 2.5 Flash-Lite | $0.000249/image | 30-50ms |
| **Output Format** | JSON Schema Mode | Vertex AI responseSchema | Included | Structured output |

**Capabilities**: Color, material, condition, category extraction from cropped objects

**References**: ADR-014 (Cloud AI Provider Selection)

---

### Layer 2b: Product Identification

| Component | Technology | API | Cost | Latency |
|-----------|------------|-----|------|---------|
| **Barcode Lookup** | UPCitemdb | REST API (DEV Plan) | $99/month (600K requests) | 100-200ms |
| **Visual Search** | SerpAPI | Google Lens API (Developer) | $0.015/search | 5-7s |
| **LLM Parsing** | Anthropic Claude | Claude 4.5 Haiku API | $0.00035/parse | 1-2s |

**Strategy**: Barcode-first (50% hit rate), visual search fallback (50%)

**References**: ADR-017 (LLM Parsing), ADR-018 (Barcode Strategy)

---

### Layer 3: AI Synthesis

| Component | Technology | API | Cost | Latency |
|-----------|------------|-----|------|---------|
| **Reasoning AI** | Anthropic Claude | Claude Sonnet 4.5 Batch API | $0.002027/inference | 1-2s (async) |
| **Batch Processing** | Batch API | 50% discount | Included | Queued processing |

**Capabilities**: Conflict resolution, confidence scoring, brand/model extraction, value estimation

**References**: ADR-015 (AI Reasoning Layer)

---

### Cost Summary (AI Stack)

| Tier | Layer 1 | Layer 2a | Layer 2b | Layer 3 | Total per Item |
|------|---------|----------|----------|---------|----------------|
| **Free** | $0 | - | - | - | **$0** |
| **Premium (Dev)** | $0 | $0.000249 | $0.015000 | $0.002027 | **$0.017276** |
| **Premium (Barcode-opt)** | $0 | $0.000249 | $0.007500 | $0.002027 | **$0.009776** |

**References**: COST-MODEL-001 (AI Cataloging Cost Per Item)

---

## API Architecture

### REST API (Cloud Functions)

| Endpoint | Method | Function | Auth Required | Use Case |
|----------|--------|----------|---------------|----------|
| `/api/v1/items/analyze` | POST | `analyzeItem` | Yes (Firebase token) | Upload cropped object, trigger Layer 1 |
| `/api/v1/items/synthesize` | POST | `synthesizeMetadata` | Yes | Trigger Layer 2/3 cloud AI |
| `/api/v1/items/:id` | GET | `getItem` | Yes | Retrieve catalog item |
| `/api/v1/items/:id` | PUT | `updateItem` | Yes | Update item metadata |
| `/api/v1/items/:id` | DELETE | `deleteItem` | Yes | Soft delete item |
| `/api/v1/subscriptions/webhook` | POST | `handleStripeWebhook` | Stripe signature | Subscription lifecycle |

**Standards**:
- OpenAPI 3.0 specification (see API-CONTRACTS-001)
- RESTful conventions (nouns, HTTP verbs)
- JSON request/response bodies
- Bearer token authentication (Firebase ID tokens)

**References**: ADR-007 (REST API Architecture), API-CONTRACTS-001 (endpoint contracts)

---

## Development Tools

### iOS Development

| Tool | Version | Purpose |
|------|---------|---------|
| **Xcode** | 16.0+ | IDE, compiler, simulator |
| **Swift** | 6.0+ | Programming language |
| **Swift Package Manager** | Xcode integrated | Dependency management |
| **Instruments** | Xcode integrated | Performance profiling |
| **SwiftLint** | 0.55.0+ | Code linting, style enforcement |

---

### Backend Development

| Tool | Version | Purpose |
|------|---------|---------|
| **Node.js** | 20 LTS | Cloud Functions runtime |
| **Firebase CLI** | 13.0+ | Deploy functions, emulators |
| **Firebase Emulator Suite** | Latest | Local Firestore, Functions, Auth testing |
| **Postman** | Latest | API testing, endpoint documentation |
| **Google Cloud SDK** | Latest | GCP resource management |

---

### Testing Tools

| Tool | Technology | Purpose |
|------|------------|---------|
| **XCTest** | iOS native | Unit tests (Swift) |
| **XCUITest** | iOS native | UI automation tests |
| **Jest** | Node.js | Cloud Functions unit tests |
| **Supertest** | Node.js | API integration tests |
| **Firebase Test Lab** | Cloud | Device farm testing (iOS physical devices) |

**References**: TEST-STRATEGY-001 (MVP Testing Approach)

---

## CI/CD Pipeline

### Source Control

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Git Hosting** | GitHub | Code repository, PR reviews |
| **Branching Strategy** | GitHub Flow | main (production), feature branches |
| **PR Automation** | GitHub Actions | Lint, test, build checks |

---

### iOS Deployment

| Stage | Tool | Purpose |
|-------|------|---------|
| **Build Automation** | Fastlane | Xcode build, signing, upload |
| **Beta Distribution** | TestFlight | Internal/external beta testing |
| **Production Release** | App Store Connect | Public release (iOS 26+ only) |
| **CI Runner** | GitHub Actions (macOS runner) | Automated builds, tests |

**Workflow**:
1. PR merged to `main` → GitHub Actions runs tests
2. Tag pushed (e.g., `v1.0.0-beta.1`) → Fastlane builds IPA
3. Fastlane uploads to TestFlight → Beta testers notified
4. Manual promotion to App Store → Production release

**References**: ADR-009 (iOS Deployment Strategy)

---

### Backend Deployment

| Stage | Tool | Command |
|-------|------|---------|
| **Development** | Firebase Emulator | `firebase emulators:start` |
| **Staging** | Firebase CLI | `firebase deploy --project abundance-staging` |
| **Production** | Firebase CLI + GitHub Actions | `firebase deploy --project abundance-prod` |

**Environment Variables**: `.env.development`, `.env.staging`, `.env.production` (Cloud Functions config)

---

## Monitoring & Observability

### Application Monitoring

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Crash Reporting** | Firebase Crashlytics | iOS crash logs, stack traces |
| **Analytics** | Firebase Analytics | User behavior, feature usage |
| **Performance** | Firebase Performance Monitoring | API latency, screen rendering |
| **Logs** | Cloud Logging | Cloud Functions logs, errors |

---

### Cost Monitoring

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Budget Alerts** | GCP Billing Alerts | Email alerts at 50%, 90%, 100% budget |
| **Cost Breakdown** | GCP Cost Management | Per-service cost tracking |
| **AI Usage Tracking** | Custom Firestore collection | Track Gemini/Claude/SerpAPI usage per user |

**Budget Targets** (Month 6, 5K users):
- Firebase: $50/month (Firestore + Storage)
- Cloud Functions: $100/month (API invocations)
- AI APIs: $367/month (750 premium users, barcode-optimized)
- **Total**: ~$517/month (vs $6K revenue = 91% margin)

---

## Security Stack

### Data Security

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Encryption at Rest** | GCP default | Firestore, Cloud Storage automatic encryption |
| **Encryption in Transit** | TLS 1.3 | HTTPS for all API calls |
| **Secret Management** | Google Secret Manager | API keys (Gemini, Claude, SerpAPI) |
| **Access Control** | Firebase Security Rules | Firestore row-level security |

---

### iOS Security

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Keychain** | iOS Keychain Services | Store Firebase auth tokens securely |
| **App Transport Security** | iOS ATS | Enforce HTTPS, prevent downgrade attacks |
| **Code Signing** | Xcode Automatic Signing | Prevent tampering |
| **Obfuscation** | SwiftShield (optional) | Protect proprietary ML model integration |

---

## Third-Party Services

### AI & Data APIs

| Service | Plan | Cost | Use Case |
|---------|------|------|----------|
| **Vertex AI** | Pay-as-you-go | $0.10/$0.40 per million tokens | Gemini Flash-Lite (Layer 2a) |
| **Anthropic API** | Pay-as-you-go | $0.25/$1.25 (Haiku), $1.50/$7.50 (Sonnet Batch) | Claude parsing + synthesis |
| **SerpAPI** | Developer Plan | $75/month (5K searches) | Google Lens visual search |
| **UPCitemdb** | DEV Plan | $99/month (600K requests) | Barcode product lookup |

---

### Payment Processing (Phase 2)

| Service | Plan | Cost | Use Case |
|---------|------|------|----------|
| **Stripe** | Standard | 2.9% + $0.30 per transaction | Premium subscriptions ($8/month) |
| **Revenue Cat** | Free tier | Free up to $10K MRR | iOS subscription management |

**Note**: Phase 1 (MVP) uses manual TestFlight invites (no Stripe integration yet)

---

## Development Environments

### Environment Configuration

| Environment | Firebase Project | GCP Project | Purpose |
|-------------|------------------|-------------|---------|
| **Development** | `abundance-dev` | `abundance-dev-123456` | Local emulators, dev builds |
| **Staging** | `abundance-staging` | `abundance-staging-123456` | TestFlight beta, QA testing |
| **Production** | `abundance-prod` | `abundance-prod-123456` | App Store public release |

**Environment Switching**: Xcode schemes (Dev, Staging, Prod) with separate GoogleService-Info.plist files

---

## Documentation Standards

### Code Documentation

| Type | Tool | Format |
|------|------|--------|
| **Swift Inline Docs** | Swift DocC | Triple-slash comments (`///`) |
| **Function Signatures** | Xcode Quick Help | `@param`, `@return`, `@throws` |
| **Architecture Docs** | Markdown | ADRs, DESIGN docs in `/docs` |

---

### API Documentation

| Type | Tool | Format |
|------|------|--------|
| **REST API** | OpenAPI 3.0 | YAML specification (API-CONTRACTS-001) |
| **Postman Collection** | Postman | JSON export (shared with team) |
| **Cloud Functions** | JSDoc | Inline comments in Node.js code |

---

## Acceptance Criteria

- [x] ✅ iOS 26 platform locked (SwiftUI + Combine + Vision Framework)
- [x] ✅ GCP + Firebase backend locked (Firestore + Cloud Functions + Storage)
- [x] ✅ AI stack locked (Gemini, Claude, SerpAPI, UPCitemdb)
- [x] ✅ REST API architecture defined (Cloud Functions HTTP triggers)
- [x] ✅ Authentication strategy locked (Firebase Auth + Apple Sign-In)
- [x] ✅ CI/CD pipeline defined (GitHub Actions + Fastlane + TestFlight)
- [x] ✅ Monitoring tools selected (Firebase Crashlytics, Analytics, Cloud Logging)
- [x] ✅ No "TBD" or unresolved technology choices

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial tech stack map, all technologies locked | Software Architecture Expert |

---

**This tech stack supports the 4-layer AI pipeline (DESIGN-004), freemium economics (ADR-003), and iOS 26 premium positioning (ADR-004).**

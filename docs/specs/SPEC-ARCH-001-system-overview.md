# SPEC-ARCH-001: System Overview

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## 1. Overview

Abundance MVP is an AI-powered household inventory cataloging application for iOS. Users photograph their belongings, and the system automatically identifies, categorizes, and values items using a multi-layer AI pipeline combining on-device object detection with cloud-based Gemini 3 Pro analysis. The backend leverages Firebase services (Firestore, Cloud Functions, Storage, Auth) to provide real-time synchronization and serverless AI processing.

---

## 2. Architecture

### 2.1 High-Level System Diagram

```
+-------------------------------------------------------------------------+
|                              iOS CLIENT                                  |
|  +-------------------------------------------------------------------+  |
|  |                        SwiftUI + MVVM                              |  |
|  |  +-------------+  +-------------+  +-------------+  +------------+ |  |
|  |  | Onboarding  |  |   Camera    |  | Inventory   |  |  Profile   | |  |
|  |  |   Feature   |  |   Feature   |  |   Feature   |  |  Feature   | |  |
|  |  +------+------+  +------+------+  +------+------+  +------+-----+ |  |
|  |         |                |                |                |       |  |
|  |  +------v----------------v----------------v----------------v-----+ |  |
|  |  |                     Core / Persistence                        | |  |
|  |  |  (Design System, Logging, Firebase SDK, Keychain)             | |  |
|  |  +---------------------------------------------------------------+ |  |
|  |                                                                    |  |
|  |  +---------------------------------------------------------------+ |  |
|  |  |                       VisionCore                               | |  |
|  |  |  (Object Detection, Subject Masking, Barcode Detection)        | |  |
|  |  +---------------------------------------------------------------+ |  |
|  +-------------------------------------------------------------------+  |
+-------------------------------+------------------------------------------+
                                |
                                | HTTPS / Firebase SDK
                                v
+-------------------------------------------------------------------------+
|                        FIREBASE BACKEND                                  |
|  +-------------------------------------------------------------------+  |
|  |                      Cloud Functions (v2)                          |  |
|  |  +----------------+  +------------------+  +---------------------+ |  |
|  |  | HTTP Endpoints |  | Firestore        |  | Scheduled Jobs      | |  |
|  |  | - createItem   |  | Triggers         |  | - cleanupDeleted    | |  |
|  |  | - getItem      |  | - onItemCreated  |  | - checkSubscription | |  |
|  |  | - listItems    |  | - onSessionCreate|  +---------------------+ |  |
|  |  | - getUserProf  |  | - onItemDeleted  |                          |  |
|  |  +----------------+  +--------+---------+                          |  |
|  +-------------------------------------------------------------------+  |
|                                  |                                       |
|  +-------------------------------------------------------------------+  |
|  |                        AI Pipeline                                 |  |
|  |  +--------------------+     +-----------------------------------+ |  |
|  |  | Layer 1            |     | Layer 2: Gemini 3 Pro             | |  |
|  |  | (Gemini 3 Flash)   | --> | (with native tool calling)        | |  |
|  |  | - Object detection |     | - Visual analysis                 | |  |
|  |  | - Quality scoring  |     | - Barcode lookup                  | |  |
|  |  | - Image cropping   |     | - Google Lens search              | |  |
|  |  +--------------------+     | - Web search (pricing)            | |  |
|  |                             | - Final catalog synthesis         | |  |
|  |                             +-----------------------------------+ |  |
|  +-------------------------------------------------------------------+  |
|                                                                          |
|  +-------------------------------------------------------------------+  |
|  |                     Firebase Services                              |  |
|  |  +-------------+  +--------------+  +------------+  +------------+ |  |
|  |  |  Firestore  |  |   Storage    |  |    Auth    |  |   FCM      | |  |
|  |  | (NoSQL DB)  |  | (GCS)        |  | (Firebase) |  | (Push)     | |  |
|  |  +-------------+  +--------------+  +------------+  +------------+ |  |
|  +-------------------------------------------------------------------+  |
+-------------------------------------------------------------------------+
                                |
                                | API Calls
                                v
+-------------------------------------------------------------------------+
|                        EXTERNAL SERVICES                                 |
|  +----------------+  +----------------+  +-----------------------------+ |
|  | Google Lens    |  | UPCitemdb      |  | E-commerce Sites            | |
|  | (SerpAPI)      |  | (Barcode API)  |  | (via Web Search)            | |
|  +----------------+  +----------------+  +-----------------------------+ |
+-------------------------------------------------------------------------+
```

### 2.2 Data Flow Diagram

```
User Captures Photo
        |
        v
+-------------------+
| iOS: Camera View  |
| (CaptureSession)  |
+--------+----------+
         |
         | Upload to GCS
         v
+-------------------+       +-------------------+
| Firebase Storage  | ----> | Firestore Session |
| (users/{uid}/...).|       | (status: pending) |
+-------------------+       +---------+---------+
                                      |
                                      | Triggers onSessionCreated
                                      v
                            +-------------------+
                            | Cloud Function:   |
                            | Layer 1 Detection |
                            | (Gemini 3 Flash)  |
                            +---------+---------+
                                      |
                                      | Creates cropped images
                                      v
                            +-------------------+
                            | Cloud Function:   |
                            | Layer 2 Catalog   |
                            | (Gemini 3 Pro)    |
                            +---------+---------+
                                      |
                                      | Tool calls: google_lens, barcode_lookup, web_search
                                      v
                            +-------------------+
                            | Firestore: Item   |
                            | (status: complete)|
                            +-------------------+
                                      |
                                      | Real-time listener
                                      v
                            +-------------------+
                            | iOS: Inventory    |
                            | (displays items)  |
                            +-------------------+
```

---

## 3. Technology Stack

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| **iOS Client** | Swift | 6.0 | Primary programming language |
| | SwiftUI | iOS 18+ | Declarative UI framework (SwiftUI-only per ADR-010) |
| | Swift Package Manager | - | Dependency management |
| | Vision Framework | - | On-device barcode detection, subject masking |
| | AVFoundation | - | Camera capture and photo processing |
| **Backend** | TypeScript | 5.3+ | Cloud Functions language |
| | Firebase Functions | 7.0.3 | Serverless compute |
| | Firebase Admin SDK | 12.0.0 | Backend Firebase operations |
| | Node.js | 20 | Runtime environment |
| **AI/ML** | Gemini 3 Flash | - | Layer 1: Object detection, quality assessment |
| | Gemini 3 Pro | - | Layer 2: Catalog synthesis with tool calling |
| | Vertex AI | - | Google Cloud AI platform |
| | @google/genai | 1.35.0 | Gemini SDK for TypeScript |
| **Storage** | Cloud Firestore | - | NoSQL document database |
| | Cloud Storage (GCS) | - | Image/file storage |
| **Authentication** | Firebase Auth | - | User authentication (Apple Sign-In, Email) |
| **External APIs** | SerpAPI | - | Google Lens visual search |
| | UPCitemdb | - | Barcode product lookup |
| **Testing** | XCTest | - | iOS unit/UI testing |
| | Jest | 30.2.0 | TypeScript unit testing |
| **Linting** | SwiftLint | - | Swift code style enforcement |
| | TypeScript compiler | - | Type checking (tsc --noEmit) |
| **CI/CD** | GitHub Actions | - | Automated build, test, deploy |

---

## 4. Module Breakdown

### 4.1 iOS Modules (Sources/)

| Module | Path | Description | Key Dependencies |
|--------|------|-------------|------------------|
| **AbundanceApp** | `App/` | Main app entry point, Firebase initialization | All feature modules, FirebaseCore |
| **OnboardingFeature** | `Sources/OnboardingFeature/` | Authentication flow (Apple Sign-In, email), first-launch experience | FirebaseAuth, CameraFeature, Core |
| **CameraFeature** | `Sources/CameraFeature/` | Camera capture (single tap, burst mode), photo upload, detection results display | VisionCore, Persistence, FirebaseAuth |
| **CollectionFeature** | `Sources/CollectionFeature/` | Item list, search, detail view, edit flow, rescan functionality | Core, CameraFeature, Persistence |
| **ProfileFeature** | `Sources/ProfileFeature/` | User profile, settings, subscription management | Core, Persistence, FirebaseAuth |
| **Persistence** | `Sources/Persistence/` | Firebase services (ItemService, StorageService), Keychain, data models | FirebaseFirestore, FirebaseStorage |
| **VisionCore** | `Sources/VisionCore/` | On-device vision: barcode detection, subject masking, image quality assessment | Vision.framework |
| **Core** | `Sources/Core/` | Design system (colors, typography, animations), logging utilities | None |

### 4.2 Key iOS Components

| Component | File | Responsibility |
|-----------|------|----------------|
| `CaptureSessionViewModel` | `CameraFeature/ViewModels/CaptureSessionViewModel.swift` | Manages capture flow: single/burst capture, upload, session observation |
| `CameraViewModel` | `CameraFeature/ViewModels/CameraViewModel.swift` | Camera session management, preview rendering |
| `CollectionViewModel` | `CollectionFeature/CollectionViewModel.swift` | Item list state, search, deletion, real-time updates |
| `ItemService` | `Persistence/Firebase/ItemService.swift` | Firestore CRUD operations for items, real-time listeners |
| `StorageService` | `Persistence/Firebase/StorageService.swift` | GCS upload/download for images |
| `Item` | `Persistence/Models/Item.swift` | Core data model matching Firestore schema |
| `BarcodeDetector` | `VisionCore/Services/BarcodeDetector.swift` | Vision framework barcode detection |
| `SubjectMaskGenerator` | `VisionCore/Services/SubjectMaskGenerator.swift` | iOS 18 subject lifting for object isolation |

### 4.3 Cloud Functions (functions/src/)

| Function | Path | Trigger | Description |
|----------|------|---------|-------------|
| **HTTP Endpoints** | | | |
| `health` | `index.ts` | HTTP GET | Health check endpoint |
| `getUserProfile` | `index.ts` | Callable | Fetch user profile document |
| `createItemHTTP` | `index.ts` | HTTP POST | Create new item with Layer 1 result |
| `getItemHTTP` | `index.ts` | HTTP GET | Fetch single item by ID |
| `listItemsHTTP` | `index.ts` | HTTP GET | List items for authenticated user |
| **Firestore Triggers** | | | |
| `onSessionCreated` | `triggers/onSessionCreated.ts` | Document create: `sessions/{id}` | Initiates Layer 1 detection for new capture sessions |
| `onItemCreatedGemini3` | `triggers/onItemCreatedGemini3.ts` | Document create: `items/{id}` | Runs Layer 2 cataloging with Gemini 3 Pro |
| `onItemFromSession` | `triggers/onItemFromSession.ts` | Document create | Creates items from detected objects in session |
| `onItemDeleted` | `triggers/onItemDeleted.ts` | Document delete: `items/{id}` | Cleans up GCS images when item deleted |
| **Scheduled Jobs** | | | |
| `cleanupDeletedItemsScheduled` | `scheduled/cleanupDeletedItems.ts` | Cron: daily | Permanently removes soft-deleted items |
| `checkSubscriptionExpiryScheduled` | `scheduled/checkSubscriptionExpiry.ts` | Cron: daily | Checks and updates subscription statuses |
| **Migrations** | | | |
| `backfillFlattenedSchema` | `migrations/backfillFlattenedSchema.ts` | HTTP (manual) | One-time schema migration utility |

### 4.4 AI Pipeline Components

| Component | Path | Description |
|-----------|------|-------------|
| `layer1-service.ts` | `ai-pipeline/layer1/layer1-service.ts` | Gemini 3 Flash detection: object identification, quality scoring, image cropping |
| `gemini-service.ts` | `ai-pipeline/gemini/gemini-service.ts` | Gemini 3 Pro orchestration with tool calling loop |
| `orchestrator.ts` | `ai-pipeline/gemini/orchestrator.ts` | Main entry point for AI cataloging pipeline |
| `prompts.ts` | `ai-pipeline/gemini/prompts.ts` | System prompts and tool definitions |
| `catalog-item.ts` | `ai-pipeline/gemini/schemas/catalog-item.ts` | TypeScript types and JSON schema for catalog output |
| `tool-executor.ts` | `ai-pipeline/tools/tool-executor.ts` | Routes tool calls to appropriate implementations |
| `google-lens.ts` | `ai-pipeline/tools/google-lens.ts` | SerpAPI Google Lens integration |
| `barcode-lookup.ts` | `ai-pipeline/tools/barcode-lookup.ts` | UPCitemdb barcode product lookup |
| `web-search.ts` | `ai-pipeline/tools/web-search.ts` | E-commerce price search |
| `CostLogger.ts` | `ai-pipeline/cost-tracking/CostLogger.ts` | AI API cost tracking and logging |

---

## 5. Key Dependencies

### 5.1 iOS Dependencies (Package.swift)

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase-ios-sdk` | 11.11.0+ | Firebase SDK (Core, Auth, Firestore, Storage) |
| `swift-protobuf` | 1.28.2 (exact) | Protocol Buffers for Firebase |

### 5.2 Backend Dependencies (package.json)

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase-admin` | 12.0.0 | Firebase Admin SDK for server-side operations |
| `firebase-functions` | 7.0.3 | Cloud Functions framework |
| `@google/genai` | 1.35.0 | Gemini AI SDK for tool calling |
| `node-fetch` | 3.3.2 | HTTP client for external API calls |
| `sharp` | 0.33.0 | High-performance image processing (cropping) |

### 5.3 Dev Dependencies (Backend)

| Package | Version | Purpose |
|---------|---------|---------|
| `typescript` | 5.3.0+ | TypeScript compiler |
| `jest` | 30.2.0 | Testing framework |
| `ts-jest` | 29.4.5 | TypeScript support for Jest |
| `dotenv` | 16.4.0 | Environment variable management |

---

## 6. Key Architectural Decisions

| ADR | Decision | Rationale |
|-----|----------|-----------|
| ADR-010 | SwiftUI-only architecture | Unified declarative UI, no UIKit in Views/ViewModels |
| ADR-014 | Gemini for AI processing | Cost-effective ($0.03-0.04/item) with native tool calling |
| ADR-015 | Single-model pipeline | Gemini 3 Pro replaces multi-model architecture (Flash-Lite + Claude) |
| ADR-006 | Firestore for database | Real-time sync, offline support, serverless scaling |
| ADR-008 | GCS for image storage | Integrated with Firebase, signed URLs for security |
| ADR-023 | Firebase Auth | Apple Sign-In primary, email fallback |

---

## 7. Cost Model

| Component | Cost per Item | Notes |
|-----------|---------------|-------|
| Gemini 3 Pro | ~$0.004 | $2-4/M input, $12-18/M output tokens |
| Google Lens (SerpAPI) | $0.015 | Per visual search |
| Barcode Lookup (UPCitemdb) | $0.01 | Per barcode lookup |
| Web Search | ~$0.014 | Google Search grounding ($14/1K queries) |
| **Total per item** | **$0.033-0.043** | Depending on whether barcode present |

---

## 8. Security Considerations

1. **Authentication**: Firebase Auth with secure token verification on all endpoints
2. **Authorization**: User-scoped data access (userId field on all documents)
3. **Image URLs**: Signed URLs with 24-hour expiration (no public access)
4. **API Keys**: Stored in environment variables, never in client code
5. **Data Encryption**: Firestore encryption at rest, HTTPS in transit
6. **Photo Metadata**: Captured for fraud prevention, stored securely

---

## 9. Deployment

| Environment | Purpose | Firebase Project |
|-------------|---------|------------------|
| Development | Local testing | abundance-dev (emulators) |
| Staging | Integration testing | abundance-staging |
| Production | Live users | abundance-prod |

**CI/CD Checks:**
- `ios-build-check`: Swift 6.0 build, SwiftLint, XCTest
- `backend-validation`: TypeScript build, ESLint, Jest tests
- `security-pr-review`: OWASP scanning on PRs

---

## 10. Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-01-18 | 1.0 | Initial system overview specification | Claude Code Audit |

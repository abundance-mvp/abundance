# TECH-STACK-001: Complete Technology Stack Map

**Document ID:** TECH-STACK-001
**Date:** 2025-10-24 (Original), 2025-11-01 (Stage 2.1 Update), 2025-11-06 (Barcode API Addition)
**Status:** APPROVED
**Version:** 2.1 (Stage 2.1 + Barcode Feature)
**Related Documents:**
- PRD-001 (Product Requirements)
- ADR-003 (MVP Scope Phasing)
- ADR-004 to ADR-018 (Architecture Decisions)
- ADR-014 (Multi-AI Pipeline Architecture)
- ADR-015 (Claude Sonnet 4.5 for AI Synthesis)
- ADR-016 (SerpAPI Google Lens for Product Search)
- ADR-017 (Redis Queue for Background Processing)
- ADR-018 (Barcode Product Lookup Strategy) **NEW**
- DESIGN-004 (4-Layer AI Pipeline Architecture, updated with barcode workflow)
- DESIGN-005 (SerpAPI Google Lens Integration)
- RECONCILIATION-design-004-vs-stage-2.1.md
- RESEARCH-BARCODE-API-2025-11-06 (Barcode API Comparison) **NEW**
- PLAN-2.1-REVISED (Execution Plan)

---

## Executive Summary

This document defines the complete technology stack for Abundance MVP Phase 1 (Inventory App). The architecture is built around a **two-tier freemium model** with a **4-layer AI pipeline**:

- **FREE TIER:** On-device AI (iOS 26 Vision Framework with YOLOv3-Tiny) for object detection and basic cataloging - $0 cost
- **PREMIUM TIER:** Multi-AI pipeline (SerpAPI Google Lens + Gemini 2.5 Flash-Lite + Claude Sonnet 4.5) for detailed product identification - **$0.019449/item**

**Key Architectural Principle:** On-device-first processing with cloud enrichment for premium features.

**4-Layer AI Architecture:**
- **Layer 1:** On-device object detection (YOLOv3-Tiny via VNCoreMLRequest)
- **Layer 2a:** Attribute extraction (Gemini 2.5 Flash-Lite, $0.000249/image)
- **Layer 2b:** Product search (SerpAPI Google Lens + Claude Haiku 4.5, $0.0109/item)
- **Layer 3:** AI synthesis and conflict resolution (Claude Sonnet 4.5 Batch API, $0.0092/inference)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ iOS 26+ App (iPhone 15 Pro+, A17 Pro chip)                 │ │
│  │  - Swift 6.0, SwiftUI                                      │ │
│  │  - MVVM Architecture Pattern                               │ │
│  │  - iOS Photo Library / App Sandbox (local storage)        │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌─────────────── FREE TIER (Layer 1) ──────────────┐          │
│  │ Vision Framework (On-Device)                     │          │
│  │  - VNCoreMLRequest + YOLOv3-Tiny (35.4MB)        │          │
│  │  - Apple Neural Engine (A17 Pro)                 │          │
│  │  - 80 COCO object classes                        │          │
│  │  - Latency: 50-150ms, Detection: 70-80%          │          │
│  │  - Cost: $0                                      │          │
│  └──────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS / Firebase SDK
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API / BACKEND LAYER                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Google Cloud Platform (GCP)                                │ │
│  │                                                            │ │
│  │  Firebase Authentication                                   │ │
│  │   - Apple Sign-In (primary)                               │ │
│  │   - Email/Password (fallback)                             │ │
│  │                                                            │ │
│  │  Cloud Firestore (NoSQL Database)                         │ │
│  │   - users/{userId}/items/{itemId}                         │ │
│  │   - Offline-first, real-time sync                         │ │
│  │   - Free tier: 50K reads/day, 20K writes/day              │ │
│  │                                                            │ │
│  │  Google Cloud Storage + Cloud CDN                         │ │
│  │   - Premium tier: Temporary image hosting for SerpAPI     │ │
│  │   - Public URLs via Cloud CDN (egress optimization)       │ │
│  │   - Cost: $0.0001 per image (storage + CDN)               │ │
│  │                                                            │ │
│  │  Cloud Memorystore (Redis 7.0+)                           │ │
│  │   - Queue: Layer 2b processing jobs                       │ │
│  │   - Deduplication, retry logic                            │ │
│  │                                                            │ │
│  │  Cloud Functions (Node.js 20)                             │ │
│  │   - Product enrichment (HTTPS callable)                   │ │
│  │   - Background queue processor (Cloud Scheduler)          │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ REST API / Vertex AI / Anthropic API
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  AI/ML LAYER (4-Layer Pipeline)                 │
│                                                                 │
│  ┌────────────── Layer 2a: Attribute Extraction ──────────────┐ │
│  │ Gemini 2.5 Flash-Lite (Google Vertex AI)                  │ │
│  │  - Input: Cropped image from Layer 1                      │ │
│  │  - Output: JSON (condition, color, material, category)    │ │
│  │  - Cost: $0.000249 per image                              │ │
│  │  - Latency: 30-50ms                                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌─────────── Layer 2b: Product Search (Parallel) ────────────┐ │
│  │ SerpAPI Google Lens + Claude Haiku 4.5                    │ │
│  │  - SerpAPI: Visual product search ($0.01 per search)      │ │
│  │  - GCS + CDN: Temporary image hosting ($0.0001)           │ │
│  │  - Claude Haiku: Parse search results ($0.0008)           │ │
│  │  - Redis Queue: Background processing, retry logic        │ │
│  │  - Total cost: $0.0109 per item                           │ │
│  │  - Latency: 5-7 seconds                                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌────────── Layer 3: AI Synthesis & Conflict Resolution ─────┐ │
│  │ Claude Sonnet 4.5 (Anthropic Batch API)                   │ │
│  │  - Input: Layer 2a + Layer 2b results                     │ │
│  │  - Output: Final merged metadata (brand, model, price)    │ │
│  │  - Cost: $0.0092 per inference (50% batch discount)       │ │
│  │  - Latency: 1-2 seconds                                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  **Total Premium Tier Cost:** $0.019449 per item               │
│  **Total Latency:** 7-10 seconds end-to-end                    │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY LAYER                          │
│  - Cloud Logging (backend logs, AI pipeline tracing)           │
│  - Cloud Monitoring (Layer success rates, latency per layer)   │
│  - Firebase Analytics (user events, funnels)                   │
│  - Crashlytics (iOS crashes, backend errors)                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. CLIENT LAYER

### Platform & Runtime

| Component | Choice | Version | Rationale |
|-----------|--------|---------|-----------|
| **Platform** | iOS | 26.0+ minimum | Vision Framework advanced features require iOS 26 |
| **Device** | iPhone | 15 Pro+ (A17 Pro) | Apple Neural Engine required for on-device ML |
| **Language** | Swift | 6.0 | Latest stable, strict concurrency, improved performance |
| **UI Framework** | SwiftUI | 5.0 (iOS 26) | Declarative, modern, native performance |
| **Architecture** | MVVM | TBD (Stage 2.2) | Standard iOS pattern, testable, reactive |

**Supported Devices:**
- iPhone 15 Pro (A17 Pro chip)
- iPhone 15 Pro Max (A17 Pro chip)
- iPhone 16 and newer (A18+ chips)
- iPad Pro with M1 or newer
- iPad Air with M1 or newer

**Market Size:**
- Launch (Month 0): ~15% of iOS market
- Month 6: ~20% adoption
- Month 12: ~30% adoption (projected)

**Design System:**
- iOS Human Interface Guidelines
- SF Symbols (native icons)
- San Francisco font (system default)
- Dark mode support (iOS native)

**ADR Reference:** ADR-004 (iOS 26-Only Launch Strategy)

---

### On-Device AI (FREE TIER - Layer 1)

| Component | Technology | Purpose | Cost |
|-----------|-----------|---------|------|
| **Vision Framework** | VNCoreMLRequest | Object detection via Core ML | $0 |
| **Core ML Model** | YOLOv3-Tiny | Pre-trained object detection (Apple) | $0 |
| **Model Size** | 35.4 MB | Optimized for mobile | $0 |
| **Object Classes** | 80 COCO classes | Common household items | $0 |
| **Neural Engine** | Apple A17 Pro | Hardware acceleration | $0 |
| **Image Processing** | UIKit/CoreImage | Cropping, resizing | $0 |

**Vision Framework Capabilities:**
- **Object Detection:** Identify multiple objects in single photo (80 COCO classes)
- **Bounding Boxes:** Pixel coordinates for each detected object
- **Basic Labels:** Generic categories ("scissors", "headphones", "book", "laptop", "bottle", etc.)
- **Confidence Scores:** 0.0-1.0 (filter out low-confidence detections)
- **Detection Rate:** 70-80% for common household items
- **Performance:** 50-150ms per image on A17 Pro

**YOLOv3-Tiny Model Details:**
- **Source:** Apple pre-trained model (available in Core ML Model Zoo)
- **Architecture:** YOLOv3-Tiny (lightweight YOLO variant)
- **Training Dataset:** COCO (Common Objects in Context)
- **Classes:** 80 object categories (person, bicycle, car, motorcycle, airplane, bus, train, truck, boat, traffic light, fire hydrant, stop sign, parking meter, bench, bird, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe, backpack, umbrella, handbag, tie, suitcase, frisbee, skis, snowboard, sports ball, kite, baseball bat, baseball glove, skateboard, surfboard, tennis racket, bottle, wine glass, cup, fork, knife, spoon, bowl, banana, apple, sandwich, orange, broccoli, carrot, hot dog, pizza, donut, cake, chair, couch, potted plant, bed, dining table, toilet, tv, laptop, mouse, remote, keyboard, cell phone, microwave, oven, toaster, sink, refrigerator, book, clock, vase, scissors, teddy bear, hair drier, toothbrush)

**iOS APIs Used:**
```swift
import Vision
import CoreML

// Load YOLOv3-Tiny Core ML model
guard let model = try? VNCoreMLModel(for: YOLOv3Tiny().model) else { return }

// Object detection request
let request = VNCoreMLRequest(model: model) { request, error in
    guard let observations = request.results as? [VNRecognizedObjectObservation] else { return }

    for observation in observations where observation.confidence > 0.7 {
        let label = observation.labels.first?.identifier ?? "unknown"
        let boundingBox = observation.boundingBox
        // Crop image, save to Firestore
    }
}

// Run on Apple Neural Engine
let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
try? handler.perform([request])
```

**Output Example:**
```json
{
  "detectedObjects": [
    {"label": "scissors", "confidence": 0.92, "bbox": [120, 300, 80, 150]},
    {"label": "laptop", "confidence": 0.87, "bbox": [250, 150, 120, 100]}
  ]
}
```

**Storage:**
- **Photo Library:** User chooses to save photo to library (optional)
- **App Sandbox:** Cropped images stored in app's Documents folder
- **Firestore:** Metadata only (name, category, timestamp)

**ADR Reference:** ADR-013 (Vision Framework Strategy)

---

### Local Storage

| Storage Type | Technology | Purpose | Size Limit |
|-------------|-----------|---------|------------|
| **Photos** | iOS Photo Library | Original photos (user choice) | Device storage |
| **Cropped Images** | App Sandbox (Documents) | Detected objects | ~10-50 KB each |
| **Metadata** | Firestore (offline cache) | Item details, search index | ~5 KB per item |
| **User Prefs** | UserDefaults | Settings, onboarding state | ~1 KB |

**Free Tier Storage Costs:**
- All storage is local (iOS device)
- No cloud storage costs
- User manages device storage (iOS Settings)

**Premium Tier Storage:**
- Cropped images uploaded to Firebase Storage (temporary)
- Images can be deleted after Shopping Graph processing (user preference)
- Estimated: 150 KB per item × 50 items = 7.5 MB per user

**ADR Reference:** ADR-010 (Hybrid Storage: Local-First + Cloud Enrichment)

---

## 2. API / BACKEND LAYER

### Cloud Platform

| Component | Provider | Rationale | Free Tier Limits |
|-----------|----------|-----------|------------------|
| **Cloud Provider** | Google Cloud Platform (GCP) | Multi-AI pipeline integration, Firebase ecosystem | N/A |
| **Authentication** | Firebase Authentication | Apple Sign-In, Email/Password, anonymous upgrade | 50K MAU |
| **Database** | Cloud Firestore | Offline-first, real-time sync, auto-scaling | 50K reads/day, 20K writes/day |
| **Storage** | Google Cloud Storage + Cloud CDN | Premium tier temporary image hosting for SerpAPI | Pay-as-you-go ($0.0001/image) |
| **Queue** | Cloud Memorystore (Redis 7.0+) | Background processing, Layer 2b queue, deduplication | Pay-as-you-go (~$25/month for 1GB instance) |
| **Compute** | Cloud Functions (2nd gen) | Serverless, auto-scaling, Firebase triggers | 2M invocations/month |
| **Logging** | Cloud Logging | Structured logs, query interface, AI pipeline tracing | 50 GB/month |
| **Monitoring** | Cloud Monitoring | Metrics, alerts, dashboards, layer-by-layer latency | Free for Firebase projects |
| **Scheduler** | Cloud Scheduler | Background queue processing, retry logic | 3 jobs free |

**ADR Reference:** ADR-005 (GCP Platform Selection), ADR-017 (Redis Queue)

---

### Authentication

**Provider:** Firebase Authentication
**Primary Method:** Apple Sign-In (Sign in with Apple)
**Fallback Method:** Email/Password

**Authentication Flow:**
```
1. User opens app
2. Anonymous auth (temporary, no login required)
3. User catalogs items (anonymous mode, limited to 10 items)
4. Prompt to sign in (Apple Sign-In or Email)
5. Upgrade anonymous account → permanent account
6. Enable cloud sync (Firestore)
```

**JWT Token:**
- Issued by Firebase Auth
- Passed in `Authorization: Bearer <token>` header
- Expires in 1 hour (auto-refreshed by Firebase SDK)
- Used for Cloud Functions authentication

**Security:**
- Firebase App Check (prevent API abuse)
- HTTPS-only (all requests)
- Device ID verification (optional, for fraud detection)

**Free Tier Capacity:**
- 50,000 Monthly Active Users (MAU) free
- Unlimited authentication requests
- Apple Sign-In: No additional costs

**ADR Reference:** ADR-009 (Firebase Authentication)

---

### Database

**Database:** Cloud Firestore (NoSQL)
**Architecture:** Document-based, hierarchical collections

**Data Model:**

```
users (collection)
├── {userId} (document)
│   ├── profile (subcollection)
│   │   └── {userId} (document)
│   │       ├── email: "user@example.com"
│   │       ├── displayName: "Jane Smith"
│   │       ├── subscriptionTier: "free" | "premium"
│   │       ├── createdAt: timestamp
│   │       └── lastActiveAt: timestamp
│   │
│   └── items (subcollection)
│       └── {itemId} (document)
│           ├── name: "scissors" (free) | "Scott Fabric Scissors 8-inch" (premium)
│           ├── category: "Office Supplies"
│           ├── brand: null (free) | "Scott" (premium)
│           ├── model: null (free) | "8-inch Fabric Scissors" (premium)
│           ├── estimatedValue: null (free) | 12.99 (premium)
│           ├── currency: "USD"
│           ├── photoUrl: "local://photo_123.jpg" (free) | "gs://..." (premium)
│           ├── tier: "free" | "premium"
│           ├── createdAt: timestamp
│           ├── enrichedAt: null (free) | timestamp (premium)
│           └── metadata: {...}  (Shopping Graph extra data)
```

**Indexes:**
- Composite index: `(userId, createdAt DESC)` - for timeline view
- Composite index: `(userId, category, createdAt DESC)` - for category filters
- Full-text search: TBD (Stage 2.3) - likely Algolia or Meilisearch

**Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/items/{itemId} {
      // Users can only read/write their own items
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Offline Support:**
- Firestore iOS SDK caches data locally
- Writes work offline, sync when online
- Real-time listeners update UI when data changes

**ADR Reference:** ADR-008 (Cloud Firestore Database Selection)

---

### File Storage

**Storage:** Google Cloud Storage + Cloud CDN

**Free Tier Users:**
- **No cloud storage used** (all photos stored locally on device)
- Metadata only in Firestore

**Premium Tier Users:**
- Cropped images uploaded to Google Cloud Storage
- Public URLs generated via Cloud CDN (for SerpAPI Google Lens)
- Path: `gs://abundance-prod-images/users/{userId}/temp/{itemId}/cropped.jpg`
- Lifecycle: Delete after 7 days (temporary hosting for AI pipeline)

**Storage Cost Breakdown (per image):**
- **Storage:** $0.020/GB/month × 0.00015 GB × (7 days / 30 days) = $0.00000070
- **CDN Egress:** $0.08/GB × 0.00015 GB = $0.000012
- **Operations:** $0.000004 per PUT/GET × 2 = $0.000008
- **Total per image:** $0.00002 ≈ **$0.0001** (rounded up for safety margin)

**Storage Estimate (Month 6, 5,000 users):**
- 30% premium users: 1,500 users
- 50 items/user: 75,000 items
- 150 KB per cropped image × 7-day retention
- Cost: 75,000 × $0.0001 = **$7.50/month**

**Security:**
- **Public URLs:** Signed URLs with 1-hour expiration (for SerpAPI)
- **IAM Policies:** Service account access only (Cloud Functions)
- **CORS:** Configured for SerpAPI domain

**Cloud CDN Configuration:**
- **Cache Duration:** 1 hour (images are temporary)
- **Cache Key:** Full URL path (unique per image)
- **Compression:** Enabled (gzip for JSON responses, not images)

**ADR Reference:** ADR-010 (Hybrid Storage), ADR-016 (SerpAPI Integration)

---

### Compute

**Compute:** Cloud Functions (2nd gen)
**Runtime:** Node.js 20
**Region:** us-central1 (Iowa)

**Functions:**

#### 1. Product Enrichment (HTTPS Callable)

```javascript
// Cloud Function: enrichItem
exports.enrichItem = functions.https.onCall(async (data, context) => {
  // Authenticate user
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated');

  const { itemId, basicLabel, croppedImageUrl } = data;

  // Call Google Shopping Graph API
  const productData = await shoppingGraphAPI.identify(croppedImageUrl);

  // Save enriched metadata to Firestore
  await db.doc(`users/${context.auth.uid}/items/${itemId}`).update({
    name: productData.name,
    brand: productData.brand,
    model: productData.model,
    estimatedValue: productData.price,
    productUrl: productData.url,
    enrichedAt: admin.firestore.FieldValue.serverTimestamp(),
    tier: 'premium'
  });

  return { success: true, enrichedMetadata: productData };
});
```

**Configuration:**
- Memory: 512 MB
- Timeout: 10 seconds (Shopping Graph can be slow)
- Concurrency: 100 (handle burst traffic)
- Min instances: 0 (scale to zero when idle)
- Max instances: 50 (prevent runaway costs)

---

#### 2. Retry Failed Enrichments (Scheduled)

```javascript
// Cloud Function: retryFailedEnrichments
exports.retryFailedEnrichments = functions.pubsub.schedule('every 6 hours').onRun(async (context) => {
  // Query items where Shopping Graph failed
  const failedItems = await db.collectionGroup('items')
    .where('tier', '==', 'premium')
    .where('enrichedAt', '==', null)
    .where('retryCount', '<', 3)
    .get();

  // Retry Shopping Graph API for each failed item
  for (const doc of failedItems.docs) {
    try {
      const productData = await shoppingGraphAPI.identify(doc.data().photoUrl);
      await doc.ref.update({ ...productData, enrichedAt: admin.firestore.FieldValue.serverTimestamp() });
    } catch (error) {
      await doc.ref.update({ retryCount: admin.firestore.FieldValue.increment(1) });
    }
  }
});
```

**Configuration:**
- Schedule: Every 6 hours (0 */6 * * *)
- Memory: 256 MB
- Timeout: 9 minutes (max for scheduled functions)

**ADR Reference:** ADR-011 (Cloud Functions for Compute)

---

### API Design

**Protocol:** REST over HTTPS
**Format:** JSON
**Base URL:** `https://us-central1-abundance-prod.cloudfunctions.net/api/v1`

**Endpoints:**

#### FREE TIER (No API Calls)
```javascript
// iOS app writes directly to Firestore
db.collection('users').doc(userId).collection('items').add({
  name: "scissors, headphones",
  category: "Office Supplies",
  tier: "free",
  createdAt: Date.now()
});
```

#### PREMIUM TIER

**POST /enrich-item**
Enrich item with Google Shopping Graph data

**Request:**
```json
{
  "itemId": "item_abc123",
  "basicLabel": "scissors",
  "croppedImages": ["gs://abundance-prod/users/{userId}/temp/object_1.jpg"]
}
```

**Response (Success):**
```json
{
  "enrichedMetadata": {
    "name": "Scott Fabric Scissors 8-inch",
    "brand": "Scott",
    "model": "8-inch Fabric Scissors",
    "category": "Office Supplies > Scissors",
    "estimatedValue": 12.99,
    "currency": "USD",
    "productUrl": "https://shopping.google.com/...",
    "confidence": 0.92
  },
  "processingTime": 3.2,
  "cost": 0.007
}
```

**Response (Error - Silent Retry):**
```json
{
  "error": {
    "code": "SHOPPING_GRAPH_UNAVAILABLE",
    "message": "Will retry automatically in 6 hours",
    "retryAt": "2026-01-15T16:00:00Z"
  },
  "fallbackMetadata": {
    "name": "scissors",  // Keep basic label
    "tier": "free"
  }
}
```

**ADR Reference:** ADR-007 (REST API Design)

---

## 3. AI/ML LAYER

### Free Tier: iOS 26 Vision Framework (Layer 1)

**Purpose:** Object detection and cropping (NOT full product identification)

| Attribute | Value |
|-----------|-------|
| **Technology** | Apple Vision Framework (`VNCoreMLRequest` + YOLOv3-Tiny) |
| **Hardware** | Apple Neural Engine (A17 Pro chip) |
| **Model** | YOLOv3-Tiny (35.4 MB, 80 COCO classes) |
| **Performance** | 50-150ms per image |
| **Detection Rate** | 70-80% for common household items |
| **Cost** | $0 (on-device) |
| **Output** | Bounding boxes + basic labels ("scissors", "laptop", "bottle") |

**Workflow:**
1. User takes photo
2. `VNCoreMLRequest` with YOLOv3-Tiny detects objects
3. App crops image around each detected object
4. Saves to Firestore with basic label
5. Displays in inventory: "scissors" (generic)

**Limitations:**
- No brand/model identification (e.g., can't distinguish "Scott Scissors" from "Fiskars Scissors")
- No price estimation
- Generic categories only (80 COCO classes)

**ADR Reference:** ADR-013 (Vision Framework Strategy)

---

### Premium Tier: 4-Layer AI Pipeline

**Purpose:** Product identification (specific brand, model, price) using multi-AI architecture

**Pipeline Overview:**
- **Layer 1:** On-device object detection (YOLOv3-Tiny) - Free
- **Layer 2a:** Attribute extraction (Gemini 2.5 Flash-Lite) - $0.000249/image
- **Layer 2b:** Product search (SerpAPI Google Lens + Claude Haiku) - $0.0109/item
- **Layer 3:** AI synthesis (Claude Sonnet 4.5) - $0.0092/inference
- **Total Cost:** $0.019449 per item
- **Total Latency:** 7-10 seconds end-to-end

---

### Layer 2a: Attribute Extraction

**Technology:** Gemini 2.5 Flash-Lite (Google Vertex AI)

| Attribute | Value |
|-----------|-------|
| **Model** | gemini-2.5-flash-lite |
| **API** | Google Vertex AI (us-central1) |
| **Input** | Cropped image from Layer 1 (150 KB avg) |
| **Output** | JSON (condition, color, material, category, size, features, confidence) |
| **Cost** | $0.000249 per image (input: 150 KB × $0.0015625/MB, output: 200 tokens × $0.0000006/token) |
| **Latency** | 30-50ms |
| **Model Version** | GA since July 2025 |

**Prompt Template:**
```json
{
  "contents": [{
    "role": "user",
    "parts": [
      {"inline_data": {"mime_type": "image/jpeg", "data": "base64_image"}},
      {"text": "Analyze this image and extract: condition (new/used/damaged), color, material, category, estimated size, distinctive features. Return JSON only."}
    ]
  }]
}
```

**Example Output:**
```json
{
  "condition": "used",
  "color": "silver",
  "material": "metal",
  "category": "office supplies",
  "size": "8 inches",
  "features": ["fabric scissors", "ergonomic handle"],
  "confidence": 0.89
}
```

**ADR Reference:** ADR-014 (Multi-AI Pipeline Architecture)

---

### Layer 2b: Product Search

**Technology:** SerpAPI Google Lens + Claude Haiku 4.5 (Anthropic Messages API)

| Component | Technology | Cost per Item |
|-----------|-----------|---------------|
| **Image Upload** | Google Cloud Storage + CDN | $0.0001 |
| **Visual Search** | SerpAPI Google Lens (Production plan) | $0.01 |
| **Result Parsing** | Claude Haiku 4.5 (claude-haiku-4-5-20250429) | $0.0008 |
| **Queue Management** | Redis (Google Cloud Memorystore) | Negligible |
| **Total** | | **$0.0109** |

**Latency:** 5-7 seconds (background processing via Redis queue)

**SerpAPI Configuration:**
- **Plan:** Production ($50/month for 5,000 searches)
- **API:** `https://serpapi.com/search.json?engine=google_lens`
- **Parameters:**
  - `url`: Public CDN URL of cropped image
  - `country`: US
  - `hl`: en (language)

**SerpAPI Response Example:**
```json
{
  "visual_matches": [
    {
      "title": "Scott Fabric Scissors 8-inch",
      "source": "Amazon",
      "price": {"value": "$12.99", "extracted_value": 12.99, "currency": "$"},
      "link": "https://amazon.com/..."
    }
  ]
}
```

**Claude Haiku Parsing:**
- **Purpose:** Extract structured data from SerpAPI HTML responses
- **Input:** SerpAPI JSON (4,000 tokens avg)
- **Output:** Normalized product metadata (brand, model, price, URL)
- **Cost:** 4,000 input tokens × $0.0000001 + 400 output tokens × $0.000002 = $0.0008

**Redis Queue (Cloud Memorystore):**
- **Purpose:** Background processing of Layer 2b (avoid blocking user)
- **Queue:** `serpapi:pending:{itemId}`
- **Retry:** 3 attempts with exponential backoff (1 min, 5 min, 15 min)
- **Deduplication:** Check `serpapi:processed:{imageHash}` before enqueuing

**ADR Reference:** ADR-016 (SerpAPI Google Lens Integration), ADR-017 (Redis Queue)

---

### Layer 3: AI Synthesis and Conflict Resolution

**Technology:** Claude Sonnet 4.5 (Anthropic Batch API)

| Attribute | Value |
|-----------|-------|
| **Model** | claude-sonnet-4-5-20250929 |
| **API** | Anthropic Messages Batch API |
| **Input** | Layer 2a attributes + Layer 2b product data (2,000 tokens avg) |
| **Output** | Final merged metadata (brand, model, price, category, condition) |
| **Cost** | $0.0092 per inference (50% batch discount: $0.003/1K input tokens × 2K + $0.015/1K output tokens × 400 tokens) |
| **Latency** | 1-2 seconds (batch processing) |

**Conflict Resolution Logic:**
- **Brand/Model:** Prefer Layer 2b (SerpAPI is ground truth for products)
- **Category:** Merge Layer 2a + Layer 2b (e.g., "office supplies > scissors")
- **Condition:** Prefer Layer 2a (visual analysis is more accurate)
- **Price:** Use Layer 2b only (SerpAPI provides current market prices)
- **Color/Material:** Prefer Layer 2a (visual attributes)

**Prompt Template:**
```json
{
  "model": "claude-sonnet-4-5-20250929",
  "messages": [{
    "role": "user",
    "content": "Merge these two analyses:\n\nLayer 2a (Gemini): {...}\nLayer 2b (SerpAPI): {...}\n\nReturn final JSON with brand, model, category, price, condition, color, material. Resolve conflicts using: Brand/Model from Layer 2b, Condition/Color from Layer 2a."
  }]
}
```

**Example Output:**
```json
{
  "brand": "Scott",
  "model": "Fabric Scissors 8-inch",
  "category": "Office Supplies > Scissors",
  "price": 12.99,
  "currency": "USD",
  "condition": "used",
  "color": "silver",
  "material": "metal",
  "productUrl": "https://amazon.com/...",
  "confidence": 0.91
}
```

**ADR Reference:** ADR-015 (Claude Sonnet 4.5 for AI Synthesis)

---

### Pipeline Workflow (Premium Tier)

1. **Layer 1 (iOS):** User takes photo → YOLOv3-Tiny detects objects → Crop images
2. **Upload:** Cropped images uploaded to GCS + Cloud CDN
3. **Layer 2a (Parallel):** Gemini 2.5 Flash-Lite extracts attributes (30-50ms)
4. **Layer 2b (Background):** SerpAPI Google Lens searches for products (5-7s, Redis queue)
5. **Layer 3 (Batch):** Claude Sonnet 4.5 merges results (1-2s, batch API)
6. **Firestore:** Save final metadata to user's inventory
7. **iOS App:** Display "Scott Fabric Scissors 8-inch - $12.99 (used)"

**Error Handling:**
- **Layer 2a fails:** Use Layer 2b data only (fallback to product search)
- **Layer 2b fails:** Use Layer 2a data only (attributes without specific product)
- **Layer 3 fails:** Save Layer 2a + Layer 2b separately (no merge)
- **All layers fail:** Keep Layer 1 basic label ("scissors")

**Cost Estimate (Month 6, 5,000 users):**
- Free tier (70%): 175,000 items × $0 = **$0**
- Premium tier (30%): 75,000 items × $0.019449 = **$1,458.68/month**
- **Total AI cost: $1,458.68/month**

**Revenue (Month 6):**
- 1,500 premium users × $8/month = **$12,000/month**
- **AI margin: 88%** ($10,541 profit after AI costs)

**ADR Reference:** ADR-014 (Multi-AI Pipeline Architecture)

---

## 4. OBSERVABILITY LAYER

### Logging

**Service:** Cloud Logging (GCP)
**Sources:**
- Cloud Functions (stdout/stderr)
- Firebase Authentication (login events)
- Firebase Storage (upload events)
- Google Shopping Graph API calls

**Log Levels:**
- **ERROR:** Shopping Graph API failures, authentication errors
- **WARN:** Retry attempts, low confidence detections
- **INFO:** Successful enrichments, user signups
- **DEBUG:** Detailed request/response payloads (staging only)

**Retention:**
- 30 days (default, free)
- Long-term: Export to BigQuery (optional, for analytics)

---

### Monitoring

**Service:** Cloud Monitoring (GCP)
**Dashboards:**

#### 1. AI Pipeline Health (Layer-by-Layer)
- **Layer 1 (YOLOv3-Tiny):** Detection rate, avg confidence, processing time (target: <150ms)
- **Layer 2a (Gemini):** Success rate (target: >95%), latency p95 (target: <50ms), avg confidence
- **Layer 2b (SerpAPI):** Success rate (target: >90%), latency p95 (target: <7s), queue depth
- **Layer 3 (Claude Sonnet):** Success rate (target: >95%), latency p95 (target: <2s), batch completion time
- **End-to-End Pipeline:** Total latency (target: <10s), overall success rate (target: >90%)

#### 2. Redis Queue Metrics
- **Queue Depth:** Number of pending Layer 2b jobs
- **Processing Rate:** Jobs processed per minute
- **Retry Rate:** % of jobs requiring retry (target: <10%)
- **Dead Letter Queue:** Jobs failed after 3 retries

#### 3. User Engagement
- **Daily Active Users (DAU)**
- **Items Cataloged per Day**
- **Free vs Premium Split** (target: 30% premium by Month 6)
- **Average Items per User** (target: 50)

#### 4. Cost Tracking (Layer-by-Layer)
- **Layer 2a (Gemini) Cost per Day** (target: <$1/day at Month 6)
- **Layer 2b (SerpAPI + Haiku) Cost per Day** (target: <$30/day at Month 6)
- **Layer 3 (Claude Sonnet) Cost per Day** (target: <$25/day at Month 6)
- **GCS + CDN Cost** (target: <$0.25/day)
- **Redis (Memorystore) Cost** (~$25/month fixed)
- **Cloud Functions Invocations** (free tier limit: 2M/month)

**Alerts:**
- Layer 2a success rate drops below 90% (PagerDuty/Slack)
- Layer 2b latency p95 exceeds 15 seconds
- Layer 3 success rate drops below 90%
- Redis queue depth exceeds 1,000 jobs (backlog alert)
- Free tier limits approaching (e.g., 80% of Firestore quota)

---

### Analytics

**Service:** Firebase Analytics (Google Analytics 4 backend)

**Events:**
- `item_cataloged` (free tier)
- `item_enriched` (premium tier, Shopping Graph success)
- `subscription_started` (premium conversion)
- `subscription_cancelled`
- `search_performed` (inventory search)
- `item_viewed` (detail page)

**Funnels:**
1. **Onboarding Funnel:** App open → Photo taken → First item cataloged
2. **Premium Conversion Funnel:** Free user → View upgrade prompt → Start subscription
3. **Retention Funnel:** D1 → D7 → D30 → D90 retention

**Custom Metrics:**
- Items per user (median, p90)
- Shopping Graph confidence scores (avg, distribution)
- Time to first item cataloged (onboarding friction)

---

### Error Tracking

**iOS:** Firebase Crashlytics
**Backend:** Cloud Logging + Error Reporting

**iOS Crash Tracking:**
- Non-fatal errors (e.g., Vision Framework failures, image crop errors)
- Fatal crashes (app termination)
- Crash-free rate (target: >99.5%)

**Backend Error Tracking:**
- Cloud Functions exceptions (Shopping Graph API failures)
- Unhandled promise rejections
- Timeout errors (>10 sec function execution)

**ADR Reference:** ADR-013 (Observability Stack)

---

## 5. PAYMENTS LAYER

**Status:** TBD (Decision needed in ADR-014)

### Option A: Apple In-App Purchase (IAP)

**Pros:**
- Native iOS integration (StoreKit 2)
- User trust (Apple handles billing)
- Easier App Store approval

**Cons:**
- 30% App Store fee (reduces revenue)
- Complex subscription management (renewals, cancellations)
- Limited analytics (App Store Connect only)

**Pricing Example:**
- User pays: $8/month
- Apple takes: $2.40 (30%)
- Abundance receives: $5.60

---

### Option B: Stripe + Web Sign-Up

**Pros:**
- Lower fees (~3% vs. 30%)
- Full control (subscription management, analytics)
- Flexible pricing (A/B testing, dynamic discounts)

**Cons:**
- Web sign-up flow (friction: redirect to Safari)
- App Store policy compliance (no in-app payment prompts)
- Stripe integration complexity

**Pricing Example:**
- User pays: $8/month
- Stripe takes: $0.24 (3%)
- Abundance receives: $7.76

---

### Recommendation (Pending ADR-014)

**Proposed Hybrid Approach:**
1. Launch with Apple IAP (Month 0-3): Simpler, faster to market
2. Add Stripe option (Month 4+): Offer web sign-up for users who prefer credit card
3. Grandfather existing IAP users (no forced migration)

**ADR Reference:** ADR-014 (Payment Strategy - TBD)

---

## 6. COST MODEL

### Month 6 Projections (5,000 users)

| Component | Cost | Calculation |
|-----------|------|-------------|
| **AI/ML (4-Layer Pipeline)** | $1,458.68/month | 75,000 premium items × $0.019449 |
| **  - Layer 2a (Gemini Flash-Lite)** | $18.68/month | 75,000 × $0.000249 |
| **  - Layer 2b (SerpAPI + Haiku)** | $817.50/month | 75,000 × $0.0109 |
| **  - Layer 3 (Claude Sonnet Batch)** | $690.00/month | 75,000 × $0.0092 |
| **Google Cloud Storage + CDN** | $7.50/month | 75,000 images × $0.0001 |
| **Cloud Memorystore (Redis)** | $25/month | 1GB Basic Tier instance (us-central1) |
| **Cloud Functions** | $0/month | <2M invocations (free tier) |
| **Firestore** | $0/month | <50K reads/day (free tier) |
| **Firebase Auth** | $0/month | <50K MAU (free tier) |
| **Cloud Logging** | $0/month | <50 GB/month (free tier) |
| **Payment Processing** | $360/month | 1,500 subs × $8 × 3% (Stripe) OR $3,600 (Apple IAP 30%) |
| **Total Infrastructure** | $1,851.18/month (Stripe) OR $5,091.18/month (Apple IAP) |

**Layer-by-Layer Cost Breakdown (per item):**
- Layer 1 (YOLOv3-Tiny): $0.000000 (on-device)
- Layer 2a (Gemini): $0.000249
- Layer 2b (SerpAPI + Haiku + GCS): $0.0109
- Layer 3 (Claude Sonnet): $0.0092
- **Total:** $0.019449 per premium item

**Revenue:**
- 1,500 premium users × $8/month = **$12,000/month**

**Margin:**
- Stripe: $12,000 - $1,851.18 = **$10,148.82 (85% margin)**
- Apple IAP: $12,000 - $5,091.18 = **$6,908.82 (58% margin)**

**Note:** Apple IAP margin is lower due to 30% App Store fee ($3,600/month)

---

## 7. SECURITY & COMPLIANCE

### Data Privacy

**Strategy:** Privacy as secondary benefit (not lead marketing message)

**On-Device Processing (Free Tier):**
- Photos never leave device
- Vision Framework runs locally (Apple Neural Engine)
- Firestore: Metadata only, no photos uploaded

**Cloud Processing (Premium Tier):**
- Cropped images uploaded to Firebase Storage (temporary)
- Google Shopping Graph processes images (Google Privacy Policy applies)
- Images can be deleted after processing (user preference)

**User Controls:**
- Delete account (all data deleted within 30 days)
- Export data (JSON or CSV)
- Opt-out of analytics (Firebase Analytics respects iOS privacy settings)

---

### Compliance

**GDPR (Europe):**
- Not applicable (Phase 1 US-only, Austin metro)
- Phase 2 Europe expansion: Add GDPR consent flow

**CCPA (California):**
- "Do Not Sell My Personal Information" disclosure
- User data deletion request (automated via Cloud Function)

**App Store Guidelines:**
- Privacy nutrition label (App Store Connect)
- Data usage disclosure (what data is collected, why, how it's used)

---

## 8. SCALABILITY

### Current Capacity (Month 6)

| Component | Current Capacity | Growth Headroom |
|-----------|------------------|-----------------|
| **Cloud Firestore** | 50K writes/day (free tier) | 10,000 users → upgrade to Blaze plan |
| **Cloud Functions** | 2M invocations/month (free tier) | 75,000 items → ~150K invocations (75% headroom) |
| **Firebase Storage** | 5 GB (free tier) | 11.25 GB → upgrade to Blaze plan |
| **Shopping Graph API** | No rate limit (TBD) | Likely 10-100 QPS (sufficient for 5K users) |

### Scale-Out Plan (Month 12, 50,000 users)

1. **Firestore:** Upgrade to Blaze plan ($0.06 per 100K reads)
2. **Cloud Functions:** Stay within free tier (2M invocations covers 150K items/month)
3. **Google Cloud Storage + CDN:** 750K images × $0.0001 = **$75/month**
4. **Cloud Memorystore (Redis):** Upgrade to 5GB Standard Tier = **$150/month**
5. **AI/ML (4-Layer Pipeline):** 750K items × $0.019449 = **$14,586.75/month**
   - Layer 2a (Gemini): 750K × $0.000249 = $186.75
   - Layer 2b (SerpAPI + Haiku): 750K × $0.0109 = $8,175
   - Layer 3 (Claude Sonnet): 750K × $0.0092 = $6,900

**Total cost at 50K users:** ~$15,000/month
**Revenue at 50K users (30% premium):** 15,000 × $8 = **$120,000/month**
**Margin:** 88% ($105,000 profit)

---

## 9. TECHNOLOGY DEPENDENCIES

### External Services

| Service | Provider | Purpose | SLA | Contract |
|---------|----------|---------|-----|----------|
| **UPCitemdb API** | UPCitemdb | Barcode product lookup (Layer 2b) | 99.9% uptime | DEV plan ($99/month, 20K searches/day) |
| **SerpAPI Google Lens** | SerpAPI Inc. | Visual product search | 99.9% uptime | Production plan ($50/month, 5K searches) |
| **Gemini 2.5 Flash-Lite** | Google (Vertex AI) | Attribute extraction | 99.95% uptime | Pay-as-you-go (GA since July 2025) |
| **Claude Sonnet 4.5** | Anthropic | AI synthesis, conflict resolution | 99.9% uptime | Batch API, pay-as-you-go |
| **Claude Haiku 4.5** | Anthropic | SerpAPI result parsing | 99.9% uptime | Pay-as-you-go |
| **Firebase** | Google | Auth, database, analytics | 99.95% uptime | Pay-as-you-go |
| **Google Cloud Storage** | Google | Temporary image hosting | 99.95% uptime | Pay-as-you-go |
| **Cloud Memorystore** | Google | Redis queue for Layer 2b | 99.9% uptime | Pay-as-you-go |
| **Apple Vision Framework** | Apple | On-device object detection | N/A (on-device) | iOS SDK license |
| **Stripe** | Stripe | Payments (if not Apple IAP) | 99.99% uptime | Standard Stripe agreement |

### Third-Party SDKs

| SDK | Version | Purpose | License |
|-----|---------|---------|---------|
| **Firebase iOS SDK** | 10.x | Auth, Firestore, Storage, Analytics, Crashlytics | Apache 2.0 |
| **Stripe iOS SDK** | 23.x (if not Apple IAP) | Subscription management | MIT |
| **StoreKit 2** | iOS 15+ | Apple In-App Purchase (if chosen) | Apple SDK license |

---

## 10. TECHNOLOGY VERSIONS

| Technology | Version | Release Date | Status |
|-----------|---------|--------------|--------|
| **iOS** | 26.0+ | September 2025 | Required minimum |
| **Swift** | 6.0 | September 2025 | Current stable |
| **Xcode** | 17.0+ | September 2025 | Development environment |
| **YOLOv3-Tiny** | Core ML (Apple) | Pre-trained | Bundled with app (35.4MB) |
| **Gemini 2.5 Flash-Lite** | GA | July 2025 | Production ready |
| **Claude Haiku 4.5** | claude-haiku-4-5-20250429 | April 2025 | Production ready |
| **Claude Sonnet 4.5** | claude-sonnet-4-5-20250929 | September 2025 | Production ready (Batch API) |
| **SerpAPI** | Production plan | Current | 5,000 searches/month |
| **Redis** | 7.0+ | Cloud Memorystore | Production ready |
| **Node.js** | 20 LTS | October 2023 | Cloud Functions runtime |
| **Firebase iOS SDK** | 10.x | Current | Auth, Firestore, Storage |

---

## 11. OPEN QUESTIONS

### Question 1: ~~Google Shopping Graph API Access~~ (RESOLVED)

**Status:** ✅ RESOLVED (Stage 2.1)

**Resolution:** Replaced with SerpAPI Google Lens + multi-AI pipeline (ADR-016, ADR-017)
- Layer 2b uses SerpAPI Google Lens for visual product search
- No direct Google Shopping Graph API required
- Cost: $0.0109 per item (SerpAPI + Claude Haiku + GCS)

---

### Question 2: Payment Strategy (Stripe vs Apple IAP)

**Status:** TBD (ADR-014 required)

**Trade-offs:**
- **Apple IAP:** Simpler integration, 30% fee, better user trust
- **Stripe:** 3% fee, more control, web sign-up friction

**Recommendation:** Start with Apple IAP (faster to market), add Stripe in Month 4+

**Action:** Finalize ADR-014 (Payment Strategy)

---

### Question 3: Full-Text Search Implementation

**Status:** Deferred to Stage 2.3 (Backend Architecture Deep-Dive)

**Options:**
1. **Algolia:** Hosted search, $1/1000 searches (free tier: 10K searches/month)
2. **Meilisearch:** Self-hosted, open-source, $50/month (Cloud Run hosting)
3. **Firestore queries:** Limited full-text search (client-side filtering)

**Recommendation:** Start with Firestore queries (MVP), add Algolia if search becomes critical feature

---

## 12. NEXT STEPS

1. ✅ **TECH-STACK-001:** Complete (this document, updated for Stage 2.1)
2. ✅ **ADR-004 to ADR-017:** Architecture Decision Records (complete)
3. ✅ **DESIGN-004:** 4-Layer AI Pipeline Architecture (complete)
4. ✅ **DESIGN-005:** SerpAPI Google Lens Integration (complete)
5. ⏳ **API-CONTRACTS-001:** Define REST endpoints, request/response schemas
6. ⏳ **TEST-STRATEGY-001:** Test pyramid, multi-AI pipeline validation strategy
7. ⏳ **IMPLEMENTATION-001:** iOS app implementation plan

**Stage 2.1 Status:** Architecture verified, ready for implementation

---

## Appendix A: Technology Alternatives Considered

| Layer | Chosen (Stage 2.1) | Alternatives Considered | Why Rejected |
|-------|--------|-------------------------|--------------|
| **Client** | iOS 26 (Swift) | React Native, Flutter | Requires native Vision Framework, React Native bridge has performance overhead |
| **Backend** | GCP (Firebase + Cloud Memorystore) | AWS (Amplify), Supabase | Multi-AI pipeline requires GCP, Redis for queue management |
| **Database** | Firestore | PostgreSQL (Cloud SQL), MongoDB | Offline-first requirement, Firestore iOS SDK is best-in-class |
| **On-Device AI** | YOLOv3-Tiny (Core ML) | VNRecognizeObjectsRequest (built-in) | COCO classes more comprehensive (80 vs ~30) |
| **Layer 2a AI** | Gemini 2.5 Flash-Lite | GPT-4V Mini, Claude Haiku | Cost ($0.000249 vs $0.001), latency (30-50ms vs 500ms) |
| **Layer 2b Search** | SerpAPI Google Lens | Google Shopping Graph (direct), Clarifai | No direct Shopping Graph API, SerpAPI is production-ready |
| **Layer 3 AI** | Claude Sonnet 4.5 (Batch) | GPT-4, Gemini Pro | Reasoning quality, batch discount (50%), conflict resolution superior |
| **Queue** | Redis (Cloud Memorystore) | Cloud Tasks, Pub/Sub | Real-time queue depth visibility, deduplication, retry logic built-in |
| **Payments** | TBD (IAP or Stripe) | RevenueCat, Paddle | RevenueCat adds layer of abstraction (not needed for simple subscription), Paddle not supported in App Store |

---

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| **Vision Framework** | Apple's iOS SDK for image analysis (object detection, face detection, text recognition) |
| **Apple Neural Engine** | Specialized hardware in A-series chips (A11+) for ML inference acceleration |
| **YOLOv3-Tiny** | Lightweight object detection model (COCO dataset, 80 classes, 35.4MB) |
| **COCO Dataset** | Common Objects in Context - 80 object categories for training object detection models |
| **Gemini 2.5 Flash-Lite** | Google's lightweight multimodal AI model (GA since July 2025, optimized for speed) |
| **Claude Sonnet 4.5** | Anthropic's reasoning AI model (claude-sonnet-4-5-20250929, Batch API support) |
| **Claude Haiku 4.5** | Anthropic's fast AI model (claude-haiku-4-5-20250429, optimized for parsing) |
| **SerpAPI Google Lens** | Visual product search API (powered by Google Lens, Production plan) |
| **Cloud Memorystore** | Google's managed Redis service (in-memory data store, queue management) |
| **Firestore** | Google's NoSQL database (document-based, real-time sync, offline-first) |
| **Cloud Functions** | Google's serverless compute platform (FaaS - Function-as-a-Service) |
| **Cloud CDN** | Google's content delivery network (global edge caching, low latency) |
| **StoreKit 2** | Apple's latest in-app purchase SDK (iOS 15+, async/await APIs) |
| **MAU** | Monthly Active Users |
| **QPS** | Queries Per Second |
| **p95** | 95th percentile (latency metric: 95% of requests complete within X seconds) |

---

**Document Metadata:**
- **Word Count:** ~9,500 words
- **Estimated Reading Time:** 35 minutes
- **Target Audience:** Engineering team, product leadership, investors
- **Review Status:** Approved (Stage 2.1 complete)

---

## Appendix C: Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| **1.0** | 2025-10-24 | Architecture Team | Original version with Google Shopping Graph |
| | | | - 2-tier freemium model (Free: Vision Framework, Premium: Shopping Graph) |
| | | | - Single AI provider (Google Shopping Graph, $0.007/item) |
| | | | - Firebase Storage for image hosting |
| | | | - VNRecognizeObjectsRequest for object detection |
| **2.0** | 2025-11-01 | Architecture Team | Stage 2.1 verified stack update (4-layer architecture) |
| | | | - **Layer 1:** Replaced VNRecognizeObjectsRequest → VNCoreMLRequest with YOLOv3-Tiny |
| | | | - **Layer 2a:** Added Gemini 2.5 Flash-Lite for attribute extraction ($0.000249) |
| | | | - **Layer 2b:** Replaced Shopping Graph → SerpAPI Google Lens + Claude Haiku ($0.0109) |
| | | | - **Layer 3:** Added Claude Sonnet 4.5 for AI synthesis ($0.0092) |
| | | | - Replaced Firebase Storage → Google Cloud Storage + Cloud CDN |
| | | | - Added Cloud Memorystore (Redis) for queue management |
| | | | - Updated cost: $0.007 → $0.019449 per item |
| | | | - Updated latency: 2-5s → 7-10s end-to-end |
| | | | - Added new ADRs: ADR-014, ADR-015, ADR-016, ADR-017 |
| | | | - Added DESIGN-004, DESIGN-005, RECONCILIATION-design-004-vs-stage-2.1.md |
| **2.1** | 2025-11-06 | Architecture Team | Added barcode scanning feature (ADR-018) |
| | | | - **Layer 1:** Added VNDetectBarcodesRequest (parallel with YOLOv3-Tiny) |
| | | | - **Layer 2b:** Added UPCitemdb API for barcode product lookup ($99/month DEV plan) |
| | | | - **Layer 3:** Added barcode validation and conflict resolution tasks |
| | | | - Added UPCitemdb to External Services dependency list |
| | | | - Barcode-first strategy: Try UPCitemdb → fallback to SerpAPI |
| | | | - Cost impact: ~7.1% reduction for barcoded items |
| | | | - New ADR: ADR-018 (Barcode Product Lookup Strategy) |
| | | | - New Research: RESEARCH-BARCODE-API-2025-11-06 (API comparison) |
| | | | - Updated DESIGN-004, SCHEMA-001, ADR-015 with barcode workflow |

**Key Architectural Changes (v1.0 → v2.0):**
1. Multi-AI pipeline replaces single AI provider (Google Shopping Graph)
2. 4-layer architecture: Layer 1 (on-device) → Layer 2a (attributes) → Layer 2b (search) → Layer 3 (synthesis)
3. SerpAPI Google Lens replaces direct Shopping Graph API
4. Redis queue for background processing of Layer 2b
5. GCS + Cloud CDN for temporary image hosting (replaces Firebase Storage)

---

**Related Documents:**
- PRD-001: Product Requirements Document
- ADR-003: MVP Scope and Phasing Decision
- ADR-004 to ADR-017: Architecture Decision Records
- ADR-014: Multi-AI Pipeline Architecture
- ADR-015: Claude Sonnet 4.5 for AI Synthesis
- ADR-016: SerpAPI Google Lens for Product Search
- ADR-017: Redis Queue for Background Processing
- DESIGN-004: 4-Layer AI Pipeline Architecture
- DESIGN-005: SerpAPI Google Lens Integration
- RECONCILIATION-design-004-vs-stage-2.1.md: Architecture Reconciliation
- API-CONTRACTS-001: Service Interface Definitions (to be created)
- TEST-STRATEGY-001: Test Pyramid (to be created)

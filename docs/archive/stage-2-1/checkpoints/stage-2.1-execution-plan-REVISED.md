# Stage 2.1 Execution Plan: High-Level Tech Stack Mapping (REVISED)

**Document ID:** PLAN-2.1-REVISED
**Date:** 2025-10-24
**Stage:** 2.1 - High-Level Tech Stack Mapping
**Status:** APPROVED - READY TO EXECUTE
**Prerequisite:** Stage 1.2 Complete ✅ + iOS 26 Research ✅ + User Decisions ✅

---

## Executive Summary

This revised plan incorporates **iOS 26 Foundation Models research** and **user decisions** to define the complete technology stack for Abundance MVP.

**Critical Corrections from Original Plan:**

1. ✅ **iOS 26 Vision for Detection Only:** On-device object detection/cropping (NOT full AI analysis)
2. ✅ **Google Shopping Graph as PRIMARY AI:** Cloud-based product identification (not Gemini/GPT-4V)
3. ✅ **Freemium Model:** Free on-device cataloging, paid cloud AI features
4. ✅ **Silent Retry Strategy:** No fallback UX, automatic retry if Shopping Graph fails
5. ✅ **Privacy as Secondary Benefit:** Not lead marketing message, but part of story

**Architecture Overview:**

```
iOS 26 On-Device (FREE):
  Vision Framework → Detect objects → Crop images → Basic labels
  Save to Firestore: "scissors, headphones" (coarse inventory)

Cloud AI (PREMIUM - $4.99-8/month):
  Upload cropped images → Google Shopping Graph
  → "Scott Fabric Scissors, Beats Pro 2 Headphones"
  → Granular product details (brand, model, price)
```

---

## Input Documents

**From Stage 1.1 (Business Strategy):**

- `docs/specs/business-strategy-validated.md`
- `docs/adr/ADR-001-strategic-positioning.md`
- `docs/adr/ADR-002-platform-strategy.md`

**From Stage 1.2 (Product Strategy):**

- `docs/specs/PRD-001-abundance-inventory-mvp.md` ⭐ PRIMARY
- `docs/specs/user-persona-cards.md`
- `docs/specs/feature-prioritization-matrix.md`
- `docs/adr/ADR-003-mvp-scope-phasing.md`

**From Stage 2.4 (iOS 26 Research):**

- `docs/checkpoints/CHECKPOINT-stage-2.4-ios26-research.md`
- `docs/research/ios-26-foundation-models-architecture.md`
- `docs/research/google-lens-architecture-analysis.md`
- `docs/specs/mvp-vision-features.md`
- `docs/adr/ADR-013-vision-framework-strategy.md`
- `docs/adr/ADR-014-cloud-ai-provider-selection.md`

---

## 10 Critical Technology Decisions (REVISED)

### Decision 1: Client Platform

**Question:** Which iOS version minimum? Device requirements?

**Decision:** **iOS 26.0 minimum, iPhone 15 Pro+ required**

**Rationale:**

- iOS 26 Vision Framework required for advanced object detection
- Apple Neural Engine (A17 Pro+) required for on-device ML performance
- Target early adopters (~15% of iOS market, growing to 30% by Month 12)

**Device Requirements:**

- iPhone 15 Pro or newer (A17 Pro chip)
- iPad with M1 or newer
- iOS 26.0 or later

**Market Size Trade-off:**

- **Smaller market:** ~15% of iOS users at launch
- **Better economics:** Free tier is truly free (no cloud costs)
- **Premium features:** Paid tier unlocks Google Shopping Graph

**Swift/UI:**

- Swift 6.0 (latest stable)
- SwiftUI (declarative, modern)

**ADR:** ADR-004 (iOS 26-Only Launch Strategy)

---

### Decision 2: Backend Platform (Cloud Provider)

**Question:** GCP vs. AWS vs. Azure?

**Decision:** **GCP (Google Cloud Platform)**

**Rationale:**

1. **Google Shopping Graph Integration:** Native Google service, tight integration
2. **Firebase Ecosystem:** Auth, Firestore, Storage work seamlessly
3. **Cost Efficiency:** Firestore free tier supports early growth
4. **Unified Billing:** Single cloud provider simplifies operations

**No Change from Original Plan** ✅

**ADR:** ADR-005 (GCP Platform Selection)

---

### Decision 3: Backend Architecture

**Question:** Monolith-first or microservices?

**Decision:** **Monolith-First (Firebase Cloud Functions)**

**Rationale:**

- Small team (3-4 engineers), monolith faster to iterate
- Single codebase, single deployment
- Can extract microservices later when needed

**Backend Responsibilities (REVISED):**

```
Cloud Functions:
  1. Receive cropped images from iOS app
  2. Call Google Shopping Graph API
  3. Return product metadata (brand, model, price)
  4. Save to Firestore
  5. Notify iOS app via real-time listener

NOT NEEDED:
  - Object detection (done on-device)
  - Image cropping (done on-device)
  - Basic labeling (done on-device)
```

**No Change from Original Plan** ✅

**ADR:** ADR-006 (Monolith-First Backend Architecture)

---

### Decision 4: API Style

**Question:** REST vs. GraphQL vs. gRPC?

**Decision:** **REST + JSON**

**Rationale:**

- Simple CRUD operations
- Firebase SDK provides Firestore REST interface
- Good iOS tooling (URLSession, Codable)

**API Endpoints (REVISED):**

```
FREE TIER:
  - No API calls (on-device only, direct Firestore write)

PREMIUM TIER:
  POST /enrich-item
  - Upload: Cropped image + basic label
  - Process: Google Shopping Graph lookup
  - Return: Enhanced metadata (brand, model, price)
```

**No Change from Original Plan** ✅

**ADR:** ADR-007 (REST API Design)

---

### Decision 5: Database

**Question:** Firestore vs. Cloud SQL vs. Hybrid?

**Decision:** **Cloud Firestore (NoSQL)**

**Rationale:**

- Offline-first (free tier works without backend)
- Real-time sync (iOS SDK)
- Auto-scaling
- Generous free tier (50K reads/day, 20K writes/day)

**Data Model (REVISED):**

```
users/{userId}/items/{itemId}
{
  // FREE TIER (on-device Vision)
  name: "scissors, headphones"  (basic label)
  category: "Office Supplies"  (inferred)
  photo: "photo_id"  (reference to local iOS storage)
  createdAt: timestamp
  tier: "free"

  // PREMIUM TIER (Google Shopping Graph)
  name: "Scott Fabric Scissors, Beats Pro 2"  (specific products)
  brand: "Scott, Beats"
  model: "8-inch Fabric Scissors, Pro 2 Over-Ear"
  estimatedValue: 12.99, 199.99
  productUrl: "https://shopping.google.com/..."
  enrichedAt: timestamp
  tier: "premium"
}
```

**No Change from Original Plan** ✅

**ADR:** ADR-008 (Cloud Firestore Database Selection)

---

### Decision 6: Authentication

**Question:** Firebase Auth vs. custom solution?

**Decision:** **Firebase Authentication**

**Rationale:**

- Supports Apple Sign-In (70% adoption expected)
- Email/Password fallback (30%)
- Anonymous upgrade path
- Free tier (50K MAU)

**No Change from Original Plan** ✅

**ADR:** ADR-009 (Firebase Authentication)

---

### Decision 7: File Storage

**Question:** Where to store photos?

**Decision:** **Hybrid: iOS Local Storage (Primary) + Firebase Storage (Cloud AI)**

**Rationale:**

**Free Tier (On-Device Only):**

- Photos stored in iOS Photo Library OR app sandbox
- Metadata stored in Firestore (text only)
- No cloud storage costs

**Premium Tier (Cloud AI):**

- Cropped images uploaded to Firebase Storage
- Google Shopping Graph processes images
- Images can be deleted after processing (optional retention for user history)

**Storage Structure:**

```
FREE TIER:
  - iOS local only (Photo Library or app Documents folder)
  - Firestore: Metadata only, photo reference

PREMIUM TIER:
  users/{userId}/enrichment-queue/{itemId}/
    cropped_object_1.jpg  (uploaded for Shopping Graph)
    cropped_object_2.jpg
```

**Cost Estimate (Month 6, 5K users):**

- Free tier users (70%): $0 (no upload)
- Premium users (30%): 1,500 × 50 items × 150 KB = 11.25 GB
- Firebase Storage: 11.25 GB × $0.026/GB = **$0.29/month** (negligible)

**ADR:** ADR-010 (Hybrid Storage: Local-First + Cloud Enrichment)

---

### Decision 8: Compute

**Question:** Cloud Functions vs. App Engine vs. Cloud Run?

**Decision:** **Cloud Functions (Firebase 2nd gen)**

**Rationale:**

- Serverless (pay per invocation)
- Auto-scales
- Firebase integration (Firestore triggers, Storage triggers)

**Function Types (REVISED):**

```
1. Product Enrichment (HTTPS callable):
   Trigger: iOS app calls with cropped images
   Process: Google Shopping Graph API
   Timeout: 10 sec (Shopping Graph can be slow)
   Memory: 512 MB (image processing minimal, API calls only)

2. Retry Failed Enrichments (Scheduled):
   Trigger: Cloud Scheduler (every 6 hours)
   Process: Retry items where Shopping Graph failed
   Silent retry (no user notification)
```

**No Change from Original Plan** ✅

**ADR:** ADR-011 (Cloud Functions for Compute)

---

### Decision 9: AI/ML Platform (VERIFIED 2025-10-30 - Multi-Layer AI Architecture)

**Question:** What AI services for product identification?

**Architecture (VERIFIED 2025-10-30 - All technologies confirmed):**

**Layer 1 (FREE TIER): iOS Vision Framework + Core ML YOLOv3-Tiny**

- **Purpose:** Object detection and cropping (NOT full AI analysis)
- **Technology:** iOS Vision Framework + Core ML YOLOv3-Tiny (35MB model)
- **Implementation:** `VNCoreMLRequest` wrapper (verified: Apple doesn't provide built-in generic object detection)
- **Output:** Bounding boxes + basic labels from 80 COCO object classes
- **Cost:** $0 (on-device, one-time 35MB model download)
- **Performance:** 50-150ms per image (verified, well under 500ms target)
- **Detection Rate:** 70-80% for common household items
- **Device Requirements:** iPhone 15 Pro+ (A17 Pro chip) recommended, iPhone 13+ supported

**Layer 2a (PREMIUM TIER): Vision Analysis - Gemini 2.5 Flash-Lite**

- **Purpose:** Extract object attributes from cropped images
- **Input:** Cropped images from Layer 1
- **API:** GCP Vertex AI (Gemini 2.5 Flash-Lite)
- **Output:** Object attributes JSON
  ```json
  {
    "condition": "used",
    "condition_confidence": 0.85,
    "color": ["red", "black"],
    "material": "plastic",
    "material_confidence": 0.92,
    "size_category": "small",
    "category": "electronics",
    "subcategory": "gaming_controller",
    "notable_features": ["PlayStation logo", "USB-C port"]
  }
  ```
- **Cost:** $0.000249 per image (verified 2025-10-30)
  - Pricing: $0.10 per 1M input tokens, $0.40 per 1M output tokens
  - Calculation: (1,290 input / 1M) × $0.10 + (300 output / 1M) × $0.40 = $0.000249
- **Performance:** <1 second per image
- **Runs in parallel with Layer 2b**

**Layer 2b (PREMIUM TIER): Visual Product Search - SerpApi Google Lens + Image Hosting + LLM Parsing**

- **Purpose:** Product identification (specific brand, model, price) using Google Lens
- **Input:** Cropped images from Layer 1
- **Technology:** SerpApi Google Lens API + AWS S3/CloudFront + Claude Haiku 4.5
- **Research Update (2025-10-30):** Google Shopping Graph API does not exist as developer-accessible API
  - Content API: For merchants to upload products (not search)
  - Vision API Product Search: Requires building own catalog ($4.50/1K queries)
  - **SerpApi Google Lens:** Access to real Google Lens visual search results
- **Architecture (3 sub-steps - CRITICAL ADDITION):**
  1. **Image Hosting:** Compress JPEG (85%) → Upload to S3/CloudFront → Generate public URL (SerpAPI requires public URLs, no direct upload)
  2. **Visual Search:** Call SerpAPI Google Lens with public URL → Returns 10-25 product matches
  3. **LLM Parsing:** Use Claude Haiku 4.5 to extract brand/model from combined title string (SerpAPI doesn't provide separate fields)
- **Output:** Product matches from Google Lens
  ```json
  {
    "visual_matches": [
      {
        "title": "Sony DualSense Wireless Controller",  // Combined title (requires parsing)
        "source": "Amazon",
        "link": "https://www.amazon.com/...",
        "price": {"value": "69.99", "currency": "USD"},
        "thumbnail": "https://..."
        // Note: No confidence score, no separate brand/model fields
      }
    ]
  }
  ```
- **Cost Breakdown:**
  - SerpAPI search: $0.010 (Production plan: $150/month for 15K searches)
  - AWS S3/CloudFront: $0.0001 per image
  - Claude Haiku parsing: $0.0008 per inference
  - **Total Layer 2b: $0.0109 per item**
- **Performance:** 5.29s average, p95 ~7s (higher than original 2-5s estimate)
- **Reliability:** 99.76% uptime
- **Hourly Quota:** 3,000 searches/hour (requires request queue with rate limiting)
- **Runs in parallel with Layer 2a**

**Layer 3 (PREMIUM TIER): AI Reasoning & Synthesis - Claude Sonnet 4.5 (Batch API)**

- **Purpose:** Validate, synthesize, and resolve conflicts between vision + product search
- **Input:** Vision analysis (Layer 2a) + SerpAPI results (Layer 2b) + parsed brand/model + basic label (Layer 1)
- **Technology:** Claude Sonnet 4.5 (Batch API) via Anthropic or GCP Vertex AI
- **Why Sonnet 4.5:** Replaces Claude 3.5 Sonnet (verified 2025-10-30)
  - Graduate-level reasoning: 83.4% GPQA Diamond (vs. ~75% for 3.5)
  - Best-in-class structured output: 61.4% OSWorld (leading all models)
  - Hybrid reasoning mode: Fast + extended thinking
  - Batch API: 50% cost savings
- **Reasoning Tasks:**
  - Compare vision attributes against SerpAPI candidates
  - Resolve conflicts (e.g., vision says "red" but SerpAPI shows "blue variant")
  - Select best product match from multiple candidates
  - Validate parsed brand/model against vision analysis
  - Calculate confidence proxy (position rank + price + reviews) to replace missing SerpAPI confidence scores
  - Detect mismatches (imperfect cropping, wrong product returned)
  - Determine if additional photos needed (low confidence scenarios)
  - Provide fallback attributes when SerpAPI fails
- **Output:** Final structured metadata (SCHEMA-001)
  ```json
  {
    "name": "Sony DualSense Wireless Controller",
    "brand": "Sony",
    "model": "DualSense",
    "category": "Video Games",
    "subcategory": "Controllers",
    "condition": "used",
    "color": ["red", "black"],
    "material": "plastic",
    "estimated_value": 69.99,
    "product_url": "https://shopping.google.com/...",
    "confidence": 0.88,
    "source": "shopping_graph_validated",
    "action": "save",
    "reasoning": "Vision analysis matches Shopping Graph top result"
  }
  ```
- **Cost:** $0.0092 per inference (Batch API with 50% discount, verified 2025-10-30)
  - Standard API: $0.0183 per inference
  - Batch API: $0.0092 per inference
  - Pricing: $1.50 per 1M input tokens (batch), $7.50 per 1M output tokens (batch)
  - Calculation: (2,000 input / 1M) × $1.50 + (500 output / 1M) × $7.50 = $0.0092
  - Can be further reduced to $0.0024 with prompt caching (90% savings, post-MVP optimization)
- **Performance:** 1-2 seconds per synthesis (standard mode)
- **Context Window:** 200K tokens (1M in beta)
- **Fallback Strategy:** If SerpApi Google Lens fails, uses vision-only attributes

**Workflow:**

```text
iOS App (FREE):
  1. User photos item
  2. VNRecognizeObjectsRequest → Detect objects
  3. Crop images (one per detected object)
  4. Save to Firestore: {name: "scissors", category: "Office", tier: "free"}
  5. Display in inventory: "scissors" (generic label)

iOS App (PREMIUM):
  1-3. Same as above (detect, crop)
  4. Upload cropped images to Cloud Function
  5. Cloud Function → PARALLEL processing:
     5a. Gemini 2.5 Flash-Lite → Analyze attributes (condition, color, material)
     5b. Google Shopping Graph API → Search for product matches
  6. Claude 3.5 Sonnet → Synthesize results:
     - Compare vision attributes with Shopping Graph candidates
     - Validate matches (does "red plastic controller" match Shopping Graph "DualSense"?)
     - Select best candidate or flag conflicts
     - Determine action: save, request_photo, manual_review
  7. Save to Firestore: {name: "Sony DualSense", brand: "Sony", condition: "used", ...}
  8. Display: "Sony DualSense Controller - Used - $69.99"

If Shopping Graph Fails:
  - Vision analysis (Layer 2a) still provides attributes
  - Claude reasoning layer falls back to vision-only metadata
  - Item saved with rich attributes but generic product name
  - Cloud Scheduler retries Shopping Graph lookup in 6 hours (silent)
  - User sees "Gaming Controller - Used - Red/Black" → upgraded to "Sony DualSense" after retry

Edge Cases Handled by AI Reasoning Layer:
  - Imperfect cropping → AI validates if Shopping Graph match is reasonable
  - Multiple candidates → AI compares vision attributes to pick correct variant
  - Conflicting data → AI resolves (e.g., "limited edition red variant" vs. standard)
  - Low confidence → AI requests additional photos (barcode, label close-up)
  - Rare items → AI provides best-effort attributes when Shopping Graph has no match
```

**Cost Estimate (Month 6, 5K users, 250K items) - VERIFIED 2025-10-30:**

- **Free tier (70%):** 175K items × $0 = **$0** (on-device only)
- **Premium tier (30%):** 75K items × $0.019449 = **$1,459/month**
  - Layer 1 (Vision): $0 (on-device)
  - Layer 2a (Gemini): 75K × $0.000249 = $19
  - Layer 2b (SerpAPI + S3 + Haiku): 75K × $0.0109 = $818
    - SerpAPI: $750
    - S3/CloudFront: $8
    - Haiku parsing: $60
  - Layer 3 (Claude 4.5 Batch): 75K × $0.0092 = $690
- **Total AI cost: $1,459/month** (83.8% margin at $6/user subscription)
- **Revenue: 1,500 users × $6 = $9,000/month**
- **Net revenue: $7,541/month** available for infrastructure, storage, team

**With Optimizations (Month 12+):**
- SerpApi Big Data plan: $0.009/search (vs. $0.010)
- Claude prompt caching: $0.0024/inference (90% savings vs. $0.0092)
- **Optimized cost:** 75K × ($0.000249 + $0.0099 + $0.0024) = **$918/month** (89.8% margin)

**ADR:** ADR-015 (AI Reasoning Layer with Multi-Model Architecture)

---

### Decision 10: Observability

**Question:** Logging, monitoring, analytics, error tracking?

**Decision:** **GCP Logging + Firebase Analytics + Crashlytics**

**Services:**

1. **Logging:** Cloud Logging (Cloud Functions logs)
2. **Monitoring:** Cloud Monitoring (latency, errors, Shopping Graph API failures)
3. **Analytics:** Firebase Analytics (user events, funnels)
4. **Error Tracking:** Firebase Crashlytics (iOS), Cloud Logging (backend)

**Key Metrics to Track:**

- Shopping Graph API success rate (target: >95%)
- Shopping Graph latency p95 (target: <5 sec)
- Free vs. Premium tier split (target: 30% premium conversion)
- Retry success rate (for failed Shopping Graph calls)

**No Change from Original Plan** ✅

**ADR:** ADR-013 (Observability Stack)

---

## Output Deliverables

### 1. TECH-STACK-001: Complete Technology Stack Map

**File:** `docs/tech-stack/TECH-STACK-001-complete-technology-map.md`

**Content Structure:**

```markdown
# Complete Technology Stack: Abundance MVP

## CLIENT LAYER

- Platform: iOS 26.0+ (minimum)
- Device: iPhone 15 Pro+ (A17 Pro chip required)
- Language: Swift 6.0
- UI Framework: SwiftUI
- Architecture Pattern: MVVM (TBD by iOS expert in Stage 2.2)

### On-Device AI (FREE TIER)

- Vision Framework: VNRecognizeObjectsRequest (object detection)
- Core ML: Apple Neural Engine optimization
- Output: Bounding boxes + basic labels
- Storage: iOS Photo Library or app sandbox (local only)

## API LAYER

- Protocol: REST over HTTPS
- Format: JSON
- Authentication: Firebase Auth JWT
- Base URL: https://us-central1-abundance-prod.cloudfunctions.net/api/v1

### Endpoints

- POST /enrich-item (premium tier only)
- GET /users/{userId}/items (inventory)
- GET /search (search inventory)

## BACKEND LAYER

- Platform: Google Cloud Platform (GCP)
- Compute: Cloud Functions (Node.js 20 - TBD in Stage 2.3)
- Database: Cloud Firestore (NoSQL)
- Storage: Firebase Storage (premium tier cropped images only)
- Authentication: Firebase Authentication

## AI/ML LAYER

### Free Tier (On-Device)

- Apple Vision Framework (VNRecognizeObjectsRequest)
- Output: Basic labels ("scissors", "headphones")
- Cost: $0

### Premium Tier (Cloud)

- Google Shopping Graph API (product identification)
- Input: Cropped images from on-device Vision
- Output: Brand, model, price, product URL
- Cost: ~$0.007/item (estimated)
- Retry: Cloud Scheduler (6-hour intervals for failures)

### NO FALLBACK

- No Gemini Vision
- No GPT-4V
- No user-facing fallback UX

## OBSERVABILITY LAYER

- Logging: Cloud Logging
- Monitoring: Cloud Monitoring (Shopping Graph success rate, latency)
- Analytics: Firebase Analytics
- Error Tracking: Crashlytics (iOS), Cloud Logging (backend)

## PAYMENTS LAYER

- Subscriptions: Stripe or Apple In-App Purchase (TBD - ADR-014)
- Pricing: $4.99-8/month (premium tier with Shopping Graph access)
```

---

### 2. API-CONTRACTS-001: Service Interface Definitions

**File:** `docs/tech-stack/API-CONTRACTS-001-service-interfaces.md`

**Content Structure:**

````markdown
# API Contracts: Abundance Backend

## Base URL

- Production: https://us-central1-abundance-prod.cloudfunctions.net/api/v1
- Staging: https://us-central1-abundance-staging.cloudfunctions.net/api/v1

## Authentication

All requests require Firebase Auth JWT:

```http
Authorization: Bearer <firebase-jwt-token>
```
````

## Free Tier Flow (NO API CALLS)

```javascript
// iOS app only:
1. VNRecognizeObjectsRequest → detect objects
2. Crop images
3. Firestore.collection('users/{userId}/items').add({
     name: "scissors, headphones",
     category: "Office Supplies",
     tier: "free",
     createdAt: Date.now()
   })
4. Display in inventory: "scissors, headphones"
```

## Premium Tier Flow (API CALL)

### POST /enrich-item

Enrich item with Google Shopping Graph data

**Request:**

```json
{
  "itemId": "item_abc123",
  "basicLabel": "scissors",
  "croppedImages": ["gs://abundance-prod/users/{userId}/temp/object_1.jpg"]
}
```

**Response:**

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

**Error Handling (Silent Retry):**

```json
// If Shopping Graph fails:
{
  "error": {
    "code": "SHOPPING_GRAPH_UNAVAILABLE",
    "message": "Will retry automatically in 6 hours",
    "retryAt": "2026-01-15T16:00:00Z"
  },
  "fallbackMetadata": {
    "name": "scissors", // Keep basic label
    "tier": "free" // Downgrade to free tier temporarily
  }
}
```

## Rate Limits

- Free tier: N/A (no API calls)
- Premium tier: 100 enrichments/hour per user

````

---

### 3. ADR-004 to ADR-014: Architecture Decision Records

**Files:** `docs/adr/ADR-004-*.md` through `ADR-014-*.md`

**List of ADRs:**

1. **ADR-004:** iOS 26-Only Launch Strategy
   - Decision: Require iOS 26 + iPhone 15 Pro+
   - Market trade-off: 15% users vs. free on-device tier
   - Rationale: Early adopters, superior economics, expansion later

2. **ADR-005:** GCP Platform Selection
   - Decision: Google Cloud Platform
   - Rationale: Shopping Graph integration, Firebase ecosystem

3. **ADR-006:** Monolith-First Backend Architecture
   - Decision: Single Cloud Functions codebase
   - Rationale: Small team, faster iteration

4. **ADR-007:** REST API Design
   - Decision: REST + JSON
   - Rationale: Simple CRUD, good iOS tooling

5. **ADR-008:** Cloud Firestore Database Selection
   - Decision: Firestore (NoSQL)
   - Rationale: Offline-first, real-time sync

6. **ADR-009:** Firebase Authentication
   - Decision: Firebase Auth (Apple Sign-In + Email)
   - Rationale: iOS SDK integration, free tier

7. **ADR-010:** Hybrid Storage Strategy
   - Decision: iOS local (free tier) + Firebase Storage (premium)
   - Rationale: Cost efficiency, privacy

8. **ADR-011:** Cloud Functions for Compute
   - Decision: Firebase Cloud Functions
   - Rationale: Serverless, auto-scaling, Firebase integration

9. **ADR-015:** AI Reasoning Layer with Multi-Model Architecture (UPDATED 2025-10-29)
   - Decision: Three-layer AI architecture (Vision + Shopping Graph + Reasoning)
   - Models: Gemini 2.5 Flash-Lite + Google Shopping Graph + Claude 3.5 Sonnet
   - Rationale: 90% margin, frontier accuracy, handles all edge cases
   - Cost: $0.0119/item (vs. $0.007 for Shopping Graph only)
   - Trade-off: +$368/month for "like magic" accuracy

10. **ADR-013:** Observability Stack
    - Decision: GCP Logging + Firebase Analytics + Crashlytics
    - Rationale: Native GCP integration

11. **ADR-014:** Payment Integration Strategy (NEW)
    - Decision: Stripe vs. Apple In-App Purchase (TBD)
    - Trade-off: Stripe 3% fee vs. Apple 30% fee
    - Legal/UX implications to research

**NOTE:** ADR-012 (Google Shopping Graph as Primary AI) has been superseded by ADR-015 (AI Reasoning Layer)

---

### 4. TEST-STRATEGY-001: Test Pyramid & Coverage Goals

**File:** `docs/test/TEST-STRATEGY-001-test-pyramid.md`

**Content Structure:**
```markdown
# Test Strategy: Abundance MVP

## Test Pyramid

````

       /\
      /E2E\         10% - Key flows (free catalog, premium enrich)
     /______\
    /        \

/Integration\ 20% - Shopping Graph API, Vision Framework
/****\_\_****\
 / \
/ Unit Tests \ 70% - Business logic, metadata parsing
/******\_\_\_\_******\

```

## Unit Tests (70%)

**iOS:**
- Vision Framework integration (mock VNRequests)
- Shopping Graph API client (mock responses)
- Firestore CRUD operations
- Metadata parsing (JSON → Swift models)

**Backend:**
- Shopping Graph API wrapper
- Retry logic (failed enrichments)
- Error handling

**Coverage Goals:**
- Critical paths: 90%+
- Supporting features: 70%+

## Integration Tests (20%)

**Shopping Graph Integration:**
- Test with sample cropped images
- Validate response parsing
- Test retry logic (simulate failures)

**Vision Framework Integration:**
- Test VNRecognizeObjectsRequest on sample images
- Validate bounding box accuracy
- Test cropping logic

## E2E Tests (10%)

**Critical Flows:**
1. **Free Tier:** Photo → Detect → Crop → Save → Display
2. **Premium Tier:** Photo → Detect → Crop → Upload → Shopping Graph → Display
3. **Retry:** Shopping Graph fails → Silent retry → Eventually succeeds

**Tools:** XCUITest (iOS), Supertest (backend)

## Performance Tests

**Targets:**
- On-device detection: <500ms (p95)
- Shopping Graph enrichment: <5 sec (p95)
- Retry success rate: >90% (within 24 hours)

## Shopping Graph Validation Tests

**Dataset:** 50 diverse household items (from research POC plan)
- Office supplies: Scissors, stapler, tape
- Electronics: Headphones, charger, mouse
- Kitchen: Utensils, containers
- Clothing: Shoes, shirt (folded)
- Tools: Drill, screwdriver, hammer

**Success Criteria:**
- Shopping Graph accuracy: >75% (correct brand/model)
- Confidence score: >0.8 for accurate items
- Failure rate: <10% (retry should catch most)

**Failure Analysis:**
- Log failed items
- Identify patterns (e.g., generic items with no brand)
- Iterate on input image quality (cropping, lighting)
```

---

### 5. SHOPPING-GRAPH-INTEGRATION-001: API Integration Specification (NEW)

**File:** `docs/tech-stack/SHOPPING-GRAPH-INTEGRATION-001.md`

**Content:**

````markdown
# Google Shopping Graph Integration Specification

**Purpose:** Define how Abundance integrates with Google Shopping Graph API

---

## API Overview

**Service:** Google Shopping Graph API
**Documentation:** https://cloud.google.com/retail/docs (TBD - exact endpoint)
**Access:** Via Vertex AI or direct Shopping API

**Capabilities:**

- Product identification from images
- Brand, model, category extraction
- Price estimation (MSRP)
- Product URLs (Google Shopping links)

---

## Input Format

**Cropped Image Requirements:**

- Format: JPEG or PNG
- Size: 512x512 to 1024x1024 (optimal for Shopping Graph)
- Quality: High (avoid compression artifacts)
- Content: Single product, centered, good lighting

**Request Structure (TBD - depends on actual API):**

```json
POST https://retail.googleapis.com/v2/projects/{project}/locations/{location}/catalogs/{catalog}:searchImages
{
  "image": {
    "imageBytes": "<base64-encoded-image>"
  },
  "maxResults": 1,
  "includeMetadata": true
}
```
````

---

## Output Format

**Response Structure (Expected):**

```json
{
  "results": [
    {
      "product": {
        "name": "Scott Fabric Scissors 8-inch",
        "brand": "Scott",
        "categories": ["Office Supplies", "Scissors"],
        "priceInfo": {
          "price": 12.99,
          "currencyCode": "USD"
        },
        "images": [
          {
            "uri": "https://lh3.googleusercontent.com/..."
          }
        ],
        "uri": "https://www.google.com/shopping/product/..."
      },
      "matchingScore": 0.92
    }
  ]
}
```

---

## Error Handling

**Common Errors:**

- `INVALID_ARGUMENT`: Image format invalid → Retry with re-encoded image
- `RESOURCE_EXHAUSTED`: Rate limit hit → Exponential backoff
- `NOT_FOUND`: Product not in graph → Save with basic label, retry later
- `UNAVAILABLE`: Service down → Silent retry in 6 hours

**Retry Strategy:**

```javascript
async function enrichWithRetry(croppedImage, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const result = await shoppingGraphAPI.search(croppedImage);
      if (result.matchingScore > 0.75) {
        return result;
      }
    } catch (error) {
      if (attempt === maxRetries) {
        // Final retry failed, schedule for later
        await scheduleRetry(croppedImage, Date.now() + 6 * 3600 * 1000);
        return { fallback: "basic-label" };
      }
      await sleep(Math.pow(2, attempt) * 1000); // Exponential backoff
    }
  }
}
```

---

## Cost Model

**Pricing (Estimated - TBD):**

- Per image search: $0.005 - $0.010
- Volume discounts: TBD (negotiate with Google)

**Monthly Cost Projection (Month 6):**

- Premium users: 1,500 (30% of 5,000 total)
- Items per user: 50/month
- Total enrichments: 75,000/month
- Cost: 75,000 × $0.007 = **$525/month**

**Revenue:**

- Premium users: 1,500 × $6/month = **$9,000/month**
- Margin: $9,000 - $525 = **$8,475** (94% margin)

---

## Performance Targets

- Latency p50: <3 sec
- Latency p95: <5 sec
- Success rate: >95% (including retries)
- Accuracy: >75% (correct brand/model)

---

## Research Required (Stage 2.3)

1. **Exact API endpoint:** Confirm Shopping Graph vs. Vision Product Search API
2. **Pricing:** Get official pricing from Google
3. **Rate limits:** Understand quotas, request volume discounts
4. **Image requirements:** Optimal image size, format, quality for best results
5. **Accuracy benchmarks:** Test with 50-item dataset, measure precision/recall

```

---

## Execution Steps (REVISED)

### Step 1: Load Martin Fowler Persona (IF EXISTS)

**Action:**
```

Check if shared/cognitive_stylometry_martin-fowler_v1.0.json exists.
If not, proceed with best-effort Martin Fowler-style analysis.

```

**Frameworks to Apply:**
1. Evolutionary Architecture
2. Monolith-First
3. YAGNI
4. Technical Debt
5. Test Pyramid

---

### Step 2: Read All Input Documents

**Priority:**
1. PRD-001 (requirements)
2. ADR-003 (MVP phasing)
3. Stage 2.4 iOS 26 research documents
4. Google Lens architecture analysis
5. User decisions (this conversation)

---

### Step 3: Make 10 Technology Decisions

**Per decision:**
1. State question
2. List 2-3 options
3. Apply Fowler framework
4. Make recommendation with rationale
5. Note cost, complexity, migration path

---

### Step 4: Create Deliverables

**Deliverable 1:** TECH-STACK-001 (~3,000 words)
- Complete tech map (CLIENT → API → BACKEND → AI/ML → OBSERVABILITY)
- Highlight freemium split (on-device vs. cloud)

**Deliverable 2:** API-CONTRACTS-001 (~2,000 words)
- REST endpoints
- Free tier: No API calls
- Premium tier: /enrich-item endpoint

**Deliverable 3-13:** ADRs (11 total, ~1,000 words each)
- ADR-004 to ADR-014
- Focus on Shopping Graph decision (ADR-012)

**Deliverable 4:** TEST-STRATEGY-001 (~2,000 words)
- Test pyramid
- Shopping Graph validation tests

**Deliverable 5:** SHOPPING-GRAPH-INTEGRATION-001 (~1,500 words) - NEW
- API integration spec
- Retry logic
- Cost model

---

### Step 5: Create Checkpoint Report

**File:** `docs/checkpoints/CHECKPOINT-2.1-tech-stack-mapping.md`

**Content:**
- Executive summary of 10 decisions
- Tech stack diagram (text-based)
- Open questions (2-3 questions)
- Risk register
- Recommendation: PROCEED TO STAGE 2.2

**Open Questions (Examples):**
1. **Stripe vs. Apple IAP for subscriptions?** (30% vs. 3% fee, legal implications)
2. **Google Shopping Graph exact API?** (Need research in Stage 2.3)
3. **Retry interval optimization?** (6 hours vs. 12 hours vs. 24 hours)

---

### Step 6: Human Review & Approval

**Review Checklist:**
- [ ] All 10 decisions made and justified
- [ ] Tech stack map complete (no blocking TBD items)
- [ ] ADRs well-reasoned (Fowler frameworks applied)
- [ ] API contracts implementable
- [ ] Test strategy includes Shopping Graph validation
- [ ] Costs estimated (within budget)
- [ ] Open questions answerable

**Approval Decision:**
- **APPROVED:** Proceed to Stage 2.2 (iOS Architecture)
- **REVISE:** Address concerns
- **BLOCKED:** External dependency needed

---

## Timeline & Effort Estimate

**Stage 2.1 Duration:** 2-3 days (16-24 hours of agent work)

**Breakdown:**
- Read input documents: 2 hours
- Make 10 decisions: 10 hours (1 hour each)
- Write TECH-STACK-001: 3 hours
- Write API-CONTRACTS-001: 2 hours
- Write 11 ADRs: 11 hours (1 hour each)
- Write TEST-STRATEGY-001: 2 hours
- Write SHOPPING-GRAPH-INTEGRATION-001: 1.5 hours
- Write checkpoint report: 2 hours
- **Total:** ~33.5 hours (2-3 days)

**Human Review Time:** 2-3 hours

---

## Success Criteria (Gate to Stage 2.2)

Stage 2.1 is COMPLETE when:
- ✅ All 10 technology decisions made and documented
- ✅ TECH-STACK-001 created (complete map)
- ✅ API-CONTRACTS-001 created (free vs. premium flows)
- ✅ 11 ADRs created (004-014)
- ✅ TEST-STRATEGY-001 created (with Shopping Graph tests)
- ✅ SHOPPING-GRAPH-INTEGRATION-001 created
- ✅ Checkpoint report complete (2-3 open questions)
- ✅ Human review complete
- ✅ APPROVAL to proceed to Stage 2.2

**BLOCKING ISSUES:**
- Missing Google Shopping Graph API specification
- Budget exceeded (AI costs > $1,000/month)

---

## Next Stage Preview: Stage 2.2

**Stage 2.2: iOS Architecture Deep-Dive**
**Persona:** paul-hudson (iOS Architecture Expert)

**Inputs (From Stage 2.1):**
- TECH-STACK-001 (locked: iOS 26, Vision Framework, Shopping Graph)
- API-CONTRACTS-001 (REST endpoints)
- PRD-001 (features)

**Outputs:**
- DESIGN-002: iOS App Architecture (MVVM, Vision integration)
- SwiftUI component hierarchy
- Vision Framework integration pattern
- Shopping Graph API client (iOS)
- Offline-first architecture (Firestore sync)

**Duration:** 2-3 days

---

## Appendix: Technology Decision Matrix

| Decision | Options | Recommendation | Key Rationale | ADR |
|----------|---------|----------------|---------------|-----|
| 1. Client Platform | iOS 16+ / 26+ | iOS 26+ (iPhone 15 Pro+) | Free on-device tier, early adopters | ADR-004 |
| 2. Backend Platform | GCP / AWS / Azure | GCP | Shopping Graph, Firebase | ADR-005 |
| 3. Backend Architecture | Monolith / Microservices | Monolith-first | Small team, fast iteration | ADR-006 |
| 4. API Style | REST / GraphQL | REST + JSON | Simple CRUD, good iOS tooling | ADR-007 |
| 5. Database | Firestore / SQL | Firestore | Offline-first, real-time | ADR-008 |
| 6. Authentication | Firebase / Custom | Firebase Auth | Apple Sign-In, free tier | ADR-009 |
| 7. File Storage | Local / Cloud | Hybrid (local + cloud) | Free tier local, premium cloud | ADR-010 |
| 8. Compute | Functions / App Engine | Cloud Functions | Serverless, Firebase integration | ADR-011 |
| 9. AI/ML Platform | Shopping Graph / Multi-Model AI | Gemini 2.5 Flash-Lite + Shopping Graph + Claude 3.5 Sonnet | 90% margin, frontier accuracy | ADR-015 |
| 10. Observability | GCP / Third-party | GCP + Firebase Analytics | Native integration | ADR-013 |

---

## Conclusion

This revised plan incorporates iOS 26 Vision Framework for on-device object detection (free tier) and Google Shopping Graph for cloud product identification (premium tier).

**Key Architecture:**
```

FREE TIER:
iOS Vision → Detect/Crop → Basic labels → Firestore
Cost: $0

PREMIUM TIER:
iOS Vision → Detect/Crop → Upload → Shopping Graph → Product details → Firestore
Cost: ~$0.007/item
Retry: Silent (6-hour intervals)

```

**Execution readiness:** READY TO BEGIN

**Next Action:** Execute Stage 2.1 using this revised plan.

---

**End of Stage 2.1 Execution Plan (REVISED)**
```

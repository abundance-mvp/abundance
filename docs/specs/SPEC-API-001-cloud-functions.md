# SPEC-API-001: Cloud Functions API

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## 1. Overview

The Abundance MVP backend is powered by Firebase Cloud Functions, providing:

- **AI-powered item cataloging** via Gemini 3 Pro/Flash
- **Capture session processing** with object detection and cropping
- **HTTP endpoints** for item CRUD operations
- **Scheduled maintenance jobs** for cleanup and subscription management
- **Firestore triggers** for event-driven processing

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Cloud Functions                              │
├─────────────────────────────────────────────────────────────────────┤
│  HTTP Endpoints        │  Firestore Triggers        │ Scheduled Jobs│
│  - health              │  - onSessionCreated        │ - cleanupDel. │
│  - createItemHTTP      │  - onItemCreatedGemini3    │ - checkExpiry │
│  - getItemHTTP         │  - onItemFromSession       │               │
│  - listItemsHTTP       │  - onItemDeleted           │               │
│  - getUserProfile      │  - onItemUpdatedDeepScan   │               │
│  - backfillFlatten...  │  - onItemUpdatedRescan     │               │
├─────────────────────────────────────────────────────────────────────┤
│                      Firebase Admin SDK                              │
│                (Firestore, Storage, Auth)                            │
├─────────────────────────────────────────────────────────────────────┤
│                      AI Pipeline (Gemini/Vertex AI)                 │
└─────────────────────────────────────────────────────────────────────┘
```

### Runtime Environment

- **Node.js:** 20
- **Region:** us-central1
- **Functions Version:** Firebase Functions v2 (2nd gen) for triggers/scheduled, v1 for HTTP callable

---

## 2. Deployed Functions Table

| Function | Type | Trigger/Schedule | Description |
|----------|------|------------------|-------------|
| `health` | HTTP Request | GET /health | Health check endpoint (no auth) |
| `getUserProfile` | Callable | N/A | Get authenticated user profile |
| `createItemHTTP` | HTTP Request | POST /createItemHTTP | Create new item with Layer 1 result |
| `getItemHTTP` | HTTP Request | GET /getItemHTTP | Get item by ID |
| `listItemsHTTP` | HTTP Request | GET /listItemsHTTP | List user's items |
| `onSessionCreated` | Firestore Update | sessions/{sessionId} | Layer 1 object detection |
| `onItemCreatedGemini3` | Firestore Create | items/{itemId} | Layer 2 AI cataloging |
| `onItemFromSession` | Firestore Create | items/{itemId} | Catalog session-detected items |
| `onItemUpdatedDeepScan` | Firestore Update | items/{itemId} | Deep scan / refresh with Gemini Pro |
| `onItemUpdatedRescan` | Firestore Update | items/{itemId} | Re-catalog item through standard pipeline |
| `onItemDeleted` | Firestore Delete | items/{itemId} | Storage cleanup on delete |
| `cleanupDeletedItemsScheduled` | Scheduled | Daily 2am UTC | Purge soft-deleted items (90+ days) |
| `checkSubscriptionExpiryScheduled` | Scheduled | Daily 6am UTC | Downgrade expired subscriptions |
| `backfillFlattenedSchema` | Callable | N/A | Migration: flatten catalog schema |

---

## 3. Function Details

### 3.1 Health Check

**Function:** `health`
**File:** `functions/src/index.ts:24-30`

```typescript
export const health = functions.https.onRequest((req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'abundance-backend'
  });
});
```

| Property | Value |
|----------|-------|
| **Type** | HTTP Request (v1) |
| **Auth Required** | No |
| **Method** | GET |
| **Response** | `{ status: 'ok', timestamp: string, service: string }` |

---

### 3.2 Get User Profile

**Function:** `getUserProfile`
**File:** `functions/src/index.ts:33-52`

```typescript
export const getUserProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
  }
  const userId = context.auth.uid;
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  if (!userDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'User profile not found');
  }
  return userDoc.data();
});
```

| Property | Value |
|----------|-------|
| **Type** | Callable (v1) |
| **Auth Required** | Yes (Firebase Auth) |
| **Input** | None |
| **Output** | User document data |
| **Errors** | `unauthenticated`, `not-found` |

---

### 3.3 Create Item HTTP

**Function:** `createItemHTTP`
**File:** `functions/src/index.ts:55-107`

| Property | Value |
|----------|-------|
| **Type** | HTTP Request (v1) |
| **Auth Required** | Yes (Bearer token) |
| **Method** | POST |

**Request Body:**
```typescript
{
  imageUrl: string;        // Required: GCS URL to uploaded image
  layer1Result: {          // Required: Layer 1 detection result
    detectedClass: string;
    confidence: number;
    boundingBox: { x, y, width, height };
  };
  detectedBarcode?: string | null;  // Optional: Detected barcode
}
```

**Response (201):**
```typescript
{
  itemId: string;
  status: 'processing';
  createdAt: string;       // ISO timestamp
  layer1Complete: true;
  layer2aScheduled: true;
  layer2bScheduled: true;
}
```

**Errors:**
- `401`: Missing/invalid Bearer token
- `400`: Missing required fields (imageUrl, layer1Result)
- `500`: Internal server error

---

### 3.4 Get Item HTTP

**Function:** `getItemHTTP`
**File:** `functions/src/index.ts:110-150`

| Property | Value |
|----------|-------|
| **Type** | HTTP Request (v1) |
| **Auth Required** | Yes (Bearer token) |
| **Method** | GET |
| **Query Params** | `itemId` (required) |

**Response (200):**
```typescript
{
  userId: string;
  imageUrl: string;
  status: string;
  createdAt: Timestamp;
  layer1Result?: object;
  detectedBarcode?: string | null;
  // ... additional catalog fields when complete
}
```

**Errors:**
- `401`: Missing/invalid Bearer token
- `400`: Missing itemId query parameter
- `404`: Item not found
- `500`: Internal server error

---

### 3.5 List Items HTTP

**Function:** `listItemsHTTP`
**File:** `functions/src/index.ts:153-179`

| Property | Value |
|----------|-------|
| **Type** | HTTP Request (v1) |
| **Auth Required** | Yes (Bearer token) |
| **Method** | GET |
| **Query Params** | `limit` (optional, default: 20) |

**Response (200):**
```typescript
{
  items: Array<{
    id: string;
    userId: string;
    imageUrl: string;
    status: string;
    createdAt: Timestamp;
    // ... additional fields
  }>;
}
```

---

### 3.6 On Session Created (Layer 1 Detection)

**Function:** `onSessionCreated`
**File:** `functions/src/triggers/onSessionCreated.ts`

| Property | Value |
|----------|-------|
| **Type** | Firestore Update Trigger (v2) |
| **Document Path** | `sessions/{sessionId}` |
| **Region** | us-central1 |
| **Memory** | 1 GiB |
| **Timeout** | Configurable via LAYER1_TIMEOUTS |

**Trigger Condition:**
Fires when:
1. Status changes from `uploading` to `detecting`, OR
2. Status is `uploading` AND `imagesUploaded === expectedImageCount`

**Processing Steps:**
1. Validate session document (userId, originalImageUrls, bucket authorization)
2. Update status to `detecting`
3. Fetch images from GCS temp bucket
4. Call Gemini 3 Flash for object detection (`detectObjectsInImages`)
5. Parse detections and extract bounding boxes
6. Crop objects with Sharp image library
7. Upload crops to permanent GCS bucket
8. Update session with `detectedObjects` array

**Session Document Schema:**
```typescript
type CaptureMode = 'single' | 'burst' | 'sweep';
type SessionStatus = 'uploading' | 'detecting' | 'detected' | 'failed';

interface CaptureSession {
  id: string;
  userId: string;
  captureMode: CaptureMode;
  status: SessionStatus;
  originalImageUrls: string[];
  imagesUploaded?: number;
  expectedImageCount?: number;
  detectedObjects?: Array<{
    groupId: string;
    label: string;
    category: string;
    attributes: Record<string, string>;
    confidence: string;
    croppedImageUrls: string[];
    boundingBoxes: Array<{ imageIndex: number; box_2d: [number, number, number, number] }>;
  }>;
  reasoning?: string;
  error?: string;
  errorCode?: string;
  /** Sweep mode: pre-cropped segments from on-device EdgeTAM */
  sweepCrops?: SweepCropInfo[];
  processingStartedAt?: FirebaseFirestore.Timestamp;
}
```

**Allowed Storage Buckets:**
- `abundance-mvp.firebasestorage.app` (default Firebase Storage bucket)
- `abundance-temp`
- `abundance-dev-temp`
- `abundance-staging-temp`

**Error Codes:**
- `INVALID_DOCUMENT`: Missing userId
- `NO_IMAGES`: Empty originalImageUrls
- `UNAUTHORIZED_BUCKET`: Image URL from unauthorized bucket
- `TIMEOUT`: Processing timeout
- `QUOTA_EXCEEDED`: API quota exceeded
- `INTERNAL_ERROR`: Generic error

---

### 3.7 On Item Created (Gemini 3 Cataloging)

**Function:** `onItemCreatedGemini3`
**File:** `functions/src/triggers/onItemCreatedGemini3.ts`

| Property | Value |
|----------|-------|
| **Type** | Firestore Create Trigger (v2) |
| **Document Path** | `items/{itemId}` |
| **Region** | us-central1 |
| **Memory** | 512 MiB |
| **Timeout** | 120 seconds |
| **Secrets** | `SERPAPI_KEY` |

**Trigger Condition:**
Fires when a new item document is created with `status="pending"`.

**Processing Steps:**
1. Set SERPAPI_KEY environment variable from secret
2. Call `handleItemCreated()` from AI pipeline
3. Gemini 3 Pro performs:
   - Visual analysis
   - Barcode lookup
   - Google Lens search
   - Web search for pricing

**Authentication:**
- Vertex AI: Application Default Credentials (service account)
- SERPAPI_KEY: Required for Google Lens visual search

**Deploy Command:**
```bash
firebase deploy --only functions:onItemCreatedGemini3
```

---

### 3.8 On Item From Session

**Function:** `onItemFromSession`
**File:** `functions/src/triggers/onItemFromSession.ts`

| Property | Value |
|----------|-------|
| **Type** | Firestore Create Trigger (v2) |
| **Document Path** | `items/{itemId}` |
| **Region** | us-central1 |
| **Memory** | 512 MiB |
| **Timeout** | 120 seconds |
| **Secrets** | `SERPAPI_KEY` |

**Trigger Condition:**
Fires when item has:
- `sessionId` field (created from session detection)
- `fromDetection: true`
- `status: 'pending'`

**Processing Steps:**
1. Verify session reference and user ownership
2. Update status to `processing`
3. Call `processItemWithGemini()` for cataloging
4. Validate catalog result with `validateCatalogItem()`
5. Flatten catalog data to top-level fields
6. Update session's `catalogedObjects` map

**Output Fields (Flattened):**
```typescript
{
  status: 'complete';
  name: string;
  category: string;
  subCategory: string;
  brand: string | null;
  model: string | null;
  color: string;
  condition: string;
  dimensions: string | null;
  quantity: number;
  estimatedValue: number | null;
  confidence: string;
  processingNotes: string | null;
  catalog: object;  // Original for backward compatibility
  completedAt: Timestamp;
}
```

---

### 3.9 On Item Deleted

**Function:** `onItemDeleted`
**File:** `functions/src/triggers/onItemDeleted.ts`

| Property | Value |
|----------|-------|
| **Type** | Firestore Delete Trigger (v2) |
| **Document Path** | `items/{itemId}` |

**Processing Steps:**
1. Extract userId and imageUrl from deleted document
2. Delete primary image: `users/{userId}/items/{itemId}.jpg`
3. Delete cropped images (prefix scan): `users/{userId}/items/{itemId}_crop_*.jpg`
4. Delete additional photos (prefix scan): `users/{userId}/items/{itemId}_photo_*.jpg`
5. Delete Live Photo motion clip (if exists): `users/{userId}/items/{itemId}/motion.mov`
6. Log results with counts (deleted, not found, errors)

**Storage Paths Cleaned:**
- `users/{userId}/items/{itemId}.jpg` (primary image)
- `users/{userId}/items/{itemId}_crop_*.jpg` (cropped object images)
- `users/{userId}/items/{itemId}_photo_*.jpg` (additional photos)
- `users/{userId}/items/{itemId}/motion.mov` (optional Live Photo)

---

### 3.10 On Item Updated: Deep Scan / Refresh

**Function:** `onItemUpdatedDeepScan`
**File:** `functions/src/triggers/onItemUpdatedDeepScan.ts`

| Property | Value |
|----------|-------|
| **Type** | Firestore Update Trigger (v2) |
| **Document Path** | `items/{itemId}` |
| **Region** | us-central1 |
| **Memory** | 1 GiB |
| **Timeout** | 180 seconds |
| **Secrets** | `SERPAPI_KEY` |

**Trigger Condition:**
Fires when:
- `deepScanRequested === true`
- `status === 'pending'`
- `before.deepScanRequested !== true` (prevents re-triggering on unrelated updates)

**Processing Steps:**
1. Set SERPAPI_KEY environment variable from secret
2. Resolve image URL from `imageUrl` or `imagePath`
3. Read `additionalImageUrls` if present
4. Call `processItemWithGeminiPersistent()` with context cache enabled
5. Extract deep scan extended fields from result
6. Update item with: `productUrl`, `upcCode`, `marketPriceRange`, `originalRetailPrice`, `deepScanCompletedAt`
7. Also update standard fields (name, dimensions, estimatedValue) if better data found

**Output Fields:**
```typescript
{
  status: 'complete';
  deepScanCompletedAt: Timestamp;
  productUrl: string | null;
  upcCode: string | null;
  marketPriceRange: string | null;
  originalRetailPrice: number | null;
  // Standard fields updated if better data found:
  name?: string;
  dimensions?: string;
  estimatedValue?: number;
}
```

---

### 3.11 On Item Updated: Rescan

**Function:** `onItemUpdatedRescan`
**File:** `functions/src/triggers/onItemUpdatedRescan.ts`

| Property | Value |
|----------|-------|
| **Type** | Firestore Update Trigger (v2) |
| **Document Path** | `items/{itemId}` |
| **Region** | us-central1 |
| **Memory** | 512 MiB |
| **Timeout** | 120 seconds |
| **Secrets** | `SERPAPI_KEY` |

**Trigger Condition:**
Fires when:
- `status === 'pending'`
- `before.status !== 'pending'` (prevents re-triggering)
- `deepScanRequested !== true` (deep scans handled by `onItemUpdatedDeepScan`)

**Processing Steps:**
1. Set SERPAPI_KEY environment variable from secret
2. Call `handleItemCreated()` with the updated document snapshot (same pipeline as initial cataloging)

**Note:** This handles the "Re-catalog" button flow where the user wants to re-process an item through the standard AI pipeline.

---

### 3.12 Cleanup Deleted Items (Scheduled)

**Function:** `cleanupDeletedItemsScheduled`
**File:** `functions/src/scheduled/cleanupDeletedItems.ts`

| Property | Value |
|----------|-------|
| **Type** | Scheduled (v2) |
| **Schedule** | `0 2 * * *` (Daily at 2am UTC) |
| **Timezone** | UTC |

**Processing Steps:**
1. Calculate cutoff date (90 days ago)
2. Query items where `status === 'deleted'` AND `deletedAt < cutoff`
3. Batch delete up to 100 items per execution
4. Log deletion count

**Reference:** ADR-008 (90-day grace period)

---

### 3.13 Check Subscription Expiry (Scheduled)

**Function:** `checkSubscriptionExpiryScheduled`
**File:** `functions/src/scheduled/checkSubscriptionExpiry.ts`

| Property | Value |
|----------|-------|
| **Type** | Scheduled (v2) |
| **Schedule** | `0 6 * * *` (Daily at 6am UTC) |
| **Timezone** | UTC |

**Processing Steps:**
1. Query users where `subscription.tier === 'premium'` AND `subscription.expiresAt < now`
2. Batch update up to 100 users per execution:
   - Set `subscription.tier` to `'free'`
   - Record `subscription.downgradedAt`
   - Store `subscription.previousTier`
3. Log downgrade count

---

### 3.14 Backfill Flattened Schema (Migration)

**Function:** `backfillFlattenedSchema`
**File:** `functions/src/migrations/backfillFlattenedSchema.ts`

| Property | Value |
|----------|-------|
| **Type** | Callable (v1) |
| **Auth Required** | Admin token required |

**Usage:**
```bash
firebase functions:call backfillFlattenedSchema --data '{}'
```

**Processing Steps:**
1. Verify admin authentication via `context.auth.token.admin`
2. Query items with non-null `catalog` field
3. For each item without `name` field (not yet migrated):
   - Flatten catalog fields to top level
   - Update document in batch
4. Process in batches of 100

**Response:**
```typescript
{
  success: true;
  migratedCount: number;
  skippedCount: number;
}
```

---

## 4. HTTP Endpoints Summary

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/health` | GET | None | Health check |
| `/createItemHTTP` | POST | Bearer | Create item |
| `/getItemHTTP` | GET | Bearer | Get item by ID |
| `/listItemsHTTP` | GET | Bearer | List user items |

**Callable Functions:**
| Function | Auth | Description |
|----------|------|-------------|
| `getUserProfile` | Firebase Auth | Get user profile |
| `backfillFlattenedSchema` | Admin only | Schema migration |

---

## 5. Configuration

### 5.1 Region

All functions deploy to **us-central1**.

### 5.2 Memory Allocations

| Function | Memory |
|----------|--------|
| `onSessionCreated` | 1 GiB (Sharp image processing) |
| `onItemCreatedGemini3` | 512 MiB |
| `onItemFromSession` | 512 MiB |
| `onItemUpdatedDeepScan` | 1 GiB |
| `onItemUpdatedRescan` | 512 MiB |
| HTTP endpoints | Default (256 MiB) |
| Scheduled jobs | Default (256 MiB) |

### 5.3 Timeout Settings

| Function | Timeout |
|----------|---------|
| `onItemCreatedGemini3` | 120 seconds |
| `onItemFromSession` | 120 seconds |
| `onItemUpdatedDeepScan` | 180 seconds |
| `onItemUpdatedRescan` | 120 seconds |
| `onSessionCreated` | LAYER1_TIMEOUTS.FUNCTION_TIMEOUT_SECONDS |
| HTTP endpoints | Default (60 seconds) |
| Scheduled jobs | Default (540 seconds) |

### 5.4 Environment Variables / Secrets

| Variable | Type | Usage |
|----------|------|-------|
| `SERPAPI_KEY` | Secret | Google Lens visual search (onItemCreatedGemini3, onItemFromSession, onItemUpdatedDeepScan, onItemUpdatedRescan) |
| `GOOGLE_CLOUD_PROJECT` | Auto-set | Vertex AI project context |
| `GOOGLE_CLOUD_LOCATION` | Auto-set | Defaults to 'global' |

### 5.5 Functions SDK Versions

- **Firestore Triggers:** `firebase-functions/v2/firestore`
- **Scheduler:** `firebase-functions/v2/scheduler`
- **HTTP (legacy):** `firebase-functions/v1`

---

## 6. Dependencies

### 6.1 Runtime Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `@google/genai` | ^1.35.0 | Gemini AI integration |
| `firebase-admin` | ^12.0.0 | Firebase Admin SDK (Firestore, Storage, Auth) |
| `firebase-functions` | ^7.0.3 | Cloud Functions runtime |
| `node-fetch` | ^3.3.2 | HTTP client for external APIs |
| `sharp` | ^0.33.0 | High-performance image processing |

### 6.2 Development Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `@types/jest` | ^30.0.0 | Jest type definitions |
| `@types/node` | ^20.0.0 | Node.js type definitions |
| `@types/node-fetch` | ^2.6.13 | node-fetch types |
| `@types/sharp` | ^0.32.0 | Sharp types |
| `dotenv` | ^16.4.0 | Environment variable loading |
| `jest` | ^30.2.0 | Testing framework |
| `ts-jest` | ^29.4.5 | TypeScript Jest transformer |
| `typescript` | ^5.3.0 | TypeScript compiler |

### 6.3 Node.js Version

```json
{
  "engines": {
    "node": "20"
  }
}
```

---

## 7. Deployment

### Deploy All Functions

```bash
firebase deploy --only functions
```

### Deploy Specific Function

```bash
firebase deploy --only functions:onItemCreatedGemini3
firebase deploy --only functions:onSessionCreated
```

### View Logs

```bash
firebase functions:log
firebase functions:log --only onItemCreatedGemini3
```

### Run Integration Tests

```bash
npm run test:integration
```

---

## 8. Error Handling Patterns

### HTTP Endpoints
```typescript
res.status(401).json({
  error: { code: 'unauthenticated', message: 'User must be signed in' }
});
```

### Callable Functions
```typescript
throw new functions.https.HttpsError('permission-denied', 'Admin access required');
```

### Firestore Triggers
```typescript
await docRef.update({
  status: 'failed',
  error: errorMessage,
  errorCode: 'INTERNAL_ERROR'
});
```

---

## 9. Related Documentation

- **ADR-008:** Soft delete with 90-day grace period
- **AI Pipeline:** `functions/src/ai-pipeline/` - Gemini integration
- **Layer 1 Service:** `functions/src/ai-pipeline/layer1/` - Object detection
- **Gemini Service:** `functions/src/ai-pipeline/gemini/` - Cataloging

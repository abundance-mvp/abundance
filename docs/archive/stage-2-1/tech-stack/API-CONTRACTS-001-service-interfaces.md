# API-CONTRACTS-001: Service Interface Definitions

**Document ID:** API-CONTRACTS-001
**Date:** 2025-10-24
**Status:** APPROVED
**Related Documents:**
- TECH-STACK-001 (Technology Stack Map)
- PRD-001 (Product Requirements)
- ADR-007 (REST API Design)
- ADR-012 (Google Shopping Graph as Primary AI)

---

## Executive Summary

This document defines all API contracts for Abundance MVP Phase 1, including:

1. **Free Tier:** Direct Firestore writes (no backend API calls)
2. **Premium Tier:** Cloud Function APIs for product enrichment
3. **Internal APIs:** Google Shopping Graph integration
4. **Client-Server Communication:** Request/response schemas, error handling

**Key Architectural Principle:** Free tier operates entirely offline-first with direct Firestore writes. Premium tier uses HTTPS callable Cloud Functions for enrichment.

---

## 1. API Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                      iOS CLIENT                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ FREE TIER FLOW:                                        │  │
│  │  1. VNRecognizeObjectsRequest (on-device)             │  │
│  │  2. Crop images                                        │  │
│  │  3. Direct Firestore write (Firebase SDK)             │  │
│  │  4. No API calls                                       │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ PREMIUM TIER FLOW:                                     │  │
│  │  1-2. Same as free tier (detect, crop)                │  │
│  │  3. Upload to Firebase Storage                         │  │
│  │  4. Call Cloud Function: enrichItem()                  │  │
│  │  5. Listen to Firestore real-time update              │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS Callable
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                  CLOUD FUNCTIONS (Backend)                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ enrichItem(itemId, basicLabel, croppedImageUrl)       │  │
│  │   → Call Google Shopping Graph API                     │  │
│  │   → Update Firestore with enriched metadata           │  │
│  │   → Return success/error                               │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ retryFailedEnrichments() [Scheduled, every 6 hours]   │  │
│  │   → Query items where enrichedAt == null              │  │
│  │   → Retry Shopping Graph API                           │  │
│  │   → Silent retry (no user notification)                │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ REST API
                            ▼
┌──────────────────────────────────────────────────────────────┐
│              GOOGLE SHOPPING GRAPH API                       │
│  POST /v1/search                                             │
│    Input: Cropped image URL                                  │
│    Output: Product metadata (brand, model, price)           │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Base Configuration

### Environments

| Environment | Base URL | Purpose |
|-------------|----------|---------|
| **Production** | `https://us-central1-abundance-prod.cloudfunctions.net` | Live production traffic |
| **Staging** | `https://us-central1-abundance-staging.cloudfunctions.net` | Pre-production testing, QA |
| **Development** | `http://localhost:5001` | Local Firebase emulator suite |

### Authentication

All API requests (except anonymous) require Firebase Authentication JWT token:

```http
Authorization: Bearer <firebase-jwt-token>
```

**Token Acquisition (iOS):**
```swift
import FirebaseAuth

let user = Auth.auth().currentUser
user?.getIDToken { token, error in
    guard let token = token else { return }
    // Use token for API requests
    callCloudFunction(token: token)
}
```

**Token Validation (Cloud Functions):**
```javascript
exports.enrichItem = functions.https.onCall(async (data, context) => {
    // context.auth is automatically populated by Firebase
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid;
    // Proceed with request
});
```

---

## 3. FREE TIER API (Direct Firestore)

### Overview

**Key Principle:** Free tier users never call backend APIs. All operations use Firebase iOS SDK with direct Firestore writes.

### 3.1 Create Item (Free Tier)

**Method:** Direct Firestore write (iOS SDK)
**Collection:** `users/{userId}/items`

**iOS Code:**
```swift
import FirebaseFirestore

struct Item: Codable {
    let name: String
    let category: String
    let photoUrl: String  // Local path: "local://photo_123.jpg"
    let tier: String
    let createdAt: Timestamp
}

func catalogItemFree(name: String, category: String, photoUrl: String) async throws {
    let db = Firestore.firestore()
    guard let userId = Auth.auth().currentUser?.uid else {
        throw CatalogError.notAuthenticated
    }

    let item = Item(
        name: name,
        category: category,
        photoUrl: photoUrl,
        tier: "free",
        createdAt: Timestamp(date: Date())
    )

    try await db.collection("users").document(userId).collection("items").addDocument(data: [
        "name": item.name,
        "category": item.category,
        "photoUrl": item.photoUrl,
        "tier": item.tier,
        "createdAt": item.createdAt
    ])
}
```

**Firestore Document Structure:**
```json
{
  "name": "scissors",
  "category": "Office Supplies",
  "photoUrl": "local://photo_abc123.jpg",
  "tier": "free",
  "createdAt": {"seconds": 1698345600, "nanoseconds": 0},
  "brand": null,
  "model": null,
  "estimatedValue": null,
  "enrichedAt": null
}
```

**Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/items/{itemId} {
      // Users can only write their own items
      allow create: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.data.tier == "free";

      allow read: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

### 3.2 Query Items (Free Tier)

**Method:** Direct Firestore query (iOS SDK)

**iOS Code:**
```swift
func fetchItems() async throws -> [Item] {
    let db = Firestore.firestore()
    guard let userId = Auth.auth().currentUser?.uid else {
        throw CatalogError.notAuthenticated
    }

    let snapshot = try await db.collection("users")
        .document(userId)
        .collection("items")
        .order(by: "createdAt", descending: true)
        .limit(to: 50)
        .getDocuments()

    return snapshot.documents.compactMap { doc in
        try? doc.data(as: Item.self)
    }
}
```

**Real-Time Listener:**
```swift
func listenToItems(completion: @escaping ([Item]) -> Void) {
    guard let userId = Auth.auth().currentUser?.uid else { return }

    db.collection("users").document(userId).collection("items")
        .order(by: "createdAt", descending: true)
        .addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            let items = documents.compactMap { try? $0.data(as: Item.self) }
            completion(items)
        }
}
```

---

### 3.3 Update Item (Free Tier)

**Method:** Direct Firestore update (iOS SDK)

**iOS Code:**
```swift
func updateItem(itemId: String, name: String, category: String) async throws {
    guard let userId = Auth.auth().currentUser?.uid else {
        throw CatalogError.notAuthenticated
    }

    try await db.collection("users").document(userId).collection("items").document(itemId).updateData([
        "name": name,
        "category": category
    ])
}
```

---

### 3.4 Delete Item (Free Tier)

**Method:** Direct Firestore delete (iOS SDK)

**iOS Code:**
```swift
func deleteItem(itemId: String) async throws {
    guard let userId = Auth.auth().currentUser?.uid else {
        throw CatalogError.notAuthenticated
    }

    try await db.collection("users").document(userId).collection("items").document(itemId).delete()
}
```

---

## 4. PREMIUM TIER API (Cloud Functions)

### 4.1 Enrich Item (Premium Tier)

**Endpoint:** `enrichItem` (HTTPS callable Cloud Function)
**Method:** POST (Firebase callable)
**Authentication:** Required (Firebase Auth JWT)
**Rate Limit:** 10 requests/minute per user
**Timeout:** 10 seconds

---

#### Request Schema

**Firebase Callable Format:**
```javascript
// iOS call:
functions.httpsCallable("enrichItem").call([
    "itemId": "item_abc123",
    "basicLabel": "scissors",
    "croppedImageUrl": "gs://abundance-prod/users/user123/temp/object_1.jpg"
])
```

**Request Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `itemId` | string | Yes | Firestore document ID | `"item_abc123"` |
| `basicLabel` | string | Yes | On-device Vision label | `"scissors"` |
| `croppedImageUrl` | string | Yes | Firebase Storage path (gs://) | `"gs://abundance-prod/users/{userId}/temp/object_1.jpg"` |

**Validation:**
- `itemId`: Must match `/^[a-zA-Z0-9_-]{10,30}$/` (Firestore auto-generated ID format)
- `basicLabel`: Max 100 characters, alphanumeric + spaces
- `croppedImageUrl`: Must start with `gs://abundance-prod/` (security: prevent SSRF attacks)

---

#### Response Schema (Success)

**HTTP Status:** 200 OK

```json
{
  "data": {
    "success": true,
    "enrichedMetadata": {
      "name": "Scott Fabric Scissors 8-inch",
      "brand": "Scott",
      "model": "8-inch Fabric Scissors",
      "category": "Office Supplies > Scissors",
      "estimatedValue": 12.99,
      "currency": "USD",
      "productUrl": "https://shopping.google.com/product/...",
      "imageUrl": "https://images.google.com/...",
      "confidence": 0.92
    },
    "processingTime": 3.2,
    "cost": 0.007,
    "timestamp": "2026-01-15T10:30:00Z"
  }
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always `true` for successful enrichment |
| `enrichedMetadata` | object | Product details from Shopping Graph |
| `enrichedMetadata.name` | string | Full product name |
| `enrichedMetadata.brand` | string | Brand name (e.g., "Scott") |
| `enrichedMetadata.model` | string | Model/variant (e.g., "8-inch Fabric Scissors") |
| `enrichedMetadata.category` | string | Hierarchical category (e.g., "Office > Scissors") |
| `enrichedMetadata.estimatedValue` | number | Price in USD |
| `enrichedMetadata.currency` | string | ISO 4217 code (e.g., "USD") |
| `enrichedMetadata.productUrl` | string | Google Shopping product page |
| `enrichedMetadata.imageUrl` | string | Product image URL |
| `enrichedMetadata.confidence` | number | 0.0-1.0 (Shopping Graph confidence) |
| `processingTime` | number | Seconds taken for Shopping Graph API call |
| `cost` | number | Estimated cost for this API call (USD) |
| `timestamp` | string | ISO 8601 timestamp |

---

#### Response Schema (Error - Shopping Graph Unavailable)

**HTTP Status:** 200 OK (Firebase callable returns data, not HTTP error)

```json
{
  "data": {
    "success": false,
    "error": {
      "code": "SHOPPING_GRAPH_UNAVAILABLE",
      "message": "Shopping Graph API temporarily unavailable. Will retry automatically in 6 hours.",
      "retryAt": "2026-01-15T16:30:00Z",
      "retryCount": 0
    },
    "fallbackMetadata": {
      "name": "scissors",
      "category": "Office Supplies",
      "tier": "free"
    }
  }
}
```

**Error Codes:**

| Code | HTTP Status | Description | User Action | Retry Strategy |
|------|-------------|-------------|-------------|----------------|
| `SHOPPING_GRAPH_UNAVAILABLE` | 200 | API timeout or 5xx error | None (silent retry) | Cloud Scheduler (6 hours) |
| `SHOPPING_GRAPH_RATE_LIMIT` | 200 | Rate limit exceeded | None (silent retry) | Cloud Scheduler (6 hours) |
| `INVALID_IMAGE_URL` | 200 | Image not found or inaccessible | User re-uploads photo | No retry |
| `SUBSCRIPTION_REQUIRED` | 403 | User not premium subscriber | Prompt upgrade | No retry |
| `UNAUTHENTICATED` | 401 | Missing or invalid JWT | Re-authenticate | No retry |

---

#### iOS Implementation

```swift
import FirebaseFunctions

func enrichItem(itemId: String, basicLabel: String, croppedImageUrl: String) async throws -> EnrichedMetadata {
    let functions = Functions.functions()
    let data: [String: Any] = [
        "itemId": itemId,
        "basicLabel": basicLabel,
        "croppedImageUrl": croppedImageUrl
    ]

    do {
        let result = try await functions.httpsCallable("enrichItem").call(data)
        let response = result.data as! [String: Any]

        if let success = response["success"] as? Bool, success {
            let metadata = response["enrichedMetadata"] as! [String: Any]
            return EnrichedMetadata(
                name: metadata["name"] as! String,
                brand: metadata["brand"] as! String,
                model: metadata["model"] as! String,
                estimatedValue: metadata["estimatedValue"] as! Double,
                productUrl: metadata["productUrl"] as! String,
                confidence: metadata["confidence"] as! Double
            )
        } else {
            // Silent retry (no user-facing error)
            let error = response["error"] as! [String: Any]
            let errorCode = error["code"] as! String
            throw EnrichmentError.shoppingGraphUnavailable(code: errorCode)
        }
    } catch {
        throw EnrichmentError.networkError(error)
    }
}
```

---

#### Cloud Function Implementation

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

exports.enrichItem = functions.https.onCall(async (data, context) => {
    // 1. Authenticate user
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;

    // 2. Validate subscription tier
    const userDoc = await admin.firestore().doc(`users/${userId}`).get();
    if (userDoc.data().subscriptionTier !== 'premium') {
        throw new functions.https.HttpsError('permission-denied', 'Premium subscription required');
    }

    // 3. Validate input
    const { itemId, basicLabel, croppedImageUrl } = data;
    if (!itemId || !basicLabel || !croppedImageUrl) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }

    // 4. Security: Validate image URL (prevent SSRF)
    if (!croppedImageUrl.startsWith('gs://abundance-prod/')) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid image URL');
    }

    // 5. Call Google Shopping Graph API
    try {
        const startTime = Date.now();
        const productData = await callShoppingGraphAPI(croppedImageUrl);
        const processingTime = (Date.now() - startTime) / 1000;

        // 6. Update Firestore with enriched metadata
        await admin.firestore().doc(`users/${userId}/items/${itemId}`).update({
            name: productData.name,
            brand: productData.brand,
            model: productData.model,
            category: productData.category,
            estimatedValue: productData.price.amount,
            currency: productData.price.currency,
            productUrl: productData.productUrl,
            imageUrl: productData.imageUrl,
            confidence: productData.confidence,
            enrichedAt: admin.firestore.FieldValue.serverTimestamp(),
            tier: 'premium'
        });

        // 7. Return success
        return {
            success: true,
            enrichedMetadata: {
                name: productData.name,
                brand: productData.brand,
                model: productData.model,
                category: productData.category,
                estimatedValue: productData.price.amount,
                currency: productData.price.currency,
                productUrl: productData.productUrl,
                imageUrl: productData.imageUrl,
                confidence: productData.confidence
            },
            processingTime: processingTime,
            cost: 0.007,
            timestamp: new Date().toISOString()
        };

    } catch (error) {
        // 8. Shopping Graph API failed - schedule silent retry
        await admin.firestore().doc(`users/${userId}/items/${itemId}`).update({
            enrichmentStatus: 'pending_retry',
            retryCount: admin.firestore.FieldValue.increment(1),
            lastRetryAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return {
            success: false,
            error: {
                code: 'SHOPPING_GRAPH_UNAVAILABLE',
                message: 'Shopping Graph API temporarily unavailable. Will retry automatically in 6 hours.',
                retryAt: new Date(Date.now() + 6 * 60 * 60 * 1000).toISOString(),
                retryCount: 0
            },
            fallbackMetadata: {
                name: basicLabel,
                category: inferCategory(basicLabel),
                tier: 'free'
            }
        };
    }
});

async function callShoppingGraphAPI(imageUrl) {
    // TODO: Replace with actual Shopping Graph API endpoint (TBD in Stage 2.5)
    const response = await axios.post('https://shopping.googleapis.com/v1/search', {
        image: imageUrl,
        language: 'en',
        country: 'US'
    }, {
        headers: {
            'Authorization': `Bearer ${process.env.GOOGLE_SHOPPING_API_KEY}`,
            'Content-Type': 'application/json'
        },
        timeout: 8000  // 8 sec timeout (Cloud Function timeout is 10 sec)
    });

    return response.data.products[0];  // Return top result
}

function inferCategory(label) {
    // Simple category inference (can be improved with ML)
    const categoryMap = {
        'scissors': 'Office Supplies',
        'headphones': 'Electronics',
        'book': 'Books',
        'toy': 'Toys & Games'
    };
    return categoryMap[label.toLowerCase()] || 'Uncategorized';
}
```

---

### 4.2 Retry Failed Enrichments (Scheduled Function)

**Endpoint:** `retryFailedEnrichments` (Pub/Sub triggered)
**Schedule:** Every 6 hours (Cron: `0 */6 * * *`)
**Authentication:** N/A (internal service account)
**Timeout:** 540 seconds (9 minutes - max for scheduled functions)

---

#### Function Purpose

Automatically retry items where Google Shopping Graph API failed (timeout, rate limit, 5xx error). This is a **silent retry** - no user notification.

---

#### Cloud Function Implementation

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.retryFailedEnrichments = functions.pubsub.schedule('0 */6 * * *').onRun(async (context) => {
    console.log('Starting retry job at', new Date().toISOString());

    // 1. Query items where Shopping Graph failed (enrichmentStatus = 'pending_retry')
    const failedItems = await admin.firestore().collectionGroup('items')
        .where('tier', '==', 'premium')
        .where('enrichmentStatus', '==', 'pending_retry')
        .where('retryCount', '<', 3)  // Max 3 retries
        .limit(100)  // Process 100 items per run (prevent timeout)
        .get();

    console.log(`Found ${failedItems.size} items to retry`);

    // 2. Retry Shopping Graph API for each failed item
    const retryPromises = failedItems.docs.map(async (doc) => {
        const itemData = doc.data();
        const croppedImageUrl = itemData.croppedImageUrl;

        try {
            const productData = await callShoppingGraphAPI(croppedImageUrl);

            // Success: Update Firestore with enriched metadata
            await doc.ref.update({
                name: productData.name,
                brand: productData.brand,
                model: productData.model,
                category: productData.category,
                estimatedValue: productData.price.amount,
                currency: productData.price.currency,
                productUrl: productData.productUrl,
                imageUrl: productData.imageUrl,
                confidence: productData.confidence,
                enrichedAt: admin.firestore.FieldValue.serverTimestamp(),
                enrichmentStatus: 'completed',
                retryCount: admin.firestore.FieldValue.increment(1)
            });

            console.log(`Successfully enriched item ${doc.id} on retry ${itemData.retryCount + 1}`);

        } catch (error) {
            // Retry failed again - increment retry count
            await doc.ref.update({
                retryCount: admin.firestore.FieldValue.increment(1),
                lastRetryAt: admin.firestore.FieldValue.serverTimestamp()
            });

            console.error(`Retry failed for item ${doc.id}: ${error.message}`);

            // If max retries reached (3), give up and keep basic label
            if (itemData.retryCount + 1 >= 3) {
                await doc.ref.update({
                    enrichmentStatus: 'failed_permanently',
                    tier: 'free'  // Fallback to free tier (basic label only)
                });
                console.warn(`Item ${doc.id} failed after 3 retries, keeping basic label`);
            }
        }
    });

    await Promise.all(retryPromises);

    console.log('Retry job completed at', new Date().toISOString());
    return null;
});
```

---

#### Firestore Document State Transitions

```
INITIAL STATE (after enrichItem call fails):
{
  "name": "scissors",  // Basic label from on-device Vision
  "tier": "premium",
  "enrichmentStatus": "pending_retry",
  "retryCount": 0,
  "enrichedAt": null
}

AFTER 1ST RETRY SUCCESS:
{
  "name": "Scott Fabric Scissors 8-inch",
  "brand": "Scott",
  "tier": "premium",
  "enrichmentStatus": "completed",
  "retryCount": 1,
  "enrichedAt": "2026-01-15T16:30:00Z"
}

AFTER 3 RETRIES FAILED:
{
  "name": "scissors",  // Keep basic label
  "tier": "free",  // Downgrade to free tier
  "enrichmentStatus": "failed_permanently",
  "retryCount": 3,
  "enrichedAt": null
}
```

---

## 5. GOOGLE SHOPPING GRAPH API (Internal Integration)

### 5.1 Overview

**Status:** TBD (Actual endpoint to be researched in Stage 2.5 - SHOPPING-GRAPH-INTEGRATION-001)

**Assumptions (based on Google Lens architecture analysis):**
- API: `https://shopping.googleapis.com/v1/search` (hypothetical, TBD)
- Authentication: GCP Service Account (OAuth 2.0)
- Rate Limit: TBD (likely 10-100 QPS)
- Cost: ~$0.005-0.010 per image lookup (estimated)

---

### 5.2 Request Schema (Hypothetical)

**Endpoint:** `POST https://shopping.googleapis.com/v1/search`

**Headers:**
```http
Authorization: Bearer <gcp-oauth-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "image": "gs://abundance-prod/users/user123/temp/object_1.jpg",
  "language": "en",
  "country": "US",
  "maxResults": 1,
  "includePrice": true,
  "includeMetadata": true
}
```

---

### 5.3 Response Schema (Hypothetical)

**Success Response:**
```json
{
  "products": [
    {
      "id": "product_abc123",
      "name": "Scott Fabric Scissors 8-inch",
      "brand": "Scott",
      "model": "8-inch Fabric Scissors",
      "category": {
        "path": "Office Supplies > Scissors",
        "id": "office_supplies_scissors"
      },
      "price": {
        "amount": 12.99,
        "currency": "USD"
      },
      "productUrl": "https://shopping.google.com/product/...",
      "imageUrl": "https://images.google.com/...",
      "confidence": 0.92,
      "attributes": {
        "color": "Silver",
        "material": "Stainless Steel",
        "size": "8 inches"
      }
    }
  ],
  "processingTime": 2.8,
  "requestId": "req_xyz789"
}
```

---

### 5.4 Error Responses

**Rate Limit Exceeded:**
```json
{
  "error": {
    "code": 429,
    "message": "Rate limit exceeded. Retry after 60 seconds.",
    "status": "RESOURCE_EXHAUSTED"
  }
}
```

**Image Not Found:**
```json
{
  "error": {
    "code": 404,
    "message": "Image not found or inaccessible.",
    "status": "NOT_FOUND"
  }
}
```

**No Product Match:**
```json
{
  "products": [],
  "message": "No products found matching the provided image."
}
```

---

### 5.5 Authentication (GCP Service Account)

**Service Account Setup:**
1. Create GCP service account: `shopping-graph-api@abundance-prod.iam.gserviceaccount.com`
2. Grant role: `roles/shopping.api.user` (hypothetical, TBD)
3. Download JSON key, store in Firebase Functions config

**Node.js Authentication:**
```javascript
const { GoogleAuth } = require('google-auth-library');

async function getShoppingGraphToken() {
    const auth = new GoogleAuth({
        keyFilename: './service-account-key.json',
        scopes: ['https://www.googleapis.com/auth/shopping']
    });

    const client = await auth.getClient();
    const token = await client.getAccessToken();
    return token.token;
}
```

---

## 6. FIRESTORE SECURITY RULES

### 6.1 Items Collection

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Items subcollection
      match /items/{itemId} {
        // Read: User can only read their own items
        allow read: if request.auth != null && request.auth.uid == userId;

        // Create: User can create items (free tier)
        allow create: if request.auth != null
                      && request.auth.uid == userId
                      && request.resource.data.tier == "free"
                      && request.resource.data.keys().hasAll(['name', 'category', 'tier', 'createdAt']);

        // Update: User can update their own items (manual edit)
        allow update: if request.auth != null
                      && request.auth.uid == userId
                      && request.resource.data.tier == resource.data.tier;  // Can't change tier manually

        // Delete: User can delete their own items
        allow delete: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Cloud Functions can write with admin SDK (bypasses security rules)
  }
}
```

---

### 6.2 Firebase Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // User-specific storage
    match /users/{userId}/{allPaths=**} {
      // Read: User can read their own files
      allow read: if request.auth != null && request.auth.uid == userId;

      // Write: User can upload files (premium tier only, enforced by Cloud Function)
      allow write: if request.auth != null && request.auth.uid == userId;

      // Delete: User can delete their own files
      allow delete: if request.auth != null && request.auth.uid == userId;
    }

    // Cloud Functions can read/write with admin SDK (bypasses security rules)
  }
}
```

---

## 7. ERROR HANDLING & RETRY STRATEGY

### 7.1 Error Handling Matrix

| Error Scenario | HTTP Status | Error Code | User Action | Retry Strategy |
|----------------|-------------|------------|-------------|----------------|
| Shopping Graph timeout (>8 sec) | 200 | `SHOPPING_GRAPH_UNAVAILABLE` | None (silent) | Cloud Scheduler (6 hours, max 3 retries) |
| Shopping Graph rate limit | 200 | `SHOPPING_GRAPH_RATE_LIMIT` | None (silent) | Cloud Scheduler (6 hours, max 3 retries) |
| Shopping Graph 5xx error | 200 | `SHOPPING_GRAPH_UNAVAILABLE` | None (silent) | Cloud Scheduler (6 hours, max 3 retries) |
| Invalid image URL | 200 | `INVALID_IMAGE_URL` | Re-upload photo | No retry |
| User not premium subscriber | 403 | `SUBSCRIPTION_REQUIRED` | Prompt upgrade | No retry |
| Missing Firebase Auth token | 401 | `UNAUTHENTICATED` | Re-authenticate | No retry |
| Firestore write failure | 500 | `INTERNAL_ERROR` | Retry on client | Exponential backoff (iOS SDK) |

---

### 7.2 Retry Strategy (Silent Retry)

**Key Principle:** Never show errors to users. Always retry silently in the background.

**Workflow:**
1. **Initial Call Fails:** Return basic label ("scissors") to user immediately
2. **Schedule Retry:** Cloud Scheduler runs every 6 hours
3. **Retry Up to 3 Times:** If all 3 retries fail, keep basic label permanently
4. **Success After Retry:** Update Firestore → iOS app real-time listener updates UI

**iOS Real-Time Update (No User Action Required):**
```swift
// User sees basic label immediately
func listenToItemEnrichment(itemId: String) {
    db.collection("users").document(userId).collection("items").document(itemId)
        .addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data() else { return }

            if data["enrichedAt"] != nil {
                // Item was enriched after retry - update UI
                let enrichedName = data["name"] as! String
                self.updateItemUI(itemId: itemId, name: enrichedName)
            }
        }
}
```

---

## 8. RATE LIMITING

### 8.1 Cloud Functions Rate Limits

| Function | Rate Limit | Enforcement | Reasoning |
|----------|------------|-------------|-----------|
| `enrichItem` | 10 calls/min per user | Firebase Functions (custom middleware) | Prevent abuse, Shopping Graph API has rate limits |
| `retryFailedEnrichments` | 1 call per 6 hours | Cloud Scheduler | Scheduled function, no user-facing rate limit |

**Rate Limit Middleware (Cloud Functions):**
```javascript
const rateLimit = require('express-rate-limit');

const enrichItemLimiter = rateLimit({
    windowMs: 60 * 1000,  // 1 minute
    max: 10,  // 10 requests per minute
    keyGenerator: (req) => req.auth.uid,  // Per-user rate limit
    handler: (req, res) => {
        throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded. Try again in 1 minute.');
    }
});

exports.enrichItem = functions.https.onCall(enrichItemLimiter, async (data, context) => {
    // ... (enrichment logic)
});
```

---

### 8.2 Shopping Graph API Rate Limits

**Status:** TBD (to be researched in SHOPPING-GRAPH-INTEGRATION-001)

**Assumptions:**
- Rate Limit: 10-100 QPS (queries per second)
- Daily Quota: 100,000-1,000,000 API calls/day
- Enforcement: HTTP 429 (Rate Limit Exceeded)

**If Rate Limit Hit:**
- Cloud Function catches 429 error
- Returns `SHOPPING_GRAPH_RATE_LIMIT` error code
- Cloud Scheduler retries in 6 hours

---

## 9. API VERSIONING

### 9.1 Versioning Strategy

**Current Version:** v1
**Base URL:** `https://us-central1-abundance-prod.cloudfunctions.net/api/v1`

**Versioning Approach:**
- Major version in URL path (`/api/v1`, `/api/v2`)
- Breaking changes require new major version
- Non-breaking changes (new optional fields) can be added to existing version

**Breaking Changes (Require New Version):**
- Removing fields from response
- Changing field types (e.g., `string` → `number`)
- Renaming fields
- Changing authentication method

**Non-Breaking Changes (Can Be Added to v1):**
- Adding optional request parameters
- Adding new response fields
- New error codes
- Performance improvements

---

### 9.2 Deprecation Policy

**Timeline:**
- **Announce Deprecation:** 6 months before sunset
- **Parallel Support:** New version (v2) and old version (v1) run simultaneously for 6 months
- **Sunset:** v1 APIs return HTTP 410 (Gone) after 6 months

**Example Deprecation Header:**
```http
X-API-Deprecated: true
X-API-Sunset-Date: 2027-01-15
X-API-Migration-Guide: https://docs.abundance.app/api/v1-to-v2
```

---

## 10. MONITORING & OBSERVABILITY

### 10.1 Cloud Function Metrics

**Metrics to Track:**

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| `enrichItem` success rate | >95% | <90% (alert) |
| `enrichItem` latency (p95) | <5 sec | >8 sec (alert) |
| Shopping Graph API errors | <5% | >10% (alert) |
| Retry success rate | >80% | <60% (alert) |
| Function invocations/day | <10,000 | >50,000 (cost alert) |

**Cloud Monitoring Dashboard:**
- `enrichItem` invocations per hour (line chart)
- Shopping Graph success vs. error rate (stacked bar chart)
- Retry job results (pie chart: success, failed, permanently failed)
- Cost per day (Shopping Graph API cost)

---

### 10.2 Logging Strategy

**Log Levels:**
- **ERROR:** Shopping Graph API failures, authentication errors, Firestore write failures
- **WARN:** Retry attempts (1st, 2nd, 3rd), low confidence detections (<0.7)
- **INFO:** Successful enrichments, user subscription changes
- **DEBUG:** Request/response payloads (staging only, never in production)

**Structured Logging Example:**
```javascript
console.log(JSON.stringify({
    level: 'INFO',
    message: 'Item enriched successfully',
    userId: userId,
    itemId: itemId,
    productName: productData.name,
    confidence: productData.confidence,
    processingTime: 3.2,
    cost: 0.007,
    timestamp: new Date().toISOString()
}));
```

---

## 11. TESTING STRATEGY

### 11.1 API Testing

**Unit Tests:**
- `enrichItem` function logic (mocked Shopping Graph API)
- `retryFailedEnrichments` query logic
- Error handling (timeout, rate limit, invalid image)

**Integration Tests:**
- End-to-end: iOS app → Cloud Function → Firestore update
- Shopping Graph API integration (real API calls, staging environment)
- Real-time listener updates (Firestore → iOS app)

**Load Tests:**
- 100 concurrent `enrichItem` calls (simulate 100 premium users cataloging items simultaneously)
- Shopping Graph API rate limit handling (trigger 429 error)

---

### 11.2 Test Data

**Mock Shopping Graph Responses:**
```json
// Test case: Scissors (high confidence)
{
  "products": [{
    "name": "Scott Fabric Scissors 8-inch",
    "brand": "Scott",
    "confidence": 0.92
  }]
}

// Test case: Ambiguous item (low confidence)
{
  "products": [{
    "name": "Generic Scissors",
    "brand": "Unknown",
    "confidence": 0.65
  }]
}

// Test case: No match
{
  "products": []
}
```

---

## 12. OPEN QUESTIONS (TBD in Stage 2.5)

### Question 1: Google Shopping Graph API Endpoint

**Status:** TBD (SHOPPING-GRAPH-INTEGRATION-001 research)

**Questions:**
1. What is the actual API endpoint? (Vertex AI wrapper vs. direct Shopping Graph API)
2. Authentication method? (Service Account OAuth vs. API key)
3. Request/response schema? (Hypothetical schema above needs validation)
4. Rate limits? (QPS, daily quota)
5. Pricing? (~$0.007/image estimated, needs confirmation)

---

### Question 2: Shopping Graph Confidence Threshold

**Question:** What confidence score (0.0-1.0) should we use to filter low-quality results?

**Options:**
- **0.7:** More results, lower accuracy (some generic labels like "Generic Scissors")
- **0.8:** Balanced (recommended)
- **0.9:** High accuracy, fewer results (may miss valid products)

**Recommendation:** Start with 0.8, A/B test after Month 3.

---

### Question 3: Image Lifecycle (Retention vs. Deletion)

**Question:** Should we keep cropped images in Firebase Storage after enrichment, or delete them?

**Options:**
- **Delete After 7 Days:** Lower storage costs ($0.29/month → $0.05/month)
- **Keep Indefinitely:** User can re-run enrichment if unsatisfied with results

**Recommendation:** Delete after 30 days (user can re-upload if needed).

---

## 13. CHANGE LOG

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-10-24 | Initial API contract definition | Stage 2.1 Execution |

---

## Appendix A: API Quick Reference

### Free Tier (Direct Firestore)
```swift
// Create item
db.collection("users/{userId}/items").addDocument(data: [...])

// Query items
db.collection("users/{userId}/items").order(by: "createdAt").getDocuments()

// Update item
db.collection("users/{userId}/items/{itemId}").updateData([...])

// Delete item
db.collection("users/{userId}/items/{itemId}").delete()
```

### Premium Tier (Cloud Functions)
```swift
// Enrich item
functions.httpsCallable("enrichItem").call([
    "itemId": "item_abc123",
    "basicLabel": "scissors",
    "croppedImageUrl": "gs://..."
])
```

---

**Related Documents:**
- TECH-STACK-001: Complete Technology Stack Map
- ADR-007: REST API Design
- ADR-012: Google Shopping Graph as Primary AI
- TEST-STRATEGY-001: Test Pyramid (to be created)
- SHOPPING-GRAPH-INTEGRATION-001: Shopping Graph API Research (to be created)

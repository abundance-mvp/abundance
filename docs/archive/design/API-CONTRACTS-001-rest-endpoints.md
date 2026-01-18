# API-CONTRACTS-001: REST API Endpoint Specifications

**Created**: 2025-11-08
**Stage**: 2.1 - Technology Selection & Stack Mapping
**Status**: Approved
**References**:
- docs/adr/ADR-007-api-architecture.md (REST API decision)
- docs/design/DESIGN-004-computer-vision-pipeline.md (4-layer pipeline)
- docs/adr/ADR-005-authentication-strategy.md (Firebase Auth tokens)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Overview

This document defines the complete REST API contract for Abundance MVP (Phase 1). All endpoints follow RESTful conventions and OpenAPI 3.0 specification.

**Base URL**: `https://us-central1-abundance-prod.cloudfunctions.net`

**API Version**: v1

**Authentication**: Firebase ID tokens (Bearer token in `Authorization` header)

**Response Format**: JSON (`Content-Type: application/json`)

---

## Authentication

All endpoints require Firebase Authentication (except health check).

**Request Header**:
```http
Authorization: Bearer <firebase-id-token>
```

**How to get Firebase ID token** (iOS Swift):
```swift
let token = try await Auth.auth().currentUser?.getIDToken()
```

**Error Response** (401 Unauthorized):
```json
{
  "error": {
    "code": "unauthenticated",
    "message": "User must be signed in",
    "details": {}
  }
}
```

---

## Endpoints

### 1. Health Check

**Endpoint**: `GET /api/v1/health`

**Purpose**: Verify API is operational (used by monitoring tools).

**Authentication**: None

**Request**: None

**Response** (200 OK):
```json
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "2025-11-08T12:00:00Z"
}
```

**Curl Example**:
```bash
curl -X GET https://us-central1-abundance-prod.cloudfunctions.net/api/v1/health
```

---

### 2. Create Item (Upload Cropped Object)

**Endpoint**: `POST /api/v1/items`

**Purpose**: Create new catalog item after iOS app performs Layer 1 (on-device object detection).

**Authentication**: Required (Firebase ID token)

**Request Body**:
```json
{
  "imageUrl": "https://storage.googleapis.com/abundance-prod-images/items/user_abc/item_123_cropped.jpg",
  "layer1Result": {
    "detectedClass": "tent",
    "confidence": 0.87,
    "boundingBox": {
      "x": 100,
      "y": 200,
      "width": 300,
      "height": 400
    }
  },
  "detectedBarcode": "012345678912" // Optional, null if no barcode
}
```

**Response** (201 Created):
```json
{
  "itemId": "item_12345",
  "status": "processing",
  "createdAt": "2025-11-08T12:00:00Z",
  "layer1Complete": true,
  "layer2aScheduled": true,
  "layer2bScheduled": true
}
```

**Error Responses**:
- `400 Bad Request`: Missing required fields (imageUrl, layer1Result)
- `401 Unauthorized`: Invalid or missing Firebase token
- `413 Payload Too Large`: Image URL points to file > 10 MB

**Curl Example**:
```bash
curl -X POST https://us-central1-abundance-prod.cloudfunctions.net/api/v1/items \
  -H "Authorization: Bearer $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "imageUrl": "https://storage.googleapis.com/.../item_123.jpg",
    "layer1Result": {
      "detectedClass": "tent",
      "confidence": 0.87,
      "boundingBox": { "x": 100, "y": 200, "width": 300, "height": 400 }
    },
    "detectedBarcode": null
  }'
```

**Cloud Function Flow**:
1. Verify Firebase auth token → extract `userId`
2. Validate `imageUrl` points to GCS bucket (user owns file)
3. Create Firestore document: `items/{itemId}` with status "processing"
4. Trigger Layer 2a Cloud Function (extract attributes)
5. Trigger Layer 2b Cloud Function (identify product)
6. Return `itemId` and status

---

### 3. Get Item

**Endpoint**: `GET /api/v1/items/:itemId`

**Purpose**: Retrieve catalog item metadata (iOS app displays in catalog list).

**Authentication**: Required (Firebase ID token)

**Path Parameters**:
- `itemId` (string): Firestore document ID (e.g., "item_12345")

**Response** (200 OK):
```json
{
  "itemId": "item_12345",
  "userId": "user_abc",
  "name": "Coleman Evanston 8-Person Tent",
  "category": "camping",
  "imageUrl": "https://storage.googleapis.com/.../item_123_cropped.jpg",
  "metadata": {
    "color": "green",
    "material": "polyester",
    "condition": "good",
    "brand": "Coleman",
    "model": "Evanston 8-Person"
  },
  "aiAnalysis": {
    "layer1": {
      "detectedClass": "tent",
      "confidence": 0.87
    },
    "layer2a": {
      "color": "green",
      "material": "polyester",
      "condition": "good",
      "category": "camping"
    },
    "layer2b": {
      "productName": "Coleman Evanston 8-Person Tent",
      "barcode": null,
      "source": "visual",
      "confidence": 0.92
    },
    "layer3": {
      "estimatedValue": 249.99,
      "confidence": "high",
      "reasoning": "Brand: Coleman (premium camping brand). Model: Evanston 8-Person (large family tent). Condition: good. Market value: $249.99 (based on similar listings)."
    }
  },
  "status": "complete",
  "createdAt": "2025-11-08T12:00:00Z",
  "updatedAt": "2025-11-08T12:05:00Z"
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing Firebase token
- `403 Forbidden`: User does not own item (userId mismatch)
- `404 Not Found`: Item does not exist

**Curl Example**:
```bash
curl -X GET https://us-central1-abundance-prod.cloudfunctions.net/api/v1/items/item_12345 \
  -H "Authorization: Bearer $FIREBASE_TOKEN"
```

**Cloud Function Flow**:
1. Verify Firebase auth token → extract `userId`
2. Read Firestore document: `items/{itemId}`
3. Verify `doc.data().userId == userId` (row-level security)
4. Return item data

---

### 4. List Items (User's Catalog)

**Endpoint**: `GET /api/v1/items`

**Purpose**: Retrieve all items in user's catalog (iOS app displays catalog list).

**Authentication**: Required (Firebase ID token)

**Query Parameters**:
- `limit` (integer, optional): Max items to return (default: 50, max: 100)
- `offset` (integer, optional): Skip N items for pagination (default: 0)
- `category` (string, optional): Filter by category (e.g., "camping", "electronics")
- `sort` (string, optional): Sort order ("createdAt", "updatedAt", "name", default: "createdAt")

**Response** (200 OK):
```json
{
  "items": [
    {
      "itemId": "item_12345",
      "name": "Coleman Evanston Tent",
      "category": "camping",
      "imageUrl": "https://...",
      "status": "complete",
      "createdAt": "2025-11-08T12:00:00Z"
    },
    {
      "itemId": "item_12346",
      "name": "Osprey Atmos 65L Backpack",
      "category": "outdoor",
      "imageUrl": "https://...",
      "status": "processing",
      "createdAt": "2025-11-08T11:00:00Z"
    }
  ],
  "total": 125,
  "limit": 50,
  "offset": 0,
  "hasMore": true
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing Firebase token
- `400 Bad Request`: Invalid query parameters (e.g., limit > 100)

**Curl Example**:
```bash
curl -X GET "https://us-central1-abundance-prod.cloudfunctions.net/api/v1/items?limit=10&category=camping" \
  -H "Authorization: Bearer $FIREBASE_TOKEN"
```

**Cloud Function Flow**:
1. Verify Firebase auth token → extract `userId`
2. Query Firestore: `items` collection where `userId == userId`
3. Apply filters (category, limit, offset)
4. Sort by specified field (default: createdAt descending)
5. Return items array + pagination metadata

**Note**: iOS app should use Firestore Realtime Listeners for live updates (not polling this endpoint). This endpoint is for initial load only.

---

### 5. Update Item

**Endpoint**: `PUT /api/v1/items/:itemId`

**Purpose**: Update item metadata (user edits name, category, condition manually).

**Authentication**: Required (Firebase ID token)

**Path Parameters**:
- `itemId` (string): Firestore document ID

**Request Body** (partial update):
```json
{
  "name": "Coleman Evanston 8-Person Tent (Updated)",
  "category": "camping",
  "metadata": {
    "condition": "excellent" // User manually corrected AI-detected condition
  }
}
```

**Response** (200 OK):
```json
{
  "itemId": "item_12345",
  "name": "Coleman Evanston 8-Person Tent (Updated)",
  "category": "camping",
  "metadata": {
    "color": "green",
    "material": "polyester",
    "condition": "excellent", // Updated
    "brand": "Coleman",
    "model": "Evanston 8-Person"
  },
  "updatedAt": "2025-11-08T12:10:00Z"
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing Firebase token
- `403 Forbidden`: User does not own item
- `404 Not Found`: Item does not exist
- `400 Bad Request`: Invalid field values (e.g., category not in allowed list)

**Curl Example**:
```bash
curl -X PUT https://us-central1-abundance-prod.cloudfunctions.net/api/v1/items/item_12345 \
  -H "Authorization: Bearer $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": { "condition": "excellent" }
  }'
```

**Cloud Function Flow**:
1. Verify Firebase auth token → extract `userId`
2. Read Firestore document: `items/{itemId}`
3. Verify `doc.data().userId == userId`
4. Merge update fields (partial update, don't overwrite entire doc)
5. Set `updatedAt` timestamp
6. Return updated item

---

### 6. Delete Item

**Endpoint**: `DELETE /api/v1/items/:itemId`

**Purpose**: Soft delete item from catalog (user removes item).

**Authentication**: Required (Firebase ID token)

**Path Parameters**:
- `itemId` (string): Firestore document ID

**Response** (204 No Content):
```
(Empty body)
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing Firebase token
- `403 Forbidden`: User does not own item
- `404 Not Found`: Item does not exist

**Curl Example**:
```bash
curl -X DELETE https://us-central1-abundance-prod.cloudfunctions.net/api/v1/items/item_12345 \
  -H "Authorization: Bearer $FIREBASE_TOKEN"
```

**Cloud Function Flow**:
1. Verify Firebase auth token → extract `userId`
2. Read Firestore document: `items/{itemId}`
3. Verify `doc.data().userId == userId`
4. Soft delete: Set `deletedAt` timestamp, `status = "deleted"` (don't physically delete doc)
5. Trigger GCS lifecycle rule: Set `customTime` on image file (auto-delete in 90 days)
6. Return 204 No Content

**Note**: Soft delete allows 90-day grace period (user can restore item, future feature).

---

### 7. Get User Profile

**Endpoint**: `GET /api/v1/users/:userId`

**Purpose**: Retrieve user profile (subscription status, preferences).

**Authentication**: Required (Firebase ID token)

**Path Parameters**:
- `userId` (string): Firebase user ID

**Response** (200 OK):
```json
{
  "userId": "user_abc",
  "email": "user@example.com", // Null if user hid email via Apple Sign-In
  "displayName": "John Doe",
  "subscriptionStatus": "premium", // "free" or "premium"
  "subscriptionExpiresAt": "2025-12-08T12:00:00Z", // Null if free tier
  "catalogItemCount": 125,
  "createdAt": "2025-10-01T12:00:00Z"
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing Firebase token
- `403 Forbidden`: User can only access own profile (userId mismatch)

**Curl Example**:
```bash
curl -X GET https://us-central1-abundance-prod.cloudfunctions.net/api/v1/users/user_abc \
  -H "Authorization: Bearer $FIREBASE_TOKEN"
```

**Cloud Function Flow**:
1. Verify Firebase auth token → extract `userId`
2. Verify path `userId == token.userId` (users can't access other profiles)
3. Read Firestore document: `users/{userId}`
4. Return user profile

---

### 8. Stripe Webhook (Subscription Lifecycle)

**Endpoint**: `POST /api/v1/subscriptions/webhook`

**Purpose**: Handle Stripe subscription events (created, renewed, canceled).

**Authentication**: Stripe signature verification (not Firebase token)

**Request Headers**:
- `Stripe-Signature`: HMAC signature (Stripe webhook secret)

**Request Body** (Stripe event JSON):
```json
{
  "type": "customer.subscription.created",
  "data": {
    "object": {
      "id": "sub_123",
      "customer": "cus_abc",
      "status": "active",
      "metadata": {
        "userId": "user_abc"
      }
    }
  }
}
```

**Response** (200 OK):
```json
{
  "received": true
}
```

**Error Responses**:
- `400 Bad Request`: Invalid Stripe signature
- `500 Internal Server Error`: Failed to update Firestore

**Curl Example** (Stripe sends this, not iOS app):
```bash
curl -X POST https://us-central1-abundance-prod.cloudfunctions.net/api/v1/subscriptions/webhook \
  -H "Stripe-Signature: t=...,v1=..." \
  -H "Content-Type: application/json" \
  -d '{...stripe event JSON...}'
```

**Cloud Function Flow**:
1. Verify Stripe signature (prevent spoofed webhooks)
2. Parse event type (`customer.subscription.created`, `customer.subscription.deleted`, etc.)
3. Extract `userId` from `metadata` field
4. Update Firestore `users/{userId}` → `subscriptionStatus = "premium"` or "free"
5. Set Firebase Auth custom claim: `admin.auth().setCustomUserClaims(userId, { premium: true })`
6. Return 200 OK (Stripe retries if not 2xx)

**Event Types Handled**:
- `customer.subscription.created`: User subscribed → Set premium status
- `customer.subscription.updated`: Subscription renewed → Update expiration date
- `customer.subscription.deleted`: User canceled → Revert to free tier

---

## Error Handling

### Standard Error Response Format

All errors return JSON with this structure:
```json
{
  "error": {
    "code": "error_code",
    "message": "Human-readable error message",
    "details": {
      "field": "specific error details"
    }
  }
}
```

### HTTP Status Codes

| Status Code | Meaning | Example |
|-------------|---------|---------|
| **200 OK** | Success (read operations) | GET /items/:id |
| **201 Created** | Success (item created) | POST /items |
| **204 No Content** | Success (no response body) | DELETE /items/:id |
| **400 Bad Request** | Invalid input | Missing required field |
| **401 Unauthorized** | Invalid/missing auth token | No Authorization header |
| **403 Forbidden** | User doesn't own resource | User tries to access other user's item |
| **404 Not Found** | Resource doesn't exist | GET /items/nonexistent_id |
| **413 Payload Too Large** | Image > 10 MB | POST /items with huge image |
| **500 Internal Server Error** | Server error | Firestore write failed |
| **503 Service Unavailable** | AI API down | SerpAPI timeout |

### Error Code Reference

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `unauthenticated` | 401 | Missing or invalid Firebase token |
| `permission_denied` | 403 | User doesn't own resource |
| `not_found` | 404 | Resource doesn't exist |
| `invalid_argument` | 400 | Invalid request parameters |
| `resource_exhausted` | 429 | Rate limit exceeded (future) |
| `internal` | 500 | Server error |
| `unavailable` | 503 | Third-party API down |

---

## Rate Limiting (Future)

**Not implemented in Phase 1 MVP**, but planned for Phase 2:

- **Free tier**: 10 catalog items/day, 100 API calls/day
- **Premium tier**: Unlimited catalog items, 10,000 API calls/day

**Response Headers** (future):
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1699459200
```

**Error Response** (429 Too Many Requests):
```json
{
  "error": {
    "code": "resource_exhausted",
    "message": "Rate limit exceeded. Upgrade to premium for unlimited cataloging.",
    "details": {
      "limit": 10,
      "resetAt": "2025-11-09T00:00:00Z"
    }
  }
}
```

---

## OpenAPI 3.0 Specification

**Full OpenAPI spec** (for Postman, Swagger UI):

```yaml
openapi: 3.0.0
info:
  title: Abundance API
  version: 1.0.0
  description: REST API for Abundance catalog management

servers:
  - url: https://us-central1-abundance-prod.cloudfunctions.net/api/v1

components:
  securitySchemes:
    FirebaseAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - FirebaseAuth: []

paths:
  /health:
    get:
      summary: Health check
      security: []
      responses:
        '200':
          description: API is healthy

  /items:
    post:
      summary: Create catalog item
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                imageUrl:
                  type: string
                layer1Result:
                  type: object
                detectedBarcode:
                  type: string
                  nullable: true
      responses:
        '201':
          description: Item created

    get:
      summary: List user's catalog items
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            default: 50
        - name: offset
          in: query
          schema:
            type: integer
            default: 0
      responses:
        '200':
          description: List of items

  /items/{itemId}:
    get:
      summary: Get item by ID
      parameters:
        - name: itemId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Item details
        '404':
          description: Item not found

    put:
      summary: Update item
      parameters:
        - name: itemId
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: Item updated

    delete:
      summary: Delete item
      parameters:
        - name: itemId
          in: path
          required: true
          schema:
            type: string
      responses:
        '204':
          description: Item deleted
```

---

## Acceptance Criteria

- [x] ✅ All CRUD endpoints defined (Create, Read, Update, Delete items)
- [x] ✅ Authentication contract specified (Firebase ID tokens)
- [x] ✅ Error handling standardized (HTTP status codes + error JSON)
- [x] ✅ OpenAPI 3.0 spec created (Postman/Swagger compatible)
- [x] ✅ Stripe webhook contract defined (subscription lifecycle)
- [x] ✅ iOS URLSession integration examples provided

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial API contract, all endpoints specified | Software Architecture Expert |

---

**These API contracts support the 4-layer AI pipeline (DESIGN-004), REST API architecture (ADR-007), and Firebase authentication (ADR-005).**

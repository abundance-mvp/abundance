# ADR-007: API Architecture

**Status**: Approved
**Date**: 2025-11-08
**Decision Makers**: Engineering Leadership, Backend Developer, iOS Developer
**Related Documents**:
- docs/adr/ADR-002-platform-strategy.md (GCP/Firebase platform)
- docs/design/DESIGN-004-computer-vision-pipeline.md (AI pipeline architecture)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Context

Abundance needs an API layer for:
- **iOS app → Backend communication**: Catalog CRUD operations, AI pipeline triggers
- **AI pipeline orchestration**: Coordinate Layer 2/3 cloud AI (Gemini, SerpAPI, Claude)
- **Webhook handling**: Stripe subscription lifecycle events (Phase 2)
- **Future PWA support**: Phase 2 web app uses same API as iOS app

**Requirements**:
- Simple iOS integration (URLSession, no GraphQL client)
- Serverless (auto-scale, pay-per-use, no server management)
- GCP platform (ADR-002): Native Firebase/GCP integration
- Cost-efficient (low invocation cost for free tier users)

---

## Decision

**Use REST API with Cloud Functions (HTTP triggers) for all backend endpoints.**

### Specifications

- **Architecture**: RESTful API (nouns + HTTP verbs: GET, POST, PUT, DELETE)
- **Compute**: Cloud Functions (2nd gen, Node.js 20 runtime)
- **Authentication**: Firebase ID tokens (Bearer token in `Authorization` header)
- **Response Format**: JSON (Content-Type: `application/json`)
- **API Versioning**: URL-based versioning (`/api/v1/...`)
- **OpenAPI Specification**: API-CONTRACTS-001 (full endpoint documentation)

---

## Rationale

### 1. Simple iOS Integration (No GraphQL Client)

**Requirement**: iOS app should use native `URLSession` (no third-party GraphQL dependencies).

**Solution**: REST API with standard HTTP methods (GET, POST, PUT, DELETE).

**iOS Example** (Swift):
```swift
struct APIClient {
    func analyzeItem(image: UIImage) async throws -> AnalysisResult {
        let url = URL(string: "https://us-central1-abundance-prod.cloudfunctions.net/analyzeItem")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(try await getFirebaseToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["imageUrl": uploadedImageUrl, "userId": userId]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(AnalysisResult.self, from: data)
    }
}
```

**Benefits**:
- **Zero dependencies**: No Apollo Client, no Relay, no code generation
- **Type-safe**: Swift `Codable` for JSON serialization
- **Familiar**: Standard HTTP patterns (every iOS dev knows URLSession)

**Outcome**: iOS developer can integrate API in < 1 day (vs 2-3 days for GraphQL setup).

---

### 2. Cloud Functions Auto-Scale (Serverless)

**Requirement**: Backend should scale automatically (no manual server provisioning).

**Solution**: Cloud Functions (2nd gen) auto-scale from 0 to 1,000+ concurrent instances.

**How it works**:
1. iOS app sends POST `/api/v1/items/analyze` → Cloud Function triggered
2. GCP spawns new Cloud Function instance (cold start: 200-500ms)
3. Subsequent requests use warm instances (latency: 50-100ms)
4. No traffic → Functions scale to zero (no cost)

**Cost Model**:
- **Invocations**: $0.40 per million (free tier: 2M/month)
- **Compute time**: $0.0000025/GB-second (free tier: 400K GB-seconds)

**Month 6 Projection** (5,000 users, 250K items cataloged):
- API calls: 250K items × 2 API calls/item (analyze + synthesize) = **500K invocations**
- Cost: 500K / 1M × $0.40 = **$0.20/month** (negligible)

**Outcome**: Serverless backend scales automatically, $0.20/month cost vs $50/month for dedicated server.

---

### 3. AI Pipeline Orchestration (Functions Map to Layers)

**Requirement**: Backend must coordinate 4-layer AI pipeline (DESIGN-004).

**Solution**: Each AI layer maps to a Cloud Function endpoint.

**Endpoint Design**:

| Endpoint | Layer | Purpose | AI APIs Called |
|----------|-------|---------|----------------|
| `POST /api/v1/items/analyze` | Layer 1 | Upload cropped object, trigger on-device analysis result | None (iOS-only) |
| `POST /api/v1/items/extract-attributes` | Layer 2a | Extract color, material, condition | Vertex AI Gemini |
| `POST /api/v1/items/identify-product` | Layer 2b | Barcode lookup or visual search | UPCitemdb or SerpAPI + Claude Haiku |
| `POST /api/v1/items/synthesize` | Layer 3 | Conflict resolution, final metadata | Claude Sonnet Batch |

**Example** (Cloud Function for Layer 2b):
```javascript
const functions = require('firebase-functions');
const { callUPCitemdb, callSerpAPI, callClaudeHaiku } = require('./ai-clients');

exports.identifyProduct = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
    }

    const { barcode, imageUrl } = data;

    // Try barcode first (Layer 2b dual-mode strategy per ADR-018)
    if (barcode) {
        const product = await callUPCitemdb(barcode);
        if (product) return { source: 'barcode', product };
    }

    // Fallback to visual search
    const serpResults = await callSerpAPI(imageUrl);
    const parsedProduct = await callClaudeHaiku(serpResults);
    return { source: 'visual', product: parsedProduct };
});
```

**Outcome**: Clean separation of concerns, each function handles one AI layer.

---

### 4. GCP Integration (Cloud Functions Native to Firebase)

**Requirement** (ADR-002): GCP platform for backend.

**Solution**: Cloud Functions are native to Firebase ecosystem.

**Integration Points**:
- **Firebase Auth**: `context.auth` auto-populated with user ID
- **Firestore**: Direct access via `admin.firestore()`
- **Cloud Storage**: Direct access via `admin.storage()`
- **Secret Manager**: API keys stored securely (Gemini, Claude, SerpAPI)

**Example** (Firestore integration):
```javascript
const admin = require('firebase-admin');
admin.initializeApp();

exports.getItem = functions.https.onCall(async (data, context) => {
    const { itemId } = data;
    const doc = await admin.firestore().collection('items').doc(itemId).get();

    if (!doc.exists) {
        throw new functions.https.HttpsError('not-found', 'Item not found');
    }

    // Verify user owns item
    if (doc.data().userId !== context.auth.uid) {
        throw new functions.https.HttpsError('permission-denied', 'Access denied');
    }

    return doc.data();
});
```

**Outcome**: No custom database adapters, no auth middleware (Firebase handles it).

---

## Alternatives Considered

### Alternative 1: GraphQL (Apollo Server)

**Approach**: Use GraphQL API with Apollo Server (Cloud Run).

**Pros**:
- **Flexible queries**: Clients request exactly what they need (no over-fetching)
- **Type safety**: GraphQL schema enforces contracts
- **Real-time subscriptions**: WebSocket support for live updates

**Cons**:
- **iOS complexity**: Requires Apollo iOS SDK (5,000+ lines of generated code)
- **Over-engineered**: MVP doesn't need complex queries (catalog is simple CRUD)
- **Cloud Run cost**: Minimum $5/month for always-on container (vs $0.20 Cloud Functions)
- **Learning curve**: GraphQL query language, schema design, resolvers

**Why Rejected**: GraphQL overkill for simple catalog CRUD. REST API simpler for iOS integration.

---

### Alternative 2: tRPC (TypeScript RPC)

**Approach**: Use tRPC for end-to-end type-safe API (TypeScript on both iOS/backend).

**Pros**:
- **Full type safety**: Shared types between frontend/backend
- **No code generation**: Auto-inferred types
- **Fast development**: Changes propagate instantly

**Cons**:
- **iOS limitation**: tRPC designed for TypeScript (no Swift support)
- **Requires TypeScript iOS app**: Would need React Native or web wrapper (contradicts iOS 26 native strategy)
- **Niche technology**: Smaller ecosystem than REST/GraphQL

**Why Rejected**: No Swift support, contradicts native iOS decision (ADR-004).

---

### Alternative 3: gRPC (Protocol Buffers)

**Approach**: Use gRPC for binary protocol, high-performance RPC.

**Pros**:
- **Performance**: Binary protocol faster than JSON
- **Type safety**: Protocol Buffers schema enforces contracts
- **Streaming**: Bi-directional streaming support

**Cons**:
- **iOS complexity**: gRPC-Swift library adds 10,000+ lines of code
- **HTTP/2 required**: More complex debugging (can't use curl/Postman easily)
- **Over-engineered**: MVP doesn't need microsecond latency (AI pipeline is seconds)

**Why Rejected**: Complexity unjustified for MVP. REST API sufficient for catalog CRUD.

---

## Implications & Consequences

### Positive

1. **Simple iOS Integration**: URLSession + Codable (no GraphQL/gRPC dependencies)
2. **Serverless Auto-Scale**: Cloud Functions scale 0 → 1,000+ instances automatically
3. **Low Cost**: $0.20/month for 500K API calls (vs $50/month dedicated server)
4. **GCP Integration**: Firebase Auth, Firestore, Secret Manager native access
5. **Fast Development**: REST API familiar to all developers (no learning curve)

---

### Negative

1. **Over-Fetching**: REST endpoints return full JSON objects (vs GraphQL selective queries)
   - **Mitigation**: Keep response payloads small (< 10 KB per item), acceptable for catalog CRUD
2. **No Real-Time Subscriptions**: REST doesn't support WebSocket live updates
   - **Mitigation**: Firestore Realtime Listeners handle real-time sync (ADR-006), API only for mutations
3. **Versioning Overhead**: URL-based versioning requires maintaining `/v1`, `/v2` endpoints
   - **Mitigation**: Phase 1 MVP unlikely to need breaking changes (stable API contract)

---

## Implementation Details

### Cloud Functions Deployment

**Project Structure**:
```
functions/
├── src/
│   ├── api/
│   │   ├── items.js          // CRUD endpoints (analyze, get, update, delete)
│   │   ├── subscriptions.js  // Stripe webhook handler
│   │   └── auth.js           // Custom claims (premium status)
│   ├── ai/
│   │   ├── gemini.js         // Layer 2a (Vertex AI Gemini)
│   │   ├── serpapi.js        // Layer 2b (SerpAPI visual search)
│   │   ├── upcitemdb.js      // Layer 2b (barcode lookup)
│   │   └── claude.js         // Layer 3 (Claude Sonnet synthesis)
│   ├── utils/
│   │   ├── auth.js           // Verify Firebase tokens
│   │   └── errors.js         // Custom error handling
│   └── index.js              // Export all functions
├── package.json
└── .env                      // API keys (Gemini, Claude, SerpAPI)
```

**Deployment**:
```bash
cd functions
npm install
firebase deploy --only functions
```

---

### API Endpoint Examples

**POST /api/v1/items/analyze**:
```json
{
  "imageUrl": "https://storage.googleapis.com/abundance-prod/items/item_123.jpg",
  "userId": "user_abc",
  "detectedObjects": [
    { "class": "tent", "confidence": 0.87, "boundingBox": [100, 200, 300, 400] }
  ]
}
```

**Response**:
```json
{
  "itemId": "item_12345",
  "status": "analyzing",
  "layer1Complete": true
}
```

**POST /api/v1/items/synthesize**:
```json
{
  "itemId": "item_12345",
  "layer2aResult": { "color": "green", "material": "polyester" },
  "layer2bResult": { "productName": "Coleman Evanston Tent", "barcode": null }
}
```

**Response**:
```json
{
  "itemId": "item_12345",
  "status": "complete",
  "metadata": {
    "name": "Coleman Evanston 8-Person Tent",
    "category": "camping",
    "brand": "Coleman",
    "model": "Evanston 8-Person",
    "color": "green",
    "material": "polyester",
    "condition": "good",
    "estimatedValue": 249.99,
    "confidence": "high"
  }
}
```

---

### Error Handling

**Standard Error Responses**:
```json
{
  "error": {
    "code": "unauthenticated",
    "message": "User must be signed in",
    "details": {}
  }
}
```

**HTTP Status Codes**:
- `200 OK`: Success
- `201 Created`: Item created
- `400 Bad Request`: Invalid input
- `401 Unauthorized`: Missing or invalid Firebase token
- `403 Forbidden`: User doesn't own resource
- `404 Not Found`: Item not found
- `500 Internal Server Error`: Server error (logged to Cloud Logging)

---

## Acceptance Criteria

- [x] ✅ REST API endpoints defined for all AI pipeline layers
- [x] ✅ Cloud Functions (2nd gen) deployed to GCP
- [x] ✅ Firebase Auth token validation implemented
- [x] ✅ iOS URLSession integration tested (POST /analyze, GET /items/:id)
- [x] ✅ OpenAPI 3.0 specification created (API-CONTRACTS-001)
- [x] ✅ Error handling standardized (HTTP status codes + error JSON)

---

## Related Decisions

- **ADR-002**: Platform strategy (GCP) → Cloud Functions native GCP service
- **ADR-005**: Authentication (Firebase Auth) → API validates Firebase ID tokens
- **ADR-006**: Database (Firestore) → API writes results to Firestore
- **DESIGN-004**: AI pipeline (4-layer) → API endpoints map to layers

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, REST API with Cloud Functions | Software Architecture Expert |

---

**This API architecture supports simple iOS integration (URLSession), serverless auto-scaling (Cloud Functions), and GCP platform integration (ADR-002).**

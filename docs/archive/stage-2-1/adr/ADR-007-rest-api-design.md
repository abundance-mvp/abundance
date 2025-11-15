# ADR-007: REST API Design

**Status:** Approved
**Date:** 2025-10-24
**Decision Makers:** Engineering Leadership, API Architect
**Related Documents:** API-CONTRACTS-001, TECH-STACK-001

---

## Context

API protocol decision for Abundance backend: REST vs. GraphQL vs. gRPC

---

## Decision

**We will use REST + JSON for all backend APIs, with Firebase HTTPS Callable functions.**

### API Style

**Protocol:** HTTPS
**Format:** JSON
**Pattern:** Firebase Callable Functions (RPC-style, not RESTful verbs)

**Example:**
```javascript
// iOS calls:
functions.httpsCallable("enrichItem").call({ itemId: "...", ... })

// Cloud Function:
exports.enrichItem = functions.https.onCall(async (data, context) => { ... })
```

---

## Rationale

### 1. Firebase Callable Functions (Automatic Auth)

**Benefit:** Authentication is automatic (no manual JWT validation)

```javascript
exports.enrichItem = functions.https.onCall(async (data, context) => {
    // context.auth is automatically populated by Firebase
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated');
    }
    const userId = context.auth.uid;  // No manual token parsing
});
```

**Alternative (Manual REST):**
```javascript
// Would require manual JWT validation:
const token = req.headers.authorization.split('Bearer ')[1];
const decodedToken = await admin.auth().verifyIdToken(token);
const userId = decodedToken.uid;
```

---

### 2. Simple CRUD Operations (No Complex Queries)

**API Operations:**
- `enrichItem(itemId, ...)` - Single item enrichment
- `retryFailedEnrichments()` - Scheduled batch job

**No need for:**
- Complex filtering (GraphQL strength)
- Batch operations (gRPC strength)
- Real-time subscriptions (handled by Firestore)

---

### 3. iOS Tooling (Firebase SDK)

**Firebase SDK:**
```swift
let functions = Functions.functions()
let result = try await functions.httpsCallable("enrichItem").call([
    "itemId": "abc123",
    "basicLabel": "scissors"
])
```

**GraphQL (Would require Apollo Client):**
```swift
// Additional dependency, more boilerplate
let apollo = ApolloClient(...)
apollo.fetch(query: EnrichItemMutation(...))
```

**gRPC (Would require Protobuf):**
```swift
// Requires .proto files, code generation
let client = EnrichmentServiceClient(...)
client.enrichItem(request: ...)
```

---

## Alternatives Considered

### Alternative 1: GraphQL

**Pros:**
- Flexible queries (client controls fields)
- Single endpoint (`/graphql`)
- Strong typing (schema)

**Cons:**
- **Overkill:** Only 1-2 API operations (not 50+ REST endpoints)
- **Complexity:** Requires Apollo Server (Node.js), Apollo Client (iOS)
- **Caching:** GraphQL caching is complex (vs. HTTP caching)

**Why Rejected:** Too complex for simple CRUD operations

---

### Alternative 2: gRPC

**Pros:**
- High performance (binary protocol)
- Strong typing (.proto files)
- Bidirectional streaming

**Cons:**
- **Mobile unfriendly:** gRPC over HTTP/2 has iOS compatibility issues
- **Complexity:** Requires .proto files, code generation
- **No browser support:** Can't call gRPC from web (future consideration)

**Why Rejected:** REST is sufficient for MVP performance needs

---

### Alternative 3: RESTful Verbs (POST /items, GET /items/:id)

**Approach:**
- Traditional REST: `POST /items`, `GET /items/:id`, `PUT /items/:id`
- Express.js server on Cloud Functions

**Pros:**
- Industry standard (everyone knows REST)
- Better for public APIs

**Cons:**
- **Manual auth:** Would need to validate Firebase JWT manually
- **More boilerplate:** Express.js setup, routing, error handling

**Why Rejected:** Firebase Callable Functions handle auth automatically (faster development)

---

## Implications

### Positive

1. **Faster development:** Firebase Callable = less boilerplate
2. **Automatic auth:** No manual JWT validation
3. **Simple debugging:** JSON is human-readable

### Negative (Risks)

1. **Not RESTful:** Firebase Callable is RPC-style (not `GET /items`)
   - **Mitigation:** Internal API (not public), RPC is fine
2. **No HTTP caching:** Firebase Callable uses POST (not cacheable)
   - **Mitigation:** Firestore handles caching (client-side)
3. **Vendor lock-in:** Firebase Callable is GCP-specific
   - **Mitigation:** Can migrate to Express.js REST later if needed (low priority)

---

## Future Considerations

**When to Switch to GraphQL/gRPC:**
- **GraphQL:** If API grows to 20+ operations, clients need flexible queries
- **gRPC:** If performance becomes bottleneck (>10K QPS, unlikely in MVP)

**Timeline:** Reevaluate at Month 12 (Phase 2 marketplace launch)

---

## Stakeholder Sign-Off

- [ ] **Engineering Leadership**
- [ ] **iOS Lead** (confirm Firebase SDK is acceptable)

**Timeline:** Finalized by 2025-10-31

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial REST API decision | Stage 2.1 Execution |

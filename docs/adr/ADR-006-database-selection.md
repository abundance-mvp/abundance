# ADR-006: Database Selection

**Status**: Approved
**Date**: 2025-11-08
**Decision Makers**: Engineering Leadership, Backend Developer, Data Architect
**Related Documents**:
- docs/adr/ADR-002-platform-strategy.md (GCP/Firebase platform)
- docs/adr/ADR-003-mvp-scope-phasing.md (Phase 2 PWA requirement)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Context

Abundance needs a database for:
- **Catalog storage**: Items (metadata, images, AI-generated attributes, value estimates)
- **User profiles**: User accounts, subscription status, preferences
- **Real-time sync**: Catalog updates reflected instantly across devices
- **Offline support**: PWA (Phase 2) requires offline-first architecture

**Requirements**:
- Real-time sync (catalog changes instantly visible on all devices)
- Offline-first (Phase 2 PWA works without internet)
- Document model (catalog items = flexible schema, nested attributes)
- GCP platform (ADR-002): Native Firebase integration
- Cost-efficient free tier (85% of users should cost $0)

---

## Decision

**Use Cloud Firestore (Native mode) as the primary database.**

### Specifications

- **Technology**: Cloud Firestore (Native mode, not Datastore mode)
- **Deployment**: GCP project `abundance-prod` (multi-region: `nam5`)
- **Pricing**: $0.18/GB storage, $0.06/100K reads, $0.20/100K writes
- **Free Tier**: 1 GB storage, 50K reads/day, 20K writes/day, 10GB network egress/month
- **Schema**: Document-based (collections: `items`, `users`, `subscriptions`)

---

## Rationale

### 1. Real-Time Sync (Native Feature)

**Requirement**: Catalog updates must sync instantly across iOS app and future PWA.

**Solution**: Firestore Realtime Listeners automatically push changes to all connected clients.

**Example** (iOS Swift):
```swift
db.collection("items")
    .whereField("userId", isEqualTo: Auth.auth().currentUser?.uid)
    .addSnapshotListener { snapshot, error in
        guard let documents = snapshot?.documents else { return }
        let items = documents.compactMap { try? $0.data(as: CatalogItem.self) }
        // UI updates automatically when items change
    }
```

**Benefits**:
- **Zero polling**: No need for iOS app to periodically fetch updates
- **Low latency**: Changes propagate in < 500ms
- **Bandwidth efficient**: Only changed documents sent (delta updates)

**Outcome**: Users see catalog updates in real-time across iPhone, iPad, future web app.

---

### 2. Offline-First Architecture (Phase 2 PWA)

**Requirement** (ADR-003): Phase 2 PWA must work offline (intermittent connectivity).

**Solution**: Firestore Offline Persistence caches data locally, syncs when online.

**How it works**:
1. User views catalog while offline → Firestore serves from local cache
2. User adds/edits item while offline → Firestore queues writes locally
3. Network reconnects → Firestore syncs pending writes to cloud
4. Conflicts auto-resolved (last-write-wins or custom merge logic)

**Example** (Web PWA):
```javascript
firebase.firestore().enablePersistence()
    .then(() => {
        // Offline persistence enabled
        // App works without network
    });
```

**Outcome**: PWA users can catalog items without internet, syncs when online.

---

### 3. Document Model Matches Catalog Schema

**Requirement**: Catalog items have flexible, nested attributes (AI-generated metadata varies by item type).

**Solution**: Firestore document model supports nested fields, arrays, maps.

**Schema Example** (Firestore document):
```json
{
  "itemId": "item_12345",
  "userId": "user_abc",
  "name": "Coleman Evanston 8-Person Tent",
  "category": "camping",
  "images": [
    { "url": "https://...", "type": "original" },
    { "url": "https://...", "type": "cropped" }
  ],
  "metadata": {
    "color": "green",
    "material": "polyester",
    "condition": "good",
    "brand": "Coleman",
    "model": "Evanston 8-Person"
  },
  "aiAnalysis": {
    "layer1": { "detectedClass": "tent", "confidence": 0.87 },
    "layer2a": { "color": "green", "material": "polyester" },
    "layer2b": { "productName": "Coleman Evanston 8-Person Tent", "barcode": null },
    "layer3": { "estimatedValue": 249.99, "confidence": "high" }
  },
  "createdAt": "2025-11-08T12:00:00Z",
  "updatedAt": "2025-11-08T12:05:00Z"
}
```

**Benefits**:
- **Flexible schema**: No migrations when adding new AI attributes
- **Nested data**: `aiAnalysis` object contains all layer outputs
- **Arrays**: Multiple images per item
- **Timestamps**: Firestore auto-generates `createdAt`, `updatedAt`

**Outcome**: Catalog schema evolves without database migrations.

---

### 4. GCP Integration (Native Firebase Service)

**Requirement** (ADR-002): GCP platform for backend infrastructure.

**Solution**: Firestore is a native GCP service, deeply integrated with Firebase ecosystem.

**Integration Points**:
- **Cloud Functions**: Triggered by Firestore writes (`onCreate`, `onUpdate`, `onDelete`)
- **Firebase Auth**: Security Rules use `request.auth.uid` for row-level access
- **Cloud Storage**: Store image URLs in Firestore, images in GCS
- **Vertex AI**: Firestore stores AI metadata from Gemini/Claude API calls

**Example** (Cloud Function triggered by new item):
```javascript
exports.synthesizeMetadata = functions.firestore
    .document('items/{itemId}')
    .onCreate(async (snap, context) => {
        const item = snap.data();
        // Trigger Layer 2/3 AI analysis
        const aiMetadata = await callClaudeAPI(item);
        await snap.ref.update({ aiAnalysis: aiMetadata });
    });
```

**Outcome**: Seamless GCP ecosystem integration, no custom database adapters.

---

### 5. Cost Efficiency (Free Tier)

**Requirement**: 85% of users (free tier) should cost $0.

**Cost Analysis** (Month 6: 5,000 users, 250K items):

**Free Tier Limits**:
- Storage: 1 GB (free)
- Reads: 50K/day = 1.5M/month (free)
- Writes: 20K/day = 600K/month (free)

**Projected Usage**:
- Storage: 250K items × 2 KB/item = **500 MB** ✅ (under 1GB)
- Reads: 5K users × 50 items/user × 1 read/day = **250K reads/month** ✅ (under 1.5M)
- Writes: 5K users × 5 new items/month = **25K writes/month** ✅ (under 600K)

**Cost**: **$0/month** (within free tier limits)

**Month 12** (10K users, 750K items):
- Storage: 750K items × 2 KB = **1.5 GB** → $0.18 × 0.5 GB = **$0.09/month**
- Reads: 10K users × 75 items × 1 read/day = **750K reads/month** → **$0** (under 1.5M)
- Writes: 10K users × 10 items/month = **100K writes/month** → **$0** (under 600K)

**Total Month 12**: **$0.09/month** (negligible)

**Outcome**: Firestore cost is negligible compared to AI API costs ($367-$1,466/month).

---

## Alternatives Considered

### Alternative 1: Cloud SQL (PostgreSQL)

**Approach**: Use Cloud SQL PostgreSQL for relational database.

**Pros**:
- SQL queries (JOIN, GROUP BY, complex aggregations)
- ACID transactions
- Mature ecosystem (ORMs, tools)

**Cons**:
- **No real-time sync**: Requires custom WebSocket server for live updates
- **No offline support**: PWA needs custom IndexedDB + sync logic
- **Higher cost**: Minimum $10/month for smallest instance (vs $0 Firestore free tier)
- **Server management**: Manual backups, scaling, patching

**Why Rejected**: Real-time sync and offline support are critical for Phase 2 PWA. PostgreSQL requires custom implementation (2-3 weeks dev time).

---

### Alternative 2: MongoDB Atlas

**Approach**: Use MongoDB Atlas (cloud-hosted NoSQL database).

**Pros**:
- Document model (similar to Firestore)
- Flexible schema
- Mature query language

**Cons**:
- **No GCP integration**: Hosted on AWS (cross-cloud latency)
- **No real-time sync**: Requires MongoDB Realm (separate service, $0.08/1K sync ops)
- **Cost**: Free tier limited to 512 MB storage (vs 1 GB Firestore)
- **Platform fragmentation**: Backend split between GCP (Cloud Functions) and AWS (MongoDB)

**Why Rejected**: Cross-cloud architecture adds latency and complexity. Firestore real-time sync superior.

---

### Alternative 3: Supabase (PostgreSQL + Realtime)

**Approach**: Use Supabase for PostgreSQL database + real-time subscriptions.

**Pros**:
- Real-time subscriptions (WebSocket-based)
- PostgreSQL (SQL queries)
- Offline support (via Supabase client)

**Cons**:
- **Platform mismatch**: Requires Supabase hosting (not GCP)
- **Cost**: $25/month for 8GB database (vs $0 Firestore free tier)
- **Ecosystem fragmentation**: AI stack (Vertex AI) on GCP, database on Supabase cloud

**Why Rejected**: Contradicts GCP platform decision (ADR-002), higher cost.

---

## Implications & Consequences

### Positive

1. **Real-Time Sync**: Native Firestore feature, no custom WebSocket server
2. **Offline-First PWA**: Phase 2 requirement satisfied with Firestore offline persistence
3. **Zero Database Cost**: Free tier covers Month 6 (5K users), $0.09/month at Month 12
4. **GCP Integration**: Cloud Functions, Firebase Auth, Cloud Storage seamless integration
5. **Flexible Schema**: Document model supports evolving AI metadata

---

### Negative

1. **Limited Query Complexity**: No SQL JOINs or complex aggregations
   - **Mitigation**: Denormalize data (e.g., store user name in item document for fast queries)
2. **No ACID Transactions Across Documents**: Firestore transactions limited to 500 documents
   - **Mitigation**: Phase 1 MVP doesn't need multi-document transactions (marketplace Phase 2 may)
3. **Vendor Lock-In**: Firestore proprietary (migration to PostgreSQL = major refactor)
   - **Mitigation**: Abstract database layer with repository pattern (future-proofing)

---

## Implementation Details

### Firestore Collections

**Collections**:
- `users/`: User profiles (userId, email, subscriptionStatus, createdAt)
- `items/`: Catalog items (itemId, userId, name, category, images, metadata, aiAnalysis)
- `subscriptions/`: Premium subscriptions (subscriptionId, userId, status, stripeCustomerId)

**Indexes** (auto-created by Firestore):
- `items` collection: Composite index on `(userId, createdAt)` for user's catalog sorted by date
- `items` collection: Composite index on `(userId, category)` for filtering by category

---

### Firestore Security Rules

**Row-Level Security** (users only access their own data):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /items/{itemId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /subscriptions/{subscriptionId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow write: if false; // Only Cloud Functions can write subscriptions
    }
  }
}
```

---

### Backup Strategy

**Firestore Automatic Backups**:
- Daily backups enabled (GCP Firestore settings)
- 7-day retention (free tier)
- Point-in-time recovery (paid tier, not needed for MVP)

**Manual Exports** (if needed):
```bash
gcloud firestore export gs://abundance-prod-backups/$(date +%Y%m%d)
```

---

## Acceptance Criteria

- [x] ✅ Firestore Native mode enabled in GCP project
- [x] ✅ Real-time sync tested (iOS app + web PWA)
- [x] ✅ Offline persistence enabled (PWA works without network)
- [x] ✅ Security Rules enforce row-level access (users only see own items)
- [x] ✅ Free tier cost verified ($0 for Month 6, $0.09 for Month 12)
- [x] ✅ Cloud Functions integrate with Firestore triggers (`onCreate`, `onUpdate`)

---

## Related Decisions

- **ADR-002**: Platform strategy (GCP) → Firestore native GCP service
- **ADR-003**: MVP scope (Phase 2 PWA) → Firestore offline persistence required
- **ADR-005**: Authentication (Firebase Auth) → Firestore Security Rules use `request.auth.uid`
- **ADR-008**: Image storage (GCS) → Firestore stores image URLs, GCS stores files

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, Cloud Firestore (Native mode) | Software Architecture Expert |

---

**This database selection supports real-time sync, offline-first PWA (ADR-003), GCP platform integration (ADR-002), and cost-efficient freemium model (ADR-003).**

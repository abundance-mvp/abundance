# ADR-008: Cloud Firestore Database Selection

**Status:** Approved
**Date:** 2025-10-24
**Decision Makers:** Engineering Leadership, Backend Lead
**Related Documents:** TECH-STACK-001, ADR-005

---

## Context

Database selection for Abundance MVP: Firestore (NoSQL) vs. Cloud SQL (PostgreSQL)

---

## Decision

**We will use Cloud Firestore (NoSQL) as our primary database.**

### Key Properties

| Property | Value |
|----------|-------|
| **Type** | NoSQL (document-based) |
| **Offline Support** | Yes (built-in iOS SDK) |
| **Real-time Sync** | Yes (live listeners) |
| **Free Tier** | 50K reads/day, 20K writes/day, 1 GB storage |
| **Scaling** | Automatic (no capacity planning) |

---

## Rationale

### 1. Offline-First (Free Tier Requirement)

**Requirement:** Free tier users must work without internet connection

**Firestore:**
- iOS SDK caches data locally
- Writes work offline, sync when online
- **Zero backend code required**

**Cloud SQL (PostgreSQL):**
- No offline support
- Would require custom sync logic (complex)

---

### 2. Real-Time Sync (Premium Tier)

**Requirement:** When enrichment completes, iOS app updates instantly

**Firestore:**
```swift
// Real-time listener (automatic updates)
db.collection("users/\(userId)/items").document(itemId)
    .addSnapshotListener { snapshot, error in
        // UI updates when enrichedAt field changes
    }
```

**Cloud SQL:**
- No real-time listeners
- Would require polling (inefficient) or WebSockets (complex)

---

### 3. Zero Backend Cost (Month 0-6)

**Free Tier (5,000 users, 250,000 items):**
- Reads: 5K users × 50 items × 2 reads/day = 500K reads/month = **16K reads/day** (within 50K limit)
- Writes: 5K users × 5 new items/day = 25K writes/month = **833 writes/day** (within 20K limit)
- Storage: 250K items × 5 KB = 1.25 GB (slightly over, ~$0.05/month)

**Cloud SQL (smallest instance):**
- $10/month minimum (db-f1-micro)

---

## Alternatives Considered

### Alternative 1: Cloud SQL (PostgreSQL)

**Pros:**
- Relational (better for complex queries, JOINs)
- Full-text search (built-in)
- ACID transactions

**Cons:**
- **No offline support:** Would require custom sync (2-4 weeks of work)
- **No real-time listeners:** Would require WebSockets or polling
- **Cost:** $10/month minimum (vs. $0 Firestore free tier)
- **Capacity planning:** Must choose instance size upfront

**Why Rejected:** Offline-first requirement makes Firestore better choice

---

### Alternative 2: Hybrid (Firestore + PostgreSQL)

**Approach:**
- Firestore for user items (offline-first)
- PostgreSQL for analytics, complex queries

**Pros:**
- Best of both worlds

**Cons:**
- **Complexity:** Two databases to maintain
- **Data consistency:** Must sync Firestore → PostgreSQL
- **Overkill:** MVP doesn't need complex analytics

**Why Rejected:** Unnecessary complexity for MVP, reevaluate at Month 12

---

## Limitations & Mitigations

### Limitation 1: No Full-Text Search

**Problem:** Firestore queries are limited (no `WHERE name CONTAINS "scissors"`)

**Mitigation:**
- **Phase 1:** Client-side filtering (fetch all items, filter in iOS app)
- **Phase 2 (Month 6+):** Add Algolia or Meilisearch for search

---

### Limitation 2: No Complex Queries (JOINs)

**Problem:** Can't JOIN `users` and `items` collections

**Mitigation:**
- **Denormalize:** Store user info in item document
```json
{
  "itemId": "abc123",
  "name": "scissors",
  "userId": "user123",
  "userEmail": "user@example.com"  // Denormalized
}
```

---

### Limitation 3: Query Limitations (OR, NOT)

**Problem:** Firestore doesn't support complex boolean logic

**Mitigation:**
- Use `whereIn()` for small OR queries (max 10 values)
- For complex queries: Fetch all, filter client-side

---

## Data Model

```
users (collection)
├── {userId} (document)
│   ├── email: "user@example.com"
│   ├── subscriptionTier: "free" | "premium"
│   └── items (subcollection)
│       └── {itemId} (document)
│           ├── name: "scissors"
│           ├── category: "Office Supplies"
│           ├── tier: "free" | "premium"
│           └── ...
```

**Security Rules:**
```javascript
match /users/{userId}/items/{itemId} {
  allow read, write: if request.auth.uid == userId;
}
```

---

## Stakeholder Sign-Off

- [ ] **Engineering Leadership**

**Timeline:** Finalized by 2025-10-31

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial Firestore selection | Stage 2.1 Execution |

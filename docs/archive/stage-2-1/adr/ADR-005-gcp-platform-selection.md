# ADR-005: GCP Platform Selection

**Status:** Approved
**Date:** 2025-10-24
**Decision Makers:** Engineering Leadership, CTO
**Related Documents:** TECH-STACK-001, ADR-004, ADR-012

---

## Context

Backend cloud platform selection for Abundance MVP. Need to choose between major cloud providers for compute, database, storage, and AI services.

---

## Decision

**We will use Google Cloud Platform (GCP) with Firebase as our primary backend platform.**

### Core Services

| Service | Technology | Purpose |
|---------|-----------|---------|
| **Authentication** | Firebase Authentication | Apple Sign-In, Email/Password |
| **Database** | Cloud Firestore | NoSQL, offline-first, real-time sync |
| **Storage** | Firebase Storage | Premium tier cropped images |
| **Compute** | Cloud Functions (2nd gen) | Serverless product enrichment |
| **AI/ML** | Google Shopping Graph | Product identification |
| **Monitoring** | Cloud Logging, Cloud Monitoring | Observability |

---

## Rationale

### 1. Google Shopping Graph Integration (PRIMARY REASON)

**Requirement:** Premium tier requires Google Shopping Graph API for product identification

**Why GCP:**
- Shopping Graph is a Google service (tight integration)
- Likely requires GCP project for authentication/billing
- Cross-platform pricing inefficiencies if backend on AWS but AI on GCP

**Alternative (AWS):**
- Would require GCP project anyway (for Shopping Graph)
- Two cloud providers = split billing, complexity

---

### 2. Firebase Ecosystem (Free Tier + iOS SDK)

**Firestore Benefits:**
- **Offline-first:** Free tier users work without internet connection
- **Real-time sync:** iOS SDK automatically syncs data when online
- **Generous free tier:** 50K reads/day, 20K writes/day, 1 GB storage
- **No backend code:** iOS app writes directly to Firestore (free tier)

**Firebase Auth Benefits:**
- Apple Sign-In integration (2 lines of code)
- Anonymous auth → permanent upgrade flow
- Free tier: 50K Monthly Active Users (MAU)

**Cost Advantage (Month 6, 5K users):**
- Firebase: $0 (within free tier)
- AWS (DynamoDB + Cognito): ~$50/month

---

### 3. Unified Billing & Simplicity

**GCP (Single Provider):**
- One invoice, one dashboard
- Unified IAM (service accounts work across Firebase, Cloud Functions, Shopping Graph)
- Single support contract

**Multi-Cloud (AWS + GCP):**
- Two invoices, two dashboards
- Complex cross-cloud networking (AWS Lambda → GCP Shopping Graph API)
- Split team expertise

---

## Alternatives Considered

### Alternative 1: AWS (Amplify, DynamoDB, Cognito)

**Pros:**
- Larger market share (easier to hire engineers with AWS experience)
- More mature serverless ecosystem (Lambda vs. Cloud Functions)
- Better enterprise support

**Cons:**
- **No Shopping Graph:** Would still need GCP for AI (split cloud)
- **Offline-first complexity:** DynamoDB requires custom sync logic (Firestore has it built-in)
- **Higher costs:** DynamoDB + Cognito + S3 = ~$50-100/month (vs. $0 on Firebase free tier)

**Why Rejected:** Shopping Graph requires GCP anyway, Firebase is better for offline-first

---

### Alternative 2: Azure (Cosmos DB, Azure Functions)

**Pros:**
- Strong enterprise sales (if targeting B2B later)
- Good offline sync (Cosmos DB)

**Cons:**
- **No Shopping Graph:** Would still need GCP
- **Smaller mobile ecosystem:** Worse iOS SDK than Firebase
- **Higher costs:** Cosmos DB is expensive

**Why Rejected:** No compelling advantage over GCP

---

### Alternative 3: Supabase (Open-Source Firebase Alternative)

**Pros:**
- Open-source (no vendor lock-in)
- PostgreSQL (vs. NoSQL) - better for relational data
- Lower costs (~$25/month vs. $0 Firebase free tier)

**Cons:**
- **No Shopping Graph integration:** Would need GCP anyway
- **Smaller ecosystem:** Fewer pre-built integrations
- **Self-hosted complexity:** Requires DevOps (startup has no DevOps engineer)

**Why Rejected:** Firebase free tier is better economics, GCP needed for Shopping Graph

---

## Implications

### Positive

1. **Lower costs:** Firebase free tier covers Month 0-6 ($0 backend costs)
2. **Faster development:** Firebase iOS SDK handles auth, database, storage
3. **Unified platform:** Single cloud provider (GCP) for backend + AI

### Negative (Risks)

1. **Vendor lock-in:** Firebase is proprietary (hard to migrate off GCP)
   - **Mitigation:** Firestore data exportable to JSON, PostgreSQL
2. **NoSQL limitations:** Firestore lacks complex queries (JOINs, full-text search)
   - **Mitigation:** Add Algolia for search (Month 6+)
3. **GCP market share:** Smaller than AWS (harder to hire engineers)
   - **Mitigation:** Firebase is popular among mobile devs (sufficient talent pool)

---

## Open Questions

### Question 1: Multi-Region Strategy (Month 12+)

**Question:** Should we deploy to multiple GCP regions for disaster recovery?

**Options:**
- **Single-region (us-central1):** Simpler, cheaper
- **Multi-region:** Better uptime (99.99% vs. 99.95%)

**Recommendation:** Single-region for Phase 1, multi-region in Phase 3 (B2B expansion)

---

## Stakeholder Sign-Off

- [ ] **CTO / Engineering Leadership**
- [ ] **Finance** (approve GCP billing)

**Timeline:** Finalized by 2025-10-31

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial GCP selection rationale | Stage 2.1 Execution |

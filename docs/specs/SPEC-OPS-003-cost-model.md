# SPEC-OPS-003: Cost Model

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## Overview

This document provides a comprehensive cost model for the Abundance MVP application, covering AI processing, storage, and Firebase infrastructure costs. The application uses a two-layer AI pipeline architecture with distinct cost profiles for each tier.

### Cost Structure Summary

| Category | Monthly Cost (1K items) | % of Total |
|----------|------------------------|------------|
| AI Processing (Layer 1) | ~$2.00 | 4% |
| AI Processing (Layer 2) | ~$40.00 | 80% |
| Cloud Storage (GCS) | ~$0.20 | <1% |
| Firestore | ~$5.00 | 10% |
| Cloud Functions | ~$3.00 | 6% |
| **Total** | **~$50.20** | 100% |

---

## AI Processing Costs

### Layer 1: Gemini 3 Flash

**Model:** `gemini-3-flash-preview`
**Reference:** `functions/src/ai-pipeline/layer1/prompts.ts:14`

| Component | Pricing | Notes |
|-----------|---------|-------|
| Input tokens | ~$0.075/1M tokens | Text + image encoding |
| Output tokens | ~$0.30/1M tokens | JSON detection response |
| Thinking tokens (LOW) | ~$0.30/1M tokens | ThinkingLevel.LOW adds minimal overhead |

**Per-Item Estimate:**

| Metric | Value |
|--------|-------|
| Input tokens (avg) | ~2,500 tokens | System prompt + 1-3 images |
| Output tokens (avg) | ~800 tokens | Detection JSON with bounding boxes |
| Thinking tokens (avg) | ~200 tokens | LOW thinking level |
| **API cost/item** | ~$0.00045 | |
| Server-side cropping | ~$0.0005 | sharp library, CPU time |
| GCS storage write | ~$0.0005 | Crop upload |
| **Total Layer 1** | **~$0.002/item** | |

**Configuration:**
- Max output tokens: 4096 (`functions/src/ai-pipeline/layer1/prompts.ts:62`)
- Temperature: 0.1 (deterministic)
- Response format: JSON schema-constrained
- API timeout: 30 seconds
- Max retries: 2 (exponential backoff)

### Layer 2: Gemini 3 Pro

**Model:** `gemini-3-pro-preview`
**Reference:** `functions/src/ai-pipeline/gemini/prompts.ts:141`

| Component | Pricing | Notes |
|-----------|---------|-------|
| Input tokens | ~$1.25/1M tokens | Text + image + tool context |
| Output tokens | ~$5.00/1M tokens | Full catalog JSON |
| Thinking tokens | ~$5.00/1M tokens | Pro thinking adds detail |

**Per-Item Estimate (API only):**

| Metric | Value |
|--------|-------|
| Input tokens (avg) | ~4,000 tokens | Prompt + image + tool results |
| Output tokens (avg) | ~1,200 tokens | CatalogItem JSON |
| Thinking tokens (avg) | ~800 tokens | Pro-level reasoning |
| Tool iterations (avg) | 2-3 | google_lens + web_search |
| **API cost/item** | ~$0.004 | |

**Configuration:**
- Max output tokens: 8192 (`functions/src/ai-pipeline/gemini/prompts.ts:136`)
- Temperature: 0.1
- Max tool iterations: 10 (`functions/src/ai-pipeline/gemini/gemini-service.ts:65`)
- Function timeout: 120 seconds

---

## Tool Costs

Layer 2 uses three external tools for product identification and pricing. Costs vary based on which tools Gemini chooses to call.

### google_lens_search (SerpAPI)

**Reference:** `functions/src/ai-pipeline/tools/google-lens.ts:36`

| Metric | Value |
|--------|-------|
| Cost per call | ~$0.015 |
| Hit rate | ~90% of items | Called when visual matching needed |
| Average calls/item | 1.0 | Usually one image per product |

**SerpAPI Google Lens Pricing:**
- Free tier: 100 searches/month
- Paid plans: $50/month for ~3,333 searches (~$0.015/search)

### barcode_lookup (UPCitemdb)

**Reference:** `functions/src/ai-pipeline/tools/barcode-lookup.ts:39`

| Metric | Value |
|--------|-------|
| Cost per call | ~$0.005 |
| Hit rate | ~30% of items | Only when barcode visible |
| Average calls/item | 0.3 | |

**UPCitemdb Pricing:**
- Free tier: 100 lookups/day
- Paid: ~$0.005/lookup (bulk plans available)

### web_search (Google Search Grounding)

**Reference:** `functions/src/ai-pipeline/tools/web-search.ts:19`

| Metric | Value |
|--------|-------|
| Cost per call | ~$0.014 |
| Hit rate | ~80% of items | Called for pricing |
| Average calls/item | 1.2 | Sometimes retried with different query |

**Google Search Grounding Pricing:**
- Vertex AI pricing: ~$35/1000 grounded queries
- Includes Amazon, eBay, Walmart, Target searches

### Total Tool Costs per Item

| Scenario | Tools Called | Cost |
|----------|-------------|------|
| **Minimum** (no tools) | None | $0.00 |
| **Typical** (lens + search) | google_lens + web_search | ~$0.03 |
| **Maximum** (all tools) | All 3 tools | ~$0.035 |
| **Average** | | **~$0.032** |

### Combined Layer 2 Cost

| Component | Cost/Item |
|-----------|-----------|
| Gemini 3 Pro API | ~$0.004 |
| Tool calls (avg) | ~$0.032 |
| **Total Layer 2** | **~$0.04/item** |

**Reference:** `functions/src/ai-pipeline/gemini/orchestrator.ts:137-152`

---

## Storage Costs

### Google Cloud Storage (GCS)

| Bucket | Purpose | Lifecycle |
|--------|---------|-----------|
| `abundance-*-temp` | Original captures | Deleted after Layer 1 |
| `abundance-mvp.firebasestorage.app` | Cropped objects | Permanent |

**Pricing (us-central1, Standard class):**

| Component | Rate |
|-----------|------|
| Storage | $0.020/GB/month |
| Class A ops (write) | $0.05/10K ops |
| Class B ops (read) | $0.004/10K ops |
| Network egress | $0.12/GB (to internet) |

**Per-Item Storage Estimate:**

| Metric | Value |
|--------|-------|
| Cropped image size | ~50KB (JPEG, compressed) |
| Crops per item | ~2 (multi-angle) |
| Storage per item | ~100KB |
| Storage cost/item/month | ~$0.000002 |
| Write operations | 2 (upload crops) |
| Read operations | ~5 (viewing + Layer 2) |
| **Monthly cost/item** | **~$0.0001** |

### Firestore

**Pricing (nam5 multi-region):**

| Operation | Rate |
|-----------|------|
| Document reads | $0.036/100K |
| Document writes | $0.108/100K |
| Document deletes | $0.012/100K |
| Storage | $0.18/GB/month |

**Per-Item Firestore Estimate:**

| Operation | Count | Cost |
|-----------|-------|------|
| Session doc writes | 3 | $0.00000324 |
| Item doc writes | 5 | $0.0000054 |
| Session doc reads | 5 | $0.0000018 |
| Item doc reads | 20 | $0.0000072 |
| Storage (~2KB/doc) | 4KB | ~$0.0000007/month |
| **Total/item** | | **~$0.00002** |

---

## Firebase/GCP Infrastructure Costs

### Firebase Authentication

| Component | Cost |
|-----------|------|
| Email/password auth | Free |
| Phone auth (SMS) | $0.01-0.06/verification |
| Monthly active users | Free up to 50K MAU |

**Estimate:** ~$0/month (staying within free tier)

### Cloud Functions

**Runtime:** Node.js 20
**Memory:** 512MiB (Layer 2), 256MiB (Layer 1)
**Reference:** `functions/src/triggers/onItemCreatedGemini3.ts:28`

| Component | Rate |
|-----------|------|
| Invocations | $0.40/million |
| Compute (GB-second) | $0.0000025 |
| Networking | $0.12/GB egress |

**Per-Item Function Costs:**

| Function | Memory | Duration | Cost |
|----------|--------|----------|------|
| onSessionCreated (L1) | 256MiB | ~15s | ~$0.000009 |
| onItemCreatedGemini3 (L2) | 512MiB | ~45s | ~$0.000056 |
| Invocation cost | | | ~$0.0000008 |
| **Total/item** | | | **~$0.00007** |

### Cloud Build (CI/CD)

| Component | Rate | Estimate |
|-----------|------|----------|
| Build minutes | $0.003/minute | ~$3/month (100 builds) |
| Free tier | 120 min/day | Usually sufficient |

---

## Cost Per Item Summary

### Layer 1 Only (Pre-catalogued)

| Component | Cost |
|-----------|------|
| Gemini 3 Flash API | $0.00045 |
| Image processing | $0.0005 |
| GCS storage | $0.0005 |
| Cloud Functions | $0.00001 |
| Firestore | $0.00001 |
| **Total** | **~$0.002/item** |

### Layer 1 + Layer 2 (Fully Catalogued)

| Component | Cost |
|-----------|------|
| Layer 1 (as above) | $0.002 |
| Gemini 3 Pro API | $0.004 |
| Tool calls (avg) | $0.032 |
| Cloud Functions | $0.00006 |
| Firestore updates | $0.00001 |
| **Total** | **~$0.04/item** |

### Total Cost with Ongoing Storage

| Time Period | Layer 1 Only | Layer 1 + Layer 2 |
|-------------|--------------|-------------------|
| Processing | $0.002 | $0.04 |
| +1 month storage | $0.0002 | $0.0002 |
| +6 months storage | $0.0012 | $0.0012 |
| +12 months storage | $0.0024 | $0.0024 |
| **Year 1 total** | **~$0.005** | **~$0.05** |

---

## Monthly Projections

### 100 Items/Month (Light User)

| Component | Layer 1 Only | With Layer 2 (50%) |
|-----------|--------------|---------------------|
| AI Processing | $0.20 | $2.20 |
| Storage | $0.01 | $0.01 |
| Firestore | $0.01 | $0.01 |
| Cloud Functions | $0.01 | $0.01 |
| **Total** | **$0.23** | **$2.23** |

### 1,000 Items/Month (Active User)

| Component | Layer 1 Only | With Layer 2 (50%) |
|-----------|--------------|---------------------|
| AI Processing | $2.00 | $22.00 |
| Storage | $0.10 | $0.10 |
| Firestore | $0.05 | $0.10 |
| Cloud Functions | $0.10 | $0.15 |
| **Total** | **$2.25** | **$22.35** |

### 10,000 Items/Month (Power User / Small Business)

| Component | Layer 1 Only | With Layer 2 (50%) |
|-----------|--------------|---------------------|
| AI Processing | $20.00 | $220.00 |
| Storage | $1.00 | $1.00 |
| Firestore | $0.50 | $1.00 |
| Cloud Functions | $1.00 | $1.50 |
| **Total** | **$22.50** | **$223.50** |

### Multi-Tenant (1,000 Users, 100 Items Each)

| Component | Layer 1 Only | With Layer 2 (30%) |
|-----------|--------------|---------------------|
| AI Processing | $200.00 | $1,400.00 |
| Storage | $10.00 | $10.00 |
| Firestore | $5.00 | $10.00 |
| Cloud Functions | $10.00 | $15.00 |
| Firebase Auth | $0 | $0 |
| **Total** | **$225** | **$1,435** |

---

## Cost Optimization Strategies

### 1. Context Caching (90% Reduction Potential)

**Applicable to:** Layer 1 and Layer 2 system prompts

Gemini supports context caching for frequently reused prompts. Since our system prompts are static:

| Component | Without Caching | With Caching | Savings |
|-----------|-----------------|--------------|---------|
| System prompt tokens | 500 tokens/call | Cached | 90% |
| Layer 1 input cost | $0.00019 | $0.000019 | $0.00017/item |
| Layer 2 input cost | $0.00063 | $0.000063 | $0.00057/item |

**Implementation:** Use `cachedContent` in Vertex AI GenerativeModel configuration.

**Estimated monthly savings (1K items):** ~$0.74

### 2. Image Compression (30-50% Reduction)

**Current:** JPEG crops at default quality
**Optimized:**
- WebP format (30% smaller than JPEG at same quality)
- Quality level 75 (sufficient for cataloging)
- Max dimension 1024px (Layer 2 doesn't need higher)

| Metric | Current | Optimized | Savings |
|--------|---------|-----------|---------|
| Crop size | 50KB | 30KB | 40% |
| Token count (images) | ~1,500 | ~1,000 | 33% |
| Upload bandwidth | 100KB/item | 60KB/item | 40% |

**Estimated monthly savings (1K items):** ~$3.50

### 3. Batch Processing

**Current:** One item per Layer 2 invocation
**Optimized:** Batch similar items in single request

| Batch Size | Overhead Reduction | Items/Month Breakeven |
|------------|-------------------|----------------------|
| 2 items | 15% | 100 |
| 5 items | 30% | 500 |
| 10 items | 40% | 1,000 |

**Considerations:**
- Requires queue-based architecture
- Increased latency for individual items
- Better for scheduled batch jobs vs. real-time

### 4. Tool Call Optimization

**Current:** Gemini decides which tools to call
**Optimizations:**

| Strategy | Savings | Trade-off |
|----------|---------|-----------|
| Skip barcode if not visible | $0.005/item | Lower accuracy for some items |
| Cache lens results | 50% lens calls | Requires result storage |
| Limit web search retries | $0.014/retry | May miss pricing data |

### 5. Tiered Processing

Route items through different processing paths based on characteristics:

| Item Type | Processing | Cost |
|-----------|------------|------|
| Common household | Layer 1 only | $0.002 |
| Consumer electronics | Layer 1 + Layer 2 | $0.04 |
| High-value/antiques | Layer 2 + manual review | $0.04 + labor |

**Implementation:** Add category-based routing in `onSessionCreated` trigger.

### 6. Free Tier Maximization

| Service | Free Tier | Strategy |
|---------|-----------|----------|
| Firestore | 50K reads/day | Batch reads, use snapshots |
| Cloud Functions | 2M invocations/month | Within limits for MVP |
| Cloud Build | 120 min/day | Cache dependencies |
| Firebase Auth | 50K MAU | No action needed |

---

## Cost Monitoring and Alerts

### Recommended Budget Alerts

| Alert Level | Threshold | Action |
|-------------|-----------|--------|
| Info | 50% of budget | Review usage patterns |
| Warning | 80% of budget | Optimize high-cost items |
| Critical | 100% of budget | Investigate anomalies |

### Key Metrics to Track

1. **Items processed/day** - Leading indicator
2. **Layer 2 conversion rate** - Premium usage
3. **Tool call frequency** - API cost driver
4. **Average token count** - Model efficiency
5. **Function duration** - Compute efficiency

### GCP Budget Setup

```bash
# Set monthly budget alert
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Abundance MVP Monthly" \
  --budget-amount=100USD \
  --threshold-rule=percent=0.5,basis=current-spend \
  --threshold-rule=percent=0.8,basis=current-spend \
  --threshold-rule=percent=1.0,basis=current-spend
```

---

## Pricing References

### Official Pricing Pages

| Service | URL | Last Verified |
|---------|-----|---------------|
| Vertex AI (Gemini) | cloud.google.com/vertex-ai/pricing | 2026-01-18 |
| Cloud Storage | cloud.google.com/storage/pricing | 2026-01-18 |
| Firestore | cloud.google.com/firestore/pricing | 2026-01-18 |
| Cloud Functions | cloud.google.com/functions/pricing | 2026-01-18 |
| SerpAPI | serpapi.com/pricing | 2026-01-18 |
| UPCitemdb | upcdatabase.org/pricing | 2026-01-18 |

### Pricing Assumptions

- Region: us-central1 / nam5 (multi-region for Firestore)
- Currency: USD
- Pricing tier: On-demand (no committed use discounts)
- Gemini 3 models: Preview pricing (may change at GA)

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-18 | 1.0 | Initial cost model specification |

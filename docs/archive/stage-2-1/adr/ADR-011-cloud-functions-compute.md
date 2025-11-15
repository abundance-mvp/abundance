# ADR-011: Cloud Functions for Serverless Compute

**Status:** Approved
**Date:** 2025-10-24
**Decision Makers:** Engineering Leadership, Backend Lead
**Related Documents:** TECH-STACK-001, ADR-005, ADR-006

---

## Context

Compute platform for backend: Cloud Functions (serverless) vs. Cloud Run (containers) vs. GKE (Kubernetes)

---

## Decision

**We will use Cloud Functions (2nd gen) for all backend compute.**

### Function Types

| Function | Trigger | Purpose |
|----------|---------|---------|
| `enrichItem` | HTTPS Callable | Product enrichment (premium tier) |
| `retryFailedEnrichments` | Cloud Scheduler (Pub/Sub) | Retry failed Shopping Graph calls |

---

## Rationale

### 1. Zero Ops (Serverless)

**Cloud Functions:**
- No server management
- Auto-scaling (0 → 1000 instances)
- Pay per invocation ($0.40 per million)

**Cloud Run (Containers):**
- Must manage Docker images
- More control, but more complexity

**GKE (Kubernetes):**
- Full control, but requires DevOps engineer
- Overkill for 2 functions

---

### 2. Firebase Integration

**Cloud Functions:**
- Native Firebase triggers (Firestore onCreate, Storage onFinalize)
- Automatic authentication (context.auth)
- Single deployment (`firebase deploy --only functions`)

**Cloud Run:**
- No Firebase triggers (would need Pub/Sub manually)
- Manual JWT validation

---

### 3. Cost (Month 6, 5K users)

**Estimated Invocations:**
- `enrichItem`: 75,000 items/month = 75K invocations
- `retryFailedEnrichments`: 4× per day × 30 days = 120 invocations
- **Total:** 75,120 invocations

**Cost:**
- Cloud Functions: 75K invocations × $0.40 per million = **$0.03/month** (free tier covers 2M invocations)
- Cloud Run: $0/month (free tier covers 2M requests)
- **Both are effectively free** (within free tier limits)

**Memory cost:**
- 512 MB × 5 sec × 75K invocations = 187,500 GB-seconds
- Free tier: 400,000 GB-seconds/month
- **Within free tier** ($0/month)

---

## Function Specifications

### enrichItem (HTTPS Callable)

```javascript
exports.enrichItem = functions
  .runWith({
    timeoutSeconds: 10,
    memory: '512MB',
    maxInstances: 50,
    minInstances: 0
  })
  .https.onCall(async (data, context) => {
    // Call Shopping Graph API
    // Update Firestore
  });
```

**Configuration:**
- **Timeout:** 10 seconds (Shopping Graph can be slow)
- **Memory:** 512 MB (image processing minimal, mostly API calls)
- **Max instances:** 50 (prevent runaway costs)
- **Min instances:** 0 (scale to zero when idle)

---

### retryFailedEnrichments (Scheduled)

```javascript
exports.retryFailedEnrichments = functions.pubsub
  .schedule('0 */6 * * *')  // Every 6 hours
  .runWith({
    timeoutSeconds: 540,  // 9 minutes (max for scheduled functions)
    memory: '256MB'
  })
  .onRun(async (context) => {
    // Query failed items
    // Retry Shopping Graph API
  });
```

**Configuration:**
- **Schedule:** Every 6 hours (Cron: `0 */6 * * *`)
- **Timeout:** 9 minutes (max for scheduled functions)
- **Memory:** 256 MB (batch processing, 100 items per run)

---

## Alternatives Considered

### Alternative 1: Cloud Run (Containerized)

**Pros:**
- More control (custom Docker image)
- Better for long-running tasks (>9 minutes)

**Cons:**
- **Complexity:** Must build Docker images, manage container registry
- **No Firebase triggers:** Would need Pub/Sub manually
- **Overkill:** 2 simple functions don't need containers

**Why Rejected:** Cloud Functions is simpler, sufficient for MVP

---

### Alternative 2: App Engine (PaaS)

**Pros:**
- Always-on (no cold starts)
- Better for web servers (Express.js)

**Cons:**
- **Cost:** Minimum 1 instance = $0.05/hour = $36/month
- **Overkill:** Don't need always-on server for 2 functions

**Why Rejected:** Serverless is cheaper ($0 vs. $36/month)

---

### Alternative 3: GKE (Kubernetes)

**Pros:**
- Full control (custom orchestration, service mesh)
- Scales to millions of requests

**Cons:**
- **Complexity:** Requires DevOps engineer (startup has none)
- **Cost:** Minimum 3 nodes = $150/month
- **Overkill:** 2 functions don't need Kubernetes

**Why Rejected:** Massive overkill for MVP

---

## Limitations & Mitigations

### Limitation 1: Cold Starts

**Problem:** First invocation after idle takes 1-2 seconds (cold start)

**Mitigation:**
- **Min instances:** Set to 1 for `enrichItem` in production (keeps 1 warm instance)
- **Cost:** 1 instance × 24 hours × 30 days = $5/month (acceptable)
- **Phase 1:** Min instances = 0 (save cost), accept cold starts
- **Phase 2:** Min instances = 1 (better UX)

---

### Limitation 2: 9-Minute Timeout (Scheduled Functions)

**Problem:** `retryFailedEnrichments` can only run for 9 minutes (540 seconds)

**Mitigation:**
- Process 100 items per run (< 5 minutes expected)
- If more than 100 items: Run multiple times (schedule every 6 hours, batches of 100)

---

### Limitation 3: No State (Stateless Functions)

**Problem:** Can't store state between invocations

**Mitigation:**
- Use Firestore for state (`enrichmentStatus: "pending_retry"`)
- Cloud Scheduler queries Firestore for items to retry

---

## Future Considerations

**When to Switch to Cloud Run:**
- Function execution time > 9 minutes (scheduled functions)
- Need for WebSockets (real-time bidirectional communication)
- Custom runtime (not Node.js, Python, Go)

**Timeline:** Reevaluate at Month 12 (unlikely to need Cloud Run)

---

## Stakeholder Sign-Off

- [ ] **Engineering Leadership**
- [ ] **Backend Lead** (confirm Cloud Functions sufficient)

**Timeline:** Finalized by 2025-10-31

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial Cloud Functions decision | Stage 2.1 Execution |

# ADR-024: Observability Stack

**Status:** Approved (Revised 2026-02-08)
**Date:** 2025-10-24
**Decision Makers:** Engineering Leadership, DevOps/SRE
**Related Documents:** TECH-STACK-001, ADR-005, ADR-007

---

## Context

Observability strategy for Abundance MVP: logging, monitoring, analytics, error tracking

---

## Decision

**We will use GCP native observability services (Cloud Logging, Cloud Monitoring) combined with Firebase Analytics and Crashlytics.**

### Observability Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Backend Logging** | Cloud Logging | Cloud Functions logs, AI Pipeline (Gemini 3 Pro) API calls |
| **Backend Monitoring** | Cloud Monitoring | Latency, error rate, AI Pipeline success rate |
| **iOS Analytics** | Firebase Analytics | User events, funnels, retention |
| **iOS Crash Tracking** | Firebase Crashlytics | App crashes, non-fatal errors |
| **Alerting** | Cloud Monitoring Alerts | PagerDuty/Slack notifications |

---

## Rationale

### 1. Zero Configuration (Firebase Integration)

**Cloud Logging:**
- Automatic for Cloud Functions (stdout/stderr → Cloud Logging)
- No setup required

**Firebase Analytics:**
```swift
// iOS: 2 lines of code
FirebaseApp.configure()
Analytics.logEvent("item_cataloged", parameters: ["tier": "free"])
```

**Alternative (Self-Hosted):**
- Grafana + Prometheus + Loki = 2-4 weeks setup
- Requires server maintenance

---

### 2. Free Tier Covers MVP

**Costs (Month 6, 5K users):**
- Cloud Logging: 50 GB/month (free tier), $0
- Cloud Monitoring: Free for Firebase projects
- Firebase Analytics: Unlimited events, $0
- Crashlytics: Unlimited crash reports, $0

**Total:** $0/month

---

### 3. Key Metrics to Track

#### Backend Metrics (Cloud Monitoring)

| Metric | Target | Alert |
|--------|--------|-------|
| AI Pipeline success rate | >95% | <90% |
| AI Pipeline latency (p95) | <5 sec | >8 sec |
| `onItemCreatedGemini3` invocations/hour | Baseline TBD | 10x spike |
| Firestore read/write quota | <80% of free tier | >90% |
| Cloud Functions error rate | <1% | >5% |

#### iOS Metrics (Firebase Analytics)

| Event | Purpose |
|-------|---------|
| `item_cataloged` | Track free tier usage |
| `item_enriched` | Track premium tier success |
| `subscription_started` | Track premium conversion |
| `subscription_cancelled` | Track churn |
| `search_performed` | Track inventory search usage |

#### Funnels (Firebase Analytics)

1. **Onboarding Funnel:** App open → Photo taken → First item cataloged
2. **Premium Conversion:** Free user → View upgrade prompt → Start subscription
3. **Retention:** D1 → D7 → D30 → D90

---

## Alternatives Considered

### Alternative 1: DataDog / New Relic (APM)

**Pros:**
- More features (distributed tracing, custom dashboards)
- Better alerting (anomaly detection)

**Cons:**
- **Cost:** $15-31/host/month (vs. $0 GCP native)
- **Overkill:** MVP doesn't need APM (14 Cloud Functions, straightforward architecture)

**Why Rejected:** GCP native tools are free and sufficient for MVP

---

### Alternative 2: Self-Hosted (Grafana + Prometheus + Loki)

**Pros:**
- Full control, no vendor lock-in
- Open-source

**Cons:**
- **Setup time:** 2-4 weeks (vs. 1 day GCP native)
- **Maintenance:** Requires DevOps engineer (startup has none)
- **Cost:** Server costs ($50-100/month)

**Why Rejected:** GCP native is faster, cheaper, zero maintenance

---

## Monitoring Dashboard (Cloud Monitoring)

### Dashboard 1: AI Pipeline Health

```yaml
- AI Pipeline Success Rate (%)
  - Green: >95%
  - Yellow: 90-95%
  - Red: <90%

- AI Pipeline Latency (p95)
  - Green: <5 sec
  - Yellow: 5-8 sec
  - Red: >8 sec

- Tool Call Success Rate (%)   # google_lens, barcode_lookup, web_search
  - Green: >80%
  - Yellow: 60-80%
  - Red: <60%
```

### Dashboard 2: User Engagement

```yaml
- Daily Active Users (DAU)
- Items Cataloged per Day
- Free vs Premium Split (target: 30% premium)
- Average Items per User (target: 50)
```

### Dashboard 3: Cost Tracking

```yaml
- AI Pipeline Cost per Day (Gemini 3 Pro + tool calls)
- Firebase Storage Cost per Day
- Cloud Functions Invocations (% of free tier quota)
- Firestore Reads/Writes (% of free tier quota)
```

---

## Alerting Strategy

### Critical Alerts (PagerDuty)

| Alert | Condition | Action |
|-------|-----------|--------|
| AI Pipeline down | Success rate < 90% for 15 min | Page on-call engineer |
| Firestore quota exceeded | >95% of free tier | Upgrade to Blaze plan |
| Cloud Functions error spike | Error rate > 10% for 5 min | Page on-call engineer |

### Warning Alerts (Slack)

| Alert | Condition | Action |
|-------|-----------|--------|
| AI Pipeline latency high | p95 > 8 sec for 30 min | Investigate, may need optimization |
| Tool call failure rate high | >20% of tool calls failing | Check SerpAPI/barcode service health |
| Cost anomaly | Daily cost > $50 (expected: $20) | Investigate runaway costs |

---

## Logging Strategy

### Log Levels

**ERROR:**
- AI Pipeline failures (Gemini API timeout, 5xx, tool call failures)
- Authentication errors (invalid JWT)
- Firestore write failures

**WARN:**
- Tool call failures (Google Lens, barcode lookup, web search)
- Low confidence detections
- Rate limit warnings (approaching quota)

**INFO:**
- Successful cataloging (item processed by Gemini 3 Pro)
- User signups
- Subscription changes

**DEBUG (Staging Only):**
- Request/response payloads (Gemini API, tool calls)
- Firestore queries

### Structured Logging (JSON)

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

## Stakeholder Sign-Off

- [ ] **Engineering Leadership**
- [ ] **DevOps/SRE** (if available, otherwise Engineering Lead)

**Timeline:** Finalized by 2025-10-31

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial observability stack | Stage 2.1 Execution |
| 2026-02-08 | 1.1 | Replaced all "Shopping Graph" references with "AI Pipeline" (Gemini 3 Pro), fixed ADR-012 reference to ADR-007, updated function count | Documentation Agent |

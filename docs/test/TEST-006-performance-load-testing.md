# TEST-006: Performance & Load Testing

**Extends**: TEST-STRATEGY-001
**Sprint**: 8 (Testing, Polish & TestFlight Launch)
**Scope**: iOS app performance + Backend scalability
**Last Updated**: 2025-11-12

---

## Purpose

Validate performance targets and load handling before TestFlight launch. Ensures MVP meets latency, throughput, and scalability requirements per DESIGN-030 (Performance Requirements).

**Referenced by**: ios-sprint-executor (Sprint 8 acceptance criteria)

---

## Performance Targets

### iOS App (Client-Side)

| Metric | Target | P0 Threshold | Tool |
|--------|--------|--------------|------|
| Cold start | < 2s | < 3s | Xcode Instruments |
| Warm start | < 1s | < 1.5s | Xcode Instruments |
| Catalog scroll FPS | 60fps | 55fps | Core Animation Profiler |
| Image load (cached) | < 100ms | < 200ms | Kingfisher metrics |
| Image load (network) | < 500ms | < 1s | Kingfisher metrics |
| Search response | < 200ms | < 500ms | SwiftUI profiling |
| Memory usage | < 150MB | < 200MB | Memory Graph |

### Backend (Cloud Functions)

| Metric | Target | P0 Threshold | Tool |
|--------|--------|--------------|------|
| Health endpoint | < 100ms | < 200ms | Firebase console |
| User profile fetch | < 300ms | < 500ms | Firebase console |
| AI pipeline (Layer 1-3) | < 10s | < 15s | Cloud Functions logs |
| Barcode lookup | < 500ms | < 1s | UPCitemdb API logs |
| Visual search | < 2s | < 3s | SerpAPI logs |
| Firestore write | < 100ms | < 200ms | Firestore metrics |

---

## iOS Performance Testing

### 1. Launch Time Testing (Xcode Instruments)

**Tool**: Time Profiler

**Steps**:
1. Close app completely (force quit)
2. Launch Xcode Instruments → Time Profiler
3. Profile app launch
4. Record time from tap to first frame

**Expected**:
- Cold start (no cache): < 2s
- Warm start (cached): < 1s

**Test Code** (XCTest):
```swift
func testAppLaunchPerformance() {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
    }
}
```

**Pass Criteria**: Average < 2s over 10 launches

---

### 2. Scrolling Performance (Core Animation Profiler)

**Tool**: Xcode Instruments → Core Animation

**Steps**:
1. Load catalog with 50 items
2. Start Core Animation profiler
3. Scroll rapidly top to bottom
4. Record FPS

**Expected**: 60fps consistent (no dropped frames)

**Optimization** (if FPS < 60):
- Enable SwiftUI lazy loading: `LazyVGrid` instead of `VGrid`
- Cache images via Kingfisher
- Reduce view complexity (avoid nested ForEach)

---

### 3. Memory Profiling (Memory Graph)

**Tool**: Xcode Instruments → Leaks & Allocations

**Steps**:
1. Launch app
2. Capture 10 items (camera + AI pipeline)
3. Navigate catalog → item detail → edit → save (10 times)
4. Record memory usage

**Expected**:
- Peak memory: < 150MB
- No memory leaks detected

**Common Leaks**:
- AVCaptureSession not released (retain cycle)
- Firebase listeners not removed (@escaping closures)
- Kingfisher cache unbounded (configure max size)

---

## Backend Performance Testing

### 1. Health Check Latency (Artillery Load Test)

**Tool**: Artillery (npm package)

**Install**:
```bash
npm install -g artillery
```

**Load Test Config** (`backend/test/load/health-check.yml`):
```yaml
config:
  target: 'https://us-central1-abundance-mvp.cloudfunctions.net'
  phases:
    - duration: 60
      arrivalRate: 10  # 10 req/sec for 60s = 600 total
  processor: './custom-functions.js'

scenarios:
  - name: "Health Check"
    flow:
      - get:
          url: "/health"
          expect:
            - statusCode: 200
            - contentType: json
            - hasProperty: status
```

**Execution**:
```bash
cd backend/test/load
artillery run health-check.yml
```

**Expected Output**:
```
Summary:
  Scenarios launched: 600
  Scenarios completed: 600
  Requests completed: 600
  Mean response time: 85ms
  P95 response time: 120ms
  P99 response time: 180ms
  Errors: 0
```

**Pass Criteria**:
- Mean < 100ms
- P95 < 200ms
- 0 errors

---

### 2. AI Pipeline Load Test

**Scenario**: 10 concurrent users capturing items (full Layer 1-3 pipeline)

**Load Test Config** (`backend/test/load/ai-pipeline.yml`):
```yaml
config:
  target: 'https://us-central1-abundance-mvp.cloudfunctions.net'
  phases:
    - duration: 120
      arrivalRate: 1  # 1 user/sec for 2 min = 120 users
  processor: './custom-functions.js'

scenarios:
  - name: "Capture Item (AI Pipeline)"
    flow:
      - post:
          url: "/processImage"
          json:
            userId: "test-user-{{ $randomString() }}"
            imageUrl: "gs://bucket/test-banana.jpg"
          expect:
            - statusCode: 200
            - hasProperty: itemId
          capture:
            - json: "$.processingTime"
              as: "processingTime"
      - log: "AI processing time: {{ processingTime }}ms"
```

**Expected Output**:
```
Summary:
  Scenarios launched: 120
  Scenarios completed: 118 (2 timeouts)
  Mean response time: 8200ms
  P95 response time: 12000ms
  P99 response time: 14500ms
  Errors: 2 (timeout after 15s)
```

**Pass Criteria**:
- Mean < 10s
- P95 < 15s
- < 5% error rate

---

### 3. Firestore Query Performance

**Test**: Catalog fetch for user with 100 items

**Test Code** (`backend/functions/test/load/firestore-load.test.ts`):
```typescript
import { expect } from 'chai';
import * as admin from 'firebase-admin';

describe('Firestore Query Performance', () => {
  it('should fetch 100 items in < 500ms', async () => {
    const startTime = Date.now();

    const items = await admin.firestore()
      .collection('items')
      .where('userId', '==', 'test-user-100-items')
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    const duration = Date.now() - startTime;

    expect(items.docs.length).to.equal(100);
    expect(duration).to.be.lessThan(500); // 500ms target
  });

  it('should handle 50 concurrent queries without throttling', async () => {
    const promises = Array(50).fill(null).map(() =>
      admin.firestore()
        .collection('items')
        .where('userId', '==', 'test-user-50-concurrent')
        .get()
    );

    const startTime = Date.now();
    await Promise.all(promises);
    const duration = Date.now() - startTime;

    expect(duration).to.be.lessThan(3000); // 3s total for 50 queries
  });
});
```

**Expected**: Query time < 500ms (single query), < 3s (50 concurrent)

---

## Load Testing Scenarios

### Scenario 1: Onboarding Spike (100 users/hour)

**Simulation**: TestFlight launch day, 100 users sign in within first hour

**Target Endpoints**:
- `/createUser` (POST): User profile creation
- `/getUserProfile` (GET): Profile fetch

**Load Config**:
```yaml
config:
  phases:
    - duration: 3600  # 1 hour
      arrivalRate: 0.028  # 100 users / 3600s ≈ 0.028/s
```

**Pass Criteria**:
- Mean response time < 500ms
- Zero Firebase quota errors
- All users created successfully

---

### Scenario 2: Peak Usage (50 concurrent captures)

**Simulation**: 50 users simultaneously capturing items during dinner prep (6pm peak)

**Load Config**:
```yaml
config:
  phases:
    - duration: 300  # 5 minutes
      arrivalRate: 10  # 10 captures/sec
```

**Pass Criteria**:
- AI pipeline completes < 15s for 95% of requests
- No Cloud Functions cold start delays (> 3s)
- Gemini/Claude API rate limits not hit

---

### Scenario 3: Database Growth (1000 items per user)

**Simulation**: Power user with 1000 catalog items (edge case)

**Test**:
1. Pre-populate Firestore with 1000 items for test user
2. Execute catalog fetch query
3. Measure query time + client render time

**Expected**:
- Query time < 1s (indexed query)
- Client render time < 2s (lazy loading)
- Pagination working (fetch 20 items at a time)

**Firestore Index Required**:
```json
{
  "collectionGroup": "items",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

---

## Stress Testing

### Firebase Quota Limits

**Free Tier Limits** (Spark plan):
- Firestore reads: 50K/day
- Firestore writes: 20K/day
- Cloud Functions invocations: 2M/month
- Storage: 5GB

**Test**: Simulate 200 users over 24 hours, verify quotas not exceeded

**Monitoring**:
```bash
# Check Firebase usage
firebase projects:list
gcloud logging read "resource.type=cloud_function" --limit 1000 --format json
```

**Pass Criteria**: < 80% of daily limits used (safety buffer)

---

## CI Integration (GitHub Actions)

**File**: `.github/workflows/performance-tests.yml`

```yaml
name: Performance Tests

on:
  pull_request:
    branches: [main]
    paths:
      - 'backend/functions/**'

jobs:
  load-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Artillery
        run: npm install -g artillery

      - name: Deploy to Staging
        env:
          GOOGLE_APPLICATION_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}
        run: |
          cd backend/functions
          firebase use staging
          firebase deploy --only functions

      - name: Run Load Tests
        run: |
          cd backend/test/load
          artillery run health-check.yml
          artillery run ai-pipeline.yml

      - name: Upload Artillery Reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: artillery-reports
          path: backend/test/load/reports/
```

---

## Success Metrics

Sprint 8 acceptance criteria:
- [ ] iOS app launch time < 2s (cold start)
- [ ] Catalog scroll FPS ≥ 60fps
- [ ] Backend health check < 100ms (mean)
- [ ] AI pipeline < 10s (mean), < 15s (P95)
- [ ] No memory leaks in iOS app
- [ ] Firebase quotas < 80% during load test
- [ ] Zero errors during 600-request load test

---

## References

- **DESIGN-030**: Performance Requirements (latency targets)
- **ADR-006**: AI Provider Selection (10s AI pipeline target)
- **COST-MODEL-001**: Firebase quota limits
- **TEST-STRATEGY-001**: Overall test strategy
- **SPRINT-PLAN-008**: Sprint 8 deliverables (performance validation)

---

**Last Updated**: 2025-11-12
**Validated**: Sprint 8 acceptance criteria
**Tools**: Xcode Instruments, Artillery, Firebase Console

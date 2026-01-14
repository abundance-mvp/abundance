# DESIGN-042: Layer 2a Error Handling

**Created**: 2025-11-11
**Stage**: 3.4 - Layer 2a Attribute Extraction Implementation Research
**Status**: Complete
**References**:
- docs/design/CODE-EXAMPLE-010-vertex-ai-attribute-extraction.md (error classes)
- docs/design/CODE-EXAMPLE-011-layer-2a-cloud-function.md (Cloud Function integration)
- docs/validation/RESEARCH-VALIDATION-stage-3.4.md (verified error codes)

---

## Overview

This document specifies the complete error handling strategy for Layer 2a attribute extraction, including error taxonomy, retry strategies, exponential backoff implementation, dead letter queue design, and monitoring alerts.

**Key Principles**:
- Fail fast for non-retryable errors (invalid arguments, quota exceeded)
- Retry with exponential backoff for transient errors (rate limits, timeouts)
- Dead letter queue for permanent failures (manual intervention required)
- Comprehensive monitoring and alerting (error rate >5% triggers alert)

**Research Foundation**: All error codes and retry patterns verified against Google Cloud documentation (RESEARCH-VALIDATION-stage-3.4.md). Testing shows 80% failure without retry vs 100% success with exponential backoff.

---

## Error Taxonomy

### Error Classification Table

| Error Code | HTTP Status | Meaning | Retryable? | Max Retries | Backoff Strategy |
|------------|-------------|---------|------------|-------------|------------------|
| **429** | 429 | Rate limit exceeded | ✅ Yes | 5 | Exponential (1s, 2s, 4s, 8s, 16s) |
| **RESOURCE_EXHAUSTED** | 429 | Same as 429 (gRPC status) | ✅ Yes | 5 | Exponential |
| **QUOTA_EXCEEDED** | 429 | Daily/monthly quota reached | ❌ No | 0 | Alert team, wait for reset |
| **DEADLINE_EXCEEDED** | 504 | Request timeout (30s default) | ✅ Yes | 3 | Exponential (1s, 2s, 4s) |
| **UNAVAILABLE** | 503 | Transient network error | ✅ Yes | 5 | Exponential |
| **INVALID_ARGUMENT** | 400 | Malformed request (bad image URL) | ❌ No | 0 | Log error, skip item |
| **NOT_FOUND** | 404 | Image URL not found | ❌ No | 0 | Log error, skip item |
| **INTERNAL** | 500 | Server error | ✅ Yes | 3 | Exponential |
| **PERMISSION_DENIED** | 403 | Auth failure (bad credentials) | ❌ No | 0 | Alert team immediately |
| **UNAUTHENTICATED** | 401 | Missing auth credentials | ❌ No | 0 | Alert team immediately |

---

## Exponential Backoff Implementation

### Retry Strategy

**Formula**: `delay = min(2^attempt × 1000ms, 60000ms)`

**Delay Sequence**:
- Attempt 0 (first try): No delay
- Attempt 1 (1st retry): 1,000ms (1s)
- Attempt 2 (2nd retry): 2,000ms (2s)
- Attempt 3 (3rd retry): 4,000ms (4s)
- Attempt 4 (4th retry): 8,000ms (8s)
- Attempt 5 (5th retry): 16,000ms (16s)
- Attempt 6+ (capped): 60,000ms (60s)

**Total Time** (5 retries): 0s + 1s + 2s + 4s + 8s + 16s = **31 seconds**

---

### Code Implementation

```javascript
/**
 * Retry function with exponential backoff
 *
 * @param {Function} fn - Async function to retry
 * @param {number} maxRetries - Maximum retry attempts (default: 5)
 * @returns {Promise<any>} Function result
 * @throws {Error} Original error if all retries exhausted
 */
async function retryWithExponentialBackoff(fn, maxRetries = 5) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      // Check if error is retryable
      const isRetryable = error.retryable || isTransientError(error);

      if (!isRetryable) {
        logger.warn(`Non-retryable error, failing immediately`, {
          error: error.message,
          code: error.code
        });
        throw error;
      }

      // Don't retry if last attempt
      if (attempt === maxRetries - 1) {
        logger.error(`Max retries (${maxRetries}) exhausted`, {
          error: error.message,
          code: error.code
        });
        throw error;
      }

      // Calculate backoff delay (capped at 60s)
      const delay = Math.min(Math.pow(2, attempt) * 1000, 60000);

      logger.warn(`Retry ${attempt + 1}/${maxRetries} after ${delay}ms`, {
        error: error.message,
        code: error.code,
        retryable: true
      });

      // Wait before retry
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

/**
 * Check if error is transient (retryable)
 *
 * @param {Error} error - Error object
 * @returns {boolean} True if transient
 */
function isTransientError(error) {
  const transientCodes = [
    429, // Rate limit
    503, // Unavailable
    504, // Timeout
    'RESOURCE_EXHAUSTED',
    'DEADLINE_EXCEEDED',
    'UNAVAILABLE',
    'INTERNAL'
  ];

  return transientCodes.includes(error.code) ||
         transientCodes.includes(error.status);
}
```

---

## Error Handling by Type

### 1. Rate Limit (429 / RESOURCE_EXHAUSTED)

**Scenario**: Too many requests in short time window

**Detection**:
```javascript
if (error.code === 429 || error.status === 'RESOURCE_EXHAUSTED') {
  // Rate limit error
}
```

**Strategy**:
- Retryable: ✅ Yes
- Max retries: 5
- Backoff: Exponential (1s, 2s, 4s, 8s, 16s)
- Expected success: 100% (verified by Google research)

**Example**:
```javascript
class RateLimitError extends GeminiError {
  constructor(message, originalError) {
    super(message, originalError);
    this.name = 'RateLimitError';
    this.code = 429;
    this.retryable = true;
  }
}
```

**Logging**:
```javascript
logger.warn(`Rate limit exceeded for item ${itemId}, retrying`, {
  attempt: currentAttempt,
  maxRetries: 5,
  nextDelayMs: delay
});
```

---

### 2. Quota Exceeded (QUOTA_EXCEEDED)

**Scenario**: Daily or monthly API quota exhausted

**Detection**:
```javascript
if (error.code === 'QUOTA_EXCEEDED' || error.message?.includes('quota')) {
  // Quota exceeded
}
```

**Strategy**:
- Retryable: ❌ No (cannot retry until quota resets)
- Max retries: 0
- Action: Alert engineering team, wait for daily/monthly reset
- Impact: All new items will fail until quota resets

**Example**:
```javascript
class QuotaExceededError extends GeminiError {
  constructor(message, originalError) {
    super(message, originalError);
    this.name = 'QuotaExceededError';
    this.code = 'QUOTA_EXCEEDED';
    this.retryable = false;
  }
}
```

**Alert Policy**:
```javascript
// Send immediate alert to team
await sendAlert({
  severity: 'CRITICAL',
  title: 'Gemini API Quota Exceeded',
  message: `Layer 2a processing blocked. Daily/monthly quota exhausted.`,
  action: 'Investigate quota limits, request increase, or wait for reset'
});
```

---

### 3. Timeout (DEADLINE_EXCEEDED)

**Scenario**: Request exceeds 30s timeout

**Detection**:
```javascript
if (error.code === 'DEADLINE_EXCEEDED' || error.message?.includes('timeout')) {
  // Timeout error
}
```

**Strategy**:
- Retryable: ✅ Yes
- Max retries: 3 (fewer retries, likely persistent issue)
- Backoff: Exponential (1s, 2s, 4s)
- Root cause: Large image, network latency, or Gemini overload

**Example**:
```javascript
class TimeoutError extends GeminiError {
  constructor(message, originalError) {
    super(message, originalError);
    this.name = 'TimeoutError';
    this.code = 'DEADLINE_EXCEEDED';
    this.retryable = true;
  }
}
```

**Mitigation**:
- Monitor timeout frequency (should be <1% of requests)
- If timeout rate >5%, investigate image sizes or Gemini latency spikes

---

### 4. Network Error (UNAVAILABLE)

**Scenario**: Transient network connectivity issue

**Detection**:
```javascript
if (error.code === 'UNAVAILABLE' || error.status === 503) {
  // Network error
}
```

**Strategy**:
- Retryable: ✅ Yes
- Max retries: 5
- Backoff: Exponential
- Expected resolution: Automatic (network recovers)

**Example**:
```javascript
class NetworkError extends GeminiError {
  constructor(message, originalError) {
    super(message, originalError);
    this.name = 'NetworkError';
    this.code = 'UNAVAILABLE';
    this.retryable = true;
  }
}
```

---

### 5. Invalid Argument (INVALID_ARGUMENT)

**Scenario**: Malformed request (invalid image URL, bad schema)

**Detection**:
```javascript
if (error.code === 'INVALID_ARGUMENT' || error.status === 400) {
  // Invalid argument
}
```

**Strategy**:
- Retryable: ❌ No (request is fundamentally broken)
- Max retries: 0
- Action: Log error, add to dead letter queue, skip item
- Root cause: Bug in code or corrupted data

**Example**:
```javascript
class InvalidArgumentError extends GeminiError {
  constructor(message, originalError) {
    super(message, originalError);
    this.name = 'InvalidArgumentError';
    this.code = 'INVALID_ARGUMENT';
    this.retryable = false;
  }
}
```

**Dead Letter Queue**:
```javascript
await addToDeadLetterQueue(itemId, {
  layer: 'layer2a',
  errorCode: 'INVALID_ARGUMENT',
  errorMessage: error.message,
  imageUrl: itemData.imageUrl,
  failedAt: Timestamp.now()
});
```

---

### 6. Not Found (NOT_FOUND)

**Scenario**: Image URL does not exist (GCS object deleted)

**Detection**:
```javascript
if (error.code === 'NOT_FOUND' || error.status === 404) {
  // Image not found
}
```

**Strategy**:
- Retryable: ❌ No (image URL is invalid)
- Max retries: 0
- Action: Log error, skip item
- Root cause: Image deleted, expired signed URL, or incorrect URL

**Example**:
```javascript
class NotFoundError extends GeminiError {
  constructor(message, originalError) {
    super(message, originalError);
    this.name = 'NotFoundError';
    this.code = 'NOT_FOUND';
    this.retryable = false;
  }
}
```

---

## Dead Letter Queue Design

### Purpose

Dead letter queue captures permanently failed items for manual investigation and recovery.

### Firestore Collection: `failedItems`

**Schema**:
```javascript
{
  itemId: 'item_abc123',
  userId: 'user_xyz789',
  layer: 'layer2a', // Which layer failed
  errorMessage: 'Image not found: 404',
  errorCode: 'NOT_FOUND',
  failedAt: Timestamp,
  retryCount: 5, // How many retries attempted
  imageUrl: 'https://storage.googleapis.com/.../cropped.jpg',
  resolved: false, // Manual resolution flag
  resolvedAt: null,
  resolvedBy: null
}
```

---

### Dead Letter Queue Logic

```javascript
/**
 * Add failed item to dead letter queue
 *
 * @param {string} itemId - Item ID
 * @param {Object} failureData - Failure metadata
 * @returns {Promise<void>}
 */
async function addToDeadLetterQueue(itemId, failureData) {
  const failedItemsRef = db.collection('failedItems').doc(itemId);

  await failedItemsRef.set({
    itemId,
    userId: failureData.userId,
    layer: failureData.layer || 'layer2a',
    errorMessage: failureData.errorMessage,
    errorCode: failureData.errorCode,
    failedAt: FieldValue.serverTimestamp(),
    retryCount: failureData.retryCount || 0,
    imageUrl: failureData.imageUrl,
    resolved: false,
    resolvedAt: null,
    resolvedBy: null
  });

  logger.warn(`Added item ${itemId} to dead letter queue`, {
    errorCode: failureData.errorCode,
    layer: failureData.layer
  });
}
```

---

### Manual Recovery Process

**Steps**:
1. Query dead letter queue: `SELECT * FROM failedItems WHERE resolved = false`
2. Investigate error (check image URL, API credentials, quota)
3. Fix root cause (re-upload image, fix bug, request quota increase)
4. Mark as resolved:
   ```javascript
   await db.collection('failedItems').doc(itemId).update({
     resolved: true,
     resolvedAt: FieldValue.serverTimestamp(),
     resolvedBy: 'admin@example.com'
   });
   ```
5. Re-trigger processing (update item status to `pending_layer2a`)

---

## Monitoring & Alerts

### Alert Policy 1: High Error Rate

**Condition**: Error rate >5% over 5 minutes

**Query**:
```sql
SELECT
  COUNTIF(status = 'failed_layer2a') / COUNT(*) * 100 as error_rate_percent
FROM
  `abundance-prod.firestore.items`
WHERE
  updatedAt >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)
HAVING
  error_rate_percent > 5
```

**Action**:
- Send email to engineering team
- Post to Slack #alerts channel
- Severity: WARNING

---

### Alert Policy 2: Quota at 80%

**Condition**: Daily token usage >80% of quota

**Query**:
```sql
SELECT
  SUM(tokensUsed) as total_tokens_today
FROM
  `abundance-prod.firestore.ai_usage`
WHERE
  service = 'gemini-2.5-flash-lite'
  AND timestamp >= TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY)
HAVING
  total_tokens_today > 0.8 * 1000000000 -- 80% of 1B token quota
```

**Action**:
- Send email to engineering team
- Log warning in Cloud Logging
- Severity: INFO (proactive warning)

---

### Alert Policy 3: Dead Letter Queue Growing

**Condition**: >10 items in dead letter queue (unresolved)

**Query**:
```sql
SELECT
  COUNT(*) as unresolved_count
FROM
  `abundance-prod.firestore.failedItems`
WHERE
  resolved = false
HAVING
  unresolved_count > 10
```

**Action**:
- Send daily digest email
- Include error code breakdown
- Severity: INFO

---

### Alert Policy 4: Permission Denied

**Condition**: Single PERMISSION_DENIED or UNAUTHENTICATED error

**Action**:
- Send immediate alert (severity: CRITICAL)
- Indicates credentials expired or misconfigured
- Block all Layer 2a processing until resolved

---

## Error Metrics Dashboard

### Key Metrics

1. **Error Rate** (target: <5%)
   - Formula: `failed_layer2a / (failed_layer2a + layer2a_complete)`
   - Chart: Time series (last 24 hours)

2. **Error Breakdown by Code**
   - Chart: Pie chart (429, QUOTA_EXCEEDED, DEADLINE_EXCEEDED, etc.)
   - Filter: Last 7 days

3. **Retry Success Rate**
   - Formula: `successful_retries / total_retries`
   - Chart: Time series
   - Expected: >90% (exponential backoff should succeed)

4. **Dead Letter Queue Size**
   - Chart: Line chart (unresolved items over time)
   - Alert threshold: >10 items

5. **Average Retries per Request**
   - Formula: `total_retries / total_requests`
   - Chart: Time series
   - Expected: <0.2 (most requests succeed on first try)

---

## Production Scenarios

### Scenario 1: Rate Limit Spike (429)

**Trigger**: 10 items uploaded simultaneously

**Expected Behavior**:
1. First 5 items process successfully
2. Next 5 items hit rate limit (429 error)
3. Exponential backoff retries succeed within 16s
4. All 10 items eventually complete (100% success rate)

**Monitoring**:
- Latency increases (p95: 2s → 18s during backoff)
- No items in dead letter queue
- Error rate: 0% (retries succeed)

---

### Scenario 2: Quota Exceeded

**Trigger**: Daily quota reached at 11:00 PM

**Expected Behavior**:
1. First QUOTA_EXCEEDED error detected
2. Alert sent to engineering team (CRITICAL)
3. All subsequent items fail immediately (no retries)
4. Items added to dead letter queue
5. Processing resumes after midnight (quota reset)

**Monitoring**:
- Error rate: 100% (until quota resets)
- Dead letter queue grows rapidly
- Alert triggered within 1 minute

**Recovery**:
- Wait for quota reset (automatic at midnight UTC)
- Re-process dead letter queue items
- Request quota increase if recurring

---

### Scenario 3: Invalid Image URL (NOT_FOUND)

**Trigger**: iOS app uploads item with corrupted image URL

**Expected Behavior**:
1. Gemini API returns 404 NOT_FOUND
2. Error classified as non-retryable
3. Item added to dead letter queue immediately
4. Firestore updated with status: `failed_layer2a`
5. No retries attempted

**Monitoring**:
- Error rate: Increases by 1 item (not significant)
- Dead letter queue: +1 item
- Root cause investigation: Check image URL validity

**Recovery**:
- Fix iOS app bug (ensure valid GCS URLs)
- Re-upload image for affected item
- Mark as resolved in dead letter queue

---

## Acceptance Criteria

- [x] Complete error taxonomy (all verified error codes documented)
- [x] Retry strategy per error type (retryable vs non-retryable)
- [x] Exponential backoff implementation (2^i × 1000ms, max 60s)
- [x] Dead letter queue design (failedItems collection)
- [x] Monitoring alerts (error rate >5%, quota at 80%)
- [x] Error classes defined (RateLimitError, QuotaExceededError, etc.)
- [x] Code examples for all error scenarios
- [x] Production scenario documentation
- [x] Recovery procedures documented

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0 | Initial error handling design | Computer Vision & ML Engineer |

---

**Next Document**: BENCHMARK-002 (Layer 2a Accuracy Methodology)

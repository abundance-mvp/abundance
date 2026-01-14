# DESIGN-043: Layer 3 Error Handling

**Created**: 2025-11-11
**Stage**: 3.6 - Layer 3 AI Synthesis Implementation Research
**Status**: Complete
**References**:
- docs/design/CODE-EXAMPLE-016-claude-sonnet-synthesis.md (synthesis function)
- docs/design/DESIGN-042-layer-2a-error-handling.md (error handling patterns)
- docs/validation/RESEARCH-VALIDATION-stage-3.6.md (verified error codes)
- docs/plans/2025-11-11-stage-3.6-layer-3-ai-synthesis-implementation-research.md (Task 5)

---

## Overview

This document specifies the complete error handling strategy for Layer 3 AI synthesis using Claude Sonnet 4.5, including error taxonomy, retry strategies, exponential backoff implementation, fallback mechanisms, dead letter queue design, and monitoring alerts.

**Key Principles**:
- Fail fast for non-retryable errors (missing Layer 2 data, invalid arguments)
- Retry with exponential backoff for transient errors (rate limits, overloaded API)
- Graceful degradation for synthesis failures (use Layer 2 data without synthesis)
- Comprehensive monitoring and alerting (synthesis failure rate >10% triggers alert)

**Research Foundation**: All error codes and retry patterns verified against Anthropic API documentation (RESEARCH-VALIDATION-stage-3.6.md). Claude Sonnet 4.5 Batch API has different error patterns than Gemini Vision API.

---

## Error Taxonomy

### Error Classification Table

| Error Code | HTTP Status | Meaning | Retryable? | Max Retries | Backoff Strategy |
|------------|-------------|---------|------------|-------------|------------------|
| **429** | 429 | Rate limit exceeded | ✅ Yes | 3 | Exponential (60s, 120s, 240s) |
| **529** | 529 | API overloaded | ✅ Yes | 3 | Exponential (30s, 60s, 120s) |
| **TIMEOUT** | 504 | Request timeout (>30s) | ✅ Yes | 1 | Extended timeout (60s) |
| **SCHEMA_VALIDATION** | 400 | Invalid JSON schema definition | ❌ No | 0 | Alert team, fix schema |
| **MALFORMED_JSON** | 200 | JSON parsing failed | ❌ No | 0 | Regex extraction fallback |
| **MISSING_LAYER2_DATA** | - | Layer 2a or 2b incomplete | ❌ No | 0 | Skip synthesis, mark failed |
| **INVALID_ARGUMENT** | 400 | Malformed request | ❌ No | 0 | Log error, dead letter queue |
| **PERMISSION_DENIED** | 403 | Auth failure (bad API key) | ❌ No | 0 | Alert team immediately |
| **INVALID_API_KEY** | 401 | Missing/invalid Anthropic key | ❌ No | 0 | Alert team immediately |

---

## Layer 3 Error Handling Patterns

### 1. Missing Layer 2 Data

**Scenario**: Layer 2a or Layer 2b processing incomplete or failed

**Detection**:
```javascript
if (!layer2a || !layer2a.category || !layer2a.confidence) {
  throw new MissingLayer2DataError('Layer 2a data incomplete');
}

if (!layer2b || !layer2b.source) {
  throw new MissingLayer2DataError('Layer 2b data incomplete');
}
```

**Strategy**:
- Retryable: ❌ No (data dependency issue, not transient error)
- Max retries: 0
- Action: Skip synthesis, mark item as `failed_layer3`, log error
- Impact: Item remains cataloged with Layer 1 + Layer 2 data only

**Error Class**:
```javascript
class MissingLayer2DataError extends Error {
  constructor(message) {
    super(message);
    this.name = 'MissingLayer2DataError';
    this.retryable = false;
    this.severity = 'ERROR';
  }
}
```

**Firestore Update**:
```javascript
await itemRef.update({
  status: 'failed_layer3',
  error: {
    code: 'MISSING_LAYER2_DATA',
    message: error.message,
    timestamp: FieldValue.serverTimestamp()
  },
  metadata: {
    // Use Layer 2a + 2b without synthesis
    ...layer2a,
    ...layer2b.product,
    confidence: 'low',
    synthesized: false,
    requiresReview: true
  }
});
```

**Logging**:
```javascript
logger.error(`Layer 3 synthesis skipped: Missing Layer 2 data`, {
  itemId,
  layer2aPresent: !!layer2a,
  layer2bPresent: !!layer2b,
  action: 'using_layer2_fallback'
});
```

---

### 2. Rate Limit (429)

**Scenario**: Claude API rate limit exceeded (too many requests in short time window)

**Detection**:
```javascript
if (error.status === 429 || error.error?.type === 'rate_limit_error') {
  // Rate limit error
}
```

**Strategy**:
- Retryable: ✅ Yes
- Max retries: 3
- Backoff: Exponential (60s, 120s, 240s)
- Expected success: >95% (longer backoff than Layer 2a due to Claude API limits)

**Error Class**:
```javascript
class RateLimitError extends Error {
  constructor(message, originalError) {
    super(message);
    this.name = 'RateLimitError';
    this.status = 429;
    this.retryable = true;
    this.originalError = originalError;
  }
}
```

**Exponential Backoff**:
```javascript
async function synthesizeWithRateLimitRetry(layer2a, layer2b, detectedLabel, itemId, retryCount = 0) {
  try {
    return await synthesizeWithClaude(layer2a, layer2b, detectedLabel, itemId);
  } catch (error) {
    if (error.status === 429 && retryCount < 3) {
      // Exponential backoff: 60s, 120s, 240s
      const delay = Math.pow(2, retryCount) * 60000; // 60s base delay

      logger.warn(`Rate limit hit, retrying in ${delay}ms`, {
        itemId,
        attempt: retryCount + 1,
        maxRetries: 3
      });

      await sleep(delay);
      return synthesizeWithRateLimitRetry(layer2a, layer2b, detectedLabel, itemId, retryCount + 1);
    }
    throw error; // Re-throw if not retryable or max retries exceeded
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

**Logging**:
```javascript
logger.warn(`Claude API rate limit exceeded for item ${itemId}`, {
  attempt: currentAttempt,
  maxRetries: 3,
  nextDelayMs: delay,
  errorType: 'rate_limit_error'
});
```

---

### 3. Overloaded (529)

**Scenario**: Claude API overloaded (high traffic, capacity issues)

**Detection**:
```javascript
if (error.status === 529 || error.error?.type === 'overloaded_error') {
  // API overloaded
}
```

**Strategy**:
- Retryable: ✅ Yes
- Max retries: 3
- Backoff: Exponential (30s, 60s, 120s)
- Expected success: >90% (shorter backoff than rate limit, usually resolves quickly)

**Error Class**:
```javascript
class OverloadedError extends Error {
  constructor(message, originalError) {
    super(message);
    this.name = 'OverloadedError';
    this.status = 529;
    this.retryable = true;
    this.originalError = originalError;
  }
}
```

**Exponential Backoff**:
```javascript
async function synthesizeWithOverloadRetry(layer2a, layer2b, detectedLabel, itemId, retryCount = 0) {
  try {
    return await synthesizeWithClaude(layer2a, layer2b, detectedLabel, itemId);
  } catch (error) {
    if (error.error?.type === 'overloaded_error' && retryCount < 3) {
      // Exponential backoff: 30s, 60s, 120s
      const delay = Math.pow(2, retryCount) * 30000; // 30s base delay

      logger.warn(`Claude API overloaded, retrying in ${delay}ms`, {
        itemId,
        attempt: retryCount + 1,
        maxRetries: 3
      });

      await sleep(delay);
      return synthesizeWithOverloadRetry(layer2a, layer2b, detectedLabel, itemId, retryCount + 1);
    }
    throw error;
  }
}
```

**Logging**:
```javascript
logger.warn(`Claude API overloaded for item ${itemId}`, {
  attempt: currentAttempt,
  maxRetries: 3,
  nextDelayMs: delay,
  errorType: 'overloaded_error'
});
```

---

### 4. Schema Validation Error

**Scenario**: JSON schema definition invalid or contains unsupported features

**Detection**:
```javascript
if (error.status === 400 && error.message?.includes('schema')) {
  // Schema validation error
}
```

**Strategy**:
- Retryable: ❌ No (schema definition issue, not transient error)
- Max retries: 0
- Action: Alert team immediately, fix schema definition
- Impact: All Layer 3 synthesis blocked until schema fixed

**Error Class**:
```javascript
class SchemaValidationError extends Error {
  constructor(message, originalError) {
    super(message);
    this.name = 'SchemaValidationError';
    this.status = 400;
    this.retryable = false;
    this.severity = 'CRITICAL';
    this.originalError = originalError;
  }
}
```

**Common Causes**:
- Using unsupported JSON Schema features (e.g., `minLength`, `maxLength`, `minimum`, `maximum`)
- Recursive schema definitions
- External `$ref` references
- Complex regex patterns with backreferences

**Logging**:
```javascript
logger.error(`Schema validation failed - invalid schema definition`, {
  errorMessage: error.message,
  schemaPreview: JSON.stringify(schema).substring(0, 500),
  action: 'blocking_all_layer3_synthesis'
});
```

**Alert**:
Send CRITICAL alert to engineering team immediately (schema error blocks all synthesis).

---

### 5. Malformed JSON Response

**Scenario**: Structured output JSON parsing fails (rare edge case)

**Detection**:
```javascript
try {
  const responseText = message.content[0].text;
  synthesized = JSON.parse(responseText);
} catch (parseError) {
  // JSON parsing failed, use fallback
}
```

**Strategy**:
- Retryable: ❌ No (use fallback extraction, don't waste tokens re-requesting)
- Max retries: 0
- Action: Regex extraction fallback, log warning
- Expected frequency: ~1-5% edge cases (native validation is highly reliable)

**Error Class**:
```javascript
class MalformedJSONError extends Error {
  constructor(message, responseText) {
    super(message);
    this.name = 'MalformedJSONError';
    this.retryable = false;
    this.responseText = responseText;
  }
}
```

**Regex Extraction Fallback**:
```javascript
/**
 * Extract synthesis output from Claude response with fallback
 *
 * @param {Object} message - Claude API response message
 * @param {string} itemId - Item ID for logging
 * @returns {Object} Synthesized metadata
 * @throws {MalformedJSONError} If all extraction methods fail
 */
function extractSynthesisOutput(message, itemId) {
  try {
    // Primary: Parse JSON from structured output
    const responseText = message.content[0].text;
    return JSON.parse(responseText);

  } catch (parseError) {
    // Fallback: Regex extraction from text (rare edge case)
    console.warn(`JSON parsing failed for item ${itemId}, falling back to regex extraction`);

    const responseText = message.content[0].text;
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);

    if (jsonMatch) {
      try {
        const parsed = JSON.parse(jsonMatch[0]);
        logger.warn(`Regex extraction succeeded for ${itemId}`, {
          extractedFields: Object.keys(parsed)
        });
        return parsed;
      } catch (regexError) {
        logger.error(`Regex JSON extraction failed for ${itemId}`, {
          rawText: responseText.substring(0, 200),
          error: regexError.message
        });
      }
    }

    // Final fallback: Extract key-value pairs manually
    const extracted = extractKeyValuePairs(responseText);
    if (Object.keys(extracted).length > 0) {
      logger.warn(`Used key-value extraction fallback for ${itemId}`, {
        extractedFields: Object.keys(extracted)
      });
      return extracted;
    }

    throw new MalformedJSONError('Failed to extract JSON from Claude response (parsing, regex, and key-value all failed)', responseText);
  }
}

/**
 * Extract key-value pairs from text (last resort fallback)
 *
 * @param {string} text - Raw text
 * @returns {Object} Extracted fields
 */
function extractKeyValuePairs(text) {
  const result = {};

  // Extract name
  const nameMatch = text.match(/"?name"?\s*:\s*"([^"]+)"/i);
  if (nameMatch) result.name = nameMatch[1];

  // Extract brand
  const brandMatch = text.match(/"?brand"?\s*:\s*"([^"]+)"/i);
  if (brandMatch) result.brand = brandMatch[1];

  // Extract estimatedValue
  const valueMatch = text.match(/"?estimatedValue"?\s*:\s*(\d+)/i);
  if (valueMatch) result.estimatedValue = parseInt(valueMatch[1], 10);

  // Extract confidence
  const confMatch = text.match(/"?confidence"?\s*:\s*"(high|medium|low)"/i);
  if (confMatch) result.confidence = confMatch[1];

  return result;
}
```

**Logging**:
```javascript
logger.warn(`Malformed JSON from Claude, using fallback extraction`, {
  itemId,
  rawTextPreview: text.substring(0, 200),
  extractionMethod: 'regex_fallback',
  extractedFields: Object.keys(synthesized)
});
```

---

### 6. Network Timeout

**Scenario**: Request exceeds 30s timeout (large prompt, slow API response)

**Detection**:
```javascript
if (error.code === 'ETIMEDOUT' || error.message?.includes('timeout')) {
  // Timeout error
}
```

**Strategy**:
- Retryable: ✅ Yes
- Max retries: 1 (single retry with extended timeout)
- Extended timeout: 60s (double default timeout)
- Expected success: >80% (most timeouts resolve with extended timeout)

**Error Class**:
```javascript
class TimeoutError extends Error {
  constructor(message, originalError) {
    super(message);
    this.name = 'TimeoutError';
    this.code = 'ETIMEDOUT';
    this.retryable = true;
    this.originalError = originalError;
  }
}
```

**Retry with Extended Timeout**:
```javascript
async function synthesizeWithTimeoutRetry(layer2a, layer2b, detectedLabel, itemId, retryCount = 0) {
  const timeout = retryCount === 0 ? 30000 : 60000; // 30s default, 60s retry

  try {
    const anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
      timeout: timeout
    });

    return await synthesizeWithClaude(layer2a, layer2b, detectedLabel, itemId, anthropic);
  } catch (error) {
    if ((error.code === 'ETIMEDOUT' || error.message?.includes('timeout')) && retryCount === 0) {
      logger.warn(`Timeout after ${timeout}ms, retrying with 60s timeout`, { itemId });
      return synthesizeWithTimeoutRetry(layer2a, layer2b, detectedLabel, itemId, retryCount + 1);
    }
    throw error;
  }
}
```

**Logging**:
```javascript
logger.warn(`Claude API timeout for item ${itemId}`, {
  timeoutMs: timeout,
  attempt: retryCount + 1,
  maxRetries: 1
});
```

---

## Unified Error Handling Function

### synthesizeWithErrorHandling

**Objective**: Single entry point for Layer 3 synthesis with all error handling logic

**Implementation**:
```javascript
/**
 * Synthesize item metadata with comprehensive error handling
 *
 * @param {Object} layer2a - Layer 2a attribute extraction result
 * @param {Object} layer2b - Layer 2b product search result
 * @param {string} detectedLabel - iOS detected label
 * @param {string} itemId - Item ID
 * @param {number} retryCount - Current retry attempt (default: 0)
 * @returns {Promise<Object>} Synthesized metadata
 * @throws {Error} Unrecoverable error after all retries exhausted
 */
async function synthesizeWithErrorHandling(layer2a, layer2b, detectedLabel, itemId, retryCount = 0) {
  // Validation: Check for missing Layer 2 data
  if (!layer2a || !layer2a.category || !layer2a.confidence) {
    throw new MissingLayer2DataError(`Layer 2a data incomplete for item ${itemId}`);
  }

  if (!layer2b || !layer2b.source) {
    throw new MissingLayer2DataError(`Layer 2b data incomplete for item ${itemId}`);
  }

  try {
    // Attempt synthesis
    return await synthesizeWithClaude(layer2a, layer2b, detectedLabel, itemId);

  } catch (error) {
    // 0. Schema Validation (400 with 'schema' in message)
    if (error.status === 400 && error.message?.includes('schema')) {
      logger.error(`Schema validation failed - critical error`, {
        itemId,
        errorMessage: error.message
      });

      // No retry - schema error blocks all synthesis
      throw new SchemaValidationError('Invalid JSON schema definition', error);
    }

    // 1. Rate Limit (429)
    if (error.status === 429 && retryCount < 3) {
      const delay = Math.pow(2, retryCount) * 60000; // 60s, 120s, 240s

      logger.warn(`Rate limit exceeded, retrying in ${delay}ms`, {
        itemId,
        attempt: retryCount + 1,
        maxRetries: 3
      });

      await sleep(delay);
      return synthesizeWithErrorHandling(layer2a, layer2b, detectedLabel, itemId, retryCount + 1);
    }

    // 2. Overloaded (529)
    if (error.error?.type === 'overloaded_error' && retryCount < 3) {
      const delay = Math.pow(2, retryCount) * 30000; // 30s, 60s, 120s

      logger.warn(`API overloaded, retrying in ${delay}ms`, {
        itemId,
        attempt: retryCount + 1,
        maxRetries: 3
      });

      await sleep(delay);
      return synthesizeWithErrorHandling(layer2a, layer2b, detectedLabel, itemId, retryCount + 1);
    }

    // 3. Timeout
    if ((error.code === 'ETIMEDOUT' || error.message?.includes('timeout')) && retryCount === 0) {
      logger.warn(`Timeout, retrying with extended timeout (60s)`, { itemId });

      // Retry once with 60s timeout
      return synthesizeWithTimeoutRetry(layer2a, layer2b, detectedLabel, itemId, 1);
    }

    // 4. Malformed JSON (already handled in synthesizeWithClaude function)
    // No retry needed, fallback extraction used

    // 5. Non-retryable errors
    logger.error(`Layer 3 synthesis failed after ${retryCount} retries`, {
      itemId,
      errorType: error.name,
      errorMessage: error.message,
      errorCode: error.status || error.code
    });

    throw error; // Propagate to fallback strategy
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

---

## Fallback Strategy

### Graceful Degradation

**Scenario**: Layer 3 synthesis fails after all retry attempts exhausted

**Strategy**:
```
IF Layer 3 synthesis fails (after 3 retries):
  → Use Layer 2a + Layer 2b data without synthesis
  → Set confidence = "low"
  → Mark item as "requires_review" = true
  → Log to dead letter queue for manual processing
  → Update Firestore with fallback metadata
```

**Implementation**:
```javascript
/**
 * Fallback strategy when Layer 3 synthesis fails
 *
 * @param {Object} layer2a - Layer 2a data
 * @param {Object} layer2b - Layer 2b data
 * @param {string} itemId - Item ID
 * @param {Error} error - Synthesis error
 * @returns {Object} Fallback metadata
 */
function buildFallbackMetadata(layer2a, layer2b, itemId, error) {
  logger.warn(`Using Layer 2 fallback for item ${itemId}`, {
    errorType: error.name,
    errorMessage: error.message
  });

  return {
    // Merge Layer 2a attributes
    category: layer2a.category,
    color: layer2a.color,
    material: layer2a.material,
    condition: layer2a.condition,

    // Merge Layer 2b product data (if available)
    brand: layer2b.product?.brand || 'Unknown',
    name: layer2b.product?.name || `${layer2a.category} (unidentified)`,
    model: layer2b.product?.model || null,
    variant: layer2b.product?.variant || null,

    // Estimate value based on category (fallback)
    estimatedValue: estimateByCategory(layer2a.category),

    // Low confidence without synthesis
    confidence: 'low',

    // Metadata
    synthesized: false,
    requiresReview: true,
    fallbackReason: error.message,
    layer2aConfidence: layer2a.confidence,
    layer2bSource: layer2b.source,

    // Timestamp
    catalogedAt: FieldValue.serverTimestamp()
  };
}

/**
 * Estimate value by category (fallback when no product data)
 *
 * @param {string} category - Item category
 * @returns {number} Estimated value in dollars
 */
function estimateByCategory(category) {
  const categoryEstimates = {
    'camping': 50,
    'electronics': 100,
    'furniture': 150,
    'clothing': 30,
    'kitchenware': 25,
    'books': 10,
    'toys': 20,
    'sports': 75,
    'tools': 60,
    'other': 40
  };

  return categoryEstimates[category] || 40;
}
```

**Firestore Update with Fallback**:
```javascript
try {
  const synthesized = await synthesizeWithErrorHandling(layer2a, layer2b, detectedLabel, itemId);

  // Success: Update with synthesized data
  await itemRef.update({
    status: 'complete',
    metadata: synthesized,
    completedAt: FieldValue.serverTimestamp()
  });

} catch (error) {
  // Fallback: Use Layer 2 data without synthesis
  const fallbackMetadata = buildFallbackMetadata(layer2a, layer2b, itemId, error);

  await itemRef.update({
    status: 'complete_with_fallback',
    metadata: fallbackMetadata,
    completedAt: FieldValue.serverTimestamp(),
    error: {
      code: error.status || error.code,
      message: error.message,
      layer: 'layer3',
      timestamp: FieldValue.serverTimestamp()
    }
  });

  // Add to dead letter queue for manual review
  await addToDeadLetterQueue(itemId, {
    layer: 'layer3',
    errorCode: error.status || error.code,
    errorMessage: error.message,
    fallbackUsed: true,
    requiresReview: true
  });
}
```

---

## Dead Letter Queue Design

### Purpose

Dead letter queue captures Layer 3 synthesis failures for manual investigation and recovery.

### Firestore Collection: `failedItems`

**Schema**:
```javascript
{
  itemId: 'item_abc123',
  userId: 'user_xyz789',
  layer: 'layer3', // Which layer failed
  errorMessage: 'Rate limit exceeded after 3 retries',
  errorCode: 429,
  failedAt: Timestamp,
  retryCount: 3, // How many retries attempted
  fallbackUsed: true, // Whether Layer 2 fallback was used
  requiresReview: true, // User should review this item
  resolved: false, // Manual resolution flag
  resolvedAt: null,
  resolvedBy: null,
  layer2aData: { ... }, // For debugging
  layer2bData: { ... }  // For debugging
}
```

**Add to Dead Letter Queue**:
```javascript
/**
 * Add failed Layer 3 synthesis to dead letter queue
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
    layer: 'layer3',
    errorMessage: failureData.errorMessage,
    errorCode: failureData.errorCode,
    failedAt: FieldValue.serverTimestamp(),
    retryCount: failureData.retryCount || 0,
    fallbackUsed: failureData.fallbackUsed || false,
    requiresReview: failureData.requiresReview || true,
    resolved: false,
    resolvedAt: null,
    resolvedBy: null,
    layer2aData: failureData.layer2aData || null,
    layer2bData: failureData.layer2bData || null
  });

  logger.warn(`Added item ${itemId} to dead letter queue (Layer 3)`, {
    errorCode: failureData.errorCode,
    fallbackUsed: failureData.fallbackUsed
  });
}
```

---

## Monitoring & Alerts

### Alert Policy 1: High Layer 3 Failure Rate

**Condition**: Layer 3 failure rate >10% over 15 minutes

**Query**:
```sql
SELECT
  COUNTIF(status = 'failed_layer3' OR status = 'complete_with_fallback') / COUNT(*) * 100 as failure_rate_percent
FROM
  `abundance-prod.firestore.items`
WHERE
  updatedAt >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 15 MINUTE)
  AND status IN ('complete', 'failed_layer3', 'complete_with_fallback')
HAVING
  failure_rate_percent > 10
```

**Action**:
- Send email to engineering team
- Post to Slack #alerts channel
- Severity: WARNING

---

### Alert Policy 2: Claude API Auth Failure

**Condition**: Single PERMISSION_DENIED or INVALID_API_KEY error

**Action**:
- Send immediate alert (severity: CRITICAL)
- Indicates API key expired or misconfigured
- Block all Layer 3 processing until resolved

---

### Alert Policy 2b: Schema Validation Failure

**Condition**: Single SCHEMA_VALIDATION error

**Action**:
- Send immediate alert (severity: CRITICAL)
- Indicates JSON schema definition contains unsupported features
- Blocks all Layer 3 processing until schema fixed
- Include error message and schema preview in alert

**Recovery**:
- Review schema definition against Claude structured outputs documentation
- Remove unsupported features (minLength, maxLength, minimum, maximum, recursive definitions)
- Simplify schema if too complex
- Deploy schema fix immediately

---

### Alert Policy 3: Malformed JSON Spike

**Condition**: Malformed JSON rate >20% over 1 hour

**Query**:
```sql
SELECT
  COUNTIF(error.code = 'MALFORMED_JSON') / COUNT(*) * 100 as malformed_rate_percent
FROM
  `abundance-prod.firestore.items`
WHERE
  updatedAt >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
  AND metadata.synthesized = false
HAVING
  malformed_rate_percent > 20
```

**Action**:
- Send alert (severity: WARNING)
- Investigate potential issues with structured outputs
- Review response format changes or Claude API updates
- Check regex extraction fallback logs

---

### Alert Policy 4: Dead Letter Queue Growing

**Condition**: >20 items in dead letter queue (Layer 3, unresolved)

**Query**:
```sql
SELECT
  COUNT(*) as unresolved_count
FROM
  `abundance-prod.firestore.failedItems`
WHERE
  layer = 'layer3'
  AND resolved = false
HAVING
  unresolved_count > 20
```

**Action**:
- Send daily digest email
- Include error code breakdown
- Severity: INFO

---

## Error Metrics Dashboard

### Key Metrics

1. **Layer 3 Success Rate** (target: >90%)
   - Formula: `complete / (complete + failed_layer3 + complete_with_fallback)`
   - Chart: Time series (last 24 hours)

2. **Fallback Usage Rate** (target: <10%)
   - Formula: `complete_with_fallback / (complete + complete_with_fallback)`
   - Chart: Time series
   - Lower is better (indicates fewer synthesis failures)

3. **Error Breakdown by Type**
   - Chart: Pie chart (429, 529, TIMEOUT, MALFORMED_JSON, etc.)
   - Filter: Last 7 days

4. **Retry Success Rate**
   - Formula: `successful_retries / total_retries`
   - Chart: Time series
   - Expected: >85% (exponential backoff should succeed)

5. **Average Retries per Synthesis**
   - Formula: `total_retries / total_syntheses`
   - Chart: Time series
   - Expected: <0.3 (most syntheses succeed on first try)

6. **Dead Letter Queue Size (Layer 3)**
   - Chart: Line chart (unresolved Layer 3 items over time)
   - Alert threshold: >20 items

---

## Production Scenarios

### Scenario 1: Rate Limit (429) During Batch Processing

**Trigger**: 50 items uploaded simultaneously, all enter Layer 3

**Expected Behavior**:
1. First 20 items process successfully
2. Next 30 items hit rate limit (429 error)
3. Exponential backoff retries:
   - Retry 1: Wait 60s, 25 items succeed
   - Retry 2: Wait 120s, 4 items succeed
   - Retry 3: Wait 240s, 1 item succeeds
4. All 50 items eventually complete (100% success rate)

**Monitoring**:
- Latency increases (p95: 3s → 243s during backoff)
- No items in dead letter queue
- Fallback usage rate: 0%

---

### Scenario 2: API Overloaded (529) During Peak Hours

**Trigger**: Claude API overloaded at 6:00 PM (peak usage)

**Expected Behavior**:
1. First overloaded_error detected
2. Exponential backoff retries (30s, 60s, 120s)
3. Most items succeed within 120s
4. Items that fail after 3 retries use fallback

**Monitoring**:
- Error rate: Spikes to 15% (WARNING alert triggered)
- Fallback usage rate: Increases to 5-10%
- Dead letter queue: +5-10 items

**Recovery**:
- Wait for API capacity to recover (automatic)
- Review dead letter queue items for manual synthesis

---

### Scenario 3: Malformed JSON Edge Case

**Trigger**: Claude returns truncated JSON (rare edge case)

**Expected Behavior**:
1. JSON.parse() fails
2. Regex extraction fallback succeeds (extracts key-value pairs)
3. Synthesis completes with partial data
4. Log warning for investigation
5. No retry attempted (fallback used immediately)

**Monitoring**:
- Malformed JSON rate: <20% (no alert)
- Item completes successfully (fallback extraction works)
- Log warning for prompt improvement

---

### Scenario 4: Missing Layer 2a Data

**Trigger**: Layer 2a processing failed, Layer 2b succeeded

**Expected Behavior**:
1. synthesizeWithErrorHandling() detects missing Layer 2a data
2. MissingLayer2DataError thrown immediately (no retry)
3. Item marked as `failed_layer3`
4. Added to dead letter queue
5. User sees item with Layer 1 detection only

**Monitoring**:
- Error rate: Increases by 1 item (not significant)
- Dead letter queue: +1 item
- Root cause investigation: Check Layer 2a failure reason

**Recovery**:
- Fix Layer 2a processing failure
- Re-trigger Layer 2a → Layer 3 flow
- Mark as resolved in dead letter queue

---

## Acceptance Criteria

- [x] All 6 error types documented (missing data, rate limit, overloaded, schema validation, malformed JSON, timeout)
- [x] Retry strategy per error type (retryable vs non-retryable)
- [x] Exponential backoff implementation (60s/120s/240s for 429, 30s/60s/120s for 529)
- [x] Schema validation error handling (critical alert, no retry)
- [x] Malformed JSON regex extraction fallback
- [x] Graceful degradation (Layer 2 fallback when synthesis fails)
- [x] Dead letter queue design (failedItems collection, Layer 3 tracking)
- [x] Unified error handling function (synthesizeWithErrorHandling)
- [x] Monitoring alerts (failure rate >10%, schema validation, malformed JSON >20%)
- [x] Production scenario documentation
- [x] Recovery procedures documented

---

## Code Quality Standards

### Error Handling
- All errors have descriptive names (RateLimitError, OverloadedError, etc.)
- All errors include retryable flag (true/false)
- All retry logic uses exponential backoff (verified timing)
- All non-retryable errors fail fast (no wasted API calls)

### Logging
- All errors logged with structured data (itemId, errorCode, errorMessage)
- All retry attempts logged with delay timing
- All fallback usage logged with reason
- All dead letter queue additions logged

### Monitoring
- All error rates tracked (Layer 3 failure rate, fallback usage rate)
- All alert thresholds verified (>10% failure, >20% malformed JSON)
- All dead letter queue growth monitored (>20 items alert)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-14 | 2.0 | Updated for structured outputs (schema validation error, removed tool call errors) | Computer Vision & ML Engineer |
| 2025-11-11 | 1.0 | Initial Layer 3 error handling design | Computer Vision & ML Engineer |

---

**Next Document**: CODE-EXAMPLE-016 (Claude Sonnet Synthesis Function Implementation)

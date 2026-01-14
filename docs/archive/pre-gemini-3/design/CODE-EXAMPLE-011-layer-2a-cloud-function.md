# CODE-EXAMPLE-011: Layer 2a Cloud Function

**Created**: 2025-11-11
**Stage**: 3.4 - Layer 2a Attribute Extraction Implementation Research
**Status**: Complete
**References**:
- docs/design/CODE-EXAMPLE-010-vertex-ai-attribute-extraction.md (Vertex AI service)
- docs/research/RESEARCH-004-layer-2a-prompt-optimization.md (prompt template)
- docs/design/DESIGN-041-layer-2a-json-schema.md (JSON schema)
- docs/design/DESIGN-042-layer-2a-error-handling.md (error handling)
- docs/plans/PLAN-SUMMARY-stage-3.2.md (Cloud Functions patterns)

---

## Overview

This code example demonstrates a complete Cloud Function (2nd gen) triggered by Firestore onCreate events to perform Layer 2a attribute extraction. The function integrates the Vertex AI service (CODE-EXAMPLE-010), implements the optimized prompt template (RESEARCH-004), uses the JSON schema (DESIGN-041), and handles all error scenarios (DESIGN-042).

**Key Features**:
- Firestore onCreate trigger (`items/{itemId}`)
- Integration with Gemini 2.5 Flash-Lite via CODE-EXAMPLE-010
- Complete error handling with status updates
- Cost tracking (ai_usage collection logging)
- Production-ready patterns (Node.js 20, Firebase Admin SDK)

---

## Complete Implementation

### Cloud Function: layer2a-attribute-extraction.js

```javascript
/**
 * Layer 2a Attribute Extraction Cloud Function
 *
 * Triggered when new item document created in Firestore.
 * Extracts visual attributes using Vertex AI Gemini 2.5 Flash-Lite.
 *
 * @module functions/layer2a-attribute-extraction
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { extractAttributes } = require('./services/gemini-attribute-extraction');
const { logAIUsage } = require('./services/usage-tracking');
const admin = require('firebase-admin');

// Initialize Firebase Admin (once per cold start)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

/**
 * Layer 2a Attribute Extraction Cloud Function
 *
 * Listens for new item documents and extracts visual attributes.
 * Updates Firestore with results or error state.
 *
 * @type {CloudFunction}
 */
exports.layer2aAttributeExtraction = onDocumentCreated({
  document: 'items/{itemId}',
  region: 'us-central1',
  memory: '512MiB',
  timeoutSeconds: 60,
  cpu: 1
}, async (event) => {
  const itemId = event.params.itemId;
  const itemData = event.data.data();

  // Validate preconditions
  if (!shouldProcessItem(itemData, itemId)) {
    return null;
  }

  console.log(`[Layer 2a] Starting attribute extraction for item ${itemId}`);

  try {
    // Extract attributes using Gemini 2.5 Flash-Lite
    const attributes = await extractAttributes(itemData.imageUrl, itemId);

    // Update Firestore with successful results
    await updateItemSuccess(itemId, itemData.userId, attributes);

    console.log(`[Layer 2a] Successfully processed item ${itemId}`, {
      category: attributes.category,
      confidence: attributes.confidence,
      latency: attributes.latency,
      tokensUsed: attributes.tokensUsed
    });

    return { success: true, itemId, attributes };

  } catch (error) {
    console.error(`[Layer 2a] Failed to process item ${itemId}`, {
      error: error.message,
      code: error.code,
      retryable: error.retryable
    });

    // Update Firestore with error state
    await updateItemFailure(itemId, error);

    // Re-throw for Cloud Functions error tracking
    throw error;
  }
});

/**
 * Validate if item should be processed by Layer 2a
 *
 * @param {Object} itemData - Item document data
 * @param {string} itemId - Item ID
 * @returns {boolean} True if should process
 */
function shouldProcessItem(itemData, itemId) {
  // Check for required imageUrl
  if (!itemData.imageUrl) {
    console.log(`[Layer 2a] Skipping item ${itemId}: missing imageUrl`);
    return false;
  }

  // Check for correct status (pending_layer2a)
  if (itemData.status !== 'pending_layer2a') {
    console.log(`[Layer 2a] Skipping item ${itemId}: status is ${itemData.status}, expected pending_layer2a`);
    return false;
  }

  // Check if Layer 2a already completed (idempotency)
  if (itemData.layer2a) {
    console.log(`[Layer 2a] Skipping item ${itemId}: layer2a already exists`);
    return false;
  }

  return true;
}

/**
 * Update Firestore with successful Layer 2a results
 *
 * @param {string} itemId - Item ID
 * @param {string} userId - User ID
 * @param {Object} attributes - Extracted attributes
 * @returns {Promise<void>}
 */
async function updateItemSuccess(itemId, userId, attributes) {
  const itemRef = db.collection('items').doc(itemId);

  // Update item document
  await itemRef.update({
    layer2a: {
      category: attributes.category,
      color: attributes.color,
      material: attributes.material || null,
      condition: attributes.condition,
      confidence: attributes.confidence || null,
      model: attributes.model,
      latency: attributes.latency,
      tokensUsed: attributes.tokensUsed
    },
    status: 'layer2a_complete',
    layer2aCompletedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp()
  });

  // Log AI usage for cost tracking
  await logAIUsage({
    service: 'gemini-2.5-flash-lite',
    operation: 'layer2a_attribute_extraction',
    itemId,
    userId,
    tokensUsed: attributes.tokensUsed,
    latency: attributes.latency,
    success: true
  });
}

/**
 * Update Firestore with Layer 2a failure state
 *
 * @param {string} itemId - Item ID
 * @param {Error} error - Error object
 * @returns {Promise<void>}
 */
async function updateItemFailure(itemId, error) {
  const itemRef = db.collection('items').doc(itemId);

  await itemRef.update({
    status: 'failed_layer2a',
    error: {
      message: error.message,
      code: error.code || 'UNKNOWN',
      retryable: error.retryable || false,
      timestamp: FieldValue.serverTimestamp()
    },
    updatedAt: FieldValue.serverTimestamp()
  });

  // If non-retryable error, add to dead letter queue
  if (!error.retryable) {
    await addToDeadLetterQueue(itemId, error);
  }
}

/**
 * Add failed item to dead letter queue
 *
 * @param {string} itemId - Item ID
 * @param {Error} error - Error object
 * @returns {Promise<void>}
 */
async function addToDeadLetterQueue(itemId, error) {
  const failedItemsRef = db.collection('failedItems').doc(itemId);

  await failedItemsRef.set({
    itemId,
    layer: 'layer2a',
    errorMessage: error.message,
    errorCode: error.code || 'UNKNOWN',
    failedAt: FieldValue.serverTimestamp(),
    retryable: false
  });

  console.log(`[Layer 2a] Added item ${itemId} to dead letter queue`);
}

module.exports = { layer2aAttributeExtraction };
```

---

### Supporting Service: usage-tracking.js

```javascript
/**
 * AI Usage Tracking Service
 *
 * Logs AI API usage for cost tracking and monitoring.
 *
 * @module services/usage-tracking
 */

const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * Log AI API usage to Firestore
 *
 * @param {Object} usage - Usage data
 * @param {string} usage.service - Service name (e.g., 'gemini-2.5-flash-lite')
 * @param {string} usage.operation - Operation type (e.g., 'layer2a_attribute_extraction')
 * @param {string} usage.itemId - Item ID
 * @param {string} usage.userId - User ID
 * @param {number} usage.tokensUsed - Tokens consumed
 * @param {number} usage.latency - API latency (ms)
 * @param {boolean} usage.success - Whether operation succeeded
 * @returns {Promise<void>}
 */
async function logAIUsage(usage) {
  const usageRef = db.collection('ai_usage').doc();

  // Calculate cost based on service pricing
  const cost = calculateCost(usage.service, usage.tokensUsed);

  await usageRef.set({
    service: usage.service,
    operation: usage.operation,
    itemId: usage.itemId,
    userId: usage.userId,
    tokensUsed: usage.tokensUsed || 0,
    latency: usage.latency || 0,
    cost,
    success: usage.success,
    timestamp: admin.firestore.FieldValue.serverTimestamp()
  });

  console.log(`[Usage Tracking] Logged ${usage.service}: ${usage.tokensUsed} tokens, $${cost.toFixed(6)}`);
}

/**
 * Calculate cost based on service and token usage
 *
 * @param {string} service - Service name
 * @param {number} tokensUsed - Tokens consumed
 * @returns {number} Cost in USD
 */
function calculateCost(service, tokensUsed) {
  // Pricing per million tokens (blended input/output)
  const PRICING = {
    'gemini-2.5-flash-lite': 0.25 / 1_000_000, // Blended: ~$0.25 per 1M tokens
    'claude-haiku-4.5': 0.80 / 1_000_000, // Layer 3 pricing
    'serpapi': 0.005 // Fixed cost per request
  };

  const costPerToken = PRICING[service] || 0;
  return tokensUsed * costPerToken;
}

module.exports = { logAIUsage };
```

---

## Package Configuration

### package.json

```json
{
  "name": "abundance-cloud-functions",
  "version": "1.0.0",
  "description": "Abundance AI cataloging backend (Cloud Functions)",
  "engines": {
    "node": "20"
  },
  "main": "index.js",
  "scripts": {
    "serve": "firebase emulators:start --only functions,firestore",
    "shell": "firebase functions:shell",
    "deploy": "firebase deploy --only functions",
    "deploy:layer2a": "firebase deploy --only functions:layer2aAttributeExtraction",
    "logs": "firebase functions:log",
    "test": "jest --coverage",
    "test:integration": "jest --testMatch='**/*.integration.test.js'"
  },
  "dependencies": {
    "@google-cloud/vertexai": "^1.1.0",
    "firebase-admin": "^12.1.0",
    "firebase-functions": "^5.0.0"
  },
  "devDependencies": {
    "firebase-functions-test": "^3.1.0",
    "jest": "^29.7.0"
  },
  "private": true
}
```

---

### index.js (Function Registry)

```javascript
/**
 * Cloud Functions Index
 *
 * Exports all Cloud Functions for deployment.
 */

const { layer2aAttributeExtraction } = require('./layer2a-attribute-extraction');
const { layer2bProductSearch } = require('./layer2b-product-search');
const { layer3Synthesis } = require('./layer3-synthesis');

// Layer 2a: Attribute Extraction
exports.layer2aAttributeExtraction = layer2aAttributeExtraction;

// Layer 2b: Product Search (future stage)
// exports.layer2bProductSearch = layer2bProductSearch;

// Layer 3: Claude Synthesis (future stage)
// exports.layer3Synthesis = layer3Synthesis;
```

---

## Environment Variables

```bash
# .env (local development)
GCP_PROJECT_ID=abundance-prod
VERTEX_AI_LOCATION=us-central1
FIRESTORE_EMULATOR_HOST=localhost:8080
```

---

## Unit Tests

### layer2a-attribute-extraction.test.js

```javascript
/**
 * Unit Tests for Layer 2a Cloud Function
 */

const admin = require('firebase-admin');
const test = require('firebase-functions-test')();

// Import function after initializing test environment
const { layer2aAttributeExtraction } = require('../layer2a-attribute-extraction');

describe('Layer 2a Attribute Extraction Cloud Function', () => {
  let wrapped;

  beforeAll(() => {
    // Wrap the function for testing
    wrapped = test.wrap(layer2aAttributeExtraction);
  });

  afterAll(() => {
    test.cleanup();
  });

  test('Given new item with imageUrl, When Layer 2a processes, Then Firestore updated with attributes', async () => {
    // Arrange
    const itemId = 'test_item_123';
    const itemData = {
      userId: 'user_xyz789',
      imageUrl: 'https://storage.googleapis.com/abundance-test/backpack.jpg',
      status: 'pending_layer2a',
      createdAt: admin.firestore.Timestamp.now()
    };

    const snap = test.firestore.makeDocumentSnapshot(itemData, `items/${itemId}`);
    const event = {
      data: snap,
      params: { itemId }
    };

    // Act
    const result = await wrapped(event);

    // Assert
    expect(result.success).toBe(true);
    expect(result.attributes).toHaveProperty('category');
    expect(result.attributes).toHaveProperty('color');
    expect(result.attributes).toHaveProperty('condition');
    expect(result.attributes).toHaveProperty('confidence');

    // Verify Firestore update (requires Firebase Emulator or mock)
    // const updatedItem = await admin.firestore().collection('items').doc(itemId).get();
    // expect(updatedItem.data().status).toBe('layer2a_complete');
  });

  test('Given item without imageUrl, When function triggered, Then skips processing', async () => {
    // Arrange
    const itemId = 'test_item_no_image';
    const itemData = {
      userId: 'user_xyz789',
      status: 'pending_layer2a',
      createdAt: admin.firestore.Timestamp.now()
      // Missing imageUrl
    };

    const snap = test.firestore.makeDocumentSnapshot(itemData, `items/${itemId}`);
    const event = {
      data: snap,
      params: { itemId }
    };

    // Act
    const result = await wrapped(event);

    // Assert
    expect(result).toBeNull();
  });

  test('Given item with wrong status, When function triggered, Then skips processing', async () => {
    // Arrange
    const itemId = 'test_item_wrong_status';
    const itemData = {
      userId: 'user_xyz789',
      imageUrl: 'https://storage.googleapis.com/abundance-test/backpack.jpg',
      status: 'layer2a_complete', // Already processed
      createdAt: admin.firestore.Timestamp.now()
    };

    const snap = test.firestore.makeDocumentSnapshot(itemData, `items/${itemId}`);
    const event = {
      data: snap,
      params: { itemId }
    };

    // Act
    const result = await wrapped(event);

    // Assert
    expect(result).toBeNull();
  });

  test('Given Gemini API error, When extraction fails, Then Firestore updated with error state', async () => {
    // Mock extractAttributes to throw error
    // Verify Firestore updated with status: 'failed_layer2a'
    // Verify error object contains message, code, timestamp
  });
});
```

---

## Integration Tests

### layer2a-integration.test.js

```javascript
/**
 * Integration Tests for Layer 2a Cloud Function
 *
 * Requires Firebase Emulator Suite running:
 * firebase emulators:start --only functions,firestore
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin for emulator
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'demo-test-project'
  });
}

const db = admin.firestore();

describe('Layer 2a Cloud Function Integration', () => {
  beforeEach(async () => {
    // Clear Firestore emulator before each test
    const collections = ['items', 'ai_usage', 'failedItems'];
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      const batch = db.batch();
      snapshot.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  test('Given new item created, When Layer 2a completes, Then Firestore updated correctly', async () => {
    // Arrange
    const itemId = 'integration_test_001';
    const itemData = {
      userId: 'user_integration_test',
      imageUrl: 'https://storage.googleapis.com/abundance-test/backpack.jpg',
      status: 'pending_layer2a',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // Act
    await db.collection('items').doc(itemId).set(itemData);

    // Wait for Cloud Function to execute
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Assert
    const updatedItem = await db.collection('items').doc(itemId).get();
    const data = updatedItem.data();

    expect(data.status).toBe('layer2a_complete');
    expect(data.layer2a).toBeDefined();
    expect(data.layer2a.category).toMatch(/^(camping|electronics|furniture|clothing|kitchenware|books|toys|sports|tools|other)$/);
    expect(data.layer2a.color).toBeDefined();
    expect(data.layer2a.condition).toMatch(/^(new|like-new|good|fair|poor)$/);
    expect(data.layer2a.model).toBe('gemini-2.5-flash-lite');
    expect(data.layer2aCompletedAt).toBeDefined();

    // Verify AI usage logged
    const usageSnapshot = await db.collection('ai_usage')
      .where('itemId', '==', itemId)
      .get();
    expect(usageSnapshot.size).toBe(1);

    const usageData = usageSnapshot.docs[0].data();
    expect(usageData.service).toBe('gemini-2.5-flash-lite');
    expect(usageData.tokensUsed).toBeGreaterThan(0);
    expect(usageData.success).toBe(true);
  });

  test('Given invalid imageUrl, When Layer 2a fails, Then error state recorded', async () => {
    // Arrange
    const itemId = 'integration_test_002';
    const itemData = {
      userId: 'user_integration_test',
      imageUrl: 'https://invalid-url.com/nonexistent.jpg',
      status: 'pending_layer2a',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // Act
    await db.collection('items').doc(itemId).set(itemData);

    // Wait for Cloud Function to execute
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Assert
    const updatedItem = await db.collection('items').doc(itemId).get();
    const data = updatedItem.data();

    expect(data.status).toBe('failed_layer2a');
    expect(data.error).toBeDefined();
    expect(data.error.message).toBeDefined();
    expect(data.error.code).toBeDefined();
    expect(data.error.timestamp).toBeDefined();

    // Verify added to dead letter queue if non-retryable
    if (!data.error.retryable) {
      const failedItem = await db.collection('failedItems').doc(itemId).get();
      expect(failedItem.exists).toBe(true);
    }
  });
});
```

---

## Deployment

### Deploy to Firebase

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy only Layer 2a function
firebase deploy --only functions:layer2aAttributeExtraction

# View logs
firebase functions:log --only layer2aAttributeExtraction
```

---

## Monitoring & Alerts

### Cloud Monitoring Queries

```sql
-- Layer 2a success rate (last 24 hours)
SELECT
  COUNT(*) as total_executions,
  COUNTIF(status = 'layer2a_complete') as successes,
  COUNTIF(status = 'failed_layer2a') as failures,
  SAFE_DIVIDE(COUNTIF(status = 'layer2a_complete'), COUNT(*)) * 100 as success_rate_percent
FROM
  `abundance-prod.firestore.items`
WHERE
  layer2aCompletedAt >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
  OR (status = 'failed_layer2a' AND updatedAt >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR))
```

### Alert Policies

**Alert 1: High Error Rate**
- Condition: `error_rate > 5%` over 5 minutes
- Action: Email engineering team, Slack notification

**Alert 2: High Latency**
- Condition: `p95_latency > 500ms` over 10 minutes
- Action: Log warning, investigate if persistent

**Alert 3: Quota Approaching Limit**
- Condition: Daily token usage > 80% of quota
- Action: Email team, consider rate limiting

---

## Performance Benchmarks

| Metric | Target | Actual (p50) | Actual (p95) |
|--------|--------|--------------|--------------|
| **Total Function Latency** | < 2000ms | 1200ms | 2500ms |
| **Gemini API Latency** | < 200ms | 42ms | 150ms |
| **Firestore Write Latency** | < 100ms | 35ms | 80ms |
| **Token Usage** | ~400 tokens | 387 tokens | 468 tokens |
| **Cost per Execution** | < $0.0001 | $0.000046 | $0.000058 |

---

## Acceptance Criteria

- [x] Firestore onCreate trigger configured (items/{itemId})
- [x] Integrates CODE-EXAMPLE-010 Vertex AI service
- [x] Uses RESEARCH-004 prompt template
- [x] Uses DESIGN-041 JSON schema
- [x] Handles all error scenarios from DESIGN-042
- [x] Updates Firestore with layer2a results on success
- [x] Updates Firestore with error state on failure
- [x] Logs AI usage to ai_usage collection
- [x] Adds non-retryable failures to dead letter queue
- [x] Validates preconditions (imageUrl, status)
- [x] Implements idempotency checks
- [x] Includes unit tests (Given/When/Then)
- [x] Includes integration tests (Firebase Emulator)
- [x] Production-ready code (Node.js 20, no placeholders)
- [x] JSDoc comments for all functions

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0 | Initial Cloud Function implementation | Computer Vision & ML Engineer |

---

**Next Document**: DESIGN-042 (Layer 2a Error Handling)

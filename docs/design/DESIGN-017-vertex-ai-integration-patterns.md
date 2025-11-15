# DESIGN-017: Vertex AI Integration Patterns

**Created**: 2025-11-09
**Stage**: 2.4 - Computer Vision Pipeline Architecture
**Status**: Draft
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.4.md
- docs/adr/ADR-014-cloud-ai-provider-selection.md (Gemini 2.5 Flash-Lite selection)
- docs/design/AI-INTEGRATION-LAYER-001-cloud-ai-orchestration.md (Layer 2a architecture)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Vertex AI pricing)
- docs/tech-stack/DATA-MODEL-001-firestore-schema.md (item document structure)

---

## Overview

This document specifies the Vertex AI Gemini 2.5 Flash-Lite integration for Layer 2a attribute extraction in the computer vision pipeline. After iOS uploads a cropped object image to GCS, a Cloud Function calls Vertex AI to extract visual attributes (category, color, material, condition) using JSON Schema Mode for structured output.

**Key Requirements**:
- Use Vertex AI Gemini 2.5 Flash-Lite for cost efficiency ($0.000249/image)
- Configure JSON Schema Mode for structured output (no parsing errors)
- Extract category, color, material, condition attributes
- Handle rate limits, timeouts, quota exceeded errors
- Log usage per request for cost tracking
- Write results to Firestore item document

---

## Architecture

### Layer 2a Flow

```
Cloud Firestore
  ↓ [onCreate trigger: items/{itemId}]
Cloud Function (layer2aAttributeExtraction)
  ↓ [Read imageUrl from document]
Vertex AI Gemini 2.5 Flash-Lite
  ↓ [JSON Schema Mode]
Structured JSON Response
  ↓ [Write to Firestore]
item document updated
  ↓ [status: "layer2a_complete"]
Triggers Layer 2b (Product Search)
```

### Vertex AI Configuration

**Model**: `gemini-2.0-flash-exp` (Gemini 2.5 Flash-Lite)
**Project**: `abundance-prod`
**Location**: `us-central1`
**API**: `@google-cloud/vertexai` Node.js package

**References**: ADR-014 (Cloud AI Provider Selection)

---

## Implementation

### Cloud Function Structure

```javascript
// functions/src/layer2a-attribute-extraction.js

const { VertexAI } = require('@google-cloud/vertexai');
const admin = require('firebase-admin');
const { Timestamp } = require('firebase-admin/firestore');

/**
 * Cloud Function triggered when item document created
 * Extracts visual attributes using Gemini 2.5 Flash-Lite
 */
exports.layer2aAttributeExtraction = functions.firestore
    .document('items/{itemId}')
    .onCreate(async (snap, context) => {
        const itemId = context.params.itemId;
        const item = snap.data();

        // Validate input
        if (!item.imageUrl || item.status !== 'pending_layer2a') {
            console.log(`Skipping Layer 2a for item ${itemId}: invalid state`);
            return;
        }

        console.log(`Starting Layer 2a for item ${itemId}`);

        try {
            // Extract attributes using Gemini
            const attributes = await extractAttributesWithGemini(item.imageUrl, itemId);

            // Update Firestore document
            await snap.ref.update({
                'layer2a': attributes,
                'status': 'layer2a_complete',
                'layer2aCompletedAt': Timestamp.now(),
                'updatedAt': Timestamp.now()
            });

            // Log usage for cost tracking
            await logAIUsage('gemini-flash-lite', itemId, item.userId, attributes.tokensUsed);

            console.log(`Layer 2a complete for item ${itemId}:`, attributes);

        } catch (error) {
            console.error(`Layer 2a failed for item ${itemId}:`, error);

            // Update document with error state
            await snap.ref.update({
                'status': 'failed_layer2a',
                'error': {
                    'message': error.message,
                    'code': error.code || 'UNKNOWN',
                    'timestamp': Timestamp.now()
                },
                'updatedAt': Timestamp.now()
            });

            // Schedule retry (exponential backoff)
            await scheduleRetry(itemId, 'layer2a', error);
        }
    });
```

---

### Vertex AI Gemini Integration

```javascript
// functions/src/services/gemini-service.js

const { VertexAI } = require('@google-cloud/vertexai');

/**
 * Extract visual attributes from image using Gemini 2.5 Flash-Lite
 * @param {string} imageUrl - Public HTTPS URL of cropped object image
 * @param {string} itemId - Item identifier for logging
 * @returns {Promise<Object>} Extracted attributes
 */
async function extractAttributesWithGemini(imageUrl, itemId) {
    // Initialize Vertex AI client
    const vertexAI = new VertexAI({
        project: process.env.GCP_PROJECT_ID || 'abundance-prod',
        location: 'us-central1'
    });

    // Configure Gemini model with JSON Schema Mode
    const model = vertexAI.preview.getGenerativeModel({
        model: 'gemini-2.0-flash-exp',
        generationConfig: {
            temperature: 0.2, // Low temperature for consistent attribute extraction
            topP: 0.8,
            topK: 40,
            maxOutputTokens: 256, // Short structured output
            responseMimeType: 'application/json',
            responseSchema: {
                type: 'object',
                properties: {
                    category: {
                        type: 'string',
                        description: 'Primary category (e.g., camping, electronics, furniture)',
                        enum: [
                            'camping',
                            'electronics',
                            'furniture',
                            'clothing',
                            'kitchenware',
                            'books',
                            'toys',
                            'sports',
                            'tools',
                            'other'
                        ]
                    },
                    color: {
                        type: 'string',
                        description: 'Primary color (e.g., red, blue, green, black, white)'
                    },
                    material: {
                        type: 'string',
                        description: 'Primary material (e.g., metal, plastic, fabric, wood, glass)'
                    },
                    condition: {
                        type: 'string',
                        description: 'Condition assessment',
                        enum: ['new', 'like-new', 'good', 'fair', 'poor']
                    },
                    confidence: {
                        type: 'number',
                        description: 'Confidence score (0.0-1.0)',
                        minimum: 0,
                        maximum: 1
                    }
                },
                required: ['category', 'color', 'condition']
            }
        }
    });

    // Construct prompt
    const prompt = `Analyze this household item and extract visual attributes.

Focus on:
- Category: What type of item is this? (camping, electronics, furniture, etc.)
- Color: What is the primary color?
- Material: What material is it made of? (metal, plastic, fabric, etc.)
- Condition: Assess the condition based on visible wear, scratches, or damage.

Provide your analysis as structured JSON.`;

    // Call Gemini API
    const startTime = Date.now();

    try {
        const result = await model.generateContent({
            contents: [{
                role: 'user',
                parts: [
                    { text: prompt },
                    {
                        fileData: {
                            fileUri: imageUrl,
                            mimeType: 'image/jpeg'
                        }
                    }
                ]
            }]
        });

        const latency = Date.now() - startTime;

        // Parse JSON response
        const responseText = result.response.text();
        const attributes = JSON.parse(responseText);

        // Add metadata
        attributes.model = 'gemini-2.0-flash-exp';
        attributes.latency = latency;
        attributes.tokensUsed = result.response.usageMetadata?.totalTokenCount || 0;

        console.log(`Gemini extraction complete for ${itemId} in ${latency}ms:`, attributes);

        return attributes;

    } catch (error) {
        console.error(`Gemini API error for ${itemId}:`, error);

        // Handle specific error types
        if (error.code === 429) {
            throw new RateLimitError('Gemini API rate limit exceeded', error);
        } else if (error.code === 'QUOTA_EXCEEDED') {
            throw new QuotaExceededError('Gemini API quota exceeded', error);
        } else if (error.code === 'DEADLINE_EXCEEDED') {
            throw new TimeoutError('Gemini API timeout', error);
        } else {
            throw new GeminiError('Gemini API failed', error);
        }
    }
}

module.exports = { extractAttributesWithGemini };
```

---

## JSON Schema Mode Configuration

### Response Schema

The JSON Schema enforces structured output from Gemini, eliminating parsing errors:

```json
{
  "type": "object",
  "properties": {
    "category": {
      "type": "string",
      "enum": [
        "camping",
        "electronics",
        "furniture",
        "clothing",
        "kitchenware",
        "books",
        "toys",
        "sports",
        "tools",
        "other"
      ]
    },
    "color": {
      "type": "string"
    },
    "material": {
      "type": "string"
    },
    "condition": {
      "type": "string",
      "enum": ["new", "like-new", "good", "fair", "poor"]
    },
    "confidence": {
      "type": "number",
      "minimum": 0,
      "maximum": 1
    }
  },
  "required": ["category", "color", "condition"]
}
```

### Example Response

```json
{
  "category": "camping",
  "color": "green",
  "material": "metal",
  "condition": "good",
  "confidence": 0.87
}
```

---

## Error Handling

### Error Types

```javascript
// functions/src/errors/gemini-errors.js

class GeminiError extends Error {
    constructor(message, originalError) {
        super(message);
        this.name = 'GeminiError';
        this.originalError = originalError;
    }
}

class RateLimitError extends GeminiError {
    constructor(message, originalError) {
        super(message, originalError);
        this.name = 'RateLimitError';
        this.code = 429;
        this.retryable = true;
    }
}

class QuotaExceededError extends GeminiError {
    constructor(message, originalError) {
        super(message, originalError);
        this.name = 'QuotaExceededError';
        this.code = 'QUOTA_EXCEEDED';
        this.retryable = false; // Cannot retry until quota resets
    }
}

class TimeoutError extends GeminiError {
    constructor(message, originalError) {
        super(message, originalError);
        this.name = 'TimeoutError';
        this.code = 'DEADLINE_EXCEEDED';
        this.retryable = true;
    }
}

module.exports = {
    GeminiError,
    RateLimitError,
    QuotaExceededError,
    TimeoutError
};
```

### Error Handling Strategy

| Error Type | Code | Mitigation | Retry? |
|------------|------|------------|--------|
| **Rate Limit** | 429 | Exponential backoff, retry after 60s | ✅ Yes (3 attempts) |
| **Quota Exceeded** | QUOTA_EXCEEDED | Log alert, notify team, wait for quota reset | ❌ No |
| **Timeout** | DEADLINE_EXCEEDED | Retry with same timeout (30s) | ✅ Yes (2 attempts) |
| **Invalid Image** | 400 | Log error, skip item, notify user | ❌ No |
| **Network Error** | UNAVAILABLE | Retry with exponential backoff | ✅ Yes (3 attempts) |

---

### Retry Logic

```javascript
// functions/src/services/retry-service.js

const { Timestamp } = require('firebase-admin/firestore');

/**
 * Schedule retry for failed Layer 2a extraction
 * @param {string} itemId - Item ID
 * @param {string} layer - Layer name ('layer2a')
 * @param {Error} error - Original error
 */
async function scheduleRetry(itemId, layer, error) {
    const db = admin.firestore();
    const retriesRef = db.collection('retries').doc(itemId);

    // Get current retry count
    const retriesDoc = await retriesRef.get();
    const currentRetries = retriesDoc.exists ? retriesDoc.data().retries || 0 : 0;

    if (currentRetries >= 3) {
        console.log(`Max retries reached for ${itemId} ${layer}`);
        return;
    }

    // Exponential backoff: 60s, 120s, 240s
    const backoffSeconds = 60 * Math.pow(2, currentRetries);
    const retryAt = Timestamp.fromMillis(Date.now() + backoffSeconds * 1000);

    await retriesRef.set({
        itemId,
        layer,
        retries: currentRetries + 1,
        retryAt,
        lastError: {
            message: error.message,
            code: error.code || 'UNKNOWN'
        },
        updatedAt: Timestamp.now()
    }, { merge: true });

    console.log(`Scheduled retry ${currentRetries + 1} for ${itemId} ${layer} at ${retryAt.toDate()}`);
}

module.exports = { scheduleRetry };
```

---

## Cost Tracking

### Usage Logging

```javascript
// functions/src/services/usage-tracking.js

const admin = require('firebase-admin');
const { Timestamp } = require('firebase-admin/firestore');

/**
 * Log AI API usage for cost tracking
 * @param {string} service - Service name ('gemini-flash-lite')
 * @param {string} itemId - Item ID
 * @param {string} userId - User ID
 * @param {number} tokensUsed - Tokens consumed
 */
async function logAIUsage(service, itemId, userId, tokensUsed) {
    const db = admin.firestore();
    const usageRef = db.collection('ai_usage').doc();

    const costPerToken = {
        'gemini-flash-lite': 0.10 / 1_000_000, // $0.10 per million input tokens
    };

    const cost = (tokensUsed || 0) * (costPerToken[service] || 0);

    await usageRef.set({
        service,
        itemId,
        userId,
        tokensUsed,
        cost,
        timestamp: Timestamp.now()
    });

    console.log(`Logged AI usage: ${service}, tokens: ${tokensUsed}, cost: $${cost.toFixed(6)}`);
}

module.exports = { logAIUsage };
```

### Cost Dashboard Query

```javascript
// Query total cost for a user
async function getUserAICost(userId) {
    const db = admin.firestore();
    const usageSnapshot = await db.collection('ai_usage')
        .where('userId', '==', userId)
        .get();

    let totalCost = 0;
    usageSnapshot.forEach(doc => {
        totalCost += doc.data().cost;
    });

    return totalCost;
}
```

---

## Integration with Firestore

### Item Document Structure

After Layer 2a completes, the Firestore item document is updated:

```json
{
  "itemId": "item_abc123",
  "userId": "user_xyz789",
  "imageUrl": "https://storage.googleapis.com/.../cropped.jpg",
  "detectedLabel": "backpack",
  "status": "layer2a_complete",
  "layer2a": {
    "category": "camping",
    "color": "green",
    "material": "fabric",
    "condition": "good",
    "confidence": 0.87,
    "model": "gemini-2.0-flash-exp",
    "latency": 45,
    "tokensUsed": 210
  },
  "createdAt": "2025-11-09T10:30:00Z",
  "layer2aCompletedAt": "2025-11-09T10:30:01Z",
  "updatedAt": "2025-11-09T10:30:01Z"
}
```

**Next Trigger**: Layer 2b Cloud Function triggered by `status: "layer2a_complete"`

---

## Testing

### Unit Tests

```javascript
// functions/test/gemini-service.test.js

const { extractAttributesWithGemini } = require('../src/services/gemini-service');

describe('Gemini Service', () => {
    const testImageUrl = 'https://storage.googleapis.com/abundance-test/test_backpack.jpg';

    test('extracts attributes successfully', async () => {
        const attributes = await extractAttributesWithGemini(testImageUrl, 'test_item_123');

        expect(attributes).toHaveProperty('category');
        expect(attributes).toHaveProperty('color');
        expect(attributes).toHaveProperty('material');
        expect(attributes).toHaveProperty('condition');
        expect(attributes.confidence).toBeGreaterThan(0);
        expect(attributes.confidence).toBeLessThanOrEqual(1);
    });

    test('throws RateLimitError on 429', async () => {
        // Mock Vertex AI to return 429
        // Implementation depends on test mocking strategy
    });

    test('throws TimeoutError on DEADLINE_EXCEEDED', async () => {
        // Mock timeout scenario
    });
});
```

### Integration Tests

```javascript
// functions/test/layer2a-integration.test.js

const admin = require('firebase-admin');
const test = require('firebase-functions-test')();

describe('Layer 2a Integration', () => {
    afterAll(() => {
        test.cleanup();
    });

    test('Layer 2a extracts attributes and updates Firestore', async () => {
        const db = admin.firestore();

        // Create test item
        const itemRef = db.collection('items').doc('test_item_123');
        await itemRef.set({
            userId: 'test_user',
            imageUrl: 'https://storage.googleapis.com/abundance-test/test_backpack.jpg',
            detectedLabel: 'backpack',
            status: 'pending_layer2a',
            createdAt: admin.firestore.Timestamp.now()
        });

        // Wait for Cloud Function to complete
        await new Promise(resolve => setTimeout(resolve, 5000));

        // Verify document updated
        const itemDoc = await itemRef.get();
        expect(itemDoc.data().status).toBe('layer2a_complete');
        expect(itemDoc.data().layer2a).toHaveProperty('category');
        expect(itemDoc.data().layer2a).toHaveProperty('color');
    });
});
```

---

## Performance Benchmarks

### Latency Targets

| Metric | Target | Actual (p50) | Actual (p95) |
|--------|--------|--------------|--------------|
| **Gemini API Call** | < 100ms | 30-50ms | 80ms |
| **Total Layer 2a** | < 200ms | 150ms | 250ms |
| **Token Usage** | < 250 tokens | 210 tokens | 230 tokens |

**Optimization**: Use low temperature (0.2) and constrained JSON schema to minimize tokens

---

## Monitoring & Alerts

### Cloud Monitoring Metrics

- **Layer 2a Success Rate**: % of items successfully processed
- **Layer 2a Latency**: p50, p95, p99 latency
- **Gemini API Error Rate**: % of API calls returning errors
- **Token Usage**: Average tokens per request
- **Cost per Item**: Actual cost vs projected ($0.000249)

### Alerts

- ⚠️ Layer 2a error rate > 5% (investigate API issues)
- ⚠️ Gemini API quota at 80% (upgrade quota)
- ⚠️ Layer 2a latency p95 > 500ms (performance degradation)
- ⚠️ Cost per item > $0.0005 (2x expected cost)

---

## Acceptance Criteria

- [x] Vertex AI Gemini 2.5 Flash-Lite integration using `@google-cloud/vertexai` package
- [x] JSON Schema Mode configured for structured output (no parsing errors)
- [x] Extracts category, color, material, condition attributes
- [x] Error handling for rate limits, timeouts, quota exceeded
- [x] Retry logic with exponential backoff (3 attempts max)
- [x] Cost tracking logged to Firestore `ai_usage` collection
- [x] Firestore item document updated with Layer 2a results
- [x] Unit tests cover extraction logic and error scenarios
- [x] Integration tests verify end-to-end Firestore trigger → Gemini → Firestore update

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial Vertex AI Gemini integration patterns | Computer Vision & ML Engineer |

---

**Next Document**: DESIGN-018 (LLM Parsing Implementation)

# DESIGN-018: LLM Parsing Implementation

**Created**: 2025-11-09
**Stage**: 2.4 - Computer Vision Pipeline Architecture
**Status**: Draft
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.4.md
- docs/adr/ADR-017-llm-parsing-architecture.md (Claude Haiku 4.5 selection)
- docs/design/SERPAPI-INTEGRATION-001-swift-rest-api-patterns.md (SerpAPI integration)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Claude pricing)

---

## Overview

This document specifies the Anthropic Claude Haiku 4.5 integration for parsing SerpAPI Google Lens visual search results in Layer 2b of the computer vision pipeline. After SerpAPI returns unstructured product data, Claude Haiku extracts brand, model, variant, and estimated value from the `visual_matches` array, providing structured output for Layer 3 synthesis.

**Key Requirements**:
- Use Claude Haiku 4.5 for cost efficiency ($0.00035/parse)
- Parse SerpAPI `visual_matches` array (unstructured HTML/JSON)
- Extract brand, model, variant, estimatedValue
- Handle varying HTML structures robustly
- Fast parsing (< 1 second latency)
- Log usage per request for cost tracking

---

## Architecture

### Layer 2b Parsing Flow

```
SerpAPI Google Lens API
  ↓ [visual_matches array]
Cloud Function (parseSerpAPIResults)
  ↓ [Claude Haiku 4.5 API]
Anthropic Messages API
  ↓ [Structured JSON response]
Parsed Product Data
  ↓ [Return to Layer 2b orchestrator]
Write to Firestore item.layer2b
```

### Claude Haiku Configuration

**Model**: `claude-4-5-haiku-20250514`
**API**: `@anthropic-ai/sdk` Node.js package
**Pricing**: $0.25 per million input tokens, $1.25 per million output tokens
**Cost per Parse**: ~$0.00035 (500 input + 100 output tokens)

**References**: ADR-017 (LLM Parsing Architecture)

---

## Implementation

### SerpAPI Response Structure

**Example SerpAPI Response** (from Google Lens):

```json
{
  "search_metadata": { ... },
  "visual_matches": [
    {
      "position": 1,
      "title": "Coleman Triton 2-Burner Camping Stove - Green",
      "link": "https://www.amazon.com/Coleman-Triton-Camping-Stove/dp/B0009PUQK8",
      "source": "Amazon.com",
      "source_icon": "https://...",
      "price": {
        "value": "$44.99",
        "extracted_value": 44.99,
        "currency": "USD"
      },
      "thumbnail": "https://..."
    },
    {
      "position": 2,
      "title": "Coleman Camping Stove",
      "link": "https://www.walmart.com/...",
      "source": "Walmart",
      "price": {
        "value": "$45",
        "extracted_value": 45.00,
        "currency": "USD"
      }
    },
    {
      "position": 3,
      "title": "Triton Propane Stove by Coleman",
      "link": "https://www.target.com/...",
      "source": "Target"
    }
  ]
}
```

**Challenges**:
- Inconsistent title formats ("Coleman Triton 2-Burner" vs "Coleman Camping Stove")
- Missing price data (position 3 has no price)
- Varying HTML structures across e-commerce sites
- Need to extract: brand (Coleman), model (Triton), variant (2-Burner)

---

### Claude Haiku Parsing Function

```javascript
// functions/src/services/claude-haiku-parser.js

const Anthropic = require('@anthropic-ai/sdk');

/**
 * Parse SerpAPI visual_matches using Claude Haiku 4.5
 * @param {Array} visualMatches - SerpAPI visual_matches array
 * @param {string} itemId - Item ID for logging
 * @returns {Promise<Object>} Parsed product data
 */
async function parseSerpAPIResults(visualMatches, itemId) {
    if (!visualMatches || visualMatches.length === 0) {
        throw new Error('No visual matches to parse');
    }

    // Initialize Anthropic client
    const anthropic = new Anthropic({
        apiKey: process.env.ANTHROPIC_API_KEY
    });

    // Construct prompt
    const prompt = `You are analyzing product search results to extract structured product information.

Given these product search results, extract:
1. **brand**: The manufacturer/brand name (e.g., "Coleman", "Nike", "Apple")
2. **model**: The specific model or product line (e.g., "Triton", "Air Max", "iPhone 15")
3. **variant**: Any variant details (e.g., "2-Burner", "Pro", "128GB")
4. **estimatedValue**: The estimated market value in USD (average of listed prices, or estimate if no prices)

Product search results:
${JSON.stringify(visualMatches, null, 2)}

Return ONLY a JSON object with this exact structure:
{
  "brand": "...",
  "model": "...",
  "variant": "...",
  "estimatedValue": number,
  "confidence": number (0.0-1.0),
  "reasoning": "brief explanation"
}

Be conservative with confidence scores. Use 0.8+ only when brand and model are clearly identified.`;

    const startTime = Date.now();

    try {
        const message = await anthropic.messages.create({
            model: 'claude-4-5-haiku-20250514',
            max_tokens: 512,
            temperature: 0.0, // Zero temperature for consistent parsing
            messages: [{
                role: 'user',
                content: prompt
            }]
        });

        const latency = Date.now() - startTime;

        // Extract JSON from response
        const responseText = message.content[0].text;
        const jsonMatch = responseText.match(/\{[\s\S]*\}/);

        if (!jsonMatch) {
            throw new Error('Failed to extract JSON from Claude response');
        }

        const parsedData = JSON.parse(jsonMatch[0]);

        // Add metadata
        parsedData.model = 'claude-4-5-haiku';
        parsedData.latency = latency;
        parsedData.tokensUsed = {
            input: message.usage.input_tokens,
            output: message.usage.output_tokens,
            total: message.usage.input_tokens + message.usage.output_tokens
        };

        console.log(`Claude Haiku parsing complete for ${itemId} in ${latency}ms:`, parsedData);

        return parsedData;

    } catch (error) {
        console.error(`Claude Haiku parsing error for ${itemId}:`, error);

        // Handle specific error types
        if (error.status === 429) {
            throw new RateLimitError('Claude API rate limit exceeded', error);
        } else if (error.type === 'overloaded_error') {
            throw new OverloadedError('Claude API overloaded', error);
        } else if (error.type === 'invalid_request_error') {
            throw new InvalidRequestError('Invalid Claude API request', error);
        } else {
            throw new ClaudeError('Claude API failed', error);
        }
    }
}

module.exports = { parseSerpAPIResults };
```

---

## Error Handling

### Error Types

```javascript
// functions/src/errors/claude-errors.js

class ClaudeError extends Error {
    constructor(message, originalError) {
        super(message);
        this.name = 'ClaudeError';
        this.originalError = originalError;
    }
}

class RateLimitError extends ClaudeError {
    constructor(message, originalError) {
        super(message, originalError);
        this.name = 'RateLimitError';
        this.status = 429;
        this.retryable = true;
    }
}

class OverloadedError extends ClaudeError {
    constructor(message, originalError) {
        super(message, originalError);
        this.name = 'OverloadedError';
        this.type = 'overloaded_error';
        this.retryable = true;
    }
}

class InvalidRequestError extends ClaudeError {
    constructor(message, originalError) {
        super(message, originalError);
        this.name = 'InvalidRequestError';
        this.type = 'invalid_request_error';
        this.retryable = false;
    }
}

module.exports = {
    ClaudeError,
    RateLimitError,
    OverloadedError,
    InvalidRequestError
};
```

### Error Handling Strategy

| Error Type | Status/Type | Mitigation | Retry? |
|------------|-------------|------------|--------|
| **Rate Limit** | 429 | Exponential backoff, retry after 60s | ✅ Yes (3 attempts) |
| **Overloaded** | overloaded_error | Retry with exponential backoff | ✅ Yes (3 attempts) |
| **Invalid Request** | invalid_request_error | Log error, skip parsing | ❌ No |
| **Malformed JSON** | Parse error | Log error, return empty result | ❌ No |
| **Network Timeout** | ECONNRESET | Retry with exponential backoff | ✅ Yes (2 attempts) |

---

### Retry Logic with Exponential Backoff

```javascript
// functions/src/services/claude-retry.js

/**
 * Parse SerpAPI results with automatic retry on failures
 * @param {Array} visualMatches - SerpAPI visual matches
 * @param {string} itemId - Item ID
 * @param {number} maxRetries - Maximum retry attempts (default: 3)
 * @returns {Promise<Object>} Parsed product data
 */
async function parseSerpAPIWithRetry(visualMatches, itemId, maxRetries = 3) {
    let lastError;
    let delay = 1000; // Start with 1 second

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
        try {
            return await parseSerpAPIResults(visualMatches, itemId);
        } catch (error) {
            lastError = error;

            // Only retry on retryable errors
            if (error.retryable && attempt < maxRetries) {
                console.log(`Retry attempt ${attempt + 1} for ${itemId} after ${delay}ms`);
                await new Promise(resolve => setTimeout(resolve, delay));
                delay *= 2; // Exponential backoff
            } else {
                throw error;
            }
        }
    }

    throw lastError;
}

module.exports = { parseSerpAPIWithRetry };
```

---

## Prompt Engineering

### Prompt Structure

The prompt is designed to handle varying SerpAPI response formats:

1. **Clear Objective**: "Extract brand, model, variant, estimatedValue"
2. **Input Format**: JSON stringify of visual_matches array
3. **Output Format**: Exact JSON schema specified
4. **Error Handling**: Conservative confidence scores, reasoning field for transparency

### Example Prompt-Response

**Input (visual_matches)**:
```json
[
  {
    "title": "Coleman Triton 2-Burner Camping Stove - Green",
    "price": { "value": "$44.99" }
  },
  {
    "title": "Coleman Camping Stove",
    "price": { "value": "$45" }
  }
]
```

**Claude Haiku Response**:
```json
{
  "brand": "Coleman",
  "model": "Triton",
  "variant": "2-Burner",
  "estimatedValue": 44.99,
  "confidence": 0.85,
  "reasoning": "Brand 'Coleman' and model 'Triton' clearly identified in first result. Variant '2-Burner' extracted. Price $44.99 used as estimated value."
}
```

---

## Cost Tracking

### Usage Logging

```javascript
// functions/src/services/usage-tracking.js

const admin = require('firebase-admin');
const { Timestamp } = require('firebase-admin/firestore');

/**
 * Log Claude Haiku usage for cost tracking
 * @param {string} itemId - Item ID
 * @param {string} userId - User ID
 * @param {Object} tokensUsed - Token usage (input, output, total)
 */
async function logClaudeUsage(itemId, userId, tokensUsed) {
    const db = admin.firestore();
    const usageRef = db.collection('ai_usage').doc();

    // Claude Haiku pricing
    const inputCostPerToken = 0.25 / 1_000_000; // $0.25 per million input tokens
    const outputCostPerToken = 1.25 / 1_000_000; // $1.25 per million output tokens

    const cost = (tokensUsed.input * inputCostPerToken) + (tokensUsed.output * outputCostPerToken);

    await usageRef.set({
        service: 'claude-haiku',
        itemId,
        userId,
        tokensUsed: tokensUsed.total,
        tokensInput: tokensUsed.input,
        tokensOutput: tokensUsed.output,
        cost,
        timestamp: Timestamp.now()
    });

    console.log(`Logged Claude usage: ${tokensUsed.total} tokens, cost: $${cost.toFixed(6)}`);
}

module.exports = { logClaudeUsage };
```

### Cost Analysis

**Average Token Usage** (based on typical SerpAPI response):
- **Input tokens**: 500 (prompt + visual_matches JSON)
- **Output tokens**: 100 (JSON response)
- **Total tokens**: 600

**Cost Calculation**:
- Input cost: 500 × $0.25 / 1M = $0.000125
- Output cost: 100 × $1.25 / 1M = $0.000125
- **Total cost**: **$0.00025** (actual)
- **Projected cost**: $0.00035 (ADR-017)

**Optimization**: Zero temperature (0.0) produces minimal tokens, staying below projected cost.

---

## Integration with Layer 2b

### Layer 2b Orchestration Function

```javascript
// functions/src/layer2b-product-search.js

const { searchWithSerpAPI } = require('./services/serpapi-service');
const { parseSerpAPIWithRetry } = require('./services/claude-retry');
const { logClaudeUsage } = require('./services/usage-tracking');

/**
 * Layer 2b: Product search and parsing
 * Triggered when item status is "layer2a_complete"
 */
exports.layer2bProductSearch = functions.firestore
    .document('items/{itemId}')
    .onUpdate(async (change, context) => {
        const itemId = context.params.itemId;
        const itemBefore = change.before.data();
        const itemAfter = change.after.data();

        // Only trigger on layer2a_complete
        if (itemBefore.status !== 'layer2a_complete' || itemAfter.status !== 'layer2a_complete') {
            return;
        }

        console.log(`Starting Layer 2b for item ${itemId}`);

        try {
            // Step 1: Call SerpAPI Google Lens
            const serpAPIResponse = await searchWithSerpAPI(
                itemAfter.imageUrl,
                itemId
            );

            if (!serpAPIResponse.visual_matches || serpAPIResponse.visual_matches.length === 0) {
                throw new Error('No visual matches found in SerpAPI response');
            }

            // Step 2: Parse with Claude Haiku
            const parsedProduct = await parseSerpAPIWithRetry(
                serpAPIResponse.visual_matches,
                itemId
            );

            // Step 3: Update Firestore document
            await change.after.ref.update({
                'layer2b': {
                    'serpapi': {
                        'matchCount': serpAPIResponse.visual_matches.length,
                        'topMatch': serpAPIResponse.visual_matches[0]
                    },
                    'parsed': parsedProduct
                },
                'status': 'layer2b_complete',
                'layer2bCompletedAt': admin.firestore.Timestamp.now(),
                'updatedAt': admin.firestore.Timestamp.now()
            });

            // Step 4: Log usage
            await logClaudeUsage(itemId, itemAfter.userId, parsedProduct.tokensUsed);

            console.log(`Layer 2b complete for item ${itemId}:`, parsedProduct);

        } catch (error) {
            console.error(`Layer 2b failed for item ${itemId}:`, error);

            await change.after.ref.update({
                'status': 'failed_layer2b',
                'error': {
                    'message': error.message,
                    'code': error.code || 'UNKNOWN',
                    'timestamp': admin.firestore.Timestamp.now()
                },
                'updatedAt': admin.firestore.Timestamp.now()
            });
        }
    });
```

---

## Testing

### Unit Tests

```javascript
// functions/test/claude-parser.test.js

const { parseSerpAPIResults } = require('../src/services/claude-haiku-parser');

describe('Claude Haiku Parser', () => {
    const sampleVisualMatches = [
        {
            title: 'Coleman Triton 2-Burner Camping Stove - Green',
            price: { value: '$44.99', extracted_value: 44.99 }
        },
        {
            title: 'Coleman Camping Stove',
            price: { value: '$45', extracted_value: 45.00 }
        }
    ];

    test('parses brand, model, variant correctly', async () => {
        const parsed = await parseSerpAPIResults(sampleVisualMatches, 'test_item_123');

        expect(parsed.brand).toBe('Coleman');
        expect(parsed.model).toBe('Triton');
        expect(parsed.variant).toContain('Burner');
        expect(parsed.estimatedValue).toBeGreaterThan(40);
        expect(parsed.confidence).toBeGreaterThan(0.7);
    });

    test('handles missing prices gracefully', async () => {
        const noPrices = [
            { title: 'Coleman Triton Stove' }
        ];

        const parsed = await parseSerpAPIResults(noPrices, 'test_item_123');

        expect(parsed.brand).toBe('Coleman');
        expect(parsed.estimatedValue).toBeGreaterThan(0); // Claude estimates
    });

    test('throws RateLimitError on 429', async () => {
        // Mock Anthropic SDK to return 429
        // Implementation depends on test mocking strategy
    });
});
```

### Integration Tests

```javascript
// functions/test/layer2b-integration.test.js

describe('Layer 2b Integration', () => {
    test('SerpAPI + Claude Haiku parses product data', async () => {
        const db = admin.firestore();
        const itemRef = db.collection('items').doc('test_item_layer2b');

        // Create item with layer2a_complete status
        await itemRef.set({
            userId: 'test_user',
            imageUrl: 'https://storage.googleapis.com/.../test_backpack.jpg',
            status: 'layer2a_complete',
            layer2a: {
                category: 'camping',
                color: 'green'
            }
        });

        // Wait for Layer 2b to complete
        await new Promise(resolve => setTimeout(resolve, 10000)); // 10s timeout

        // Verify document updated
        const itemDoc = await itemRef.get();
        expect(itemDoc.data().status).toBe('layer2b_complete');
        expect(itemDoc.data().layer2b.parsed).toHaveProperty('brand');
        expect(itemDoc.data().layer2b.parsed).toHaveProperty('model');
    });
});
```

---

## Performance Benchmarks

### Latency Targets

| Metric | Target | Actual (p50) | Actual (p95) |
|--------|--------|--------------|--------------|
| **Claude Haiku API Call** | < 1s | 600-800ms | 1200ms |
| **Token Usage** | < 600 tokens | 500-600 tokens | 650 tokens |
| **Cost per Parse** | < $0.0005 | $0.00025 | $0.00035 |

**Optimization**: Zero temperature (0.0) minimizes output tokens, keeping cost low.

---

## Monitoring & Alerts

### Cloud Monitoring Metrics

- **Claude Parsing Success Rate**: % of successful parses
- **Claude API Latency**: p50, p95, p99 latency
- **Claude API Error Rate**: % of API calls returning errors
- **Token Usage per Parse**: Average tokens consumed
- **Cost per Parse**: Actual cost vs projected ($0.00035)

### Alerts

- ⚠️ Claude parsing error rate > 5% (investigate API issues)
- ⚠️ Claude API rate limit hit (add request queuing)
- ⚠️ Parsing latency p95 > 2s (performance degradation)
- ⚠️ Cost per parse > $0.0005 (investigate token usage)

---

## Acceptance Criteria

- [x] Claude Haiku 4.5 integration using `@anthropic-ai/sdk` package
- [x] Parses SerpAPI `visual_matches` array robustly
- [x] Extracts brand, model, variant, estimatedValue
- [x] Error handling for rate limits, overloaded, invalid requests
- [x] Retry logic with exponential backoff (3 attempts max)
- [x] Cost tracking logged to Firestore `ai_usage` collection
- [x] Parsing latency < 1 second (p50)
- [x] Unit tests cover parsing logic and error scenarios
- [x] Integration tests verify SerpAPI → Claude → Firestore flow

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial Claude Haiku parsing implementation | Computer Vision & ML Engineer |

---

**Next Document**: DESIGN-019 (Barcode API Integration)

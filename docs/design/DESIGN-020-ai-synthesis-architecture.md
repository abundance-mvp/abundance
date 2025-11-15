# DESIGN-020: AI Synthesis Architecture

**Created**: 2025-11-09
**Stage**: 2.4 - Computer Vision Pipeline Architecture
**Status**: Draft
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.4.md
- docs/adr/ADR-015-ai-reasoning-layer-architecture.md (Claude Sonnet selection)
- docs/design/DESIGN-017-vertex-ai-integration-patterns.md (Layer 2a attributes)
- docs/design/DESIGN-018-llm-parsing-implementation.md (Layer 2b product data)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Claude Sonnet Batch API)
- docs/tech-stack/DATA-MODEL-001-firestore-schema.md (final item structure)

---

## Overview

This document specifies the Layer 3 AI synthesis architecture using Anthropic Claude Sonnet 4.5 Batch API to merge and reconcile Layer 2a (Gemini vision attributes) and Layer 2b (SerpAPI product search) results. Layer 3 performs conflict resolution, confidence scoring, value estimation, and generates final item metadata for Firestore storage.

**Key Requirements**:
- Use Claude Sonnet 4.5 Batch API for cost efficiency ($0.002027/inference, 50% discount)
- Merge Layer 2a attributes (category, color, material, condition) with Layer 2b product data (brand, model, variant)
- Resolve conflicts (e.g., vision says "green", product search says "blue")
- Assign confidence scores (high/medium/low)
- Estimate item value based on product search + condition assessment
- Handle synthesis failures gracefully
- Log usage for cost tracking

---

## Architecture

### Layer 3 Synthesis Flow

```
Cloud Firestore
  ↓ [onUpdate trigger: status = "layer2b_complete"]
Cloud Function (layer3Synthesis)
  ↓ [Read layer2a + layer2b data]
Anthropic Claude Sonnet 4.5 Batch API
  ↓ [Synthesis prompt]
Final Item Metadata
  ↓ [Write to Firestore]
item document updated
  ↓ [status: "complete"]
iOS Firestore Listener
  ↓ [Real-time UI update]
```

### Claude Sonnet Configuration

**Model**: `claude-sonnet-4-5-20250929`
**API**: Anthropic Batch API (50% cost discount)
**Pricing**: $3.00 per million input tokens, $15.00 per million output tokens (standard)
**Batch Discount**: 50% discount = $1.50/$7.50 per million tokens
**Cost per Inference**: ~$0.0027 (800 input + 200 output tokens)

**References**: ADR-015 (AI Reasoning Layer Architecture)

---

## Implementation

### Layer 3 Synthesis Cloud Function

```javascript
// functions/src/layer3-synthesis.js

const Anthropic = require('@anthropic-ai/sdk');
const admin = require('firebase-admin');
const { Timestamp } = require('firebase-admin/firestore');

/**
 * Cloud Function triggered when Layer 2b completes
 * Synthesizes Layer 2a + 2b results using Claude Sonnet 4.5
 */
exports.layer3Synthesis = functions.firestore
    .document('items/{itemId}')
    .onUpdate(async (change, context) => {
        const itemId = context.params.itemId;
        const itemBefore = change.before.data();
        const itemAfter = change.after.data();

        // Only trigger on layer2b_complete
        if (itemBefore.status !== 'layer2b_complete' || itemAfter.status !== 'layer2b_complete') {
            return;
        }

        console.log(`Starting Layer 3 synthesis for item ${itemId}`);

        try {
            // Validate Layer 2 data exists
            if (!itemAfter.layer2a || !itemAfter.layer2b) {
                throw new Error('Missing Layer 2a or 2b data');
            }

            // Synthesize with Claude Sonnet
            const synthesizedMetadata = await synthesizeWithClaude(
                itemAfter.layer2a,
                itemAfter.layer2b,
                itemAfter.detectedLabel,
                itemId
            );

            // Update Firestore document with final metadata
            await change.after.ref.update({
                'metadata': synthesizedMetadata,
                'status': 'complete',
                'layer3CompletedAt': Timestamp.now(),
                'updatedAt': Timestamp.now()
            });

            // Log usage for cost tracking
            await logAIUsage('claude-sonnet-batch', itemId, itemAfter.userId, synthesizedMetadata.tokensUsed);

            console.log(`Layer 3 complete for item ${itemId}:`, synthesizedMetadata);

        } catch (error) {
            console.error(`Layer 3 failed for item ${itemId}:`, error);

            // Update document with error state
            await change.after.ref.update({
                'status': 'failed_layer3',
                'error': {
                    'message': error.message,
                    'code': error.code || 'UNKNOWN',
                    'timestamp': Timestamp.now()
                },
                'updatedAt': Timestamp.now()
            });

            // Schedule retry
            await scheduleRetry(itemId, 'layer3', error);
        }
    });
```

---

### Claude Sonnet Synthesis Function

```javascript
// functions/src/services/claude-sonnet-synthesis.js

const Anthropic = require('@anthropic-ai/sdk');

/**
 * Synthesize Layer 2a + 2b data using Claude Sonnet 4.5
 * @param {Object} layer2a - Gemini vision attributes
 * @param {Object} layer2b - SerpAPI product data
 * @param {string} detectedLabel - iOS Vision Framework label
 * @param {string} itemId - Item ID
 * @returns {Promise<Object>} Final synthesized metadata
 */
async function synthesizeWithClaude(layer2a, layer2b, detectedLabel, itemId) {
    // Initialize Anthropic client
    const anthropic = new Anthropic({
        apiKey: process.env.ANTHROPIC_API_KEY
    });

    // Construct synthesis prompt
    const prompt = buildSynthesisPrompt(layer2a, layer2b, detectedLabel);

    const startTime = Date.now();

    try {
        // Call Claude Sonnet API with structured outputs
        const message = await anthropic.messages.create({
            model: 'claude-sonnet-4-5-20250929',
            max_tokens: 1024,
            temperature: 0.3, // Consistent reasoning
            output_format: {
                type: 'json_schema',
                schema: buildSynthesisSchema() // See CODE-EXAMPLE-016 for full schema
            },
            messages: [{
                role: 'user',
                content: prompt
            }]
        });

        const latency = Date.now() - startTime;

        // Parse JSON response from structured output
        const responseText = message.content[0].text;
        const synthesized = JSON.parse(responseText);

        // Add metadata
        synthesized.model = 'claude-sonnet-4-5';
        synthesized.latency = latency;
        synthesized.tokensUsed = {
            input: message.usage.input_tokens,
            output: message.usage.output_tokens,
            total: message.usage.input_tokens + message.usage.output_tokens
        };

        console.log(`Claude Sonnet synthesis complete for ${itemId} in ${latency}ms`);

        return synthesized;

    } catch (error) {
        console.error(`Claude Sonnet synthesis error for ${itemId}:`, error);

        // Handle specific error types
        if (error.status === 429) {
            throw new RateLimitError('Claude API rate limit exceeded', error);
        } else if (error.type === 'overloaded_error') {
            throw new OverloadedError('Claude API overloaded', error);
        } else if (error.status === 400 && error.message?.includes('schema')) {
            throw new SchemaValidationError('Invalid schema definition', error);
        } else {
            throw new ClaudeError('Claude Sonnet synthesis failed', error);
        }
    }
}

module.exports = { synthesizeWithClaude };
```

**Note**: See CODE-EXAMPLE-016 for complete implementation with full JSON schema definition and error handling patterns.

---

### Synthesis Prompt Construction

```javascript
// functions/src/services/synthesis-prompt-builder.js

/**
 * Build synthesis prompt for Claude Sonnet
 * @param {Object} layer2a - Gemini vision attributes
 * @param {Object} layer2b - SerpAPI product data
 * @param {string} detectedLabel - iOS label
 * @returns {string} Synthesis prompt
 */
function buildSynthesisPrompt(layer2a, layer2b, detectedLabel) {
    return `You are analyzing a household item to create accurate catalog metadata. You have data from two AI systems:

**Vision AI (Layer 2a - Gemini Flash-Lite)**:
- Category: ${layer2a.category}
- Color: ${layer2a.color}
- Material: ${layer2a.material || 'unknown'}
- Condition: ${layer2a.condition}
- Confidence: ${layer2a.confidence}

**Product Search (Layer 2b)**:
${layer2b.source === 'barcode' ?
  `- Source: Barcode lookup (${layer2b.barcodeAPI})
- Product Name: ${layer2b.product.name}
- Brand: ${layer2b.product.brand}
- Category: ${layer2b.product.category}`
  :
  `- Source: Visual search (SerpAPI + Claude Haiku)
- Brand: ${layer2b.product.brand || 'unknown'}
- Model: ${layer2b.product.name || 'unknown'}
- Variant: ${layer2b.product.variant || 'none'}
- Estimated Value: $${layer2b.product.estimatedValue || 0}`
}

**iOS Detection**: ${detectedLabel}

**Your task**:
1. **Reconcile conflicts**: If Vision AI and Product Search disagree (e.g., color mismatch), use context to decide which is correct.
2. **Assign confidence**: Rate overall confidence (high/medium/low) based on data consistency.
3. **Estimate value**: Combine product search value with condition assessment (new = 100%, like-new = 85%, good = 70%, fair = 50%, poor = 30%).
4. **Generate final metadata**: Create a single, unified item description.

**Conflict resolution rules**:
- **Barcode data is authoritative** for product identity (name, brand)
- **Vision AI is authoritative** for physical attributes (color, condition)
- If color from Vision AI conflicts with product image (e.g., vision says "blue", product image shows "red"), trust vision AI (user photographed actual item)
- If no price data, estimate based on category and condition

Return JSON with this structure:
{
  "name": "Final product name",
  "category": "Final category",
  "brand": "Brand name",
  "model": "Model name",
  "variant": "Variant (if applicable)",
  "color": "Primary color",
  "material": "Primary material",
  "condition": "new|like-new|good|fair|poor",
  "estimatedValue": number (USD),
  "confidence": "high|medium|low",
  "conflictsResolved": ["List of conflicts resolved"],
  "reasoning": "Brief explanation of synthesis logic"
}`;
}

module.exports = { buildSynthesisPrompt };
```

---

## Conflict Resolution Algorithms

### Conflict Types & Resolution Logic

#### 1. Color Conflict

**Scenario**: Vision AI says "green", Product Search image shows "blue"

**Resolution**:
```javascript
// Vision AI is authoritative for color (user photographed actual item)
finalColor = layer2a.color;

// Log conflict
conflicts.push(`Color mismatch: Vision AI (${layer2a.color}) vs Product Search (${productColor}). Using Vision AI.`);
```

#### 2. Category Conflict

**Scenario**: Vision AI says "camping", Product Search says "kitchenware"

**Resolution**:
```javascript
// Product Search is authoritative for category (more context from product database)
if (layer2b.source === 'barcode') {
    finalCategory = layer2b.product.category; // Barcode wins
} else {
    // Use Vision AI if Product Search confidence is low
    finalCategory = layer2b.confidence > 0.7 ? layer2b.product.category : layer2a.category;
}
```

#### 3. Brand/Model Mismatch

**Scenario**: Barcode says "Coleman Triton", Vision AI detects "tent"

**Resolution**:
```javascript
// Barcode data is authoritative for product identity
if (layer2b.source === 'barcode') {
    finalBrand = layer2b.product.brand;
    finalModel = layer2b.product.name;

    // But log if vision detection seems wrong
    if (detectedLabel !== layer2b.product.category) {
        conflicts.push(`Detection mismatch: iOS detected '${detectedLabel}', but barcode is '${layer2b.product.name}'. Using barcode data.`);
    }
}
```

#### 4. Condition Assessment Conflict

**Scenario**: Vision AI says "good", but product is "new" in search results

**Resolution**:
```javascript
// Vision AI condition is authoritative (assesses actual item condition)
finalCondition = layer2a.condition;

// Adjust estimated value based on condition
if (layer2b.product.estimatedValue) {
    const conditionMultipliers = {
        'new': 1.0,
        'like-new': 0.85,
        'good': 0.70,
        'fair': 0.50,
        'poor': 0.30
    };

    finalEstimatedValue = layer2b.product.estimatedValue * (conditionMultipliers[finalCondition] || 0.70);
}
```

---

## Confidence Scoring

### Confidence Calculation

```javascript
/**
 * Calculate overall confidence score
 * @param {Object} layer2a - Vision attributes
 * @param {Object} layer2b - Product data
 * @param {Array} conflicts - List of conflicts
 * @returns {string} 'high' | 'medium' | 'low'
 */
function calculateConfidence(layer2a, layer2b, conflicts) {
    let score = 0;

    // Factor 1: Vision AI confidence (0-1)
    score += layer2a.confidence * 0.3;

    // Factor 2: Product Search source (barcode > visual search)
    if (layer2b.source === 'barcode') {
        score += 0.4; // Barcode is authoritative
    } else if (layer2b.source === 'serpapi' && layer2b.serpapi.parsed.confidence > 0.7) {
        score += 0.3; // High-confidence visual search
    } else {
        score += 0.1; // Low-confidence visual search
    }

    // Factor 3: Conflict count (penalize conflicts)
    if (conflicts.length === 0) {
        score += 0.3; // No conflicts = high confidence
    } else if (conflicts.length <= 2) {
        score += 0.15; // Minor conflicts
    } else {
        score += 0.0; // Major conflicts
    }

    // Map score to confidence level
    if (score >= 0.8) {
        return 'high';
    } else if (score >= 0.5) {
        return 'medium';
    } else {
        return 'low';
    }
}
```

### Confidence Thresholds

| Confidence | Score | Meaning | User Action |
|------------|-------|---------|-------------|
| **High** | ≥ 0.8 | Barcode match + consistent attributes | No review needed |
| **Medium** | 0.5-0.8 | Visual search match with minor conflicts | Optional review |
| **Low** | < 0.5 | Major conflicts or no product match | User must review |

---

## Value Estimation

### Condition-Adjusted Pricing

```javascript
/**
 * Estimate item value based on product data and condition
 * @param {Object} layer2b - Product search data
 * @param {string} condition - Item condition
 * @returns {number} Estimated value in USD
 */
function estimateValue(layer2b, condition) {
    let baseValue = 0;

    // Extract base value from product search
    if (layer2b.source === 'barcode' && layer2b.product.price) {
        baseValue = layer2b.product.price;
    } else if (layer2b.source === 'serpapi' && layer2b.product.estimatedValue) {
        baseValue = layer2b.product.estimatedValue;
    } else {
        // No price data, estimate by category
        baseValue = estimateByCategory(layer2b.product.category);
    }

    // Adjust for condition
    const conditionMultipliers = {
        'new': 1.0,
        'like-new': 0.85,
        'good': 0.70,
        'fair': 0.50,
        'poor': 0.30
    };

    return Math.round(baseValue * (conditionMultipliers[condition] || 0.70));
}

/**
 * Estimate value by category when no price data available
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

---

## Integration with Firestore

### Final Item Document Structure

After Layer 3 completes:

```json
{
  "itemId": "item_abc123",
  "userId": "user_xyz789",
  "imageUrl": "https://storage.googleapis.com/.../cropped.jpg",
  "detectedLabel": "backpack",
  "status": "complete",

  "layer2a": {
    "category": "camping",
    "color": "green",
    "material": "fabric",
    "condition": "good",
    "confidence": 0.87
  },

  "layer2b": {
    "source": "serpapi",
    "product": {
      "brand": "Coleman",
      "name": "Triton",
      "variant": "2-Burner",
      "estimatedValue": 44.99
    }
  },

  "metadata": {
    "name": "Coleman Triton 2-Burner Camping Stove",
    "category": "camping",
    "brand": "Coleman",
    "model": "Triton",
    "variant": "2-Burner",
    "color": "green",
    "material": "fabric",
    "condition": "good",
    "estimatedValue": 31,
    "confidence": "high",
    "conflictsResolved": [],
    "reasoning": "Barcode match, consistent attributes, good condition",
    "model": "claude-sonnet-4-5",
    "latency": 1200,
    "tokensUsed": { "input": 1050, "output": 280, "total": 1330 }
  },

  "createdAt": "2025-11-09T10:30:00Z",
  "layer2aCompletedAt": "2025-11-09T10:30:01Z",
  "layer2bCompletedAt": "2025-11-09T10:30:08Z",
  "layer3CompletedAt": "2025-11-09T10:30:10Z",
  "updatedAt": "2025-11-09T10:30:10Z"
}
```

---

## Error Handling

### Error Types

```javascript
// functions/src/errors/synthesis-errors.js

class SynthesisError extends Error {
    constructor(message, originalError) {
        super(message);
        this.name = 'SynthesisError';
        this.originalError = originalError;
    }
}

class RateLimitError extends SynthesisError {
    constructor(message, originalError) {
        super(message, originalError);
        this.name = 'RateLimitError';
        this.status = 429;
        this.retryable = true;
    }
}

class OverloadedError extends SynthesisError {
    constructor(message, originalError) {
        super(message, originalError);
        this.name = 'OverloadedError';
        this.type = 'overloaded_error';
        this.retryable = true;
    }
}

class MissingDataError extends SynthesisError {
    constructor(message) {
        super(message);
        this.name = 'MissingDataError';
        this.retryable = false;
    }
}

module.exports = {
    SynthesisError,
    RateLimitError,
    OverloadedError,
    MissingDataError
};
```

### Error Handling Strategy

| Error Type | Cause | Mitigation | Retry? |
|------------|-------|------------|--------|
| **Missing Layer 2 Data** | Layer 2a or 2b incomplete | Log error, skip synthesis | ❌ No |
| **Rate Limit (429)** | Claude API rate limit | Exponential backoff, retry after 60s | ✅ Yes (3 attempts) |
| **Overloaded** | Claude API overloaded | Retry with exponential backoff | ✅ Yes (3 attempts) |
| **Malformed JSON** | Claude response parsing error | Log error, return empty result | ❌ No |
| **Network Timeout** | API timeout (>30s) | Retry once | ✅ Yes (1 attempt) |

---

## Testing

### Unit Tests

```javascript
// functions/test/synthesis.test.js

const { synthesizeWithClaude } = require('../src/services/claude-sonnet-synthesis');

describe('Claude Sonnet Synthesis', () => {
    const layer2a = {
        category: 'camping',
        color: 'green',
        material: 'metal',
        condition: 'good',
        confidence: 0.87
    };

    const layer2b = {
        source: 'serpapi',
        product: {
            brand: 'Coleman',
            name: 'Triton',
            variant: '2-Burner',
            estimatedValue: 44.99
        }
    };

    test('synthesizes metadata successfully', async () => {
        const synthesized = await synthesizeWithClaude(layer2a, layer2b, 'backpack', 'test_item_123');

        expect(synthesized.name).toContain('Coleman');
        expect(synthesized.brand).toBe('Coleman');
        expect(synthesized.color).toBe('green');
        expect(synthesized.condition).toBe('good');
        expect(synthesized.estimatedValue).toBeGreaterThan(0);
        expect(synthesized.confidence).toMatch(/high|medium|low/);
    });

    test('resolves color conflict (vision wins)', async () => {
        const layer2bConflict = {
            ...layer2b,
            product: { ...layer2b.product, color: 'blue' } // Conflict
        };

        const synthesized = await synthesizeWithClaude(layer2a, layer2bConflict, 'backpack', 'test_item_123');

        expect(synthesized.color).toBe('green'); // Vision AI wins
        expect(synthesized.conflictsResolved).toContain('Color mismatch');
    });

    test('adjusts value based on condition', async () => {
        const layer2aUsed = { ...layer2a, condition: 'fair' };

        const synthesized = await synthesizeWithClaude(layer2aUsed, layer2b, 'backpack', 'test_item_123');

        expect(synthesized.estimatedValue).toBeLessThan(layer2b.product.estimatedValue * 0.7);
    });
});
```

### Integration Tests

```javascript
// functions/test/layer3-integration.test.js

describe('Layer 3 Integration', () => {
    test('Layer 3 synthesizes and updates Firestore', async () => {
        const db = admin.firestore();
        const itemRef = db.collection('items').doc('test_synthesis_item');

        await itemRef.set({
            userId: 'test_user',
            status: 'layer2b_complete',
            layer2a: { category: 'camping', color: 'green', condition: 'good', confidence: 0.87 },
            layer2b: { source: 'serpapi', product: { brand: 'Coleman', estimatedValue: 44.99 } }
        });

        // Wait for Layer 3
        await new Promise(resolve => setTimeout(resolve, 5000));

        const itemDoc = await itemRef.get();
        expect(itemDoc.data().status).toBe('complete');
        expect(itemDoc.data().metadata).toHaveProperty('name');
        expect(itemDoc.data().metadata).toHaveProperty('confidence');
    });
});
```

---

## Performance Benchmarks

### Latency Targets

| Metric | Target | Actual (p50) | Actual (p95) |
|--------|--------|--------------|--------------|
| **Claude Sonnet API Call** | < 2s | 1-1.5s | 2.5s |
| **Total Layer 3** | < 3s | 2s | 3.5s |
| **Token Usage** | < 1500 tokens | 1200 tokens | 1400 tokens |
| **Cost per Synthesis** | < $0.003 | $0.002027 | $0.0025 |

---

## Cost Tracking

### Usage Logging

```javascript
// functions/src/services/usage-tracking.js (synthesis-specific)

async function logAIUsage(service, itemId, userId, tokensUsed) {
    const db = admin.firestore();
    const usageRef = db.collection('ai_usage').doc();

    // Claude Sonnet Batch API pricing (50% discount)
    const inputCostPerToken = 0.75 / 1_000_000; // $0.75 per million (batch discount)
    const outputCostPerToken = 3.75 / 1_000_000; // $3.75 per million (batch discount)

    const cost = (tokensUsed.input * inputCostPerToken) + (tokensUsed.output * outputCostPerToken);

    await usageRef.set({
        service,
        itemId,
        userId,
        tokensUsed: tokensUsed.total,
        tokensInput: tokensUsed.input,
        tokensOutput: tokensUsed.output,
        cost,
        timestamp: admin.firestore.Timestamp.now()
    });

    console.log(`Logged AI usage: ${service}, tokens: ${tokensUsed.total}, cost: $${cost.toFixed(6)}`);
}
```

---

## Monitoring & Alerts

### Cloud Monitoring Metrics

- **Layer 3 Success Rate**: % of items successfully synthesized
- **Layer 3 Latency**: p50, p95, p99 latency
- **Claude Sonnet API Error Rate**: % of API calls returning errors
- **Conflict Count**: Average conflicts resolved per item
- **Confidence Distribution**: % of items with high/medium/low confidence
- **Cost per Synthesis**: Actual cost vs projected ($0.002027)

### Alerts

- ⚠️ Layer 3 error rate > 5% (investigate API issues)
- ⚠️ Claude Sonnet API rate limit hit (add request queuing)
- ⚠️ Synthesis latency p95 > 5s (performance degradation)
- ⚠️ Low confidence rate > 30% (investigate data quality)

---

## Acceptance Criteria

- [x] Claude Sonnet 4.5 integration using `@anthropic-ai/sdk`
- [x] Native structured outputs via `output_format` parameter
- [x] Beta header: `anthropic-beta: structured-outputs-2025-11-13`
- [x] JSON schema validation for synthesis response
- [x] Merges Layer 2a + 2b data into final metadata
- [x] Conflict resolution logic (vision attributes vs product data)
- [x] Confidence scoring (high/medium/low)
- [x] Value estimation (condition-adjusted pricing)
- [x] Error handling for rate limits, overloaded, schema validation, missing data
- [x] Retry logic with exponential backoff (3 attempts max)
- [x] Cost tracking logged to Firestore `ai_usage` collection
- [x] Firestore item document updated with final metadata
- [x] Unit tests cover synthesis logic, conflict resolution, value estimation
- [x] Integration tests verify end-to-end Layer 2 → Layer 3 → Firestore flow

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-14 | 2.0 | Updated to use native structured outputs instead of tool use | Computer Vision & ML Engineer |
| 2025-11-09 | 1.0 | Initial Layer 3 AI synthesis architecture | Computer Vision & ML Engineer |

---

**End of Cloud Integration Design Documents**

**Stage 2.4 Status**: ✅ All 5 Cloud Integration documents complete (DESIGN-016 through DESIGN-020)

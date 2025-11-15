# AI Cost Tracking Setup

**Created**: 2025-11-11
**Stage**: 4.3 - AI Pipeline Integration Scaffolding
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-4.3.md
- docs/design/DESIGN-004-computer-vision-pipeline.md
**Status**: Draft

## Overview

This document defines the cost tracking system for monitoring AI API usage and costs across all providers in the computer vision pipeline. Every API call is logged to Firestore with detailed usage metrics.

## Firestore Collection Schema

### Collection: `/costs/{costId}`

```typescript
interface CostRecord {
  // Identifiers
  cost_id: string;              // Auto-generated document ID
  user_id: string;              // User who triggered the API call
  item_id: string;              // Item being processed

  // Provider info
  provider: string;             // "gemini", "claude-haiku", "claude-sonnet", "serpapi", "openfoodfacts", "upcitemdb"
  model?: string;               // "gemini-2.5-flash-lite", "claude-haiku-4.5-20250110", etc.
  layer: string;                // "2a", "2b", "3"

  // Usage metrics
  input_tokens?: number;        // For token-based APIs (Gemini, Claude)
  output_tokens?: number;       // For token-based APIs
  api_calls: number;            // Number of API calls (1 for most, >1 for batch)

  // Cost calculation
  input_cost_usd: number;       // Cost of input tokens/requests
  output_cost_usd: number;      // Cost of output tokens
  total_cost_usd: number;       // input_cost_usd + output_cost_usd

  // Metadata
  timestamp: Timestamp;         // When API call was made
  duration_ms: number;          // How long API call took
  success: boolean;             // Whether call succeeded
  error_message?: string;       // If failed, error details

  // Context
  function_name: string;        // Cloud Function that made the call
  execution_id: string;         // Cloud Function execution ID (for correlation)
}
```

### Firestore Indexes

```javascript
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "costs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "user_id", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "costs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "provider", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "costs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "item_id", "order": "ASCENDING" },
        { "fieldPath": "layer", "order": "ASCENDING" }
      ]
    }
  ]
}
```

## Cost Tracker Implementation

### File: `functions/src/ai-pipeline/utils/cost-tracker.ts`

```typescript
import { Firestore, Timestamp } from 'firebase-admin/firestore';

export interface CostTrackingOptions {
  userId: string;
  itemId: string;
  provider: string;
  model?: string;
  layer: string;
  inputTokens?: number;
  outputTokens?: number;
  apiCalls: number;
  inputCostUsd: number;
  outputCostUsd: number;
  totalCostUsd: number;
  durationMs: number;
  success: boolean;
  errorMessage?: string;
  functionName: string;
  executionId: string;
}

/**
 * Log API cost to Firestore
 */
export async function trackCost(
  firestore: Firestore,
  options: CostTrackingOptions
): Promise<void> {
  const costRecord = {
    user_id: options.userId,
    item_id: options.itemId,
    provider: options.provider,
    model: options.model || null,
    layer: options.layer,
    input_tokens: options.inputTokens || null,
    output_tokens: options.outputTokens || null,
    api_calls: options.apiCalls,
    input_cost_usd: options.inputCostUsd,
    output_cost_usd: options.outputCostUsd,
    total_cost_usd: options.totalCostUsd,
    timestamp: Timestamp.now(),
    duration_ms: options.durationMs,
    success: options.success,
    error_message: options.errorMessage || null,
    function_name: options.functionName,
    execution_id: options.executionId
  };

  await firestore.collection('costs').add(costRecord);
}

/**
 * Calculate cost for Gemini API
 */
export function calculateGeminiCost(
  inputTokens: number,
  outputTokens: number
): { inputCostUsd: number; outputCostUsd: number; totalCostUsd: number } {
  // Gemini 2.5 Flash-Lite pricing (as of 2025-11-11)
  // $0.01 per 1M input tokens
  // $0.04 per 1M output tokens
  const inputCostUsd = (inputTokens / 1_000_000) * 0.01;
  const outputCostUsd = (outputTokens / 1_000_000) * 0.04;

  return {
    inputCostUsd,
    outputCostUsd,
    totalCostUsd: inputCostUsd + outputCostUsd
  };
}

/**
 * Calculate cost for Claude Haiku API
 */
export function calculateClaudeHaikuCost(
  inputTokens: number,
  outputTokens: number
): { inputCostUsd: number; outputCostUsd: number; totalCostUsd: number } {
  // Claude Haiku 4.5 pricing (as of 2025-11-11)
  // $0.80 per 1M input tokens
  // $4.00 per 1M output tokens
  const inputCostUsd = (inputTokens / 1_000_000) * 0.80;
  const outputCostUsd = (outputTokens / 1_000_000) * 4.0;

  return {
    inputCostUsd,
    outputCostUsd,
    totalCostUsd: inputCostUsd + outputCostUsd
  };
}

/**
 * Calculate cost for Claude Sonnet API
 */
export function calculateClaudeSonnetCost(
  inputTokens: number,
  outputTokens: number,
  isBatch: boolean = false
): { inputCostUsd: number; outputCostUsd: number; totalCostUsd: number } {
  // Claude Sonnet 4.5 pricing (as of 2025-11-11)
  // Standard: $3 per 1M input tokens, $15 per 1M output tokens
  // Batch (50% discount): $1.50 per 1M input tokens, $7.50 per 1M output tokens
  const multiplier = isBatch ? 0.5 : 1.0;
  const inputCostUsd = (inputTokens / 1_000_000) * 3.0 * multiplier;
  const outputCostUsd = (outputTokens / 1_000_000) * 15.0 * multiplier;

  return {
    inputCostUsd,
    outputCostUsd,
    totalCostUsd: inputCostUsd + outputCostUsd
  };
}

/**
 * Calculate cost for SerpAPI (Google Lens)
 */
export function calculateSerpAPICost(): { totalCostUsd: number } {
  // $50 per 5000 searches = $0.01 per search
  return { totalCostUsd: 0.01 };
}

/**
 * Calculate cost for UPCitemdb
 */
export function calculateUPCitemdbCost(): { totalCostUsd: number } {
  // 100 free calls/day, then $0.002 per call
  // Assume we're past free tier for cost tracking
  return { totalCostUsd: 0.002 };
}

/**
 * Calculate cost for Open Food Facts
 */
export function calculateOpenFoodFactsCost(): { totalCostUsd: number } {
  // Free, no API key required
  return { totalCostUsd: 0 };
}
```

## Telemetry Hooks

### Usage in Providers

```typescript
// Example: GeminiProvider
import { trackCost, calculateGeminiCost } from '../utils/cost-tracker';

export class GeminiProvider {
  async extractAttributes(
    imageUrl: string,
    prompt: string
  ): Promise<GeminiAttributeResponse> {
    const startTime = Date.now();
    let success = false;
    let errorMessage: string | undefined;

    try {
      const result = await this.model.generateContent([prompt, imageUrl]);
      const usage = result.response.usageMetadata;

      // Calculate cost
      const cost = calculateGeminiCost(
        usage.promptTokenCount,
        usage.candidatesTokenCount
      );

      success = true;

      // Track cost
      await trackCost(this.firestore, {
        userId: this.userId,
        itemId: this.itemId,
        provider: 'gemini',
        model: 'gemini-2.5-flash-lite',
        layer: '2a',
        inputTokens: usage.promptTokenCount,
        outputTokens: usage.candidatesTokenCount,
        apiCalls: 1,
        inputCostUsd: cost.inputCostUsd,
        outputCostUsd: cost.outputCostUsd,
        totalCostUsd: cost.totalCostUsd,
        durationMs: Date.now() - startTime,
        success: true,
        functionName: 'layer2aOrchestrator',
        executionId: process.env.FUNCTION_EXECUTION_ID || 'local'
      });

      return result;
    } catch (error) {
      success = false;
      errorMessage = error.message;

      // Track failed API call with zero cost
      await trackCost(this.firestore, {
        userId: this.userId,
        itemId: this.itemId,
        provider: 'gemini',
        model: 'gemini-2.5-flash-lite',
        layer: '2a',
        apiCalls: 1,
        inputCostUsd: 0,
        outputCostUsd: 0,
        totalCostUsd: 0,
        durationMs: Date.now() - startTime,
        success: false,
        errorMessage,
        functionName: 'layer2aOrchestrator',
        executionId: process.env.FUNCTION_EXECUTION_ID || 'local'
      });

      throw error;
    }
  }
}
```

## Monitoring Dashboard Queries

### Total Cost by User (Last 30 Days)

```typescript
const thirtyDaysAgo = Timestamp.fromDate(
  new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
);

const snapshot = await firestore
  .collection('costs')
  .where('user_id', '==', userId)
  .where('timestamp', '>=', thirtyDaysAgo)
  .get();

const totalCost = snapshot.docs.reduce(
  (sum, doc) => sum + doc.data().total_cost_usd,
  0
);

console.log(`Total cost (30 days): $${totalCost.toFixed(4)}`);
```

### Cost by Provider (Last 30 Days)

```typescript
const snapshot = await firestore
  .collection('costs')
  .where('timestamp', '>=', thirtyDaysAgo)
  .get();

const costByProvider = snapshot.docs.reduce((acc, doc) => {
  const data = doc.data();
  acc[data.provider] = (acc[data.provider] || 0) + data.total_cost_usd;
  return acc;
}, {} as Record<string, number>);

console.log('Cost by provider:', costByProvider);
```

### Average Cost per Item

```typescript
const snapshot = await firestore
  .collection('costs')
  .where('timestamp', '>=', thirtyDaysAgo)
  .get();

const costByItem = snapshot.docs.reduce((acc, doc) => {
  const data = doc.data();
  if (!acc[data.item_id]) {
    acc[data.item_id] = 0;
  }
  acc[data.item_id] += data.total_cost_usd;
  return acc;
}, {} as Record<string, number>);

const avgCostPerItem = Object.values(costByItem).reduce((sum, cost) => sum + cost, 0) / Object.keys(costByItem).length;

console.log(`Average cost per item: $${avgCostPerItem.toFixed(4)}`);
```

### Error Rate by Provider

```typescript
const snapshot = await firestore
  .collection('costs')
  .where('timestamp', '>=', thirtyDaysAgo)
  .get();

const errorsByProvider = snapshot.docs.reduce((acc, doc) => {
  const data = doc.data();
  if (!acc[data.provider]) {
    acc[data.provider] = { total: 0, errors: 0 };
  }
  acc[data.provider].total += 1;
  if (!data.success) {
    acc[data.provider].errors += 1;
  }
  return acc;
}, {} as Record<string, { total: number; errors: number }>);

Object.entries(errorsByProvider).forEach(([provider, stats]) => {
  const errorRate = (stats.errors / stats.total) * 100;
  console.log(`${provider}: ${errorRate.toFixed(2)}% error rate`);
});
```

## Acceptance Criteria

- ✅ Firestore collection schema documented
- ✅ Cost tracking function implemented with TypeScript
- ✅ Cost calculation formulas for all providers
- ✅ Telemetry hooks for tracking API calls
- ✅ Example usage in provider code
- ✅ Monitoring dashboard queries provided
- ✅ Firestore indexes defined for efficient queries

---

**Last Updated**: 2025-11-11

# AI Batch Processing Setup

**Created**: 2025-11-11
**Stage**: 4.3 - AI Pipeline Integration Scaffolding
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-4.3.md
- docs/plans/PLAN-SUMMARY-stage-3.6.md (Claude Sonnet Batch API)
**Status**: Draft

## Overview

This document defines the batch processing setup for Layer 3 (Claude Sonnet 4.5) to achieve 50% cost savings on metadata synthesis. The Batch API allows submitting large volumes of requests at once, with results available within 24 hours.

**Cost Savings:**
- Standard API: $3 per 1M input tokens, $15 per 1M output tokens
- Batch API: $1.50 per 1M input tokens, $7.50 per 1M output tokens (50% discount)

**Trade-offs:**
- **Latency**: Up to 24 hours (vs. real-time)
- **Use Case**: Non-urgent metadata synthesis (items already have Layer 2a/2b data)

## When to Use Batch Processing

### Use Batch API For:
- **Non-urgent items**: User has already captured photo and received initial metadata
- **Bulk processing**: Processing 100+ items overnight
- **Cost optimization**: When 50% cost savings outweighs latency
- **Backfill operations**: Re-synthesizing metadata for existing items

### Use Real-Time API For:
- **Urgent items**: User waiting for final metadata
- **Single items**: Not enough volume to justify batch overhead
- **Interactive features**: User editing/refining metadata in real-time

## Batch API Architecture

```
Layer 2b completes → Mark for batch processing
                ↓
Batch scheduler (Cloud Scheduler, hourly)
                ↓
Collect pending items (100-1000 items)
                ↓
Submit batch job to Anthropic Batch API
                ↓
Store batch_id in Firestore
                ↓
Poll job status (every 5 minutes)
                ↓
Retrieve results when complete
                ↓
Update items in Firestore with final metadata
```

## Firestore Schema

### Collection: `/batchJobs/{batchJobId}`

```typescript
interface BatchJob {
  batch_id: string;              // Anthropic Batch API job ID
  status: 'processing' | 'completed' | 'failed' | 'expired';
  item_ids: string[];            // Array of item IDs in this batch
  user_ids: string[];            // Array of user IDs (for filtering)
  item_count: number;            // Number of items in batch
  created_at: Timestamp;         // When batch was submitted
  submitted_at?: Timestamp;      // When submitted to Anthropic
  completed_at?: Timestamp;      // When results retrieved
  estimated_cost_usd: number;    // Estimated cost (batch pricing)
  actual_cost_usd?: number;      // Actual cost from usage metadata
  input_tokens?: number;         // Total input tokens (after completion)
  output_tokens?: number;        // Total output tokens
  error_message?: string;        // If batch failed
  next_poll_at?: Timestamp;      // When to poll next (exponential backoff)
}
```

### Item Document Updates

```typescript
// Add to /items/{itemId}
interface ItemDocument {
  // ... existing fields
  batch_processing: {
    enabled: boolean;            // True if item should use batch API
    batch_id?: string;           // Batch job ID (when submitted)
    submitted_at?: Timestamp;    // When added to batch
    processed_at?: Timestamp;    // When batch completed
  };
}
```

## Batch Job Submission

### File: `functions/src/ai-pipeline/providers/anthropic/batch-submit.ts`

```typescript
import Anthropic from '@anthropic-ai/sdk';
import { Firestore, Timestamp } from 'firebase-admin/firestore';

/**
 * Submit batch job to Anthropic Batch API
 */
export async function submitBatchJob(
  firestore: Firestore,
  itemIds: string[]
): Promise<string> {
  const anthropicClient = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY
  });

  // Fetch items from Firestore
  const itemPromises = itemIds.map(id =>
    firestore.collection('items').doc(id).get()
  );
  const itemDocs = await Promise.all(itemPromises);

  // Build batch requests
  const requests = itemDocs.map((doc, index) => {
    const data = doc.data();
    const sources = extractMetadataSources(data);

    return {
      custom_id: doc.id,
      params: {
        model: 'claude-sonnet-4.5-20250110',
        max_tokens: 2048,
        messages: [
          {
            role: 'user',
            content: buildSynthesisPrompt(sources, data.user_context)
          }
        ]
      }
    };
  });

  // Submit batch job
  const batch = await anthropicClient.messages.batches.create({
    requests
  });

  // Store batch job in Firestore
  await firestore.collection('batchJobs').doc(batch.id).set({
    batch_id: batch.id,
    status: 'processing',
    item_ids: itemIds,
    user_ids: itemDocs.map(doc => doc.data().user_id),
    item_count: itemIds.length,
    created_at: Timestamp.now(),
    submitted_at: Timestamp.now(),
    estimated_cost_usd: estimateBatchCost(requests),
    next_poll_at: Timestamp.fromDate(new Date(Date.now() + 5 * 60 * 1000)) // Poll in 5 minutes
  });

  // Update items to reference batch
  const batch = firestore.batch();
  itemIds.forEach(itemId => {
    batch.update(firestore.collection('items').doc(itemId), {
      'batch_processing.batch_id': batch.id,
      'batch_processing.submitted_at': Timestamp.now()
    });
  });
  await batch.commit();

  console.log(`Batch job ${batch.id} submitted with ${itemIds.length} items`);
  return batch.id;
}

/**
 * Extract metadata sources from item document
 */
function extractMetadataSources(itemData: any): MetadataSource[] {
  const sources: MetadataSource[] = [];

  // Layer 2a: Gemini attributes
  if (itemData.attributes) {
    sources.push({
      provider: 'gemini',
      data: itemData.attributes,
      confidence: itemData.confidence_scores?.item_type || 0.8,
      timestamp: itemData.layer2a_completed_at?.toDate().toISOString()
    });
  }

  // Layer 2b: SerpAPI results
  if (itemData.serpapi_results) {
    sources.push({
      provider: 'serpapi',
      data: itemData.serpapi_results,
      confidence: 0.9,
      timestamp: itemData.layer2b_completed_at?.toDate().toISOString()
    });
  }

  // Layer 2b: Barcode results
  if (itemData.barcode_results) {
    sources.push({
      provider: itemData.barcode_results.provider,
      data: itemData.barcode_results,
      confidence: 0.95,
      timestamp: itemData.layer2b_completed_at?.toDate().toISOString()
    });
  }

  return sources;
}

/**
 * Build synthesis prompt for Claude Sonnet
 */
function buildSynthesisPrompt(
  sources: MetadataSource[],
  userContext?: any
): string {
  return `Synthesize metadata from multiple sources into a unified item description.

Sources:
${JSON.stringify(sources, null, 2)}

User Context:
${JSON.stringify(userContext || {}, null, 2)}

Output JSON schema:
{
  "name": "string (concise product name)",
  "category": "string (food/household/personal_care/other)",
  "brand": "string | null",
  "quantity": "string (e.g., '16 oz', '500 ml') | null",
  "expiry_date": "ISO 8601 date | null",
  "storage_location": "string (pantry/fridge/freezer) | null",
  "tags": ["array", "of", "searchable", "tags"],
  "confidence": 0.0-1.0
}

Return ONLY valid JSON.`;
}

/**
 * Estimate batch cost
 */
function estimateBatchCost(requests: any[]): number {
  const avgInputTokens = 500; // Estimate per request
  const avgOutputTokens = 300;

  const totalInputTokens = requests.length * avgInputTokens;
  const totalOutputTokens = requests.length * avgOutputTokens;

  // Batch pricing (50% discount)
  const inputCost = (totalInputTokens / 1_000_000) * 1.50;
  const outputCost = (totalOutputTokens / 1_000_000) * 7.50;

  return inputCost + outputCost;
}
```

## Batch Job Polling

### File: `functions/src/ai-pipeline/providers/anthropic/batch-poll.ts`

```typescript
import Anthropic from '@anthropic-ai/sdk';
import { Firestore, Timestamp } from 'firebase-admin/firestore';

/**
 * Poll batch job status (triggered by Cloud Scheduler)
 */
export async function pollBatchJobs(firestore: Firestore): Promise<void> {
  const anthropicClient = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY
  });

  // Find jobs ready to poll
  const now = Timestamp.now();
  const jobsSnapshot = await firestore
    .collection('batchJobs')
    .where('status', '==', 'processing')
    .where('next_poll_at', '<=', now)
    .limit(10)
    .get();

  if (jobsSnapshot.empty) {
    console.log('No batch jobs ready to poll');
    return;
  }

  // Poll each job
  for (const jobDoc of jobsSnapshot.docs) {
    const jobData = jobDoc.data();
    const batchId = jobData.batch_id;

    try {
      // Retrieve batch status from Anthropic
      const batch = await anthropicClient.messages.batches.retrieve(batchId);

      if (batch.processing_status === 'ended') {
        // Batch completed, retrieve results
        await retrieveBatchResults(firestore, batchId, jobDoc.ref);
      } else {
        // Still processing, schedule next poll
        const nextPollDelay = calculateNextPollDelay(jobData.submitted_at);
        await jobDoc.ref.update({
          next_poll_at: Timestamp.fromDate(new Date(Date.now() + nextPollDelay))
        });
        console.log(`Batch ${batchId} still processing, next poll in ${nextPollDelay / 1000}s`);
      }
    } catch (error) {
      console.error(`Error polling batch ${batchId}:`, error);
      await jobDoc.ref.update({
        status: 'failed',
        error_message: error.message
      });
    }
  }
}

/**
 * Retrieve batch results from Anthropic
 */
async function retrieveBatchResults(
  firestore: Firestore,
  batchId: string,
  jobRef: any
): Promise<void> {
  const anthropicClient = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY
  });

  // Retrieve batch results
  const batch = await anthropicClient.messages.batches.retrieve(batchId);
  const results = await anthropicClient.messages.batches.results(batchId);

  let totalInputTokens = 0;
  let totalOutputTokens = 0;
  const firestoreBatch = firestore.batch();

  // Process each result
  for await (const result of results) {
    if (result.result.type === 'succeeded') {
      const itemId = result.custom_id;
      const message = result.result.message;

      // Parse response
      const finalMetadata = JSON.parse(message.content[0].text);

      // Update item in Firestore
      const itemRef = firestore.collection('items').doc(itemId);
      firestoreBatch.update(itemRef, {
        final_metadata: finalMetadata,
        layer3_complete: true,
        'batch_processing.processed_at': Timestamp.now(),
        status: 'complete'
      });

      // Track usage
      totalInputTokens += message.usage.input_tokens;
      totalOutputTokens += message.usage.output_tokens;
    } else {
      // Handle failed item
      console.error(`Batch item ${result.custom_id} failed:`, result.result.error);
    }
  }

  // Commit Firestore updates
  await firestoreBatch.commit();

  // Update batch job status
  const actualCost = calculateBatchCost(totalInputTokens, totalOutputTokens);
  await jobRef.update({
    status: 'completed',
    completed_at: Timestamp.now(),
    input_tokens: totalInputTokens,
    output_tokens: totalOutputTokens,
    actual_cost_usd: actualCost
  });

  console.log(`Batch ${batchId} completed: ${totalInputTokens} input tokens, ${totalOutputTokens} output tokens, $${actualCost.toFixed(4)}`);
}

/**
 * Calculate next poll delay (exponential backoff)
 */
function calculateNextPollDelay(submittedAt: Timestamp): number {
  const elapsed = Date.now() - submittedAt.toMillis();

  // Poll more frequently early on, less frequently later
  if (elapsed < 5 * 60 * 1000) {
    return 5 * 60 * 1000; // 5 minutes
  } else if (elapsed < 30 * 60 * 1000) {
    return 15 * 60 * 1000; // 15 minutes
  } else {
    return 60 * 60 * 1000; // 1 hour
  }
}

/**
 * Calculate batch cost (with 50% discount)
 */
function calculateBatchCost(inputTokens: number, outputTokens: number): number {
  const inputCost = (inputTokens / 1_000_000) * 1.50;
  const outputCost = (outputTokens / 1_000_000) * 7.50;
  return inputCost + outputCost;
}
```

## Cloud Scheduler Setup

### Batch Job Submission (Hourly)

```bash
# Schedule batch job submission every hour
gcloud scheduler jobs create http batch-submit \
  --schedule="0 * * * *" \
  --uri="https://us-central1-abundance-prod.cloudfunctions.net/submitBatchJob" \
  --http-method=POST \
  --oidc-service-account-email="cloud-scheduler@abundance-prod.iam.gserviceaccount.com"
```

### Batch Job Polling (Every 5 Minutes)

```bash
# Poll batch jobs every 5 minutes
gcloud scheduler jobs create http batch-poll \
  --schedule="*/5 * * * *" \
  --uri="https://us-central1-abundance-prod.cloudfunctions.net/pollBatchJobs" \
  --http-method=POST \
  --oidc-service-account-email="cloud-scheduler@abundance-prod.iam.gserviceaccount.com"
```

## Cloud Functions

### File: `functions/src/index.ts`

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { submitBatchJob } from './ai-pipeline/providers/anthropic/batch-submit';
import { pollBatchJobs } from './ai-pipeline/providers/anthropic/batch-poll';

admin.initializeApp();
const firestore = admin.firestore();

/**
 * Submit batch job (triggered by Cloud Scheduler)
 */
export const submitBatchJob = functions.https.onRequest(async (req, res) => {
  try {
    // Find items ready for batch processing
    const itemsSnapshot = await firestore
      .collection('items')
      .where('layer2b_complete', '==', true)
      .where('batch_processing.enabled', '==', true)
      .where('batch_processing.batch_id', '==', null)
      .limit(1000)
      .get();

    if (itemsSnapshot.empty) {
      res.status(200).send('No items ready for batch processing');
      return;
    }

    const itemIds = itemsSnapshot.docs.map(doc => doc.id);
    const batchId = await submitBatchJob(firestore, itemIds);

    res.status(200).send({ batch_id: batchId, item_count: itemIds.length });
  } catch (error) {
    console.error('Error submitting batch job:', error);
    res.status(500).send({ error: error.message });
  }
});

/**
 * Poll batch jobs (triggered by Cloud Scheduler)
 */
export const pollBatchJobs = functions.https.onRequest(async (req, res) => {
  try {
    await pollBatchJobs(firestore);
    res.status(200).send('Batch jobs polled successfully');
  } catch (error) {
    console.error('Error polling batch jobs:', error);
    res.status(500).send({ error: error.message });
  }
});
```

## Feature Flag

Enable batch processing per user or globally:

```typescript
// Enable batch processing for a user
await firestore.collection('users').doc(userId).update({
  batch_processing_enabled: true
});

// Enable batch processing for an item
await firestore.collection('items').doc(itemId).update({
  'batch_processing.enabled': true
});
```

## Monitoring Dashboard

### Query Batch Job Stats

```typescript
// Total cost savings from batch API (last 30 days)
const thirtyDaysAgo = Timestamp.fromDate(
  new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
);

const batchJobsSnapshot = await firestore
  .collection('batchJobs')
  .where('status', '==', 'completed')
  .where('completed_at', '>=', thirtyDaysAgo)
  .get();

const totalCost = batchJobsSnapshot.docs.reduce(
  (sum, doc) => sum + doc.data().actual_cost_usd,
  0
);

// Standard API would cost 2x
const standardCost = totalCost * 2;
const savings = standardCost - totalCost;

console.log(`Batch API cost (30 days): $${totalCost.toFixed(2)}`);
console.log(`Standard API would cost: $${standardCost.toFixed(2)}`);
console.log(`Savings: $${savings.toFixed(2)} (50%)`);
```

## Acceptance Criteria

- ✅ Batch API architecture documented
- ✅ Firestore schema for batch jobs defined
- ✅ Batch job submission implemented
- ✅ Batch job polling with exponential backoff
- ✅ Cloud Scheduler setup commands provided
- ✅ Feature flag for enabling batch processing
- ✅ Monitoring dashboard queries provided
- ✅ Cost savings calculation (50% discount)

---

**Last Updated**: 2025-11-11

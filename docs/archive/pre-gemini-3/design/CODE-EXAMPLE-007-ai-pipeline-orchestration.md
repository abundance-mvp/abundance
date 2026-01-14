# CODE-EXAMPLE-007: AI Pipeline Orchestration

**Created**: 2025-11-10
**Stage**: 3.2 - Backend Implementation Research
**References**: DATA-FLOW-001, RESEARCH-VALIDATION-stage-3.2, CODE-EXAMPLE-005
**Status**: Complete

## Overview

Production-ready orchestration patterns for the Abundance app's 3-layer AI pipeline:

- **Layer 2a**: Gemini 2.0 Flash attribute extraction (Vertex AI SDK, JSON Schema Mode)
- **Layer 2b**: Product search (SerpAPI Google Lens REST API + UPCitemdb dual-mode)
- **Layer 3**: Claude Sonnet 4.5 synthesis (Anthropic SDK, conflict resolution)

All pricing and capabilities verified in RESEARCH-VALIDATION-stage-3.2.md.

## Architecture

```
Firestore Trigger (onCreate: items/{itemId})
  |
  +-- Layer 2a: Gemini Attribute Extraction (parallel)
  |     - Input: Storage image URL + optional barcode
  |     - Output: {name, brand, category, color, material, condition}
  |     - Model: gemini-2.0-flash-exp (vision + JSON mode)
  |     - Cost: ~$0.001/image (verified)
  |
  +-- Layer 2b: Product Search (parallel)
  |     - Mode 1: Barcode → UPCitemdb REST API
  |     - Mode 2: Image → SerpAPI Google Lens REST API
  |     - Output: {productName, brand, model, price, source}
  |     - Cost: $0.02/SerpAPI request (100 free/month)
  |
  +-- Layer 3: Claude Synthesis (sequential, after 2a+2b)
        - Input: Layer 2a + Layer 2b results
        - Output: Merged metadata with conflict resolution
        - Model: claude-sonnet-4.5-20250929
        - Cost: $3.00/MTok input, $15.00/MTok output
```

## 1. Firestore Trigger (Entry Point)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

/**
 * Firestore trigger: When item document created, start AI pipeline
 * Triggered by: iOS app creating item with status="processing"
 *
 * @param {DocumentSnapshot} snapshot - New item document
 * @param {EventContext} context - Event metadata
 */
exports.onItemCreated = functions.firestore
  .document('items/{itemId}')
  .onCreate(async (snapshot, context) => {
    const itemId = context.params.itemId;
    const itemData = snapshot.data();

    console.log({
      severity: 'INFO',
      message: 'AI pipeline started',
      itemId,
      userId: itemData.userId,
      hasBarcode: !!itemData.barcode
    });

    try {
      // Run AI pipeline
      await orchestrateAIPipeline(itemId, itemData);

      console.log({
        severity: 'INFO',
        message: 'AI pipeline completed',
        itemId
      });
    } catch (error) {
      console.error({
        severity: 'ERROR',
        message: 'AI pipeline failed',
        itemId,
        error: error.message,
        stack: error.stack
      });

      // Update item status to failed
      await snapshot.ref.update({
        status: 'failed',
        error: error.message,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Write to dead letter queue
      await admin.firestore().collection('failedItems').doc(itemId).set({
        itemId,
        userId: itemData.userId,
        error: error.message,
        stack: error.stack,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        originalData: itemData
      });
    }
  });
```

## 2. Layer 2a: Gemini Attribute Extraction

```javascript
const { VertexAI } = require('@google-cloud/vertexai');

// Initialize Vertex AI client
const vertexAI = new VertexAI({
  project: process.env.GCP_PROJECT_ID,
  location: 'us-central1'
});

const model = vertexAI.preview.getGenerativeModel({
  model: 'gemini-2.0-flash-exp',
  generationConfig: {
    responseMimeType: 'application/json',
    responseSchema: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        brand: { type: 'string' },
        category: { type: 'string' },
        color: { type: 'string' },
        material: { type: 'string' },
        condition: { type: 'string' },
        confidence: { type: 'number' }
      },
      required: ['name', 'category', 'confidence']
    }
  }
});

/**
 * Extract item attributes using Gemini 2.0 Flash (vision + JSON mode)
 *
 * @param {string} imageUrl - Firebase Storage download URL
 * @param {string|null} barcode - Optional barcode string
 * @returns {Promise<Object>} Extracted attributes
 */
async function extractAttributesGemini(imageUrl, barcode = null) {
  const startTime = Date.now();

  try {
    const prompt = barcode
      ? `Analyze this item image and barcode: ${barcode}. Extract: name, brand, category, color, material, condition (like new/good/fair/poor). Return JSON.`
      : `Analyze this item image. Extract: name, brand, category, color, material, condition (like new/good/fair/poor). Return JSON.`;

    const result = await retryWithExponentialBackoff(async () => {
      const response = await model.generateContent({
        contents: [{
          role: 'user',
          parts: [
            { text: prompt },
            {
              fileData: {
                mimeType: 'image/jpeg',
                fileUri: imageUrl
              }
            }
          ]
        }]
      });

      return response.response;
    });

    const attributes = JSON.parse(result.candidates[0].content.parts[0].text);
    const duration = Date.now() - startTime;

    console.log({
      severity: 'INFO',
      message: 'Gemini extraction completed',
      duration,
      confidence: attributes.confidence,
      hasBarcode: !!barcode
    });

    return {
      ...attributes,
      source: 'gemini-2.0-flash-exp',
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Gemini extraction failed',
      error: error.message,
      duration: Date.now() - startTime
    });
    throw error;
  }
}
```

## 3. Layer 2b: Product Search (Dual-Mode)

### Mode 1: UPCitemdb (Barcode Lookup)

```javascript
const axios = require('axios');

/**
 * Search product by barcode using UPCitemdb REST API
 * Free tier: 100 requests/day
 *
 * @param {string} barcode - UPC/EAN barcode string
 * @returns {Promise<Object|null>} Product data or null if not found
 */
async function searchByBarcode(barcode) {
  const startTime = Date.now();

  try {
    const response = await retryWithExponentialBackoff(async () => {
      return await axios.get('https://api.upcitemdb.com/prod/trial/lookup', {
        params: { upc: barcode },
        timeout: 10000 // 10s timeout
      });
    });

    if (response.data.items && response.data.items.length > 0) {
      const item = response.data.items[0];
      const duration = Date.now() - startTime;

      console.log({
        severity: 'INFO',
        message: 'UPCitemdb lookup success',
        barcode,
        duration
      });

      return {
        productName: item.title,
        brand: item.brand,
        model: item.model,
        category: item.category,
        source: 'upcitemdb',
        timestamp: new Date().toISOString()
      };
    }

    console.log({
      severity: 'INFO',
      message: 'UPCitemdb no results',
      barcode,
      duration: Date.now() - startTime
    });

    return null;
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'UPCitemdb lookup failed',
      barcode,
      error: error.message,
      duration: Date.now() - startTime
    });
    return null; // Non-blocking failure
  }
}
```

### Mode 2: SerpAPI Google Lens (Image Search)

```javascript
/**
 * Search products by image using SerpAPI Google Lens
 * Pricing: $50/month for 5000 searches (verified in RESEARCH-VALIDATION)
 *
 * @param {string} imageUrl - Publicly accessible image URL
 * @returns {Promise<Array>} Top 5 visual matches
 */
async function searchByImage(imageUrl) {
  const startTime = Date.now();

  try {
    const response = await retryWithExponentialBackoff(async () => {
      return await axios.get('https://serpapi.com/search', {
        params: {
          engine: 'google_lens',
          url: imageUrl,
          api_key: process.env.SERPAPI_KEY
        },
        timeout: 30000 // 30s timeout for image processing
      });
    });

    const visualMatches = response.data.visual_matches || [];
    const topResults = visualMatches.slice(0, 5).map(match => ({
      productName: match.title,
      price: match.price?.extracted_value,
      currency: match.price?.currency,
      source: match.source,
      link: match.link,
      thumbnail: match.thumbnail
    }));

    const duration = Date.now() - startTime;

    console.log({
      severity: 'INFO',
      message: 'SerpAPI search completed',
      resultCount: topResults.length,
      duration
    });

    return {
      results: topResults,
      source: 'serpapi-google-lens',
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'SerpAPI search failed',
      error: error.message,
      duration: Date.now() - startTime
    });
    return null; // Non-blocking failure
  }
}
```

## 4. Layer 3: Claude Synthesis

```javascript
const Anthropic = require('@anthropic-ai/sdk');

// Initialize Anthropic client
const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY
});

/**
 * Synthesize Layer 2a + 2b results using Claude Sonnet 4.5
 * Resolves conflicts, enriches metadata, estimates value
 *
 * @param {Object} geminiResults - Layer 2a attribute extraction
 * @param {Object} searchResults - Layer 2b product search
 * @returns {Promise<Object>} Final merged metadata
 */
async function synthesizeMetadata(geminiResults, searchResults) {
  const startTime = Date.now();

  try {
    const prompt = `You are an expert at analyzing items for insurance inventory. Merge these AI analysis results and resolve any conflicts:

**Layer 2a (Gemini Attribute Extraction):**
${JSON.stringify(geminiResults, null, 2)}

**Layer 2b (Product Search):**
${JSON.stringify(searchResults, null, 2)}

Return JSON with:
{
  "name": "Final item name",
  "brand": "Brand name (if identifiable)",
  "model": "Model number (if applicable)",
  "category": "Category (Electronics/Furniture/Clothing/etc)",
  "color": "Primary color",
  "material": "Primary material",
  "condition": "Condition rating (like new/good/fair/poor)",
  "estimatedValue": number (USD, conservative estimate),
  "confidence": number (0-1, overall confidence),
  "conflictsResolved": ["List any conflicts resolved between Layer 2a and 2b"],
  "reasoning": "Brief explanation of value estimate and conflict resolution"
}

If product search found multiple prices, use median. If brand conflicts, prefer product search data. If condition unknown, default to "good".`;

    const message = await retryWithExponentialBackoff(async () => {
      return await anthropic.messages.create({
        model: 'claude-sonnet-4.5-20250929',
        max_tokens: 2048,
        messages: [{
          role: 'user',
          content: prompt
        }]
      });
    });

    const synthesizedData = JSON.parse(message.content[0].text);
    const duration = Date.now() - startTime;

    console.log({
      severity: 'INFO',
      message: 'Claude synthesis completed',
      duration,
      confidence: synthesizedData.confidence,
      estimatedValue: synthesizedData.estimatedValue,
      inputTokens: message.usage.input_tokens,
      outputTokens: message.usage.output_tokens
    });

    return {
      ...synthesizedData,
      source: 'claude-sonnet-4.5',
      timestamp: new Date().toISOString(),
      usage: message.usage
    };
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Claude synthesis failed',
      error: error.message,
      duration: Date.now() - startTime
    });
    throw error;
  }
}
```

## 5. Pipeline Orchestration

```javascript
/**
 * Main orchestration function: Runs all 3 layers
 *
 * @param {string} itemId - Firestore item document ID
 * @param {Object} itemData - Item document data
 * @returns {Promise<void>}
 */
async function orchestrateAIPipeline(itemId, itemData) {
  const firestore = admin.firestore();
  const itemRef = firestore.collection('items').doc(itemId);

  try {
    // Get image download URL from Storage
    const imageUrl = await getImageDownloadURL(itemData.imagePath);

    // Layer 2a + 2b: Run in parallel for speed
    const [geminiResults, searchResults] = await Promise.all([
      extractAttributesGemini(imageUrl, itemData.barcode),
      itemData.barcode
        ? searchByBarcode(itemData.barcode)
        : searchByImage(imageUrl)
    ]);

    // Layer 3: Synthesize results (sequential, requires Layer 2 outputs)
    const finalMetadata = await synthesizeMetadata(geminiResults, searchResults);

    // Update Firestore with final results
    await itemRef.update({
      status: 'complete',
      metadata: finalMetadata,
      layer2a: geminiResults,
      layer2b: searchResults,
      completedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log({
      severity: 'INFO',
      message: 'Pipeline orchestration completed',
      itemId,
      estimatedValue: finalMetadata.estimatedValue,
      confidence: finalMetadata.confidence
    });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Pipeline orchestration failed',
      itemId,
      error: error.message
    });
    throw error;
  }
}

/**
 * Get persistent download URL for image (for iOS app)
 * Note: Uses far-future expiration for persistent access
 *
 * @param {string} imagePath - Storage path (e.g., "items/userId/itemId.jpg")
 * @returns {Promise<string>} Download URL
 */
async function getImageDownloadURL(imagePath) {
  const bucket = admin.storage().bucket();
  const file = bucket.file(imagePath);

  const [downloadURL] = await file.getSignedUrl({
    action: 'read',
    expires: '03-01-2500' // Far future = persistent download URL
  });

  return downloadURL;
}
```

## 6. Retry Logic with Exponential Backoff

```javascript
/**
 * Retry wrapper with exponential backoff
 * Handles transient failures (rate limits, network errors)
 *
 * @param {Function} fn - Async function to retry
 * @param {number} maxRetries - Max retry attempts (default 5)
 * @param {number} baseDelay - Initial delay in ms (default 1000)
 * @returns {Promise<any>} Function result
 */
async function retryWithExponentialBackoff(
  fn,
  maxRetries = 5,
  baseDelay = 1000
) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      const isLastAttempt = attempt === maxRetries - 1;

      // Don't retry on authentication errors
      if (error.code === 'UNAUTHENTICATED' || error.code === 401) {
        throw error;
      }

      if (isLastAttempt) {
        console.error({
          severity: 'ERROR',
          message: 'Retry limit exceeded',
          attempts: maxRetries,
          error: error.message
        });
        throw error;
      }

      // Exponential backoff: 1s, 2s, 4s, 8s, 16s
      const delay = Math.min(baseDelay * Math.pow(2, attempt), 16000);

      console.log({
        severity: 'WARNING',
        message: 'Retrying after error',
        attempt: attempt + 1,
        maxRetries,
        delay,
        error: error.message
      });

      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

## 7. Dead Letter Queue

```javascript
/**
 * Scheduled function: Retry failed items from dead letter queue
 * Runs daily at 2 AM UTC
 */
exports.retryFailedItems = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    const firestore = admin.firestore();

    try {
      // Get failed items from last 7 days
      const cutoffDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const failedItems = await firestore
        .collection('failedItems')
        .where('failedAt', '>', cutoffDate)
        .limit(50) // Process 50 per run
        .get();

      console.log({
        severity: 'INFO',
        message: 'Retrying failed items',
        count: failedItems.size
      });

      const retryPromises = failedItems.docs.map(async (doc) => {
        const failedData = doc.data();

        try {
          // Retry AI pipeline
          await orchestrateAIPipeline(failedData.itemId, failedData.originalData);

          // Remove from dead letter queue
          await doc.ref.delete();

          console.log({
            severity: 'INFO',
            message: 'Failed item retry succeeded',
            itemId: failedData.itemId
          });
        } catch (error) {
          console.error({
            severity: 'ERROR',
            message: 'Failed item retry failed',
            itemId: failedData.itemId,
            error: error.message
          });

          // Increment retry count
          await doc.ref.update({
            retryCount: admin.firestore.FieldValue.increment(1),
            lastRetryAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      });

      await Promise.all(retryPromises);

      console.log({
        severity: 'INFO',
        message: 'Failed items retry completed',
        processed: failedItems.size
      });
    } catch (error) {
      console.error({
        severity: 'ERROR',
        message: 'retryFailedItems job failed',
        error: error.message
      });
    }
  });
```

## 8. Cost Monitoring

```javascript
/**
 * Track AI API costs per pipeline execution
 * Write to separate collection for analytics
 */
async function logAICosts(itemId, usage) {
  const firestore = admin.firestore();

  // Pricing from RESEARCH-VALIDATION-stage-3.2.md
  const geminiCost = 0.001; // ~$0.001/image (Gemini 2.0 Flash)
  const serpapiCost = usage.serpapi ? 0.02 : 0; // $0.02/search (100 free/month)
  const claudeInputCost = (usage.claudeInputTokens / 1_000_000) * 3.0; // $3/MTok
  const claudeOutputCost = (usage.claudeOutputTokens / 1_000_000) * 15.0; // $15/MTok

  const totalCost = geminiCost + serpapiCost + claudeInputCost + claudeOutputCost;

  await firestore.collection('aiCosts').add({
    itemId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    breakdown: {
      gemini: geminiCost,
      serpapi: serpapiCost,
      claudeInput: claudeInputCost,
      claudeOutput: claudeOutputCost
    },
    total: totalCost,
    usage
  });

  console.log({
    severity: 'INFO',
    message: 'AI costs logged',
    itemId,
    totalCost
  });
}
```

## Cross-References

- **DATA-FLOW-001**: See overall AI pipeline architecture
- **CODE-EXAMPLE-005**: See Cloud Functions deployment patterns
- **CODE-EXAMPLE-006**: See Firestore queries for item retrieval
- **CODE-EXAMPLE-008**: See Firebase Admin SDK integration
- **TEST-EXAMPLE-003**: See unit tests for pipeline orchestration
- **RESEARCH-VALIDATION-stage-3.2**: Verified pricing for all AI APIs

## Notes

- All code uses Node.js 20 async/await (NO callbacks)
- Layer 2a + 2b run in parallel for speed (~2-3s total)
- Layer 3 runs sequentially after Layer 2 completes
- Exponential backoff handles transient failures (rate limits, network)
- Dead letter queue enables manual review + automated retry
- Structured logging tracks duration, costs, confidence scores
- Gemini pricing: ~$0.001/image (verified)
- SerpAPI pricing: $0.02/search ($50/month for 5000 searches)
- Claude pricing: $3/MTok input, $15/MTok output

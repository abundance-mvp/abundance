# DESIGN-005: Layer 2b Product Search Architecture

**Status**: Accepted
**Date**: 2025-11-01
**Author**: Backend & ML Engineer
**Stakeholders**: Engineering, DevOps, ML/AI, Finance
**Related Docs**:
- ADR-015: AI Reasoning Layer Architecture
- ADR-016: Image Hosting Strategy (GCS + Cloud CDN)
- ADR-017: LLM Parsing Architecture (Claude Haiku)
- DESIGN-004: Computer Vision Pipeline Architecture
- serpapi-google-lens-verification-report.md (Stage 2.1 Research)

---

## Overview

### What is Layer 2b?

Layer 2b is the **Product Search** component of Abundance's 4-layer vision pipeline. It uses visual search to identify specific products (brand, model, pricing) from cropped object images, complementing Layer 2a's attribute extraction.

**Purpose**: Convert a cropped image of an unknown product into structured product metadata:
- Brand (e.g., "Sony", "Apple", "Samsung")
- Model (e.g., "WH-1000XM5", "AirPods Pro", "Galaxy S23")
- Variant (e.g., "Black", "256GB", "2nd Gen")
- Average price across retailers
- Product URLs for verification

### Why do we need it?

**Problem**: Layer 2a (Gemini Flash-Lite) excels at visual attributes (color, material, condition) but cannot identify specific product brands/models reliably. Users cataloging premium items need accurate product identification for:

1. **Insurance documentation**: "Sony WH-1000XM5" vs. "Generic Headphones"
2. **Resale value estimation**: $350 (authentic) vs. $50 (replica)
3. **Warranty tracking**: Need exact model number for claims
4. **Shopping recommendations**: Match user's existing products for compatibility

**Solution**: SerpAPI Google Lens provides access to Google's visual product search (same technology as the consumer Google Lens app), with 50B+ products indexed.

**Layer 2a vs. Layer 2b Comparison**:

| Capability | Layer 2a (Gemini Flash-Lite) | Layer 2b (SerpAPI + Parsing) |
|------------|------------------------------|------------------------------|
| **Visual attributes** | Excellent (color, material, condition) | N/A |
| **Brand identification** | Unreliable (generic brands only) | Excellent (from Google's catalog) |
| **Model/variant** | Not supported | Excellent (parsed from search results) |
| **Pricing** | Not supported | Yes (real-time from retailers) |
| **Product URLs** | Not supported | Yes (direct links to purchase) |
| **Cost** | $0.000249/item | $0.0109/item |
| **Latency** | 30-50ms | 5-7s |

### How does it fit in the 4-layer pipeline?

```
┌─────────────────────────────────────────────────────────────┐
│                    ABUNDANCE VISION PIPELINE                 │
│                                                              │
│  Layer 1: On-Device Detection (iOS Vision Framework)        │
│  - Crop object from photo                                   │
│  - Detect barcodes                                           │
│  ↓                                                           │
│  Layer 2a: Attribute Extraction (Gemini Flash-Lite)         │
│  - Condition, color, material, category                     │
│  - Runs in PARALLEL with Layer 2b ⟷                        │
│                                                              │
│  Layer 2b: Product Search (SerpAPI + Parsing)        [THIS] │
│  - Upload to GCS + Cloud CDN                                │
│  - Visual search via SerpAPI Google Lens                    │
│  - Parse brand/model with Claude Haiku                      │
│  - Runs in PARALLEL with Layer 2a ⟷                        │
│  ↓                                                           │
│  Layer 3: AI Synthesis (Claude Sonnet 4.5)                  │
│  - Merge Layer 2a + 2b results                              │
│  - Resolve conflicts (e.g., color mismatch)                 │
│  - Calculate final confidence                               │
│  - Determine if additional photos needed                    │
│  ↓                                                           │
│  Layer 4: Data Integration (Firestore + iOS)                │
│  - Save to catalog                                           │
│  - Display to user for confirmation                         │
└─────────────────────────────────────────────────────────────┘
```

**Key Architectural Principle**: Layer 2a and 2b run in **parallel** (Promise.all) to minimize latency. Layer 3 waits for both to complete before synthesis.

---

## Architecture Components

### 1. Image Hosting Service (GCS + Cloud CDN)

#### Why?

**Critical Requirement**: SerpAPI Google Lens API **requires publicly accessible image URLs** - it does not support direct file uploads or base64 encoding.

**Verification**: Confirmed via SerpAPI documentation and community forums (see serpapi-google-lens-verification-report.md, Section 2).

#### Technology

- **Storage**: Google Cloud Storage (GCS) bucket with public read access
- **CDN**: Cloud CDN enabled for global edge caching
- **URL Format**: `https://cdn.abundance.app/items/{userId}/{itemId}-{timestamp}.jpg`
- **GCP-Native**: Unified with Vertex AI, Cloud Functions, Firestore

#### Cost

**Per Image**:
- GCS storage: $0.000002 (100 KB × $0.020/GB/month)
- Cloud CDN egress: $0.000008 (100 KB × $0.08/GB)
- Cloud CDN cache hits: $0.00009 (cache lookup cost)
- **Total**: $0.0001 per image

**Monthly (75K items)**:
- GCS storage: $0.15
- Cloud CDN egress: $0.60
- Cloud CDN cache: $6.75
- **Total**: $7.50/month

#### Implementation

**GCS Bucket Configuration**:

```bash
# Create bucket
gcloud storage buckets create gs://abundance-cropped-images \
  --location=us-central1 \
  --uniform-bucket-level-access

# Enable public read access
gcloud storage buckets add-iam-policy-binding gs://abundance-cropped-images \
  --member=allUsers \
  --role=roles/storage.objectViewer

# Set lifecycle policy (auto-delete after 90 days)
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [{
      "action": {"type": "Delete"},
      "condition": {"age": 90}
    }]
  }
}
EOF
gcloud storage buckets update gs://abundance-cropped-images \
  --lifecycle-file=lifecycle.json
```

**Cloud CDN Configuration**:

```bash
# Create backend bucket
gcloud compute backend-buckets create abundance-image-backend \
  --gcs-bucket-name=abundance-cropped-images \
  --enable-cdn

# Create URL map
gcloud compute url-maps create abundance-cdn \
  --default-backend-bucket=abundance-image-backend

# Create SSL certificate
gcloud compute ssl-certificates create abundance-cdn-cert \
  --domains=cdn.abundance.app

# Create HTTPS proxy
gcloud compute target-https-proxies create abundance-cdn-proxy \
  --url-map=abundance-cdn \
  --ssl-certificates=abundance-cdn-cert

# Create forwarding rule
gcloud compute forwarding-rules create abundance-cdn-rule \
  --global \
  --target-https-proxy=abundance-cdn-proxy \
  --ports=443
```

#### Security & Privacy

**Public URLs**:
- Obfuscated filenames: `{userId}/{itemId}-{timestamp}.jpg`
- No user-identifiable information in URL
- Images auto-deleted after 90 days (lifecycle policy)

**Why 90 days?**:
- SerpAPI processing takes <10 seconds (only needs temporary access)
- 90-day buffer allows retry attempts if SerpAPI fails
- Balances privacy (shorter retention) vs. reliability (retry window)

**Alternative (Post-MVP)**: Signed URLs with 1-hour expiration for enhanced privacy.

#### Reference

See ADR-016: Image Hosting Strategy for decision rationale and alternatives considered.

---

### 2. SerpAPI Integration

#### API Overview

**Service**: SerpAPI Google Lens visual search
**Endpoint**: `https://serpapi.com/search`
**Engine**: `google_lens`
**Method**: GET with query parameters
**Authentication**: API key via `api_key` parameter

#### Pricing

**Production Plan** (Recommended):
- Monthly cost: $150
- Included searches: 15,000
- Cost per search: $0.010
- Overage handling: Automatic renewal (full $150 charge)
- Hourly quota: 3,000 searches/hour (20% of monthly)

**Alternative Plans**:
- Free: 250 searches/month ($0.00)
- Developer: $75/month (5K searches, $0.015/search)
- Big Data: $275/month (30K searches, $0.0092/search) - for Month 12+ scale

**Recommendation**: Start with Production plan ($150/month), upgrade to Big Data at 300K+ items/month for lower per-search cost.

#### Rate Limits

**Hourly Quota**: 3,000 searches/hour (20% of monthly allocation)
- **Practical limit**: 50 searches/minute (safety buffer)
- **Implementation**: Redis-backed queue with rate limiting (see Section 3)

**Cache Behavior**:
- Repeat searches within 1 hour: FREE (cached results)
- Only successful searches count toward quota
- Errors/timeouts: Not charged

#### Latency

**Verified Performance** (from Stage 2.1 research):
- Average: 5.29 seconds
- p50: ~2.75 seconds
- p95: ~7 seconds (higher than original 2-5s estimate)

**Implication**: Layer 2b dominates total pipeline latency (Layer 2a is 30-50ms).

#### Response Format

**Request Example**:

```bash
curl -X GET "https://serpapi.com/search" \
  -G \
  --data-urlencode "engine=google_lens" \
  --data-urlencode "url=https://cdn.abundance.app/items/user123/item456-1698765432.jpg" \
  --data-urlencode "api_key=YOUR_API_KEY" \
  --data-urlencode "type=visual_matches" \
  --data-urlencode "hl=en" \
  --data-urlencode "country=us"
```

**Response Structure**:

```json
{
  "search_metadata": {
    "id": "search_xyz123",
    "status": "Success",
    "total_time_taken": 5.29
  },
  "visual_matches": [
    {
      "position": 1,
      "title": "Sony WH-1000XM5 Wireless Noise Cancelling Headphones - Black",
      "link": "https://www.amazon.com/...",
      "source": "Amazon",
      "source_icon": "https://...",
      "price": {
        "value": "$399.99",
        "extracted_value": 399.99,
        "currency": "$"
      },
      "rating": 4.8,
      "reviews": 12543,
      "in_stock": true,
      "condition": "New",
      "thumbnail": "https://...",
      "image": "https://..."
    },
    {
      "position": 2,
      "title": "WH-1000XM5 | Sony Headphones (Black)",
      "link": "https://www.bestbuy.com/...",
      "source": "Best Buy",
      "price": {
        "value": "$379.99",
        "extracted_value": 379.99,
        "currency": "$"
      }
    }
  ]
}
```

**Key Fields**:
- `title`: Combined product title (brand + model + variant mixed)
- `source`: Retailer name (Amazon, Best Buy, etc.)
- `price`: Structured price object (value string + extracted float)
- `rating`, `reviews`, `in_stock`: Optional fields (not always present)
- `position`: Result ranking (lower = higher confidence proxy)

**Critical Gaps** (see serpapi-google-lens-verification-report.md):
1. **No confidence scores**: Must use `position` + `price` + `reviews` as proxy
2. **No separate brand/model fields**: Must parse from combined `title` string
3. **Variable number of results**: Typically 10-25 matches per search

#### Error Handling

**Empty Results**:

```json
{
  "search_metadata": {"status": "Success"},
  "search_information": {"organic_results_state": "Fully empty"},
  "error": "Google hasn't returned any results for this query."
}
```

**Action**: Return empty results to Layer 3, which will fall back to Layer 2a (vision-only metadata).

**API Errors**:
- 503 Service Unavailable: Schedule silent retry in 6 hours
- 429 Rate Limit: Queue request for next hourly window
- Timeout: Retry once with 2x timeout

#### Reference

See serpapi-google-lens-verification-report.md for comprehensive API verification (availability, pricing, response format, limitations).

---

### 3. Request Queue (Redis)

#### Why?

**Rate Limit Constraint**: SerpAPI Production plan allows 3,000 searches/hour (50/minute practical limit).

**Problem**: During peak usage (e.g., user uploads 20 photos), direct API calls would exceed rate limit and fail.

**Solution**: Redis-backed request queue with rate-limited worker processing.

#### Technology

**Service**: Google Cloud Memorystore (Redis)
**Instance**: Standard tier, 1 GB (sufficient for 100K+ queue entries)
**Cost**: ~$30/month (flat cost, independent of volume)

#### Queue Strategy

**Priority Queue**:
1. Premium users: Higher priority (faster processing)
2. Free users: Lower priority
3. Retries: Lowest priority

**Rate Limiting**:
- Max 45 requests/minute (10% safety buffer under 50/min limit)
- Worker dequeues 1 request every 1.33 seconds
- Batch processing disabled (SerpAPI doesn't support batch requests)

**Retry Logic**:
- On failure: Exponential backoff (2min, 10min, 1hr, 6hr)
- Max retries: 3 attempts
- After 3 failures: Flag for manual review

#### Implementation

**Enqueue Function** (Cloud Function):

```javascript
const Redis = require('ioredis');
const redis = new Redis(process.env.REDIS_URL);

async function enqueueSerpAPIRequest(publicUrl, userId, itemId, priority = 'normal') {
  const job = {
    jobId: uuidv4(),
    publicUrl,
    userId,
    itemId,
    priority,
    timestamp: Date.now(),
    retryCount: 0
  };

  // Add to priority queue (ZADD with score = timestamp + priority offset)
  const score = Date.now() + (priority === 'premium' ? -1000000 : 0);
  await redis.zadd('serpapi-queue', score, JSON.stringify(job));

  console.log(`Enqueued SerpAPI request for item ${itemId} (priority: ${priority})`);
  return job.jobId;
}
```

**Worker Function** (Cloud Scheduler, runs every 1 minute):

```javascript
async function processSerpAPIQueue() {
  const startTime = Date.now();
  const targetRequests = 45; // 45 requests per minute
  const intervalMs = 60000 / targetRequests; // 1333ms between requests

  for (let i = 0; i < targetRequests; i++) {
    // Dequeue next job (ZPOPMIN for lowest score = highest priority)
    const result = await redis.zpopmin('serpapi-queue', 1);

    if (!result || result.length === 0) {
      console.log('Queue empty, stopping worker');
      break;
    }

    const job = JSON.parse(result[0]);

    try {
      // Call SerpAPI
      const serpResults = await callSerpAPI(job.publicUrl);

      // Parse with Claude Haiku
      const parsedProduct = await parseSerpResults(serpResults);

      // Save to Firestore (Layer 2b results)
      await saveLayer2bResults(job.itemId, {
        raw_results: serpResults,
        parsed: parsedProduct,
        timestamp: Date.now()
      });

      console.log(`Processed item ${job.itemId} successfully`);

    } catch (error) {
      console.error(`Failed to process item ${job.itemId}:`, error);

      // Retry logic
      if (job.retryCount < 3) {
        const retryDelay = Math.pow(2, job.retryCount) * 60000; // 2min, 4min, 8min
        const retryTime = Date.now() + retryDelay;

        job.retryCount += 1;
        await redis.zadd('serpapi-queue', retryTime, JSON.stringify(job));

        console.log(`Scheduled retry for item ${job.itemId} in ${retryDelay}ms`);
      } else {
        // Max retries exceeded, flag for manual review
        await flagForManualReview(job.itemId, error);
      }
    }

    // Rate limiting: Wait before next request
    if (i < targetRequests - 1) {
      await sleep(intervalMs);
    }
  }

  console.log(`Processed ${targetRequests} requests in ${Date.now() - startTime}ms`);
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

#### Monitoring

**Key Metrics**:
- Queue depth (current number of pending jobs)
- Processing rate (jobs/minute)
- Success rate (% of jobs processed without error)
- Retry rate (% of jobs requiring retries)

**Alerts**:
- Queue depth > 100: Peak load, consider upgrading to Big Data plan
- Processing rate < 40/min: Worker performance degradation
- Success rate < 95%: SerpAPI reliability issues

---

### 4. LLM Parsing Service (Claude Haiku)

#### Why?

**Problem**: SerpAPI returns unstructured product titles without separate brand/model fields.

**Example**:
- SerpAPI title: "Sony WH-1000XM5 Wireless Noise Cancelling Headphones - Black"
- Needed fields: `brand: "Sony"`, `model: "WH-1000XM5"`, `variant: "Black"`

**Solution**: Use Claude Haiku 4.5 with JSON schema mode to extract structured product metadata from search results.

#### Technology

**Model**: Claude Haiku 4.5 (`claude-haiku-4-5-20250429`)
**API**: Anthropic Messages API
**Mode**: JSON schema validation (structured output)
**Cost**: $0.0008 per inference (200 input + 100 output tokens)
**Latency**: 200-300ms p95

#### Why Claude Haiku?

**Alternatives Considered** (see ADR-017):
1. Regex parsing: $0.00 but fragile (breaks on unusual formats)
2. GPT-4o Mini: $0.0015 (87% more expensive)
3. Gemini Flash-Lite: $0.0002 but lower accuracy on text-only tasks

**Decision**: Claude Haiku 4.5 offers best accuracy/cost/latency trade-off for text parsing.

#### Output Schema

```json
{
  "type": "object",
  "properties": {
    "brand": {
      "type": "string",
      "description": "Product brand (e.g., 'Sony', 'Apple', 'Samsung')"
    },
    "model": {
      "type": "string",
      "description": "Product model number or name (e.g., 'WH-1000XM5', 'AirPods Pro')"
    },
    "variant": {
      "type": "string",
      "description": "Product variant (color, storage, generation, etc.)"
    },
    "avg_price": {
      "type": "number",
      "description": "Average price across all sources (USD)"
    },
    "price_range": {
      "type": "object",
      "properties": {
        "min": {"type": "number"},
        "max": {"type": "number"}
      }
    },
    "confidence": {
      "type": "number",
      "minimum": 0,
      "maximum": 1,
      "description": "Parsing confidence (0.0 to 1.0)"
    },
    "sources": {
      "type": "array",
      "items": {"type": "string"},
      "description": "Retailers where product was found"
    }
  },
  "required": ["brand", "model", "confidence"]
}
```

#### Implementation

**Parsing Function**:

```javascript
const Anthropic = require('@anthropic-ai/sdk');
const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY
});

const PARSING_PROMPT = `You are an expert at parsing product search results. Extract brand, model, variant, and pricing information from the provided search results.

Guidelines:
- brand: Manufacturer name (Sony, Apple, Samsung, etc.)
- model: Model number or name (WH-1000XM5, AirPods Pro, Galaxy S23)
- variant: Color, storage, generation, or edition (Black, 256GB, 2nd Gen, Limited Edition)
- avg_price: Average of all listed prices (USD)
- confidence: Your confidence in the parsing (0.0 to 1.0)

If brand/model are ambiguous, use the most common interpretation across sources.
If prices vary widely (>30% difference), set confidence lower.`;

async function parseSerpResults(serpResults) {
  // Extract visual matches
  const visualMatches = serpResults.visual_matches || [];

  if (visualMatches.length === 0) {
    return {
      brand: null,
      model: null,
      variant: null,
      confidence: 0.0,
      sources: []
    };
  }

  // Format results for LLM
  const formattedResults = visualMatches.slice(0, 10).map(match => ({
    title: match.title,
    source: match.source,
    price: match.price?.value,
    position: match.position
  }));

  // Call Claude Haiku with JSON schema
  const message = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20250429',
    max_tokens: 500,
    temperature: 0,
    messages: [{
      role: 'user',
      content: `${PARSING_PROMPT}\n\nSearch Results:\n${JSON.stringify(formattedResults, null, 2)}`
    }],
    response_format: {
      type: 'json_schema',
      json_schema: {
        name: 'product_parsing',
        schema: PARSING_SCHEMA
      }
    }
  });

  // Parse JSON response
  const parsedData = JSON.parse(message.content[0].text);

  // Calculate average price
  const prices = visualMatches
    .map(m => m.price?.extracted_value)
    .filter(p => p !== null && p !== undefined);

  if (prices.length > 0) {
    parsedData.avg_price = prices.reduce((a, b) => a + b, 0) / prices.length;
    parsedData.price_range = {
      min: Math.min(...prices),
      max: Math.max(...prices)
    };
  }

  // Extract sources
  parsedData.sources = visualMatches.map(m => m.source);

  return parsedData;
}
```

#### Example Parsing

**Input (SerpAPI results)**:

```json
{
  "visual_matches": [
    {
      "position": 1,
      "title": "Sony WH-1000XM5 Wireless Noise Cancelling Headphones - Black",
      "source": "Amazon",
      "price": {"value": "$399.99", "extracted_value": 399.99}
    },
    {
      "position": 2,
      "title": "WH-1000XM5 | Sony Headphones (Black)",
      "source": "Best Buy",
      "price": {"value": "$379.99", "extracted_value": 379.99}
    },
    {
      "position": 3,
      "title": "Sony WH1000XM5/B Noise Canceling Headphones",
      "source": "B&H Photo",
      "price": {"value": "$398.00", "extracted_value": 398.00}
    }
  ]
}
```

**Output (Claude Haiku)**:

```json
{
  "brand": "Sony",
  "model": "WH-1000XM5",
  "variant": "Black",
  "avg_price": 392.33,
  "price_range": {
    "min": 379.99,
    "max": 399.99
  },
  "confidence": 0.95,
  "sources": ["Amazon", "Best Buy", "B&H Photo"]
}
```

#### Edge Case Handling

**Multiple Brands**:

```json
{
  "visual_matches": [
    {"title": "Sony WH-1000XM5", "source": "Amazon"},
    {"title": "Bose QuietComfort 45", "source": "Best Buy"}
  ]
}
```

**Claude Response**:

```json
{
  "brand": "Sony",
  "model": "WH-1000XM5",
  "confidence": 0.6,
  "note": "Multiple brands detected (Sony, Bose). Selected most common."
}
```

**Action**: Layer 3 (Claude Sonnet) reviews low confidence and may request additional photo.

**Generic Titles**:

```json
{
  "visual_matches": [
    {"title": "Wireless Headphones - Black", "source": "AliExpress"}
  ]
}
```

**Claude Response**:

```json
{
  "brand": "Unknown",
  "model": "Generic Wireless Headphones",
  "variant": "Black",
  "confidence": 0.3,
  "note": "Generic title with no brand/model information."
}
```

**Action**: Layer 3 falls back to Layer 2a (vision-only) metadata.

#### Reference

See ADR-017: LLM Parsing Architecture for decision rationale and alternatives.

---

## Data Flow

### End-to-End Workflow

```
1. iOS: User captures photo
   ↓
2. Layer 1 (Vision Framework): Crop object
   ↓
3. Cloud Function: Upload cropped image to GCS bucket
   ↓
4. Cloud Function: Generate public CDN URL
   ↓
5. Cloud Function: Enqueue SerpAPI request to Redis
   ↓
6. Worker (Cloud Scheduler): Dequeue request (rate-limited 45/min)
   ↓
7. Worker: Call SerpAPI with public CDN URL
   ↓
8. SerpAPI: Fetch image from CDN (< 50ms cache hit)
   ↓
9. SerpAPI: Run Google Lens visual search (5.29s average)
   ↓
10. SerpAPI: Return visual matches (10-25 results)
    ↓
11. Worker: Parse results with Claude Haiku (200-300ms)
    ↓
12. Worker: Save Layer 2b results to Firestore
    ↓
13. Layer 3 (Claude Sonnet): Merge Layer 2a + 2b results
    ↓
14. iOS: Display final metadata to user
```

### Parallel Processing

**Layer 2a and 2b run in parallel**:

```javascript
async function processItem(croppedImageBuffer, userId, itemId) {
  // STEP 1: Upload to GCS + CDN
  const publicUrl = await uploadToCDN(croppedImageBuffer, userId, itemId);

  // STEP 2: Launch parallel processing
  const [layer2aResults, layer2bJobId] = await Promise.all([
    // Layer 2a: Gemini Flash-Lite (30-50ms)
    analyzeWithGeminiFlashLite(croppedImageBuffer),

    // Layer 2b: Enqueue SerpAPI request (50ms)
    enqueueSerpAPIRequest(publicUrl, userId, itemId)
  ]);

  // STEP 3: Wait for Layer 2b to complete (async via Firestore listener)
  // Worker processes queue independently, saves results to Firestore
  // Layer 3 waits for both Layer 2a + 2b results via Firestore triggers

  return {
    layer2a: layer2aResults,
    layer2b_job_id: layer2bJobId
  };
}
```

### Firestore Integration

**Layer 2b Results Document**:

```javascript
// Firestore path: /items/{itemId}/layer2b_results/{timestamp}
{
  "item_id": "item123",
  "user_id": "user456",
  "serpapi_response": {
    "search_metadata": { /* ... */ },
    "visual_matches": [ /* ... */ ]
  },
  "parsed_product": {
    "brand": "Sony",
    "model": "WH-1000XM5",
    "variant": "Black",
    "avg_price": 392.33,
    "confidence": 0.95
  },
  "status": "completed",
  "created_at": 1698765432000,
  "processing_time_ms": 5500
}
```

**Firestore Trigger** (Layer 3 synthesis):

```javascript
exports.synthesizeResults = functions.firestore
  .document('/items/{itemId}/layer2b_results/{timestamp}')
  .onCreate(async (snapshot, context) => {
    const itemId = context.params.itemId;

    // Wait for Layer 2a results (should already be available)
    const layer2aDoc = await firestore
      .collection('items')
      .doc(itemId)
      .collection('layer2a_results')
      .orderBy('created_at', 'desc')
      .limit(1)
      .get();

    if (layer2aDoc.empty) {
      console.error('Layer 2a results not available yet');
      return;
    }

    const layer2aResults = layer2aDoc.docs[0].data();
    const layer2bResults = snapshot.data();

    // Call Layer 3 (Claude Sonnet) synthesis
    const finalMetadata = await synthesizeWithClaude({
      layer2a: layer2aResults,
      layer2b: layer2bResults
    });

    // Save final catalog entry
    await saveToInventory(itemId, finalMetadata);
  });
```

---

## Cloud Function Implementation

### 1. Upload to CDN

```javascript
const {Storage} = require('@google-cloud/storage');
const storage = new Storage();
const bucketName = 'abundance-cropped-images';

async function uploadToCDN(imageBuffer, userId, itemId) {
  const timestamp = Date.now();
  const filename = `items/${userId}/${itemId}-${timestamp}.jpg`;
  const bucket = storage.bucket(bucketName);
  const file = bucket.file(filename);

  // Compress JPEG to 85% quality (reduce file size below 4.5 MB limit)
  const compressedBuffer = await compressJPEG(imageBuffer, 85);

  // Upload with public read access
  await file.save(compressedBuffer, {
    metadata: {
      contentType: 'image/jpeg',
      cacheControl: 'public, max-age=86400' // 24 hour cache
    },
    public: true
  });

  // Generate public CDN URL
  const publicUrl = `https://cdn.abundance.app/${filename}`;

  console.log(`Uploaded image to CDN: ${publicUrl}`);
  return publicUrl;
}

async function compressJPEG(buffer, quality) {
  const sharp = require('sharp');

  return sharp(buffer)
    .jpeg({ quality })
    .resize(2048, 2048, { fit: 'inside' }) // Max 2048px on longest side
    .toBuffer();
}
```

**Performance**:
- GCS upload: < 100ms p95 (GCP internal network)
- JPEG compression: < 50ms
- Total: < 150ms

### 2. Enqueue SerpAPI Request

```javascript
const Redis = require('ioredis');
const redis = new Redis(process.env.REDIS_URL);
const { v4: uuidv4 } = require('uuid');

async function enqueueSerpAPIRequest(publicUrl, userId, itemId) {
  const job = {
    jobId: uuidv4(),
    publicUrl,
    userId,
    itemId,
    priority: isPremiumUser(userId) ? 'premium' : 'normal',
    timestamp: Date.now(),
    retryCount: 0
  };

  // Priority score: timestamp + priority offset
  const priorityOffset = job.priority === 'premium' ? -1000000 : 0;
  const score = job.timestamp + priorityOffset;

  // Add to sorted set (ZADD)
  await redis.zadd('serpapi-queue', score, JSON.stringify(job));

  console.log(`Enqueued SerpAPI request: ${job.jobId}`);
  return job.jobId;
}

function isPremiumUser(userId) {
  // Check Firestore user subscription status
  // Placeholder implementation
  return true;
}
```

**Performance**: < 50ms (Redis write)

### 3. Process SerpAPI Queue

```javascript
const fetch = require('node-fetch');

async function processSerpAPIQueue() {
  const RATE_LIMIT = 45; // Requests per minute
  const INTERVAL_MS = 60000 / RATE_LIMIT; // 1333ms

  for (let i = 0; i < RATE_LIMIT; i++) {
    const job = await dequeueNextJob();

    if (!job) {
      console.log('Queue empty');
      break;
    }

    try {
      // Call SerpAPI
      const serpResults = await callSerpAPI(job.publicUrl);

      // Parse with Claude Haiku
      const parsedProduct = await parseSerpResults(serpResults);

      // Save to Firestore
      await saveLayer2bResults(job.itemId, {
        serpapi_response: serpResults,
        parsed_product: parsedProduct,
        status: 'completed',
        created_at: Date.now()
      });

    } catch (error) {
      await handleSerpAPIFailure(job, error);
    }

    // Rate limiting
    if (i < RATE_LIMIT - 1) {
      await sleep(INTERVAL_MS);
    }
  }
}

async function dequeueNextJob() {
  // Pop job with lowest score (ZPOPMIN)
  const result = await redis.zpopmin('serpapi-queue', 1);

  if (!result || result.length === 0) {
    return null;
  }

  return JSON.parse(result[0]);
}

async function callSerpAPI(imageUrl) {
  const params = new URLSearchParams({
    api_key: process.env.SERPAPI_API_KEY,
    engine: 'google_lens',
    url: imageUrl,
    type: 'visual_matches',
    hl: 'en',
    country: 'us'
  });

  const response = await fetch(`https://serpapi.com/search?${params}`);

  if (!response.ok) {
    throw new Error(`SerpAPI error: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();

  // Check for errors
  if (data.error) {
    throw new Error(`SerpAPI error: ${data.error}`);
  }

  return data;
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

**Performance**:
- SerpAPI call: 5.29s average
- Claude Haiku parsing: 200-300ms
- Firestore write: < 100ms
- **Total**: ~5.7s per item

### 4. Parse SerpAPI Results

See Section 4 (LLM Parsing Service) for implementation details.

### 5. Handle SerpAPI Failure

```javascript
async function handleSerpAPIFailure(job, error) {
  console.error(`SerpAPI failed for item ${job.itemId}:`, error.message);

  // Retry logic
  if (job.retryCount < 3) {
    const retryDelay = Math.pow(2, job.retryCount) * 60000; // 2min, 4min, 8min
    const retryTime = Date.now() + retryDelay;

    job.retryCount += 1;
    await redis.zadd('serpapi-queue', retryTime, JSON.stringify(job));

    console.log(`Scheduled retry ${job.retryCount}/3 in ${retryDelay}ms`);

  } else if (job.retryCount < 6) {
    // Extended retry: 6 hours
    const retryTime = Date.now() + 6 * 3600 * 1000;

    job.retryCount += 1;
    await redis.zadd('serpapi-queue', retryTime, JSON.stringify(job));

    console.log(`Scheduled extended retry (6 hours)`);

  } else {
    // Max retries exceeded, return empty results
    await saveLayer2bResults(job.itemId, {
      serpapi_response: null,
      parsed_product: null,
      status: 'failed',
      error: error.message,
      created_at: Date.now()
    });

    console.error(`Max retries exceeded for item ${job.itemId}`);
  }
}
```

**Fallback Strategy**:
1. Retry 1-3: Exponential backoff (2min, 4min, 8min)
2. Retry 4-6: Extended retry (6 hours) - for service outages
3. After 6 retries: Return empty results, Layer 3 proceeds with Layer 2a only

---

## Performance Targets

### Component Latencies

| Component | Target p95 | Verified | Impact |
|-----------|-----------|----------|--------|
| GCS upload | < 100ms | Yes | Minimal |
| CDN URL generation | < 10ms | Yes | Negligible |
| Queue enqueue | < 50ms | Yes | Minimal |
| SerpAPI call | < 7s | Yes (5.29s avg) | Dominates latency |
| Claude Haiku parsing | < 300ms | Yes | Minimal |
| **Total Layer 2b** | **< 7s** | **Yes** | **Primary bottleneck** |

### End-to-End Latency

**Full Pipeline** (Layer 1 → Layer 4):
- Layer 1 (iOS Vision): 50-150ms
- **Layer 2a (Gemini)**: 30-50ms (parallel with Layer 2b)
- **Layer 2b (SerpAPI + Parsing)**: 5-7s (parallel with Layer 2a)
- Layer 3 (Claude Sonnet): 1-2s
- Layer 4 (Firestore write): < 100ms
- **Total**: 7-10s p95

**User Experience**:
- iOS displays Layer 1 results instantly ("Gaming Controller")
- Loading indicator shows "Analyzing details..."
- After 7-10s, full metadata appears ("Sony DualSense Wireless Controller - Black - $69.99")

### Optimization Opportunities

**Cache Common Products**:
- SerpAPI caches repeat searches for 1 hour (free)
- Implement application-level cache for frequent items (e.g., "AirPods", "iPhone charger")
- Expected savings: ~5% reduction in SerpAPI calls

**Batch Processing** (Post-MVP):
- If SerpAPI adds batch API support, process multiple items in single request
- Expected savings: ~20% reduction in latency overhead

---

## Cost Breakdown

### Per-Item Cost

| Component | Cost | Calculation |
|-----------|------|-------------|
| GCS storage | $0.000002 | 100 KB × $0.020/GB/month |
| Cloud CDN egress | $0.000008 | 100 KB × $0.08/GB |
| Cloud CDN cache | $0.00009 | Cache lookup cost |
| SerpAPI search | $0.010000 | Production plan pricing |
| Claude Haiku parsing | $0.000800 | (200 in + 100 out) × pricing |
| **Total Layer 2b** | **$0.010900** | **Per item cataloged** |

### Monthly Cost (75K Items)

| Component | Cost | Notes |
|-----------|------|-------|
| GCS storage | $0.15 | 7.5 GB × $0.020/GB |
| Cloud CDN | $7.35 | $0.60 egress + $6.75 cache |
| SerpAPI | $750.00 | 75K searches × $0.010 |
| Claude Haiku | $60.00 | 75K inferences × $0.0008 |
| Redis queue | $30.00 | Flat monthly cost (1 GB instance) |
| **Total** | **$817.50** | **75K items/month** |

**SerpAPI Breakdown**:
- Production plan: $150/month (15K searches)
- Actual usage: 75K searches/month
- Auto-renewals: 75K / 15K = 5 renewals
- Total cost: $150 × 5 = $750/month

**Optimization Path** (Month 12+):
- Upgrade to Big Data plan: $275/month (30K searches)
- Cost for 75K searches: $275 × 2.5 = $687.50
- Savings: $750 - $687.50 = $62.50/month

### Cost Per User (Month 6: 1,500 Premium Users)

**Assumptions**:
- 75K items cataloged/month
- 50 items/user on average
- $6/month subscription

**Economics**:
- Revenue: 1,500 users × $6 = $9,000/month
- Layer 2b cost: $817.50/month
- Other costs (Layer 2a + 3 + infrastructure): $641.50/month
- **Total compute cost**: $1,459/month
- **Gross margin**: ($9,000 - $1,459) / $9,000 = **83.8%**

**Per User**:
- Revenue: $6.00
- Layer 2b cost: $0.545
- Total compute cost: $0.973
- Net contribution: $5.027

---

## Error Handling & Fallbacks

### SerpAPI Failures

#### 1. Rate Limit Exceeded (429)

**Error**: `{"error": "You have exceeded your rate limit"}`

**Action**:
1. Do not retry immediately
2. Re-enqueue job with delay = time to next hourly window
3. Example: If limit hit at 10:45am, re-enqueue for 11:00am

**Implementation**:

```javascript
if (error.message.includes('rate limit')) {
  const now = new Date();
  const nextHour = new Date(now);
  nextHour.setHours(now.getHours() + 1, 0, 0, 0);

  const delayMs = nextHour - now;
  const retryTime = Date.now() + delayMs;

  job.retryCount += 1;
  await redis.zadd('serpapi-queue', retryTime, JSON.stringify(job));

  console.log(`Rate limit hit, retrying in ${delayMs}ms`);
}
```

#### 2. API Timeout

**Error**: Request exceeds 30s timeout

**Action**:
1. Retry once with 2x timeout (60s)
2. If still fails, return empty results

**Implementation**:

```javascript
async function callSerpAPI(imageUrl, timeoutMs = 30000) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, { signal: controller.signal });
    clearTimeout(timeoutId);
    return await response.json();

  } catch (error) {
    if (error.name === 'AbortError') {
      throw new Error('SerpAPI timeout');
    }
    throw error;
  }
}

// In worker
try {
  serpResults = await callSerpAPI(job.publicUrl, 30000);
} catch (error) {
  if (error.message === 'SerpAPI timeout' && job.retryCount === 0) {
    // Retry with 2x timeout
    serpResults = await callSerpAPI(job.publicUrl, 60000);
  } else {
    throw error;
  }
}
```

#### 3. No Results Found

**Response**:

```json
{
  "search_metadata": {"status": "Success"},
  "error": "Google hasn't returned any results for this query."
}
```

**Action**:
1. Return empty results to Layer 3
2. Layer 3 proceeds with Layer 2a (vision-only) metadata
3. User sees: "Gaming Controller - Used - Red/Black" (no specific product ID)

**Implementation**:

```javascript
if (serpResults.error || !serpResults.visual_matches || serpResults.visual_matches.length === 0) {
  await saveLayer2bResults(job.itemId, {
    serpapi_response: serpResults,
    parsed_product: null,
    status: 'no_results',
    created_at: Date.now()
  });

  console.log(`No results found for item ${job.itemId}`);
  return;
}
```

#### 4. Service Unavailable (503)

**Error**: `{"error": "Service temporarily unavailable"}`

**Action**:
1. Schedule silent retry in 6 hours
2. Return empty results immediately (don't block user)
3. Update metadata when retry succeeds

**Implementation**:

```javascript
if (error.message.includes('unavailable') || error.message.includes('503')) {
  const retryTime = Date.now() + 6 * 3600 * 1000; // 6 hours

  job.retryCount += 1;
  await redis.zadd('serpapi-queue', retryTime, JSON.stringify(job));

  // Save partial results
  await saveLayer2bResults(job.itemId, {
    serpapi_response: null,
    parsed_product: null,
    status: 'retry_later',
    created_at: Date.now()
  });

  console.log(`Service unavailable, retrying in 6 hours`);
}
```

### Claude Haiku Failures

#### 1. API Error

**Action**:
1. Retry once
2. If still fails, use regex fallback for basic parsing

**Implementation**:

```javascript
async function parseSerpResults(serpResults) {
  try {
    return await parseWithClaude(serpResults);

  } catch (error) {
    console.error('Claude Haiku parsing failed:', error);

    // Fallback: Regex parsing
    return parseWithRegex(serpResults);
  }
}

function parseWithRegex(serpResults) {
  const firstMatch = serpResults.visual_matches[0];

  if (!firstMatch) {
    return null;
  }

  // Basic regex patterns
  const title = firstMatch.title;
  const brandPattern = /^([A-Z][a-z]+)\s/; // "Sony WH-1000XM5" → "Sony"
  const brandMatch = title.match(brandPattern);

  return {
    brand: brandMatch ? brandMatch[1] : 'Unknown',
    model: title, // Fallback: Use full title as model
    variant: null,
    avg_price: firstMatch.price?.extracted_value,
    confidence: 0.5, // Low confidence (regex parsing)
    sources: [firstMatch.source]
  };
}
```

#### 2. Invalid JSON Response

**Action**:
1. Log error for review
2. Return empty parsing results
3. Layer 3 proceeds with unparsed SerpAPI data

**Implementation**:

```javascript
try {
  const parsedData = JSON.parse(message.content[0].text);
  return parsedData;

} catch (error) {
  console.error('Invalid JSON from Claude Haiku:', message.content[0].text);

  return {
    brand: null,
    model: null,
    confidence: 0.0,
    error: 'Invalid JSON response'
  };
}
```

---

## Security & Privacy

### Public CDN URLs

**Security Measures**:
1. **Obfuscated filenames**: `{userId}/{itemId}-{timestamp}.jpg` (no PII)
2. **Auto-deletion**: Lifecycle policy deletes images after 90 days
3. **No user data in URL**: Cannot reverse-engineer user identity from URL
4. **Rate limiting**: Cloud Functions quota prevents abuse (mass uploads)

**Privacy Considerations**:
- Cropped images contain only the object (no home layout/background)
- No location data embedded in images (EXIF stripped during upload)
- SerpAPI receives only image URL (no user identity)

### SerpAPI Data Handling

**What SerpAPI Receives**:
- Image URL (publicly accessible)
- Search parameters (language, country)

**What SerpAPI Does NOT Receive**:
- User ID
- User email
- Location data
- Full photo (only cropped object)

**Data Retention**:
- SerpAPI may cache search results for 1 hour (documented)
- No long-term storage of user images (per SerpAPI privacy policy)

### Signed URLs (Post-MVP Option)

**Alternative**: Generate signed URLs with 1-hour expiration

**Implementation**:

```javascript
const [signedUrl] = await file.getSignedUrl({
  action: 'read',
  expires: Date.now() + 3600 * 1000 // 1 hour
});
```

**Trade-offs**:
- **Pro**: Enhanced privacy (URLs expire, cannot be shared)
- **Con**: CDN caching less effective (unique URLs per request)
- **Con**: Higher Cloud Function CPU usage (signature generation)

**Recommendation**: Use public URLs for MVP, add signed URLs if abuse detected.

---

## Monitoring & Alerts

### Key Metrics

**SerpAPI Performance**:
- Success rate (% of requests returning results)
- Latency distribution (p50, p95, p99)
- Error rate by type (timeout, rate limit, no results, 503)
- Cost per request (actual vs. $0.010 estimate)

**Queue Health**:
- Queue depth (current number of pending jobs)
- Processing rate (jobs/minute)
- Average wait time (enqueue → dequeue)
- Retry rate (% of jobs requiring retries)

**Parsing Accuracy**:
- Claude Haiku success rate (% of valid JSON responses)
- Average confidence score
- Regex fallback rate (% using fallback)

**Cost Tracking**:
- SerpAPI monthly spend (track auto-renewals)
- Claude Haiku token usage
- GCS storage usage
- Cloud CDN egress

### Alerts

**Performance Alerts**:
- SerpAPI success rate < 95% → Investigate API reliability
- SerpAPI latency p95 > 10s → Performance degradation
- Queue depth > 100 requests → Upgrade to Big Data plan
- Processing rate < 40/min → Worker performance issue

**Cost Alerts**:
- SerpAPI monthly spend > $800 → Budget overrun
- Cost per request > $0.012 → Pricing change or inefficiency
- Claude Haiku cost > $70/month → Token usage spike

**Error Alerts**:
- SerpAPI error rate > 5% → API issues
- Queue retry rate > 10% → Persistent failures
- Parsing success rate < 90% → Claude Haiku issues

### Dashboards

**Cloud Monitoring Dashboard**:

```yaml
widgets:
  - title: "SerpAPI Success Rate"
    type: line_chart
    metrics:
      - serpapi_success_rate
      - serpapi_error_rate
    threshold: 95%

  - title: "Queue Depth"
    type: line_chart
    metrics:
      - redis_queue_depth
    threshold: 100

  - title: "Layer 2b Latency"
    type: line_chart
    metrics:
      - serpapi_latency_p50
      - serpapi_latency_p95
      - parsing_latency_p95

  - title: "Monthly Cost"
    type: scorecard
    metrics:
      - serpapi_monthly_cost
      - claude_haiku_monthly_cost
      - gcs_monthly_cost
```

---

## Integration with Other Layers

### Layer 1 (iOS Vision Framework)

**Input to Layer 2b**:
- Cropped image buffer (JPEG, 100-500 KB)
- User ID, Item ID (for tracking)

**What Layer 1 Provides**:
- High-quality object crop (bounding box accuracy critical)
- Basic label (e.g., "headphones", "gaming controller") - not used by Layer 2b but sent to Layer 3

**Dependency**: Layer 2b cannot run without successful Layer 1 crop.

### Layer 2a (Gemini Flash-Lite)

**Parallel Processing**:
- Layer 2a and 2b run simultaneously (Promise.all)
- No dependencies between them
- Both complete before Layer 3 synthesis

**Layer 2a Provides**:
- Visual attributes: color, material, condition, category
- Confidence scores for each attribute

**Layer 2b Provides**:
- Product identification: brand, model, variant
- Pricing data
- Retailer sources

**Complementary Data**:
- Layer 2a: "Red plastic gaming controller, good condition"
- Layer 2b: "Sony DualSense, $69.99 average"
- Layer 3 combines: "Sony DualSense Wireless Controller - Red - Good Condition - $69.99"

### Layer 3 (Claude Sonnet 4.5 Synthesis)

**Input from Layer 2b**:

```javascript
{
  "layer2b": {
    "status": "completed",
    "parsed_product": {
      "brand": "Sony",
      "model": "WH-1000XM5",
      "variant": "Black",
      "avg_price": 392.33,
      "confidence": 0.95,
      "sources": ["Amazon", "Best Buy", "B&H Photo"]
    },
    "serpapi_response": {
      "visual_matches": [ /* raw SerpAPI data */ ]
    }
  }
}
```

**Layer 3 Tasks**:
1. **Validate Layer 2b confidence**: If < 0.7, request additional photos
2. **Cross-reference with Layer 2a**: Verify color/material match
3. **Resolve conflicts**: Layer 2a says "red" but Layer 2b shows "black variant" → request clarification
4. **Calculate final confidence**: Combine Layer 2a + 2b confidence scores
5. **Select best product match**: If multiple candidates, use Layer 2a attributes to disambiguate
6. **Detect replicas**: If Layer 2a detects low quality but Layer 2b shows premium brand → flag as replica

**Output to Layer 4**:

```javascript
{
  "name": "Sony WH-1000XM5 Wireless Headphones",
  "brand": "Sony",
  "model": "WH-1000XM5",
  "variant": "Black",
  "category": "Electronics",
  "subcategory": "Headphones",
  "condition": "used",
  "color": ["black"],
  "material": "plastic",
  "estimated_value": 392.33,
  "confidence": 0.92,
  "source": "hybrid_analysis",
  "product_url": "https://www.amazon.com/...",
  "action": "save"
}
```

### Fallback Strategy

**If Layer 2b Fails**:
1. Layer 3 proceeds with Layer 2a (vision-only) metadata
2. User sees rich attributes but no specific product ID
3. Example: "Wireless Headphones - Black - Good Condition" (generic)
4. Silent retry scheduled for 6 hours
5. If retry succeeds, metadata upgraded to "Sony WH-1000XM5"

**User Experience**:
- Immediate results (Layer 1 + 2a): "Wireless Headphones - $300 (estimated)"
- After retry: "Sony WH-1000XM5 - $392 (market price)"
- User never sees "failed" state (graceful degradation)

---

## Testing Strategy

### Unit Tests

**Upload to CDN**:
- Test JPEG compression (verify quality = 85%)
- Test file size limit (reject images > 4.5 MB)
- Test public URL generation
- Test lifecycle policy (images deleted after 90 days)

**Queue Management**:
- Test enqueue/dequeue operations
- Test priority ordering (premium users first)
- Test rate limiting (max 45 requests/minute)
- Test retry logic (exponential backoff)

**Parsing Logic**:
- Test brand/model extraction from various title formats
- Test handling of multiple brands in results
- Test generic titles (no brand/model)
- Test price averaging (multiple sources)
- Test confidence calculation

### Integration Tests

**End-to-End Workflow**:
1. Upload test image to GCS
2. Enqueue SerpAPI request
3. Worker processes queue
4. Verify SerpAPI call succeeds
5. Verify parsing produces valid JSON
6. Verify results saved to Firestore
7. Verify Layer 3 synthesis completes

**Test Cases**:
- **Common product**: "Sony WH-1000XM5 headphones" → Expect high confidence, accurate brand/model
- **Generic product**: "Wireless earbuds" → Expect low confidence, may return empty results
- **Rare product**: "Vintage 1980s cassette player" → Expect no SerpAPI results, vision-only fallback
- **Replica**: "Designer handbag (low quality)" → Expect conflict detection in Layer 3

### Load Tests

**Simulate Peak Usage**:
- 1,000 concurrent users
- Each uploads 10 photos simultaneously
- Total: 10,000 items to process

**Metrics**:
- Queue depth over time (should not exceed 500)
- Processing rate (should maintain ~45/min)
- SerpAPI error rate (should be < 5%)
- End-to-end latency p95 (should be < 10s)

**Failure Modes**:
- Redis queue full (>100K entries) → Upgrade Redis instance
- SerpAPI rate limit hit → Requests queued for next hour
- Cloud Function timeout → Increase timeout limit

### Cost Validation

**Track Actual Costs**:
- Run POC with 1,000 items
- Measure actual SerpAPI cost (should be ~$10)
- Measure actual Claude Haiku cost (should be ~$0.80)
- Measure actual GCS/CDN cost (should be ~$0.10)
- **Total**: Should match $10.90 estimate

**Extrapolate to Month 6**:
- 75K items × $0.0109 = $817.50 (validate vs. actual)

---

## Future Optimizations

### 1. Cache Common Products

**Opportunity**: Many users catalog identical products (AirPods, iPhone chargers, popular books)

**Implementation**:
- Perceptual hashing (identify visually similar images)
- Cache SerpAPI results for 24 hours
- Skip SerpAPI call if hash match found

**Expected Savings**:
- ~5% reduction in SerpAPI calls
- Savings: 75K × 5% × $0.010 = $37.50/month

### 2. Batch SerpAPI Requests

**Opportunity**: If SerpAPI adds batch API support, process multiple items in single request

**Implementation**:
- Batch up to 10 images per request
- SerpAPI returns results for all images
- Amortize API call overhead

**Expected Savings**:
- ~20% reduction in latency overhead
- No cost savings (charged per image)

### 3. Upgrade to Big Data Plan

**Trigger**: Monthly usage exceeds 30K items

**Cost Comparison**:
- Production plan (15K searches): $0.010/search
- Big Data plan (30K searches): $0.0092/search

**Breakeven**: 30K items/month
- Production: 30K × $0.010 = $300 (requires 2 renewals)
- Big Data: $275 (flat monthly)
- **Savings**: $25/month

**At 75K items/month**:
- Production: 75K × $0.010 = $750
- Big Data: 75K × $0.0092 = $690 (requires 2.5 renewals)
- **Savings**: $60/month

### 4. Prompt Caching (Claude Haiku)

**Opportunity**: Cache system prompts and JSON schemas (90% cost reduction per Anthropic docs)

**Implementation**:
- Use Anthropic Prompt Caching API
- Cache parsing instructions + schema (unchanged across requests)
- Only variable content: SerpAPI results

**Expected Savings**:
- Input tokens reduced by ~90%
- New cost: $0.000800 → $0.000240 (70% savings)
- Monthly savings: 75K × $0.000560 = $42/month

### 5. Perceptual Hashing for Duplicates

**Opportunity**: Detect when user photos same item twice

**Implementation**:
- Generate perceptual hash (pHash) of cropped image
- Check Firestore for existing hash within 24 hours
- If match found, skip Layer 2b (reuse cached results)

**Expected Savings**:
- ~5% duplicate detection rate
- Savings: 75K × 5% × $0.0109 = $40.88/month

### Combined Optimization (Month 12+)

**Optimizations**:
1. Cache common products: -$37.50/month
2. Big Data plan upgrade: -$60/month
3. Prompt caching: -$42/month
4. Duplicate detection: -$40.88/month

**Total Savings**: $180.38/month (22% reduction)

**Optimized Cost**:
- Current: $817.50/month
- Optimized: $637.12/month
- Per-item: $0.0109 → $0.0085

**Updated Margin**:
- Revenue: $9,000/month
- Layer 2b cost: $637.12
- Other layers: $641.50
- **Total compute**: $1,278.62
- **Gross margin**: 85.8% (vs. 83.8% current)

---

## References

### Architecture Decision Records
- ADR-015: AI Reasoning Layer Architecture
- ADR-016: Image Hosting Strategy (GCS + Cloud CDN)
- ADR-017: LLM Parsing Architecture (Claude Haiku)

### Design Documents
- DESIGN-004: Computer Vision Pipeline Architecture

### Research Reports
- serpapi-google-lens-verification-report.md (Stage 2.1)

### External Documentation
- SerpAPI Google Lens API: https://serpapi.com/google-lens-api
- SerpAPI Visual Matches API: https://serpapi.com/google-lens-visual-matches-api
- SerpAPI Pricing: https://serpapi.com/pricing
- SerpAPI Status Page: https://serpapi.com/status/google_lens
- Google Cloud Storage Pricing: https://cloud.google.com/storage/pricing
- Cloud CDN Pricing: https://cloud.google.com/cdn/pricing
- Anthropic Claude Pricing: https://www.anthropic.com/api#pricing
- Anthropic JSON Mode: https://docs.anthropic.com/en/docs/build-with-claude/tool-use#json-mode

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-01 | 1.0 | Initial document | Backend & ML Engineer |

---

## Approval

**Status**: ✅ Accepted

**Approved by**:
- Tech Lead (2025-11-01)
- Engineering Manager (2025-11-01)
- Product Leadership (2025-11-01)

**Next Steps**:
1. Implement GCS bucket + Cloud CDN setup
2. Integrate SerpAPI with Cloud Functions
3. Deploy Claude Haiku parsing service
4. Set up Redis queue system
5. Run POC validation with 50-item test dataset

---

**End of DESIGN-005**

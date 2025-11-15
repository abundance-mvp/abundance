# SHOPPING-GRAPH-INTEGRATION-001: Google Shopping Graph API Integration Research

**Document ID:** SHOPPING-GRAPH-INTEGRATION-001
**Date:** 2025-10-24
**Status:** RESEARCH REQUIRED
**Researcher:** TBD (Backend Engineer + AI/ML Specialist)
**Related Documents:**
- ADR-012 (Google Shopping Graph as Primary AI)
- TECH-STACK-001 (Technology Stack Map)
- API-CONTRACTS-001 (Service Interface Definitions)

---

## Executive Summary

This document outlines the **research required** to integrate Google Shopping Graph API into Abundance MVP. The Shopping Graph API is hypothetical based on Google Lens architecture analysis - actual endpoint, authentication, and pricing need validation.

**Status:** This is a **research task**, not a completed integration spec. An engineer must complete this research before implementation.

---

## Research Objectives

### Primary Questions (MUST ANSWER)

1. **API Endpoint:** What is the actual Shopping Graph API endpoint?
   - Hypothesis: `https://shopping.googleapis.com/v1/search` (TBD)
   - Alternative: Vertex AI wrapper? Google Vision API product search?

2. **Authentication:** How to authenticate Shopping Graph API calls?
   - Service Account OAuth 2.0?
   - API Key?
   - Vertex AI authentication?

3. **Request/Response Schema:** What is the exact API contract?
   - Request: Image URL (gs://) or base64 encoded?
   - Response: Product metadata (name, brand, model, price, URL)

4. **Pricing:** How much does Shopping Graph cost per API call?
   - Hypothesis: $0.005-0.010 per image lookup (TBD)
   - Is there a free tier? (e.g., first 1,000 calls/month free)

5. **Rate Limits:** What are the rate limits?
   - QPS (queries per second)?
   - Daily quota?
   - Burst limits?

6. **Availability:** Is Shopping Graph API publicly available?
   - Public API (anyone can sign up)?
   - Private API (requires Google partnership)?
   - Beta/Alpha program (waitlist)?

---

## Research Plan

### Phase 1: Documentation Review (1-2 days)

**Task:** Search for official Google Shopping Graph API documentation

**Resources to Check:**
1. Google Cloud AI/ML documentation
   - https://cloud.google.com/vision/product-search/docs
   - https://cloud.google.com/vertex-ai/docs
2. Google Shopping API documentation
   - https://developers.google.com/shopping-content
3. Google Lens API (if available)
   - Search for "Google Lens API" in GCP console
4. Google AI forums / Stack Overflow
   - Search for "Google Shopping Graph API"
   - Search for "Google product identification API"

**Expected Outcome:**
- Official API documentation (ideal)
- OR: Confirmation that Shopping Graph is NOT publicly available
- OR: Alternative APIs (Google Vision API Product Search, etc.)

---

### Phase 2: GCP Console Exploration (1 day)

**Task:** Explore GCP Console for Shopping-related APIs

**Steps:**
1. Create GCP project (abundance-research)
2. Go to **APIs & Services > Library**
3. Search for:
   - "Shopping"
   - "Product"
   - "Lens"
   - "Vision"
   - "Retail"
4. Enable any relevant APIs
5. Check API documentation links

**Expected APIs to Find:**
- ✅ **Vision API Product Search** (likely candidate)
- ✅ **Retail API** (product catalog management)
- ❌ **Shopping Graph API** (may not exist as standalone API)

---

### Phase 3: Proof-of-Concept Integration (2-3 days)

**Task:** Implement minimal API integration to validate hypothesis

**Approach A: Vision API Product Search (If Shopping Graph Not Found)**

```javascript
// poc-vision-product-search.js
const vision = require('@google-cloud/vision');
const client = new vision.ProductSearchClient();

async function identifyProduct(imageUrl) {
    const request = {
        image: { source: { imageUri: imageUrl } },
        features: [{ type: 'PRODUCT_SEARCH' }],
        imageContext: {
            productSearchParams: {
                productSet: 'projects/abundance-research/locations/us-east1/productSets/all_products',
                productCategories: ['general-v1'],
            },
        },
    };

    const [response] = await client.batchAnnotateImages({ requests: [request] });
    const results = response.responses[0].productSearchResults;

    return {
        name: results.results[0].product.displayName,
        confidence: results.results[0].score,
    };
}

// Test with sample image
identifyProduct('gs://abundance-research/test/scissors.jpg')
    .then(result => console.log('Product identified:', result))
    .catch(err => console.error('Error:', err));
```

**Approach B: Vertex AI Gemini Vision (Fallback)**

```javascript
// poc-gemini-vision.js
const { VertexAI } = require('@google-cloud/vertexai');

async function identifyProductGemini(imageUrl) {
    const vertex_ai = new VertexAI({ project: 'abundance-research', location: 'us-central1' });
    const model = 'gemini-pro-vision';

    const request = {
        contents: [{
            role: 'user',
            parts: [
                { fileData: { mimeType: 'image/jpeg', fileUri: imageUrl } },
                { text: 'Identify this product. Return JSON: { "name": "...", "brand": "...", "model": "...", "estimatedPrice": ... }' }
            ]
        }]
    };

    const response = await vertex_ai.preview.generativeModel(model).generateContent(request);
    const productData = JSON.parse(response.response.text);

    return productData;
}

// Test with sample image
identifyProductGemini('gs://abundance-research/test/scissors.jpg')
    .then(result => console.log('Product identified:', result))
    .catch(err => console.error('Error:', err));
```

**Expected Outcome:**
- Working POC with **actual Google API** (not mock)
- Measured latency (p50, p95, p99)
- Measured cost ($ per API call)
- Documented API endpoint, authentication, request/response schema

---

### Phase 4: Cost & Performance Benchmarking (1 day)

**Task:** Measure cost and performance with 100 test images

**Test Dataset:**
```
test-images/
├── scissors_01.jpg (known product: Scott Fabric Scissors)
├── scissors_02.jpg (known product: Fiskars Scissors)
├── headphones_01.jpg (known product: Beats Pro 2)
├── headphones_02.jpg (known product: Sony WH-1000XM5)
├── book_01.jpg (known product: specific ISBN)
├── unknown_object.jpg (not in product database)
└── ... (100 total images)
```

**Metrics to Collect:**

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Success Rate** | >90% | % of images successfully identified |
| **Latency (p50)** | <3 sec | Median response time |
| **Latency (p95)** | <5 sec | 95th percentile |
| **Latency (p99)** | <10 sec | 99th percentile |
| **Cost per Image** | <$0.010 | Actual GCP billing |
| **Confidence Score (avg)** | >0.85 | Average confidence across all results |

**Benchmarking Script:**

```javascript
// benchmark.js
const fs = require('fs');
const { identifyProduct } = require('./poc-vision-product-search');

async function benchmark() {
    const testImages = fs.readdirSync('./test-images').map(file => `gs://test/${file}`);
    const results = [];

    for (const imageUrl of testImages) {
        const start = Date.now();
        try {
            const product = await identifyProduct(imageUrl);
            results.push({
                imageUrl,
                success: true,
                latency: Date.now() - start,
                confidence: product.confidence,
                name: product.name,
            });
        } catch (error) {
            results.push({
                imageUrl,
                success: false,
                latency: Date.now() - start,
                error: error.message,
            });
        }
    }

    // Calculate metrics
    const successRate = results.filter(r => r.success).length / results.length;
    const latencies = results.map(r => r.latency).sort((a, b) => a - b);
    const p50 = latencies[Math.floor(latencies.length * 0.5)];
    const p95 = latencies[Math.floor(latencies.length * 0.95)];
    const p99 = latencies[Math.floor(latencies.length * 0.99)];
    const avgConfidence = results.filter(r => r.success).reduce((sum, r) => sum + r.confidence, 0) / results.filter(r => r.success).length;

    console.log('Benchmark Results:');
    console.log(`  Success Rate: ${(successRate * 100).toFixed(1)}%`);
    console.log(`  Latency (p50): ${p50}ms`);
    console.log(`  Latency (p95): ${p95}ms`);
    console.log(`  Latency (p99): ${p99}ms`);
    console.log(`  Avg Confidence: ${avgConfidence.toFixed(2)}`);

    // Save results to CSV
    fs.writeFileSync('benchmark-results.csv', results.map(r => Object.values(r).join(',')).join('\n'));
}

benchmark();
```

**Expected Outcome:**
- CSV file with 100 API call results (latency, success, confidence)
- Cost analysis (GCP billing statement)
- Performance recommendation (is Shopping Graph fast enough?)

---

## Decision Tree (Based on Research Findings)

### Scenario A: Shopping Graph API Exists (Public, Affordable)

**If:**
- ✅ Public API available (no waitlist)
- ✅ Cost < $0.010 per image
- ✅ Success rate > 90%
- ✅ Latency p95 < 5 sec

**Decision:** Proceed with Shopping Graph integration (as planned in ADR-012)

**Next Steps:**
1. Update API-CONTRACTS-001 with actual endpoint
2. Implement Cloud Function integration
3. Deploy to staging, test with real users

---

### Scenario B: Shopping Graph API Requires Partnership

**If:**
- ❌ Shopping Graph is private API (requires Google partnership)
- ⏳ Waitlist or beta program (6-12 month wait)

**Decision:** Use **Vision API Product Search** as interim solution

**Revised Architecture:**
```
Phase 1 (Month 0-6): Vision API Product Search
  - Cost: $0.015/image (estimated)
  - Requires product catalog setup (manual)
  - Lower accuracy (70-80% vs. 90% Shopping Graph)

Phase 2 (Month 6+): Migrate to Shopping Graph when available
  - Apply for Google partnership (Month 0)
  - Migrate once approved (Month 6-12)
```

**Impact on ADR-012:**
- Revise cost model ($0.015 vs. $0.007 per image)
- Month 6 AI cost: 75K items × $0.015 = **$1,125/month** (vs. $525 planned)
- Still profitable (revenue $9,000 - AI cost $1,125 = $7,875 margin)

---

### Scenario C: Shopping Graph API Too Expensive

**If:**
- ✅ API exists, but cost > $0.015 per image
- OR: Rate limits too restrictive (< 10 QPS)

**Decision:** Use **Gemini Vision** as primary AI (revised ADR-012)

**Revised Architecture:**
```
Primary AI: Gemini Vision (Vertex AI)
  - Cost: $0.020/image (Gemini Pro Vision)
  - Success rate: 70-80% (vs. 90% Shopping Graph)
  - Latency: 3-5 sec (similar to Shopping Graph)
```

**Impact on ADR-012:**
- Revise cost model ($0.020 vs. $0.007 per image)
- Month 6 AI cost: 75K items × $0.020 = **$1,500/month** (vs. $525 planned)
- Still profitable (revenue $9,000 - AI cost $1,500 = $7,500 margin)

**Recommendation:** Still proceed (55% margin acceptable for MVP)

---

### Scenario D: No Viable Google API (Worst Case)

**If:**
- ❌ Shopping Graph not available
- ❌ Vision API Product Search requires manual catalog (unscalable)
- ❌ Gemini Vision accuracy < 70%

**Decision:** Pivot to **third-party product recognition API**

**Alternative APIs:**
1. **Amazon Rekognition Custom Labels** (AWS)
   - Cost: $0.005 per image (inference)
   - Requires training data (1,000+ labeled images)
2. **Clarifai Product Recognition** (Third-party)
   - Cost: $0.012 per image
   - Accuracy: 80-85% (per vendor claims)
3. **Custom ML Model** (Train YOLO + Product Database)
   - Cost: $0.002 per image (Cloud Run GPU inference)
   - Requires 3-6 months training, 10K+ labeled images

**Impact on Timeline:**
- 3-6 month delay (train model or integrate third-party API)
- Higher cost ($0.012-0.020 per image)
- Lower accuracy (75-85% vs. 90% Shopping Graph)

**Recommendation:** Only consider if Scenarios A/B/C all fail

---

## Research Deliverables

### Deliverable 1: API Discovery Report

**Template:**
```markdown
# Shopping Graph API Discovery Report

**Date:** [Date]
**Researcher:** [Name]

## Findings

### API Availability
- [ ] Public API (no waitlist)
- [ ] Private API (requires partnership)
- [ ] Beta program (waitlist)
- [ ] Does not exist (alternative: Vision API Product Search)

### API Endpoint
- **URL:** https://...
- **Authentication:** Service Account OAuth / API Key
- **Documentation:** [Link]

### Pricing
- **Cost per Image:** $X.XXX
- **Free Tier:** X calls/month (if applicable)
- **Rate Limit:** X QPS, Y calls/day

### Request/Response Schema
```json
// Example request
{
  "image": "gs://...",
  "language": "en",
  "country": "US"
}

// Example response
{
  "products": [
    {
      "name": "...",
      "brand": "...",
      "price": {...},
      "confidence": 0.92
    }
  ]
}
```

### Performance Benchmarks
- **Success Rate:** X%
- **Latency (p95):** X ms
- **Confidence (avg):** X.XX

### Recommendation
- [ ] Proceed with Shopping Graph (Scenario A)
- [ ] Use Vision API Product Search interim (Scenario B)
- [ ] Use Gemini Vision (Scenario C)
- [ ] Pivot to third-party API (Scenario D)
```

---

### Deliverable 2: POC Code (Working Integration)

**File:** `poc-shopping-graph-integration.js`

```javascript
/**
 * Proof-of-Concept: Google Shopping Graph API Integration
 *
 * This POC demonstrates:
 * 1. Authentication (Service Account OAuth 2.0)
 * 2. API request (upload image, get product metadata)
 * 3. Error handling (timeout, rate limit, no match)
 *
 * Usage:
 *   node poc-shopping-graph-integration.js gs://test/scissors.jpg
 */

const { ShoppingGraphClient } = require('@google-cloud/shopping-graph');  // Hypothetical package

async function identifyProduct(imageUrl) {
    const client = new ShoppingGraphClient({
        projectId: 'abundance-research',
        keyFilename: './service-account-key.json'
    });

    try {
        const [response] = await client.searchProducts({
            image: imageUrl,
            language: 'en',
            country: 'US',
            maxResults: 1
        });

        if (response.products.length === 0) {
            return { success: false, error: 'No product match found' };
        }

        const product = response.products[0];
        return {
            success: true,
            name: product.name,
            brand: product.brand,
            model: product.model,
            price: product.price.amount,
            currency: product.price.currency,
            productUrl: product.url,
            confidence: product.confidence
        };

    } catch (error) {
        if (error.code === 429) {
            return { success: false, error: 'RATE_LIMIT_EXCEEDED', retryAfter: error.retryAfter };
        } else if (error.code === 'DEADLINE_EXCEEDED') {
            return { success: false, error: 'TIMEOUT', message: 'API call took > 10 sec' };
        } else {
            return { success: false, error: error.message };
        }
    }
}

// Test
const imageUrl = process.argv[2] || 'gs://test/scissors.jpg';
identifyProduct(imageUrl)
    .then(result => console.log(JSON.stringify(result, null, 2)))
    .catch(err => console.error('Fatal error:', err));
```

---

### Deliverable 3: Cost Analysis Spreadsheet

**File:** `shopping-graph-cost-analysis.xlsx`

| Month | Premium Users | Items Cataloged | API Calls | Cost per Call | Total AI Cost | Revenue | Margin |
|-------|---------------|-----------------|-----------|---------------|---------------|---------|--------|
| 1 | 150 | 7,500 | 7,500 | $0.007 | $52.50 | $900 | 94% |
| 2 | 300 | 15,000 | 15,000 | $0.007 | $105.00 | $1,800 | 94% |
| 3 | 500 | 25,000 | 25,000 | $0.007 | $175.00 | $3,000 | 94% |
| 6 | 1,500 | 75,000 | 75,000 | $0.007 | $525.00 | $9,000 | 94% |
| 12 | 5,000 | 250,000 | 250,000 | $0.007 | $1,750.00 | $30,000 | 94% |

**Sensitivity Analysis (If Cost per Call Changes):**

| Cost per Call | Month 6 AI Cost | Margin | Acceptable? |
|---------------|-----------------|--------|-------------|
| $0.005 | $375 | 96% | ✅ Yes |
| $0.007 | $525 | 94% | ✅ Yes (baseline) |
| $0.010 | $750 | 92% | ✅ Yes |
| $0.015 | $1,125 | 88% | ⚠️ Marginal (consider alternatives) |
| $0.020 | $1,500 | 83% | ⚠️ Marginal (Gemini Vision fallback) |
| $0.030 | $2,250 | 75% | ❌ Too expensive (pivot required) |

---

## Open Questions (To Be Answered by Research)

1. **Shopping Graph vs. Vision API Product Search:**
   - Are they the same API?
   - Is Shopping Graph a marketing name for Vision API Product Search?

2. **Product Catalog Requirement:**
   - Does Vision API require pre-populating product catalog?
   - OR: Does Shopping Graph have built-in catalog (Google's e-commerce data)?

3. **Regional Availability:**
   - Is Shopping Graph available in US only?
   - OR: Global (supports 100+ countries)?

4. **Image Requirements:**
   - Minimum resolution (e.g., 640×480)?
   - Maximum file size (e.g., 10 MB)?
   - Supported formats (JPEG, PNG, WebP)?

5. **Confidence Score:**
   - What does confidence score mean? (0.0-1.0)
   - What threshold should we use? (0.7, 0.8, 0.9?)

---

## Timeline

**Estimated Research Duration:** 5-7 days (1 engineer full-time)

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| **Phase 1:** Documentation review | 1-2 days | API availability report |
| **Phase 2:** GCP console exploration | 1 day | List of relevant APIs |
| **Phase 3:** POC integration | 2-3 days | Working code + API contract |
| **Phase 4:** Benchmarking | 1 day | Cost & performance metrics |
| **Total** | **5-7 days** | **Full research report** |

**Deadline:** 2025-11-08 (Week of 2025-11-04, after Stage 2.1 completion)

---

## Stakeholder Sign-Off

**Required Approvals:**

- [ ] **CTO / Engineering Leadership:** Approve research plan, allocate engineer time (5-7 days)
- [ ] **Product Leadership:** Approve research timeline (may delay Stage 2.2 by 1 week)
- [ ] **Finance:** Approve GCP research project costs ($50-100 for API testing)

**Timeline:**
- Research plan approval: 2025-10-31
- Research execution: Week of 2025-11-04
- Research report delivery: 2025-11-08
- Decision on API strategy: 2025-11-11

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial research plan | Stage 2.1 Execution |

---

## Conclusion

**This document is a RESEARCH PLAN, not a completed integration.**

**Next Actions:**
1. Assign engineer to research task (Week of 2025-11-04)
2. Complete research phases 1-4 (5-7 days)
3. Update ADR-012 based on findings (if Shopping Graph unavailable)
4. Proceed with Cloud Function implementation (Stage 2.3)

**Critical Path Dependency:** Stage 2.3 (Backend Implementation) is **blocked** until Shopping Graph research is complete.

---

**Related Documents:**
- ADR-012: Google Shopping Graph as Primary AI
- TECH-STACK-001: Complete Technology Stack Map
- API-CONTRACTS-001: Service Interface Definitions
- TEST-STRATEGY-001: Test Pyramid (Shopping Graph integration tests)

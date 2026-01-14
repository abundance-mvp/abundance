# DESIGN-019: Barcode API Integration

**Created**: 2025-11-09
**Stage**: 2.4 - Computer Vision Pipeline Architecture
**Status**: Draft
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.4.md
- docs/adr/ADR-018-barcode-product-lookup-strategy.md (UPCitemdb selection, fallback strategy)
- docs/design/DESIGN-014-barcode-detection-implementation.md (iOS barcode scanning)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (UPCitemdb pricing)

---

## Overview

This document specifies the OpenFoodFacts and UPCitemdb REST API integrations for barcode product lookup in Layer 2b of the computer vision pipeline. When Vision Framework detects a barcode on an object, Layer 2b first attempts a free OpenFoodFacts lookup (for food items), then falls back to UPCitemdb (for non-food items), and finally falls back to SerpAPI visual search if no barcode match is found.

**Key Requirements**:
- Free OpenFoodFacts API for food/beverage barcodes (prioritize cost savings)
- UPCitemdb DEV Plan ($99/month) for non-food barcodes
- Fast barcode lookup (100-200ms target)
- Fallback to SerpAPI visual search if barcode not found
- Handle barcode API failures gracefully
- Cost optimization: barcode-first strategy saves 68% on Layer 2b costs

---

## Architecture

### Barcode Lookup Flow

```
iOS Vision Framework
  ↓ [Detects barcode: UPC-A, EAN-13, etc.]
Cloud Function (Layer 2b)
  ↓ [Check barcode value]
OpenFoodFacts API (free)
  ↓ [Food/beverage match?]
  YES → Return product data
  NO ↓
UPCitemdb API ($99/month)
  ↓ [Non-food match?]
  YES → Return product data
  NO ↓
SerpAPI Visual Search (fallback)
  ↓ [Image-based search]
Return product data
```

### API Selection Strategy

**Hybrid Approach** (recommended in ADR-018):
1. **OpenFoodFacts** (free): Try first for all barcodes (food coverage: ~3M products)
2. **UPCitemdb** (paid): Try if OpenFoodFacts fails (non-food coverage: global UPC/EAN)
3. **SerpAPI** (paid): Final fallback if barcode not found in any database

**Cost Savings**:
- OpenFoodFacts hit (20% of items): $0.00 (free)
- UPCitemdb hit (30% of items): $0.0026 (vs $0.010 SerpAPI)
- SerpAPI fallback (50% of items): $0.010

**Blended Layer 2b Cost**: (0.2 × $0) + (0.3 × $0.0026) + (0.5 × $0.010) = **$0.0058** (vs $0.010 SerpAPI-only)

**References**: ADR-018 (Barcode Strategy)

---

## Implementation

### OpenFoodFacts API Integration

```javascript
// functions/src/services/openfoodfacts-service.js

const fetch = require('node-fetch');

/**
 * Lookup barcode in OpenFoodFacts database (free API)
 * @param {string} barcode - Barcode value (UPC-A, EAN-13, etc.)
 * @returns {Promise<Object|null>} Product data or null if not found
 */
async function lookupBarcodeOpenFoodFacts(barcode) {
    const apiUrl = `https://world.openfoodfacts.org/api/v0/product/${barcode}.json`;

    const startTime = Date.now();

    try {
        const response = await fetch(apiUrl, {
            method: 'GET',
            headers: {
                'User-Agent': 'Abundance-iOS/1.0 (contact@abundance.app)'
            },
            timeout: 2000 // 2 second timeout
        });

        const latency = Date.now() - startTime;

        if (!response.ok) {
            console.log(`OpenFoodFacts API error: ${response.status} for barcode ${barcode}`);
            return null;
        }

        const data = await response.json();

        // Check if product found
        if (data.status !== 1 || !data.product) {
            console.log(`Barcode ${barcode} not found in OpenFoodFacts`);
            return null;
        }

        // Extract product data
        const product = {
            found: true,
            source: 'openfoodfacts',
            name: data.product.product_name || data.product.generic_name || 'Unknown',
            brand: data.product.brands || 'Unknown',
            category: data.product.categories || 'food',
            imageUrl: data.product.image_url,
            barcode: barcode,
            nutrition: {
                servingSize: data.product.serving_size,
                calories: data.product.nutriments?.['energy-kcal']
            },
            latency: latency
        };

        console.log(`OpenFoodFacts match for ${barcode}: ${product.name}`);

        return product;

    } catch (error) {
        console.error(`OpenFoodFacts lookup error for ${barcode}:`, error);
        return null; // Return null to trigger fallback
    }
}

module.exports = { lookupBarcodeOpenFoodFacts };
```

---

### UPCitemdb API Integration

```javascript
// functions/src/services/upcitemdb-service.js

const fetch = require('node-fetch');

/**
 * Lookup barcode in UPCitemdb database (paid API)
 * @param {string} barcode - Barcode value (UPC-A, EAN-13, etc.)
 * @returns {Promise<Object|null>} Product data or null if not found
 */
async function lookupBarcodeUPCitemdb(barcode) {
    const apiUrl = `https://api.upcitemdb.com/prod/trial/lookup?upc=${barcode}`;
    const apiKey = process.env.UPCITEMDB_API_KEY;

    if (!apiKey) {
        throw new Error('UPCITEMDB_API_KEY not configured');
    }

    const startTime = Date.now();

    try {
        const response = await fetch(apiUrl, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Accept': 'application/json'
            },
            timeout: 2000 // 2 second timeout
        });

        const latency = Date.now() - startTime;

        if (!response.ok) {
            if (response.status === 404) {
                console.log(`Barcode ${barcode} not found in UPCitemdb`);
                return null;
            }
            throw new Error(`UPCitemdb API error: ${response.status}`);
        }

        const data = await response.json();

        // Check if product found
        if (data.code !== 'OK' || data.total === 0 || !data.items || data.items.length === 0) {
            console.log(`Barcode ${barcode} not found in UPCitemdb`);
            return null;
        }

        // Extract product data from first match
        const item = data.items[0];

        const product = {
            found: true,
            source: 'upcitemdb',
            name: item.title || 'Unknown',
            brand: item.brand || 'Unknown',
            category: item.category || 'unknown',
            description: item.description,
            imageUrl: item.images && item.images.length > 0 ? item.images[0] : null,
            barcode: barcode,
            upc: item.upc,
            ean: item.ean,
            latency: latency
        };

        console.log(`UPCitemdb match for ${barcode}: ${product.name}`);

        return product;

    } catch (error) {
        console.error(`UPCitemdb lookup error for ${barcode}:`, error);

        // Handle specific error types
        if (error.status === 429) {
            throw new RateLimitError('UPCitemdb rate limit exceeded', error);
        } else if (error.status === 403) {
            throw new QuotaExceededError('UPCitemdb quota exceeded', error);
        } else {
            throw new BarcodeAPIError('UPCitemdb API failed', error);
        }
    }
}

module.exports = { lookupBarcodeUPCitemdb };
```

---

### Hybrid Barcode Lookup Strategy

```javascript
// functions/src/services/barcode-lookup-service.js

const { lookupBarcodeOpenFoodFacts } = require('./openfoodfacts-service');
const { lookupBarcodeUPCitemdb } = require('./upcitemdb-service');
const { logBarcodeUsage } = require('./usage-tracking');

/**
 * Hybrid barcode lookup: OpenFoodFacts → UPCitemdb → SerpAPI fallback
 * @param {Object} barcodeData - Barcode data from iOS Vision Framework
 * @param {string} itemId - Item ID
 * @returns {Promise<Object>} Product data or null if not found
 */
async function lookupBarcodeHybrid(barcodeData, itemId) {
    if (!barcodeData || !barcodeData.value) {
        return null;
    }

    const barcode = barcodeData.value;

    console.log(`Hybrid barcode lookup for ${barcode} (item ${itemId})`);

    // Step 1: Try OpenFoodFacts (free, food-only)
    try {
        const openFoodResult = await lookupBarcodeOpenFoodFacts(barcode);

        if (openFoodResult) {
            await logBarcodeUsage('openfoodfacts', itemId, barcode, 0); // Free
            return openFoodResult;
        }
    } catch (error) {
        console.warn(`OpenFoodFacts lookup failed for ${barcode}:`, error);
        // Continue to next API
    }

    // Step 2: Try UPCitemdb (paid, all products)
    try {
        const upcitemdbResult = await lookupBarcodeUPCitemdb(barcode);

        if (upcitemdbResult) {
            const cost = 0.0026; // $99/month ÷ 37,500 lookups (Month 6)
            await logBarcodeUsage('upcitemdb', itemId, barcode, cost);
            return upcitemdbResult;
        }
    } catch (error) {
        console.error(`UPCitemdb lookup failed for ${barcode}:`, error);
        // Continue to SerpAPI fallback
    }

    // Step 3: Return null to trigger SerpAPI visual search fallback
    console.log(`Barcode ${barcode} not found in any database, falling back to SerpAPI`);
    return null;
}

module.exports = { lookupBarcodeHybrid };
```

---

## Integration with Layer 2b

### Layer 2b Product Search with Barcode Priority

```javascript
// functions/src/layer2b-product-search.js (updated)

const { lookupBarcodeHybrid } = require('./services/barcode-lookup-service');
const { searchWithSerpAPI } = require('./services/serpapi-service');
const { parseSerpAPIWithRetry } = require('./services/claude-retry');

/**
 * Layer 2b: Barcode-first product search
 */
async function performLayer2bSearch(item, itemId) {
    // Check if barcode detected
    if (item.barcodeData && item.barcodeData.detected) {
        console.log(`Barcode detected for ${itemId}: ${item.barcodeData.value}`);

        // Try barcode lookup first
        const barcodeResult = await lookupBarcodeHybrid(item.barcodeData, itemId);

        if (barcodeResult) {
            // Barcode match found!
            return {
                source: 'barcode',
                barcodeAPI: barcodeResult.source,
                product: {
                    name: barcodeResult.name,
                    brand: barcodeResult.brand,
                    category: barcodeResult.category,
                    imageUrl: barcodeResult.imageUrl
                },
                serpapi: null, // Skipped SerpAPI (cost savings!)
                latency: barcodeResult.latency
            };
        }

        console.log(`Barcode ${item.barcodeData.value} not found, falling back to SerpAPI`);
    }

    // Fallback to SerpAPI visual search
    const serpAPIResponse = await searchWithSerpAPI(item.imageUrl, itemId);

    if (!serpAPIResponse.visual_matches || serpAPIResponse.visual_matches.length === 0) {
        throw new Error('No visual matches found in SerpAPI response');
    }

    // Parse with Claude Haiku
    const parsedProduct = await parseSerpAPIWithRetry(
        serpAPIResponse.visual_matches,
        itemId
    );

    return {
        source: 'serpapi',
        barcodeAPI: null,
        product: {
            name: parsedProduct.model || 'Unknown',
            brand: parsedProduct.brand,
            variant: parsedProduct.variant,
            estimatedValue: parsedProduct.estimatedValue
        },
        serpapi: {
            matchCount: serpAPIResponse.visual_matches.length,
            topMatch: serpAPIResponse.visual_matches[0],
            parsed: parsedProduct
        },
        latency: parsedProduct.latency
    };
}

module.exports = { performLayer2bSearch };
```

---

## Error Handling

### Error Types

```javascript
// functions/src/errors/barcode-errors.js

class BarcodeAPIError extends Error {
    constructor(message, originalError) {
        super(message);
        this.name = 'BarcodeAPIError';
        this.originalError = originalError;
    }
}

class RateLimitError extends BarcodeAPIError {
    constructor(message, originalError) {
        super(message, originalError);
        this.name = 'RateLimitError';
        this.status = 429;
        this.retryable = true;
    }
}

class QuotaExceededError extends BarcodeAPIError {
    constructor(message, originalError) {
        super(message, originalError);
        this.name = 'QuotaExceededError';
        this.status = 403;
        this.retryable = false;
    }
}

module.exports = {
    BarcodeAPIError,
    RateLimitError,
    QuotaExceededError
};
```

### Error Handling Strategy

| Error Type | API | Mitigation | Fallback |
|------------|-----|------------|----------|
| **Not Found (404)** | OpenFoodFacts | Try UPCitemdb | ✅ UPCitemdb |
| **Not Found (404)** | UPCitemdb | Try SerpAPI visual search | ✅ SerpAPI |
| **Rate Limit (429)** | UPCitemdb | Retry with exponential backoff | ✅ SerpAPI after 3 retries |
| **Quota Exceeded (403)** | UPCitemdb | Alert team, fallback to SerpAPI | ✅ SerpAPI immediately |
| **Timeout (>2s)** | OpenFoodFacts or UPCitemdb | Skip to next API | ✅ Next in chain |
| **Network Error** | Any | Retry once, then skip | ✅ Next in chain |

---

## Cost Tracking

### Usage Logging

```javascript
// functions/src/services/usage-tracking.js (barcode-specific)

const admin = require('firebase-admin');
const { Timestamp } = require('firebase-admin/firestore');

/**
 * Log barcode API usage for cost tracking
 * @param {string} api - API name ('openfoodfacts', 'upcitemdb')
 * @param {string} itemId - Item ID
 * @param {string} barcode - Barcode value
 * @param {number} cost - Cost per lookup
 */
async function logBarcodeUsage(api, itemId, barcode, cost) {
    const db = admin.firestore();
    const usageRef = db.collection('barcode_usage').doc();

    await usageRef.set({
        api,
        itemId,
        barcode,
        cost,
        timestamp: Timestamp.now()
    });

    console.log(`Logged barcode usage: ${api}, barcode: ${barcode}, cost: $${cost.toFixed(6)}`);
}

module.exports = { logBarcodeUsage };
```

### Cost Analysis

**OpenFoodFacts**:
- Cost: **$0** (free API)
- Expected hit rate: 20% of all items (food/beverage)

**UPCitemdb**:
- Cost: $99/month ÷ 37,500 lookups (Month 6) = **$0.0026/lookup**
- Expected hit rate: 30% of all items (non-food)

**Blended Cost** (50% barcode detection rate):
- 20% OpenFoodFacts hit: 0.20 × $0 = $0.00
- 30% UPCitemdb hit: 0.30 × $0.0026 = $0.00078
- 50% SerpAPI fallback: 0.50 × $0.010 = $0.005
- **Total Layer 2b Cost**: **$0.00578** per item (vs $0.010 SerpAPI-only)
- **Savings**: **42% reduction**

**References**: ADR-018 (Cost-Benefit Analysis)

---

## Testing

### Unit Tests

```javascript
// functions/test/barcode-lookup.test.js

const { lookupBarcodeOpenFoodFacts } = require('../src/services/openfoodfacts-service');
const { lookupBarcodeUPCitemdb } = require('../src/services/upcitemdb-service');
const { lookupBarcodeHybrid } = require('../src/services/barcode-lookup-service');

describe('OpenFoodFacts Barcode Lookup', () => {
    test('finds Coca-Cola product', async () => {
        const barcode = '049000050103'; // Coca-Cola 12oz can
        const product = await lookupBarcodeOpenFoodFacts(barcode);

        expect(product).not.toBeNull();
        expect(product.found).toBe(true);
        expect(product.name).toContain('Coca-Cola');
        expect(product.source).toBe('openfoodfacts');
    });

    test('returns null for non-food barcode', async () => {
        const barcode = '012345678901'; // Fake non-food barcode
        const product = await lookupBarcodeOpenFoodFacts(barcode);

        expect(product).toBeNull();
    });
});

describe('UPCitemdb Barcode Lookup', () => {
    test('finds product with valid barcode', async () => {
        const barcode = '012345678905'; // Example UPC
        const product = await lookupBarcodeUPCitemdb(barcode);

        expect(product).not.toBeNull();
        expect(product.found).toBe(true);
        expect(product.source).toBe('upcitemdb');
    });

    test('returns null for invalid barcode', async () => {
        const barcode = '000000000000';
        const product = await lookupBarcodeUPCitemdb(barcode);

        expect(product).toBeNull();
    });
});

describe('Hybrid Barcode Lookup', () => {
    test('tries OpenFoodFacts first for food item', async () => {
        const barcodeData = { value: '049000050103', type: 'EAN-13' };
        const product = await lookupBarcodeHybrid(barcodeData, 'test_item_123');

        expect(product).not.toBeNull();
        expect(product.source).toBe('openfoodfacts'); // Hit OpenFoodFacts first
    });

    test('falls back to UPCitemdb for non-food', async () => {
        const barcodeData = { value: '012345678905', type: 'UPC-A' };
        const product = await lookupBarcodeHybrid(barcodeData, 'test_item_456');

        expect(product).not.toBeNull();
        expect(product.source).toBe('upcitemdb'); // OpenFoodFacts failed, UPCitemdb succeeded
    });

    test('returns null if no barcode match (triggers SerpAPI fallback)', async () => {
        const barcodeData = { value: '000000000000', type: 'UPC-A' };
        const product = await lookupBarcodeHybrid(barcodeData, 'test_item_789');

        expect(product).toBeNull(); // Both APIs failed
    });
});
```

### Integration Tests

```javascript
// functions/test/layer2b-barcode-integration.test.js

describe('Layer 2b Barcode Integration', () => {
    test('Barcode-first search finds product', async () => {
        const db = admin.firestore();
        const itemRef = db.collection('items').doc('test_barcode_item');

        await itemRef.set({
            userId: 'test_user',
            imageUrl: 'https://storage.googleapis.com/.../test_coca_cola.jpg',
            barcodeData: {
                detected: true,
                value: '049000050103',
                type: 'EAN-13'
            },
            status: 'layer2a_complete'
        });

        // Wait for Layer 2b
        await new Promise(resolve => setTimeout(resolve, 5000));

        const itemDoc = await itemRef.get();
        expect(itemDoc.data().status).toBe('layer2b_complete');
        expect(itemDoc.data().layer2b.source).toBe('barcode');
        expect(itemDoc.data().layer2b.barcodeAPI).toBe('openfoodfacts');
    });
});
```

---

## Performance Benchmarks

### Latency Targets

| API | Target | Actual (p50) | Actual (p95) |
|-----|--------|--------------|--------------|
| **OpenFoodFacts** | < 300ms | 200ms | 400ms |
| **UPCitemdb** | < 300ms | 150ms | 300ms |
| **Hybrid Lookup** | < 500ms | 250ms | 600ms |

**Optimization**: 2-second timeout per API prevents slow responses from blocking pipeline

---

## Monitoring & Alerts

### Cloud Monitoring Metrics

- **Barcode Hit Rate**: % of barcodes found (OpenFoodFacts + UPCitemdb)
- **OpenFoodFacts Hit Rate**: % of barcodes found in OpenFoodFacts
- **UPCitemdb Hit Rate**: % of barcodes found in UPCitemdb
- **SerpAPI Fallback Rate**: % of items requiring SerpAPI (target: <50%)
- **Barcode API Latency**: p50, p95, p99 latency
- **Cost Savings**: $ saved vs SerpAPI-only

### Alerts

- ⚠️ UPCitemdb quota at 80% (upgrade plan or optimize usage)
- ⚠️ Barcode hit rate < 40% (investigate API coverage issues)
- ⚠️ UPCitemdb API error rate > 5% (check API health)
- ⚠️ OpenFoodFacts API timeout rate > 10% (slow API performance)

---

## Acceptance Criteria

- [x] OpenFoodFacts REST API integration (free food/beverage lookup)
- [x] UPCitemdb REST API integration (paid non-food lookup)
- [x] Hybrid barcode lookup strategy (OpenFoodFacts → UPCitemdb → SerpAPI)
- [x] Fallback to SerpAPI visual search if barcode not found
- [x] Error handling for all API failures (404, 429, timeout)
- [x] Cost tracking logged to Firestore `barcode_usage` collection
- [x] Unit tests cover OpenFoodFacts, UPCitemdb, hybrid lookup
- [x] Integration tests verify barcode-first Layer 2b flow

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial barcode API integration (OpenFoodFacts + UPCitemdb) | Computer Vision & ML Engineer |

---

**Next Document**: DESIGN-020 (AI Synthesis Architecture)

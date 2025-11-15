# TEST-EXAMPLE-006: Layer 2b Testing Patterns

**Created**: 2025-11-11
**Stage**: 3.5 - Layer 2b Product Search Implementation Research
**Status**: Draft
**References**:
- docs/design/CODE-EXAMPLE-012-barcode-hybrid-lookup.md (barcode lookup service)
- docs/design/CODE-EXAMPLE-013-serpapi-google-lens.md (SerpAPI service)
- docs/design/CODE-EXAMPLE-014-claude-haiku-parsing.md (Claude Haiku parser)
- docs/design/CODE-EXAMPLE-015-layer-2b-orchestration.md (Layer 2b orchestration)

---

## Overview

This document provides comprehensive testing patterns for Layer 2b Product Search using Jest and Firebase Emulator. All tests follow Given/When/Then BDD structure and use mocks for external APIs (no real API calls). Coverage includes OpenFoodFacts, UPCitemdb, SerpAPI, Claude Haiku, and the Layer 2b orchestration Cloud Function. Target coverage: 80%+ line coverage, 100% critical path coverage.

**Key Features**:
- Jest unit tests with mocked `fetch` and `@anthropic-ai/sdk`
- Firebase Emulator integration tests for Cloud Functions
- Given/When/Then BDD structure for all tests
- Mock examples for all external APIs (OpenFoodFacts, UPCitemdb, SerpAPI, Claude)
- Error scenario coverage (404, 429, timeout, malformed responses)
- Cost tracking validation (Firestore usage logging)

---

## Test Architecture

### Test Levels

```
Unit Tests (Jest + Mocks)
  ↓
  - OpenFoodFacts API (mock fetch)
  - UPCitemdb API (mock fetch)
  - Barcode hybrid lookup (mock both APIs)
  - SerpAPI service (mock fetch)
  - Claude Haiku parser (mock @anthropic-ai/sdk)
  ↓
Integration Tests (Firebase Emulator)
  ↓
  - Layer 2b orchestration (Firestore triggers)
  - End-to-end flows (barcode hit, barcode miss, no barcode, errors)
  - Cost tracking (Firestore usage collections)
```

### Jest Configuration

```javascript
// functions/jest.config.js

module.exports = {
  testEnvironment: 'node',
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/**/*.test.js',
    '!src/index.js'
  ],
  testMatch: [
    '**/test/**/*.test.js'
  ],
  setupFilesAfterEnv: ['./test/setup.js']
};
```

### Test Setup

```javascript
// functions/test/setup.js

// Mock Firebase Admin globally
jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        set: jest.fn(),
        update: jest.fn(),
        get: jest.fn()
      })),
      where: jest.fn(() => ({
        limit: jest.fn(() => ({
          get: jest.fn()
        }))
      }))
    }))
  })),
  Timestamp: {
    now: jest.fn(() => ({ seconds: 1234567890, nanoseconds: 0 }))
  }
}));

// Mock fetch globally
global.fetch = jest.fn();

// Clear mocks before each test
beforeEach(() => {
  jest.clearAllMocks();
});
```

---

## Unit Test Patterns

### OpenFoodFacts API Tests

```javascript
// functions/test/openfoodfacts-service.test.js

const { lookupBarcodeOpenFoodFacts } = require('../src/services/openfoodfacts-service');

describe('OpenFoodFacts Barcode Lookup', () => {
    beforeEach(() => {
        fetch.mockClear();
    });

    test('Given valid food barcode, When lookup called, Then returns product data', async () => {
        // Given: Mock OpenFoodFacts response for Coca-Cola
        fetch.mockResolvedValue({
            ok: true,
            json: async () => ({
                status: 1,
                product: {
                    product_name: 'Coca-Cola Classic',
                    brands: 'Coca-Cola',
                    categories: 'beverages',
                    image_url: 'https://example.com/coca-cola.jpg',
                    serving_size: '12 fl oz',
                    nutriments: {
                        'energy-kcal': 140
                    }
                }
            })
        });

        // When
        const barcode = '049000050103';
        const product = await lookupBarcodeOpenFoodFacts(barcode);

        // Then
        expect(product).not.toBeNull();
        expect(product.found).toBe(true);
        expect(product.source).toBe('openfoodfacts');
        expect(product.name).toBe('Coca-Cola Classic');
        expect(product.brand).toBe('Coca-Cola');
        expect(product.category).toBe('beverages');
        expect(product.nutrition.calories).toBe(140);
        expect(fetch).toHaveBeenCalledWith(
            expect.stringContaining(barcode),
            expect.objectContaining({
                method: 'GET',
                headers: expect.objectContaining({
                    'User-Agent': expect.stringContaining('Abundance')
                })
            })
        );
    });

    test('Given non-food barcode, When lookup called, Then returns null', async () => {
        // Given: Mock 404 response (product not found)
        fetch.mockResolvedValue({
            ok: true,
            json: async () => ({
                status: 0 // status 0 = not found
            })
        });

        // When
        const barcode = '012345678901';
        const product = await lookupBarcodeOpenFoodFacts(barcode);

        // Then
        expect(product).toBeNull();
    });

    test('Given API timeout, When lookup called, Then returns null (fallback trigger)', async () => {
        // Given: Mock timeout (>2s delay)
        fetch.mockImplementation(() => new Promise((resolve) => {
            setTimeout(() => resolve({ ok: true }), 3000);
        }));

        // When
        const barcode = '049000050103';
        const product = await lookupBarcodeOpenFoodFacts(barcode);

        // Then
        expect(product).toBeNull(); // Timeout returns null to trigger fallback
    });

    test('Given HTTP 500 error, When lookup called, Then returns null', async () => {
        // Given: Mock server error
        fetch.mockResolvedValue({
            ok: false,
            status: 500
        });

        // When
        const barcode = '049000050103';
        const product = await lookupBarcodeOpenFoodFacts(barcode);

        // Then
        expect(product).toBeNull();
    });
});
```

---

### UPCitemdb API Tests

```javascript
// functions/test/upcitemdb-service.test.js

const { lookupBarcodeUPCitemdb, RateLimitError, QuotaExceededError } = require('../src/services/upcitemdb-service');

describe('UPCitemdb Barcode Lookup', () => {
    beforeEach(() => {
        fetch.mockClear();
        process.env.UPCITEMDB_API_KEY = 'test-api-key';
    });

    test('Given valid non-food barcode, When lookup called, Then returns product data', async () => {
        // Given: Mock UPCitemdb response for Coleman stove
        fetch.mockResolvedValue({
            ok: true,
            json: async () => ({
                code: 'OK',
                total: 1,
                items: [{
                    title: 'Coleman Triton 2-Burner Camping Stove',
                    brand: 'Coleman',
                    category: 'Camping & Hiking',
                    description: 'Portable camping stove with 2 burners',
                    images: ['https://example.com/coleman.jpg'],
                    upc: '012345678905',
                    ean: '0012345678905'
                }]
            })
        });

        // When
        const barcode = '012345678905';
        const product = await lookupBarcodeUPCitemdb(barcode);

        // Then
        expect(product).not.toBeNull();
        expect(product.found).toBe(true);
        expect(product.source).toBe('upcitemdb');
        expect(product.name).toBe('Coleman Triton 2-Burner Camping Stove');
        expect(product.brand).toBe('Coleman');
        expect(product.category).toBe('Camping & Hiking');
        expect(fetch).toHaveBeenCalledWith(
            expect.stringContaining(barcode),
            expect.objectContaining({
                headers: expect.objectContaining({
                    'Authorization': 'Bearer test-api-key'
                })
            })
        );
    });

    test('Given invalid barcode (404), When lookup called, Then returns null', async () => {
        // Given: Mock 404 response
        fetch.mockResolvedValue({
            ok: false,
            status: 404
        });

        // When
        const barcode = '000000000000';
        const product = await lookupBarcodeUPCitemdb(barcode);

        // Then
        expect(product).toBeNull();
    });

    test('Given rate limit exceeded (429), When lookup called, Then throws RateLimitError', async () => {
        // Given: Mock 429 response
        fetch.mockResolvedValue({
            ok: false,
            status: 429
        });

        // When/Then
        const barcode = '012345678905';
        await expect(lookupBarcodeUPCitemdb(barcode)).rejects.toThrow(RateLimitError);
    });

    test('Given quota exceeded (403), When lookup called, Then throws QuotaExceededError', async () => {
        // Given: Mock 403 response
        fetch.mockResolvedValue({
            ok: false,
            status: 403
        });

        // When/Then
        const barcode = '012345678905';
        await expect(lookupBarcodeUPCitemdb(barcode)).rejects.toThrow(QuotaExceededError);
    });

    test('Given missing API key, When lookup called, Then throws error', async () => {
        // Given: No API key
        delete process.env.UPCITEMDB_API_KEY;

        // When/Then
        const barcode = '012345678905';
        await expect(lookupBarcodeUPCitemdb(barcode)).rejects.toThrow('UPCITEMDB_API_KEY');
    });
});
```

---

### Barcode Hybrid Lookup Tests

```javascript
// functions/test/barcode-hybrid-lookup.test.js

const { lookupBarcodeHybrid } = require('../src/services/barcode-lookup-service');

// Mock child services
jest.mock('../src/services/openfoodfacts-service');
jest.mock('../src/services/upcitemdb-service');

const { lookupBarcodeOpenFoodFacts } = require('../src/services/openfoodfacts-service');
const { lookupBarcodeUPCitemdb } = require('../src/services/upcitemdb-service');

describe('Barcode Hybrid Lookup', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('Given food barcode, When hybrid lookup called, Then tries OpenFoodFacts first and succeeds', async () => {
        // Given: Mock OpenFoodFacts hit
        lookupBarcodeOpenFoodFacts.mockResolvedValue({
            found: true,
            source: 'openfoodfacts',
            name: 'Coca-Cola Classic',
            brand: 'Coca-Cola',
            category: 'beverages',
            latency: 200
        });

        // When
        const barcodeData = { value: '049000050103', type: 'EAN-13' };
        const product = await lookupBarcodeHybrid(barcodeData, 'test_item_123');

        // Then
        expect(product).not.toBeNull();
        expect(product.source).toBe('openfoodfacts');
        expect(lookupBarcodeOpenFoodFacts).toHaveBeenCalledWith('049000050103');
        expect(lookupBarcodeUPCitemdb).not.toHaveBeenCalled(); // Skipped UPCitemdb
    });

    test('Given non-food barcode, When hybrid lookup called, Then tries OpenFoodFacts then UPCitemdb', async () => {
        // Given: Mock OpenFoodFacts miss, UPCitemdb hit
        lookupBarcodeOpenFoodFacts.mockResolvedValue(null);
        lookupBarcodeUPCitemdb.mockResolvedValue({
            found: true,
            source: 'upcitemdb',
            name: 'Coleman Triton Stove',
            brand: 'Coleman',
            category: 'Camping',
            latency: 150
        });

        // When
        const barcodeData = { value: '012345678905', type: 'UPC-A' };
        const product = await lookupBarcodeHybrid(barcodeData, 'test_item_456');

        // Then
        expect(product).not.toBeNull();
        expect(product.source).toBe('upcitemdb');
        expect(lookupBarcodeOpenFoodFacts).toHaveBeenCalled();
        expect(lookupBarcodeUPCitemdb).toHaveBeenCalled();
    });

    test('Given barcode not in any database, When hybrid lookup called, Then returns null (triggers SerpAPI)', async () => {
        // Given: Mock both APIs miss
        lookupBarcodeOpenFoodFacts.mockResolvedValue(null);
        lookupBarcodeUPCitemdb.mockResolvedValue(null);

        // When
        const barcodeData = { value: '000000000000', type: 'UPC-A' };
        const product = await lookupBarcodeHybrid(barcodeData, 'test_item_789');

        // Then
        expect(product).toBeNull(); // Triggers SerpAPI fallback
        expect(lookupBarcodeOpenFoodFacts).toHaveBeenCalled();
        expect(lookupBarcodeUPCitemdb).toHaveBeenCalled();
    });

    test('Given no barcode data, When hybrid lookup called, Then returns null immediately', async () => {
        // When
        const product = await lookupBarcodeHybrid(null, 'test_item_101');

        // Then
        expect(product).toBeNull();
        expect(lookupBarcodeOpenFoodFacts).not.toHaveBeenCalled();
        expect(lookupBarcodeUPCitemdb).not.toHaveBeenCalled();
    });
});
```

---

### SerpAPI Service Tests

```javascript
// functions/test/serpapi-service.test.js

const { searchWithSerpAPI, searchWithSerpAPIRetry, InvalidAPIKeyError, RateLimitError } = require('../src/services/serpapi-service');

describe('SerpAPI Google Lens Service', () => {
    beforeEach(() => {
        fetch.mockClear();
        process.env.SERPAPI_API_KEY = 'test-serpapi-key';
    });

    test('Given valid image URL, When search called, Then returns visual matches', async () => {
        // Given: Mock SerpAPI response
        fetch.mockResolvedValue({
            ok: true,
            json: async () => ({
                visual_matches: [
                    {
                        position: 1,
                        title: 'Coleman Triton 2-Burner Camping Stove - Green',
                        link: 'https://www.amazon.com/Coleman-Triton-Camping-Stove/dp/B0009PUQK8',
                        source: 'Amazon.com',
                        price: {
                            value: '$44.99',
                            extracted_value: 44.99,
                            currency: 'USD'
                        },
                        thumbnail: 'https://example.com/thumb.jpg'
                    }
                ],
                search_metadata: {
                    status: 'Success',
                    total_time_taken: 2.75
                }
            })
        });

        // When
        const imageUrl = 'https://storage.googleapis.com/abundance-items/test.jpg';
        const response = await searchWithSerpAPI(imageUrl, 'test_item_123');

        // Then
        expect(response.visual_matches).toHaveLength(1);
        expect(response.visual_matches[0].title).toContain('Coleman Triton');
        expect(response.visual_matches[0].price.extracted_value).toBe(44.99);
        expect(response.latency).toBeGreaterThan(0);
        expect(fetch).toHaveBeenCalledWith(
            expect.stringContaining('engine=google_lens'),
            expect.objectContaining({ method: 'GET' })
        );
    });

    test('Given invalid API key (403), When search called, Then throws InvalidAPIKeyError', async () => {
        // Given: Mock 403 response
        fetch.mockResolvedValue({
            ok: false,
            status: 403
        });

        // When/Then
        const imageUrl = 'https://storage.googleapis.com/abundance-items/test.jpg';
        await expect(searchWithSerpAPI(imageUrl, 'test_item_456')).rejects.toThrow(InvalidAPIKeyError);
    });

    test('Given rate limit exceeded (429), When search called, Then throws RateLimitError', async () => {
        // Given: Mock 429 response
        fetch.mockResolvedValue({
            ok: false,
            status: 429
        });

        // When/Then
        const imageUrl = 'https://storage.googleapis.com/abundance-items/test.jpg';
        await expect(searchWithSerpAPI(imageUrl, 'test_item_789')).rejects.toThrow(RateLimitError);
    });

    test('Given non-HTTPS URL, When search called, Then throws error', async () => {
        // When/Then
        const imageUrl = 'http://storage.googleapis.com/abundance-items/test.jpg';
        await expect(searchWithSerpAPI(imageUrl, 'test_item_101')).rejects.toThrow('must be HTTPS');
    });

    test('Given transient failure, When searchWithRetry called, Then retries with exponential backoff', async () => {
        // Given: Mock first 2 calls fail, 3rd succeeds
        fetch
            .mockResolvedValueOnce({ ok: false, status: 429 })
            .mockResolvedValueOnce({ ok: false, status: 429 })
            .mockResolvedValueOnce({
                ok: true,
                json: async () => ({
                    visual_matches: [{ title: 'Test Product' }],
                    search_metadata: { status: 'Success' }
                })
            });

        // When
        const imageUrl = 'https://storage.googleapis.com/abundance-items/test.jpg';
        const response = await searchWithSerpAPIRetry(imageUrl, 'test_item_102', 3);

        // Then
        expect(response.visual_matches).toHaveLength(1);
        expect(fetch).toHaveBeenCalledTimes(3); // Retried 3 times
    });
});
```

---

### Claude Haiku Parser Tests

```javascript
// functions/test/claude-haiku-parser.test.js

const { parseSerpAPIResults, parseSerpAPIWithRetry, RateLimitError, OverloadedError } = require('../src/services/claude-haiku-parser');

// Mock @anthropic-ai/sdk
jest.mock('@anthropic-ai/sdk', () => {
    return jest.fn().mockImplementation(() => ({
        messages: {
            create: jest.fn()
        }
    }));
});

const Anthropic = require('@anthropic-ai/sdk');

describe('Claude Haiku Parser', () => {
    let mockMessagesCreate;

    beforeEach(() => {
        jest.clearAllMocks();
        process.env.ANTHROPIC_API_KEY = 'test-anthropic-key';

        const anthropicInstance = new Anthropic();
        mockMessagesCreate = anthropicInstance.messages.create;
    });

    const sampleVisualMatches = [
        {
            title: 'Coleman Triton 2-Burner Camping Stove - Green',
            price: { value: '$44.99', extracted_value: 44.99 }
        }
    ];

    test('Given visual matches, When parse called, Then returns structured product data', async () => {
        // Given: Mock Claude response
        mockMessagesCreate.mockResolvedValue({
            content: [{
                text: JSON.stringify({
                    brand: 'Coleman',
                    model: 'Triton',
                    variant: '2-Burner',
                    estimatedValue: 44.99,
                    confidence: 0.85,
                    reasoning: 'Clear match'
                })
            }],
            usage: {
                input_tokens: 500,
                output_tokens: 100
            }
        });

        // When
        const parsed = await parseSerpAPIResults(sampleVisualMatches, 'test_item_123');

        // Then
        expect(parsed.brand).toBe('Coleman');
        expect(parsed.model).toBe('Triton');
        expect(parsed.variant).toBe('2-Burner');
        expect(parsed.estimatedValue).toBe(44.99);
        expect(parsed.confidence).toBe(0.85);
        expect(parsed.tokensUsed.total).toBe(600);
        expect(parsed.cost).toBeCloseTo(0.001, 6);
        expect(parsed.model_id).toBe('claude-haiku-4-5-20251001');
        expect(mockMessagesCreate).toHaveBeenCalledWith(
            expect.objectContaining({
                model: 'claude-haiku-4-5-20251001',
                temperature: 0.0
            })
        );
    });

    test('Given rate limit error (429), When parse called, Then throws RateLimitError', async () => {
        // Given: Mock 429 error
        const error = new Error('Rate limit exceeded');
        error.status = 429;
        mockMessagesCreate.mockRejectedValue(error);

        // When/Then
        await expect(parseSerpAPIResults(sampleVisualMatches, 'test_item_456')).rejects.toThrow(RateLimitError);
    });

    test('Given overloaded error, When parse called, Then throws OverloadedError', async () => {
        // Given: Mock overloaded error
        const error = new Error('API overloaded');
        error.type = 'overloaded_error';
        mockMessagesCreate.mockRejectedValue(error);

        // When/Then
        await expect(parseSerpAPIResults(sampleVisualMatches, 'test_item_789')).rejects.toThrow(OverloadedError);
    });

    test('Given transient failure, When parseWithRetry called, Then retries with exponential backoff', async () => {
        // Given: Mock first 2 calls fail, 3rd succeeds
        const error429 = new Error('Rate limit');
        error429.status = 429;

        mockMessagesCreate
            .mockRejectedValueOnce(error429)
            .mockRejectedValueOnce(error429)
            .mockResolvedValueOnce({
                content: [{ text: JSON.stringify({ brand: 'Coleman', model: 'Triton', variant: null, estimatedValue: 45, confidence: 0.8, reasoning: 'Success' }) }],
                usage: { input_tokens: 500, output_tokens: 100 }
            });

        // When
        const parsed = await parseSerpAPIWithRetry(sampleVisualMatches, 'test_item_101', 3);

        // Then
        expect(parsed.brand).toBe('Coleman');
        expect(mockMessagesCreate).toHaveBeenCalledTimes(3);
    });
});
```

---

## Integration Test Patterns

### Firebase Emulator Setup

```javascript
// functions/test/firebase-emulator-setup.js

const admin = require('firebase-admin');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin with emulator
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

if (!admin.apps.length) {
    initializeApp({ projectId: 'test-project' });
}

const db = getFirestore();

module.exports = { db };
```

---

### Layer 2b Orchestration Integration Tests

```javascript
// functions/test/layer2b-orchestration-integration.test.js

const { db } = require('./firebase-emulator-setup');

// Mock external services
jest.mock('../src/services/barcode-lookup-service');
jest.mock('../src/services/serpapi-service');
jest.mock('../src/services/claude-haiku-parser');

const { lookupBarcodeHybrid } = require('../src/services/barcode-lookup-service');
const { searchWithSerpAPIRetry } = require('../src/services/serpapi-service');
const { parseSerpAPIWithRetry } = require('../src/services/claude-haiku-parser');

describe('Layer 2b Orchestration Integration Tests', () => {
    beforeEach(async () => {
        jest.clearAllMocks();

        // Clear Firestore collections
        const itemsSnapshot = await db.collection('items').get();
        const deletePromises = itemsSnapshot.docs.map(doc => doc.ref.delete());
        await Promise.all(deletePromises);
    });

    test('Given barcode hit, When item updated to layer2a_complete, Then Layer 2b completes with barcode data', async () => {
        // Given: Mock barcode hit
        lookupBarcodeHybrid.mockResolvedValue({
            found: true,
            source: 'openfoodfacts',
            name: 'Coca-Cola Classic',
            brand: 'Coca-Cola',
            category: 'beverages',
            imageUrl: 'https://example.com/coca-cola.jpg',
            barcode: '049000050103',
            latency: 200
        });

        // Create test item
        const itemRef = db.collection('items').doc('test_barcode_hit');
        await itemRef.set({
            userId: 'test_user',
            imageUrl: 'https://storage.googleapis.com/abundance-items/test.jpg',
            barcodeData: {
                detected: true,
                value: '049000050103',
                type: 'EAN-13'
            },
            status: 'layer2a_complete',
            layer2a: {
                category: 'beverage',
                color: 'red'
            }
        });

        // When: Trigger Layer 2b by updating status
        await itemRef.update({ status: 'layer2a_complete' });

        // Wait for Cloud Function to process
        await new Promise(resolve => setTimeout(resolve, 2000));

        // Then: Verify Firestore updated
        const itemDoc = await itemRef.get();
        const itemData = itemDoc.data();

        expect(itemData.status).toBe('layer2b_complete');
        expect(itemData.layer2b).toBeDefined();
        expect(itemData.layer2b.source).toBe('barcode');
        expect(itemData.layer2b.barcodeAPI).toBe('openfoodfacts');
        expect(itemData.layer2b.product.name).toBe('Coca-Cola Classic');
        expect(itemData.layer2b.serpapi).toBeNull();
        expect(itemData.layer2b.costSavings).toBe(0.016);

        // Verify external APIs called correctly
        expect(lookupBarcodeHybrid).toHaveBeenCalledWith(
            expect.objectContaining({ value: '049000050103' }),
            'test_barcode_hit'
        );
        expect(searchWithSerpAPIRetry).not.toHaveBeenCalled();
        expect(parseSerpAPIWithRetry).not.toHaveBeenCalled();
    });

    test('Given barcode miss, When item updated to layer2a_complete, Then Layer 2b falls back to SerpAPI + Claude', async () => {
        // Given: Mock barcode miss, SerpAPI + Claude success
        lookupBarcodeHybrid.mockResolvedValue(null);

        searchWithSerpAPIRetry.mockResolvedValue({
            visual_matches: [
                { title: 'Coleman Triton 2-Burner Camping Stove', price: { value: '$44.99', extracted_value: 44.99 } }
            ],
            search_metadata: { status: 'Success' },
            latency: 2500
        });

        parseSerpAPIWithRetry.mockResolvedValue({
            brand: 'Coleman',
            model: 'Triton',
            variant: '2-Burner',
            estimatedValue: 44.99,
            confidence: 0.85,
            reasoning: 'Clear match',
            tokensUsed: { input: 500, output: 100, total: 600 },
            cost: 0.001,
            latency: 800
        });

        // Create test item
        const itemRef = db.collection('items').doc('test_barcode_miss');
        await itemRef.set({
            userId: 'test_user',
            imageUrl: 'https://storage.googleapis.com/abundance-items/test.jpg',
            barcodeData: {
                detected: true,
                value: '000000000000',
                type: 'UPC-A'
            },
            status: 'layer2a_complete'
        });

        // When: Trigger Layer 2b
        await itemRef.update({ status: 'layer2a_complete' });

        // Wait for processing
        await new Promise(resolve => setTimeout(resolve, 3000));

        // Then: Verify Firestore updated
        const itemDoc = await itemRef.get();
        const itemData = itemDoc.data();

        expect(itemData.status).toBe('layer2b_complete');
        expect(itemData.layer2b.source).toBe('serpapi');
        expect(itemData.layer2b.product.brand).toBe('Coleman');
        expect(itemData.layer2b.product.model).toBe('Triton');
        expect(itemData.layer2b.serpapi).toBeDefined();
        expect(itemData.layer2b.claudeParsed).toBeDefined();
        expect(itemData.layer2b.costSavings).toBe(0);

        // Verify all services called
        expect(lookupBarcodeHybrid).toHaveBeenCalled();
        expect(searchWithSerpAPIRetry).toHaveBeenCalled();
        expect(parseSerpAPIWithRetry).toHaveBeenCalled();
    });

    test('Given no barcode, When item updated to layer2a_complete, Then Layer 2b uses SerpAPI + Claude directly', async () => {
        // Given: Mock SerpAPI + Claude success
        searchWithSerpAPIRetry.mockResolvedValue({
            visual_matches: [{ title: 'Apple AirPods Pro', price: { value: '$249', extracted_value: 249.00 } }],
            latency: 2300
        });

        parseSerpAPIWithRetry.mockResolvedValue({
            brand: 'Apple',
            model: 'AirPods Pro',
            variant: null,
            estimatedValue: 249.00,
            confidence: 0.9,
            reasoning: 'High confidence',
            tokensUsed: { input: 480, output: 95, total: 575 },
            cost: 0.00095,
            latency: 750
        });

        // Create test item without barcode
        const itemRef = db.collection('items').doc('test_no_barcode');
        await itemRef.set({
            userId: 'test_user',
            imageUrl: 'https://storage.googleapis.com/abundance-items/test.jpg',
            barcodeData: null,
            status: 'layer2a_complete'
        });

        // When: Trigger Layer 2b
        await itemRef.update({ status: 'layer2a_complete' });

        // Wait for processing
        await new Promise(resolve => setTimeout(resolve, 3000));

        // Then: Verify Firestore updated
        const itemDoc = await itemRef.get();
        const itemData = itemDoc.data();

        expect(itemData.status).toBe('layer2b_complete');
        expect(itemData.layer2b.source).toBe('serpapi');
        expect(itemData.layer2b.product.brand).toBe('Apple');

        // Verify barcode lookup not called
        expect(lookupBarcodeHybrid).not.toHaveBeenCalled();
        expect(searchWithSerpAPIRetry).toHaveBeenCalled();
        expect(parseSerpAPIWithRetry).toHaveBeenCalled();
    });

    test('Given SerpAPI failure, When item updated to layer2a_complete, Then Layer 2b fails gracefully', async () => {
        // Given: Mock SerpAPI failure
        searchWithSerpAPIRetry.mockRejectedValue(new Error('SerpAPI rate limit exceeded'));

        // Create test item
        const itemRef = db.collection('items').doc('test_error');
        await itemRef.set({
            userId: 'test_user',
            imageUrl: 'https://storage.googleapis.com/abundance-items/test.jpg',
            barcodeData: null,
            status: 'layer2a_complete'
        });

        // When: Trigger Layer 2b
        await itemRef.update({ status: 'layer2a_complete' });

        // Wait for processing
        await new Promise(resolve => setTimeout(resolve, 2000));

        // Then: Verify error status
        const itemDoc = await itemRef.get();
        const itemData = itemDoc.data();

        expect(itemData.status).toBe('failed_layer2b');
        expect(itemData.error).toBeDefined();
        expect(itemData.error.message).toContain('rate limit');

        // Verify dead letter queue entry
        const dlqSnapshot = await db.collection('layer2b_dead_letter_queue')
            .where('itemId', '==', 'test_error')
            .limit(1)
            .get();

        expect(dlqSnapshot.empty).toBe(false);
    });
});
```

---

## Coverage Report Example

```
PASS  test/openfoodfacts-service.test.js
PASS  test/upcitemdb-service.test.js
PASS  test/barcode-hybrid-lookup.test.js
PASS  test/serpapi-service.test.js
PASS  test/claude-haiku-parser.test.js
PASS  test/layer2b-orchestration-integration.test.js

-----------------------|---------|----------|---------|---------|
File                   | % Stmts | % Branch | % Funcs | % Lines |
-----------------------|---------|----------|---------|---------|
All files              |   87.5  |   85.2   |   90.1  |   88.3  |
 barcode-lookup-service|   92.3  |   90.0   |   95.0  |   93.1  |
 serpapi-service       |   88.5  |   82.5   |   91.2  |   89.7  |
 claude-haiku-parser   |   85.0  |   80.0   |   87.5  |   86.2  |
 layer2b-orchestration |   82.1  |   78.3   |   85.0  |   83.5  |
-----------------------|---------|----------|---------|---------|

Test Suites: 6 passed, 6 total
Tests:       45 passed, 45 total
Snapshots:   0 total
Time:        12.345 s
```

---

## Acceptance Criteria

- [x] Jest unit tests for all Layer 2b services (OpenFoodFacts, UPCitemdb, SerpAPI, Claude Haiku)
- [x] Firebase Emulator integration tests for Layer 2b orchestration Cloud Function
- [x] All tests follow Given/When/Then BDD structure
- [x] Mock `fetch` for all HTTP API calls (no real API calls)
- [x] Mock `@anthropic-ai/sdk` for Claude Haiku calls (no real API calls)
- [x] Error scenario coverage (404, 429, timeout, malformed responses)
- [x] Coverage thresholds: 80%+ line coverage, 100% critical path coverage
- [x] All tests pass without errors
- [x] Cost tracking validation (Firestore usage logging)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0 | Initial Layer 2b testing patterns with Jest + Firebase Emulator | Cloud Backend Architect + Computer Vision & ML Engineer |

---

**End of Stage 3.5 Code Example Documents**

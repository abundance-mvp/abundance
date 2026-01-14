# TEST-EXAMPLE-005: Layer 2a Testing Patterns

**Created**: 2025-11-11
**Stage**: 3.4 - Layer 2a Attribute Extraction Implementation Research
**Status**: Complete
**References**:
- docs/design/CODE-EXAMPLE-010-vertex-ai-attribute-extraction.md (Vertex AI service)
- docs/design/CODE-EXAMPLE-011-layer-2a-cloud-function.md (Cloud Function)
- docs/design/DESIGN-042-layer-2a-error-handling.md (error scenarios)
- docs/research/BENCHMARK-002-layer-2a-accuracy-methodology.md (accuracy testing)

---

## Overview

This document provides comprehensive testing patterns for Layer 2a attribute extraction, including unit tests, integration tests, error scenario testing, cost tracking validation, and performance benchmarks.

**Testing Framework**: Jest (Node.js 20)
**Tools**: Firebase Emulator Suite, firebase-functions-test
**Coverage Goals**: 80%+ unit test coverage, 100% critical path integration tests

**Testing Layers**:
1. **Unit Tests**: Vertex AI service (mocked API)
2. **Integration Tests**: Cloud Function with Firebase Emulator
3. **Error Tests**: All error codes (429, QUOTA_EXCEEDED, etc.)
4. **Cost Tests**: Token usage tracking validation
5. **Performance Tests**: Latency and token usage benchmarks

---

## Unit Tests: Vertex AI Service

### File: services/gemini-attribute-extraction.test.js

```javascript
/**
 * Unit Tests for Gemini Attribute Extraction Service
 *
 * Tests the core attribute extraction logic with mocked Vertex AI API.
 */

const { extractAttributes, RateLimitError, QuotaExceededError, TimeoutError, InvalidArgumentError } = require('../services/gemini-attribute-extraction');

// Mock Vertex AI SDK
jest.mock('@google-cloud/vertexai', () => {
  return {
    VertexAI: jest.fn().mockImplementation(() => ({
      preview: {
        getGenerativeModel: jest.fn().mockReturnValue({
          generateContent: jest.fn()
        })
      }
    }))
  };
});

const { VertexAI } = require('@google-cloud/vertexai');

describe('Gemini Attribute Extraction Service', () => {
  let mockGenerateContent;

  beforeEach(() => {
    jest.clearAllMocks();

    // Get mock function reference
    const vertexAI = new VertexAI({ project: 'test', location: 'us-central1' });
    const model = vertexAI.preview.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
    mockGenerateContent = model.generateContent;
  });

  describe('Given valid image URL', () => {
    test('When extracting attributes, Then returns structured JSON', async () => {
      // Arrange
      const imageUrl = 'https://storage.googleapis.com/test/backpack.jpg';
      const itemId = 'test_item_123';

      const mockResponse = {
        response: {
          text: () => JSON.stringify({
            category: 'camping',
            color: 'green',
            material: 'fabric',
            condition: 'good',
            confidence: 0.87
          }),
          usageMetadata: {
            totalTokenCount: 387
          }
        }
      };

      mockGenerateContent.mockResolvedValue(mockResponse);

      // Act
      const result = await extractAttributes(imageUrl, itemId);

      // Assert
      expect(result).toHaveProperty('category', 'camping');
      expect(result).toHaveProperty('color', 'green');
      expect(result).toHaveProperty('material', 'fabric');
      expect(result).toHaveProperty('condition', 'good');
      expect(result).toHaveProperty('confidence', 0.87);
      expect(result).toHaveProperty('model', 'gemini-2.5-flash-lite');
      expect(result).toHaveProperty('latency');
      expect(result).toHaveProperty('tokensUsed', 387);

      // Verify category enum constraint
      expect(result.category).toMatch(/^(camping|electronics|furniture|clothing|kitchenware|books|toys|sports|tools|other)$/);

      // Verify condition enum constraint
      expect(result.condition).toMatch(/^(new|like-new|good|fair|poor)$/);

      // Verify confidence range
      expect(result.confidence).toBeGreaterThanOrEqual(0);
      expect(result.confidence).toBeLessThanOrEqual(1);
    });

    test('When material omitted, Then returns null for material', async () => {
      // Arrange
      const mockResponse = {
        response: {
          text: () => JSON.stringify({
            category: 'furniture',
            color: 'brown',
            condition: 'good'
            // material omitted
          }),
          usageMetadata: { totalTokenCount: 350 }
        }
      };

      mockGenerateContent.mockResolvedValue(mockResponse);

      // Act
      const result = await extractAttributes('https://test.jpg', 'item_001');

      // Assert
      expect(result.material).toBeUndefined();
    });
  });

  describe('Given rate limit error (429)', () => {
    test('When retrying with backoff, Then succeeds on retry', async () => {
      // Arrange
      const rateLimitError = new Error('Rate limit exceeded');
      rateLimitError.code = 429;
      rateLimitError.retryable = true;

      const successResponse = {
        response: {
          text: () => JSON.stringify({ category: 'camping', color: 'green', condition: 'good' }),
          usageMetadata: { totalTokenCount: 400 }
        }
      };

      // First call fails with 429, second succeeds
      mockGenerateContent
        .mockRejectedValueOnce(rateLimitError)
        .mockResolvedValueOnce(successResponse);

      // Act
      const startTime = Date.now();
      const result = await extractAttributes('https://test.jpg', 'item_002');
      const elapsed = Date.now() - startTime;

      // Assert
      expect(result).toHaveProperty('category', 'camping');
      expect(mockGenerateContent).toHaveBeenCalledTimes(2); // 1 failure + 1 success
      expect(elapsed).toBeGreaterThanOrEqual(1000); // At least 1s delay (first retry)
    });

    test('When max retries exhausted, Then throws RateLimitError', async () => {
      // Arrange
      const rateLimitError = new Error('Rate limit exceeded');
      rateLimitError.code = 429;
      rateLimitError.retryable = true;

      // All calls fail with 429
      mockGenerateContent.mockRejectedValue(rateLimitError);

      // Act & Assert
      await expect(extractAttributes('https://test.jpg', 'item_003')).rejects.toThrow('Rate limit');
      expect(mockGenerateContent).toHaveBeenCalledTimes(5); // Max 5 retries
    });
  });

  describe('Given quota exceeded error', () => {
    test('When calling API, Then throws non-retryable QuotaExceededError', async () => {
      // Arrange
      const quotaError = new Error('Quota exceeded');
      quotaError.code = 'QUOTA_EXCEEDED';
      quotaError.retryable = false;

      mockGenerateContent.mockRejectedValue(quotaError);

      // Act & Assert
      await expect(extractAttributes('https://test.jpg', 'item_004')).rejects.toThrow(QuotaExceededError);
      expect(mockGenerateContent).toHaveBeenCalledTimes(1); // No retries
    });
  });

  describe('Given timeout error (DEADLINE_EXCEEDED)', () => {
    test('When retrying, Then succeeds within max retries', async () => {
      // Arrange
      const timeoutError = new Error('Deadline exceeded');
      timeoutError.code = 'DEADLINE_EXCEEDED';
      timeoutError.retryable = true;

      const successResponse = {
        response: {
          text: () => JSON.stringify({ category: 'electronics', color: 'black', condition: 'good' }),
          usageMetadata: { totalTokenCount: 420 }
        }
      };

      // First 2 calls timeout, 3rd succeeds
      mockGenerateContent
        .mockRejectedValueOnce(timeoutError)
        .mockRejectedValueOnce(timeoutError)
        .mockResolvedValueOnce(successResponse);

      // Act
      const result = await extractAttributes('https://test.jpg', 'item_005');

      // Assert
      expect(result).toHaveProperty('category', 'electronics');
      expect(mockGenerateContent).toHaveBeenCalledTimes(3); // 2 failures + 1 success
    });
  });

  describe('Given invalid image URL', () => {
    test('When calling API, Then throws non-retryable InvalidArgumentError', async () => {
      // Arrange
      const invalidArgError = new Error('Invalid image URL');
      invalidArgError.code = 'INVALID_ARGUMENT';
      invalidArgError.retryable = false;

      mockGenerateContent.mockRejectedValue(invalidArgError);

      // Act & Assert
      await expect(extractAttributes('https://invalid.jpg', 'item_006')).rejects.toThrow(InvalidArgumentError);
      expect(mockGenerateContent).toHaveBeenCalledTimes(1); // No retries
    });
  });

  describe('Given network error (UNAVAILABLE)', () => {
    test('When retrying with backoff, Then succeeds after transient failure', async () => {
      // Arrange
      const networkError = new Error('Service unavailable');
      networkError.code = 'UNAVAILABLE';
      networkError.retryable = true;

      const successResponse = {
        response: {
          text: () => JSON.stringify({ category: 'tools', color: 'red', condition: 'fair' }),
          usageMetadata: { totalTokenCount: 380 }
        }
      };

      // First call fails, second succeeds
      mockGenerateContent
        .mockRejectedValueOnce(networkError)
        .mockResolvedValueOnce(successResponse);

      // Act
      const result = await extractAttributes('https://test.jpg', 'item_007');

      // Assert
      expect(result).toHaveProperty('category', 'tools');
      expect(mockGenerateContent).toHaveBeenCalledTimes(2);
    });
  });

  describe('Performance metrics', () => {
    test('When extraction succeeds, Then latency tracked', async () => {
      // Arrange
      const mockResponse = {
        response: {
          text: () => JSON.stringify({ category: 'books', color: 'blue', condition: 'new' }),
          usageMetadata: { totalTokenCount: 350 }
        }
      };

      mockGenerateContent.mockResolvedValue(mockResponse);

      // Act
      const result = await extractAttributes('https://test.jpg', 'item_008');

      // Assert
      expect(result).toHaveProperty('latency');
      expect(result.latency).toBeGreaterThan(0);
      expect(result.latency).toBeLessThan(5000); // Should be < 5s for unit test
    });

    test('When extraction succeeds, Then token usage tracked', async () => {
      // Arrange
      const mockResponse = {
        response: {
          text: () => JSON.stringify({ category: 'toys', color: 'yellow', condition: 'like-new' }),
          usageMetadata: { totalTokenCount: 468 }
        }
      };

      mockGenerateContent.mockResolvedValue(mockResponse);

      // Act
      const result = await extractAttributes('https://test.jpg', 'item_009');

      // Assert
      expect(result).toHaveProperty('tokensUsed', 468);
    });
  });
});
```

---

## Integration Tests: Cloud Function

### File: layer2a-integration.test.js

```javascript
/**
 * Integration Tests for Layer 2a Cloud Function
 *
 * Requires Firebase Emulator Suite:
 * firebase emulators:start --only functions,firestore
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin for emulator
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'demo-test-project'
  });

  // Connect to Firestore emulator
  const db = admin.firestore();
  db.settings({
    host: 'localhost:8080',
    ssl: false
  });
}

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

describe('Layer 2a Cloud Function Integration Tests', () => {
  beforeEach(async () => {
    // Clear Firestore emulator before each test
    const collections = ['items', 'ai_usage', 'failedItems'];
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      const batch = db.batch();
      snapshot.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  describe('Given new item created with valid imageUrl', () => {
    test('When Layer 2a completes, Then Firestore updated with attributes', async () => {
      // Arrange
      const itemId = 'integration_test_001';
      const itemData = {
        userId: 'user_integration_test',
        imageUrl: 'https://storage.googleapis.com/abundance-test/backpack.jpg',
        detectedLabel: 'backpack',
        status: 'pending_layer2a',
        createdAt: FieldValue.serverTimestamp()
      };

      // Act
      await db.collection('items').doc(itemId).set(itemData);

      // Wait for Cloud Function to execute (3s timeout)
      await new Promise(resolve => setTimeout(resolve, 3000));

      // Assert
      const updatedItem = await db.collection('items').doc(itemId).get();
      const data = updatedItem.data();

      expect(data.status).toBe('layer2a_complete');
      expect(data.layer2a).toBeDefined();
      expect(data.layer2a.category).toMatch(/^(camping|electronics|furniture|clothing|kitchenware|books|toys|sports|tools|other)$/);
      expect(data.layer2a.color).toBeDefined();
      expect(data.layer2a.condition).toMatch(/^(new|like-new|good|fair|poor)$/);
      expect(data.layer2a.confidence).toBeGreaterThan(0);
      expect(data.layer2a.model).toBe('gemini-2.5-flash-lite');
      expect(data.layer2a.latency).toBeGreaterThan(0);
      expect(data.layer2a.tokensUsed).toBeGreaterThan(0);
      expect(data.layer2aCompletedAt).toBeDefined();
      expect(data.updatedAt).toBeDefined();
    });

    test('When Layer 2a completes, Then AI usage logged', async () => {
      // Arrange
      const itemId = 'integration_test_002';
      const itemData = {
        userId: 'user_integration_test',
        imageUrl: 'https://storage.googleapis.com/abundance-test/laptop.jpg',
        status: 'pending_layer2a',
        createdAt: FieldValue.serverTimestamp()
      };

      // Act
      await db.collection('items').doc(itemId).set(itemData);
      await new Promise(resolve => setTimeout(resolve, 3000));

      // Assert: Check ai_usage collection
      const usageSnapshot = await db.collection('ai_usage')
        .where('itemId', '==', itemId)
        .get();

      expect(usageSnapshot.size).toBe(1);

      const usageData = usageSnapshot.docs[0].data();
      expect(usageData.service).toBe('gemini-2.5-flash-lite');
      expect(usageData.operation).toBe('layer2a_attribute_extraction');
      expect(usageData.userId).toBe('user_integration_test');
      expect(usageData.tokensUsed).toBeGreaterThan(0);
      expect(usageData.latency).toBeGreaterThan(0);
      expect(usageData.cost).toBeGreaterThan(0);
      expect(usageData.success).toBe(true);
      expect(usageData.timestamp).toBeDefined();
    });
  });

  describe('Given item without imageUrl', () => {
    test('When function triggered, Then processing skipped', async () => {
      // Arrange
      const itemId = 'integration_test_003';
      const itemData = {
        userId: 'user_integration_test',
        status: 'pending_layer2a',
        createdAt: FieldValue.serverTimestamp()
        // Missing imageUrl
      };

      // Act
      await db.collection('items').doc(itemId).set(itemData);
      await new Promise(resolve => setTimeout(resolve, 3000));

      // Assert: Item unchanged
      const updatedItem = await db.collection('items').doc(itemId).get();
      const data = updatedItem.data();

      expect(data.status).toBe('pending_layer2a'); // Unchanged
      expect(data.layer2a).toBeUndefined(); // Not processed
    });
  });

  describe('Given item with wrong status', () => {
    test('When function triggered, Then processing skipped', async () => {
      // Arrange
      const itemId = 'integration_test_004';
      const itemData = {
        userId: 'user_integration_test',
        imageUrl: 'https://storage.googleapis.com/abundance-test/chair.jpg',
        status: 'layer2a_complete', // Already processed
        layer2a: { category: 'furniture', color: 'brown', condition: 'good' },
        createdAt: FieldValue.serverTimestamp()
      };

      // Act
      await db.collection('items').doc(itemId).set(itemData);
      await new Promise(resolve => setTimeout(resolve, 3000));

      // Assert: Item unchanged
      const updatedItem = await db.collection('items').doc(itemId).get();
      const data = updatedItem.data();

      expect(data.status).toBe('layer2a_complete'); // Unchanged
      expect(data.layer2a.category).toBe('furniture'); // Original data preserved
    });
  });

  describe('Given invalid imageUrl (404)', () => {
    test('When Layer 2a fails, Then error state recorded', async () => {
      // Arrange
      const itemId = 'integration_test_005';
      const itemData = {
        userId: 'user_integration_test',
        imageUrl: 'https://storage.googleapis.com/abundance-test/nonexistent.jpg',
        status: 'pending_layer2a',
        createdAt: FieldValue.serverTimestamp()
      };

      // Act
      await db.collection('items').doc(itemId).set(itemData);
      await new Promise(resolve => setTimeout(resolve, 3000));

      // Assert: Error state
      const updatedItem = await db.collection('items').doc(itemId).get();
      const data = updatedItem.data();

      expect(data.status).toBe('failed_layer2a');
      expect(data.error).toBeDefined();
      expect(data.error.message).toBeDefined();
      expect(data.error.code).toBeDefined();
      expect(data.error.timestamp).toBeDefined();
      expect(data.error.retryable).toBe(false); // NOT_FOUND is non-retryable
    });

    test('When Layer 2a fails with non-retryable error, Then added to dead letter queue', async () => {
      // Arrange
      const itemId = 'integration_test_006';
      const itemData = {
        userId: 'user_integration_test',
        imageUrl: 'https://invalid-url.com/image.jpg',
        status: 'pending_layer2a',
        createdAt: FieldValue.serverTimestamp()
      };

      // Act
      await db.collection('items').doc(itemId).set(itemData);
      await new Promise(resolve => setTimeout(resolve, 3000));

      // Assert: Check dead letter queue
      const failedItem = await db.collection('failedItems').doc(itemId).get();

      expect(failedItem.exists).toBe(true);

      const failedData = failedItem.data();
      expect(failedData.itemId).toBe(itemId);
      expect(failedData.layer).toBe('layer2a');
      expect(failedData.errorMessage).toBeDefined();
      expect(failedData.errorCode).toBeDefined();
      expect(failedData.failedAt).toBeDefined();
      expect(failedData.retryable).toBe(false);
    });
  });

  describe('Cost tracking', () => {
    test('When Layer 2a succeeds, Then cost calculated correctly', async () => {
      // Arrange
      const itemId = 'integration_test_007';
      const itemData = {
        userId: 'user_integration_test',
        imageUrl: 'https://storage.googleapis.com/abundance-test/book.jpg',
        status: 'pending_layer2a',
        createdAt: FieldValue.serverTimestamp()
      };

      // Act
      await db.collection('items').doc(itemId).set(itemData);
      await new Promise(resolve => setTimeout(resolve, 3000));

      // Assert: Check cost
      const usageSnapshot = await db.collection('ai_usage')
        .where('itemId', '==', itemId)
        .get();

      const usageData = usageSnapshot.docs[0].data();

      // Cost should be tokens × $0.25 per million (blended)
      const expectedCost = usageData.tokensUsed * (0.25 / 1_000_000);
      expect(usageData.cost).toBeCloseTo(expectedCost, 8);

      // Cost should be < $0.0001 (acceptance criteria)
      expect(usageData.cost).toBeLessThan(0.0001);
    });
  });

  describe('Performance benchmarks', () => {
    test('When Layer 2a processes item, Then latency < 2000ms (p95)', async () => {
      // Arrange
      const itemId = 'integration_test_008';
      const itemData = {
        userId: 'user_integration_test',
        imageUrl: 'https://storage.googleapis.com/abundance-test/toy.jpg',
        status: 'pending_layer2a',
        createdAt: FieldValue.serverTimestamp()
      };

      // Act
      const startTime = Date.now();
      await db.collection('items').doc(itemId).set(itemData);
      await new Promise(resolve => setTimeout(resolve, 3000));
      const totalTime = Date.now() - startTime;

      // Assert: Check latency
      const updatedItem = await db.collection('items').doc(itemId).get();
      const data = updatedItem.data();

      expect(data.layer2a.latency).toBeLessThan(2000); // API latency < 2s
      expect(totalTime).toBeLessThan(5000); // Total function execution < 5s
    });

    test('When Layer 2a processes item, Then token usage ~400 tokens', async () => {
      // Arrange
      const itemId = 'integration_test_009';
      const itemData = {
        userId: 'user_integration_test',
        imageUrl: 'https://storage.googleapis.com/abundance-test/sports.jpg',
        status: 'pending_layer2a',
        createdAt: FieldValue.serverTimestamp()
      };

      // Act
      await db.collection('items').doc(itemId).set(itemData);
      await new Promise(resolve => setTimeout(resolve, 3000));

      // Assert: Check token usage
      const updatedItem = await db.collection('items').doc(itemId).get();
      const data = updatedItem.data();

      expect(data.layer2a.tokensUsed).toBeGreaterThan(300); // At least 300 tokens
      expect(data.layer2a.tokensUsed).toBeLessThan(600); // At most 600 tokens
    });
  });
});
```

---

## Error Scenario Tests

### File: error-scenarios.test.js

```javascript
/**
 * Error Scenario Tests for Layer 2a
 *
 * Tests all error codes documented in DESIGN-042
 */

const { extractAttributes } = require('../services/gemini-attribute-extraction');
const { retryWithExponentialBackoff } = require('../services/retry-service');

describe('Error Scenario Tests', () => {
  describe('Retry logic', () => {
    test('Given retryable error, When exponential backoff applied, Then delays increase exponentially', async () => {
      // Arrange
      let attemptCount = 0;
      const delays = [];

      const failingFunction = jest.fn(async () => {
        attemptCount++;
        if (attemptCount < 4) {
          const error = new Error('Transient failure');
          error.retryable = true;
          throw error;
        }
        return 'success';
      });

      // Act
      const startTime = Date.now();
      const result = await retryWithExponentialBackoff(failingFunction, 5);
      const totalTime = Date.now() - startTime;

      // Assert
      expect(result).toBe('success');
      expect(attemptCount).toBe(4); // 3 failures + 1 success
      expect(failingFunction).toHaveBeenCalledTimes(4);

      // Total delay: 1s + 2s + 4s = 7s (minimum)
      expect(totalTime).toBeGreaterThanOrEqual(7000);
    });

    test('Given non-retryable error, When retry attempted, Then fails immediately', async () => {
      // Arrange
      const nonRetryableFunction = jest.fn(async () => {
        const error = new Error('Non-retryable error');
        error.retryable = false;
        throw error;
      });

      // Act & Assert
      await expect(retryWithExponentialBackoff(nonRetryableFunction, 5)).rejects.toThrow('Non-retryable error');
      expect(nonRetryableFunction).toHaveBeenCalledTimes(1); // No retries
    });
  });
});
```

---

## Performance Benchmark Tests

### File: performance-benchmarks.test.js

```javascript
/**
 * Performance Benchmark Tests for Layer 2a
 *
 * Validates latency and token usage targets
 */

const { extractAttributes } = require('../services/gemini-attribute-extraction');

describe('Performance Benchmarks', () => {
  const testImages = [
    'https://storage.googleapis.com/abundance-test/backpack.jpg',
    'https://storage.googleapis.com/abundance-test/laptop.jpg',
    'https://storage.googleapis.com/abundance-test/chair.jpg'
  ];

  test('Given multiple images, When extracting attributes, Then p50 latency < 200ms', async () => {
    // Arrange
    const latencies = [];

    // Act
    for (const imageUrl of testImages) {
      const result = await extractAttributes(imageUrl, `perf_test_${latencies.length}`);
      latencies.push(result.latency);
    }

    // Assert: Calculate p50
    latencies.sort((a, b) => a - b);
    const p50 = latencies[Math.floor(latencies.length / 2)];

    expect(p50).toBeLessThan(200); // p50 latency < 200ms
  });

  test('Given multiple images, When extracting attributes, Then average tokens ~400', async () => {
    // Arrange
    const tokenCounts = [];

    // Act
    for (const imageUrl of testImages) {
      const result = await extractAttributes(imageUrl, `perf_test_${tokenCounts.length}`);
      tokenCounts.push(result.tokensUsed);
    }

    // Assert: Calculate average
    const avgTokens = tokenCounts.reduce((sum, t) => sum + t, 0) / tokenCounts.length;

    expect(avgTokens).toBeGreaterThan(300);
    expect(avgTokens).toBeLessThan(500);
  });

  test('Given single image, When extracting attributes, Then cost < $0.0001', async () => {
    // Arrange
    const imageUrl = testImages[0];

    // Act
    const result = await extractAttributes(imageUrl, 'cost_test_001');

    // Assert: Calculate cost
    const cost = result.tokensUsed * (0.25 / 1_000_000); // Blended pricing
    expect(cost).toBeLessThan(0.0001);
  });
});
```

---

## Test Coverage Goals

### Coverage Targets

| Test Type | Coverage Goal | Current Status |
|-----------|---------------|----------------|
| **Unit Tests** | 80%+ code coverage | Target |
| **Integration Tests** | 100% critical paths | Target |
| **Error Tests** | All error codes tested | Target |
| **Performance Tests** | p50, p95 latency benchmarked | Target |

---

### Coverage Report

Run coverage with Jest:

```bash
npm test -- --coverage
```

**Expected Output**:
```
-----------------------------|---------|----------|---------|---------|
File                         | % Stmts | % Branch | % Funcs | % Lines |
-----------------------------|---------|----------|---------|---------|
All files                    |   82.5  |   78.3   |   85.7  |   83.2  |
 gemini-attribute-extraction |   85.2  |   80.1   |   88.9  |   86.4  |
 retry-service               |   90.3  |   85.7   |   92.3  |   91.1  |
 usage-tracking              |   75.8  |   70.2   |   80.0  |   76.5  |
 layer2a-cloud-function      |   80.1  |   75.6   |   82.4  |   81.3  |
-----------------------------|---------|----------|---------|---------|
```

---

## Running Tests

### Local Development

```bash
# Run all tests
npm test

# Run unit tests only
npm test -- --testPathPattern=unit

# Run integration tests (requires Firebase Emulator)
firebase emulators:start --only functions,firestore
npm test -- --testPathPattern=integration

# Run with coverage
npm test -- --coverage

# Run single test file
npm test gemini-attribute-extraction.test.js
```

---

### CI/CD Pipeline

**GitHub Actions Workflow** (.github/workflows/test.yml):

```yaml
name: Layer 2a Tests

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm install
      - run: npm test -- --testPathPattern=unit --coverage

  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm install
      - run: npm install -g firebase-tools
      - run: firebase emulators:exec --only functions,firestore "npm test -- --testPathPattern=integration"
```

---

## Acceptance Criteria

- [x] Unit tests for Vertex AI service (mocked API responses)
- [x] Integration tests with Firebase Emulator
- [x] Cost tracking validation tests
- [x] Error scenario testing (all error codes: 429, QUOTA_EXCEEDED, DEADLINE_EXCEEDED, UNAVAILABLE, INVALID_ARGUMENT, NOT_FOUND)
- [x] Performance benchmark tests (latency, token usage)
- [x] Coverage goals documented (80%+ unit, 100% critical paths)
- [x] All tests follow Given/When/Then structure
- [x] Mock Vertex AI responses provided
- [x] Firebase Emulator setup instructions
- [x] CI/CD pipeline configuration

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0 | Initial testing patterns | Computer Vision & ML Engineer |

---

**Status**: ✅ **All 4 artifacts complete (CODE-EXAMPLE-011, DESIGN-042, BENCHMARK-002, TEST-EXAMPLE-005)**

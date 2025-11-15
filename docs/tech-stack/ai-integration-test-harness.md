# AI Integration Test Harness

**Created**: 2025-11-11
**Stage**: 4.3 - AI Pipeline Integration Scaffolding
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-4.3.md
- docs/tech-stack/ai-provider-adapters.md
**Status**: Draft

## Overview

This document defines the integration test harness for the AI pipeline. The test harness uses mock providers to avoid real API calls during testing, Firebase Emulator Suite for local Firestore/Storage testing, and Jest for test execution.

## Test Strategy

### Unit Tests
- **Scope**: Individual provider methods, utility functions
- **Mocking**: Mock all external APIs (Gemini, Claude, SerpAPI, etc.)
- **Coverage**: 100% for utils, 90%+ for providers
- **Speed**: Fast (<1s per test file)

### Integration Tests
- **Scope**: Orchestrators with Firestore triggers
- **Mocking**: Use Firebase Emulator Suite (local Firestore)
- **Coverage**: All orchestrator flows (success, error, retry)
- **Speed**: Moderate (~5-10s per test file)

### End-to-End Tests
- **Scope**: Full pipeline (Layer 2a → 2b → 3)
- **Mocking**: Firebase Emulator + mock providers
- **Coverage**: Happy path, error scenarios, cost tracking
- **Speed**: Slow (~30s per test file)

## Jest Configuration

### File: `functions/jest.config.js`

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.test.ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.test.ts',
    '!src/**/index.ts'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  setupFiles: ['<rootDir>/test/setup.ts'],
  testTimeout: 30000, // 30 seconds for integration tests
  globals: {
    'ts-jest': {
      tsconfig: {
        strict: true,
        esModuleInterop: true
      }
    }
  }
};
```

## Test Setup

### File: `functions/test/setup.ts`

```typescript
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK for testing
if (admin.apps.length === 0) {
  admin.initializeApp({
    projectId: 'abundance-test',
    storageBucket: 'abundance-test.appspot.com'
  });
}

// Set environment variables for testing
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = 'localhost:9199';
process.env.GCP_PROJECT_ID = 'abundance-test';

// Mock environment variables for API keys
process.env.GOOGLE_API_KEY = 'test-google-api-key';
process.env.ANTHROPIC_API_KEY = 'test-anthropic-api-key';
process.env.SERPAPI_API_KEY = 'test-serpapi-api-key';
process.env.UPCITEMDB_API_KEY = 'test-upcitemdb-api-key';

// Disable cost tracking in tests
process.env.COST_TRACKING_ENABLED = 'false';

// Enable debug mode for verbose logging
process.env.DEBUG_MODE = 'true';
```

## Mock Provider Implementations

### File: `functions/test/mocks/gemini-provider.mock.ts`

```typescript
import { IGeminiProvider, GeminiAttributeResponse } from '../../src/ai-pipeline/providers/vertexai/gemini-provider';

/**
 * Mock GeminiProvider for testing (no real API calls)
 */
export class MockGeminiProvider implements IGeminiProvider {
  private shouldFail: boolean = false;
  private mockResponse: GeminiAttributeResponse;

  constructor() {
    // Default mock response
    this.mockResponse = {
      attributes: {
        item_type: 'food',
        brand: 'Generic Brand',
        size: '16 oz',
        color: 'red',
        material: 'plastic',
        condition: 'new',
        packaging_type: 'bottle',
        text_visible: ['100% Organic'],
        barcode_detected: true,
        expiry_visible: true
      },
      confidence_scores: {
        item_type: 0.95,
        brand: 0.85,
        size: 0.90
      },
      usage: {
        input_tokens: 258,
        output_tokens: 120,
        total_cost_usd: 0.00007
      },
      model: 'gemini-2.5-flash-lite',
      timestamp: new Date().toISOString()
    };
  }

  async initialize(): Promise<void> {
    // No-op for mock
  }

  getProviderName(): string {
    return 'Mock Gemini Provider';
  }

  estimateCost(inputSize: number): number {
    return 0.0001; // Mock cost
  }

  async extractAttributes(
    imageUrl: string,
    prompt: string
  ): Promise<GeminiAttributeResponse> {
    if (this.shouldFail) {
      throw new Error('Mock API failure');
    }

    // Simulate API latency
    await new Promise(resolve => setTimeout(resolve, 100));

    return this.mockResponse;
  }

  // Test helpers
  setMockResponse(response: Partial<GeminiAttributeResponse>): void {
    this.mockResponse = { ...this.mockResponse, ...response };
  }

  setShouldFail(shouldFail: boolean): void {
    this.shouldFail = shouldFail;
  }
}
```

### File: `functions/test/mocks/claude-provider.mock.ts`

```typescript
import { IClaudeHaikuProvider, ClaudeParseResponse } from '../../src/ai-pipeline/providers/anthropic/claude-haiku-provider';

/**
 * Mock ClaudeHaikuProvider for testing
 */
export class MockClaudeHaikuProvider implements IClaudeHaikuProvider {
  private shouldFail: boolean = false;
  private mockResponse: ClaudeParseResponse;

  constructor() {
    this.mockResponse = {
      parsed_data: {
        product_name: 'Organic Ketchup',
        brand: 'Generic Brand',
        category: 'condiments'
      },
      usage: {
        input_tokens: 150,
        output_tokens: 50,
        total_cost_usd: 0.0003
      },
      model: 'claude-haiku-4.5',
      timestamp: new Date().toISOString()
    };
  }

  async initialize(): Promise<void> {
    // No-op
  }

  getProviderName(): string {
    return 'Mock Claude Haiku Provider';
  }

  estimateCost(inputSize: number): number {
    return 0.001;
  }

  async parseText(text: string, schema: object): Promise<ClaudeParseResponse> {
    if (this.shouldFail) {
      throw new Error('Mock API failure');
    }

    await new Promise(resolve => setTimeout(resolve, 100));

    return this.mockResponse;
  }

  setMockResponse(response: Partial<ClaudeParseResponse>): void {
    this.mockResponse = { ...this.mockResponse, ...response };
  }

  setShouldFail(shouldFail: boolean): void {
    this.shouldFail = shouldFail;
  }
}
```

## Firebase Emulator Test Patterns

### Starting Emulators

```bash
# In functions/ directory
npm run serve
# This runs: firebase emulators:start --only functions,firestore,storage
```

### Example Integration Test

### File: `functions/src/ai-pipeline/orchestration/layer2a-orchestrator.test.ts`

```typescript
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { layer2aOrchestrator } from './layer2a-orchestrator';
import { MockGeminiProvider } from '../../../test/mocks/gemini-provider.mock';

describe('Layer 2a Orchestrator', () => {
  let firestore: admin.firestore.Firestore;

  beforeAll(() => {
    firestore = admin.firestore();
  });

  afterEach(async () => {
    // Clean up test data
    const snapshot = await firestore.collection('items').get();
    const batch = firestore.batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });

  it('should extract attributes when new item is created', async () => {
    // Arrange: Create test item in Firestore
    const itemRef = await firestore.collection('items').add({
      user_id: 'test-user',
      photo_url: 'https://storage.googleapis.com/test/photo.jpg',
      status: 'pending',
      created_at: admin.firestore.Timestamp.now()
    });

    // Mock Gemini provider
    const mockProvider = new MockGeminiProvider();
    mockProvider.setMockResponse({
      attributes: {
        item_type: 'food',
        brand: 'Test Brand'
      }
    });

    // Act: Trigger function with mock provider
    const snapshot = await itemRef.get();
    const context = {
      params: { itemId: itemRef.id }
    };

    // Note: In real tests, we'd inject the mock provider via dependency injection
    await layer2aOrchestrator(snapshot, context);

    // Assert: Check Firestore was updated
    const updatedItem = await itemRef.get();
    const data = updatedItem.data();

    expect(data.layer2a_complete).toBe(true);
    expect(data.attributes).toEqual({
      item_type: 'food',
      brand: 'Test Brand'
    });
    expect(data.status).toBe('layer2a_complete');
  });

  it('should retry on transient errors', async () => {
    // Arrange: Create test item
    const itemRef = await firestore.collection('items').add({
      user_id: 'test-user',
      photo_url: 'https://storage.googleapis.com/test/photo.jpg',
      status: 'pending'
    });

    // Mock provider that fails first 2 times, succeeds on 3rd
    const mockProvider = new MockGeminiProvider();
    let attempts = 0;
    mockProvider.setShouldFail(true);

    // Override extractAttributes to succeed on 3rd attempt
    const originalExtract = mockProvider.extractAttributes.bind(mockProvider);
    mockProvider.extractAttributes = async (...args) => {
      attempts++;
      if (attempts < 3) {
        throw new Error('Rate limit exceeded');
      }
      mockProvider.setShouldFail(false);
      return originalExtract(...args);
    };

    // Act
    const snapshot = await itemRef.get();
    await layer2aOrchestrator(snapshot, { params: { itemId: itemRef.id } });

    // Assert: Should succeed after retries
    const updatedItem = await itemRef.get();
    expect(updatedItem.data().layer2a_complete).toBe(true);
    expect(attempts).toBe(3);
  });

  it('should move to dead letter queue after max retries', async () => {
    // Arrange: Create test item
    const itemRef = await firestore.collection('items').add({
      user_id: 'test-user',
      photo_url: 'https://storage.googleapis.com/test/photo.jpg',
      status: 'pending'
    });

    // Mock provider that always fails
    const mockProvider = new MockGeminiProvider();
    mockProvider.setShouldFail(true);

    // Act
    const snapshot = await itemRef.get();
    await layer2aOrchestrator(snapshot, { params: { itemId: itemRef.id } });

    // Assert: Should be in dead letter queue
    const failedSnapshot = await firestore
      .collection('failedItems')
      .where('item_id', '==', itemRef.id)
      .get();

    expect(failedSnapshot.empty).toBe(false);
    expect(failedSnapshot.docs[0].data().error_message).toContain('Max retries exceeded');
  });
});
```

## Test Data Fixtures

### File: `functions/test/fixtures/item-metadata.fixture.ts`

```typescript
import { Timestamp } from 'firebase-admin/firestore';

/**
 * Test fixture for item metadata at various pipeline stages
 */
export const itemFixtures = {
  /**
   * Fresh item, no processing yet
   */
  pending: {
    user_id: 'test-user-123',
    photo_url: 'https://storage.googleapis.com/test/photo.jpg',
    status: 'pending',
    created_at: Timestamp.now()
  },

  /**
   * Item after Layer 2a completion
   */
  layer2aComplete: {
    user_id: 'test-user-123',
    photo_url: 'https://storage.googleapis.com/test/photo.jpg',
    status: 'layer2a_complete',
    layer2a_complete: true,
    attributes: {
      item_type: 'food',
      brand: 'Heinz',
      size: '32 oz',
      packaging_type: 'bottle',
      barcode_detected: true
    },
    confidence_scores: {
      item_type: 0.95,
      brand: 0.90
    },
    created_at: Timestamp.now(),
    layer2a_completed_at: Timestamp.now()
  },

  /**
   * Item after Layer 2b completion
   */
  layer2bComplete: {
    user_id: 'test-user-123',
    photo_url: 'https://storage.googleapis.com/test/photo.jpg',
    status: 'layer2b_complete',
    layer2a_complete: true,
    layer2b_complete: true,
    attributes: {
      item_type: 'food',
      brand: 'Heinz',
      size: '32 oz',
      packaging_type: 'bottle',
      barcode_detected: true
    },
    serpapi_results: {
      product_name: 'Heinz Tomato Ketchup',
      price: '$4.99',
      source: 'Amazon'
    },
    barcode_results: {
      product_name: 'Heinz Tomato Ketchup',
      ingredients: ['tomatoes', 'vinegar', 'sugar'],
      nutrition: { calories: '20' }
    },
    created_at: Timestamp.now(),
    layer2a_completed_at: Timestamp.now(),
    layer2b_completed_at: Timestamp.now()
  }
};
```

## Running Tests

### Unit Tests Only

```bash
npm test -- --testPathPattern="\.test\.ts$" --testPathIgnorePatterns="orchestrator"
```

### Integration Tests Only

```bash
# Start emulators in one terminal
firebase emulators:start --only firestore,storage

# Run integration tests in another terminal
npm test -- --testPathPattern="orchestrator\.test\.ts$"
```

### All Tests with Coverage

```bash
npm run test:coverage
```

### Watch Mode (TDD)

```bash
npm run test:watch
```

## Acceptance Criteria

- ✅ Mock provider implementations for all external APIs
- ✅ Jest configuration with TypeScript support
- ✅ Firebase Emulator test patterns documented
- ✅ Example integration tests for orchestrators
- ✅ Test data fixtures for common scenarios
- ✅ Test commands documented (unit, integration, coverage)
- ✅ No real API calls in tests (all mocked)

---

**Last Updated**: 2025-11-11

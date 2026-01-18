# TEST-EXAMPLE-003: Cloud Functions Testing Patterns

**Created**: 2025-11-10
**Stage**: 3.2 - Backend Implementation Research
**References**: CODE-EXAMPLE-005, CODE-EXAMPLE-006, CODE-EXAMPLE-007, RESEARCH-VALIDATION-stage-3.2
**Status**: Complete

## Overview

Production-ready testing patterns for Cloud Functions (Node.js):

- **Jest Unit Tests**: Mock Firebase Admin SDK, test business logic
- **Supertest Integration Tests**: Test HTTP endpoints with real requests
- **Firebase Emulator**: Local testing with Firestore/Storage/Auth emulators
- **Test Pyramid**: 80% unit, 15% integration, 5% E2E

All patterns follow Given/When/Then structure for clarity.

## 1. Test Environment Setup

### package.json

```json
{
  "name": "abundance-backend",
  "version": "1.0.0",
  "engines": {
    "node": "20"
  },
  "scripts": {
    "test": "jest --coverage",
    "test:watch": "jest --watch",
    "test:integration": "firebase emulators:exec --only functions,firestore,auth 'jest --testMatch=**/*.integration.test.js'",
    "emulators": "firebase emulators:start --only functions,firestore,auth,storage"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0",
    "@google-cloud/vertexai": "^1.0.0",
    "@anthropic-ai/sdk": "^0.20.0",
    "axios": "^1.6.0",
    "express": "^4.18.0"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "supertest": "^6.3.0",
    "@firebase/rules-unit-testing": "^3.0.0"
  }
}
```

### jest.config.js

```javascript
module.exports = {
  testEnvironment: 'node',
  coveragePathIgnorePatterns: ['/node_modules/'],
  testMatch: ['**/*.test.js'],
  collectCoverageFrom: [
    'functions/**/*.js',
    '!functions/index.js',
    '!functions/node_modules/**'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
};
```

## 2. Jest Unit Tests (Mock Firebase Admin SDK)

### analyzeItem.test.js

```javascript
const admin = require('firebase-admin');
const { analyzeItem } = require('../functions/analyzeItem');

// Mock Firebase Admin SDK
jest.mock('firebase-admin', () => {
  const mockFirestore = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn(),
    set: jest.fn(),
    update: jest.fn()
  };

  const mockStorage = {
    bucket: jest.fn(() => ({
      file: jest.fn(() => ({
        getSignedUrl: jest.fn().mockResolvedValue(['https://storage.googleapis.com/test.jpg'])
      }))
    }))
  };

  const mockAuth = {
    verifyIdToken: jest.fn()
  };

  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => mockFirestore),
    storage: jest.fn(() => mockStorage),
    auth: jest.fn(() => mockAuth),
    firestore: {
      FieldValue: {
        serverTimestamp: jest.fn(() => 'MOCK_TIMESTAMP')
      }
    }
  };
});

describe('analyzeItem', () => {
  let mockFirestore;
  let mockStorage;
  let mockAuth;

  beforeEach(() => {
    jest.clearAllMocks();
    mockFirestore = admin.firestore();
    mockStorage = admin.storage();
    mockAuth = admin.auth();
  });

  describe('Given valid request with Firebase token', () => {
    it('When analyzeItem is invoked, Then creates item with status=processing', async () => {
      // Given: Valid auth token
      mockAuth.verifyIdToken.mockResolvedValue({
        uid: 'user123',
        email: 'test@example.com'
      });

      mockFirestore.get.mockResolvedValue({
        exists: true,
        data: () => ({ itemCount: 5, subscriptionTier: 'free' })
      });

      mockFirestore.set.mockResolvedValue({});

      // When: analyzeItem called
      const result = await analyzeItem({
        imageBase64: 'base64data',
        barcode: '123456789'
      }, { uid: 'user123' });

      // Then: Firestore.set() called with correct data
      expect(mockFirestore.set).toHaveBeenCalledWith({
        userId: 'user123',
        status: 'processing',
        barcode: '123456789',
        createdAt: 'MOCK_TIMESTAMP'
      });

      expect(result.success).toBe(true);
      expect(result.itemId).toBeDefined();
    });

    it('When user is over free limit, Then throws error', async () => {
      // Given: Free user with 10 items
      mockFirestore.get.mockResolvedValue({
        exists: true,
        data: () => ({ itemCount: 10, subscriptionTier: 'free' })
      });

      // When: Attempt to create item
      // Then: Throws error
      await expect(
        analyzeItem({ imageBase64: 'data' }, { uid: 'user123' })
      ).rejects.toThrow('Free tier limit reached');
    });

    it('When premium user, Then no limit check', async () => {
      // Given: Premium user with 50 items
      mockFirestore.get.mockResolvedValue({
        exists: true,
        data: () => ({ itemCount: 50, subscriptionTier: 'premium' })
      });

      mockFirestore.set.mockResolvedValue({});

      // When: Create item
      const result = await analyzeItem(
        { imageBase64: 'data' },
        { uid: 'premium-user', premium: true }
      );

      // Then: Item created successfully
      expect(result.success).toBe(true);
    });
  });

  describe('Given invalid input', () => {
    it('When imageBase64 missing, Then throws validation error', async () => {
      // Given: No image data
      // When: analyzeItem called
      // Then: Throws error
      await expect(
        analyzeItem({}, { uid: 'user123' })
      ).rejects.toThrow('imageBase64 required');
    });

    it('When barcode invalid format, Then throws validation error', async () => {
      // Given: Invalid barcode
      // When: analyzeItem called with invalid barcode
      // Then: Throws error
      await expect(
        analyzeItem({ imageBase64: 'data', barcode: 'abc' }, { uid: 'user123' })
      ).rejects.toThrow('Invalid barcode format');
    });
  });
});
```

### aiPipeline.test.js

```javascript
const { extractAttributesGemini, synthesizeMetadata } = require('../functions/aiPipeline');
const { VertexAI } = require('@google-cloud/vertexai');
const Anthropic = require('@anthropic-ai/sdk');

// Mock AI SDKs
jest.mock('@google-cloud/vertexai');
jest.mock('@anthropic-ai/sdk');

describe('AI Pipeline', () => {
  describe('extractAttributesGemini', () => {
    it('Given valid image URL, When extracting attributes, Then returns JSON', async () => {
      // Given: Mock Gemini response
      const mockModel = {
        generateContent: jest.fn().mockResolvedValue({
          response: {
            candidates: [{
              content: {
                parts: [{
                  text: JSON.stringify({
                    name: 'iPhone 13',
                    brand: 'Apple',
                    category: 'Electronics',
                    color: 'Blue',
                    condition: 'good',
                    confidence: 0.92
                  })
                }]
              }
            }]
          }
        })
      };

      VertexAI.mockImplementation(() => ({
        preview: {
          getGenerativeModel: jest.fn(() => mockModel)
        }
      }));

      // When: Extract attributes
      const result = await extractAttributesGemini('https://storage.example.com/test.jpg');

      // Then: Returns parsed JSON
      expect(result.name).toBe('iPhone 13');
      expect(result.brand).toBe('Apple');
      expect(result.confidence).toBe(0.92);
      expect(mockModel.generateContent).toHaveBeenCalledTimes(1);
    });

    it('Given Gemini API error, When retrying, Then succeeds after backoff', async () => {
      // Given: Gemini fails twice, succeeds third time
      const mockModel = {
        generateContent: jest.fn()
          .mockRejectedValueOnce(new Error('Rate limit'))
          .mockRejectedValueOnce(new Error('Rate limit'))
          .mockResolvedValueOnce({
            response: {
              candidates: [{
                content: {
                  parts: [{ text: JSON.stringify({ name: 'Test', confidence: 0.8 }) }]
                }
              }]
            }
          })
      };

      VertexAI.mockImplementation(() => ({
        preview: {
          getGenerativeModel: jest.fn(() => mockModel)
        }
      }));

      // When: Extract with retry
      const result = await extractAttributesGemini('https://example.com/test.jpg');

      // Then: Succeeds after 2 retries
      expect(result.name).toBe('Test');
      expect(mockModel.generateContent).toHaveBeenCalledTimes(3);
    });
  });

  describe('synthesizeMetadata', () => {
    it('Given Layer 2a + 2b results, When synthesizing, Then merges data', async () => {
      // Given: Mock Claude response
      const mockAnthropic = {
        messages: {
          create: jest.fn().mockResolvedValue({
            content: [{
              text: JSON.stringify({
                name: 'iPhone 13 Pro',
                brand: 'Apple',
                model: 'A2483',
                category: 'Electronics',
                estimatedValue: 800,
                confidence: 0.95,
                conflictsResolved: ['Brand matched between sources'],
                reasoning: 'Combined Gemini attributes with product search data'
              })
            }],
            usage: {
              input_tokens: 500,
              output_tokens: 200
            }
          })
        }
      };

      Anthropic.mockImplementation(() => mockAnthropic);

      const layer2aResults = {
        name: 'iPhone',
        brand: 'Apple',
        category: 'Electronics'
      };

      const layer2bResults = {
        productName: 'iPhone 13 Pro',
        model: 'A2483'
      };

      // When: Synthesize
      const result = await synthesizeMetadata(layer2aResults, layer2bResults);

      // Then: Returns merged metadata
      expect(result.name).toBe('iPhone 13 Pro');
      expect(result.estimatedValue).toBe(800);
      expect(result.confidence).toBe(0.95);
      expect(mockAnthropic.messages.create).toHaveBeenCalledTimes(1);
    });
  });
});
```

### firestoreQueries.test.js

```javascript
const admin = require('firebase-admin');
const { getUserItemsLatest, getItemsPaginated } = require('../functions/firestoreQueries');

jest.mock('firebase-admin');

describe('Firestore Queries', () => {
  let mockFirestore;

  beforeEach(() => {
    jest.clearAllMocks();

    const mockDocs = [
      { id: 'item1', data: () => ({ name: 'Item 1', createdAt: new Date() }) },
      { id: 'item2', data: () => ({ name: 'Item 2', createdAt: new Date() }) }
    ];

    mockFirestore = {
      collection: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      startAfter: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({ docs: mockDocs })
    };

    admin.firestore.mockReturnValue(mockFirestore);
  });

  describe('getUserItemsLatest', () => {
    it('Given userId, When fetching items, Then returns sorted array', async () => {
      // Given: User with items
      const userId = 'user123';

      // When: Fetch latest items
      const result = await getUserItemsLatest(userId, 20);

      // Then: Returns array with IDs
      expect(result).toHaveLength(2);
      expect(result[0].id).toBe('item1');
      expect(mockFirestore.where).toHaveBeenCalledWith('userId', '==', userId);
      expect(mockFirestore.orderBy).toHaveBeenCalledWith('createdAt', 'desc');
      expect(mockFirestore.limit).toHaveBeenCalledWith(20);
    });
  });

  describe('getItemsPaginated', () => {
    it('Given cursor, When paginating, Then uses startAfter', async () => {
      // Given: Last document from previous page
      const lastDoc = { id: 'item10' };

      // When: Fetch next page
      await getItemsPaginated('user123', lastDoc, 20);

      // Then: Query uses startAfter
      expect(mockFirestore.startAfter).toHaveBeenCalledWith(lastDoc);
      expect(mockFirestore.limit).toHaveBeenCalledWith(20);
    });
  });
});
```

## 3. Supertest Integration Tests (HTTP Endpoints)

### api.integration.test.js

```javascript
const request = require('supertest');
const admin = require('firebase-admin');
const { app } = require('../functions/index');

// Initialize Firebase Admin SDK for testing
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'abundance-test'
  });
}

describe('API Integration Tests', () => {
  let authToken;
  let testUserId;

  beforeAll(async () => {
    // Create test user
    const userRecord = await admin.auth().createUser({
      email: 'test@example.com',
      password: 'testpassword123'
    });
    testUserId = userRecord.uid;

    // Generate custom token
    authToken = await admin.auth().createCustomToken(testUserId);
  });

  afterAll(async () => {
    // Cleanup test user
    await admin.auth().deleteUser(testUserId);
  });

  describe('POST /analyzeItem', () => {
    it('Given valid auth token, When creating item, Then returns 200', async () => {
      // Given: Valid request
      const requestData = {
        imageBase64: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        barcode: '123456789012'
      };

      // When: POST request
      const response = await request(app)
        .post('/analyzeItem')
        .set('Authorization', `Bearer ${authToken}`)
        .send(requestData);

      // Then: Success response
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.itemId).toBeDefined();
    });

    it('Given missing auth token, When creating item, Then returns 401', async () => {
      // Given: No auth token
      // When: POST request without Authorization header
      const response = await request(app)
        .post('/analyzeItem')
        .send({ imageBase64: 'data' });

      // Then: Unauthorized
      expect(response.status).toBe(401);
      expect(response.body.error).toBe('Unauthorized');
    });

    it('Given invalid image data, When creating item, Then returns 400', async () => {
      // Given: Invalid base64
      // When: POST request with bad data
      const response = await request(app)
        .post('/analyzeItem')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ imageBase64: 'not-base64!' });

      // Then: Bad request
      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Invalid image data');
    });
  });

  describe('GET /items', () => {
    it('Given user with items, When listing, Then returns paginated results', async () => {
      // Given: Create 3 test items
      await Promise.all([
        createTestItem(testUserId, 'Item 1'),
        createTestItem(testUserId, 'Item 2'),
        createTestItem(testUserId, 'Item 3')
      ]);

      // When: GET request
      const response = await request(app)
        .get('/items?pageSize=2')
        .set('Authorization', `Bearer ${authToken}`);

      // Then: Returns 2 items with nextCursor
      expect(response.status).toBe(200);
      expect(response.body.items).toHaveLength(2);
      expect(response.body.nextCursor).toBeDefined();
      expect(response.body.hasMore).toBe(true);
    });
  });

  describe('DELETE /items/:itemId', () => {
    it('Given user owns item, When deleting, Then returns 200', async () => {
      // Given: Create test item
      const itemId = await createTestItem(testUserId, 'Test Item');

      // When: DELETE request
      const response = await request(app)
        .delete(`/items/${itemId}`)
        .set('Authorization', `Bearer ${authToken}`);

      // Then: Success
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify item deleted from Firestore
      const itemDoc = await admin.firestore().collection('items').doc(itemId).get();
      expect(itemDoc.exists).toBe(false);
    });

    it('Given user does not own item, When deleting, Then returns 403', async () => {
      // Given: Item owned by another user
      const otherUserId = 'other-user-123';
      const itemId = await createTestItem(otherUserId, 'Other User Item');

      // When: DELETE request
      const response = await request(app)
        .delete(`/items/${itemId}`)
        .set('Authorization', `Bearer ${authToken}`);

      // Then: Forbidden
      expect(response.status).toBe(403);
      expect(response.body.error).toContain('Unauthorized');
    });
  });
});

// Helper: Create test item
async function createTestItem(userId, name) {
  const itemRef = admin.firestore().collection('items').doc();
  await itemRef.set({
    userId,
    name,
    status: 'complete',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  return itemRef.id;
}
```

## 4. Firebase Emulator Tests

### emulator.test.js

```javascript
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const fs = require('fs');

describe('Firebase Emulator Tests', () => {
  let testEnv;
  let authenticatedContext;
  let unauthenticatedContext;

  beforeAll(async () => {
    // Initialize test environment
    testEnv = await initializeTestEnvironment({
      projectId: 'abundance-test',
      firestore: {
        rules: fs.readFileSync('firestore.rules', 'utf8'),
        host: 'localhost',
        port: 8080
      },
      storage: {
        rules: fs.readFileSync('storage.rules', 'utf8'),
        host: 'localhost',
        port: 9199
      }
    });

    authenticatedContext = testEnv.authenticatedContext('user123');
    unauthenticatedContext = testEnv.unauthenticatedContext();
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  describe('Firestore Security Rules', () => {
    it('Given authenticated user, When reading own items, Then succeeds', async () => {
      // Given: Item owned by user123
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('items').doc('item1').set({
          userId: 'user123',
          name: 'Test Item'
        });
      });

      // When: User reads own item
      const itemRef = authenticatedContext.firestore().collection('items').doc('item1');

      // Then: Read succeeds
      await assertSucceeds(itemRef.get());
    });

    it('Given authenticated user, When reading other user items, Then fails', async () => {
      // Given: Item owned by user456
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('items').doc('item2').set({
          userId: 'user456',
          name: 'Other User Item'
        });
      });

      // When: user123 tries to read user456's item
      const itemRef = authenticatedContext.firestore().collection('items').doc('item2');

      // Then: Read fails
      await assertFails(itemRef.get());
    });

    it('Given unauthenticated user, When reading items, Then fails', async () => {
      // Given: Public item
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('items').doc('item3').set({
          userId: 'user123',
          name: 'Item'
        });
      });

      // When: Unauthenticated user reads
      const itemRef = unauthenticatedContext.firestore().collection('items').doc('item3');

      // Then: Read fails
      await assertFails(itemRef.get());
    });

    it('Given authenticated user, When creating item, Then sets userId', async () => {
      // Given: Authenticated as user123
      // When: Create item
      const itemRef = authenticatedContext.firestore().collection('items').doc('new-item');

      // Then: Create succeeds only if userId matches auth
      await assertSucceeds(itemRef.set({
        userId: 'user123',
        name: 'New Item',
        status: 'processing'
      }));

      await assertFails(itemRef.set({
        userId: 'other-user',
        name: 'Fake Item'
      }));
    });
  });

  describe('Storage Security Rules', () => {
    it('Given authenticated user, When uploading to own folder, Then succeeds', async () => {
      // Given: Authenticated as user123
      // When: Upload to items/user123/
      const fileRef = authenticatedContext.storage().ref('items/user123/test.jpg');

      // Then: Upload succeeds
      await assertSucceeds(fileRef.put(Buffer.from('test-image-data')));
    });

    it('Given authenticated user, When uploading to other folder, Then fails', async () => {
      // Given: Authenticated as user123
      // When: Upload to items/user456/
      const fileRef = authenticatedContext.storage().ref('items/user456/test.jpg');

      // Then: Upload fails
      await assertFails(fileRef.put(Buffer.from('test-image-data')));
    });
  });
});
```

## 5. Test Execution Scripts

### Run All Tests

```bash
# Unit tests (fast, mock dependencies)
npm test

# Watch mode (during development)
npm run test:watch

# Integration tests (Firebase Emulator required)
npm run test:integration

# Full test suite with coverage
npm test -- --coverage
```

### Firebase Emulator Workflow

```bash
# Terminal 1: Start emulators
firebase emulators:start --only functions,firestore,auth,storage

# Terminal 2: Run integration tests
npm run test:integration

# Or use emulators:exec (auto start/stop)
firebase emulators:exec --only functions,firestore 'npm test'
```

## 6. Coverage Reports

### View Coverage in Terminal

```bash
npm test -- --coverage

# Example output:
# ----------------------------|---------|----------|---------|---------|
# File                        | % Stmts | % Branch | % Funcs | % Lines |
# ----------------------------|---------|----------|---------|---------|
# All files                   |   85.2  |   80.5   |   88.1  |   85.0  |
#  analyzeItem.js             |   90.0  |   85.0   |   95.0  |   90.2  |
#  aiPipeline.js              |   82.5  |   78.0   |   85.5  |   82.1  |
#  firestoreQueries.js        |   88.0  |   82.0   |   90.0  |   87.8  |
# ----------------------------|---------|----------|---------|---------|
```

### HTML Coverage Report

```bash
npm test -- --coverage --coverageReporters=html

# Open coverage/index.html in browser
open coverage/index.html
```

## Cross-References

- **CODE-EXAMPLE-005**: See Cloud Functions being tested
- **CODE-EXAMPLE-006**: See Firestore queries being tested
- **CODE-EXAMPLE-007**: See AI pipeline being tested
- **CODE-EXAMPLE-008**: See Firebase Admin SDK being tested
- **INFRASTRUCTURE-001**: See CI/CD integration with tests

## Notes

- Test pyramid: 80% unit (fast, isolated), 15% integration (real dependencies), 5% E2E
- All tests use Given/When/Then structure for clarity
- Mock Firebase Admin SDK in unit tests (jest.mock)
- Use Firebase Emulator for integration tests (real Firestore/Auth/Storage)
- Supertest for HTTP endpoint testing (no server startup required)
- Jest coverage threshold: 80% (enforced in jest.config.js)
- Run tests before every commit (git pre-commit hook)
- CI/CD pipeline runs full test suite + linting

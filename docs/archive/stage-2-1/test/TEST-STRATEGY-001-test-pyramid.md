# TEST-STRATEGY-001: Test Pyramid and Strategy

**Document ID:** TEST-STRATEGY-001
**Date:** 2025-10-24 (Original), 2025-11-01 (Stage 2.1 Update)
**Status:** APPROVED
**Related Documents:**
- TECH-STACK-001 (Technology Stack Map)
- API-CONTRACTS-001 (Service Interface Definitions)
- ADR-014 (Multi-Layer AI Pipeline Architecture)
- ADR-015 (Gemini 2.5 Flash-Lite for Attribute Extraction)
- ADR-016 (SerpAPI + Claude Haiku for Product Search)
- ADR-017 (Claude Sonnet 4.5 for AI Synthesis)
- DESIGN-004 (Backend AI Pipeline Design)
- DESIGN-005 (iOS Vision Integration Design)
- SCHEMA-001 (Core Data Schemas)

---

## Executive Summary

This document defines the testing strategy for Abundance MVP Phase 1, following the test pyramid pattern:
- **70% Unit Tests:** Fast, isolated, test business logic across all layers
- **20% Integration Tests:** Test API contracts, Firestore, 4-layer AI pipeline (Layer 1: Vision, Layer 2a: Gemini, Layer 2b: SerpAPI, Layer 3: Claude)
- **10% E2E Tests:** Critical user flows (iOS app → backend → multi-layer AI)

**Key Testing Principles:**
1. **Test behavior, not implementation**
2. **Fast feedback loop** (unit tests run in <1 sec)
3. **Mock external dependencies** (Vertex AI, SerpAPI, Claude API, Firestore) for unit tests
4. **Real dependencies** for integration tests (staging environment)
5. **Layer-specific testing** for each AI layer in the pipeline

---

## Test Pyramid

```
                    ▲
                   / \
                  /   \
                 /     \
                / E2E   \  (10%) - Critical user flows
               /_________\
              /           \
             / Integration \  (20%) - API contracts, Multi-layer AI pipeline
            /_______________\
           /                 \
          /   Unit Tests      \  (70%) - Business logic, pure functions
         /____________________\
```

### Test Distribution

| Test Type | Percentage | Count (Estimated) | Execution Time |
|-----------|------------|-------------------|----------------|
| **Unit Tests** | 70% | ~300 tests | <5 sec total |
| **Integration Tests** | 20% | ~100 tests | 30-60 sec total |
| **E2E Tests** | 10% | ~30 tests | 5-8 min total |
| **Total** | 100% | ~430 tests | <9 min total |

---

## 1. UNIT TESTS (70%)

### 1.1 iOS Unit Tests (Swift)

**Framework:** XCTest (native iOS testing framework)

**Scope:**
- ViewModel logic (MVVM pattern)
- Pure functions (data transformation, validation)
- Core ML YOLOv3-Tiny mocks (simulate object detection)
- Bounding box coordinate conversion
- Image cropping logic for Layer 2 inputs

**Example: Item Cataloging Logic**

```swift
import XCTest
import CoreML
import Vision
@testable import Abundance

class ItemCatalogingTests: XCTestCase {

    func testYOLOv3TinyObjectDetection() {
        // Given: Core ML YOLOv3-Tiny model detected "scissors"
        let mockPrediction = MockVNCoreMLFeatureValueObservation(
            identifier: "scissors",
            confidence: 0.92,
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5)
        )

        // When: Process YOLOv3 detection
        let detection = VisionService.processDetection(mockPrediction)

        // Then: Detection has correct properties
        XCTAssertEqual(detection.label, "scissors")
        XCTAssertEqual(detection.confidence, 0.92)
        XCTAssertEqual(detection.boundingBox.origin.x, 0.2, accuracy: 0.01)
    }

    func testBoundingBoxCoordinateConversion() {
        // Given: YOLOv3 normalized coordinates (0.0-1.0)
        let normalizedBox = CGRect(x: 0.3, y: 0.4, width: 0.2, height: 0.3)
        let imageSize = CGSize(width: 1920, height: 1080)

        // When: Convert to pixel coordinates
        let pixelBox = VisionService.convertToPixelCoordinates(
            normalizedBox: normalizedBox,
            imageSize: imageSize
        )

        // Then: Pixel coordinates are correct
        XCTAssertEqual(pixelBox.origin.x, 576, accuracy: 1)  // 0.3 * 1920
        XCTAssertEqual(pixelBox.origin.y, 432, accuracy: 1)  // 0.4 * 1080
        XCTAssertEqual(pixelBox.width, 384, accuracy: 1)     // 0.2 * 1920
        XCTAssertEqual(pixelBox.height, 324, accuracy: 1)    // 0.3 * 1080
    }

    func testImageCroppingForLayer2() {
        // Given: Full-size image and bounding box
        let image = UIImage(named: "test_scissors.jpg")!
        let boundingBox = CGRect(x: 100, y: 150, width: 400, height: 300)

        // When: Crop image to bounding box
        let croppedImage = VisionService.cropImage(image, to: boundingBox)

        // Then: Cropped image has correct dimensions
        XCTAssertEqual(croppedImage?.size.width, 400, accuracy: 1)
        XCTAssertEqual(croppedImage?.size.height, 300, accuracy: 1)
    }

    func testConfidenceThreshold() {
        // Given: Low confidence detection
        let mockPrediction = MockVNCoreMLFeatureValueObservation(
            identifier: "unknown",
            confidence: 0.65,
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)
        )

        // When: Filter by confidence threshold
        let shouldProcess = VisionService.meetsConfidenceThreshold(mockPrediction)

        // Then: Detection is rejected (confidence < 0.7)
        XCTAssertFalse(shouldProcess)
    }

    func testCategoryInference() {
        // Given: Basic label "scissors"
        let item = Item(name: "scissors", tier: .free)

        // When: Infer category
        let category = CategoryService.inferCategory(for: item)

        // Then: Correct category assigned
        XCTAssertEqual(category, "Office Supplies")
    }
}
```

---

### 1.2 Backend Unit Tests (Node.js)

**Framework:** Jest (JavaScript testing framework)

**Scope:**
- Cloud Function business logic (no Firestore/AI API calls)
- Error handling (timeout, rate limit, 5xx errors)
- Retry logic (should retry or not?)
- Layer 2a: Gemini attribute extraction parsing
- Layer 2b: SerpAPI + Claude Haiku parsing
- Layer 3: Claude Sonnet conflict resolution

**Example: Layer 2b Parsing Logic**

```javascript
// layer2b.test.js
const { parseClaudeHaikuResponse } = require('../functions/layer2b');
const { mockSerpAPI, mockClaudeHaiku } = require('./mocks');

describe('Layer 2b: SerpAPI + Claude Haiku Parsing', () => {

    test('should parse Claude Haiku brand/model extraction', async () => {
        // Given: Mock Claude Haiku response
        const mockResponse = {
            content: [{
                type: 'text',
                text: JSON.stringify({
                    brand: 'Fiskars',
                    model: '8-Inch Fabric Scissors',
                    confidence: 0.88
                })
            }]
        };

        // When: Parse response
        const result = parseClaudeHaikuResponse(mockResponse);

        // Then: Returns extracted brand/model
        expect(result.brand).toBe('Fiskars');
        expect(result.model).toBe('8-Inch Fabric Scissors');
        expect(result.confidence).toBe(0.88);
    });

    test('should calculate average price from SerpAPI results', async () => {
        // Given: SerpAPI returned 5 shopping results
        const serpResults = [
            { price: 12.99, source: 'Amazon' },
            { price: 14.99, source: 'Walmart' },
            { price: 11.99, source: 'Target' },
            { price: 13.49, source: 'eBay' },
            { price: 12.49, source: 'Etsy' }
        ];

        // When: Calculate average price
        const avgPrice = calculateAveragePrice(serpResults);

        // Then: Average is correct
        expect(avgPrice).toBeCloseTo(13.19, 2);  // (12.99+14.99+11.99+13.49+12.49)/5
    });

    test('should handle SerpAPI rate limit (429)', async () => {
        // Given: SerpAPI returns 429 error
        mockSerpAPI.mockRejectedValue({
            statusCode: 429,
            message: 'Rate limit exceeded'
        });

        // When: Call Layer 2b
        const result = await runLayer2b({
            itemId: 'item_abc123',
            croppedImageUrl: 'gs://test/image.jpg'
        });

        // Then: Returns retry info
        expect(result.success).toBe(false);
        expect(result.error.code).toBe('SERPAPI_RATE_LIMIT');
        expect(result.retryAfter).toBeGreaterThan(0);
    });

    test('should enqueue Redis job for async processing', async () => {
        // Given: Layer 2b request
        const jobData = {
            itemId: 'item_abc123',
            cdnUrl: 'https://cdn.abundance.app/images/test.jpg'
        };

        // When: Enqueue job
        const jobId = await redisQueue.enqueue('layer2b', jobData);

        // Then: Job is queued
        expect(jobId).toBeDefined();
        expect(jobId).toMatch(/^job_/);
    });

    test('should not retry when image upload to GCS fails', async () => {
        // Given: Invalid GCS path
        const result = await uploadToGCS({
            imagePath: '/tmp/invalid.jpg'
        });

        // Then: Returns error, no retry scheduled
        expect(result.success).toBe(false);
        expect(result.error.code).toBe('GCS_UPLOAD_FAILED');
    });
});
```

---

### 1.2.1 Layer 2a Unit Tests (Gemini 2.5 Flash-Lite)

**Framework:** Jest + Mock Vertex AI API

**Scope:**
- JSON schema validation (ensure Gemini response matches expected schema)
- Attribute extraction (condition, color, material, brand_visibility)
- Confidence scoring (validate confidence ranges)
- Error handling (malformed JSON, missing fields)

**Example: Gemini Attribute Extraction**

```javascript
// layer2a.test.js
const { parseGeminiResponse, validateGeminiSchema } = require('../functions/layer2a');
const { mockVertexAI } = require('./mocks');

describe('Layer 2a: Gemini 2.5 Flash-Lite Attribute Extraction', () => {

    test('should extract attributes from Gemini response', async () => {
        // Given: Mock Gemini response
        const mockResponse = {
            candidates: [{
                content: {
                    parts: [{
                        text: JSON.stringify({
                            condition: 'good',
                            condition_confidence: 0.92,
                            color: 'blue',
                            color_confidence: 0.88,
                            material: 'metal',
                            material_confidence: 0.85,
                            brand_visibility: 'visible',
                            brand_visibility_confidence: 0.90
                        })
                    }]
                }
            }]
        };

        // When: Parse Gemini response
        const result = parseGeminiResponse(mockResponse);

        // Then: Attributes extracted correctly
        expect(result.condition).toBe('good');
        expect(result.condition_confidence).toBe(0.92);
        expect(result.color).toBe('blue');
        expect(result.material).toBe('metal');
        expect(result.brand_visibility).toBe('visible');
    });

    test('should validate Gemini JSON schema', () => {
        // Given: Valid Gemini response
        const validResponse = {
            condition: 'excellent',
            condition_confidence: 0.95,
            color: 'red',
            color_confidence: 0.89
        };

        // When: Validate schema
        const isValid = validateGeminiSchema(validResponse);

        // Then: Schema is valid
        expect(isValid).toBe(true);
    });

    test('should reject invalid Gemini schema', () => {
        // Given: Invalid Gemini response (missing confidence fields)
        const invalidResponse = {
            condition: 'good',
            color: 'blue'
            // Missing confidence fields
        };

        // When: Validate schema
        const isValid = validateGeminiSchema(invalidResponse);

        // Then: Schema is invalid
        expect(isValid).toBe(false);
    });

    test('should handle Gemini API timeout', async () => {
        // Given: Vertex AI API timeout
        mockVertexAI.mockRejectedValue({
            code: 'DEADLINE_EXCEEDED',
            message: 'Request timeout'
        });

        // When: Call Layer 2a
        const result = await runLayer2a({
            itemId: 'item_abc123',
            croppedImageUrl: 'gs://test/image.jpg'
        });

        // Then: Returns timeout error
        expect(result.success).toBe(false);
        expect(result.error.code).toBe('GEMINI_TIMEOUT');
    });

    test('should validate condition values', () => {
        // Given: Valid condition values
        const validConditions = ['excellent', 'good', 'fair', 'poor'];

        // When: Validate each
        validConditions.forEach(condition => {
            const isValid = validateCondition(condition);
            // Then: All valid
            expect(isValid).toBe(true);
        });

        // Invalid condition
        const isValid = validateCondition('amazing');
        expect(isValid).toBe(false);
    });
});
```

---

### 1.2.2 Layer 2b Unit Tests (SerpAPI + Claude Haiku)

**Framework:** Jest + Mock SerpAPI + Mock Anthropic API

**Scope:**
- GCS upload and CDN URL generation
- Redis queue enqueue/dequeue
- SerpAPI response parsing (extract products, prices)
- Claude Haiku brand/model extraction
- Price averaging logic
- Error handling (SerpAPI rate limits, Claude API failures)

**Example: SerpAPI + Claude Haiku Integration**

```javascript
// layer2b.test.js
const { processSerpAPIResults, extractBrandModel } = require('../functions/layer2b');
const { mockSerpAPI, mockClaudeHaiku } = require('./mocks');

describe('Layer 2b: SerpAPI + Claude Haiku Product Search', () => {

    test('should generate CDN URL from GCS path', async () => {
        // Given: GCS path
        const gcsPath = 'gs://abundance-items/cropped/item_abc123.jpg';

        // When: Generate CDN URL
        const cdnUrl = await generateCDNUrl(gcsPath);

        // Then: CDN URL is correct
        expect(cdnUrl).toBe('https://cdn.abundance.app/cropped/item_abc123.jpg');
    });

    test('should enqueue Redis job for Layer 2b processing', async () => {
        // Given: Job data
        const jobData = {
            itemId: 'item_abc123',
            cdnUrl: 'https://cdn.abundance.app/cropped/item_abc123.jpg',
            basicLabel: 'scissors'
        };

        // When: Enqueue job
        const jobId = await redisQueue.enqueue('layer2b', jobData);

        // Then: Job ID is returned
        expect(jobId).toMatch(/^job_/);
    });

    test('should dequeue and process Redis job', async () => {
        // Given: Job in queue
        const jobId = await redisQueue.enqueue('layer2b', {
            itemId: 'item_abc123',
            cdnUrl: 'https://cdn.abundance.app/test.jpg'
        });

        // When: Dequeue job
        const job = await redisQueue.dequeue('layer2b');

        // Then: Job data is correct
        expect(job.id).toBe(jobId);
        expect(job.data.itemId).toBe('item_abc123');
    });

    test('should parse SerpAPI shopping results', async () => {
        // Given: Mock SerpAPI response
        const mockSerpResponse = {
            shopping_results: [
                { title: 'Fiskars Scissors', price: '$12.99', source: 'Amazon' },
                { title: 'Fiskars Fabric Scissors 8"', price: '$14.99', source: 'Walmart' },
                { title: 'Fiskars Premium Scissors', price: '$11.99', source: 'Target' }
            ]
        };

        // When: Parse results
        const results = processSerpAPIResults(mockSerpResponse);

        // Then: Results extracted correctly
        expect(results).toHaveLength(3);
        expect(results[0].title).toBe('Fiskars Scissors');
        expect(results[0].price).toBe(12.99);
        expect(results[0].source).toBe('Amazon');
    });

    test('should extract brand/model from Claude Haiku', async () => {
        // Given: Mock Claude Haiku response
        mockClaudeHaiku.mockResolvedValue({
            content: [{
                type: 'text',
                text: JSON.stringify({
                    brand: 'Fiskars',
                    model: '8-Inch Fabric Scissors',
                    confidence: 0.91
                })
            }]
        });

        // When: Extract brand/model
        const result = await extractBrandModel({
            serpResults: [
                { title: 'Fiskars Scissors', price: 12.99 },
                { title: 'Fiskars Fabric Scissors 8"', price: 14.99 }
            ]
        });

        // Then: Brand/model extracted
        expect(result.brand).toBe('Fiskars');
        expect(result.model).toBe('8-Inch Fabric Scissors');
        expect(result.confidence).toBe(0.91);
    });

    test('should calculate average price from shopping results', () => {
        // Given: Shopping results with prices
        const results = [
            { price: 12.99 },
            { price: 14.99 },
            { price: 11.99 },
            { price: 13.49 }
        ];

        // When: Calculate average
        const avgPrice = calculateAveragePrice(results);

        // Then: Average is correct
        expect(avgPrice).toBeCloseTo(13.37, 2);
    });

    test('should handle missing prices in shopping results', () => {
        // Given: Shopping results with some missing prices
        const results = [
            { price: 12.99 },
            { price: null },
            { price: 14.99 },
            { price: undefined }
        ];

        // When: Calculate average (ignore null/undefined)
        const avgPrice = calculateAveragePrice(results);

        // Then: Average only includes valid prices
        expect(avgPrice).toBeCloseTo(13.99, 2);  // (12.99 + 14.99) / 2
    });
});
```

---

### 1.2.3 Layer 3 Unit Tests (Claude Sonnet 4.5)

**Framework:** Jest + Mock Anthropic Batch API

**Scope:**
- Conflict resolution (Layer 2a vs Layer 2b mismatch)
- Confidence aggregation (combine Layer 2a + 2b confidences)
- Action determination (save, request_photo, manual_review)
- Reasoning generation (explain decision)
- Error handling (Claude API failures, batch processing errors)

**Example: Claude Sonnet Conflict Resolution**

```javascript
// layer3.test.js
const { resolveConflicts, determineAction, aggregateConfidence } = require('../functions/layer3');
const { mockClaudeSonnet } = require('./mocks');

describe('Layer 3: Claude Sonnet 4.5 AI Synthesis', () => {

    test('should resolve conflict between Layer 2a and 2b', async () => {
        // Given: Conflicting data from Layer 2a and 2b
        const layer2aData = {
            condition: 'good',
            color: 'blue',
            brand_visibility: 'visible'
        };
        const layer2bData = {
            brand: 'Fiskars',
            model: '8-Inch Fabric Scissors',
            avgPrice: 13.99
        };

        // Mock Claude Sonnet response
        mockClaudeSonnet.mockResolvedValue({
            content: [{
                type: 'text',
                text: JSON.stringify({
                    final_condition: 'good',
                    final_color: 'blue',
                    final_brand: 'Fiskars',
                    final_model: '8-Inch Fabric Scissors',
                    action: 'save',
                    reasoning: 'High confidence from both layers. Layer 2a and 2b agree on visible brand.'
                })
            }]
        });

        // When: Resolve conflicts
        const result = await resolveConflicts(layer2aData, layer2bData);

        // Then: Conflicts resolved
        expect(result.final_brand).toBe('Fiskars');
        expect(result.final_condition).toBe('good');
        expect(result.action).toBe('save');
    });

    test('should determine action: save', () => {
        // Given: High confidence from both layers
        const layer2aConfidence = 0.92;
        const layer2bConfidence = 0.88;

        // When: Determine action
        const action = determineAction(layer2aConfidence, layer2bConfidence);

        // Then: Action is save
        expect(action).toBe('save');
    });

    test('should determine action: request_photo', () => {
        // Given: Low brand visibility, low Layer 2b confidence
        const layer2aData = { brand_visibility: 'not_visible' };
        const layer2bConfidence = 0.65;

        // When: Determine action
        const action = determineAction(layer2aData, layer2bConfidence);

        // Then: Action is request_photo
        expect(action).toBe('request_photo');
    });

    test('should determine action: manual_review', () => {
        // Given: Conflicting data, medium confidence
        const layer2aData = { condition: 'good', brand_visibility: 'visible' };
        const layer2bData = { brand: null, confidence: 0.60 };

        // When: Determine action
        const action = determineAction(layer2aData, layer2bData);

        // Then: Action is manual_review
        expect(action).toBe('manual_review');
    });

    test('should aggregate confidence scores', () => {
        // Given: Layer 2a and 2b confidence scores
        const layer2aConfidence = 0.92;
        const layer2bConfidence = 0.88;

        // When: Aggregate confidence (weighted average)
        const aggregated = aggregateConfidence(layer2aConfidence, layer2bConfidence);

        // Then: Aggregated confidence is correct
        expect(aggregated).toBeCloseTo(0.90, 2);  // (0.92 + 0.88) / 2
    });

    test('should generate reasoning for decision', async () => {
        // Given: High confidence from both layers
        const layer2aData = { condition: 'excellent', brand_visibility: 'visible' };
        const layer2bData = { brand: 'Fiskars', confidence: 0.91 };

        // When: Generate reasoning
        const reasoning = await generateReasoning(layer2aData, layer2bData);

        // Then: Reasoning is present
        expect(reasoning).toBeDefined();
        expect(reasoning).toContain('High confidence');
    });

    test('should handle Claude Batch API failure', async () => {
        // Given: Claude Batch API fails
        mockClaudeSonnet.mockRejectedValue({
            error: {
                type: 'api_error',
                message: 'Batch processing failed'
            }
        });

        // When: Call Layer 3
        const result = await runLayer3({
            layer2aData: {},
            layer2bData: {}
        });

        // Then: Returns error
        expect(result.success).toBe(false);
        expect(result.error.code).toBe('CLAUDE_BATCH_FAILED');
    });

    test('should validate Layer 3 output schema', () => {
        // Given: Valid Layer 3 output
        const output = {
            final_condition: 'good',
            final_color: 'blue',
            final_brand: 'Fiskars',
            final_model: '8-Inch Scissors',
            action: 'save',
            reasoning: 'High confidence from both layers.'
        };

        // When: Validate schema
        const isValid = validateLayer3Schema(output);

        // Then: Schema is valid
        expect(isValid).toBe(true);
    });
});
```

---

### 1.3 Test Coverage Targets

| Module | Target Coverage | Critical Paths |
|--------|----------------|----------------|
| **iOS ViewModels** | >80% | Item cataloging, YOLOv3 detection, image cropping |
| **Layer 2a (Gemini)** | >90% | Attribute extraction, JSON validation |
| **Layer 2b (SerpAPI + Haiku)** | >90% | Brand/model extraction, price averaging |
| **Layer 3 (Sonnet)** | >95% | Conflict resolution, action determination |
| **Cloud Functions** | >90% | Pipeline orchestration, retry logic |
| **Utility Functions** | >95% | Category inference, validation |

**Coverage Tool:**
- iOS: Xcode Code Coverage
- Backend: Jest Coverage (`jest --coverage`)

---

## 2. INTEGRATION TESTS (20%)

### 2.1 API Contract Tests

**Framework:** Swift (iOS) + Firebase Emulator Suite (backend)

**Scope:**
- Cloud Function APIs (enrichItem)
- Firestore read/write operations
- Firebase Storage upload/download

**Example: enrichItem API Contract**

```swift
// enrichItemIntegrationTests.swift
class EnrichItemAPITests: XCTestCase {

    var functions: Functions!

    override func setUp() {
        super.setUp()
        // Use Firebase Emulator (localhost:5001)
        functions = Functions.functions()
        functions.useEmulator(withHost: "localhost", port: 5001)
    }

    func testEnrichItem_SuccessfulCall() async throws {
        // Given: Premium user with cropped image
        let userId = "test_user_123"
        let itemId = "test_item_456"

        // Upload test image to Firebase Storage (emulator)
        let imageUrl = try await uploadTestImage(name: "scissors.jpg")

        // When: Call enrichItem Cloud Function
        let result = try await functions.httpsCallable("enrichItem").call([
            "itemId": itemId,
            "basicLabel": "scissors",
            "croppedImageUrl": imageUrl
        ])

        // Then: Returns enriched metadata
        let data = result.data as! [String: Any]
        XCTAssertTrue(data["success"] as! Bool)

        let metadata = data["enrichedMetadata"] as! [String: Any]
        XCTAssertNotNil(metadata["name"])
        XCTAssertNotNil(metadata["brand"])
        XCTAssertGreaterThan(metadata["confidence"] as! Double, 0.7)
    }

    func testEnrichItem_UpdatesFirestore() async throws {
        // Given: Item exists in Firestore (emulator)
        let db = Firestore.firestore()
        let itemRef = db.collection("users/test_user/items").document("item_123")
        try await itemRef.setData(["name": "scissors", "tier": "free"])

        // When: Call enrichItem
        _ = try await functions.httpsCallable("enrichItem").call([
            "itemId": "item_123",
            "basicLabel": "scissors",
            "croppedImageUrl": "gs://test/scissors.jpg"
        ])

        // Then: Firestore document updated with enriched data
        let snapshot = try await itemRef.getDocument()
        let data = snapshot.data()!
        XCTAssertEqual(data["tier"] as! String, "premium")
        XCTAssertNotNil(data["enrichedAt"])
        XCTAssertNotNil(data["brand"])
    }
}
```

---

### 2.2 AI Layer Integration Tests

**Framework:** Jest (Node.js) + Real AI APIs (staging environment)

**Scope:**
- Layer 2a: Real Vertex AI Gemini 2.5 Flash-Lite calls
- Layer 2b: Real SerpAPI + Claude Haiku calls
- Layer 3: Real Claude Sonnet 4.5 calls
- Test rate limiting, error handling, latency
- Validate end-to-end pipeline (Layer 1 → 2a+2b → 3)

**Example: Layer 2a Integration (Gemini 2.5 Flash-Lite)**

```javascript
// layer2aIntegration.test.js
const { VertexAI } = require('@google-cloud/vertexai');
const { runLayer2a } = require('../functions/layer2a');

describe('Layer 2a: Gemini 2.5 Flash-Lite Integration', () => {

    // NOTE: These tests call REAL Vertex AI API (staging)
    // Run sparingly to avoid costs

    test('should extract attributes from real Gemini API', async () => {
        // Given: Test image (scissors)
        const imageUrl = 'gs://abundance-staging/test/scissors.jpg';

        // When: Call Gemini API
        const result = await runLayer2a({
            itemId: 'test_item_123',
            croppedImageUrl: imageUrl
        });

        // Then: Returns extracted attributes
        expect(result.success).toBe(true);
        expect(result.attributes.condition).toBeDefined();
        expect(result.attributes.color).toBeDefined();
        expect(result.attributes.brand_visibility).toBeDefined();
        expect(result.attributes.condition_confidence).toBeGreaterThan(0.7);
    }, 5000);  // 5 sec timeout

    test('should measure Gemini latency (p95 < 50ms)', async () => {
        // Given: 10 test images
        const imageUrls = Array(10).fill('gs://test/scissors.jpg');

        // When: Measure latency for each call
        const latencies = [];
        for (const url of imageUrls) {
            const start = Date.now();
            await runLayer2a({ itemId: 'test', croppedImageUrl: url });
            latencies.push(Date.now() - start);
        }

        // Then: p95 latency < 50ms
        latencies.sort((a, b) => a - b);
        const p95 = latencies[Math.floor(latencies.length * 0.95)];
        expect(p95).toBeLessThan(50);
    });
});
```

**Example: Layer 2b Integration (SerpAPI + Claude Haiku)**

```javascript
// layer2bIntegration.test.js
const { runLayer2b } = require('../functions/layer2b');

describe('Layer 2b: SerpAPI + Claude Haiku Integration', () => {

    test('should search products via SerpAPI and extract brand/model', async () => {
        // Given: Test image uploaded to CDN
        const cdnUrl = 'https://cdn.abundance.app/test/scissors.jpg';

        // When: Call Layer 2b (SerpAPI + Claude Haiku)
        const result = await runLayer2b({
            itemId: 'test_item_123',
            cdnUrl: cdnUrl,
            basicLabel: 'scissors'
        });

        // Then: Returns brand/model/price
        expect(result.success).toBe(true);
        expect(result.brand).toBeDefined();
        expect(result.model).toBeDefined();
        expect(result.avgPrice).toBeGreaterThan(0);
        expect(result.confidence).toBeGreaterThan(0.7);
    }, 10000);  // 10 sec timeout (SerpAPI can be slow)

    test('should handle SerpAPI no results', async () => {
        // Given: Unknown object image
        const cdnUrl = 'https://cdn.abundance.app/test/unknown.jpg';

        // When: Call Layer 2b
        const result = await runLayer2b({
            itemId: 'test_item_123',
            cdnUrl: cdnUrl,
            basicLabel: 'unknown'
        });

        // Then: Returns no results
        expect(result.success).toBe(true);
        expect(result.brand).toBeNull();
        expect(result.serpResults).toHaveLength(0);
    });

    test('should measure Layer 2b latency (p95 < 7s)', async () => {
        // Given: 10 test images
        const testData = Array(10).fill({
            itemId: 'test',
            cdnUrl: 'https://cdn.abundance.app/test/scissors.jpg',
            basicLabel: 'scissors'
        });

        // When: Measure latency
        const latencies = [];
        for (const data of testData) {
            const start = Date.now();
            await runLayer2b(data);
            latencies.push(Date.now() - start);
        }

        // Then: p95 latency < 7 sec
        latencies.sort((a, b) => a - b);
        const p95 = latencies[Math.floor(latencies.length * 0.95)];
        expect(p95).toBeLessThan(7000);
    });
});
```

**Example: Layer 3 Integration (Claude Sonnet 4.5)**

```javascript
// layer3Integration.test.js
const { runLayer3 } = require('../functions/layer3');

describe('Layer 3: Claude Sonnet 4.5 Integration', () => {

    test('should synthesize Layer 2a + 2b data via Claude Sonnet', async () => {
        // Given: Layer 2a and 2b results
        const layer2aData = {
            condition: 'good',
            color: 'blue',
            brand_visibility: 'visible',
            condition_confidence: 0.92
        };
        const layer2bData = {
            brand: 'Fiskars',
            model: '8-Inch Fabric Scissors',
            avgPrice: 13.99,
            confidence: 0.88
        };

        // When: Call Layer 3 (Claude Sonnet synthesis)
        const result = await runLayer3({
            itemId: 'test_item_123',
            layer2aData,
            layer2bData
        });

        // Then: Returns synthesized metadata
        expect(result.success).toBe(true);
        expect(result.final_condition).toBe('good');
        expect(result.final_brand).toBe('Fiskars');
        expect(result.action).toBe('save');
        expect(result.reasoning).toBeDefined();
    }, 5000);  // 5 sec timeout

    test('should use Claude Batch API for cost optimization', async () => {
        // Given: 10 items to process in batch
        const batchData = Array(10).fill({
            layer2aData: { condition: 'good' },
            layer2bData: { brand: 'Fiskars' }
        });

        // When: Submit batch
        const batchId = await submitClaudeBatch(batchData);

        // Then: Batch ID returned
        expect(batchId).toMatch(/^batch_/);
    });

    test('should measure Layer 3 latency (p95 < 2s)', async () => {
        // Given: 10 test synthesis requests
        const testData = Array(10).fill({
            itemId: 'test',
            layer2aData: { condition: 'good', brand_visibility: 'visible' },
            layer2bData: { brand: 'Fiskars', confidence: 0.88 }
        });

        // When: Measure latency
        const latencies = [];
        for (const data of testData) {
            const start = Date.now();
            await runLayer3(data);
            latencies.push(Date.now() - start);
        }

        // Then: p95 latency < 2 sec
        latencies.sort((a, b) => a - b);
        const p95 = latencies[Math.floor(latencies.length * 0.95)];
        expect(p95).toBeLessThan(2000);
    });
});
```

**Example: End-to-End Pipeline Integration**

```javascript
// pipelineIntegration.test.js
const { runFullPipeline } = require('../functions/pipeline');

describe('End-to-End 4-Layer AI Pipeline Integration', () => {

    test('should process item through all 4 layers', async () => {
        // Given: Cropped image from Layer 1 (iOS)
        const croppedImageUrl = 'gs://abundance-staging/test/scissors_cropped.jpg';

        // When: Run full pipeline (Layer 1 already done, run 2a+2b+3)
        const result = await runFullPipeline({
            itemId: 'test_item_123',
            basicLabel: 'scissors',
            croppedImageUrl: croppedImageUrl
        });

        // Then: Returns final enriched metadata
        expect(result.success).toBe(true);
        expect(result.final_condition).toBeDefined();
        expect(result.final_brand).toBeDefined();
        expect(result.final_model).toBeDefined();
        expect(result.action).toBe('save');
        expect(result.pipelineLatency).toBeLessThan(10000);  // < 10 sec
    }, 15000);  // 15 sec timeout for full pipeline

    test('should handle Layer 2b fallback when SerpAPI fails', async () => {
        // Given: SerpAPI rate limit triggered
        // (simulate by using invalid API key)

        // When: Run pipeline
        const result = await runFullPipeline({
            itemId: 'test_item_123',
            basicLabel: 'scissors',
            croppedImageUrl: 'gs://test/scissors.jpg',
            forceSerpAPIFailure: true
        });

        // Then: Falls back to Layer 2a only
        expect(result.success).toBe(true);
        expect(result.layer2bStatus).toBe('failed');
        expect(result.final_condition).toBeDefined();  // Layer 2a still works
        expect(result.final_brand).toBeNull();  // No Layer 2b data
    });
});
```

---

### 2.3 Firestore Integration Tests

**Framework:** Firebase Emulator Suite + Jest

**Scope:**
- Security rules (user can only access own items)
- Offline sync (writes work offline, sync when online)
- Real-time listeners (detect changes)

**Example: Firestore Security Rules**

```javascript
// firestoreSecurityRules.test.js
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

describe('Firestore Security Rules', () => {
    let testEnv;

    beforeAll(async () => {
        testEnv = await initializeTestEnvironment({
            projectId: 'abundance-test',
            firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') }
        });
    });

    test('user can read their own items', async () => {
        const db = testEnv.authenticatedContext('user_123').firestore();

        // When: Read own item
        const doc = await db.doc('users/user_123/items/item_abc').get();

        // Then: Allowed
        expect(doc.exists).toBe(true);
    });

    test('user CANNOT read other users items', async () => {
        const db = testEnv.authenticatedContext('user_123').firestore();

        // When: Attempt to read another user's item
        const promise = db.doc('users/user_456/items/item_xyz').get();

        // Then: Permission denied
        await expect(promise).rejects.toThrow('permission-denied');
    });

    test('user can create free tier items', async () => {
        const db = testEnv.authenticatedContext('user_123').firestore();

        // When: Create item with tier=free
        await db.collection('users/user_123/items').add({
            name: 'scissors',
            tier: 'free',
            createdAt: new Date()
        });

        // Then: Allowed (no error)
    });

    test('user CANNOT change tier manually', async () => {
        const db = testEnv.authenticatedContext('user_123').firestore();

        // Given: Item exists with tier=free
        const itemRef = db.doc('users/user_123/items/item_abc');
        await itemRef.set({ name: 'scissors', tier: 'free' });

        // When: Attempt to change tier to premium manually
        const promise = itemRef.update({ tier: 'premium' });

        // Then: Permission denied (only Cloud Functions can change tier)
        await expect(promise).rejects.toThrow('permission-denied');
    });
});
```

---

## 3. END-TO-END TESTS (10%)

### 3.1 Critical User Flows

**Framework:** XCUITest (iOS UI testing)

**Scope:**
- Onboarding flow (take photo → Layer 1 YOLOv3 → catalog item)
- Premium upgrade flow (free → premium → Layer 2a+2b+3 enrichment)
- Search flow (find item by name)
- Tier-specific flows (free tier: Layer 1 only, premium tier: full pipeline)

**Example: E2E Onboarding Flow**

```swift
// OnboardingE2ETests.swift
class OnboardingE2ETests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["RESET_STATE"]  // Clean state for each test
        app.launch()
    }

    func testCompleteOnboardingFlow_FreeTier() throws {
        // GIVEN: User opens app (anonymous auth, free tier)
        XCTAssertTrue(app.staticTexts["Welcome to Abundance"].exists)

        // WHEN: User taps "Take Photo"
        app.buttons["Take Photo"].tap()

        // Simulate camera permission (granted)
        addUIInterruptionMonitor(withDescription: "Camera Permission") { alert in
            alert.buttons["OK"].tap()
            return true
        }

        // Simulate taking photo (test image: scissors.jpg)
        app.buttons["Capture"].tap()

        // Wait for YOLOv3-Tiny processing (Layer 1) (<150ms)
        let itemCard = app.otherElements["ItemCard_scissors"]
        XCTAssertTrue(itemCard.waitForExistence(timeout: 2))

        // THEN: Item appears in inventory with basic label (Layer 1 only)
        XCTAssertTrue(app.staticTexts["scissors"].exists)
        XCTAssertTrue(app.staticTexts["Office Supplies"].exists)

        // AND: Free tier badge visible (no enrichment)
        XCTAssertTrue(app.images["FreeTierBadge"].exists)

        // AND: No brand/model/condition shown (free tier limitation)
        XCTAssertFalse(app.staticTexts["Brand:"].exists)
        XCTAssertFalse(app.staticTexts["Condition:"].exists)
    }

    func testPremiumUpgradeFlow_FullPipeline() throws {
        // GIVEN: User has cataloged 1 item (free tier, Layer 1 only)
        catalogTestItem(name: "scissors")

        // WHEN: User taps "Upgrade to Premium"
        app.buttons["Upgrade to Premium"].tap()

        // Simulate Apple IAP purchase flow (sandbox)
        let purchaseButton = app.buttons["Subscribe"]
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 2))
        purchaseButton.tap()

        // Wait for StoreKit confirmation
        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3))
        confirmButton.tap()

        // THEN: Premium badge appears
        let premiumBadge = app.images["PremiumBadge"]
        XCTAssertTrue(premiumBadge.waitForExistence(timeout: 5))

        // AND: Item is enriched via 4-layer AI pipeline (Layer 2a+2b+3)
        // Layer 2a: Gemini extracts condition, color
        let conditionLabel = app.staticTexts["Condition: Good"]
        XCTAssertTrue(conditionLabel.waitForExistence(timeout: 2))

        let colorLabel = app.staticTexts["Color: Blue"]
        XCTAssertTrue(colorLabel.waitForExistence(timeout: 2))

        // Layer 2b: SerpAPI + Claude Haiku extracts brand/model
        let brandLabel = app.staticTexts["Brand: Fiskars"]
        XCTAssertTrue(brandLabel.waitForExistence(timeout: 8))  // SerpAPI can take 5-7 sec

        let modelLabel = app.staticTexts["Model: 8-Inch Fabric Scissors"]
        XCTAssertTrue(modelLabel.waitForExistence(timeout: 2))

        // Layer 3: Claude Sonnet synthesis action is 'save'
        let priceLabel = app.staticTexts["Est. Value: $13.99"]
        XCTAssertTrue(priceLabel.waitForExistence(timeout: 3))

        // Total pipeline latency < 10 sec
        // (Layer 1: <150ms, Layer 2a: <50ms, Layer 2b: <7s, Layer 3: <2s)
    }

    func testPremiumFlow_Layer2bFallback() throws {
        // GIVEN: Premium user with SerpAPI rate limit triggered
        setupPremiumUser()

        // WHEN: User catalogs item (SerpAPI fails, Layer 2a only)
        app.buttons["Take Photo"].tap()
        app.buttons["Capture"].tap()

        // THEN: Item shows Layer 2a data (condition, color) but no brand/model
        let conditionLabel = app.staticTexts["Condition: Good"]
        XCTAssertTrue(conditionLabel.waitForExistence(timeout: 2))

        let colorLabel = app.staticTexts["Color: Blue"]
        XCTAssertTrue(colorLabel.waitForExistence(timeout: 2))

        // No brand/model (Layer 2b failed)
        XCTAssertFalse(app.staticTexts["Brand:"].exists)
        XCTAssertFalse(app.staticTexts["Model:"].exists)

        // Fallback message shown
        let fallbackMessage = app.staticTexts["We couldn't find a brand. Try taking a clearer photo."]
        XCTAssertTrue(fallbackMessage.exists)
    }
}
```

---

### 3.2 E2E Test Environment

**Setup:**
- **iOS Simulator:** iPhone 15 Pro (iOS 26 simulator)
- **Firebase Emulator Suite:** Local backend (Firestore, Cloud Functions, Storage)
- **Mock AI Services:** Mock servers for Gemini, SerpAPI, Claude APIs

**Why Mock AI Services for E2E:**
- Real AI APIs are slow (Layer 2b: 5-7 sec, Layer 3: 1-2 sec)
- Rate limits (Vertex AI: 60 QPM, SerpAPI: 100/mo free tier)
- Cost (Layer 2b: $0.0109/item, Layer 3: $0.0092/item)
- Consistency (mock responses are deterministic)

**Mock AI Services Server (Node.js):**
```javascript
// mockAIServices.js
const express = require('express');
const app = express();
app.use(express.json());

// Mock Gemini 2.5 Flash-Lite (Layer 2a)
app.post('/v1/models/gemini-2.5-flash-lite:generateContent', (req, res) => {
    const imageData = req.body.contents[0].parts[0].inline_data;

    res.json({
        candidates: [{
            content: {
                parts: [{
                    text: JSON.stringify({
                        condition: 'good',
                        condition_confidence: 0.92,
                        color: 'blue',
                        color_confidence: 0.88,
                        material: 'metal',
                        material_confidence: 0.85,
                        brand_visibility: 'visible',
                        brand_visibility_confidence: 0.90
                    })
                }]
            }
        }]
    });
});

// Mock SerpAPI (Layer 2b)
app.get('/search', (req, res) => {
    const query = req.query.q;

    if (query.includes('scissors')) {
        res.json({
            shopping_results: [
                { title: 'Fiskars Scissors', price: '$12.99', source: 'Amazon' },
                { title: 'Fiskars Fabric Scissors 8"', price: '$14.99', source: 'Walmart' },
                { title: 'Fiskars Premium Scissors', price: '$11.99', source: 'Target' }
            ]
        });
    } else {
        res.json({ shopping_results: [] });
    }
});

// Mock Claude Haiku (Layer 2b)
app.post('/v1/messages', (req, res) => {
    const model = req.body.model;

    if (model === 'claude-3-5-haiku-20241022') {
        // Layer 2b: Brand/model extraction
        res.json({
            id: 'msg_test123',
            content: [{
                type: 'text',
                text: JSON.stringify({
                    brand: 'Fiskars',
                    model: '8-Inch Fabric Scissors',
                    confidence: 0.91
                })
            }]
        });
    } else if (model === 'claude-sonnet-4-5-20250929') {
        // Layer 3: AI synthesis
        res.json({
            id: 'msg_test456',
            content: [{
                type: 'text',
                text: JSON.stringify({
                    final_condition: 'good',
                    final_color: 'blue',
                    final_brand: 'Fiskars',
                    final_model: '8-Inch Fabric Scissors',
                    action: 'save',
                    reasoning: 'High confidence from both layers.'
                })
            }]
        });
    }
});

app.listen(8080, () => console.log('Mock AI Services running on :8080'));
```

---

## 4. AI LAYER TESTING STRATEGY

### 4.1 Layer-Specific Testing Approach

**Layer 1 (iOS YOLOv3-Tiny):**
- **Unit:** Mock Core ML model, test bounding box extraction, image cropping
- **Integration:** Real Core ML model on iOS simulator with 10 test images
- **E2E:** Full onboarding flow with real camera input (simulator photos)
- **Performance Target:** <150ms p95 (on-device inference)
- **Coverage Target:** >85% (critical path: object detection → cropping)

**Layer 2a (Gemini 2.5 Flash-Lite):**
- **Unit:** Mock Vertex AI API, test JSON parsing, schema validation
- **Integration:** Real Vertex AI calls with 10 test images (cropped scissors, headphones, etc.)
- **E2E:** Full pipeline test with Gemini validation (check condition, color, material extracted)
- **Performance Target:** <50ms p95 (Vertex AI latency)
- **Cost Target:** $0.000249 per image (1 image = 1250 tokens * $0.000199/1K tokens)
- **Coverage Target:** >90% (critical path: API call → JSON parse → validation)

**Layer 2b (SerpAPI + Claude Haiku):**
- **Unit:** Mock SerpAPI + Claude API, test parsing logic, price averaging
- **Integration:** Real SerpAPI + Claude calls with 10 test images (via CDN URLs)
- **E2E:** Full pipeline test with SerpAPI validation (check brand/model extracted)
- **Performance Target:** <7s p95 (SerpAPI: 5s + Claude Haiku: 1s + parsing: 1s)
- **Cost Target:** $0.0109 per item (SerpAPI: $0.01 + Claude Haiku: $0.0009)
- **Coverage Target:** >90% (critical path: GCS upload → SerpAPI → Claude parse)

**Layer 3 (Claude Sonnet 4.5):**
- **Unit:** Mock Claude Batch API, test conflict resolution, action determination
- **Integration:** Real Claude Sonnet calls with synthetic Layer 2a+2b data (20 test cases)
- **E2E:** Full pipeline test with synthesis validation (check action: save/request_photo/manual_review)
- **Performance Target:** <2s p95 (Claude Sonnet Batch API)
- **Cost Target:** $0.0092 per inference (avg 800 output tokens * $0.000115/1K tokens)
- **Coverage Target:** >95% (critical path: conflict resolution → action → reasoning)

### 4.2 Cross-Layer Integration Testing

**Pipeline Flow Tests:**
1. **Happy Path:** Layer 1 → 2a+2b → 3 → Firestore (all layers succeed)
2. **Layer 2b Fallback:** Layer 1 → 2a only → 3 (SerpAPI fails, use Layer 2a data only)
3. **Layer 3 Manual Review:** Layer 1 → 2a+2b → 3 (confidence too low, action: manual_review)
4. **Layer 3 Request Photo:** Layer 1 → 2a+2b → 3 (brand_visibility: not_visible, action: request_photo)

**Test Data:**
- 20 test images covering common objects (scissors, headphones, books, tools, clothing)
- 10 edge cases (low quality, no brand visible, unknown object)
- 5 conflict scenarios (Layer 2a says "red", Layer 2b says "blue")

---

## 5. PERFORMANCE TESTING

### 5.1 Layer-Specific Performance Targets

| Layer | Target Latency (p95) | Measurement Method | Acceptance Criteria |
|-------|---------------------|-------------------|---------------------|
| **Layer 1 (iOS YOLOv3)** | <150ms | Xcode Instruments (Time Profiler) | 95% of inferences < 150ms |
| **Layer 2a (Gemini)** | <50ms | Backend timing logs (start → response) | 95% of API calls < 50ms |
| **Layer 2b (SerpAPI)** | <7s | Backend timing logs (upload → parse) | 95% of searches < 7s |
| **Layer 3 (Claude Sonnet)** | <2s | Backend timing logs (batch submit → result) | 95% of syntheses < 2s |
| **Total Pipeline** | <10s | End-to-end trace (Layer 1 → Firestore) | 95% of items < 10s |

### 5.2 Performance Test Plan

**iOS Layer 1 Performance Test:**
```swift
// PerformanceTests.swift
func testYOLOv3InferencePerformance() {
    let image = UIImage(named: "test_scissors.jpg")!

    measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
        // Measure YOLOv3-Tiny inference time
        _ = VisionService.detectObjects(in: image)
    }

    // Expected: <150ms average, <200ms p95
}
```

**Backend Performance Test (k6):**
```javascript
// performanceTest.js
import http from 'k6/http';
import { check } from 'k6';

export let options = {
    thresholds: {
        'http_req_duration{layer:2a}': ['p(95)<50'],      // Layer 2a < 50ms
        'http_req_duration{layer:2b}': ['p(95)<7000'],    // Layer 2b < 7s
        'http_req_duration{layer:3}': ['p(95)<2000'],     // Layer 3 < 2s
        'http_req_duration{pipeline:full}': ['p(95)<10000'], // Full < 10s
    },
};

export default function () {
    // Test Layer 2a (Gemini)
    let layer2aStart = Date.now();
    let res2a = http.post('https://api.abundance.app/layer2a', {
        croppedImageUrl: 'gs://test/scissors.jpg'
    }, { tags: { layer: '2a' } });
    check(res2a, { 'Layer 2a success': (r) => r.status === 200 });

    // Test Layer 2b (SerpAPI + Claude Haiku)
    let res2b = http.post('https://api.abundance.app/layer2b', {
        cdnUrl: 'https://cdn.abundance.app/test/scissors.jpg'
    }, { tags: { layer: '2b' } });
    check(res2b, { 'Layer 2b success': (r) => r.status === 200 });

    // Test Layer 3 (Claude Sonnet)
    let res3 = http.post('https://api.abundance.app/layer3', {
        layer2aData: JSON.parse(res2a.body),
        layer2bData: JSON.parse(res2b.body)
    }, { tags: { layer: '3' } });
    check(res3, { 'Layer 3 success': (r) => r.status === 200 });
}
```

### 5.3 Load Testing

**Scenario:** 100 concurrent premium users cataloging items

**Setup:**
- k6 load testing tool
- Staging environment (Firebase, GCS, Cloud Functions)
- Mock AI APIs (to avoid rate limits and costs)

**Success Criteria:**
- p95 latency < 10 sec (under 100 concurrent users)
- 0% error rate (no 5xx errors from Cloud Functions)
- Firestore writes succeed (all items saved)
- No API rate limits triggered (Vertex AI, SerpAPI, Claude)

---

## 6. COST VALIDATION TESTING

### 6.1 Cost Tracking Per Test Run

**Goal:** Ensure actual costs match estimated costs per layer

**Test Setup:**
```javascript
// costTracking.test.js
const { trackAPICosts } = require('../functions/costTracking');

describe('Cost Validation Tests', () => {

    test('Layer 2a cost should be $0.000249 per image', async () => {
        // Given: Track Layer 2a API costs
        const costTracker = new CostTracker();

        // When: Process 100 test images via Gemini
        for (let i = 0; i < 100; i++) {
            await runLayer2a({ croppedImageUrl: `gs://test/image${i}.jpg` });
        }

        // Then: Total cost should be ~$0.0249 (100 * $0.000249)
        const totalCost = await costTracker.getLayer2aCost();
        expect(totalCost).toBeCloseTo(0.0249, 3);
        expect(totalCost).toBeLessThan(0.03);  // Alert if > $0.03
    });

    test('Layer 2b cost should be $0.0109 per item', async () => {
        // Given: Track Layer 2b API costs (SerpAPI + Claude Haiku)
        const costTracker = new CostTracker();

        // When: Process 10 test images via SerpAPI + Claude Haiku
        for (let i = 0; i < 10; i++) {
            await runLayer2b({
                cdnUrl: `https://cdn.abundance.app/test/image${i}.jpg`,
                basicLabel: 'scissors'
            });
        }

        // Then: Total cost should be ~$0.109 (10 * $0.0109)
        const totalCost = await costTracker.getLayer2bCost();
        expect(totalCost).toBeCloseTo(0.109, 3);
        expect(totalCost).toBeLessThan(0.12);  // Alert if > $0.12
    });

    test('Layer 3 cost should be $0.0092 per inference', async () => {
        // Given: Track Layer 3 API costs (Claude Sonnet Batch)
        const costTracker = new CostTracker();

        // When: Process 10 syntheses via Claude Sonnet
        for (let i = 0; i < 10; i++) {
            await runLayer3({
                layer2aData: { condition: 'good' },
                layer2bData: { brand: 'Fiskars' }
            });
        }

        // Then: Total cost should be ~$0.092 (10 * $0.0092)
        const totalCost = await costTracker.getLayer3Cost();
        expect(totalCost).toBeCloseTo(0.092, 3);
        expect(totalCost).toBeLessThan(0.10);  // Alert if > $0.10
    });

    test('Full pipeline cost should be $0.0211 per item', async () => {
        // Given: Track full pipeline costs (Layer 2a + 2b + 3)
        const costTracker = new CostTracker();

        // When: Process 10 items through full pipeline
        for (let i = 0; i < 10; i++) {
            await runFullPipeline({
                croppedImageUrl: `gs://test/image${i}.jpg`,
                basicLabel: 'scissors'
            });
        }

        // Then: Total cost should be ~$0.211 (10 * $0.0211)
        const totalCost = await costTracker.getTotalCost();
        expect(totalCost).toBeCloseTo(0.211, 3);
        expect(totalCost).toBeLessThan(0.25);  // Alert if > $0.25
    });
});
```

### 6.2 Cost Alerting

**Setup:** BigQuery cost tracking + alerts

**Alerts:**
- If Layer 2a cost > $0.0003 per image → investigate (expected: $0.000249)
- If Layer 2b cost > $0.012 per item → investigate (expected: $0.0109)
- If Layer 3 cost > $0.010 per inference → investigate (expected: $0.0092)
- If total pipeline cost > $0.025 per item → investigate (expected: $0.0211)

**Implementation:**
```sql
-- BigQuery cost monitoring query
SELECT
  DATE(timestamp) as date,
  COUNT(*) as items_processed,
  SUM(layer2a_cost) as total_layer2a_cost,
  SUM(layer2b_cost) as total_layer2b_cost,
  SUM(layer3_cost) as total_layer3_cost,
  SUM(layer2a_cost + layer2b_cost + layer3_cost) as total_cost,
  AVG(layer2a_cost + layer2b_cost + layer3_cost) as avg_cost_per_item
FROM `abundance-staging.costs.ai_pipeline`
WHERE DATE(timestamp) = CURRENT_DATE()
GROUP BY date
HAVING avg_cost_per_item > 0.025  -- Alert if > $0.025 per item
```

---

## 7. TEST TOOLING

### 7.1 AI Service Testing Tools

**Vertex AI Testing:**
```bash
# Install Google Cloud SDK
brew install google-cloud-sdk

# Test Gemini 2.5 Flash-Lite
gcloud ai models predict gemini-2.5-flash-lite \
  --region=us-central1 \
  --project=abundance-staging \
  --request=@test-request.json
```

**SerpAPI Testing:**
```bash
# Install SerpAPI Node.js client
npm install serpapi

# Test SerpAPI search
node testSerpAPI.js
```

**Anthropic API Testing:**
```bash
# Install Anthropic SDK
npm install @anthropic-ai/sdk

# Test Claude Haiku
node testClaudeHaiku.js

# Test Claude Sonnet Batch API
node testClaudeSonnetBatch.js
```

**GCS + CDN Testing:**
```bash
# Install Google Cloud Storage SDK
npm install @google-cloud/storage

# Test image upload to GCS
node testGCSUpload.js

# Test CDN URL generation
node testCDNUrl.js
```

**Redis Testing:**
```bash
# Install ioredis client
npm install ioredis

# Test Redis queue enqueue/dequeue
node testRedisQueue.js
```

### 7.2 Test Data Management

**Test Images:**
```
test-data/images/
├── layer1/
│   ├── scissors.jpg (high quality, brand visible)
│   ├── headphones.jpg (high quality, brand visible)
│   ├── low_quality.jpg (blurry, brand not visible)
│   └── unknown_object.jpg (not in training data)
├── layer2a_cropped/
│   ├── scissors_cropped.jpg (cropped from Layer 1)
│   ├── headphones_cropped.jpg
│   └── book_cropped.jpg
└── layer2b_cdn/
    ├── scissors_cdn_url.txt (https://cdn.abundance.app/...)
    └── headphones_cdn_url.txt
```

**Mock API Responses:**
```json
// test-data/mock-responses/gemini-responses.json
{
  "scissors.jpg": {
    "condition": "good",
    "condition_confidence": 0.92,
    "color": "blue",
    "color_confidence": 0.88,
    "material": "metal",
    "material_confidence": 0.85,
    "brand_visibility": "visible",
    "brand_visibility_confidence": 0.90
  },
  "headphones.jpg": {
    "condition": "excellent",
    "condition_confidence": 0.95,
    "color": "black",
    "color_confidence": 0.93,
    "material": "plastic",
    "material_confidence": 0.89,
    "brand_visibility": "visible",
    "brand_visibility_confidence": 0.94
  }
}
```

```json
// test-data/mock-responses/serpapi-responses.json
{
  "scissors": {
    "shopping_results": [
      { "title": "Fiskars Scissors", "price": "$12.99", "source": "Amazon" },
      { "title": "Fiskars Fabric Scissors 8\"", "price": "$14.99", "source": "Walmart" },
      { "title": "Fiskars Premium Scissors", "price": "$11.99", "source": "Target" }
    ]
  },
  "headphones": {
    "shopping_results": [
      { "title": "Beats Pro 2 Headphones", "price": "$199.99", "source": "Amazon" },
      { "title": "Beats Pro 2 Over-Ear", "price": "$189.99", "source": "Best Buy" }
    ]
  }
}
```

---

## 8. TEST AUTOMATION & CI/CD

### 8.1 GitHub Actions Workflow

**Trigger:** Every push to `main` branch, every pull request

```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  unit-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      # iOS Unit Tests
      - name: Run iOS Unit Tests
        run: |
          xcodebuild test \
            -scheme Abundance \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -resultBundlePath TestResults

      # Backend Unit Tests
      - name: Run Backend Unit Tests
        run: |
          cd functions
          npm install
          npm test -- --coverage

      # Upload coverage
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./functions/coverage/lcov.info,./ios/coverage.lcov

  integration-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      # Start Firebase Emulator
      - name: Start Firebase Emulator
        run: |
          npm install -g firebase-tools
          firebase emulators:start --only firestore,functions,storage &
          sleep 10  # Wait for emulators to start

      # Run Integration Tests
      - name: Run Integration Tests
        run: |
          cd functions
          npm run test:integration

      - name: Stop Firebase Emulator
        run: firebase emulators:stop

  e2e-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      # Start Mock AI Services
      - name: Start Mock AI Services
        run: |
          cd test-utils
          node mockAIServices.js &
          sleep 5

      # Run E2E Tests
      - name: Run E2E Tests
        run: |
          xcodebuild test \
            -scheme Abundance \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -only-testing:AbundanceE2ETests \
            -resultBundlePath E2EResults

      # Record test failure screenshots
      - name: Upload Screenshots
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: e2e-screenshots
          path: E2EResults/Attachments
```

---

### 8.2 Test Coverage Requirements

**Pull Request Merge Criteria:**
- ✅ All unit tests pass (0 failures)
- ✅ Code coverage ≥ 80% (unit tests)
- ✅ All integration tests pass (0 failures)
- ✅ Critical E2E tests pass (onboarding, premium upgrade)

**Enforcement:** GitHub branch protection rules
```yaml
# .github/branch-protection.yml
main:
  required_status_checks:
    - unit-tests
    - integration-tests
    - e2e-tests
  required_code_coverage:
    minimum: 80
```

---

## 9. TEST DATA MANAGEMENT

### 9.1 Test Fixtures

**iOS Test Images:**
```
test-data/images/
├── scissors.jpg (known product: Scott Fabric Scissors)
├── headphones.jpg (known product: Beats Pro 2)
├── unknown_object.jpg (not in Shopping Graph database)
└── low_quality.jpg (confidence < 0.7)
```

**Mock AI Service Responses:** (See Section 7.2 for complete mock responses)

---

### 9.2 Test User Accounts

**Firebase Auth (Emulator):**
```javascript
// test-data/users.js
module.exports = {
  freeUser: {
    uid: 'test_free_user_123',
    email: 'free@test.com',
    subscriptionTier: 'free'
  },
  premiumUser: {
    uid: 'test_premium_user_456',
    email: 'premium@test.com',
    subscriptionTier: 'premium'
  }
};
```

---

## 10. LOAD TESTING (LEGACY - SEE SECTION 5 FOR UPDATED PERFORMANCE TESTING)

### 10.1 Load Testing (AI Pipeline)

**Tool:** k6 (load testing tool)

**Scenario:** Simulate 100 concurrent premium users cataloging items

```javascript
// loadTest.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 10 },   // Ramp up to 10 users
    { duration: '3m', target: 50 },   // Ramp up to 50 users
    { duration: '5m', target: 100 },  // Ramp up to 100 users
    { duration: '2m', target: 0 },    // Ramp down
  ],
};

export default function () {
  // Simulate enrichItem Cloud Function call
  let res = http.post('https://us-central1-abundance-staging.cloudfunctions.net/enrichItem', JSON.stringify({
    itemId: 'load_test_item',
    basicLabel: 'scissors',
    croppedImageUrl: 'gs://test/scissors.jpg'
  }), {
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer test-token' }
  });

  check(res, {
    'status is 200': (r) => r.status === 200,
    'latency < 10 sec': (r) => r.timings.duration < 10000,
  });

  sleep(5);  // Wait 5 sec between requests
}
```

**Success Criteria:**
- p95 latency < 10 sec (under 100 concurrent users)
- 0% error rate (no 5xx errors)
- AI APIs don't rate limit (Vertex AI: < 60 QPM, SerpAPI: < 100/mo)

---

## 11. MANUAL TESTING CHECKLIST

### 11.1 Pre-Launch Testing (Week Before Launch)

**Device Matrix:**
- ✅ iPhone 15 Pro (iOS 26.0)
- ✅ iPhone 15 Pro Max (iOS 26.0)
- ✅ iPad Pro M1 (iOS 26.0)

**Test Cases:**
1. ✅ Onboarding flow (take photo → Layer 1 YOLOv3 → catalog item)
2. ✅ Premium upgrade (Apple IAP sandbox → Layer 2a+2b+3 enrichment)
3. ✅ Offline mode (airplane mode, catalog item, sync when online)
4. ✅ Search (find item by name, category)
5. ✅ Export (PDF, CSV)
6. ✅ Delete account (GDPR compliance)
7. ✅ Layer 2b fallback (SerpAPI fails, Layer 2a only)
8. ✅ Layer 3 manual review (low confidence, action: manual_review)

---

### 11.2 Beta Testing (Month -1 to Launch)

**TestFlight:**
- 50-100 beta testers (friends, family, early adopters)
- Collect feedback via TestFlight feedback form
- Track crash rate (target: >99.5% crash-free)

**Metrics to Track:**
- Time to first item cataloged (target: <2 min)
- Premium conversion rate (target: 15-30%)
- Layer 2a success rate (target: >95%)
- Layer 2b success rate (target: >85%, with fallback to Layer 2a)
- Layer 3 action distribution (save: >70%, request_photo: 15-20%, manual_review: <10%)

---

## 12. TEST MAINTENANCE

### 12.1 Test Review Cadence

**Weekly:** Review failed tests in CI/CD (fix or update)
**Monthly:** Review test coverage (identify gaps)
**Quarterly:** Refactor brittle tests (reduce flakiness)

---

### 12.2 Flaky Test Policy

**Definition:** Test that fails intermittently (passes/fails without code changes)

**Action:**
1. Mark test as `@Flaky` (skip in CI/CD)
2. Create GitHub issue (investigate root cause)
3. Fix within 1 sprint (or delete test)

**Flakiness Threshold:** <5% of tests can be flaky (if >5%, pause feature work to fix)

---

## Stakeholder Sign-Off

- [ ] **Engineering Leadership** (approve test strategy)
- [ ] **iOS Lead** (approve iOS test plan)
- [ ] **Backend Lead** (approve backend test plan)
- [ ] **QA Lead** (approve manual testing checklist)

**Timeline:** Finalized by 2025-10-31

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-10-24 | 1.0 | Initial test strategy with Google Shopping Graph |
| 2025-11-01 | 2.0 | Updated for 4-layer AI pipeline (Layer 1: Vision, Layer 2a: Gemini, Layer 2b: SerpAPI, Layer 3: Claude). Added layer-specific unit tests, integration tests, performance targets, and cost validation testing. |

---

## Appendix A: Test Command Reference

### Run All Tests (iOS)
```bash
xcodebuild test \
  -scheme Abundance \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -resultBundlePath TestResults
```

### Run Backend Unit Tests
```bash
cd functions
npm test -- --coverage
```

### Run Integration Tests (Requires Firebase Emulator)
```bash
firebase emulators:start --only firestore,functions,storage &
npm run test:integration
```

### Run E2E Tests
```bash
xcodebuild test \
  -scheme Abundance \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AbundanceE2ETests
```

---

## Appendix B: CI/CD Pipeline Diagram

```
GitHub Push/PR
     │
     ▼
┌─────────────────┐
│  Unit Tests     │  (<5 sec)
│  - iOS          │
│  - Backend      │
└────────┬────────┘
         │ Pass
         ▼
┌─────────────────┐
│ Integration     │  (30-60 sec)
│  - API Tests    │
│  - Firestore    │
└────────┬────────┘
         │ Pass
         ▼
┌─────────────────┐
│ E2E Tests       │  (3-5 min)
│  - Onboarding   │
│  - Premium      │
└────────┬────────┘
         │ Pass
         ▼
┌─────────────────┐
│ Merge to main   │
│ Deploy staging  │
└─────────────────┘
```

---

**Related Documents:**
- TECH-STACK-001: Complete Technology Stack Map
- API-CONTRACTS-001: Service Interface Definitions
- ADR-014: Multi-Layer AI Pipeline Architecture
- ADR-015: Gemini 2.5 Flash-Lite for Attribute Extraction
- ADR-016: SerpAPI + Claude Haiku for Product Search
- ADR-017: Claude Sonnet 4.5 for AI Synthesis
- DESIGN-004: Backend AI Pipeline Design
- DESIGN-005: iOS Vision Integration Design
- SCHEMA-001: Core Data Schemas

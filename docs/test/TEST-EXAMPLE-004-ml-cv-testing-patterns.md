# TEST-EXAMPLE-004: ML/CV Testing Patterns

**Created**: 2025-11-11
**Stage**: 3.3 - Layer 1 On-Device ML Implementation Research
**Status**: Complete
**References**: docs/plans/PLAN-SUMMARY-stage-3.3.md, TEST-EXAMPLE-001

---

## Overview

ML/CV-specific testing patterns for Layer 1: mock Core ML models, snapshot tests for bounding boxes, performance tests.

---

## 1. Unit Tests with Mock Models

**Problem**: Loading 34MB YOLOv3-Tiny model in unit tests is slow (50-100ms).  
**Solution**: Mock VisionService to avoid model loading.

```swift
class MockVisionService: VisionServiceProtocol {
    var mockDetections: [DetectedObject] = []
    
    func detectObjects(in image: UIImage) async throws -> [DetectedObject] {
        return mockDetections
    }
}

func testHouseholdItemDetector_WithMockService() async throws {
    // Given
    let mockService = MockVisionService()
    mockService.mockDetections = [
        DetectedObject(label: "backpack", confidence: 0.8, ...)
    ]
    let detector = HouseholdItemDetector(visionService: mockService, ...)
    
    // When
    let items = try await detector.detectHouseholdItems(in: testImage)
    
    // Then
    XCTAssertEqual(items.count, 1)
}
```

---

## 2. Integration Tests with Real Model

**When to use**: End-to-end testing with actual YOLOv3-Tiny model.

```swift
func testVisionService_RealModel_DetectsBackpack() async throws {
    // Given
    let visionService = try VisionService() // Loads real 34MB model
    let testImage = UIImage(named: "test_backpack.jpg")!
    
    // When
    let detections = try await visionService.detectObjects(in: testImage)
    
    // Then
    XCTAssertFalse(detections.isEmpty)
    XCTAssertTrue(detections.contains { $0.label == "backpack" })
    XCTAssertTrue(detections.first!.confidence > 0.6)
}
```

---

## 3. Snapshot Tests for Bounding Boxes

**Purpose**: Visual regression testing (detect unintended changes in detection behavior).

```swift
import SnapshotTesting

func testBoundingBoxes_Snapshot() async throws {
    // Given
    let visionService = try VisionService()
    let testImage = UIImage(named: "test_camping_gear.jpg")!
    
    // When
    let detections = try await visionService.detectObjects(in: testImage)
    
    // Then: Render bounding boxes on image
    let annotatedImage = renderBoundingBoxes(detections, on: testImage)
    assertSnapshot(matching: annotatedImage, as: .image)
}
```

---

## 4. Performance Tests

**Target**: <500ms latency on iPhone 15 Pro.

```swift
func testPerformance_ObjectDetection_Completes500ms() throws {
    let visionService = try VisionService()
    let testImage = UIImage(named: "test_backpack.jpg")!
    
    measure(metrics: [XCTClockMetric()]) {
        _ = try await visionService.detectObjects(in: testImage)
    }
    
    // XCTest will report average latency
    // Assert: <500ms average
}
```

---

## 5. Mocking Strategies

### Mock Core ML Model (Advanced)

```swift
class MockVNCoreMLModel: VNCoreMLModel {
    var mockResults: [VNRecognizedObjectObservation] = []
    
    override func perform(_ request: VNCoreMLRequest) throws {
        request.results = mockResults
    }
}
```

### Deterministic Test Fixtures

- Use same test images across runs
- Store in `Tests/Fixtures/` directory
- Include ground truth labels in comments

---

## Acceptance Criteria

- [x] ✅ Unit tests with mock VisionService (avoid 34MB model load)
- [x] ✅ Integration tests with real YOLOv3-Tiny model
- [x] ✅ Snapshot tests for bounding box visual regression
- [x] ✅ Performance tests measuring <500ms latency
- [x] ✅ Mocking strategies documented

---

**Status**: ✅ COMPLETE

# SPEC-UI-007: On-Device ML Integration

**Document ID:** SPEC-UI-007
**Date:** 2026-01-15
**Status:** DRAFT
**Related Documents:**
- Brand Bible: Part IV (On-Device Machine Learning)
- DESIGN-004 (Computer Vision Pipeline)
- ADR-013 (Vision Framework Strategy)

---

## Executive Summary

This specification defines the **on-device ML integration** for Abundance, leveraging Vision Framework, Core ML, and Foundation Models for intelligent cataloging without cloud dependency.

---

## 1. Vision Framework Integration

### 1.1 Detection Pipeline

```swift
actor VisionDetectionService {
    private let requestHandler: VNImageRequestHandler

    func detectObjects(in image: CGImage) async throws -> [DetectedObject] {
        // Text recognition
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate

        // Barcode detection
        let barcodeRequest = VNDetectBarcodesRequest()
        barcodeRequest.symbologies = [.qr, .ean13, .ean8, .upce]

        // Object classification (Core ML)
        let classificationRequest = try VNCoreMLRequest(model: objectClassifier)

        try requestHandler.perform([textRequest, barcodeRequest, classificationRequest])

        // Aggregate results
        return aggregateResults(
            text: textRequest.results ?? [],
            barcodes: barcodeRequest.results ?? [],
            classifications: classificationRequest.results ?? []
        )
    }
}
```

### 1.2 iOS 26 New APIs

```swift
// Lens smudge detection (Brand Bible 3.3)
func checkLensQuality(pixelBuffer: CVPixelBuffer) async throws -> LensQuality {
    let request = DetectLensSmudgeRequest()
    let result = try await request.perform(on: pixelBuffer)

    return LensQuality(
        isSmudged: result.confidence > 0.7,
        confidence: result.confidence
    )
}

// Document segmentation (Brand Bible 3.3)
func segmentDocument(in image: CGImage) async throws -> CGRect? {
    let request = DetectDocumentSegmentationRequest()
    try requestHandler.perform([request])

    return request.results?.first?.boundingBox
}
```

---

## 2. Core ML Custom Models

### 2.1 Model Integration

```swift
struct CoreMLModelManager {
    static let shared = CoreMLModelManager()

    // Object classifier (YOLOv3-Tiny or custom)
    lazy var objectClassifier: VNCoreMLModel = {
        guard let model = try? YOLOv3Tiny(configuration: .init()).model,
              let visionModel = try? VNCoreMLModel(for: model) else {
            fatalError("Failed to load object classifier")
        }
        return visionModel
    }()

    // Category-specific classifiers (future)
    // - Sneaker classifier
    // - Electronics classifier
    // - Book classifier
}
```

### 2.2 Model Performance Requirements

| Model | Max Latency | Min Accuracy |
|-------|-------------|--------------|
| Object Detection | 150ms | 85% |
| Text Recognition | 200ms | 95% |
| Barcode Detection | 50ms | 99% |

---

## 3. Foundation Models Integration (iOS 26+)

### 3.1 Intelligent Cataloging

Per Brand Bible 4.1 (Guided Generation):

```swift
import FoundationModels

@Generable
struct CatalogItem: Codable {
    @Guide(description: "A concise, marketable title under 60 characters")
    var title: String

    @Guide(description: "A detailed description for catalog listing, 100-300 words")
    var description: String

    @Guide(description: "The primary category for this item")
    var category: ItemCategory

    @Guide(description: "Estimated market value in USD")
    var estimatedValue: Decimal?

    @Guide(description: "Relevant keywords for search, 5-10 items")
    var keywords: [String]
}

actor IntelligentCatalogingService {
    private let session = LanguageModelSession()

    func generateCatalogItem(from detectionResult: DetectionResult) async throws -> CatalogItem {
        let prompt = """
        Based on the following recognized data, generate a CatalogItem:
        - Object type: \(detectionResult.objectType)
        - Recognized text: \(detectionResult.text.joined(separator: ", "))
        - Barcode: \(detectionResult.barcode ?? "none")
        """

        let result = try await session.generate(
            prompt,
            as: CatalogItem.self
        )

        return result
    }
}
```

### 3.2 Feature Availability

Per Brand Bible 4.1:

| Feature | Minimum Device | iOS Version |
|---------|----------------|-------------|
| Basic Vision | iPhone 11+ | iOS 26 |
| Foundation Models | iPhone 15 Pro+ | iOS 26 + Apple Intelligence |
| Custom Core ML | iPhone 11+ | iOS 26 |

### 3.3 Graceful Degradation

```swift
struct MLCapabilities {
    static var supportsFoundationModels: Bool {
        if #available(iOS 26, *) {
            return LanguageModelSession.isAvailable
        }
        return false
    }

    static var supportsAdvancedVision: Bool {
        // Check for Neural Engine capability
        return ProcessInfo.processInfo.processorCount >= 6
    }
}

// Usage
func catalogItem(_ image: CGImage) async throws -> CatalogItem {
    let detection = try await visionService.detectObjects(in: image)

    if MLCapabilities.supportsFoundationModels {
        // Full intelligent cataloging
        return try await intelligentService.generateCatalogItem(from: detection)
    } else {
        // Fallback to basic detection results
        return CatalogItem(
            title: detection.text.first ?? "Unknown Item",
            description: "",
            category: .other,
            estimatedValue: nil,
            keywords: []
        )
    }
}
```

---

## 4. Tool Calling for Live Data

Per Brand Bible 4.3:

```swift
import FoundationModels

// Define tool for market data lookup
struct MarketDataTool: Tool {
    let name = "lookupMarketValue"
    let description = "Look up current market value for an item"

    struct Input: Codable {
        let itemTitle: String
        let category: String
    }

    struct Output: Codable {
        let estimatedValue: Decimal
        let priceRange: ClosedRange<Decimal>
        let recentSales: Int
    }

    func call(with input: Input) async throws -> Output {
        // Call Abundance backend API
        let response = try await abundanceAPI.lookupMarketValue(
            title: input.itemTitle,
            category: input.category
        )
        return Output(
            estimatedValue: response.median,
            priceRange: response.low...response.high,
            recentSales: response.saleCount
        )
    }
}
```

---

## 5. Privacy Architecture

Per Brand Bible 4.1:

```
┌─────────────────────────────────────────────────────┐
│                   USER'S DEVICE                      │
│                                                      │
│  ┌────────────┐     ┌─────────────────────────┐    │
│  │   Camera   │────▶│   Vision Framework      │    │
│  └────────────┘     │   - Text Recognition    │    │
│                     │   - Object Detection    │    │
│                     │   - Barcode Scanning    │    │
│                     └───────────┬─────────────┘    │
│                                 │                   │
│                                 ▼                   │
│                     ┌─────────────────────────┐    │
│                     │  Foundation Models      │    │
│                     │  - Intelligent Catalog  │    │
│                     │  - Runs 100% on-device  │    │
│                     └───────────┬─────────────┘    │
│                                 │                   │
│                                 ▼                   │
│                     ┌─────────────────────────┐    │
│                     │     Firestore           │    │
│                     │  - Catalog metadata     │    │
│                     │  - No original photos   │    │
│                     └─────────────────────────┘    │
│                                                      │
└─────────────────────────────────────────────────────┘
               │
               │ Premium tier only
               ▼
┌─────────────────────────────────────────────────────┐
│                   GCP BACKEND                        │
│  - Cropped thumbnails only (not originals)          │
│  - Market data lookup                               │
│  - SerpAPI Google Lens (optional)                   │
└─────────────────────────────────────────────────────┘
```

---

## 6. Acceptance Criteria

- [ ] Vision detection pipeline runs <200ms total
- [ ] Text recognition accuracy >95%
- [ ] Barcode detection accuracy >99%
- [ ] Foundation Models gracefully degrade on unsupported devices
- [ ] Original photos never leave device
- [ ] All ML processing respects Reduce Motion setting

---

## 7. Test Plan

```swift
func testVisionPipelinePerformance() async throws {
    let testImage = loadTestImage("sample_product.jpg")

    let start = CFAbsoluteTimeGetCurrent()
    let results = try await visionService.detectObjects(in: testImage)
    let elapsed = CFAbsoluteTimeGetCurrent() - start

    XCTAssertLessThan(elapsed, 0.2) // 200ms max
    XCTAssertFalse(results.isEmpty)
}
```

# DESIGN-008: Vision Framework Integration

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Approved
**References**: ADR-013 (Vision Framework Strategy from Stage 2.0)

---

## Overview

This document specifies how the Abundance iOS app uses Apple's Vision Framework for on-device object detection and barcode scanning (Layer 1 of the 4-layer AI pipeline).

---

## 1. Object Detection (VNCoreMLRequest)

### Model: YOLOv3-Tiny (34 MB, on-device)

### Pattern:
```swift
import Vision
import CoreML

class VisionService {
    private var model: VNCoreMLModel?

    init() {
        do {
            let config = MLModelConfiguration()
            let yolo = try YOLOv3Tiny(configuration: config)
            model = try VNCoreMLModel(for: yolo.model)
        } catch {
            print("Failed to load Core ML model: \(error)")
        }
    }

    func detectObjects(in image: UIImage) async throws -> [DetectedObject] {
        guard let cgImage = image.cgImage, let model = model else {
            throw VisionError.invalidInput
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let objects = results.compactMap { observation -> DetectedObject? in
                    guard observation.confidence > 0.5 else { return nil }
                    return DetectedObject(
                        label: observation.labels.first?.identifier ?? "unknown",
                        confidence: observation.confidence,
                        boundingBox: observation.boundingBox
                    )
                }

                continuation.resume(returning: objects)
            }

            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}

struct DetectedObject {
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}
```

---

## 2. Barcode Scanning (VNDetectBarcodesRequest)

### Symbologies: 24 supported (UPC-A, EAN-13, QR Code, Code 128, etc.)

### Pattern:
```swift
func detectBarcodes(in image: UIImage) async throws -> [String] {
    guard let cgImage = image.cgImage else {
        throw VisionError.invalidInput
    }

    return try await withCheckedThrowingContinuation { continuation in
        let request = VNDetectBarcodesRequest { request, error in
            if let error = error {
                continuation.resume(throwing: error)
                return
            }

            guard let results = request.results as? [VNBarcodeObservation] else {
                continuation.resume(returning: [])
                return
            }

            let barcodes = results.compactMap { $0.payloadStringValue }
            continuation.resume(returning: barcodes)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}
```

---

## 3. Image Cropping (Bounding Box → UIImage)

### Pattern:
```swift
func cropImage(_ image: UIImage, boundingBox: CGRect) -> UIImage {
    let imageSize = image.size
    let x = boundingBox.origin.x * imageSize.width
    let y = (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height
    let width = boundingBox.width * imageSize.width
    let height = boundingBox.height * imageSize.height

    let cropRect = CGRect(x: x, y: y, width: width, height: height)

    guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
        return image
    }

    return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
}
```

---

## 4. ViewModel Integration

### CameraViewModel:
```swift
@MainActor
class CameraViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var detectedObjects: [DetectedObject] = []
    @Published var barcodes: [String] = []
    @Published var error: Error?

    private let visionService: VisionService

    init(visionService: VisionService = VisionService()) {
        self.visionService = visionService
    }

    func processCapturedImage(_ image: UIImage) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            // Step 1: Detect objects
            detectedObjects = try await visionService.detectObjects(in: image)

            // Step 2: Detect barcodes
            barcodes = try await visionService.detectBarcodes(in: image)
        } catch {
            self.error = error
        }
    }
}
```

---

## Performance Targets

- **Object Detection**: < 500ms (on iPhone 15 Pro, A17 Pro Neural Engine)
- **Barcode Scanning**: < 100ms
- **Cropping**: < 50ms

---

## References

- **ADR-013**: Vision Framework Strategy (from Stage 2.0)
- **TECH-STACK-MAP-001**: iOS stack (Vision, Core ML, YOLOv3-Tiny)

---

**Status**: ✅ Approved

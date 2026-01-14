import XCTest
import Vision
import CoreML
@preconcurrency import CoreVideo
@testable import VisionCore
@testable import CameraFeature

/// Manual test to run detection on example image and print confidence/quality scores
/// Usage: swift test --filter testDetectHouseholdItemsInExampleImage
final class TestHouseholdItemDetection: XCTestCase {

    func testDetectHouseholdItemsInExampleImage() async throws {
        print("\n========================================")
        print("Testing Household Item Detection")
        print("========================================\n")

        // Load test image
        let imagePath = "/Users/w/code/abundance-mvp/docs/design/examples/real-time-detection-ux/test-household-item.jpg"

        #if os(iOS)
        guard let image = UIImage(contentsOfFile: imagePath) else {
            XCTFail("Failed to load test image at: \(imagePath)")
            return
        }
        #elseif os(macOS)
        guard let image = NSImage(contentsOfFile: imagePath) else {
            XCTFail("Failed to load test image at: \(imagePath)")
            return
        }
        #endif

        print("✅ Loaded test image: \(imagePath)")
        print("   Image size: \(image.size.width) x \(image.size.height)\n")

        // Create real detector (not mock)
        let detector = HouseholdItemDetector()
        let qualityAssessor = ImageQualityAssessor()

        // Convert to pixel buffer
        guard let pixelBuffer = try? createPixelBuffer(from: image) else {
            XCTFail("Failed to convert image to pixel buffer")
            return
        }

        print("🔍 Running YOLO11n detection...")
        print("   (Shows ALL objects detected, not just 'household items')\n")

        // Run detection
        let results = try await detector.detectInStream(pixelBuffer: pixelBuffer)

        print("📊 Detection Results:")
        print("   Found \(results.count) object(s)")
        print("   NOTE: detectInStream returns ALL COCO classes (80 total)")
        print("         No filtering by 'household' category\n")

        // Process each detected object
        for (index, result) in results.enumerated() {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("Object \(index + 1): \(result.label)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            // YOLO Confidence
            print("\n1️⃣  YOLO Confidence:")
            print("   Score: \(String(format: "%.2f", result.confidence * 100))%")
            print("   Threshold for automatic: ≥70%")
            print("   Threshold for manual: ≥40%")

            let confidenceStatus = result.confidence >= 0.70 ? "✅ AUTOMATIC" :
                                   result.confidence >= 0.40 ? "⚠️  MANUAL" :
                                   "❌ IGNORE"
            print("   Status: \(confidenceStatus)")

            // Quality Assessment
            print("\n2️⃣  Quality Assessment:")
            let quality = await qualityAssessor.assess(
                pixelBuffer: pixelBuffer,
                boundingBox: result.boundingBox
            )
            print("   Composite Score: \(String(format: "%.2f", quality * 100))%")
            print("   Threshold for automatic: ≥65%")

            let qualityStatus = quality >= 0.65 ? "✅ HIGH QUALITY" : "⚠️  LOW QUALITY"
            print("   Status: \(qualityStatus)")

            // Catalog Mode
            print("\n3️⃣  Catalog Mode Decision:")
            let catalogMode = determineCatalogMode(confidence: result.confidence, quality: quality)

            switch catalogMode {
            case .automatic:
                print("   Mode: 🟢 AUTOMATIC")
                print("   Action: Upload immediately to GCS + create Firestore doc")
                print("   UI: Mint green border + sparkle animation")
            case .manual:
                print("   Mode: 🟡 MANUAL")
                print("   Action: Show grey border, wait for double-tap")
                print("   Upload: Only when user double-taps")
            case .ignore:
                print("   Mode: 🔴 IGNORE")
                print("   Action: Don't show this object (confidence too low)")
            }

            // Bounding Box
            print("\n4️⃣  Bounding Box (normalized 0-1):")
            print("   X: \(String(format: "%.3f", result.boundingBox.origin.x))")
            print("   Y: \(String(format: "%.3f", result.boundingBox.origin.y))")
            print("   Width: \(String(format: "%.3f", result.boundingBox.width))")
            print("   Height: \(String(format: "%.3f", result.boundingBox.height))")

            // Alternative labels
            if !result.alternativeLabels.isEmpty {
                print("\n5️⃣  Alternative Classifications:")
                for (altIndex, alt) in result.alternativeLabels.enumerated() {
                    print("   \(altIndex + 1). \(alt.label) (\(String(format: "%.1f", alt.confidence * 100))%)")
                }
            }

            print("\n")
        }

        print("========================================")
        print("Test Complete")
        print("========================================\n")
    }

    /// Test showing ALL raw YOLO detections including those below 40% threshold
    /// This reveals what the mouse was detected as (if at all)
    func testShowAllRawYOLODetections() async throws {
        print("\n========================================")
        print("ALL Raw YOLO Detections (No Filtering)")
        print("========================================\n")

        // Load test image
        let imagePath = "/Users/w/code/abundance-mvp/docs/design/examples/real-time-detection-ux/test-household-item.jpg"

        #if os(iOS)
        guard let image = UIImage(contentsOfFile: imagePath) else {
            XCTFail("Failed to load test image")
            return
        }
        #elseif os(macOS)
        guard let image = NSImage(contentsOfFile: imagePath) else {
            XCTFail("Failed to load test image")
            return
        }
        #endif

        guard let pixelBuffer = try? createPixelBuffer(from: image) else {
            XCTFail("Failed to convert image to pixel buffer")
            return
        }

        print("✅ Loaded test image: \(imagePath)")
        print("   Image size: \(image.size.width) x \(image.size.height)\n")

        // Load YOLO model directly
        guard let modelURL = Bundle.module.url(forResource: "yolo11n", withExtension: "mlmodelc"),
              let mlModel = try? MLModel(contentsOf: modelURL),
              let visionModel = try? VNCoreMLModel(for: mlModel) else {
            XCTFail("Failed to load YOLO model")
            return
        }

        print("🔍 Running raw YOLO11n with NO confidence threshold...\n")

        // Create request with NO confidence filtering
        let allDetections = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[(String, Float, CGRect, [(String, Float)])], Error>) in
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                // Convert to sendable tuple immediately
                let sendableResults = results.map { observation -> (String, Float, CGRect, [(String, Float)]) in
                    let topLabel = observation.labels.first?.identifier ?? "unknown"
                    let confidence = observation.labels.first?.confidence ?? 0
                    let bbox = observation.boundingBox
                    let alternatives = observation.labels.dropFirst().prefix(5).map { ($0.identifier, $0.confidence) }
                    return (topLabel, confidence, bbox, Array(alternatives))
                }

                continuation.resume(returning: sendableResults)
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }

        print("📊 Raw Detection Results:")
        print("   Total objects detected: \(allDetections.count)\n")

        // Show ALL detections sorted by confidence
        let sortedDetections = allDetections.sorted { $0.1 > $1.1 }

        for (index, detection) in sortedDetections.enumerated() {
            let (label, confidenceFloat, bbox, alternatives) = detection

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("Object \(index + 1): \(label)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            let confidence = Double(confidenceFloat)
            print("\n📈 Confidence: \(String(format: "%.2f", confidence * 100))%")

            // Determine what would happen
            if confidence >= 0.70 {
                print("   → Would be AUTOMATIC catalog candidate (if quality ≥ 65%)")
            } else if confidence >= 0.40 {
                print("   → Would be MANUAL catalog (grey border, wait for double-tap)")
            } else {
                print("   → Would be IGNORED (below 40% threshold)")
            }

            // Bounding box
            print("\n📍 Bounding Box:")
            print("   X: \(String(format: "%.3f", bbox.origin.x))")
            print("   Y: \(String(format: "%.3f", bbox.origin.y))")
            print("   Width: \(String(format: "%.3f", bbox.width))")
            print("   Height: \(String(format: "%.3f", bbox.height))")

            // Alternative labels
            if !alternatives.isEmpty {
                print("\n🔀 Alternative Labels:")
                for (altLabel, altConf) in alternatives {
                    print("   • \(altLabel): \(String(format: "%.2f", Double(altConf) * 100))%")
                }
            }

            print("\n")
        }

        print("========================================")
        print("Raw Detection Complete")
        print("========================================\n")
    }

    // MARK: - Helpers

    private func determineCatalogMode(confidence: Double, quality: Double) -> CatalogMode {
        if confidence < 0.40 {
            return .ignore
        }

        if confidence >= 0.70 && quality >= 0.65 {
            return .automatic
        }

        return .manual
    }

    private func createPixelBuffer(from image: PlatformImage) throws -> CVPixelBuffer {
        #if os(iOS)
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No CGImage"])
        }
        #elseif os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No CGImage"])
        }
        #endif

        let width = cgImage.width
        let height = cgImage.height

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferCGImageCompatibilityKey: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true
            ] as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"])
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create context"])
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }
}

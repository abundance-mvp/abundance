import Foundation
import Vision
import CoreML
@preconcurrency import CoreVideo
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Production-ready household item detector using Vision Framework + YOLOv3-Tiny
/// - Note: YOLOv3-Tiny.mlmodel download deferred to Sprint 3
public final class HouseholdItemDetector: HouseholdItemDetectorProtocol {

    // MARK: - Properties

    private let confidenceThreshold: Float = 0.6

    /// Household-relevant COCO classes (18 of 80 classes)
    /// Source: RESEARCH-003-layer-1-household-item-detection.md
    private static let householdClasses: Set<String> = [
        "backpack", "handbag", "suitcase", "umbrella",
        "bottle", "cup", "fork", "knife", "spoon", "bowl", "wine glass",
        "chair", "bed", "dining table",
        "tie", "couch", "potted plant", "toilet"
    ]

    // MARK: - Initialization

    public init() {}

    // MARK: - Detection

    public func detectHouseholdItems(in image: PlatformImage) async throws -> [HouseholdItem] {
        // Platform bridging: Convert to CGImage for Vision Framework
        #if os(iOS)
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }
        #elseif os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw VisionError.invalidImage
        }
        #endif

        // Load YOLOv11n CoreML model (5.2 MB, trained on COCO 80 classes)
        // YOLOv11n includes built-in NMS and outputs VNRecognizedObjectObservation
        // which Vision Framework can use directly without custom post-processing.
        guard let modelURL = Bundle.module.url(forResource: "yolo11n", withExtension: "mlmodelc") else {
            throw VisionError.modelNotFound
        }

        let model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))

        // Create Vision request
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: VisionError.requestFailed(error))
                    return
                }

                // Process results
                // YOLOv11n outputs VNRecognizedObjectObservation with built-in NMS
                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                // Filter by household classes and confidence threshold
                let imageWidth = cgImage.width
                let imageHeight = cgImage.height
                let householdItems: [HouseholdItem] = results.compactMap { observation -> HouseholdItem? in
                    guard let topLabel = observation.labels.first,
                          Self.householdClasses.contains(topLabel.identifier),
                          topLabel.confidence >= self.confidenceThreshold else {
                        return nil
                    }

                    return HouseholdItem(
                        label: topLabel.identifier,
                        confidence: ConfidenceScore(raw: topLabel.confidence),
                        boundingBox: observation.boundingBox,
                        imageSize: CGSize(width: imageWidth, height: imageHeight)
                    )
                }

                continuation.resume(returning: Array(householdItems))
            }

            // Perform detection
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VisionError.requestFailed(error))
            }
        }
    }

    // MARK: - Real-time Stream Detection

    /// Detects objects in a real-time video frame from CVPixelBuffer
    /// Optimized for streaming pipeline with lower confidence threshold
    /// - Parameter pixelBuffer: CVPixelBuffer from camera frame
    /// - Returns: Array of raw YOLO detection results with alternative labels
    /// - Throws: VisionError if detection fails
    public func detectInStream(pixelBuffer: CVPixelBuffer) async throws -> [YOLOResult] {
        // Load YOLOv11n CoreML model
        guard let modelURL = Bundle.module.url(forResource: "yolo11n", withExtension: "mlmodelc") else {
            throw VisionError.modelNotFound
        }

        let model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))

        // Create Vision request with lower confidence threshold for real-time
        // Real-time uses 0.40 (vs 0.60 for single-photo) to catch more objects
        // Quality filtering happens later in the pipeline
        let streamConfidenceThreshold: Float = 0.40

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: VisionError.requestFailed(error))
                    return
                }

                // Process results - YOLOv11n outputs VNRecognizedObjectObservation
                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                // Convert to YOLOResult with alternative labels
                let yoloResults: [YOLOResult] = results.compactMap { observation -> YOLOResult? in
                    guard let topLabel = observation.labels.first,
                          topLabel.confidence >= streamConfidenceThreshold else {
                        return nil
                    }

                    // Collect top 3 alternative labels (excluding primary)
                    let alternatives = observation.labels
                        .dropFirst() // Skip primary label
                        .prefix(3) // Take top 3 alternatives
                        .map { AlternativeLabel(label: $0.identifier, confidence: Double($0.confidence)) }

                    return YOLOResult(
                        label: topLabel.identifier,
                        confidence: Double(topLabel.confidence),
                        boundingBox: observation.boundingBox,
                        alternativeLabels: Array(alternatives)
                    )
                }

                continuation.resume(returning: yoloResults)
            }

            // Perform detection on pixel buffer
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VisionError.requestFailed(error))
            }
        }
    }
}

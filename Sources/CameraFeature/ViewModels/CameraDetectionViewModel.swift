import Foundation
import SwiftUI
@preconcurrency import CoreVideo
import VisionCore
import os.log

/// MainActor-bound ViewModel managing real-time object detection state
/// Orchestrates the detection pipeline: YOLO → quality assessment → deduplication → masking
@MainActor
public final class CameraDetectionViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Currently detected objects displayed with borders
    @Published public var detectedObjects: [DetectedObject] = []

    /// True when processing a frame (throttles UI updates)
    @Published public var isProcessing: Bool = false

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.abundance.camerafeature", category: "CameraDetectionViewModel")

    /// YOLO detector for object recognition
    private let yoloDetector: HouseholdItemDetectorProtocol

    /// Quality assessor for composite quality scoring
    private let qualityAssessor: ImageQualityAssessorProtocol

    /// Deduplicator for preventing duplicate detections
    private let deduplicator: ObjectDeduplicatorProtocol

    /// Mask generator for organic borders
    private let maskGenerator: SubjectMaskGeneratorProtocol

    // Confidence and quality thresholds
    private let automaticConfidenceThreshold: Double = 0.70
    private let manualConfidenceThreshold: Double = 0.40
    private let automaticQualityThreshold: Double = 0.65

    // MARK: - Initialization

    public init(
        yoloDetector: HouseholdItemDetectorProtocol,
        qualityAssessor: ImageQualityAssessorProtocol,
        deduplicator: ObjectDeduplicatorProtocol,
        maskGenerator: SubjectMaskGeneratorProtocol
    ) {
        self.yoloDetector = yoloDetector
        self.qualityAssessor = qualityAssessor
        self.deduplicator = deduplicator
        self.maskGenerator = maskGenerator
    }

    // MARK: - Frame Processing Pipeline

    /// Process a single camera frame through the detection pipeline
    /// - Parameter pixelBuffer: CVPixelBuffer from camera capture
    /// - Note: Runs at 2 FPS (throttled by caller), processes objects in parallel
    nonisolated public func processFrame(_ pixelBuffer: CVPixelBuffer) async {
        let shouldSkip = await MainActor.run { isProcessing }
        guard !shouldSkip else {
            logger.debug("Skipping frame: already processing")
            return
        }

        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }

        do {
            // Step 1: YOLO detection
            let yoloResults = try await yoloDetector.detectInStream(pixelBuffer: pixelBuffer)

            logger.debug("YOLO detected \(yoloResults.count) objects")

            // Step 2: Process objects in parallel
            let processedObjects = await withTaskGroup(of: DetectedObject?.self) { group in
                for yoloResult in yoloResults {
                    group.addTask {
                        await self.processObject(yoloResult, in: pixelBuffer)
                    }
                }

                var results: [DetectedObject] = []
                for await object in group {
                    if let object = object {
                        results.append(object)
                    }
                }
                return results
            }

            // Step 3: Update UI with detected objects
            await MainActor.run {
                detectedObjects = processedObjects
            }

            logger.debug("Pipeline complete: \(processedObjects.count) objects ready for display")

        } catch {
            logger.error("Frame processing failed: \(error.localizedDescription)")
            await MainActor.run {
                detectedObjects = []
            }
        }
    }

    // MARK: - Object Processing

    /// Process a single YOLO result through quality, deduplication, and masking
    /// - Parameters:
    ///   - yoloResult: Raw YOLO detection result
    ///   - pixelBuffer: Original frame for quality/mask generation
    /// - Returns: Complete DetectedObject or nil if filtered out
    nonisolated private func processObject(_ yoloResult: YOLOResult, in pixelBuffer: CVPixelBuffer) async -> DetectedObject? {
        let boundingBox = yoloResult.boundingBox

        // Step 1: Check for duplicates
        let isDuplicate = await deduplicator.isSimilarToRecent(
            pixelBuffer: pixelBuffer,
            boundingBox: boundingBox
        )

        if isDuplicate {
            logger.debug("Object '\(yoloResult.label)' is duplicate, skipping")
            return nil
        }

        // Step 2: Assess quality
        let qualityScore = await qualityAssessor.assess(
            pixelBuffer: pixelBuffer,
            boundingBox: boundingBox
        )

        // Step 3: Determine catalog mode
        let catalogMode = determineCatalogMode(
            confidence: yoloResult.confidence,
            quality: qualityScore
        )

        // Filter out ignored objects
        guard catalogMode != .ignore else {
            logger.debug("Object '\(yoloResult.label)' ignored (confidence: \(yoloResult.confidence))")
            return nil
        }

        // Step 4: Generate subject mask for organic borders
        let mask = await maskGenerator.generateMask(
            pixelBuffer: pixelBuffer,
            boundingBox: boundingBox
        )

        // Step 5: Generate fingerprint and cache it
        guard let fingerprint = await deduplicator.generateFingerprint(
            pixelBuffer: pixelBuffer,
            boundingBox: boundingBox
        ) else {
            logger.warning("Failed to generate fingerprint for '\(yoloResult.label)'")
            return nil
        }

        // Cache fingerprint to prevent future duplicates
        await deduplicator.addToCache(fingerprint)

        // Step 6: Create DetectedObject
        let detectedObject = DetectedObject(
            label: yoloResult.label,
            confidence: yoloResult.confidence,
            boundingBox: boundingBox,
            qualityScore: qualityScore,
            catalogMode: catalogMode,
            mask: mask,
            fingerprint: fingerprint,
            alternativeLabels: yoloResult.alternativeLabels
        )

        logger.debug("Processed '\(yoloResult.label)': confidence=\(yoloResult.confidence), quality=\(qualityScore), mode=\(String(describing: catalogMode))")

        return detectedObject
    }

    // MARK: - Catalog Mode Logic

    /// Determines catalog mode based on confidence and quality scores
    /// - Parameters:
    ///   - confidence: YOLO confidence score (0.0-1.0)
    ///   - quality: Composite quality score (0.0-1.0)
    /// - Returns: CatalogMode (automatic/manual/ignore)
    nonisolated private func determineCatalogMode(confidence: Double, quality: Double) -> CatalogMode {
        // Ignore: confidence too low
        if confidence < manualConfidenceThreshold {
            return .ignore
        }

        // Automatic: high confidence AND high quality
        if confidence >= automaticConfidenceThreshold && quality >= automaticQualityThreshold {
            return .automatic
        }

        // Manual: medium confidence OR low quality
        return .manual
    }

    // MARK: - User Interactions

    /// Handle double-tap gesture to manually catalog an object
    /// - Parameter location: Tap location in normalized coordinates (0.0-1.0)
    public func handleDoubleTap(at location: CGPoint) async {
        logger.debug("Double-tap at location: \(String(describing: location))")

        // Find object at tap location
        guard let tappedObject = findObject(at: location) else {
            logger.debug("No object found at tap location")
            return
        }

        logger.info("Manual catalog triggered for '\(tappedObject.label)'")

        // Update catalog mode to manual (if not already)
        if let index = detectedObjects.firstIndex(where: { $0.id == tappedObject.id }) {
            detectedObjects[index].catalogMode = .manual
            // TODO: Trigger catalog upload in Stage 5
        }
    }

    /// Find detected object at a given location
    /// - Parameter location: Normalized coordinates (0.0-1.0)
    /// - Returns: DetectedObject if found, nil otherwise
    private func findObject(at location: CGPoint) -> DetectedObject? {
        return detectedObjects.first { object in
            object.boundingBox.contains(location)
        }
    }

    // MARK: - Public API for Testing

    /// Manually add a detected object (for testing)
    public func addObject(_ object: DetectedObject) {
        detectedObjects.append(object)
    }

    /// Clear all detected objects
    public func clearObjects() {
        detectedObjects = []
    }
}

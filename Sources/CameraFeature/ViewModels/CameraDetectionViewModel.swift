import Foundation
import SwiftUI
import Combine
@preconcurrency import CoreVideo
import os.log
@preconcurrency import FirebaseAuth
import VisionCore
import Persistence

/// MainActor-bound ViewModel managing real-time object detection state
/// Orchestrates the detection pipeline: YOLO → quality assessment → deduplication → masking
@MainActor
public final class CameraDetectionViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Currently detected objects displayed with borders
    @Published public var detectedObjects: [DetectedObject] = []

    /// True when processing a frame (throttles UI updates)
    @Published public var isProcessing: Bool = false

    /// Upload error that can be observed by the view for UI feedback
    @Published public var uploadError: Error?

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

    // Storage and persistence services (optional for testing)
    private let storageService: StorageServiceProtocol?
    private let itemService: ItemRepository?

    // Confidence and quality thresholds
    private let automaticConfidenceThreshold: Double = 0.70
    private let manualConfidenceThreshold: Double = 0.40
    private let automaticQualityThreshold: Double = 0.65

    // MARK: - Frame Processing Subscription

    /// Subscription for camera frame processing (managed by ViewModel to fix Swift 6 compliance)
    private var frameSubscription: AnyCancellable?

    // MARK: - Initialization

    public init(
        yoloDetector: HouseholdItemDetectorProtocol,
        qualityAssessor: ImageQualityAssessorProtocol,
        deduplicator: ObjectDeduplicatorProtocol,
        maskGenerator: SubjectMaskGeneratorProtocol,
        storageService: StorageServiceProtocol? = StorageService(),
        itemService: ItemRepository? = ItemService()
    ) {
        self.yoloDetector = yoloDetector
        self.qualityAssessor = qualityAssessor
        self.deduplicator = deduplicator
        self.maskGenerator = maskGenerator
        self.storageService = storageService
        self.itemService = itemService
    }

    // MARK: - Frame Processing Pipeline

    /// Process a single camera frame through the detection pipeline
    /// - Parameter pixelBuffer: CVPixelBuffer from camera capture (read-only, thread-safe)
    /// - Note: Runs at 2 FPS (throttled by caller), processes objects in parallel
    nonisolated public func processFrame(_ pixelBuffer: CVPixelBuffer) async {
        let shouldSkip = await MainActor.run { isProcessing }
        guard !shouldSkip else {
            logger.debug("Skipping frame: already processing")
            return
        }

        await MainActor.run { isProcessing = true }

        do {
            // Step 1: YOLO detection
            let yoloResults = try await yoloDetector.detectInStream(pixelBuffer: pixelBuffer)

            logger.debug("YOLO detected \(yoloResults.count) objects")

            // Step 2: Process objects in parallel
            // Note: CVPixelBuffer is thread-safe for reading (immutable after creation)
            // Process sequentially to avoid Swift 6 concurrency issues with parallel tasks
            var processedObjects: [DetectedObject] = []
            for yoloResult in yoloResults {
                if let object = await processObject(yoloResult, in: pixelBuffer) {
                    processedObjects.append(object)
                }
            }

            // Step 3: Update UI with detected objects
            let previousObjects = await MainActor.run { detectedObjects }
            await MainActor.run {
                detectedObjects = processedObjects
            }

            // Step 4: Upload new automatic catalog objects
            for object in processedObjects where object.catalogMode == .automatic {
                if !previousObjects.contains(where: { $0.id == object.id }) {
                    await uploadObject(object, pixelBuffer: pixelBuffer)
                }
            }

            logger.debug("Pipeline complete: \(processedObjects.count) objects ready for display")

            // Clear processing flag using structured concurrency (not defer with Task)
            await MainActor.run { isProcessing = false }

        } catch {
            logger.error("Frame processing failed: \(error.localizedDescription)")
            await MainActor.run {
                detectedObjects = []
                isProcessing = false
            }
        }
    }

    // MARK: - Object Processing

    /// Process a single YOLO result through quality, deduplication, and masking
    /// - Parameters:
    ///   - yoloResult: Raw YOLO detection result
    ///   - pixelBuffer: Original frame for quality/mask generation (read-only, thread-safe)
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

    /// Upload detected object to trigger Layer 1→2 catalog pipeline
    /// - Parameters:
    ///   - object: DetectedObject to upload
    ///   - pixelBuffer: Source pixel buffer for cropping (passed directly to avoid data race)
    private func uploadObject(_ object: DetectedObject, pixelBuffer: CVPixelBuffer) async {
        guard let storageService = storageService,
              let itemService = itemService,
              let userId = Auth.auth().currentUser?.uid else {
            logger.warning("Upload skipped: missing services or auth")
            return
        }

        do {
            // Crop image from pixel buffer
            let croppedImage = try PixelBufferCropper.cropImage(
                from: pixelBuffer,
                boundingBox: object.boundingBox
            )

            // Upload to GCS
            let imageUrl = try await storageService.uploadCroppedObject(
                croppedImage,
                itemId: object.id.uuidString,
                userId: userId
            )

            // Create Firestore document (triggers Layer 2a/2b/3)
            try await itemService.createItemWithLayer1Metadata(
                itemId: object.id.uuidString,
                userId: userId,
                imageUrl: imageUrl.absoluteString,
                layer1Metadata: Layer1Metadata(
                    detectedClass: object.label,
                    confidence: object.confidence,
                    boundingBox: object.boundingBox,
                    qualityScore: object.qualityScore
                )
            )

            logger.info("Uploaded \(object.label) → Layer 2 pipeline: \(imageUrl.absoluteString)")
        } catch {
            logger.error("Upload failed: \(error.localizedDescription)")
            await MainActor.run {
                uploadError = error
            }
        }
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

        // Update catalog mode to automatic (user confirmed via double-tap)
        if let index = detectedObjects.firstIndex(where: { $0.id == tappedObject.id }) {
            detectedObjects[index].catalogMode = .automatic
            // Note: Upload will occur on next frame processing cycle when object is re-detected
            // with automatic mode. Direct upload removed to fix CVPixelBuffer data race (P0 issue).
            logger.info("Object marked for automatic catalog - will upload on next detection cycle")
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

    /// Clear the upload error state
    public func clearUploadError() {
        uploadError = nil
    }

    // MARK: - Frame Processing Lifecycle

    /// Start processing frames from a camera service's frame publisher
    /// - Parameter framePublisher: Publisher emitting CVPixelBuffer frames from camera
    /// - Note: Manages subscription lifecycle internally to comply with Swift 6 (no @State with reference types)
    public func startFrameProcessing(from framePublisher: AnyPublisher<CVPixelBuffer, Never>) {
        // Cancel any existing subscription
        frameSubscription?.cancel()

        // Wire frame loop at 2 FPS (throttle to 500ms)
        frameSubscription = framePublisher
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] pixelBuffer in
                guard let self else { return }
                Task {
                    await self.processFrame(pixelBuffer)
                }
            }
    }

    /// Stop processing frames and clean up subscription
    public func stopFrameProcessing() {
        frameSubscription?.cancel()
        frameSubscription = nil
    }
}

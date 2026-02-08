import Foundation
import CoreML
@preconcurrency import CoreVideo
import QuartzCore
import os.log

#if os(iOS)
import UIKit
#endif

/// Actor-isolated CoreML inference service for EdgeTAM segmentation.
///
/// Wraps 3 CoreML models (image encoder, prompt encoder, mask decoder).
/// Uses encode-once/decode-on-tap strategy:
/// - Image encoder runs on keyframes (~60-900ms, the bottleneck)
/// - Prompt encoder + mask decoder run per tap (~5-15ms, feels instant)
///
/// Thread Safety: Actor isolation ensures all model access is serialized.
public actor EdgeTAMService: @preconcurrency EdgeTAMServiceProtocol {

    // MARK: - Properties

    private let configuration: EdgeTAMConfiguration
    private let logger = Logger(subsystem: "com.abundance.edgetam", category: "EdgeTAMService")

    private var imageEncoder: MLModel?
    private var promptEncoder: MLModel?
    private var maskDecoder: MLModel?

    /// Cached image features from the most recent encodeFrame() call.
    /// Key = feature token (UUID string), Value = MLMultiArray features.
    private var featureCache: [String: MLMultiArray] = [:]

    /// Maximum cached features to prevent memory pressure
    private let maxCachedFeatures = 3

    /// Task for monitoring memory pressure notifications
    private var memoryMonitorTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(configuration: EdgeTAMConfiguration = .default) {
        self.configuration = configuration
    }

    deinit {
        memoryMonitorTask?.cancel()
    }

    // MARK: - Public API

    public var isLoaded: Bool {
        imageEncoder != nil && promptEncoder != nil && maskDecoder != nil
    }

    public func warmup() async throws {
        let startTime = CACurrentMediaTime()
        let config = MLModelConfiguration()
        config.computeUnits = .all // CPU + GPU + Neural Engine

        guard let encoderURL = Bundle.module.url(
            forResource: configuration.imageEncoderName,
            withExtension: "mlmodelc"
        ) else {
            throw SweepError.modelLoadFailed("Image encoder not found in bundle")
        }

        guard let promptURL = Bundle.module.url(
            forResource: configuration.promptEncoderName,
            withExtension: "mlmodelc"
        ) else {
            throw SweepError.modelLoadFailed("Prompt encoder not found in bundle")
        }

        guard let decoderURL = Bundle.module.url(
            forResource: configuration.maskDecoderName,
            withExtension: "mlmodelc"
        ) else {
            throw SweepError.modelLoadFailed("Mask decoder not found in bundle")
        }

        imageEncoder = try MLModel(contentsOf: encoderURL, configuration: config)
        promptEncoder = try MLModel(contentsOf: promptURL, configuration: config)
        maskDecoder = try MLModel(contentsOf: decoderURL, configuration: config)

        let loadTime = (CACurrentMediaTime() - startTime) * 1000
        logger.info("Models loaded in \(String(format: "%.0f", loadTime))ms")

        // Start monitoring memory pressure after models are loaded
        startMemoryMonitoring()
    }

    public func encodeFrame(_ pixelBuffer: CVPixelBuffer) async throws -> String {
        guard imageEncoder != nil else {
            throw SweepError.modelLoadFailed("Image encoder not loaded. Call warmup() first.")
        }

        let startTime = CACurrentMediaTime()

        // TODO: Task 0.1 — Resize pixelBuffer to 1024x1024 and normalize
        // TODO: Task 0.1 — Create MLFeatureProvider input from resized buffer
        // TODO: Task 0.1 — Run encoder.prediction(from: input)
        // TODO: Task 0.1 — Extract feature map MLMultiArray from output

        // Placeholder — replace with actual inference after model export
        let featureToken = UUID().uuidString

        // Evict arbitrary entry if cache is full
        if featureCache.count >= maxCachedFeatures {
            if let oldestKey = featureCache.keys.first {
                featureCache.removeValue(forKey: oldestKey)
            }
        }

        // TODO: Task 0.1 — Cache actual features
        // featureCache[featureToken] = outputFeatures

        let encodeTime = (CACurrentMediaTime() - startTime) * 1000
        logger.debug("Frame encoded in \(String(format: "%.0f", encodeTime))ms")

        return featureToken
    }

    public func decodeMask(at point: CGPoint, featureToken: String) async throws -> SegmentedObject {
        guard promptEncoder != nil, maskDecoder != nil else {
            throw SweepError.modelLoadFailed("Models not loaded. Call warmup() first.")
        }

        // TODO: Task 0.1 — Look up cached features for featureToken
        // TODO: Task 0.1 — Create prompt input from point coordinates
        // TODO: Task 0.1 — Run prompt encoder -> sparse + dense embeddings
        // TODO: Task 0.1 — Run mask decoder -> segmentation mask + IoU score
        // TODO: Task 0.1 — Convert mask to SegmentedObject

        // Placeholder — replace with actual inference after model export
        return SegmentedObject(
            boundingBox: CGRect(
                x: max(0, point.x - 0.1),
                y: max(0, point.y - 0.1),
                width: min(0.2, 1.0 - max(0, point.x - 0.1)),
                height: min(0.2, 1.0 - max(0, point.y - 0.1))
            ),
            iouScore: 0.0
        )
    }

    public func autoSegment(featureToken: String) async throws -> [SegmentedObject] {
        var segments: [SegmentedObject] = []

        let rows = configuration.gridRows
        let cols = configuration.gridColumns

        for row in 0..<rows {
            for col in 0..<cols {
                let point = CGPoint(
                    x: (Double(col) + 0.5) / Double(cols),
                    y: (Double(row) + 0.5) / Double(rows)
                )

                do {
                    let segment = try await decodeMask(at: point, featureToken: featureToken)
                    if segment.iouScore > 0.5 {
                        segments.append(segment)
                    }
                } catch {
                    continue
                }
            }
        }

        return segments
    }

    public func unload() async {
        memoryMonitorTask?.cancel()
        memoryMonitorTask = nil
        imageEncoder = nil
        promptEncoder = nil
        maskDecoder = nil
        featureCache.removeAll()
        logger.info("Models unloaded")
    }

    // MARK: - Memory Pressure

    /// Register for memory warnings to proactively manage cache
    /// Call this after warmup() to start monitoring
    public func startMemoryMonitoring() {
        #if os(iOS)
        // Cancel any existing monitor before creating a new one
        memoryMonitorTask?.cancel()

        // Use nonisolated closure to observe notification, then hop to actor
        let taskRef = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: UIApplication.didReceiveMemoryWarningNotification
            )
            for await _ in notifications {
                guard let self else { break }
                await self.handleMemoryWarning()
            }
        }
        // Store task reference to cancel on unload
        memoryMonitorTask = taskRef
        #endif
    }

    /// Handle memory warning by clearing caches
    private func handleMemoryWarning() {
        logger.warning("Memory warning received — clearing feature cache (\(self.featureCache.count) entries)")
        featureCache.removeAll()
        // Keep models loaded — only clear cache
        // If a second warning comes, the system will terminate us anyway
    }
}

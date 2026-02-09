import Foundation
import CoreML
@preconcurrency import CoreVideo
@preconcurrency import CoreImage
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

    /// MLModel is thread-safe for prediction calls but not Sendable.
    /// Actor isolation + nonisolated(unsafe) is the same pattern used by
    /// SessionService for Firestore. All access is serialized by the actor.
    nonisolated(unsafe) private var imageEncoder: MLModel?
    nonisolated(unsafe) private var promptEncoder: MLModel?
    nonisolated(unsafe) private var maskDecoder: MLModel?

    /// Cached image features from the most recent encodeFrame() call.
    /// Key = feature token (UUID string), Value = encoded features.
    private var featureCache: [String: EncodedFeatures] = [:]

    /// Maximum cached features to prevent memory pressure
    private let maxCachedFeatures = 3

    /// Task for monitoring memory pressure notifications
    private var memoryMonitorTask: Task<Void, Never>?

    /// CIContext for pixel buffer operations (reused to avoid allocation overhead)
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - Feature Cache Entry

    /// Cached output from the image encoder for a single keyframe
    private struct EncodedFeatures {
        let visionFeatures: MLMultiArray   // (1, 256, 64, 64)
        let highResFeat0: MLMultiArray     // (1, 32, 256, 256)
        let highResFeat1: MLMultiArray     // (1, 64, 128, 128)
    }

    // MARK: - Initialization

    public init(configuration: EdgeTAMConfiguration = .default) {
        self.configuration = configuration
    }

    // Safe to access actor-isolated `memoryMonitorTask` from deinit:
    // deinit runs only after all strong references are gone, so no concurrent
    // access is possible. The Task holds only a [weak self] reference, so it
    // does not prevent deinit from firing.
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
        guard let encoder = imageEncoder else {
            throw SweepError.modelLoadFailed("Image encoder not loaded. Call warmup() first.")
        }

        let startTime = CACurrentMediaTime()

        // Resize pixel buffer to 1024x1024 for the encoder
        let resizedBuffer = try resizePixelBuffer(pixelBuffer, to: CGSize(width: 1024, height: 1024))

        // Create input using CoreML's ImageType (matches export: scale=1/255, RGB)
        let imageFeature = MLFeatureValue(pixelBuffer: resizedBuffer)
        let input = try MLDictionaryFeatureProvider(dictionary: ["image": imageFeature])

        // Run encoder prediction (synchronous — actor serializes access)
        let output = try runPrediction(encoder, input: input)

        // Extract feature tensors
        guard let visionFeatures = output.featureValue(for: "vision_features")?.multiArrayValue,
              let highResFeat0 = output.featureValue(for: "high_res_feat_0")?.multiArrayValue,
              let highResFeat1 = output.featureValue(for: "high_res_feat_1")?.multiArrayValue else {
            throw SweepError.encoderFailed
        }

        let featureToken = UUID().uuidString

        // Evict oldest entry if cache is full
        if featureCache.count >= maxCachedFeatures {
            if let oldestKey = featureCache.keys.first {
                featureCache.removeValue(forKey: oldestKey)
            }
        }

        featureCache[featureToken] = EncodedFeatures(
            visionFeatures: visionFeatures,
            highResFeat0: highResFeat0,
            highResFeat1: highResFeat1
        )

        let encodeTime = (CACurrentMediaTime() - startTime) * 1000
        logger.debug("Frame encoded in \(String(format: "%.0f", encodeTime))ms")

        return featureToken
    }

    public func decodeMask(at point: CGPoint, featureToken: String) async throws -> SegmentedObject {
        guard let prompt = promptEncoder, let decoder = maskDecoder else {
            throw SweepError.modelLoadFailed("Models not loaded. Call warmup() first.")
        }

        guard let features = featureCache[featureToken] else {
            throw SweepError.decoderFailed
        }

        // Prepare prompt encoder inputs
        // point_coords: (1, 4, 2) — up to 4 points, first is our tap, rest are padding
        let pointCoords = try MLMultiArray(shape: [1, 4, 2], dataType: .float32)
        // Scale normalized point (0-1) to encoder input space (0-1024)
        pointCoords[[0, 0, 0] as [NSNumber]] = NSNumber(value: Float(point.x) * 1024.0)
        pointCoords[[0, 0, 1] as [NSNumber]] = NSNumber(value: Float(point.y) * 1024.0)
        // Padding points (0, 0)
        for i in 1..<4 {
            pointCoords[[0, i, 0] as [NSNumber]] = 0
            pointCoords[[0, i, 1] as [NSNumber]] = 0
        }

        // point_labels: (1, 4) — 1.0 = foreground, -1.0 = padding
        let pointLabels = try MLMultiArray(shape: [1, 4], dataType: .float32)
        pointLabels[[0, 0] as [NSNumber]] = 1.0   // foreground point
        pointLabels[[0, 1] as [NSNumber]] = -1.0   // padding
        pointLabels[[0, 2] as [NSNumber]] = -1.0   // padding
        pointLabels[[0, 3] as [NSNumber]] = -1.0   // padding

        // boxes: (1, 4) — no box prompt, all zeros
        let boxes = try MLMultiArray(shape: [1, 4], dataType: .float32)

        // mask_input: (1, 1, 256, 256) — no mask prompt, all zeros
        let maskInput = try MLMultiArray(shape: [1, 1, 256, 256], dataType: .float32)

        // Run prompt encoder
        let promptInput = try MLDictionaryFeatureProvider(dictionary: [
            "point_coords": MLFeatureValue(multiArray: pointCoords),
            "point_labels": MLFeatureValue(multiArray: pointLabels),
            "boxes": MLFeatureValue(multiArray: boxes),
            "mask_input": MLFeatureValue(multiArray: maskInput),
        ])

        let promptOutput = try runPrediction(prompt, input: promptInput)

        guard let sparseEmbeddings = promptOutput.featureValue(for: "sparse_embeddings")?.multiArrayValue,
              let denseEmbeddings = promptOutput.featureValue(for: "dense_embeddings")?.multiArrayValue else {
            throw SweepError.decoderFailed
        }

        // Run mask decoder
        // image_pe is not needed — it's computed inside the decoder wrapper
        let imagePE = try MLMultiArray(shape: [1, 256, 64, 64], dataType: .float32)

        // multimask_output: (1,) — false for single point prompt
        let multimaskOutput = try MLMultiArray(shape: [1], dataType: .float32)
        multimaskOutput[0] = 0.0 // single mask mode

        let decoderInput = try MLDictionaryFeatureProvider(dictionary: [
            "image_embeddings": MLFeatureValue(multiArray: features.visionFeatures),
            "image_pe": MLFeatureValue(multiArray: imagePE),
            "sparse_prompt_embeddings": MLFeatureValue(multiArray: sparseEmbeddings),
            "dense_prompt_embeddings": MLFeatureValue(multiArray: denseEmbeddings),
            "high_res_feat_0": MLFeatureValue(multiArray: features.highResFeat0),
            "high_res_feat_1": MLFeatureValue(multiArray: features.highResFeat1),
            "multimask_output": MLFeatureValue(multiArray: multimaskOutput),
        ])

        let decoderOutput = try runPrediction(decoder, input: decoderInput)

        guard let masks = decoderOutput.featureValue(for: "masks")?.multiArrayValue,
              let iouPred = decoderOutput.featureValue(for: "iou_pred")?.multiArrayValue else {
            throw SweepError.decoderFailed
        }

        return extractMaskData(masks: masks, iouPred: iouPred)
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
                    if segment.iouScore >= configuration.similarityThreshold {
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

    // MARK: - Prediction Helper

    /// Run prediction synchronously, bypassing actor isolation.
    /// MLModel is documented as thread-safe; actor serializes all callers.
    private nonisolated func runPrediction(
        _ model: MLModel,
        input: MLDictionaryFeatureProvider
    ) throws -> MLFeatureProvider {
        try model.prediction(from: input)
    }

    // MARK: - Frame Preprocessing

    /// Resize a CVPixelBuffer to the target size using CoreImage
    private func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer, to targetSize: CGSize) throws -> CVPixelBuffer {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        let sourceWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let sourceHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        let scaleX = targetSize.width / sourceWidth
        let scaleY = targetSize.height / sourceHeight

        let resized = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        var outputBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(targetSize.width),
            Int(targetSize.height),
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferCGImageCompatibilityKey: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            ] as CFDictionary,
            &outputBuffer
        )

        guard status == kCVReturnSuccess, let output = outputBuffer else {
            throw SweepError.encoderFailed
        }

        ciContext.render(resized, to: output)
        return output
    }

    // MARK: - Mask Data Extraction

    /// Convert mask decoder output to a SegmentedObject
    ///
    /// The mask decoder outputs:
    /// - masks: (1, 1, H, W) float32 — logits where > 0.0 is foreground
    /// - iou_pred: (1, 1) float32 — IoU quality score
    private func extractMaskData(masks: MLMultiArray, iouPred: MLMultiArray) -> SegmentedObject {
        let iouScore = iouPred[0].floatValue

        // Mask dimensions (typically 256x256 from decoder)
        let maskShape = masks.shape.map { $0.intValue }
        let maskH = maskShape.count >= 3 ? maskShape[maskShape.count - 2] : 256
        let maskW = maskShape.count >= 4 ? maskShape[maskShape.count - 1] : 256

        // Extract bounding box and binary mask from logits
        var minX = maskW, maxX = 0, minY = maskH, maxY = 0
        var maskBytes = Data(count: maskH * maskW)

        let totalMaskElements = maskH * maskW
        // Offset into the MLMultiArray for the first (and only) mask
        // Shape could be (1, 1, H, W) or (1, H, W) depending on multimask mode
        let baseOffset = masks.count - totalMaskElements

        for y in 0..<maskH {
            for x in 0..<maskW {
                let idx = baseOffset + y * maskW + x
                let logit = masks[idx].floatValue
                if logit > 0.0 {
                    maskBytes[y * maskW + x] = 255
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }

        // Compute normalized bounding box (0-1 range)
        let bbox: CGRect
        if maxX >= minX && maxY >= minY {
            bbox = CGRect(
                x: CGFloat(minX) / CGFloat(maskW),
                y: CGFloat(minY) / CGFloat(maskH),
                width: CGFloat(maxX - minX + 1) / CGFloat(maskW),
                height: CGFloat(maxY - minY + 1) / CGFloat(maskH)
            )
        } else {
            // No foreground pixels found
            bbox = .zero
        }

        return SegmentedObject(
            boundingBox: bbox,
            maskData: maskBytes,
            maskWidth: maskW,
            maskHeight: maskH,
            iouScore: iouScore
        )
    }

    // MARK: - Memory Pressure

    /// Register for memory warnings to proactively manage cache
    private func startMemoryMonitoring() {
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

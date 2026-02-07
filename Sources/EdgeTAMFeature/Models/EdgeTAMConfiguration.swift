import Foundation

/// Configuration for EdgeTAM CoreML model inference
public struct EdgeTAMConfiguration: Sendable {
    public let imageEncoderName: String
    public let promptEncoderName: String
    public let maskDecoderName: String
    public let keyframeInterval: TimeInterval
    public let gridRows: Int
    public let gridColumns: Int
    public let similarityThreshold: Float

    public var gridPromptCount: Int {
        gridRows * gridColumns
    }

    public static let `default` = EdgeTAMConfiguration(
        imageEncoderName: "edgetam_image_encoder",
        promptEncoderName: "edgetam_prompt_encoder",
        maskDecoderName: "edgetam_mask_decoder",
        keyframeInterval: 0.5,
        gridRows: 4,
        gridColumns: 4,
        similarityThreshold: 0.90
    )
}

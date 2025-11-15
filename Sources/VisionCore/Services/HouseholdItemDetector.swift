import Foundation
import Vision
import CoreML
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

        // TODO: Implement YOLOv3-Tiny Vision request in Sprint 3
        // For now, return empty array (structure complete, ML model integration deferred)

        // Placeholder for Sprint 2: Return empty array
        // Sprint 3 will implement:
        // 1. Load YOLOv3-Tiny.mlmodel (34 MB)
        // 2. Create VNCoreMLRequest with model
        // 3. Filter results by householdClasses
        // 4. Apply NMS (Non-Maximum Suppression)
        // 5. Convert VNRecognizedObjectObservation to HouseholdItem

        return []
    }
}

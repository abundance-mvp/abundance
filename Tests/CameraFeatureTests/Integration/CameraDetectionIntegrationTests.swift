import XCTest
import SwiftUI
import Combine
@testable import CameraFeature
@testable import VisionCore

@MainActor
final class CameraDetectionIntegrationTests: XCTestCase {

    var viewModel: CameraDetectionViewModel!
    var mockYOLO: MockHouseholdItemDetector!
    var mockQuality: MockImageQualityAssessor!
    var mockDeduplicator: MockObjectDeduplicator!
    var mockMaskGenerator: MockSubjectMaskGenerator!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        mockYOLO = MockHouseholdItemDetector()
        mockQuality = MockImageQualityAssessor()
        mockDeduplicator = MockObjectDeduplicator()
        mockMaskGenerator = MockSubjectMaskGenerator()

        viewModel = CameraDetectionViewModel(
            yoloDetector: mockYOLO,
            qualityAssessor: mockQuality,
            deduplicator: mockDeduplicator,
            maskGenerator: mockMaskGenerator,
            storageService: nil,  // Skip Firebase in tests
            itemService: nil      // Skip Firebase in tests
        )

        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        cancellables = nil
        viewModel = nil
        mockYOLO = nil
        mockQuality = nil
        mockDeduplicator = nil
        mockMaskGenerator = nil
    }

    func testDetectionPipelineUpdatesPublishedObjects() async throws {
        // Given: Mock pixel buffer and YOLO result
        let pixelBuffer = try createMockPixelBuffer()

        mockYOLO.stubbedYOLOResults = [
            YOLOResult(
                label: "backpack",
                confidence: 0.92,
                boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
                alternativeLabels: []
            )
        ]

        // When: Frame is processed
        await viewModel.processFrame(pixelBuffer)

        // Then: Detected objects are published (await ensures completion)
        XCTAssertEqual(viewModel.detectedObjects.count, 1)
        XCTAssertEqual(viewModel.detectedObjects.first?.label, "backpack")
        XCTAssertEqual(viewModel.detectedObjects.first?.catalogMode, .automatic)
    }

    func testAutomaticCatalogTriggersForHighConfidenceObjects() async throws {
        // Given: High confidence + quality object
        let pixelBuffer = try createMockPixelBuffer()

        mockYOLO.stubbedYOLOResults = [
            YOLOResult(
                label: "tent",
                confidence: 0.88,
                boundingBox: CGRect(x: 0.3, y: 0.4, width: 0.3, height: 0.4),
                alternativeLabels: []
            )
        ]

        await mockQuality.setQualityScore(0.75) // High quality

        // When: Frame is processed
        await viewModel.processFrame(pixelBuffer)

        // Then: Object has automatic catalog mode (await ensures completion)
        XCTAssertEqual(viewModel.detectedObjects.first?.catalogMode, .automatic)
    }

    func testManualCatalogForLowQualityObjects() async throws {
        // Given: Medium confidence + low quality object
        let pixelBuffer = try createMockPixelBuffer()

        mockYOLO.stubbedYOLOResults = [
            YOLOResult(
                label: "bottle",
                confidence: 0.65,
                boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.2, height: 0.3),
                alternativeLabels: []
            )
        ]

        await mockQuality.setQualityScore(0.45) // Low quality

        // When: Frame is processed
        await viewModel.processFrame(pixelBuffer)

        // Then: Object has manual catalog mode (await ensures completion)
        XCTAssertEqual(viewModel.detectedObjects.first?.catalogMode, .manual)
    }

    // MARK: - Helpers

    private func createMockPixelBuffer() throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            100,
            100,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"])
        }

        return buffer
    }
}

import XCTest
import SwiftUI
@preconcurrency import Vision
@testable import CameraFeature
@testable import VisionCore

final class CameraDetectionViewTests: XCTestCase {

    @MainActor
    func testViewInitializesWithViewModel() async {
        // Given: Mock dependencies
        let mockYOLO = MockHouseholdItemDetector()
        let mockQuality = MockImageQualityAssessor()
        let mockDeduplicator = MockObjectDeduplicator()
        let mockMaskGenerator = MockSubjectMaskGenerator()

        let viewModel = CameraDetectionViewModel(
            yoloDetector: mockYOLO,
            qualityAssessor: mockQuality,
            deduplicator: mockDeduplicator,
            maskGenerator: mockMaskGenerator,
            storageService: nil,  // Skip Firebase in tests
            itemService: nil      // Skip Firebase in tests
        )

        // When: View is created
        let view = CameraDetectionView(viewModel: viewModel)

        // Then: View is not nil
        XCTAssertNotNil(view)
    }
}

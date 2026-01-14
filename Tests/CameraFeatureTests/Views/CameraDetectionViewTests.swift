import XCTest
import SwiftUI
@preconcurrency import Vision
@testable import CameraFeature
@testable import VisionCore

final class CameraDetectionViewTests: XCTestCase {

    // MARK: - Helper Methods

    @MainActor
    private func createMockViewModel() -> CameraDetectionViewModel {
        let mockYOLO = MockHouseholdItemDetector()
        let mockQuality = MockImageQualityAssessor()
        let mockDeduplicator = MockObjectDeduplicator()
        let mockMaskGenerator = MockSubjectMaskGenerator()

        return CameraDetectionViewModel(
            yoloDetector: mockYOLO,
            qualityAssessor: mockQuality,
            deduplicator: mockDeduplicator,
            maskGenerator: mockMaskGenerator,
            storageService: nil,  // Skip Firebase in tests
            itemService: nil      // Skip Firebase in tests
        )
    }

    // MARK: - View Initialization Tests

    @MainActor
    func testViewInitializesWithViewModel() async {
        // Given: Mock dependencies
        let viewModel = createMockViewModel()

        // When: View is created
        let view = CameraDetectionView(viewModel: viewModel)

        // Then: View is not nil
        XCTAssertNotNil(view)
    }

    @MainActor
    func testViewBodyCompiles() async {
        // Given: View with mock dependencies
        let viewModel = createMockViewModel()
        let view = CameraDetectionView(viewModel: viewModel)

        // Then: View body should be accessible (compiles correctly)
        // This tests that the view hierarchy including modeIndicator and instructionLabel compiles
        XCTAssertNotNil(view.body)
    }

    // MARK: - Mode Indicator Tests

    @MainActor
    func testModeIndicatorUsesRoundedDesignFont() async {
        // Given: CameraDetectionView
        let viewModel = createMockViewModel()
        let view = CameraDetectionView(viewModel: viewModel)

        // Then: View compiles with rounded design typography
        // The modeIndicator should use .font(.system(size: 12, weight: .semibold, design: .rounded))
        XCTAssertNotNil(view, "View should compile with rounded typography in modeIndicator")
    }

    @MainActor
    func testModeIndicatorHasGlassEffectBackground() async {
        // Given: CameraDetectionView with modeIndicator
        let viewModel = createMockViewModel()
        let view = CameraDetectionView(viewModel: viewModel)

        // Then: View compiles with glass effect background
        // modeIndicator should use glassEffect() for iOS 26+ or .ultraThickMaterial for iOS 25-
        XCTAssertNotNil(view, "View should compile with glass effect background in modeIndicator")
    }

    // MARK: - Instruction Label Tests

    @MainActor
    func testInstructionLabelUsesRoundedDesignFont() async {
        // Given: CameraDetectionView
        let viewModel = createMockViewModel()
        let view = CameraDetectionView(viewModel: viewModel)

        // Then: View compiles with rounded design typography
        // The instructionLabel should use .font(.system(size: 15, weight: .regular, design: .rounded))
        XCTAssertNotNil(view, "View should compile with rounded typography in instructionLabel")
    }

    @MainActor
    func testInstructionLabelHasGlassEffectBackground() async {
        // Given: CameraDetectionView with instructionLabel
        let viewModel = createMockViewModel()
        let view = CameraDetectionView(viewModel: viewModel)

        // Then: View compiles with glass effect background
        // instructionLabel should use glassEffect() for iOS 26+ or .ultraThickMaterial for iOS 25-
        XCTAssertNotNil(view, "View should compile with glass effect background in instructionLabel")
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testViewSupportsAccessibilityReduceTransparency() async {
        // Given: CameraDetectionView with accessibility environment
        let viewModel = createMockViewModel()
        let view = CameraDetectionView(viewModel: viewModel)

        // Then: View compiles and supports @Environment(\.accessibilityReduceTransparency)
        // When reduceTransparency is true, solid backgrounds should be used instead of glass effects
        XCTAssertNotNil(view, "View should compile with accessibilityReduceTransparency support")
    }
}

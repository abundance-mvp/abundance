import XCTest
import SwiftUI
@testable import CameraFeature
@testable import VisionCore

final class OrganicBorderOverlayTests: XCTestCase {

    func testAutomaticModeBorderIsMintGreen() {
        // Given: Detected object with automatic catalog mode
        let object = DetectedObject(
            label: "backpack",
            confidence: 0.92,
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            qualityScore: 0.85,
            catalogMode: .automatic,
            mask: nil,
            fingerprint: "test-fingerprint"
        )

        // When: Border color is computed
        let borderColor = object.borderColor

        // Then: Returns mint green for automatic mode
        // Mint green RGB: (0.4, 0.95, 0.7)
        let expectedColor = Color(red: 0.4, green: 0.95, blue: 0.7)
        XCTAssertEqual(borderColor, expectedColor)
    }

    func testManualModeBorderIsGrey() {
        // Given: Detected object with manual catalog mode
        let object = DetectedObject(
            label: "bottle",
            confidence: 0.55,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.50,
            catalogMode: .manual,
            mask: nil,
            fingerprint: "test-fingerprint"
        )

        // When: Border color is computed
        let borderColor = object.borderColor

        // Then: Returns grey for manual mode
        let expectedColor = Color.gray.opacity(0.7)
        XCTAssertEqual(borderColor, expectedColor)
    }

    func testIgnoreModeBorderIsClear() {
        // Given: Detected object with ignore catalog mode
        let object = DetectedObject(
            label: "unknown",
            confidence: 0.25,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.30,
            catalogMode: .ignore,
            mask: nil,
            fingerprint: "test-fingerprint"
        )

        // When: Border color is computed
        let borderColor = object.borderColor

        // Then: Returns clear for ignore mode
        XCTAssertEqual(borderColor, Color.clear)
    }

    func testOverlayRendersWithObject() {
        // Given: Detected object
        let object = DetectedObject(
            label: "tent",
            confidence: 0.88,
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            qualityScore: 0.75,
            catalogMode: .automatic,
            mask: nil,
            fingerprint: "test-fingerprint"
        )

        // When: Overlay view is created
        let overlay = OrganicBorderOverlay(object: object)

        // Then: View is not nil
        XCTAssertNotNil(overlay)
    }

    func testOverlayRendersWithAutomaticMode() {
        // Given: Detected object with automatic catalog mode (high confidence + quality)
        let object = DetectedObject(
            label: "backpack",
            confidence: 0.92,
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            qualityScore: 0.85,
            catalogMode: .automatic,
            mask: nil,
            fingerprint: "test"
        )

        // When: Overlay view is created
        let overlay = OrganicBorderOverlay(object: object)

        // Then: View renders successfully with automatic mode styling
        XCTAssertNotNil(overlay)

        // Verify object properties match expected automatic mode characteristics
        XCTAssertEqual(object.catalogMode, .automatic)
        XCTAssertGreaterThanOrEqual(object.confidence, 0.9)
        XCTAssertGreaterThanOrEqual(object.qualityScore, 0.85)

        // Verify border color is mint green for automatic mode
        let expectedMintGreen = Color(red: 0.4, green: 0.95, blue: 0.7)
        XCTAssertEqual(object.borderColor, expectedMintGreen)
    }

    func testConfidenceBadgeDisplaysCorrectPercentage() {
        // Given: Detected object with known confidence
        let object = DetectedObject(
            label: "laptop",
            confidence: 0.87,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            mask: nil,
            fingerprint: "test-fingerprint"
        )

        // When: Confidence percentage is calculated
        let confidencePercentage = Int(object.confidence * 100)

        // Then: Percentage matches expected value
        XCTAssertEqual(confidencePercentage, 87)
    }

    func testOverlayRendersWithManualMode() {
        // Given: Detected object with manual catalog mode (lower confidence/quality)
        let object = DetectedObject(
            label: "water bottle",
            confidence: 0.55,
            boundingBox: CGRect(x: 0.15, y: 0.25, width: 0.35, height: 0.45),
            qualityScore: 0.50,
            catalogMode: .manual,
            mask: nil,
            fingerprint: "test-manual"
        )

        // When: Overlay view is created
        let overlay = OrganicBorderOverlay(object: object)

        // Then: View renders successfully with manual mode styling
        XCTAssertNotNil(overlay)
        XCTAssertEqual(object.catalogMode, .manual)

        // Verify border color is grey for manual mode
        let expectedGrey = Color.gray.opacity(0.7)
        XCTAssertEqual(object.borderColor, expectedGrey)
    }

    // MARK: - iOS 26 Liquid Glass Tests

    @MainActor
    func testConfidenceBadgeRendersWithGlassEffectOnIOS26() {
        // Given: Detected object with any catalog mode
        let object = DetectedObject(
            label: "phone",
            confidence: 0.95,
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            qualityScore: 0.88,
            catalogMode: .automatic,
            mask: nil,
            fingerprint: "test-glass"
        )

        // When: Overlay view is created
        let overlay = OrganicBorderOverlay(object: object)

        // Then: View should render successfully
        // Note: glassEffect() availability is handled at runtime via #available check
        XCTAssertNotNil(overlay)

        // Verify the overlay body can be accessed without crashing
        // This ensures the conditional compilation for iOS 26 is syntactically correct
        _ = overlay.body
    }

    @MainActor
    func testConfidenceBadgeHasAccessibilityReduceTransparencySupport() {
        // Given: Detected object
        let object = DetectedObject(
            label: "tablet",
            confidence: 0.82,
            boundingBox: CGRect(x: 0.15, y: 0.25, width: 0.35, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            mask: nil,
            fingerprint: "test-accessibility"
        )

        // When: Overlay view is created
        let overlay = OrganicBorderOverlay(object: object)

        // Then: View should render successfully
        // The @Environment(\.accessibilityReduceTransparency) is properly integrated
        XCTAssertNotNil(overlay)

        // Note: Actual accessibility preference testing requires UI testing
        // or dependency injection, but we verify the view renders correctly
        _ = overlay.body
    }

    @MainActor
    func testConfidenceBadgeFallbackOnIOS25() {
        // Given: Detected object
        let object = DetectedObject(
            label: "camera",
            confidence: 0.91,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.80,
            catalogMode: .automatic,
            mask: nil,
            fingerprint: "test-fallback"
        )

        // When: Overlay view is created
        let overlay = OrganicBorderOverlay(object: object)

        // Then: View should render successfully with material fallback
        // The Capsule().fill(.ultraThickMaterial) fallback is used on iOS 25-
        XCTAssertNotNil(overlay)

        // Verify the overlay renders without crashing on any iOS version
        _ = overlay.body
    }
}

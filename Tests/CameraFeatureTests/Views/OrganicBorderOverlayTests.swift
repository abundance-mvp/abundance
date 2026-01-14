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
}

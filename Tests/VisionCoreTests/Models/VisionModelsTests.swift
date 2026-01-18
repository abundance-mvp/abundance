import XCTest
@testable import VisionCore

final class VisionModelsTests: XCTestCase {

    func testConfidenceScore_high_isCorrectCategory() {
        // Given
        let score = ConfidenceScore(raw: 0.9)

        // Then
        XCTAssertEqual(score.raw, 0.9)
        XCTAssertEqual(score.adjusted, 0.9)
        XCTAssertEqual(score.category, .high)
    }

    func testConfidenceScore_medium_isCorrectCategory() {
        // Given
        let score = ConfidenceScore(raw: 0.7)

        // Then
        XCTAssertEqual(score.category, .medium)
    }

    func testConfidenceScore_low_isCorrectCategory() {
        // Given
        let score = ConfidenceScore(raw: 0.4)

        // Then
        XCTAssertEqual(score.category, .low)
    }

    // Note: HouseholdItem test removed as part of YOLO removal (server-side detection now)

    func testBarcodeResult_initialization_setsPropertiesCorrectly() {
        // Given
        let payload = "012345678912"
        let symbology = "EAN13"
        let confidence: Float = 0.99

        // When
        let barcode = BarcodeResult(
            payload: payload,
            symbology: symbology,
            confidence: confidence
        )

        // Then
        XCTAssertEqual(barcode.payload, payload)
        XCTAssertEqual(barcode.symbology, symbology)
        XCTAssertEqual(barcode.confidence, confidence)
    }
}

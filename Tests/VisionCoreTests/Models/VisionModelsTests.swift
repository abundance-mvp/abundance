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

    func testHouseholdItem_initialization_setsPropertiesCorrectly() {
        // Given
        let id = UUID()
        let label = "tent"
        let confidence = ConfidenceScore(raw: 0.85)
        let boundingBox = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        let imageSize = CGSize(width: 1000, height: 1000)

        // When
        let item = HouseholdItem(
            id: id,
            label: label,
            confidence: confidence,
            boundingBox: boundingBox,
            imageSize: imageSize
        )

        // Then
        XCTAssertEqual(item.id, id)
        XCTAssertEqual(item.label, label)
        XCTAssertEqual(item.confidence, confidence)
        XCTAssertEqual(item.boundingBox, boundingBox)
    }

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

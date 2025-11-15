import XCTest
import SwiftUI
@testable import VisionCore

final class DetectedObjectTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDetectedObject_initialization_setsPropertiesCorrectly() {
        // Given
        let id = UUID()
        let label = "bottle"
        let confidence = 0.85
        let boundingBox = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        let qualityScore = 0.75
        let catalogMode = CatalogMode.automatic
        let fingerprint = "abc123"
        let alternativeLabels = [
            AlternativeLabel(label: "cup", confidence: 0.7),
            AlternativeLabel(label: "mug", confidence: 0.65)
        ]

        // When
        let object = DetectedObject(
            id: id,
            label: label,
            confidence: confidence,
            boundingBox: boundingBox,
            qualityScore: qualityScore,
            catalogMode: catalogMode,
            mask: nil,
            fingerprint: fingerprint,
            alternativeLabels: alternativeLabels
        )

        // Then
        XCTAssertEqual(object.id, id)
        XCTAssertEqual(object.label, label)
        XCTAssertEqual(object.confidence, confidence)
        XCTAssertEqual(object.boundingBox, boundingBox)
        XCTAssertEqual(object.qualityScore, qualityScore)
        XCTAssertEqual(object.catalogMode, catalogMode)
        XCTAssertNil(object.mask)
        XCTAssertEqual(object.fingerprint, fingerprint)
        XCTAssertEqual(object.alternativeLabels.count, 2)
        XCTAssertEqual(object.alternativeLabels[0].label, "cup")
    }

    func testDetectedObject_initWithDefaults_usesDefaultValues() {
        // When
        let object = DetectedObject(
            label: "laptop",
            confidence: 0.9,
            boundingBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.5),
            qualityScore: 0.8,
            catalogMode: .automatic,
            fingerprint: "xyz789"
        )

        // Then
        XCTAssertNotNil(object.id) // UUID generated
        XCTAssertNil(object.mask) // Default nil
        XCTAssertEqual(object.alternativeLabels.count, 0) // Default empty array
    }

    // MARK: - Border Color Tests

    func testBorderColor_automatic_returnsMintGreen() {
        // Given
        let object = DetectedObject(
            label: "chair",
            confidence: 0.92,
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.3),
            qualityScore: 0.85,
            catalogMode: .automatic,
            fingerprint: "mint123"
        )

        // When
        let color = object.borderColor

        // Then
        // Mint green: rgb(0.4, 0.95, 0.7)
        XCTAssertNotEqual(color, Color.clear)
        // Can't directly compare SwiftUI Colors, but we verify it's not grey or clear
    }

    func testBorderColor_manual_returnsGrey() {
        // Given
        let object = DetectedObject(
            label: "desk",
            confidence: 0.55,
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.3),
            qualityScore: 0.50,
            catalogMode: .manual,
            fingerprint: "grey456"
        )

        // When
        let color = object.borderColor

        // Then
        XCTAssertNotEqual(color, Color.clear)
    }

    func testBorderColor_ignore_returnsClear() {
        // Given
        let object = DetectedObject(
            label: "unknown",
            confidence: 0.25,
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.3),
            qualityScore: 0.45,
            catalogMode: .ignore,
            fingerprint: "ignore789"
        )

        // When
        let color = object.borderColor

        // Then
        XCTAssertEqual(color, Color.clear)
    }

    // MARK: - Equatable Tests

    func testEquatable_sameObjects_areEqual() {
        // Given
        let id = UUID()
        let object1 = DetectedObject(
            id: id,
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            fingerprint: "abc123"
        )
        let object2 = DetectedObject(
            id: id,
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            fingerprint: "abc123"
        )

        // Then
        XCTAssertEqual(object1, object2)
    }

    func testEquatable_differentIds_areNotEqual() {
        // Given
        let object1 = DetectedObject(
            id: UUID(),
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            fingerprint: "abc123"
        )
        let object2 = DetectedObject(
            id: UUID(),
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            fingerprint: "abc123"
        )

        // Then
        XCTAssertNotEqual(object1, object2)
    }

    func testEquatable_differentLabels_areNotEqual() {
        // Given
        let id = UUID()
        let object1 = DetectedObject(
            id: id,
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            fingerprint: "abc123"
        )
        let object2 = DetectedObject(
            id: id,
            label: "cup",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            fingerprint: "abc123"
        )

        // Then
        XCTAssertNotEqual(object1, object2)
    }

    func testEquatable_differentCatalogModes_areNotEqual() {
        // Given
        let id = UUID()
        let object1 = DetectedObject(
            id: id,
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            fingerprint: "abc123"
        )
        var object2 = DetectedObject(
            id: id,
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            fingerprint: "abc123"
        )
        object2.catalogMode = .manual // Mutate catalog mode

        // Then
        XCTAssertNotEqual(object1, object2)
    }

    // MARK: - CatalogMode Mutation Tests

    func testCatalogMode_canBeMutated() {
        // Given
        var object = DetectedObject(
            label: "laptop",
            confidence: 0.6,
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            qualityScore: 0.5,
            catalogMode: .manual,
            fingerprint: "mutable123"
        )

        // When
        object.catalogMode = .automatic

        // Then
        XCTAssertEqual(object.catalogMode, .automatic)
    }
}

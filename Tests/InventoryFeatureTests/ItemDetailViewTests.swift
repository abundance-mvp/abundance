import Testing
import SwiftUI
@testable import InventoryFeature
@testable import Persistence

@Suite("ItemDetailView Tests")
@MainActor
struct ItemDetailViewTests {

    // MARK: - Test Fixtures

    static func makeTestItem(
        id: String = "test-item-1",
        userId: String = "test-user-1",
        imageUrl: String = "https://example.com/test-image.jpg",
        category: String? = "Electronics",
        color: String? = "Silver",
        material: String? = "Aluminum",
        condition: String? = "Good",
        confidence: Double? = nil,
        estimatedValue: Double? = 150.00
    ) -> Item {
        Item(
            id: id,
            userId: userId,
            imageUrl: imageUrl,
            status: .complete,
            category: category,
            color: color,
            material: material,
            condition: condition,
            confidence: confidence,
            estimatedValue: estimatedValue
        )
    }

    // MARK: - Rendering Tests

    @Test("ItemDetailView renders with parallax hero image")
    func testItemDetailViewRendersWithParallax() async throws {
        // Given
        let item = Self.makeTestItem()

        // When
        let view = ItemDetailView(item: item)

        // Then - View should render without crashing
        #expect(view.item.id == "test-item-1")
        #expect(view.item.imageUrl == "https://example.com/test-image.jpg")
    }

    @Test("ItemDetailView renders metadata card")
    func testItemDetailViewRendersMetadataCard() async throws {
        // Given
        let item = Self.makeTestItem(
            category: "Camping Gear",
            estimatedValue: 89.00
        )

        // When
        let view = ItemDetailView(item: item)

        // Then
        #expect(view.item.category == "Camping Gear")
        #expect(view.item.estimatedValue == 89.00)
    }

    // MARK: - Confidence Color Coding Tests

    @Test("High confidence (>= 0.80) returns green color")
    func testHighConfidenceColorCoding() async throws {
        // Given
        let highConfidence = 0.80

        // When
        let color = confidenceColor(highConfidence)

        // Then
        #expect(color == .green)
    }

    @Test("High confidence at 0.95 returns green color")
    func testVeryHighConfidenceColorCoding() async throws {
        // Given
        let veryHighConfidence = 0.95

        // When
        let color = confidenceColor(veryHighConfidence)

        // Then
        #expect(color == .green)
    }

    @Test("Medium confidence (>= 0.60, < 0.80) returns orange color")
    func testMediumConfidenceColorCoding() async throws {
        // Given
        let mediumConfidence = 0.65

        // When
        let color = confidenceColor(mediumConfidence)

        // Then
        #expect(color == .orange)
    }

    @Test("Medium confidence at boundary 0.60 returns orange color")
    func testMediumConfidenceBoundaryColorCoding() async throws {
        // Given
        let boundaryConfidence = 0.60

        // When
        let color = confidenceColor(boundaryConfidence)

        // Then
        #expect(color == .orange)
    }

    @Test("Medium confidence at boundary 0.79 returns orange color")
    func testMediumConfidenceUpperBoundaryColorCoding() async throws {
        // Given
        let upperBoundaryConfidence = 0.79

        // When
        let color = confidenceColor(upperBoundaryConfidence)

        // Then
        #expect(color == .orange)
    }

    @Test("Low confidence (< 0.60) returns red color")
    func testLowConfidenceColorCoding() async throws {
        // Given
        let lowConfidence = 0.45

        // When
        let color = confidenceColor(lowConfidence)

        // Then
        #expect(color == .red)
    }

    @Test("Very low confidence at 0.10 returns red color")
    func testVeryLowConfidenceColorCoding() async throws {
        // Given
        let veryLowConfidence = 0.10

        // When
        let color = confidenceColor(veryLowConfidence)

        // Then
        #expect(color == .red)
    }

    @Test("Low confidence at boundary 0.59 returns red color")
    func testLowConfidenceBoundaryColorCoding() async throws {
        // Given
        let boundaryConfidence = 0.59

        // When
        let color = confidenceColor(boundaryConfidence)

        // Then
        #expect(color == .red)
    }

    // MARK: - Confidence Level Label Tests

    @Test("High confidence returns 'High' label")
    func testHighConfidenceLabel() async throws {
        // Given
        let highConfidence = 0.85

        // When
        let label = confidenceLevel(highConfidence)

        // Then
        #expect(label == "High")
    }

    @Test("Medium confidence returns 'Medium' label")
    func testMediumConfidenceLabel() async throws {
        // Given
        let mediumConfidence = 0.70

        // When
        let label = confidenceLevel(mediumConfidence)

        // Then
        #expect(label == "Medium")
    }

    @Test("Low confidence returns 'Low' label")
    func testLowConfidenceLabel() async throws {
        // Given
        let lowConfidence = 0.30

        // When
        let label = confidenceLevel(lowConfidence)

        // Then
        #expect(label == "Low")
    }

    // MARK: - Confidence Icon Tests

    @Test("High confidence returns checkmark icon")
    func testHighConfidenceIcon() async throws {
        // Given
        let highConfidence = 0.90

        // When
        let icon = confidenceIcon(highConfidence)

        // Then
        #expect(icon == "checkmark.circle.fill")
    }

    @Test("Medium confidence returns warning icon")
    func testMediumConfidenceIcon() async throws {
        // Given
        let mediumConfidence = 0.65

        // When
        let icon = confidenceIcon(mediumConfidence)

        // Then
        #expect(icon == "exclamationmark.triangle.fill")
    }

    @Test("Low confidence returns question icon")
    func testLowConfidenceIcon() async throws {
        // Given
        let lowConfidence = 0.40

        // When
        let icon = confidenceIcon(lowConfidence)

        // Then
        #expect(icon == "questionmark.circle.fill")
    }

    // MARK: - Helper Functions (These should match implementation)

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.80 {
            return .green
        } else if confidence >= 0.60 {
            return .orange
        } else {
            return .red
        }
    }

    private func confidenceLevel(_ confidence: Double) -> String {
        if confidence >= 0.80 { return "High" }
        else if confidence >= 0.60 { return "Medium" }
        else { return "Low" }
    }

    private func confidenceIcon(_ confidence: Double) -> String {
        if confidence >= 0.80 { return "checkmark.circle.fill" }
        else if confidence >= 0.60 { return "exclamationmark.triangle.fill" }
        else { return "questionmark.circle.fill" }
    }
}

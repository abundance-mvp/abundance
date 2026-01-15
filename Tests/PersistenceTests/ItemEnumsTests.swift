import XCTest
@testable import Persistence

final class ItemEnumsTests: XCTestCase {

    // MARK: - ItemCondition Tests

    func testItemCondition_allCasesExist() {
        let cases: [ItemCondition] = [.new, .likeNew, .good, .fair, .poor]
        XCTAssertEqual(ItemCondition.allCases.count, 5)
        XCTAssertEqual(Set(ItemCondition.allCases), Set(cases))
    }

    func testItemCondition_rawValues() {
        XCTAssertEqual(ItemCondition.new.rawValue, "new")
        XCTAssertEqual(ItemCondition.likeNew.rawValue, "like-new")
        XCTAssertEqual(ItemCondition.good.rawValue, "good")
        XCTAssertEqual(ItemCondition.fair.rawValue, "fair")
        XCTAssertEqual(ItemCondition.poor.rawValue, "poor")
    }

    func testItemCondition_displayNames() {
        XCTAssertEqual(ItemCondition.new.displayName, "New")
        XCTAssertEqual(ItemCondition.likeNew.displayName, "Like New")
        XCTAssertEqual(ItemCondition.good.displayName, "Good")
        XCTAssertEqual(ItemCondition.fair.displayName, "Fair")
        XCTAssertEqual(ItemCondition.poor.displayName, "Poor")
    }

    func testItemCondition_codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for condition in ItemCondition.allCases {
            let encoded = try encoder.encode(condition)
            let decoded = try decoder.decode(ItemCondition.self, from: encoded)
            XCTAssertEqual(decoded, condition)
        }
    }

    func testItemCondition_initFromRawValue() {
        XCTAssertEqual(ItemCondition(rawValue: "new"), .new)
        XCTAssertEqual(ItemCondition(rawValue: "like-new"), .likeNew)
        XCTAssertEqual(ItemCondition(rawValue: "good"), .good)
        XCTAssertEqual(ItemCondition(rawValue: "fair"), .fair)
        XCTAssertEqual(ItemCondition(rawValue: "poor"), .poor)
        XCTAssertNil(ItemCondition(rawValue: "invalid"))
    }

    func testItemCondition_sendableConformance() {
        let condition = ItemCondition.good
        let _: any Sendable = condition
        XCTAssertNotNil(condition)
    }

    // MARK: - ItemConfidence Tests

    func testItemConfidence_allCasesExist() {
        let cases: [ItemConfidence] = [.high, .medium, .low]
        XCTAssertEqual(ItemConfidence.allCases.count, 3)
        XCTAssertEqual(Set(ItemConfidence.allCases), Set(cases))
    }

    func testItemConfidence_rawValues() {
        XCTAssertEqual(ItemConfidence.high.rawValue, "high")
        XCTAssertEqual(ItemConfidence.medium.rawValue, "medium")
        XCTAssertEqual(ItemConfidence.low.rawValue, "low")
    }

    func testItemConfidence_numericValues() {
        XCTAssertEqual(ItemConfidence.high.numericValue, 0.9)
        XCTAssertEqual(ItemConfidence.medium.numericValue, 0.7)
        XCTAssertEqual(ItemConfidence.low.numericValue, 0.4)
    }

    func testItemConfidence_codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for confidence in ItemConfidence.allCases {
            let encoded = try encoder.encode(confidence)
            let decoded = try decoder.decode(ItemConfidence.self, from: encoded)
            XCTAssertEqual(decoded, confidence)
        }
    }

    func testItemConfidence_initFromRawValue() {
        XCTAssertEqual(ItemConfidence(rawValue: "high"), .high)
        XCTAssertEqual(ItemConfidence(rawValue: "medium"), .medium)
        XCTAssertEqual(ItemConfidence(rawValue: "low"), .low)
        XCTAssertNil(ItemConfidence(rawValue: "invalid"))
    }

    func testItemConfidence_sendableConformance() {
        let confidence = ItemConfidence.high
        let _: any Sendable = confidence
        XCTAssertNotNil(confidence)
    }

    // MARK: - Item Model Tests with New Fields

    func testItem_initWithNewFields() {
        let now = Date()
        let photoMetadata = PhotoMetadata(
            latitude: 37.7749,
            imageHash: "abc123"
        )

        let item = Item(
            id: "test-id",
            userId: "user-123",
            imageUrl: "https://example.com/image.jpg",
            status: .complete,
            name: "Coleman Sundome Tent",
            category: "Outdoor & Camping",
            subCategory: "Tents",
            brand: "Coleman",
            model: "Sundome 4P",
            color: "Blue/Gray",
            material: "Polyester",
            condition: .good,
            dimensions: "4-person, 9' x 7'",
            quantity: 1,
            estimatedValue: 89.99,
            confidence: .high,
            processingNotes: "Good quality image",
            userEditedFields: ["name", "brand"],
            lastRescanAt: now,
            photoMetadata: photoMetadata,
            createdAt: now,
            updatedAt: now
        )

        XCTAssertEqual(item.id, "test-id")
        XCTAssertEqual(item.name, "Coleman Sundome Tent")
        XCTAssertEqual(item.category, "Outdoor & Camping")
        XCTAssertEqual(item.subCategory, "Tents")
        XCTAssertEqual(item.brand, "Coleman")
        XCTAssertEqual(item.model, "Sundome 4P")
        XCTAssertEqual(item.color, "Blue/Gray")
        XCTAssertEqual(item.material, "Polyester")
        XCTAssertEqual(item.condition, .good)
        XCTAssertEqual(item.dimensions, "4-person, 9' x 7'")
        XCTAssertEqual(item.quantity, 1)
        XCTAssertEqual(item.estimatedValue, 89.99)
        XCTAssertEqual(item.confidence, .high)
        XCTAssertEqual(item.processingNotes, "Good quality image")
        XCTAssertEqual(item.userEditedFields, ["name", "brand"])
        XCTAssertEqual(item.lastRescanAt, now)
        XCTAssertNotNil(item.photoMetadata)
        XCTAssertEqual(item.photoMetadata?.latitude, 37.7749)
    }

    func testItem_initWithMinimalFields() {
        let item = Item(
            id: "test-id",
            userId: "user-123",
            imageUrl: "https://example.com/image.jpg",
            status: .pending
        )

        XCTAssertEqual(item.id, "test-id")
        XCTAssertEqual(item.status, .pending)
        XCTAssertNil(item.name)
        XCTAssertNil(item.category)
        XCTAssertNil(item.brand)
        XCTAssertNil(item.condition)
        XCTAssertNil(item.confidence)
        XCTAssertNil(item.photoMetadata)
    }

    func testItem_equatable() {
        let item1 = Item(
            id: "test-id",
            userId: "user-123",
            imageUrl: "https://example.com/image.jpg",
            status: .pending,
            name: "Test Item"
        )
        let item2 = Item(
            id: "test-id",
            userId: "user-123",
            imageUrl: "https://example.com/image.jpg",
            status: .pending,
            name: "Test Item"
        )

        XCTAssertEqual(item1, item2)
    }

    func testItem_sendableConformance() {
        let item = Item(
            id: "test-id",
            userId: "user-123",
            imageUrl: "https://example.com/image.jpg",
            status: .pending
        )
        let _: any Sendable = item
        XCTAssertNotNil(item)
    }
}

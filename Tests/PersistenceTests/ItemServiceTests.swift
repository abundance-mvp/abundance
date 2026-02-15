import XCTest
import FirebaseFirestore
@testable import Persistence

/// Tests for ItemService Layer 1→2 handoff functionality
///
/// Note: Firestore integration tests require Firebase emulator
/// These tests verify the API surface and data model correctness
final class ItemServiceTests: XCTestCase {

    // MARK: - Layer1Metadata Tests

    func testLayer1Metadata_initialization_storesAllFields() {
        // Given: Layer 1 metadata parameters
        let detectedClass = "tent"
        let confidence = 0.87
        let boundingBox = CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5)
        let qualityScore = 0.75

        // When: Create Layer1Metadata
        let metadata = Layer1Metadata(
            detectedClass: detectedClass,
            confidence: confidence,
            boundingBox: boundingBox,
            qualityScore: qualityScore
        )

        // Then: All fields should be stored correctly
        XCTAssertEqual(metadata.detectedClass, detectedClass)
        XCTAssertEqual(metadata.confidence, confidence, accuracy: 0.001)
        XCTAssertEqual(metadata.boundingBox, boundingBox)
        XCTAssertEqual(metadata.qualityScore, qualityScore, accuracy: 0.001)
    }

    func testLayer1Metadata_sendableConformance() {
        // Given: Layer1Metadata struct
        // When: Create instance
        let metadata = Layer1Metadata(
            detectedClass: "tent",
            confidence: 0.87,
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            qualityScore: 0.75
        )

        // Then: Should be Sendable (compile-time check)
        // This verifies thread-safety for concurrent usage in camera pipeline
        let _: any Sendable = metadata
        XCTAssertNotNil(metadata)
    }

    func testLayer1Metadata_boundingBoxFormat() {
        // Given: Vision framework normalized coordinates (0-1 range)
        let boundingBox = CGRect(x: 0.25, y: 0.30, width: 0.50, height: 0.40)

        // When: Create metadata
        let metadata = Layer1Metadata(
            detectedClass: "tent",
            confidence: 0.87,
            boundingBox: boundingBox,
            qualityScore: 0.75
        )

        // Then: Bounding box coordinates preserved correctly
        XCTAssertEqual(metadata.boundingBox.origin.x, 0.25, accuracy: 0.001)
        XCTAssertEqual(metadata.boundingBox.origin.y, 0.30, accuracy: 0.001)
        XCTAssertEqual(metadata.boundingBox.size.width, 0.50, accuracy: 0.001)
        XCTAssertEqual(metadata.boundingBox.size.height, 0.40, accuracy: 0.001)
    }

    // MARK: - ItemService API Tests

    func testItemRepository_hasLayer1MetadataMethod() {
        // Given: ItemRepository protocol
        // Then: Should have createItemWithLayer1Metadata method
        // This test verifies the protocol requirement exists (compile-time check)
        let _: (ItemRepository) -> (String, String, String, Layer1Metadata) async throws -> Void
        _ = ItemRepository.createItemWithLayer1Metadata

        XCTAssertTrue(true)
    }

}

// MARK: - Integration Tests (Require Firebase Emulator)

/// Integration tests for ItemService.createItemWithLayer1Metadata
/// These tests verify the full Firestore round-trip for Layer 1→2 handoff.
///
/// ## Running Integration Tests
///
/// 1. Start Firebase emulator: `firebase emulators:start --only firestore`
/// 2. Set environment variable: `FIREBASE_EMULATOR_HOST=localhost:8080`
/// 3. Run tests: `swift test --filter ItemServiceIntegrationTests`
///
/// Note: Tests are skipped automatically if emulator is not available.
final class ItemServiceIntegrationTests: XCTestCase {

    /// Check if Firebase emulator is available
    private static var emulatorAvailable: Bool {
        ProcessInfo.processInfo.environment["FIREBASE_EMULATOR_HOST"] != nil
    }

    /// Check if running in CI environment
    private static var isCI: Bool {
        ProcessInfo.processInfo.environment["CI"] == "true"
    }

    var sut: ItemService!

    override func setUp() async throws {
        try await super.setUp()

        // In CI, fail loudly if emulator not configured (prevents silent coverage gaps)
        if Self.isCI && !Self.emulatorAvailable {
            XCTFail("CI environment requires FIREBASE_EMULATOR_HOST to be set for integration tests")
            return
        }

        // Locally, skip if emulator not available
        try XCTSkipUnless(
            Self.emulatorAvailable,
            "Firebase emulator not available. Set FIREBASE_EMULATOR_HOST=localhost:8080"
        )

        // Configure Firestore to use emulator
        let settings = Firestore.firestore().settings
        settings.host = ProcessInfo.processInfo.environment["FIREBASE_EMULATOR_HOST"] ?? "localhost:8080"
        settings.isSSLEnabled = false
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings

        sut = ItemService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    /// Test that createItemWithLayer1Metadata creates document with correct schema
    func testIntegration_createItemWithLayer1Metadata_createsDocumentWithCorrectSchema() async throws {
        try XCTSkipUnless(Self.emulatorAvailable, "Requires Firebase emulator")

        // Given: Layer 1 metadata from camera detection
        let userId = "test-user-\(UUID().uuidString)"
        let itemId = UUID().uuidString
        let imageUrl = "gs://test-bucket/test-image.jpg"
        let metadata = Layer1Metadata(
            detectedClass: "tent",
            confidence: 0.87,
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            qualityScore: 0.75
        )

        // When: Create item with Layer 1 metadata
        try await sut.createItemWithLayer1Metadata(
            itemId: itemId,
            userId: userId,
            imageUrl: imageUrl,
            layer1Metadata: metadata
        )

        // Then: Document should exist with correct schema
        let items = try await sut.getItems(userId: userId)
        XCTAssertEqual(items.count, 1, "Should have exactly one item")

        let item = items[0]
        XCTAssertEqual(item.userId, userId)
        XCTAssertEqual(item.imageUrl, imageUrl)
        XCTAssertEqual(item.status, .processing, "Status should be processing (mapped from pending)")
    }

    /// Test that created items have non-empty id field
    func testIntegration_createItemWithLayer1Metadata_includesIdField() async throws {
        try XCTSkipUnless(Self.emulatorAvailable, "Requires Firebase emulator")

        // Given: Valid inputs
        let userId = "test-user-\(UUID().uuidString)"
        let itemId = UUID().uuidString
        let imageUrl = "gs://test-bucket/test-image.jpg"
        let metadata = Layer1Metadata(
            detectedClass: "tent",
            confidence: 0.87,
            boundingBox: .zero,
            qualityScore: 0.75
        )

        // When: Create item
        try await sut.createItemWithLayer1Metadata(
            itemId: itemId,
            userId: userId,
            imageUrl: imageUrl,
            layer1Metadata: metadata
        )

        // Then: Item should have the specified id
        let item = try await sut.getItem(id: itemId)
        XCTAssertNotNil(item, "Item should be retrievable by id")
        XCTAssertEqual(item?.id, itemId, "Item id should match provided itemId")
    }

    /// Test that items can be fetched after creation
    func testIntegration_getItems_returnsCreatedItems() async throws {
        try XCTSkipUnless(Self.emulatorAvailable, "Requires Firebase emulator")

        // Given: Create multiple items
        let userId = "test-user-\(UUID().uuidString)"

        for index in 1...3 {
            let metadata = Layer1Metadata(
                detectedClass: "item-\(index)",
                confidence: Double(index) * 0.25,
                boundingBox: CGRect(x: 0, y: 0, width: 0.1, height: 0.1),
                qualityScore: 0.8
            )

            try await sut.createItemWithLayer1Metadata(
                itemId: UUID().uuidString,
                userId: userId,
                imageUrl: "gs://test-bucket/image-\(index).jpg",
                layer1Metadata: metadata
            )
        }

        // When: Fetch items for user
        let items = try await sut.getItems(userId: userId)

        // Then: All items should be returned
        XCTAssertEqual(items.count, 3, "Should return all created items")
    }
}

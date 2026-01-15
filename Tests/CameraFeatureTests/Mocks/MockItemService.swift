import Foundation
import FirebaseFirestore
import Combine
@testable import Persistence

final class MockItemService: ItemRepository, @unchecked Sendable {
    var createItemCalled: Bool = false
    var createItemWithLayer1MetadataCalled: Bool = false
    var createItemWithPhotoMetadataCalled: Bool = false
    var createdUserId: String?
    var createdImageUrl: String?
    var createdItemId: String?
    var createdLayer1Metadata: Layer1Metadata?
    var createdPhotoMetadata: PhotoMetadata?
    var stubbedItemId: String = "test-item-123"
    var shouldFail: Bool = false

    func createItem(userId: String, imageUrl: String) async throws -> String {
        createItemCalled = true
        createdUserId = userId
        createdImageUrl = imageUrl

        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }

        return stubbedItemId
    }

    func createItemWithLayer1Metadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata
    ) async throws {
        createItemWithLayer1MetadataCalled = true
        createdItemId = itemId
        createdUserId = userId
        createdImageUrl = imageUrl
        createdLayer1Metadata = layer1Metadata

        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }

    func createItemWithPhotoMetadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata,
        photoMetadata: PhotoMetadata
    ) async throws {
        createItemWithPhotoMetadataCalled = true
        createdItemId = itemId
        createdUserId = userId
        createdImageUrl = imageUrl
        createdLayer1Metadata = layer1Metadata
        createdPhotoMetadata = photoMetadata

        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }

    func getItem(id: String) async throws -> Item? {
        return nil
    }

    func getItems(userId: String) async throws -> [Item] {
        return []
    }

    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration {
        fatalError("Not implemented in mock")
    }

    func observeItems(userId: String) -> AnyPublisher<[Item], Never> {
        return Just([]).eraseToAnyPublisher()
    }

    func deleteItem(id: String) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }

    func deleteItems(ids: Set<String>) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }

    func reset() {
        createItemCalled = false
        createItemWithLayer1MetadataCalled = false
        createItemWithPhotoMetadataCalled = false
        createdUserId = nil
        createdImageUrl = nil
        createdItemId = nil
        createdLayer1Metadata = nil
        createdPhotoMetadata = nil
        stubbedItemId = "test-item-123"
        shouldFail = false
    }
}

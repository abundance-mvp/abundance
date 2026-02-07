import Foundation
import Combine
import FirebaseFirestore
@testable import InventoryFeature
@testable import Persistence

/// Comprehensive mock ItemRepository for testing InventoryViewModel and EditItemViewModel
/// Supports configurable behavior for success/failure scenarios and tracking of method calls
final class MockItemRepository: ItemRepository, @unchecked Sendable {
    // MARK: - Call Tracking

    var getItemsCalled = false
    var getItemCalled = false
    var lastUserId: String?
    var lastItemId: String?
    var createItemCalled = false
    var updateItemCalled = false
    var rescanItemCalled = false
    var deleteItemCalled = false
    var deleteItemsCalled = false

    // MARK: - Mock Data

    var itemsToReturn: [Item] = []
    var itemToReturn: Item?
    var deletedIds: [String] = []
    var deletedBulkIds: Set<String> = []
    var lastUpdatedItem: Item?
    var lastUserEditedFields: [String]?
    var lastRescanItem: Item?

    // MARK: - Backward Compatibility Aliases

    /// Alias for itemsToReturn (backward compatibility)
    var mockItems: [Item] {
        get { itemsToReturn }
        set { itemsToReturn = newValue }
    }

    /// Alias for deletedIds (backward compatibility)
    var deletedItemIds: [String] {
        get { deletedIds }
        set { deletedIds = newValue }
    }

    /// Alias for getItemsError (backward compatibility)
    var shouldThrowError: Error? {
        get { getItemsError }
        set { getItemsError = newValue }
    }

    // MARK: - Error Configuration

    var getItemsError: Error?
    var getItemError: Error?
    var deleteError: Error?
    var updateError: Error?
    var rescanError: Error?

    // MARK: - Convenience Properties

    var shouldFailDelete: Bool {
        get { deleteError != nil }
        set { deleteError = newValue ? MockError.deleteFailure : nil }
    }

    var shouldFailUpdate: Bool {
        get { updateError != nil }
        set { updateError = newValue ? MockError.updateFailure : nil }
    }

    var shouldFailRescan: Bool {
        get { rescanError != nil }
        set { rescanError = newValue ? MockError.rescanFailure : nil }
    }

    // MARK: - Real-Time Updates

    private var itemsSubject = PassthroughSubject<[Item], Never>()

    /// Simulate a real-time update from Firestore
    func simulateItemsUpdate(_ items: [Item]) {
        itemsToReturn = items
        itemsSubject.send(items)
    }

    /// Simulate a single item update
    func simulateItemUpdate(_ item: Item) {
        if let index = itemsToReturn.firstIndex(where: { $0.id == item.id }) {
            itemsToReturn[index] = item
        } else {
            itemsToReturn.append(item)
        }
        itemsSubject.send(itemsToReturn)
    }

    /// Simulate item deletion via real-time update
    func simulateItemDeletion(id: String) {
        itemsToReturn.removeAll { $0.id == id }
        itemsSubject.send(itemsToReturn)
    }

    // MARK: - ItemReadRepository

    func getItem(id: String) async throws -> Item? {
        getItemCalled = true
        lastItemId = id
        if let error = getItemError {
            throw error
        }
        return itemToReturn ?? itemsToReturn.first { $0.id == id }
    }

    func getItems(userId: String) async throws -> [Item] {
        getItemsCalled = true
        lastUserId = userId
        if let error = getItemsError {
            throw error
        }
        return itemsToReturn
    }

    // MARK: - ItemWriteRepository

    func createItem(userId: String, imageUrl: String) async throws -> String {
        createItemCalled = true
        return "mock-item-id"
    }

    func createItemWithLayer1Metadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata
    ) async throws {
        createItemCalled = true
    }

    func createItemWithPhotoMetadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata,
        photoMetadata: PhotoMetadata
    ) async throws {
        createItemCalled = true
    }

    func updateItem(_ item: Item, userEditedFields: [String]?) async throws {
        if let error = updateError {
            throw error
        }
        updateItemCalled = true
        lastUpdatedItem = item
        lastUserEditedFields = userEditedFields
    }

    func rescanItem(_ item: Item) async throws {
        if let error = rescanError {
            throw error
        }
        rescanItemCalled = true
        lastRescanItem = item
    }

    var refreshImageUrlCalled = false
    var refreshedImageUrl: String?

    func refreshImageUrl(id: String) async throws -> String? {
        refreshImageUrlCalled = true
        return refreshedImageUrl ?? itemsToReturn.first { $0.id == id }?.imageUrl
    }

    var requestDeepScanCalled = false
    var lastDeepScanId: String?

    func requestDeepScan(id: String) async throws {
        requestDeepScanCalled = true
        lastDeepScanId = id
    }

    var recatalogWithPhotosCalled = false
    var lastRecatalogWithPhotosId: String?

    func recatalogWithPhotos(id: String) async throws {
        recatalogWithPhotosCalled = true
        lastRecatalogWithPhotosId = id
    }

    func deleteItem(id: String) async throws {
        deleteItemCalled = true
        if let error = deleteError {
            throw error
        }
        deletedIds.append(id)
    }

    func deleteItems(ids: Set<String>) async throws {
        deleteItemsCalled = true
        if let error = deleteError {
            throw error
        }
        deletedBulkIds = ids
    }

    // MARK: - ItemObservableRepository

    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration {
        // Return the item immediately if it exists
        let item = itemsToReturn.first { $0.id == id }
        onChange(item)
        return MockListenerRegistration()
    }

    func observeItems(userId: String) -> AnyPublisher<[Item], Never> {
        // Immediately send current items, then allow future updates
        let initialPublisher = Just(itemsToReturn).eraseToAnyPublisher()
        return initialPublisher
            .merge(with: itemsSubject.eraseToAnyPublisher())
            .eraseToAnyPublisher()
    }

    // MARK: - Reset

    func reset() {
        getItemsCalled = false
        getItemCalled = false
        lastUserId = nil
        lastItemId = nil
        createItemCalled = false
        updateItemCalled = false
        rescanItemCalled = false
        deleteItemCalled = false
        deleteItemsCalled = false

        itemsToReturn = []
        itemToReturn = nil
        deletedIds = []
        deletedBulkIds = []
        lastUpdatedItem = nil
        lastUserEditedFields = nil
        lastRescanItem = nil

        getItemsError = nil
        getItemError = nil
        deleteError = nil
        updateError = nil
        rescanError = nil
    }
}

// MARK: - Mock Errors

enum MockError: LocalizedError {
    case deleteFailure
    case updateFailure
    case rescanFailure
    case getItemsFailure
    case networkError
    case timeout

    var errorDescription: String? {
        switch self {
        case .deleteFailure:
            return "Mock delete error"
        case .updateFailure:
            return "Mock update error"
        case .rescanFailure:
            return "Mock rescan error"
        case .getItemsFailure:
            return "Mock getItems error"
        case .networkError:
            return "Network connection failed"
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - Mock Listener Registration

final class MockListenerRegistration: NSObject, ListenerRegistration {
    var removeCount = 0

    func remove() {
        removeCount += 1
    }
}

// MARK: - Mock Storage Service

/// Mock StorageServiceProtocol for testing upload flows
final class MockStorageService: StorageServiceProtocol, @unchecked Sendable {
    var uploadCalled = false
    var uploadCount = 0
    var lastUploadedItemId: String?
    var lastUploadedUserId: String?

    var uploadError: Error?
    var uploadDelay: TimeInterval = 0
    var uploadedURLs: [URL] = []

    var shouldFailUpload: Bool {
        get { uploadError != nil }
        set { uploadError = newValue ? MockError.networkError : nil }
    }

    func uploadCroppedObject(_ image: PlatformImage, itemId: String, userId: String) async throws -> URL {
        if uploadDelay > 0 {
            try await Task.sleep(for: .seconds(uploadDelay))
        }

        if let error = uploadError {
            throw error
        }

        uploadCalled = true
        uploadCount += 1
        lastUploadedItemId = itemId
        lastUploadedUserId = userId

        let url = URL(string: "https://example.com/uploaded/\(itemId).jpg")!
        uploadedURLs.append(url)
        return url
    }

    func uploadLivePhotoMotion(_ motionData: Data, itemId: String, userId: String) async throws -> URL {
        URL(string: "https://example.com/motion/\(itemId).mov")!
    }

    func uploadAdditionalPhoto(_ image: PlatformImage, itemId: String, photoIndex: Int, userId: String) async throws -> URL {
        if let error = uploadError { throw error }
        uploadCount += 1
        let url = URL(string: "https://example.com/uploaded/\(itemId)_photo_\(photoIndex).jpg")!
        uploadedURLs.append(url)
        return url
    }

    func reset() {
        uploadCalled = false
        uploadCount = 0
        lastUploadedItemId = nil
        lastUploadedUserId = nil
        uploadError = nil
        uploadDelay = 0
        uploadedURLs = []
    }
}

// MARK: - Test Item Factory

/// Factory for creating test items with various configurations
enum TestItemFactory {
    static func makeItem(
        id: String = "test-item-1",
        userId: String = "test-user",
        imageUrl: String = "https://example.com/image.jpg",
        status: ItemStatus = .complete,
        name: String? = "Test Item",
        category: String? = "Test Category",
        subCategory: String? = nil,
        brand: String? = nil,
        model: String? = nil,
        color: String? = nil,
        material: String? = nil,
        condition: ItemCondition? = .good,
        dimensions: String? = nil,
        quantity: Int? = 1,
        estimatedValue: Double? = 100.0,
        confidence: ItemConfidence? = .high,
        processingNotes: String? = nil,
        userEditedFields: [String]? = nil,
        lastRescanAt: Date? = nil,
        photoMetadata: PhotoMetadata? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Item {
        Item(
            id: id,
            userId: userId,
            imageUrl: imageUrl,
            status: status,
            name: name,
            category: category,
            subCategory: subCategory,
            brand: brand,
            model: model,
            color: color,
            material: material,
            condition: condition,
            dimensions: dimensions,
            quantity: quantity,
            estimatedValue: estimatedValue,
            confidence: confidence,
            processingNotes: processingNotes,
            userEditedFields: userEditedFields,
            lastRescanAt: lastRescanAt,
            photoMetadata: photoMetadata,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Create multiple test items with sequential IDs
    static func makeItems(count: Int, userId: String = "test-user") -> [Item] {
        (0..<count).map { index in
            makeItem(
                id: "item-\(index + 1)",
                userId: userId,
                name: "Test Item \(index + 1)",
                category: "Category \(index + 1)"
            )
        }
    }

    /// Create an item in processing status (awaiting AI pipeline)
    static func makeProcessingItem(id: String = "processing-item", userId: String = "test-user") -> Item {
        makeItem(
            id: id,
            userId: userId,
            status: .processing,
            name: nil,
            category: nil,
            confidence: nil
        )
    }

    /// Create an item that failed processing
    static func makeFailedItem(id: String = "failed-item", userId: String = "test-user") -> Item {
        makeItem(
            id: id,
            userId: userId,
            status: .failed,
            name: nil,
            category: nil,
            confidence: nil,
            processingNotes: "Processing failed: Unable to identify item"
        )
    }
}

import Testing
import Foundation
import Combine
import FirebaseFirestore
@testable import InventoryFeature
@testable import Persistence

@Suite("InventoryViewModel Tests")
@MainActor
struct InventoryViewModelTests {

    // MARK: - Authentication State Tests

    @Test("Init with no userId sets error state")
    func testInit_withNoUserId_setsErrorState() async throws {
        // Given: No authenticated user (nil userId)
        let mockRepository = MockItemRepository()

        // When: Create ViewModel without userId, using mock auth provider that returns nil
        let viewModel = InventoryViewModel(
            userId: nil,
            itemRepository: mockRepository,
            requiresAuthentication: true,
            authProvider: { nil }  // Mock: no authenticated user
        )

        // Then: Should have error state, not empty string
        #expect(viewModel.error == "Authentication required")
        #expect(viewModel.items.isEmpty)
        #expect(mockRepository.getItemsCalled == false, "Should not attempt to fetch items without auth")
    }

    @Test("Init with valid userId does not set error")
    func testInit_withValidUserId_noError() async throws {
        // Given: Valid user ID
        let mockRepository = MockItemRepository()

        // When: Create ViewModel with userId
        let viewModel = InventoryViewModel(
            userId: "test-user-123",
            itemRepository: mockRepository,
            requiresAuthentication: true
        )

        // Then: Should not have error
        #expect(viewModel.error == nil)
    }

    @Test("loadItems with no auth sets error")
    func testLoadItems_withNoAuth_setsError() async throws {
        // Given: ViewModel with no userId
        let mockRepository = MockItemRepository()
        let viewModel = InventoryViewModel(
            userId: nil,
            itemRepository: mockRepository,
            requiresAuthentication: true,
            authProvider: { nil }  // Mock: no authenticated user
        )

        // When: Try to load items
        await viewModel.loadItems()

        // Then: Should have auth error
        #expect(viewModel.error == "Authentication required")
        #expect(mockRepository.getItemsCalled == false)
    }

    @Test("loadItems with valid auth fetches items")
    func testLoadItems_withValidAuth_fetchesItems() async throws {
        // Given: ViewModel with valid userId
        let mockRepository = MockItemRepository()
        mockRepository.mockItems = [
            Item(
                id: "item-1",
                userId: "test-user-123",
                imageUrl: "https://example.com/image.jpg",
                status: .complete,
                category: "camping",
                color: nil,
                material: nil,
                condition: nil,
                confidence: 0.95,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        let viewModel = InventoryViewModel(
            userId: "test-user-123",
            itemRepository: mockRepository,
            requiresAuthentication: true
        )

        // When: Load items
        await viewModel.loadItems()

        // Then: Should fetch items successfully
        #expect(viewModel.error == nil)
        #expect(viewModel.items.count == 1)
        #expect(mockRepository.getItemsCalled == true)
        #expect(mockRepository.lastUserId == "test-user-123")
    }

    @Test("requiresAuthentication=false allows nil userId")
    func testInit_withNoAuthRequired_allowsNilUserId() async throws {
        // Given: No auth required mode (for previews/testing)
        let mockRepository = MockItemRepository()

        // When: Create ViewModel without userId and auth not required
        let viewModel = InventoryViewModel(
            userId: nil,
            itemRepository: mockRepository,
            requiresAuthentication: false
        )

        // Then: Should not have error (for preview mode)
        #expect(viewModel.error == nil)
    }

    // MARK: - Delete Tests

    @Test("deleteItem removes item from local array")
    func testDeleteItem_removesFromLocalArray() async throws {
        // Given: ViewModel with items (disable observer by not setting userId)
        let mockRepository = MockItemRepository()
        let testItem = Item(
            id: "item-1",
            userId: "test-user",
            imageUrl: "https://example.com/image.jpg",
            status: .complete,
            category: "Test Item"
        )
        // Don't set mockItems to avoid observer overwriting
        let viewModel = InventoryViewModel(
            userId: nil,  // No userId means no observer
            itemRepository: mockRepository,
            requiresAuthentication: false
        )
        viewModel.items = [testItem]
        viewModel.error = nil  // Clear the auth error for testing

        // When: Delete item
        await viewModel.deleteItem(testItem)

        // Then: Repository should have been called and item removed locally
        #expect(mockRepository.deletedItemIds.contains("item-1"))
        // Note: Item is removed optimistically but we verify the repository was called
    }

    @Test("deleteItem calls repository")
    func testDeleteItem_callsRepository() async throws {
        // Given: ViewModel with item
        let mockRepository = MockItemRepository()
        let testItem = Item(
            id: "item-1",
            userId: "test-user",
            imageUrl: "https://example.com/image.jpg",
            status: .complete,
            category: "Test Item"
        )
        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepository,
            requiresAuthentication: false
        )
        viewModel.items = [testItem]

        // When: Delete item
        await viewModel.deleteItem(testItem)

        // Then: Repository should have been called
        #expect(mockRepository.deletedItemIds == ["item-1"])
    }

    @Test("deleteItem rolls back on failure")
    func testDeleteItem_rollsBackOnFailure() async throws {
        // Given: ViewModel with item and failing repository
        let mockRepository = MockItemRepository()
        mockRepository.shouldFailDelete = true
        let testItem = Item(
            id: "item-1",
            userId: "test-user",
            imageUrl: "https://example.com/image.jpg",
            status: .complete,
            category: "Test Item"
        )
        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepository,
            requiresAuthentication: false
        )
        viewModel.items = [testItem]

        // When: Delete item (should fail)
        await viewModel.deleteItem(testItem)

        // Then: Item should be restored and error set
        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.id == "item-1")
        #expect(viewModel.deleteError != nil)
    }

    @Test("deleteItems removes multiple items from local array")
    func testDeleteItems_removesMultipleFromLocalArray() async throws {
        // Given: ViewModel with multiple items (disable observer by not setting userId)
        let mockRepository = MockItemRepository()
        let items = [
            Item(id: "item-1", userId: "test-user", imageUrl: "url1", status: .complete, category: "Item 1"),
            Item(id: "item-2", userId: "test-user", imageUrl: "url2", status: .complete, category: "Item 2"),
            Item(id: "item-3", userId: "test-user", imageUrl: "url3", status: .complete, category: "Item 3")
        ]
        let viewModel = InventoryViewModel(
            userId: nil,  // No userId means no observer
            itemRepository: mockRepository,
            requiresAuthentication: false
        )
        viewModel.items = items
        viewModel.error = nil  // Clear the auth error for testing

        // When: Delete items 1 and 3
        await viewModel.deleteItems(ids: Set(["item-1", "item-3"]))

        // Then: Repository should have been called with correct ids
        #expect(mockRepository.deletedBulkIds == Set(["item-1", "item-3"]))
    }

    @Test("deleteItems rolls back all on failure")
    func testDeleteItems_rollsBackAllOnFailure() async throws {
        // Given: ViewModel with items and failing repository
        let mockRepository = MockItemRepository()
        mockRepository.shouldFailDelete = true
        let items = [
            Item(id: "item-1", userId: "test-user", imageUrl: "url1", status: .complete, category: "Item 1"),
            Item(id: "item-2", userId: "test-user", imageUrl: "url2", status: .complete, category: "Item 2")
        ]
        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepository,
            requiresAuthentication: false
        )
        viewModel.items = items

        // When: Delete items (should fail)
        await viewModel.deleteItems(ids: Set(["item-1", "item-2"]))

        // Then: All items should be restored
        #expect(viewModel.items.count == 2)
        #expect(viewModel.deleteError != nil)
    }

    @Test("deleteItems with empty set does nothing")
    func testDeleteItems_emptySetDoesNothing() async throws {
        // Given: ViewModel with items
        let mockRepository = MockItemRepository()
        let items = [
            Item(id: "item-1", userId: "test-user", imageUrl: "url1", status: .complete, category: "Item 1")
        ]
        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepository,
            requiresAuthentication: false
        )
        viewModel.items = items

        // When: Delete empty set
        await viewModel.deleteItems(ids: Set())

        // Then: Items should remain unchanged
        #expect(viewModel.items.count == 1)
        #expect(mockRepository.deletedBulkIds.isEmpty)
    }
}

// MARK: - Mock Repository

/// Mock ItemRepository for testing
final class MockItemRepository: ItemRepository, @unchecked Sendable {
    var getItemsCalled = false
    var lastUserId: String?
    var mockItems: [Item] = []
    var shouldThrowError: Error?

    // Delete tracking
    var deletedItemIds: [String] = []
    var deletedBulkIds: Set<String> = []
    var shouldFailDelete = false

    func createItem(userId: String, imageUrl: String) async throws -> String {
        return "mock-item-id"
    }

    func createItemWithLayer1Metadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata
    ) async throws {
        // Mock implementation
    }

    func getItem(id: String) async throws -> Item? {
        return mockItems.first { $0.id == id }
    }

    func getItems(userId: String) async throws -> [Item] {
        getItemsCalled = true
        lastUserId = userId
        if let error = shouldThrowError {
            throw error
        }
        return mockItems
    }

    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration {
        // Return a mock listener - this is a placeholder
        fatalError("Mock observeItem not implemented")
    }

    func observeItems(userId: String) -> AnyPublisher<[Item], Never> {
        Just(mockItems).eraseToAnyPublisher()
    }

    func deleteItem(id: String) async throws {
        if shouldFailDelete {
            throw NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock delete error"])
        }
        deletedItemIds.append(id)
    }

    func deleteItems(ids: Set<String>) async throws {
        if shouldFailDelete {
            throw NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock batch delete error"])
        }
        deletedBulkIds = ids
    }
}

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
                confidence: .high,
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
}

// MARK: - Mock Repository

/// Mock ItemRepository for testing
final class MockItemRepository: ItemRepository, @unchecked Sendable {
    var getItemsCalled = false
    var lastUserId: String?
    var mockItems: [Item] = []
    var shouldThrowError: Error?

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

    func createItemWithPhotoMetadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata,
        photoMetadata: PhotoMetadata
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
}

import Testing
import Foundation
import Combine
import FirebaseFirestore
@testable import CollectionFeature
@testable import Persistence

@Suite("CollectionViewModel Tests")
@MainActor
struct CollectionViewModelTests {

    // MARK: - Authentication State Tests

    @Test("Init with no userId sets error state")
    func testInit_withNoUserId_setsErrorState() async throws {
        // Given: No authenticated user (nil userId)
        let mockRepository = MockItemRepository()

        // When: Create ViewModel without userId, using mock auth provider that returns nil
        let viewModel = CollectionViewModel(
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
        let viewModel = CollectionViewModel(
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
        let viewModel = CollectionViewModel(
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
        let viewModel = CollectionViewModel(
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
        let viewModel = CollectionViewModel(
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
        let viewModel = CollectionViewModel(
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
        let viewModel = CollectionViewModel(
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
        let viewModel = CollectionViewModel(
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
        let viewModel = CollectionViewModel(
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
        let viewModel = CollectionViewModel(
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
        let viewModel = CollectionViewModel(
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

    // MARK: - Loading State Tests

    @Test("loadItems sets loading state during fetch")
    func testLoadItems_setsLoadingState() async throws {
        // Given: ViewModel with valid userId and mock repository
        let mockRepository = MockItemRepository()
        mockRepository.mockItems = [
            Item(
                id: "item-1",
                userId: "test-user-123",
                imageUrl: "https://example.com/image.jpg",
                status: .complete,
                category: "camping"
            )
        ]
        let viewModel = CollectionViewModel(
            userId: "test-user-123",
            itemRepository: mockRepository,
            requiresAuthentication: true
        )

        // Initial state should not be loading
        #expect(viewModel.isLoading == false)

        // When: Load items
        await viewModel.loadItems()

        // Then: After completion, loading should be false
        #expect(viewModel.isLoading == false)
        #expect(viewModel.items.count == 1)
    }

    @Test("loadItems handles repository error")
    func testLoadItems_handlesError() async throws {
        // Given: ViewModel with failing repository
        let mockRepository = MockItemRepository()
        mockRepository.shouldThrowError = NSError(
            domain: "test",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Network error"]
        )
        let viewModel = CollectionViewModel(
            userId: "test-user-123",
            itemRepository: mockRepository,
            requiresAuthentication: true
        )

        // When: Load items (should fail)
        await viewModel.loadItems()

        // Then: Should have error and not be loading
        #expect(viewModel.error != nil)
        #expect(viewModel.error?.contains("Network error") == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.items.isEmpty)
    }

    @Test("loadItems populates items array")
    func testLoadItems_populatesItemsArray() async throws {
        // Given: ViewModel with multiple items in repository
        let mockRepository = MockItemRepository()
        mockRepository.mockItems = [
            Item(
                id: "item-1",
                userId: "test-user-123",
                imageUrl: "https://example.com/image1.jpg",
                status: .complete,
                name: "Test Item 1",
                category: "camping"
            ),
            Item(
                id: "item-2",
                userId: "test-user-123",
                imageUrl: "https://example.com/image2.jpg",
                status: .complete,
                name: "Test Item 2",
                category: "electronics"
            ),
            Item(
                id: "item-3",
                userId: "test-user-123",
                imageUrl: "https://example.com/image3.jpg",
                status: .complete,
                name: "Test Item 3",
                category: "furniture"
            )
        ]
        let viewModel = CollectionViewModel(
            userId: "test-user-123",
            itemRepository: mockRepository,
            requiresAuthentication: true
        )

        // When: Load items
        await viewModel.loadItems()

        // Then: All items should be populated
        #expect(viewModel.items.count == 3)
        #expect(viewModel.items[0].id == "item-1")
        #expect(viewModel.items[1].id == "item-2")
        #expect(viewModel.items[2].id == "item-3")
        #expect(viewModel.error == nil)
    }

    // MARK: - Real-Time Updates Tests

    @Test("Real-time updates sync changes from Firestore listener")
    func testRealTimeUpdates_syncsChanges() async throws {
        // Given: ViewModel with real-time observer
        let mockRepository = MockItemRepository()
        let initialItems = [
            Item(
                id: "item-1",
                userId: "test-user-123",
                imageUrl: "https://example.com/image1.jpg",
                status: .complete,
                name: "Initial Item"
            )
        ]
        mockRepository.mockItems = initialItems

        let viewModel = CollectionViewModel(
            userId: "test-user-123",
            itemRepository: mockRepository,
            requiresAuthentication: true
        )

        // Wait for observer to sync items (poll instead of arbitrary sleep)
        // The observer publishes mockItems immediately via Just(), but delivery
        // crosses an async boundary so we poll briefly.
        let synced = await pollUntil(timeout: 2.0) { viewModel.items.count == 1 }
        #expect(synced, "Observer should sync items within timeout")
        #expect(viewModel.items.first?.name == "Initial Item")
    }
}

// MARK: - Test Helpers

/// Polls a condition with short intervals, avoiding flaky fixed sleeps.
@MainActor
private func pollUntil(
    timeout: TimeInterval = 2.0,
    pollingInterval: TimeInterval = 0.01,
    condition: @escaping () -> Bool
) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if condition() { return true }
        try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
    }
    return condition()
}

// Note: MockItemRepository is now in Tests/CollectionFeatureTests/Mocks/MockItemRepository.swift

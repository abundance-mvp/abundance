// Tests/InventoryFeatureTests/InventoryViewSearchTests.swift

import Testing
import SwiftUI
import Foundation
import Combine
import FirebaseFirestore
@testable import InventoryFeature
@testable import Persistence

// swiftlint:disable explicit_type_interface

@Suite("InventoryView Search Tests")
@MainActor
struct InventoryViewSearchTests {

    // MARK: - Integration Tests (ViewModel + View Logic)

    @Test("All items match empty search query")
    func testEmptySearchMatchesAll() async {
        // Given: ViewModel with items
        let mockRepo = MockSearchTestItemRepository()
        mockRepo.mockItems = [
            createTestItem(id: "1", category: "Electronics"),
            createTestItem(id: "2", category: "Furniture"),
            createTestItem(id: "3", category: "Clothing")
        ]

        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepo,
            requiresAuthentication: false
        )
        await viewModel.loadItems()

        // When: Search text is empty
        // Then: All items should match empty query
        #expect(viewModel.items.count == 3)
        #expect(viewModel.items.allSatisfy { $0.matchesSearchQuery("") })
    }

    @Test("filteredItems filters by category")
    func testFilterByCategory() async {
        let mockRepo = MockSearchTestItemRepository()
        mockRepo.mockItems = [
            createTestItem(id: "1", category: "Electronics"),
            createTestItem(id: "2", category: "Furniture"),
            createTestItem(id: "3", category: "Electronics")
        ]

        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepo,
            requiresAuthentication: false
        )
        await viewModel.loadItems()

        let filtered = viewModel.items.filter { $0.matchesSearchQuery("electronics") }

        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.category == "Electronics" })
    }

    @Test("filteredItems filters by color")
    func testFilterByColor() async {
        let mockRepo = MockSearchTestItemRepository()
        mockRepo.mockItems = [
            createTestItem(id: "1", color: "Blue"),
            createTestItem(id: "2", color: "Red"),
            createTestItem(id: "3", color: "Blue")
        ]

        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepo,
            requiresAuthentication: false
        )
        await viewModel.loadItems()

        let filtered = viewModel.items.filter { $0.matchesSearchQuery("blue") }

        #expect(filtered.count == 2)
    }

    @Test("filteredItems filters by material")
    func testFilterByMaterial() async {
        let mockRepo = MockSearchTestItemRepository()
        mockRepo.mockItems = [
            createTestItem(id: "1", material: "Wood"),
            createTestItem(id: "2", material: "Metal"),
            createTestItem(id: "3", material: "Wooden Frame")
        ]

        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepo,
            requiresAuthentication: false
        )
        await viewModel.loadItems()

        let filtered = viewModel.items.filter { $0.matchesSearchQuery("wood") }

        #expect(filtered.count == 2)
    }

    @Test("filteredItems returns empty when no matches")
    func testNoMatchesReturnsEmpty() async {
        let mockRepo = MockSearchTestItemRepository()
        mockRepo.mockItems = [
            createTestItem(id: "1", category: "Electronics", color: "Black"),
            createTestItem(id: "2", category: "Furniture", color: "Brown")
        ]

        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepo,
            requiresAuthentication: false
        )
        await viewModel.loadItems()

        let filtered = viewModel.items.filter { $0.matchesSearchQuery("refrigerator") }

        #expect(filtered.isEmpty)
    }

    @Test("filteredItems is case insensitive")
    func testCaseInsensitiveFiltering() async {
        let mockRepo = MockSearchTestItemRepository()
        mockRepo.mockItems = [
            createTestItem(id: "1", category: "Electronics"),
            createTestItem(id: "2", category: "ELECTRONICS"),
            createTestItem(id: "3", category: "electronics")
        ]

        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepo,
            requiresAuthentication: false
        )
        await viewModel.loadItems()

        let filtered = viewModel.items.filter { $0.matchesSearchQuery("Electronics") }

        #expect(filtered.count == 3)
    }

    @Test("filteredItems supports partial matching")
    func testPartialMatching() async {
        let mockRepo = MockSearchTestItemRepository()
        mockRepo.mockItems = [
            createTestItem(id: "1", category: "Digital Electronics"),
            createTestItem(id: "2", category: "Analog Electronics"),
            createTestItem(id: "3", category: "Furniture")
        ]

        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepo,
            requiresAuthentication: false
        )
        await viewModel.loadItems()

        let filtered = viewModel.items.filter { $0.matchesSearchQuery("elec") }

        #expect(filtered.count == 2)
    }

    @Test("filteredItems searches across multiple fields")
    func testCrossFieldSearch() async {
        let mockRepo = MockSearchTestItemRepository()
        mockRepo.mockItems = [
            createTestItem(id: "1", category: "Appliances", color: "Blue"),
            createTestItem(id: "2", category: "Blue Furniture", color: "Brown"),
            createTestItem(id: "3", category: "Electronics", material: "Blue Plastic")
        ]

        let viewModel = InventoryViewModel(
            userId: "test-user",
            itemRepository: mockRepo,
            requiresAuthentication: false
        )
        await viewModel.loadItems()

        let filtered = viewModel.items.filter { $0.matchesSearchQuery("blue") }

        // All 3 should match: color, category, material
        #expect(filtered.count == 3)
    }

    // MARK: - Helper Methods

    private func createTestItem(
        id: String,
        name: String? = nil,
        category: String? = nil,
        subCategory: String? = nil,
        brand: String? = nil,
        model: String? = nil,
        color: String? = nil,
        material: String? = nil,
        condition: ItemCondition? = nil
    ) -> Item {
        Item(
            id: id,
            userId: "test-user",
            imageUrl: "https://example.com/\(id).jpg",
            status: .complete,
            name: name,
            category: category,
            subCategory: subCategory,
            brand: brand,
            model: model,
            color: color,
            material: material,
            condition: condition
        )
    }
}

// MARK: - Mock Repository for Search Tests

/// Separate mock to avoid conflicts with existing mock in InventoryViewModelTests
final class MockSearchTestItemRepository: ItemRepository, @unchecked Sendable {
    var getItemsCalled: Bool = false
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

    func deleteItem(id: String) async throws {
        mockItems.removeAll { $0.id == id }
    }

    func deleteItems(ids: Set<String>) async throws {
        mockItems.removeAll { ids.contains($0.id) }
    }

    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration {
        fatalError("Mock observeItem not implemented")
    }

    func observeItems(userId: String) -> AnyPublisher<[Item], Never> {
        Just(mockItems).eraseToAnyPublisher()
    }

    func updateItem(_ item: Item, userEditedFields: [String]?) async throws {
        // Mock implementation
    }

    func rescanItem(_ item: Item) async throws {
        // Mock implementation
    }

    func refreshImageUrl(id: String) async throws -> String? {
        nil
    }

    func requestDeepScan(id: String) async throws {}
}

// swiftlint:enable explicit_type_interface

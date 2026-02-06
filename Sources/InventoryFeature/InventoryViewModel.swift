import Foundation
import Observation
import FirebaseAuth
import Combine
import Persistence

/// ViewModel for Inventory list view
/// **Patterns:** DESIGN-037 Pattern 1 (Constructor Injection), Pattern 2 (Real-time Listener)
@MainActor
@Observable
public final class InventoryViewModel {
    // @Observable tracks changes automatically - no @Published needed
    public var items: [Item] = []
    public var isLoading: Bool = false
    public var error: String?
    public var deleteError: String?
    public var recatalogError: String?
    public var searchText: String = ""

    /// Filters items based on search text matching any searchable text field.
    /// Searches: category, color, material, condition (and name, subCategory, brand, model after Stage 3.1)
    /// Uses case-insensitive, locale-aware matching per Apple best practices.
    public var filteredItems: [Item] {
        guard !searchText.isEmpty else {
            return items
        }
        return items.filter { $0.matchesSearchQuery(searchText) }
    }

    private let itemRepository: ItemRepository
    private let userId: String?
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()

    /// Initialize InventoryViewModel
    /// - Parameters:
    ///   - userId: User ID. If nil, falls back to current Firebase user.
    ///   - itemRepository: Repository for item persistence (injectable for testing)
    ///   - requiresAuthentication: If true, sets error when no userId available. Default true.
    ///                             Pass false for SwiftUI Previews/testing without auth.
    ///   - authProvider: Closure to provide auth user ID (injectable, @Sendable for Swift 6)
    public init(
        userId: String? = nil,
        itemRepository: ItemRepository = ItemService(),
        requiresAuthentication: Bool = true,
        authProvider: (@Sendable () -> String?)? = nil
    ) {
        // Resolve userId: explicit > authProvider > Firebase Auth (only if auth required)
        let resolvedUserId: String?
        if let userId = userId {
            resolvedUserId = userId
        } else if let provider = authProvider {
            resolvedUserId = provider()
        } else if requiresAuthentication {
            // Only call Firebase Auth when authentication is required and no userId provided
            resolvedUserId = Auth.auth().currentUser?.uid
        } else {
            resolvedUserId = nil
        }

        if requiresAuthentication && resolvedUserId == nil {
            self.userId = nil
            self.itemRepository = itemRepository
            self.error = "Authentication required"
            return
        }

        self.userId = resolvedUserId
        self.itemRepository = itemRepository
        observeItems()
    }

    // MARK: - Public Methods

    public func loadItems() async {
        guard let userId = userId else {
            error = "Authentication required"
            return
        }

        isLoading = true
        error = nil

        do {
            items = try await itemRepository.getItems(userId: userId)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    /// Deletes a single item with optimistic update
    /// - Parameter item: The item to delete
    /// - Note: Optimistically removes item from local array, rolls back on failure
    public func deleteItem(_ item: Item) async {
        // Store item for potential rollback
        let itemIndex: Int? = items.firstIndex(where: { $0.id == item.id })

        // Optimistic removal (View handles animation)
        items.removeAll { $0.id == item.id }
        deleteError = nil

        do {
            try await itemRepository.deleteItem(id: item.id)
        } catch {
            // Rollback: re-insert item at original position
            if let index = itemIndex, index < items.count {
                items.insert(item, at: index)
            } else {
                items.append(item)
            }
            deleteError = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    /// Deletes multiple items with optimistic update
    /// - Parameter ids: Set of item IDs to delete
    /// - Note: Optimistically removes items, rolls back all on any failure
    public func deleteItems(ids: Set<String>) async {
        guard !ids.isEmpty else { return }

        // Store items for potential rollback
        let originalItems: [Item] = items

        // Optimistic removal (View handles animation)
        items.removeAll { ids.contains($0.id) }
        deleteError = nil

        do {
            try await itemRepository.deleteItems(ids: ids)
        } catch {
            // Rollback: restore original items array
            items = originalItems
            deleteError = "Failed to delete \(ids.count) items: \(error.localizedDescription)"
        }
    }

    /// Re-catalogs an item by resetting its status to pending
    /// - Parameter item: The item to re-catalog
    /// - Note: Triggers the AI pipeline to re-process the item
    public func recatalogItem(_ item: Item) async {
        do {
            try await itemRepository.rescanItem(item)
        } catch {
            recatalogError = "Failed to re-catalog item: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    /// Real-time listener for items
    /// **Pattern:** DESIGN-037 Pattern 2 (Firestore Real-Time Listener Integration)
    private func observeItems() {
        guard let userId = userId else { return }

        itemRepository.observeItems(userId: userId)
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }
}

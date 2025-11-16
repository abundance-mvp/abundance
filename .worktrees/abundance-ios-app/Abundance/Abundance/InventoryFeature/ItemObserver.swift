import SwiftUI
@preconcurrency import FirebaseFirestore

/// ObservableObject for real-time item updates from Firestore
/// **Pattern:** DESIGN-037 Pattern 2 (Firestore Real-Time Listener Integration)
@MainActor
final class ItemObserver: ObservableObject {
    // MARK: - Published Properties

    @Published var item: Item?
    @Published var isLoading: Bool = true
    @Published var error: String?

    // MARK: - Dependencies

    private let itemRepository: ItemRepository
    nonisolated(unsafe) private var listener: ListenerRegistration?

    // MARK: - Initialization

    init(itemRepository: ItemRepository = ItemService()) {
        self.itemRepository = itemRepository
    }

    // MARK: - Public Methods

    /// Observe real-time updates for a specific item
    /// - Parameter itemId: Item document ID to observe
    func observe(itemId: String) {
        isLoading = true
        error = nil

        // Clean up previous listener if exists
        listener?.remove()

        // Set up real-time listener
        listener = itemRepository.observeItem(id: itemId) { [weak self] updatedItem in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoading = false
                if let updatedItem = updatedItem {
                    self.item = updatedItem
                    self.error = nil
                } else {
                    self.error = "Item not found"
                }
            }
        }
    }

    /// Stop observing item updates
    func stopObserving() {
        listener?.remove()
        listener = nil
        item = nil
        isLoading = false
        error = nil
    }

    // MARK: - Lifecycle

    deinit {
        listener?.remove()
    }
}

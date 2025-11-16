import Foundation
import Persistence
import FirebaseAuth
import Combine

/// ViewModel for Inventory list view
/// **Patterns:** DESIGN-037 Pattern 1 (Constructor Injection), Pattern 2 (Real-time Listener)
@MainActor
public final class InventoryViewModel: ObservableObject {
    @Published public var items: [Item] = []
    @Published public var isLoading = false
    @Published public var error: String?

    private let itemRepository: ItemRepository
    private let userId: String
    private var cancellables = Set<AnyCancellable>()

    public init(
        userId: String? = nil,
        itemRepository: ItemRepository = ItemService()
    ) {
        self.userId = userId ?? Auth.auth().currentUser?.uid ?? ""
        self.itemRepository = itemRepository
        observeItems()
    }

    // MARK: - Public Methods

    public func loadItems() async {
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

    // MARK: - Private Methods

    /// Real-time listener for items
    /// **Pattern:** DESIGN-037 Pattern 2 (Firestore Real-Time Listener Integration)
    private func observeItems() {
        itemRepository.observeItems(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }
}

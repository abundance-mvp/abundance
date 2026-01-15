import Foundation
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
    public var isLoading = false
    public var error: String?

    private let itemRepository: ItemRepository
    private let userId: String?
    private var cancellables = Set<AnyCancellable>()

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

    // MARK: - Private Methods

    /// Real-time listener for items
    /// **Pattern:** DESIGN-037 Pattern 2 (Firestore Real-Time Listener Integration)
    private func observeItems() {
        guard let userId = userId else { return }

        itemRepository.observeItems(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }
}

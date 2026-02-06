#if DEBUG
import Foundation
import Combine
import FirebaseFirestore
import Persistence

// MARK: - Simulator Item Repository

/// In-memory ItemRepository for simulator testing.
/// Provides pre-seeded items without requiring Firebase Auth or Firestore.
@MainActor
final class SimulatorItemRepository: @preconcurrency ItemRepository {
    private var items: [Item]
    private let subject = PassthroughSubject<[Item], Never>()

    init(items: [Item] = SimulatorItemFactory.makeItems()) {
        self.items = items
    }

    // MARK: - ItemReadRepository

    func getItem(id: String) async throws -> Item? {
        items.first { $0.id == id }
    }

    func getItems(userId: String) async throws -> [Item] {
        items.filter { $0.userId == userId }
    }

    // MARK: - ItemObservableRepository

    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration {
        onChange(items.first { $0.id == id })
        return NoOpListenerRegistration()
    }

    func observeItems(userId: String) -> AnyPublisher<[Item], Never> {
        // Emit current items immediately, then future updates
        let initial = Just(items.filter { $0.userId == userId })
            .eraseToAnyPublisher()
        let updates = subject
            .map { $0.filter { $0.userId == userId } }
            .eraseToAnyPublisher()
        return initial.merge(with: updates).eraseToAnyPublisher()
    }

    // MARK: - ItemWriteRepository

    func createItem(userId: String, imageUrl: String) async throws -> String {
        let id = UUID().uuidString
        let item = Item(id: id, userId: userId, imageUrl: imageUrl, status: .pending)
        items.append(item)
        subject.send(items)
        return id
    }

    func createItemWithLayer1Metadata(
        itemId: String, userId: String, imageUrl: String, layer1Metadata: Layer1Metadata
    ) async throws {
        // No-op for simulator
    }

    func createItemWithPhotoMetadata(
        itemId: String, userId: String, imageUrl: String,
        layer1Metadata: Layer1Metadata, photoMetadata: PhotoMetadata
    ) async throws {
        // No-op for simulator
    }

    func updateItem(_ item: Item, userEditedFields: [String]? = nil) async throws {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            subject.send(items)
        }
    }

    func rescanItem(_ item: Item) async throws {
        // No-op for simulator
    }

    func deleteItem(id: String) async throws {
        items.removeAll { $0.id == id }
        subject.send(items)
    }

    func deleteItems(ids: Set<String>) async throws {
        items.removeAll { ids.contains($0.id) }
        subject.send(items)
    }
}

// MARK: - No-Op Listener Registration

/// Stub for ListenerRegistration conformance without Firestore.
private final class NoOpListenerRegistration: NSObject, ListenerRegistration {
    func remove() {}
}

// MARK: - Simulator Item Factory

/// Creates 8 test items covering various statuses, conditions, and categories.
enum SimulatorItemFactory {
    static let userId = "simulator-debug-user"

    static func makeItems() -> [Item] {
        let now = Date()
        return [
            Item(
                id: "sim-001",
                userId: userId,
                imageUrl: "https://picsum.photos/seed/coleman-tent/400/400",
                status: .complete,
                name: "Coleman Sundome Tent",
                category: "Outdoor & Camping",
                subCategory: "Tents",
                brand: "Coleman",
                model: "Sundome 4-Person",
                color: "Green/Gray",
                material: "Polyester",
                condition: .good,
                dimensions: "4-person, 9' x 7'",
                quantity: 1,
                estimatedValue: 89.99,
                confidence: .high,
                createdAt: now.addingTimeInterval(-86400 * 7),
                updatedAt: now.addingTimeInterval(-86400 * 2)
            ),
            Item(
                id: "sim-002",
                userId: userId,
                imageUrl: "https://picsum.photos/seed/kitchenaid-mixer/400/400",
                status: .complete,
                name: "KitchenAid Stand Mixer",
                category: "Kitchen Appliances",
                subCategory: "Mixers",
                brand: "KitchenAid",
                model: "Artisan 5-Qt",
                color: "Empire Red",
                material: "Die-cast metal",
                condition: .likeNew,
                quantity: 1,
                estimatedValue: 349.99,
                confidence: .high,
                createdAt: now.addingTimeInterval(-86400 * 6),
                updatedAt: now.addingTimeInterval(-86400 * 1)
            ),
            Item(
                id: "sim-003",
                userId: userId,
                imageUrl: "https://picsum.photos/seed/bose-qc45/400/400",
                status: .layer2aComplete,
                name: "Bose QuietComfort 45",
                category: "Electronics",
                subCategory: "Headphones",
                brand: "Bose",
                model: "QC45",
                color: "Black",
                material: "Plastic/Leather",
                condition: .good,
                quantity: 1,
                estimatedValue: 229.00,
                confidence: .medium,
                createdAt: now.addingTimeInterval(-86400 * 5),
                updatedAt: now.addingTimeInterval(-86400 * 3)
            ),
            Item(
                id: "sim-004",
                userId: userId,
                imageUrl: "https://picsum.photos/seed/ikea-kallax/400/400",
                status: .complete,
                name: "IKEA KALLAX Shelf",
                category: "Furniture",
                subCategory: "Shelving",
                brand: "IKEA",
                model: "KALLAX 4x2",
                color: "White",
                material: "Particleboard",
                condition: .fair,
                dimensions: "77 x 147 cm",
                quantity: 1,
                estimatedValue: 69.99,
                confidence: .high,
                createdAt: now.addingTimeInterval(-86400 * 4),
                updatedAt: now.addingTimeInterval(-86400 * 4)
            ),
            Item(
                id: "sim-005",
                userId: userId,
                imageUrl: "https://picsum.photos/seed/dyson-v15/400/400",
                status: .complete,
                name: "Dyson V15 Detect",
                category: "Home Appliances",
                subCategory: "Vacuums",
                brand: "Dyson",
                model: "V15 Detect",
                color: "Gold/Nickel",
                material: "Polycarbonate",
                condition: .new,
                quantity: 1,
                estimatedValue: 649.99,
                confidence: .high,
                createdAt: now.addingTimeInterval(-86400 * 3),
                updatedAt: now.addingTimeInterval(-86400 * 1)
            ),
            Item(
                id: "sim-006",
                userId: userId,
                imageUrl: "https://picsum.photos/seed/vintage-satchel/400/400",
                status: .layer2aComplete,
                name: "Vintage Leather Satchel",
                category: "Bags & Accessories",
                subCategory: "Bags",
                color: "Brown",
                material: "Leather",
                condition: .good,
                quantity: 1,
                estimatedValue: 45.00,
                confidence: .medium,
                createdAt: now.addingTimeInterval(-86400 * 2),
                updatedAt: now.addingTimeInterval(-86400 * 2)
            ),
            Item(
                id: "sim-007",
                userId: userId,
                imageUrl: "https://picsum.photos/seed/unknown-electronics/400/400",
                status: .pending,
                name: "Unknown Electronics",
                category: "Electronics",
                createdAt: now.addingTimeInterval(-3600),
                updatedAt: now.addingTimeInterval(-3600)
            ),
            Item(
                id: "sim-008",
                userId: userId,
                imageUrl: "https://picsum.photos/seed/failed-item/400/400",
                status: .failed,
                processingNotes: "Layer 2a extraction timed out after 3 retries",
                createdAt: now.addingTimeInterval(-7200),
                updatedAt: now.addingTimeInterval(-1800)
            ),
        ]
    }
}
#endif

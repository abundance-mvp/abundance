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
/// Images loaded from bundled DebugResources (object-1..8.jpeg).
enum SimulatorItemFactory {
    static let userId = "simulator-debug-user"

    /// Returns a file URL string for a bundled debug image, with picsum fallback.
    private static func imageUrl(for name: String) -> String {
        // Xcode project copies DebugResources as a folder → images in subdirectory
        // SPM .process() flattens resources into Bundle.module root
        let url: URL? =
            Bundle.main.url(forResource: name, withExtension: "jpeg", subdirectory: "DebugResources")
            ?? Bundle.main.url(forResource: name, withExtension: "jpeg")
        return url?.absoluteString ?? "https://picsum.photos/seed/\(name)/400/400"
    }

    static func makeItems() -> [Item] {
        let now = Date()
        return [
            // 1. MelodySusie nail drill — pink, boxed, new condition
            Item(
                id: "sim-001",
                userId: userId,
                imageUrl: imageUrl(for: "object-1"),
                status: .complete,
                name: "MelodySusie Nail Drill",
                category: "Beauty & Personal Care",
                subCategory: "Nail Tools",
                brand: "MelodySusie",
                color: "Pink",
                material: "Plastic",
                condition: .new,
                quantity: 1,
                estimatedValue: 35.99,
                confidence: .high,
                createdAt: now.addingTimeInterval(-86400 * 7),
                updatedAt: now.addingTimeInterval(-86400 * 2)
            ),
            // 2. Hurma knife sharpener — beige/brown, used
            Item(
                id: "sim-002",
                userId: userId,
                imageUrl: imageUrl(for: "object-2"),
                status: .complete,
                name: "Hurma Knife Sharpener",
                category: "Kitchen Appliances",
                subCategory: "Knife Sharpeners",
                brand: "Hurma",
                color: "Beige/Brown",
                material: "Plastic/Ceramic",
                condition: .good,
                quantity: 1,
                estimatedValue: 19.99,
                confidence: .high,
                createdAt: now.addingTimeInterval(-86400 * 6),
                updatedAt: now.addingTimeInterval(-86400 * 1)
            ),
            // 3. Panasonic vintage AM/FM radio — wood cabinet, fair condition
            Item(
                id: "sim-003",
                userId: userId,
                imageUrl: imageUrl(for: "object-3"),
                status: .layer2aComplete,
                name: "Panasonic AM/FM Radio",
                category: "Electronics",
                subCategory: "Radios",
                brand: "Panasonic",
                color: "Walnut/Silver",
                material: "Wood/Metal",
                condition: .fair,
                quantity: 1,
                estimatedValue: 65.00,
                confidence: .medium,
                createdAt: now.addingTimeInterval(-86400 * 5),
                updatedAt: now.addingTimeInterval(-86400 * 3)
            ),
            // 4. Ceramic plant pot on metal stand with trailing vine
            Item(
                id: "sim-004",
                userId: userId,
                imageUrl: imageUrl(for: "object-4"),
                status: .complete,
                name: "Ceramic Plant Pot with Stand",
                category: "Home & Garden",
                subCategory: "Planters",
                color: "Cream/Terracotta",
                material: "Ceramic/Metal",
                condition: .good,
                quantity: 1,
                estimatedValue: 28.00,
                confidence: .high,
                createdAt: now.addingTimeInterval(-86400 * 4),
                updatedAt: now.addingTimeInterval(-86400 * 4)
            ),
            // 5. Amber glass bowl vase
            Item(
                id: "sim-005",
                userId: userId,
                imageUrl: imageUrl(for: "object-5"),
                status: .complete,
                name: "Amber Glass Bowl Vase",
                category: "Home Decor",
                subCategory: "Vases",
                color: "Amber",
                material: "Glass",
                condition: .good,
                quantity: 1,
                estimatedValue: 42.00,
                confidence: .high,
                createdAt: now.addingTimeInterval(-86400 * 3),
                updatedAt: now.addingTimeInterval(-86400 * 1)
            ),
            // 6. Round gold-framed wall mirror
            Item(
                id: "sim-006",
                userId: userId,
                imageUrl: imageUrl(for: "object-6"),
                status: .layer2aComplete,
                name: "Round Gold Wall Mirror",
                category: "Furniture",
                subCategory: "Mirrors",
                color: "Gold",
                material: "Glass/Metal",
                condition: .good,
                dimensions: "30\" diameter",
                quantity: 1,
                estimatedValue: 89.00,
                confidence: .medium,
                createdAt: now.addingTimeInterval(-86400 * 2),
                updatedAt: now.addingTimeInterval(-86400 * 2)
            ),
            // 7. Non-stick frying pan — pending (minimal metadata)
            Item(
                id: "sim-007",
                userId: userId,
                imageUrl: imageUrl(for: "object-7"),
                status: .pending,
                category: "Kitchen Appliances",
                createdAt: now.addingTimeInterval(-3600),
                updatedAt: now.addingTimeInterval(-3600)
            ),
            // 8. Yellow ceramic bowl — failed processing
            Item(
                id: "sim-008",
                userId: userId,
                imageUrl: imageUrl(for: "object-8"),
                status: .failed,
                processingNotes: "Layer 2a extraction timed out after 3 retries",
                createdAt: now.addingTimeInterval(-7200),
                updatedAt: now.addingTimeInterval(-1800)
            ),
        ]
    }
}
#endif

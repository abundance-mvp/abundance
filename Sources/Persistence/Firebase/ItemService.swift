import Foundation
import FirebaseFirestore
import Combine
import os

/// Metadata from Layer 1 (on-device YOLO detection)
/// Captures detection results before Layer 2 cloud processing
public struct Layer1Metadata: Sendable {
    public let detectedClass: String
    public let confidence: Double
    public let boundingBox: CGRect
    public let qualityScore: Double

    public init(detectedClass: String, confidence: Double, boundingBox: CGRect, qualityScore: Double) {
        self.detectedClass = detectedClass
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.qualityScore = qualityScore
    }
}

/// Repository protocol for Item persistence operations
/// **Pattern:** DESIGN-037 Pattern 1 (Repository Protocol)
public protocol ItemRepository: Sendable {
    /// Creates a new item document in Firestore
    func createItem(userId: String, imageUrl: String) async throws -> String

    /// Creates a new item document with Layer 1 metadata for Layer 1→2 handoff
    func createItemWithLayer1Metadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata
    ) async throws

    /// Fetches a single item by ID
    func getItem(id: String) async throws -> Item?

    /// Fetches all items for a user (sorted by creation date, newest first)
    func getItems(userId: String) async throws -> [Item]

    /// Real-time listener for item updates
    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration

    /// Real-time listener for all user items
    func observeItems(userId: String) -> AnyPublisher<[Item], Never>
}

/// Service for managing Item documents in Firestore
/// Triggers: Creating item with status="pending" triggers onItemCreated → Layer 2a extraction
///
/// **Pattern:** DESIGN-037 Pattern 1 (Repository Protocol)
public final class ItemService: ItemRepository {
    /// Firestore instance for database operations
    /// Thread safety: Firestore SDK is thread-safe; nonisolated(unsafe) allows Sendable conformance
    nonisolated(unsafe) private let db: Firestore

    public init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    /// Creates a new item document in Firestore
    /// Triggers Layer 2a extraction via onItemCreated cloud function
    ///
    /// - Parameters:
    ///   - userId: Owner's user ID
    ///   - imageUrl: Public URL of uploaded image in Firebase Storage
    /// - Returns: Generated item document ID
    public func createItem(userId: String, imageUrl: String) async throws -> String {
        let itemRef = db.collection("items").document()
        let itemId = itemRef.documentID

        let data: [String: Any] = [
            "id": itemId,
            "userId": userId,
            "imageUrl": imageUrl,
            "status": ItemStatus.pending.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await itemRef.setData(data)
        return itemId
    }

    /// Creates a new item document with Layer 1 metadata for Layer 1→2 handoff
    /// Triggers Layer 2a extraction via onItemCreated cloud function
    ///
    /// - Parameters:
    ///   - itemId: Unique item ID (from YOLO detection)
    ///   - userId: Owner's user ID
    ///   - imageUrl: Public URL of uploaded image in Firebase Storage
    ///   - layer1Metadata: On-device detection results (class, confidence, bounding box, quality)
    public func createItemWithLayer1Metadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata
    ) async throws {
        let itemRef = db.collection("items").document(itemId)

        let data: [String: Any] = [
            "userId": userId,
            "imageUrl": imageUrl,
            "aiAnalysis": [
                "layer1": [
                    "detectedClass": layer1Metadata.detectedClass,
                    "confidence": layer1Metadata.confidence,
                    "boundingBox": [
                        "x": layer1Metadata.boundingBox.origin.x,
                        "y": layer1Metadata.boundingBox.origin.y,
                        "width": layer1Metadata.boundingBox.size.width,
                        "height": layer1Metadata.boundingBox.size.height
                    ],
                    "qualityScore": layer1Metadata.qualityScore
                ]
            ],
            "status": ItemStatus.pending.rawValue,  // Triggers Cloud Function for Layer 2a
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await itemRef.setData(data)
    }

    /// Fetches a single item by ID
    public func getItem(id: String) async throws -> Item? {
        let doc = try await db.collection("items").document(id).getDocument()
        guard let data = doc.data() else { return nil }
        return try decodeItem(from: data, id: id)
    }

    /// Fetches all items for a user (sorted by creation date, newest first)
    public func getItems(userId: String) async throws -> [Item] {
        let snapshot = try await db.collection("items")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try decodeItem(from: doc.data(), id: doc.documentID)
        }
    }

    /// Real-time listener for item updates
    /// Use this to observe Layer 2a extraction completion
    ///
    /// **Pattern:** DESIGN-037 Pattern 2 (Firestore Real-Time Listener Integration)
    public func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration {
        db.collection("items").document(id).addSnapshotListener { snapshot, error in
            if let error = error {
                os_log(.error, log: .default, "observeItem error for id=%{public}@: %{public}@", id, error.localizedDescription)
                onChange(nil)
                return
            }

            guard let data = snapshot?.data() else {
                onChange(nil)
                return
            }

            do {
                let item = try self.decodeItem(from: data, id: id)
                onChange(item)
            } catch {
                os_log(.error, log: .default, "Failed to decode item id=%{public}@: %{public}@", id, error.localizedDescription)
                onChange(nil)
            }
        }
    }

    /// Real-time listener for all user items
    /// **Pattern:** DESIGN-037 Pattern 2 (Firestore Real-Time Listener Integration)
    public func observeItems(userId: String) -> AnyPublisher<[Item], Never> {
        let subject = PassthroughSubject<[Item], Never>()

        let listener = db.collection("items")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    os_log(.error, log: .default, "observeItems error for userId=%{public}@: %{public}@", userId, error.localizedDescription)
                    subject.send([])
                    return
                }

                guard let snapshot = snapshot else {
                    subject.send([])
                    return
                }

                let items = snapshot.documents.compactMap { doc -> Item? in
                    do {
                        return try self.decodeItem(from: doc.data(), id: doc.documentID)
                    } catch {
                        os_log(.error, log: .default, "Failed to decode item id=%{public}@: %{public}@", doc.documentID, error.localizedDescription)
                        return nil
                    }
                }

                subject.send(items)
            }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove() // Clean up listener on cancel
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Private Helpers

    private func decodeItem(from data: [String: Any], id: String) throws -> Item {
        // Firestore timestamps need special handling
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()

        return Item(
            id: id,
            userId: data["userId"] as? String ?? "",
            imageUrl: data["imageUrl"] as? String ?? "",
            status: ItemStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
            category: data["category"] as? String,
            color: data["color"] as? String,
            material: data["material"] as? String,
            condition: data["condition"] as? String,
            confidence: data["confidence"] as? Double,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

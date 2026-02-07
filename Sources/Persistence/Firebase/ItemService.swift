import Foundation
import FirebaseFirestore
import FirebaseStorage
import Combine
import os

// MARK: - Set Chunking Extension

extension Set {
    /// Splits a set into chunks of a specified size
    /// - Parameter size: Maximum size of each chunk
    /// - Returns: Array of arrays, each containing up to `size` elements
    func chunked(into size: Int) -> [[Element]] {
        let array = Array(self)
        return stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<Swift.min($0 + size, array.count)])
        }
    }
}

/// Metadata from Layer 1 (object detection)
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

// MARK: - Segregated Repository Protocols (Interface Segregation Principle)

/// Read-only operations for fetching items
/// **Pattern:** DESIGN-037 Pattern 1 (Repository Protocol) - Interface Segregation
public protocol ItemReadRepository: Sendable {
    /// Fetches a single item by ID
    func getItem(id: String) async throws -> Item?

    /// Fetches all items for a user (sorted by creation date, newest first)
    func getItems(userId: String) async throws -> [Item]
}

/// Write operations for creating, updating, and deleting items
/// **Pattern:** DESIGN-037 Pattern 1 (Repository Protocol) - Interface Segregation
public protocol ItemWriteRepository: Sendable {
    /// Creates a new item document in Firestore
    func createItem(userId: String, imageUrl: String) async throws -> String

    /// Creates a new item document with Layer 1 metadata for Layer 1→2 handoff
    func createItemWithLayer1Metadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata
    ) async throws

    /// Creates a new item document with Layer 1 metadata AND photo metadata
    /// Triggers Layer 2a extraction via onItemCreated cloud function
    func createItemWithPhotoMetadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata,
        photoMetadata: PhotoMetadata
    ) async throws

    /// Updates an existing item with optional user-edited field tracking
    /// - Parameters:
    ///   - item: Updated item data
    ///   - userEditedFields: Array of field names that were manually edited (for training data)
    /// - Throws: Error if Firestore write fails
    func updateItem(_ item: Item, userEditedFields: [String]?) async throws

    /// Triggers a rescan by updating image URL and status to pending
    /// - Parameter item: Item with new imageUrl and updated fields
    /// - Throws: Error if Firestore write fails
    func rescanItem(_ item: Item) async throws

    /// Regenerate the download URL for an item's image if expired
    /// - Parameter id: The item document ID
    /// - Returns: Fresh download URL, or nil if item has no storage path
    func refreshImageUrl(id: String) async throws -> String?

    /// Request a deep scan for an item
    /// - Parameter id: The item document ID
    func requestDeepScan(id: String) async throws

    /// Deletes a single item by ID
    /// - Parameter id: The item document ID
    /// - Throws: Error if deletion fails
    func deleteItem(id: String) async throws

    /// Deletes multiple items in a batch
    /// - Parameter ids: Set of item document IDs to delete
    /// - Throws: Error if batch deletion fails
    func deleteItems(ids: Set<String>) async throws
}

/// Observable/reactive operations for real-time updates
/// **Pattern:** DESIGN-037 Pattern 2 (Firestore Real-Time Listener Integration)
public protocol ItemObservableRepository: Sendable {
    /// Real-time listener for item updates
    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration

    /// Real-time listener for all user items
    func observeItems(userId: String) -> AnyPublisher<[Item], Never>
}

/// Full repository protocol combining all operations (backward compatible)
/// **Pattern:** DESIGN-037 Pattern 1 (Repository Protocol)
public protocol ItemRepository: ItemReadRepository, ItemWriteRepository, ItemObservableRepository {}

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
            "status": "pending",
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
    ///   - itemId: Unique item ID (from object detection)
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
            "status": "pending",  // Triggers Cloud Function for Layer 2a
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await itemRef.setData(data)
    }

    /// Creates a new item document with Layer 1 metadata AND photo metadata
    /// Triggers Layer 2a extraction via onItemCreated cloud function
    ///
    /// - Parameters:
    ///   - itemId: Unique item ID (from object detection)
    ///   - userId: Owner's user ID
    ///   - imageUrl: Public URL of uploaded image in Firebase Storage
    ///   - layer1Metadata: On-device detection results
    ///   - photoMetadata: Photo capture metadata for fraud prevention
    public func createItemWithPhotoMetadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata,
        photoMetadata: PhotoMetadata
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
            "photoMetadata": photoMetadata.toFirestoreData(),
            "status": "pending",
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
        db.collection("items").document(id).addSnapshotListener { [weak self] snapshot, error in
            guard let self else {
                onChange(nil)
                return
            }

            if let error = error {
                os_log(
                    .error, log: .default,
                    "observeItem error for id=%{public}@: %{public}@",
                    id, error.localizedDescription
                )
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
                os_log(
                    .error, log: .default,
                    "Failed to decode item id=%{public}@: %{public}@",
                    id, error.localizedDescription
                )
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
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else {
                    subject.send([])
                    return
                }

                if let error = error {
                    os_log(
                        .error, log: .default,
                        "observeItems error for userId=%{public}@: %{public}@",
                        userId, error.localizedDescription
                    )
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
                        os_log(
                            .error, log: .default,
                            "Failed to decode item id=%{public}@: %{public}@",
                            doc.documentID, error.localizedDescription
                        )
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

    // MARK: - Deep Scan

    /// Request a deep scan for an item (sets deepScanRequested=true, status=pending)
    public func requestDeepScan(id: String) async throws {
        let itemRef = db.collection("items").document(id)
        try await itemRef.updateData([
            "deepScanRequested": true,
            "status": "pending",
            "updatedAt": FieldValue.serverTimestamp()
        ])
        os_log(.info, log: .default, "Requested deep scan for item id=%{public}@", id)
    }

    // MARK: - Image URL Refresh

    /// Regenerate the download URL for an item's image if expired
    /// Reads `imagePath` from Firestore, generates a new download URL from Storage
    public func refreshImageUrl(id: String) async throws -> String? {
        let doc = try await db.collection("items").document(id).getDocument()
        guard let data = doc.data() else { return nil }

        // If the item has an imagePath (GCS path), generate a fresh download URL
        guard let imagePath = data["imagePath"] as? String, !imagePath.isEmpty else {
            // No storage path — imageUrl was either direct or already a download URL
            return data["imageUrl"] as? String
        }

        let storageRef = Storage.storage().reference().child(imagePath)
        let freshUrl = try await storageRef.downloadURL()
        let urlString = freshUrl.absoluteString

        // Update Firestore with the fresh URL
        try await db.collection("items").document(id).updateData([
            "imageUrl": urlString,
            "updatedAt": FieldValue.serverTimestamp()
        ])

        return urlString
    }

    // MARK: - Delete Operations

    /// Deletes a single item document from Firestore
    /// - Parameter id: The item document ID to delete
    /// - Note: Cloud Function onItemDeleted handles Cloud Storage cleanup
    public func deleteItem(id: String) async throws {
        try await db.collection("items").document(id).delete()
        os_log(.info, log: .default, "Deleted item id=%{public}@", id)
    }

    /// Deletes multiple items in a Firestore batch
    /// - Parameter ids: Set of item document IDs to delete
    /// - Note: Firestore batch limit is 500 writes; larger sets are chunked
    public func deleteItems(ids: Set<String>) async throws {
        guard !ids.isEmpty else { return }

        // Firestore batch limit is 500 operations
        let chunks = ids.chunked(into: 500)

        for chunk in chunks {
            let batch = db.batch()
            for id in chunk {
                let ref = db.collection("items").document(id)
                batch.deleteDocument(ref)
            }
            try await batch.commit()
        }

        os_log(.info, log: .default, "Batch deleted %{public}d items", ids.count)
    }

    // MARK: - Update Operations

    /// Update an existing item with optimistic update pattern
    /// - Parameters:
    ///   - item: Updated item data
    ///   - userEditedFields: Array of field names that were manually edited (for tracking)
    /// - Throws: Error if Firestore write fails
    public func updateItem(_ item: Item, userEditedFields: [String]? = nil) async throws {
        let itemRef = db.collection("items").document(item.id)

        var data: [String: Any] = [
            "name": item.name as Any,
            "category": item.category as Any,
            "subCategory": item.subCategory as Any,
            "brand": item.brand as Any,
            "model": item.model as Any,
            "color": item.color as Any,
            "material": item.material as Any,
            "condition": item.condition?.rawValue as Any,
            "dimensions": item.dimensions as Any,
            "quantity": item.quantity as Any,
            "estimatedValue": item.estimatedValue as Any,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        // Track user edits if provided
        if let editedFields = userEditedFields {
            // Merge with existing edited fields
            data["userEditedFields"] = FieldValue.arrayUnion(editedFields)
        }

        if let lastRescanAt = item.lastRescanAt {
            data["lastRescanAt"] = Timestamp(date: lastRescanAt)
        }

        // Write additional image URLs if present
        if let additionalUrls = item.additionalImageUrls {
            data["additionalImageUrls"] = additionalUrls
        }

        try await itemRef.updateData(data)
        os_log(.info, log: .default, "Updated item id=%{public}@", item.id)
    }

    /// Trigger a rescan by updating the image URL and resetting status
    /// - Parameter item: Item with new imageUrl and updated fields
    /// - Throws: Error if Firestore write fails
    public func rescanItem(_ item: Item) async throws {
        let itemRef = db.collection("items").document(item.id)

        let data: [String: Any] = [
            "imageUrl": item.imageUrl,
            "status": "pending", // Triggers Cloud Function
            "lastRescanAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await itemRef.updateData(data)
        os_log(.info, log: .default, "Triggered rescan for item id=%{public}@", item.id)
    }

    // MARK: - Private Helpers

    // swiftlint:disable:next function_body_length
    private func decodeItem(from data: [String: Any], id: String) throws -> Item {
        // Firestore timestamps need special handling
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let lastRescanAt = (data["lastRescanAt"] as? Timestamp)?.dateValue()

        // Parse condition enum (with legacy string fallback)
        let condition: ItemCondition?
        if let conditionStr = data["condition"] as? String {
            condition = ItemCondition(rawValue: conditionStr)
        } else {
            condition = nil
        }

        // Parse confidence enum (with legacy Double fallback)
        let confidence: ItemConfidence?
        if let confidenceStr = data["confidence"] as? String {
            confidence = ItemConfidence(rawValue: confidenceStr)
        } else if let legacyConfidence = data["confidence"] as? Double {
            // Legacy: convert numeric confidence to enum
            if legacyConfidence >= 0.8 {
                confidence = .high
            } else if legacyConfidence >= 0.5 {
                confidence = .medium
            } else {
                confidence = .low
            }
        } else {
            confidence = nil
        }

        // Parse photo metadata if present
        let photoMetadata: PhotoMetadata?
        if let metadataDict = data["photoMetadata"] as? [String: Any] {
            var metadata = PhotoMetadata(fromFirestoreData: metadataDict)
            // Handle Firestore Timestamp for captureTimestamp
            if let captureTs = metadataDict["captureTimestamp"] as? Timestamp {
                metadata.captureTimestamp = captureTs.dateValue()
            }
            photoMetadata = metadata
        } else {
            photoMetadata = nil
        }

        // Parse deep scan completion timestamp
        let deepScanCompletedAt = (data["deepScanCompletedAt"] as? Timestamp)?.dateValue()

        return Item(
            id: id,
            userId: data["userId"] as? String ?? "",
            imageUrl: data["imageUrl"] as? String ?? "",
            status: ItemStatus.fromFirestoreValue(data["status"] as? String ?? "pending"),
            name: data["name"] as? String,
            category: data["category"] as? String,
            subCategory: data["subCategory"] as? String,
            brand: data["brand"] as? String,
            model: data["model"] as? String,
            color: data["color"] as? String,
            material: data["material"] as? String,
            condition: condition,
            dimensions: data["dimensions"] as? String,
            quantity: data["quantity"] as? Int,
            estimatedValue: data["estimatedValue"] as? Double,
            confidence: confidence,
            processingNotes: data["processingNotes"] as? String,
            userEditedFields: data["userEditedFields"] as? [String],
            lastRescanAt: lastRescanAt,
            additionalImageUrls: data["additionalImageUrls"] as? [String],
            deepScanRequested: data["deepScanRequested"] as? Bool,
            deepScanCompletedAt: deepScanCompletedAt,
            productUrl: data["productUrl"] as? String,
            upcCode: data["upcCode"] as? String,
            marketPriceRange: data["marketPriceRange"] as? String,
            originalRetailPrice: data["originalRetailPrice"] as? Double,
            photoMetadata: photoMetadata,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

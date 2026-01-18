import Foundation
import FirebaseFirestore
import Combine
import os.log

/// Protocol for cataloging detected objects
public protocol CatalogServiceProtocol: Sendable {
    /// Create an item from a session detection
    func catalogDetectedObject(
        userId: String,
        sessionId: String,
        object: ServerDetectedObject
    ) async throws -> String

    /// Observe item status updates
    func observeItem(itemId: String) -> AnyPublisher<ItemCatalogStatus?, Never>
}

/// Status of item cataloging
public struct ItemCatalogStatus: Sendable {
    public let itemId: String
    public let status: String // pending, processing, complete, failed
    public let name: String?
    public let category: String?
    public let error: String?
}

/// Service for creating catalog items from session detections
public final class CatalogService: CatalogServiceProtocol {
    /// Firestore database reference.
    ///
    /// SAFETY: Marked `nonisolated(unsafe)` because Firestore is thread-safe.
    /// See SessionService.swift for detailed rationale.
    nonisolated(unsafe) private let db: Firestore
    private let logger = Logger(subsystem: "com.abundance.camerafeature", category: "CatalogService")

    public init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    /// Create an item document from a session detection
    /// This triggers the onItemFromSession Cloud Function to run Layer 2
    public func catalogDetectedObject(
        userId: String,
        sessionId: String,
        object: ServerDetectedObject
    ) async throws -> String {
        let itemRef = db.collection("items").document()
        let itemId = itemRef.documentID

        // Use the first cropped image URL
        guard let imageUrl = object.croppedImageUrls.first else {
            throw CatalogError.missingImageUrl
        }

        let data: [String: Any] = [
            "id": itemId,
            "userId": userId,
            "sessionId": sessionId,
            "groupId": object.groupId,
            "fromDetection": true,
            "imageUrl": imageUrl,
            "additionalImageUrls": Array(object.croppedImageUrls.dropFirst()),
            "layer1Label": object.label,
            "layer1Category": object.category,
            "layer1Confidence": object.confidence,
            "layer1Attributes": object.attributes,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await itemRef.setData(data)
        logger.info("Created item \(itemId) from session \(sessionId) detection \(object.groupId)")
        return itemId
    }

    /// Observe item cataloging status
    public func observeItem(itemId: String) -> AnyPublisher<ItemCatalogStatus?, Never> {
        let subject = PassthroughSubject<ItemCatalogStatus?, Never>()

        let listener = db.collection("items").document(itemId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else {
                    subject.send(nil)
                    return
                }

                if let error {
                    self.logger.error("observeItem error: \(error.localizedDescription)")
                    subject.send(nil)
                    return
                }

                guard let data = snapshot?.data() else {
                    subject.send(nil)
                    return
                }

                let status = ItemCatalogStatus(
                    itemId: itemId,
                    status: data["status"] as? String ?? "unknown",
                    name: data["name"] as? String,
                    category: data["category"] as? String,
                    error: data["error"] as? String
                )

                subject.send(status)
            }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }
}

/// Errors that can occur during cataloging
public enum CatalogError: Error, LocalizedError {
    case missingImageUrl
    case firestoreError(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .missingImageUrl:
            return "No cropped image available for this object"
        case .firestoreError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}

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

        // Extract GCS storage path from Firebase download URL
        // This enables refreshImageUrl() to regenerate expired URLs
        let imagePath = Self.extractStoragePath(from: imageUrl)

        var data: [String: Any] = [
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

        if let imagePath {
            data["imagePath"] = imagePath
        }

        try await itemRef.setData(data)
        logger.info("Created item \(itemId) from session \(sessionId) detection \(object.groupId)")
        return itemId
    }

    /// Extract GCS storage path from a Firebase Storage download URL
    ///
    /// Firebase download URLs have the format:
    /// `https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encodedPath}?alt=media&token={token}`
    ///
    /// This extracts and decodes `{encodedPath}` to get the GCS path like:
    /// `users/{userId}/sessions/{sessionId}/crops/{groupId}_crop_0.jpg`
    static func extractStoragePath(from url: String) -> String? {
        guard let urlComponents = URLComponents(string: url),
              urlComponents.host == "firebasestorage.googleapis.com",
              let path = urlComponents.path.split(separator: "/o/").last else {
            return nil
        }
        return String(path).removingPercentEncoding
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

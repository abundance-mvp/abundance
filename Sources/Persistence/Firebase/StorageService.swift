import Foundation
import FirebaseStorage
#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#endif

/// Protocol for Firebase Storage upload operations
public protocol StorageServiceProtocol {
    /// Upload cropped object image to Firebase Storage
    /// - Parameters:
    ///   - image: Cropped image from Vision Framework
    ///   - itemId: Unique item identifier
    ///   - userId: Current user ID (Firebase Auth UID)
    /// - Returns: Public download URL for uploaded image
    /// - Throws: StorageError if upload fails
    func uploadCroppedObject(
        _ image: PlatformImage,
        itemId: String,
        userId: String
    ) async throws -> URL
}

/// Concrete implementation of Firebase Storage operations
public final class StorageService: StorageServiceProtocol {

    // MARK: - Properties

    private let storage: Storage
    private let compressionQuality: CGFloat = 0.8 // 80% JPEG quality

    // MARK: - Initialization

    public init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }

    // MARK: - Upload Operations

    public func uploadCroppedObject(
        _ image: PlatformImage,
        itemId: String,
        userId: String
    ) async throws -> URL {
        // Compress image to JPEG
        #if os(iOS)
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw StorageError.compressionFailed
        }
        #elseif os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw StorageError.compressionFailed
        }
        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        guard let imageData = imageRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
            throw StorageError.compressionFailed
        }
        #endif

        // Create storage reference: users/{userId}/items/{itemId}/cropped.jpg
        let ref = storage.reference()
            .child("users/\(userId)/items/\(itemId)/cropped.jpg")

        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public, max-age=3600" // 1 hour cache
        metadata.customMetadata = [
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "itemId": itemId,
            "userId": userId,
            "version": "1.0"
        ]

        // Upload data
        _ = try await ref.putDataAsync(imageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await ref.downloadURL()
        return downloadURL
    }
}

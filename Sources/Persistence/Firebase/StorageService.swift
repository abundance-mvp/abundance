import Foundation
@preconcurrency import FirebaseStorage
import os.log
#if os(iOS)
import UIKit
/// Platform-agnostic image type (UIImage on iOS)
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
/// Platform-agnostic image type (NSImage on macOS)
public typealias PlatformImage = NSImage
#endif

/// Protocol for Firebase Storage upload operations
public protocol StorageServiceProtocol: Sendable {
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

    /// Upload Live Photo motion clip to Cloud Storage
    /// - Parameters:
    ///   - motionData: MOV file data from Live Photo
    ///   - itemId: Unique item identifier
    ///   - userId: Current user ID (Firebase Auth UID)
    /// - Returns: Public download URL for uploaded motion clip
    /// - Throws: StorageError if upload fails
    func uploadLivePhotoMotion(
        _ motionData: Data,
        itemId: String,
        userId: String
    ) async throws -> URL
}

/// Concrete implementation of Firebase Storage operations
public final class StorageService: StorageServiceProtocol {

    // MARK: - Properties

    private let storage: Storage
    private let compressionQuality: CGFloat = 0.8 // 80% JPEG quality
    private let uploadTimeout: TimeInterval = 60.0 // 60 seconds
    private let logger = Logger(subsystem: "com.abundance.persistence", category: "StorageService")

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
        let imageRep: NSBitmapImageRep = NSBitmapImageRep(cgImage: cgImage)
        guard let imageData = imageRep.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        ) else {
            throw StorageError.compressionFailed
        }
        #endif

        // Create storage reference: users/{userId}/items/{itemId}.jpg
        // Note: Every image uploaded via this service is a cropped object, no need for /cropped suffix
        let ref: StorageReference = storage.reference()
            .child("users/\(userId)/items/\(itemId).jpg")

        // Set metadata
        let metadata: StorageMetadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public, max-age=3600" // 1 hour cache
        metadata.customMetadata = [
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "itemId": itemId,
            "userId": userId,
            "version": "1.0",
            // GCP processing metadata - enables Cloud Function triggers
            "processingStatus": "pending",
            "uploadSource": "camera-detection"
        ]

        logger.info("📤 Uploading cropped object: itemId=\(itemId), size=\(imageData.count) bytes")
        logger.debug("📋 Metadata: processingStatus=pending, uploadSource=camera-detection")

        // Upload with timeout
        let url = try await withTimeout(uploadTimeout, ref: ref, imageData: imageData, metadata: metadata)
        logger.info("✅ Upload complete: \(url.absoluteString)")
        return url
    }

    /// Upload Live Photo motion clip to Cloud Storage
    /// - Parameters:
    ///   - motionData: MOV file data from Live Photo
    ///   - itemId: Unique item identifier
    ///   - userId: Current user ID (Firebase Auth UID)
    /// - Returns: Public download URL for uploaded motion clip
    /// - Throws: StorageError if upload fails
    public func uploadLivePhotoMotion(
        _ motionData: Data,
        itemId: String,
        userId: String
    ) async throws -> URL {
        // Create storage reference: users/{userId}/items/{itemId}/motion.mov
        let ref: StorageReference = storage.reference()
            .child("users/\(userId)/items/\(itemId)/motion.mov")

        // Set metadata
        let metadata: StorageMetadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        metadata.cacheControl = "public, max-age=86400" // 24 hour cache
        metadata.customMetadata = [
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "itemId": itemId,
            "userId": userId,
            "type": "live-photo-motion",
            // GCP processing metadata - enables Cloud Function triggers
            "processingStatus": "pending",
            "uploadSource": "live-photo-capture"
        ]

        return try await withTimeout(uploadTimeout, ref: ref, imageData: motionData, metadata: metadata)
    }

    // MARK: - Helper Methods

    /// Execute upload operation with timeout
    private func withTimeout(
        _ timeout: TimeInterval,
        ref: StorageReference,
        imageData: Data,
        metadata: StorageMetadata
    ) async throws -> URL {
        try await withThrowingTaskGroup(of: URL?.self) { group in
            // Add main upload operation
            group.addTask {
                // Upload data
                _ = try await ref.putDataAsync(imageData, metadata: metadata)

                // Get download URL
                let downloadURL: URL = try await ref.downloadURL()
                return downloadURL
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw StorageError.networkTimeout
            }

            // Wait for first completion (operation or timeout)
            if let result = try await group.next() {
                group.cancelAll()
                if let url = result {
                    return url
                }
            }

            throw StorageError.networkTimeout
        }
    }
}

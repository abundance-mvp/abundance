import Foundation
@testable import Persistence

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Mock StorageService for testing upload operations
/// Tracks upload calls and allows error simulation
final class MockStorageService: StorageServiceProtocol, @unchecked Sendable {
    // MARK: - Call Tracking

    var uploadCroppedObjectCallCount = 0
    var uploadLivePhotoMotionCallCount = 0

    // MARK: - Captured Parameters

    var capturedItemIds: [String] = []
    var capturedUserIds: [String] = []
    var capturedImages: [PlatformImage] = []
    var capturedMotionData: [Data] = []

    // MARK: - Stubbed Responses

    var stubbedUploadUrl: URL = URL(string: "https://storage.example.com/test.jpg")!
    var stubbedMotionUrl: URL = URL(string: "https://storage.example.com/motion.mov")!

    // MARK: - Error Simulation

    var errorToThrow: Error?
    var uploadDelay: TimeInterval = 0

    // MARK: - Progress Simulation

    var simulateProgress: Bool = false
    var progressCallback: ((Double) -> Void)?

    // MARK: - StorageServiceProtocol

    func uploadCroppedObject(
        _ image: PlatformImage,
        itemId: String,
        userId: String
    ) async throws -> URL {
        uploadCroppedObjectCallCount += 1
        capturedImages.append(image)
        capturedItemIds.append(itemId)
        capturedUserIds.append(userId)

        // Simulate upload delay if configured
        if uploadDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(uploadDelay * 1_000_000_000))
        }

        // Simulate progress updates if configured
        if simulateProgress {
            for progress in stride(from: 0.0, through: 1.0, by: 0.25) {
                progressCallback?(progress)
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }

        if let error = errorToThrow {
            throw error
        }

        return URL(string: "https://storage.example.com/\(itemId).jpg")!
    }

    func uploadLivePhotoMotion(
        _ motionData: Data,
        itemId: String,
        userId: String
    ) async throws -> URL {
        uploadLivePhotoMotionCallCount += 1
        capturedMotionData.append(motionData)
        capturedItemIds.append(itemId)
        capturedUserIds.append(userId)

        if let error = errorToThrow {
            throw error
        }

        return stubbedMotionUrl
    }

    func uploadAdditionalPhoto(
        _ image: PlatformImage,
        itemId: String,
        photoIndex: Int,
        userId: String
    ) async throws -> URL {
        if let error = errorToThrow { throw error }
        return URL(string: "https://storage.example.com/\(itemId)_photo_\(photoIndex).jpg")!
    }

    // MARK: - Test Helpers

    /// Reset all state for clean test setup
    func reset() {
        uploadCroppedObjectCallCount = 0
        uploadLivePhotoMotionCallCount = 0

        capturedItemIds = []
        capturedUserIds = []
        capturedImages = []
        capturedMotionData = []

        stubbedUploadUrl = URL(string: "https://storage.example.com/test.jpg")!
        stubbedMotionUrl = URL(string: "https://storage.example.com/motion.mov")!
        errorToThrow = nil
        uploadDelay = 0
        simulateProgress = false
        progressCallback = nil
    }
}

/// Storage errors for testing
enum MockStorageError: Error, LocalizedError {
    case networkTimeout
    case quotaExceeded
    case permissionDenied
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .networkTimeout:
            return "Network timeout during upload"
        case .quotaExceeded:
            return "Storage quota exceeded"
        case .permissionDenied:
            return "Permission denied"
        case .compressionFailed:
            return "Image compression failed"
        }
    }
}

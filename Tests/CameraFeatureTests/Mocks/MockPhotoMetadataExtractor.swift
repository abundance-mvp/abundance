import Foundation
import Photos
@testable import CameraFeature
@testable import Persistence

/// Mock implementation of PhotoMetadataExtractorProtocol for testing
final class MockPhotoMetadataExtractor: PhotoMetadataExtractorProtocol, @unchecked Sendable {

    // MARK: - Test Configuration

    /// Metadata to return from extractMetadata calls
    var mockMetadata: PhotoMetadata = PhotoMetadata(
        deviceModel: "iPhone16,2-mock",
        osVersion: "18.0-mock",
        sourceType: .camera,
        imageHash: "mock-hash-123456"
    )

    /// Track method calls
    var extractMetadataCallCount = 0
    var lastImageData: Data?
    var lastAsset: PHAsset?

    // MARK: - PhotoMetadataExtractorProtocol

    func extractMetadata(
        from imageData: Data,
        asset: PHAsset?
    ) async -> PhotoMetadata {
        extractMetadataCallCount += 1
        lastImageData = imageData
        lastAsset = asset
        return mockMetadata
    }
}

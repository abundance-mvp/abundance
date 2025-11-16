import Foundation

/// Errors that can occur during Firebase Storage operations
public enum StorageError: Error, LocalizedError {
    case invalidImage
    case compressionFailed
    case uploadFailed(Error)
    case networkTimeout
    case quotaExceeded
    case invalidURL
    case deleteFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format. Cannot convert to JPEG."
        case .compressionFailed:
            return "Failed to compress image for upload."
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .networkTimeout:
            return "Upload timed out. Check your internet connection."
        case .quotaExceeded:
            return "Storage quota exceeded. Please contact support."
        case .invalidURL:
            return "Failed to generate download URL."
        case .deleteFailed(let error):
            return "Failed to delete image: \(error.localizedDescription)"
        }
    }
}

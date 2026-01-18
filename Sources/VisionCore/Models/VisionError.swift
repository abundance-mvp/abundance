// VisionError.swift
// Error types for Vision framework operations
//
// Part of VisionCore module

import Foundation

/// Errors that can occur during Vision framework operations
public enum VisionError: Error, LocalizedError, Sendable {
    /// The input image is invalid or cannot be processed
    case invalidImage(String)

    /// The Vision request failed
    case requestFailed(Error)

    /// No results were returned from the Vision request
    case noResults

    /// Convenience: invalidImage with default message
    static var invalidImage: VisionError {
        .invalidImage("Unable to process the provided image")
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidImage(let message):
            return "Invalid image: \(message)"
        case .requestFailed(let error):
            return "Vision request failed: \(error.localizedDescription)"
        case .noResults:
            return "No results from Vision analysis"
        }
    }
}

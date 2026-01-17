import Foundation
import Photos
import ImageIO
import CryptoKit
import CoreLocation
import os.log

#if os(iOS)
import UIKit
#endif

import Persistence

/// Protocol for photo metadata extraction
public protocol PhotoMetadataExtractorProtocol: Sendable {
    /// Extract metadata from image data and optional PHAsset
    func extractMetadata(
        from imageData: Data,
        asset: PHAsset?
    ) async -> PhotoMetadata
}

/// Service for extracting photo metadata from captured images
/// Extracts EXIF data, device info, and computes image hash
///
/// Uses Apple APIs:
/// - CryptoKit SHA256 for image hash computation
/// - CGImageSource for EXIF extraction
/// - PHAsset for Photos library metadata
public final class PhotoMetadataExtractor: PhotoMetadataExtractorProtocol, @unchecked Sendable {

    private let logger: Logger = Logger(
        subsystem: "com.abundance.camerafeature",
        category: "PhotoMetadataExtractor"
    )

    public init() {}

    // MARK: - Public API

    /// Extract comprehensive metadata from image data
    /// - Parameters:
    ///   - imageData: Raw JPEG/HEIC image data
    ///   - asset: Optional PHAsset for Photos library metadata
    /// - Returns: PhotoMetadata with all available fields populated
    public func extractMetadata(
        from imageData: Data,
        asset: PHAsset?
    ) async -> PhotoMetadata {

        var metadata: PhotoMetadata = PhotoMetadata()

        // 1. Compute SHA-256 hash
        metadata.imageHash = computeSHA256(from: imageData)

        // 2. Extract device info
        metadata.deviceModel = deviceModel()
        metadata.osVersion = await osVersion()
        metadata.timezone = TimeZone.current.identifier

        // 3. Extract EXIF data
        let exifData: EXIFData = extractEXIF(from: imageData)
        metadata.captureTimestamp = exifData.timestamp ?? Date()
        metadata.lensType = exifData.lensType

        // 4. Get image dimensions
        if let dimensions = imageDimensions(from: imageData) {
            metadata.imageWidth = Int(dimensions.width)
            metadata.imageHeight = Int(dimensions.height)
        }

        // 5. Determine source type
        metadata.sourceType = determineSourceType(from: imageData, asset: asset)

        // 6. Extract PHAsset metadata if available
        if let asset = asset {
            metadata.latitude = asset.location?.coordinate.latitude
            metadata.longitude = asset.location?.coordinate.longitude
            metadata.altitude = asset.location?.altitude
            metadata.captureTimestamp = asset.creationDate
            metadata.hasDepthData = asset.mediaSubtypes.contains(.photoDepthEffect)
            metadata.isLivePhoto = asset.mediaSubtypes.contains(.photoLive)
        }

        let hashValue: String = metadata.imageHash ?? "nil"
        let sourceValue: String = String(describing: metadata.sourceType)
        logger.debug("Extracted metadata: hash=\(hashValue), source=\(sourceValue)")

        return metadata
    }

    // MARK: - SHA-256 Hash

    /// Compute SHA-256 hash of image data
    /// Uses Apple CryptoKit for hardware-accelerated hashing
    public func computeSHA256(from data: Data) -> String {
        let digest: SHA256.Digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Device Info

    private func deviceModel() -> String {
        var systemInfo: utsname = utsname()
        uname(&systemInfo)
        let machineMirror: Mirror = Mirror(reflecting: systemInfo.machine)
        let identifier: String = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    private func osVersion() async -> String {
        #if os(iOS)
        return await MainActor.run { UIDevice.current.systemVersion }
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }

    // MARK: - EXIF Extraction

    private struct EXIFData {
        var timestamp: Date?
        var lensType: String?
    }

    private func extractEXIF(from data: Data) -> EXIFData {
        var exif: EXIFData = EXIFData()

        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return exif
        }

        // Extract EXIF dictionary
        if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            // Date/Time Original
            if let dateString = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                exif.timestamp = parseEXIFDate(dateString)
            }

            // Lens Model
            if let lens = exifDict[kCGImagePropertyExifLensModel as String] as? String {
                exif.lensType = lens
            }
        }

        return exif
    }

    /// Static EXIF date formatter - expensive to create, so reused across calls
    /// EXIF DateTimeOriginal follows a strict format, so we use POSIX locale and UTC timezone
    /// to prevent locale-dependent parsing failures
    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private func parseEXIFDate(_ dateString: String) -> Date? {
        Self.exifDateFormatter.date(from: dateString)
    }

    // MARK: - Image Dimensions

    private func imageDimensions(from data: Data) -> CGSize? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    // MARK: - Source Type Detection

    private func determineSourceType(from data: Data, asset: PHAsset?) -> PhotoSourceType {
        // Check PHAsset source type if available
        if let asset = asset {
            switch asset.sourceType {
            case .typeUserLibrary:
                // Could be camera capture or imported
                // Check if it has EXIF data (camera captures usually do)
                if extractEXIF(from: data).timestamp != nil {
                    return .camera
                }
                return .imported
            case .typeCloudShared:
                return .imported
            case .typeiTunesSynced:
                return .imported
            default:
                break
            }
        }

        // Heuristic: Check for EXIF data indicating camera capture
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return .unknown
        }

        // Screenshots typically have no EXIF and specific dimensions
        let hasEXIF: Bool = properties[kCGImagePropertyExifDictionary as String] != nil

        if !hasEXIF {
            // Could be screenshot or saved from web
            return .savedFromWeb // Conservative guess
        }

        // Has EXIF - likely camera capture
        return .camera
    }
}

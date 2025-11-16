import Foundation
@preconcurrency import Vision
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Barcode detector using Vision Framework VNDetectBarcodesRequest
public final class BarcodeDetector: BarcodeDetectorProtocol {

    // MARK: - Properties

    /// Default symbologies for product barcodes
    private let defaultSymbologies: [VNBarcodeSymbology] = [
        .upce,      // UPC-E (8-digit)
        .ean8,      // EAN-8 (8-digit)
        .ean13,     // EAN-13 (13-digit, most common)
        .qr,        // QR Code
        .code128    // Code 128 (variable length)
    ]

    // MARK: - Initialization

    public init() {}

    // MARK: - Detection

    public func detectBarcodes(in image: PlatformImage) async throws -> [BarcodeResult] {
        // Platform bridging: Convert to CGImage for Vision Framework
        #if os(iOS)
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }
        let orientation = cgImageOrientation(from: image.imageOrientation)
        #elseif os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw VisionError.invalidImage
        }
        let orientation = CGImagePropertyOrientation.up
        #endif

        // Create barcode detection request
        let request = VNDetectBarcodesRequest()
        request.symbologies = defaultSymbologies

        // Perform request on background thread using async/await
        return try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: orientation,
                options: [:]
            )

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])

                    guard let results = request.results as? [VNBarcodeObservation] else {
                        continuation.resume(returning: [])
                        return
                    }

                    // Filter out barcodes with no payload
                    let detectedBarcodes = results.compactMap { observation -> BarcodeResult? in
                        guard let payload = observation.payloadStringValue else {
                            return nil
                        }

                        return BarcodeResult(
                            payload: payload,
                            symbology: observation.symbology.rawValue,
                            confidence: observation.confidence,
                            boundingBox: observation.boundingBox
                        )
                    }

                    continuation.resume(returning: detectedBarcodes)
                } catch {
                    continuation.resume(throwing: VisionError.requestFailed(error))
                }
            }
        }
    }

    // MARK: - Helper Methods

    #if os(iOS)
    /// Convert UIImage.Orientation to CGImagePropertyOrientation for Vision Framework
    private func cgImageOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
    #endif
}

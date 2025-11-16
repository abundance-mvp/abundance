import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Protocol for barcode detection using Vision Framework
public protocol BarcodeDetectorProtocol {
    /// Detect barcodes in an image using VNDetectBarcodesRequest
    /// - Parameter image: Input image to scan
    /// - Returns: Array of detected barcodes with payload values
    /// - Throws: VisionError if detection fails
    func detectBarcodes(in image: PlatformImage) async throws -> [BarcodeResult]
}

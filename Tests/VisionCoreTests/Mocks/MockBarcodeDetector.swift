import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import VisionCore

/// Test mock for BarcodeDetectorProtocol
/// Uses @unchecked Sendable because test mocks need mutable state for stubbing/verification
/// This is safe in test contexts where mocks are used from a single test thread
final class MockBarcodeDetector: BarcodeDetectorProtocol, @unchecked Sendable {

    var stubbedBarcodes: [BarcodeResult] = []
    var shouldFail: Bool = false
    var didCallDetectBarcodes: Bool = false

    func detectBarcodes(in image: PlatformImage) async throws -> [BarcodeResult] {
        didCallDetectBarcodes = true

        if shouldFail {
            throw VisionError.requestFailed(NSError(domain: "test", code: 1))
        }

        return stubbedBarcodes
    }

    func reset() {
        stubbedBarcodes = []
        shouldFail = false
        didCallDetectBarcodes = false
    }
}

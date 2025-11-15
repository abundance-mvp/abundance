import Foundation
@preconcurrency import CoreVideo
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import VisionCore

final class MockHouseholdItemDetector: HouseholdItemDetectorProtocol, @unchecked Sendable {

    var stubbedItems: [HouseholdItem] = []
    var stubbedYOLOResults: [YOLOResult] = []
    var shouldFail: Bool = false
    var didCallDetectHouseholdItems: Bool = false
    var didCallDetectInStream: Bool = false

    func detectHouseholdItems(in image: PlatformImage) async throws -> [HouseholdItem] {
        didCallDetectHouseholdItems = true

        if shouldFail {
            throw VisionError.requestFailed(NSError(domain: "test", code: 1))
        }

        return stubbedItems
    }

    func detectInStream(pixelBuffer: CVPixelBuffer) async throws -> [YOLOResult] {
        didCallDetectInStream = true

        if shouldFail {
            throw VisionError.requestFailed(NSError(domain: "test", code: 1))
        }

        return stubbedYOLOResults
    }

    func reset() {
        stubbedItems = []
        stubbedYOLOResults = []
        shouldFail = false
        didCallDetectHouseholdItems = false
        didCallDetectInStream = false
    }
}

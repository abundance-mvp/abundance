import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import VisionCore

final class MockHouseholdItemDetector: HouseholdItemDetectorProtocol {

    var stubbedItems: [HouseholdItem] = []
    var shouldFail: Bool = false
    var didCallDetectHouseholdItems: Bool = false

    func detectHouseholdItems(in image: PlatformImage) async throws -> [HouseholdItem] {
        didCallDetectHouseholdItems = true

        if shouldFail {
            throw VisionError.requestFailed(NSError(domain: "test", code: 1))
        }

        return stubbedItems
    }

    func reset() {
        stubbedItems = []
        shouldFail = false
        didCallDetectHouseholdItems = false
    }
}

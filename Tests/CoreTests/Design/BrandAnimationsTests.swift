import XCTest
import SwiftUI
@testable import Core

final class BrandAnimationsTests: XCTestCase {
    func testBrandPressAnimation() {
        let animation = Animation.brandPress
        XCTAssertNotNil(animation)
    }

    func testBrandDefaultAnimation() {
        let animation = Animation.brandDefault
        XCTAssertNotNil(animation)
    }

    func testBrandReducedMotionAnimation() {
        let animation = Animation.brandReducedMotion
        XCTAssertNotNil(animation)
    }
}

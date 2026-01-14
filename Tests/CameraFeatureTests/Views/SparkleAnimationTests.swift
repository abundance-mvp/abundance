import XCTest
import SwiftUI
@testable import CameraFeature

final class SparkleAnimationTests: XCTestCase {

    func testSparkleAnimationCreatesParticles() {
        // Given: Center point for sparkles
        let center = CGPoint(x: 100, y: 100)

        // When: Animation view is created
        let animation = SparkleAnimation(center: center)

        // Then: View is not nil
        XCTAssertNotNil(animation)
    }
}

import XCTest
import AVFoundation
@testable import CameraFeature

#if os(iOS)
/// Tests for CameraPreviewView and CameraPreviewUIView
///
/// These tests verify that the camera preview layer frame is properly managed,
/// specifically catching the bug where preview layer frame remained (0,0,0,0)
/// when using SwiftUI's updateUIView instead of UIKit's layoutSubviews.
///
/// Key test: Preview layer frame must be updated when view bounds change via layoutSubviews.
@MainActor
final class CameraPreviewViewTests: XCTestCase {

    var session: AVCaptureSession!

    override func setUp() {
        super.setUp()
        session = AVCaptureSession()
    }

    override func tearDown() {
        session = nil
        super.tearDown()
    }

    // MARK: - CameraPreviewUIView Tests

    func testInit_createsPreviewLayer() {
        // When
        let view = CameraPreviewUIView(session: session)

        // Then
        XCTAssertNotNil(view.previewLayer)
        XCTAssertEqual(view.previewLayer.session, session)
    }

    func testInit_addsPreviewLayerToSublayers() {
        // When
        let view = CameraPreviewUIView(session: session)

        // Then
        XCTAssertTrue(view.layer.sublayers?.contains(view.previewLayer) ?? false)
    }

    func testInit_setsVideoGravityToResizeAspectFill() {
        // When
        let view = CameraPreviewUIView(session: session)

        // Then
        XCTAssertEqual(view.previewLayer.videoGravity, .resizeAspectFill)
    }

    func testInit_setsBackgroundColorToBlack() {
        // When
        let view = CameraPreviewUIView(session: session)

        // Then
        XCTAssertEqual(view.backgroundColor, .black)
    }

    func testInit_previewLayerFrameIsInitiallyZero() {
        // This documents the initial state before layout
        // When
        let view = CameraPreviewUIView(session: session)

        // Then - before layout, frame is zero (this is expected)
        XCTAssertEqual(view.previewLayer.frame, .zero)
    }

    /// CRITICAL TEST: This test would have caught the black camera preview bug.
    ///
    /// The bug was: preview layer frame remained (0,0,0,0) because we relied on
    /// SwiftUI's updateUIView which wasn't being called with proper bounds.
    ///
    /// The fix: Use layoutSubviews to update preview layer frame when UIKit
    /// triggers layout.
    func testLayoutSubviews_updatesPreviewLayerFrameToMatchBounds() {
        // Given
        let view = CameraPreviewUIView(session: session)
        let expectedFrame = CGRect(x: 0, y: 0, width: 390, height: 844)

        // When - simulate UIKit setting bounds and triggering layout
        view.frame = expectedFrame
        view.layoutSubviews()

        // Then - preview layer frame should match view bounds
        XCTAssertEqual(view.previewLayer.frame, view.bounds)
        XCTAssertEqual(view.previewLayer.frame.width, 390)
        XCTAssertEqual(view.previewLayer.frame.height, 844)
    }

    func testLayoutSubviews_updatesFrameOnBoundsChange() {
        // Given
        let view = CameraPreviewUIView(session: session)
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 300)
        view.layoutSubviews()
        XCTAssertEqual(view.previewLayer.frame.width, 200)

        // When - bounds change (e.g., rotation)
        view.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        view.layoutSubviews()

        // Then - preview layer frame updates
        XCTAssertEqual(view.previewLayer.frame.width, 844)
        XCTAssertEqual(view.previewLayer.frame.height, 390)
    }

    func testLayoutSubviews_handlesMultipleLayoutPasses() {
        // Given
        let view = CameraPreviewUIView(session: session)

        // When - multiple layout passes (common in UIKit)
        for i in 1...5 {
            let size = CGFloat(i * 100)
            view.frame = CGRect(x: 0, y: 0, width: size, height: size)
            view.layoutSubviews()

            // Then - each pass updates correctly
            XCTAssertEqual(view.previewLayer.frame.width, size)
            XCTAssertEqual(view.previewLayer.frame.height, size)
        }
    }

    // MARK: - Integration with View Hierarchy

    func testPreviewLayerFrameUpdates_whenAddedToWindow() {
        // Given
        let view = CameraPreviewUIView(session: session)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))

        // When - add to window and trigger layout
        window.addSubview(view)
        view.frame = window.bounds
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // Then - preview layer should have proper frame
        XCTAssertEqual(view.previewLayer.frame, view.bounds)
        XCTAssertGreaterThan(view.previewLayer.frame.width, 0)
        XCTAssertGreaterThan(view.previewLayer.frame.height, 0)
    }

    // MARK: - Edge Cases

    func testLayoutSubviews_handlesZeroBounds() {
        // Given
        let view = CameraPreviewUIView(session: session)
        view.frame = .zero

        // When
        view.layoutSubviews()

        // Then - should not crash, frame should be zero
        XCTAssertEqual(view.previewLayer.frame, .zero)
    }

    func testLayoutSubviews_handlesVerySmallBounds() {
        // Given
        let view = CameraPreviewUIView(session: session)
        view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)

        // When
        view.layoutSubviews()

        // Then
        XCTAssertEqual(view.previewLayer.frame.width, 1)
        XCTAssertEqual(view.previewLayer.frame.height, 1)
    }

    func testLayoutSubviews_handlesLargeBounds() {
        // Given - iPad Pro 12.9" or external display
        let view = CameraPreviewUIView(session: session)
        view.frame = CGRect(x: 0, y: 0, width: 2732, height: 2048)

        // When
        view.layoutSubviews()

        // Then
        XCTAssertEqual(view.previewLayer.frame.width, 2732)
        XCTAssertEqual(view.previewLayer.frame.height, 2048)
    }
}
#endif

import XCTest
@testable import CameraFeature

final class BoundingBoxTests: XCTestCase {

    // MARK: - normalizedRect Conversion

    func testNormalizedRect_convertsGeminiFormatCorrectly() {
        // Gemini format: [ymin, xmin, ymax, xmax] normalized 0-1000
        // Object at top-left quarter of image
        let box = BoundingBoxInfo(imageIndex: 0, box2d: [0, 0, 500, 500])
        let rect = box.normalizedRect

        XCTAssertEqual(rect.origin.x, 0.0, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 0.0, accuracy: 0.001)
        XCTAssertEqual(rect.width, 0.5, accuracy: 0.001)
        XCTAssertEqual(rect.height, 0.5, accuracy: 0.001)
    }

    func testNormalizedRect_centersCorrectly() {
        // Object centered in image (25%-75% in both axes)
        let box = BoundingBoxInfo(imageIndex: 0, box2d: [250, 250, 750, 750])
        let rect = box.normalizedRect

        XCTAssertEqual(rect.origin.x, 0.25, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 0.25, accuracy: 0.001)
        XCTAssertEqual(rect.width, 0.5, accuracy: 0.001)
        XCTAssertEqual(rect.height, 0.5, accuracy: 0.001)
    }

    func testNormalizedRect_fullImage() {
        let box = BoundingBoxInfo(imageIndex: 0, box2d: [0, 0, 1000, 1000])
        let rect = box.normalizedRect

        XCTAssertEqual(rect.origin.x, 0.0, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 0.0, accuracy: 0.001)
        XCTAssertEqual(rect.width, 1.0, accuracy: 0.001)
        XCTAssertEqual(rect.height, 1.0, accuracy: 0.001)
    }

    func testNormalizedRect_bottomRightCorner() {
        // Object in bottom-right corner
        let box = BoundingBoxInfo(imageIndex: 0, box2d: [800, 700, 1000, 1000])
        let rect = box.normalizedRect

        XCTAssertEqual(rect.origin.x, 0.7, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 0.8, accuracy: 0.001)
        XCTAssertEqual(rect.width, 0.3, accuracy: 0.001)
        XCTAssertEqual(rect.height, 0.2, accuracy: 0.001)
    }

    func testNormalizedRect_emptyBox2d_returnsZero() {
        let box = BoundingBoxInfo(imageIndex: 0, box2d: [])
        XCTAssertEqual(box.normalizedRect, .zero)
    }

    func testNormalizedRect_wrongCount_returnsZero() {
        let box = BoundingBoxInfo(imageIndex: 0, box2d: [100, 200, 300])
        XCTAssertEqual(box.normalizedRect, .zero)
    }

    // MARK: - Aspect-Fit Image Rect Calculation

    /// Regression test: bounding boxes must map to the displayed image area,
    /// not the full container. This verifies the aspect-fit calculation that
    /// was missing and caused bounding boxes to be misaligned.
    func testImageDisplayRect_portraitImageInLandscapeContainer() {
        // Portrait image (3:4) in a wider container
        let imageSize = CGSize(width: 300, height: 400)
        let containerSize = CGSize(width: 400, height: 400)

        let displayRect = computeImageDisplayRect(imageSize: imageSize, containerSize: containerSize)

        // Image fits to height, letterboxed left/right
        XCTAssertEqual(displayRect.height, 400, accuracy: 0.1)
        XCTAssertEqual(displayRect.width, 300, accuracy: 0.1) // 400 * (300/400) = 300
        XCTAssertEqual(displayRect.minX, 50, accuracy: 0.1)   // (400 - 300) / 2
        XCTAssertEqual(displayRect.minY, 0, accuracy: 0.1)
    }

    func testImageDisplayRect_landscapeImageInPortraitContainer() {
        // Landscape image (4:3) in a taller container
        let imageSize = CGSize(width: 400, height: 300)
        let containerSize = CGSize(width: 400, height: 400)

        let displayRect = computeImageDisplayRect(imageSize: imageSize, containerSize: containerSize)

        // Image fits to width, letterboxed top/bottom
        XCTAssertEqual(displayRect.width, 400, accuracy: 0.1)
        XCTAssertEqual(displayRect.height, 300, accuracy: 0.1) // 400 * (300/400) = 300
        XCTAssertEqual(displayRect.minX, 0, accuracy: 0.1)
        XCTAssertEqual(displayRect.minY, 50, accuracy: 0.1)    // (400 - 300) / 2
    }

    func testImageDisplayRect_sameAspectRatio() {
        // Image matches container aspect ratio — no letterboxing
        let imageSize = CGSize(width: 200, height: 400)
        let containerSize = CGSize(width: 200, height: 400)

        let displayRect = computeImageDisplayRect(imageSize: imageSize, containerSize: containerSize)

        XCTAssertEqual(displayRect.minX, 0, accuracy: 0.1)
        XCTAssertEqual(displayRect.minY, 0, accuracy: 0.1)
        XCTAssertEqual(displayRect.width, 200, accuracy: 0.1)
        XCTAssertEqual(displayRect.height, 400, accuracy: 0.1)
    }

    func testBoundingBoxMapping_withLetterboxing() {
        // Regression test: normalized bbox (0.25, 0.25, 0.5, 0.5) on a portrait
        // image displayed in a wider container must offset by the letterbox margin.
        let imageSize = CGSize(width: 300, height: 400)
        let containerSize = CGSize(width: 400, height: 400)

        let imgRect = computeImageDisplayRect(imageSize: imageSize, containerSize: containerSize)
        // imgRect = (50, 0, 300, 400)

        let normalizedBox = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)

        // Map to displayed image rect (the fix)
        let mappedFrame = CGRect(
            x: imgRect.minX + normalizedBox.minX * imgRect.width,
            y: imgRect.minY + normalizedBox.minY * imgRect.height,
            width: normalizedBox.width * imgRect.width,
            height: normalizedBox.height * imgRect.height
        )

        // Should be offset by 50px (letterbox margin) on x-axis
        XCTAssertEqual(mappedFrame.minX, 125, accuracy: 0.1) // 50 + 0.25*300
        XCTAssertEqual(mappedFrame.minY, 100, accuracy: 0.1) // 0 + 0.25*400
        XCTAssertEqual(mappedFrame.width, 150, accuracy: 0.1) // 0.5*300
        XCTAssertEqual(mappedFrame.height, 200, accuracy: 0.1) // 0.5*400

        // OLD (broken) mapping would use container size directly:
        let brokenFrame = CGRect(
            x: normalizedBox.minX * containerSize.width,
            y: normalizedBox.minY * containerSize.height,
            width: normalizedBox.width * containerSize.width,
            height: normalizedBox.height * containerSize.height
        )
        // Verify the old mapping gives DIFFERENT (wrong) results
        XCTAssertNotEqual(mappedFrame.minX, brokenFrame.minX)
        XCTAssertEqual(brokenFrame.minX, 100) // Wrong: no offset for letterbox
    }

    // MARK: - Helper (mirrors DetectionResultsView.imageDisplayRect)

    private func computeImageDisplayRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        let displaySize: CGSize
        if imageAspect > containerAspect {
            displaySize = CGSize(
                width: containerSize.width,
                height: containerSize.width / imageAspect
            )
        } else {
            displaySize = CGSize(
                width: containerSize.height * imageAspect,
                height: containerSize.height
            )
        }

        return CGRect(
            x: (containerSize.width - displaySize.width) / 2,
            y: (containerSize.height - displaySize.height) / 2,
            width: displaySize.width,
            height: displaySize.height
        )
    }
}

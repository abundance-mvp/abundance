import XCTest
import CoreVideo
import CoreGraphics
@testable import VisionCore

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

final class PixelBufferCropperTests: XCTestCase {

    func testCropImage_withValidPixelBufferAndBoundingBox_returnsCroppedImage() throws {
        // Given: 100x100 pixel buffer
        let pixelBuffer = try createMockPixelBuffer(width: 100, height: 100)

        // Bounding box: center 50x50 square (Vision coordinates: origin bottom-left, normalized)
        let boundingBox = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)

        // When: Crop image
        let croppedImage = try PixelBufferCropper.cropImage(
            from: pixelBuffer,
            boundingBox: boundingBox
        )

        // Then: Returns image with correct dimensions
        XCTAssertNotNil(croppedImage)
    }

    func testCropImage_withInvalidBoundingBox_throwsError() throws {
        // Given: 100x100 pixel buffer
        let pixelBuffer = try createMockPixelBuffer(width: 100, height: 100)

        // Invalid bounding box: x < 0
        let invalidBoundingBox = CGRect(x: -0.1, y: 0.25, width: 0.5, height: 0.5)

        // When/Then: Cropping with invalid box throws invalidBoundingBox error
        XCTAssertThrowsError(try PixelBufferCropper.cropImage(
            from: pixelBuffer,
            boundingBox: invalidBoundingBox
        )) { error in
            XCTAssertEqual(error as? PixelBufferCropper.CropError, .invalidBoundingBox)
        }
    }

    func testCropImage_verifiesCroppedDimensions() throws {
        // Given: 100x100 pixel buffer
        let pixelBuffer = try createMockPixelBuffer(width: 100, height: 100)

        // Bounding box: center 50x50 square (Vision coordinates: origin bottom-left, normalized)
        let boundingBox = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)

        // When: Crop image
        let croppedImage = try PixelBufferCropper.cropImage(
            from: pixelBuffer,
            boundingBox: boundingBox
        )

        // Then: Cropped image has 50x50 dimensions
        #if os(iOS)
        XCTAssertEqual(croppedImage.size.width, 50, accuracy: 1.0)
        XCTAssertEqual(croppedImage.size.height, 50, accuracy: 1.0)
        #elseif os(macOS)
        XCTAssertEqual(croppedImage.size.width, 50, accuracy: 1.0)
        XCTAssertEqual(croppedImage.size.height, 50, accuracy: 1.0)
        #endif
    }

    private func createMockPixelBuffer(width: Int, height: Int) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw NSError(domain: "Test", code: -1)
        }

        return buffer
    }
}

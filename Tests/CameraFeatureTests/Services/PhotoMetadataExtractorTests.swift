import XCTest
import CryptoKit
@testable import CameraFeature
@testable import Persistence

final class PhotoMetadataExtractorTests: XCTestCase {

    var sut: PhotoMetadataExtractor!

    override func setUp() {
        super.setUp()
        sut = PhotoMetadataExtractor()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - SHA-256 Tests

    func testComputeSHA256_returnsHexString() {
        let testData = Data("Hello, World!".utf8)

        let hash = sut.computeSHA256(from: testData)

        XCTAssertEqual(hash.count, 64) // SHA-256 is 32 bytes = 64 hex chars
        XCTAssertTrue(hash.allSatisfy { $0.isHexDigit })
    }

    func testComputeSHA256_sameInputSameHash() {
        let testData = Data("Test data".utf8)

        let hash1 = sut.computeSHA256(from: testData)
        let hash2 = sut.computeSHA256(from: testData)

        XCTAssertEqual(hash1, hash2)
    }

    func testComputeSHA256_differentInputDifferentHash() {
        let data1 = Data("Data 1".utf8)
        let data2 = Data("Data 2".utf8)

        let hash1 = sut.computeSHA256(from: data1)
        let hash2 = sut.computeSHA256(from: data2)

        XCTAssertNotEqual(hash1, hash2)
    }

    func testComputeSHA256_emptyData() {
        let emptyData = Data()

        let hash = sut.computeSHA256(from: emptyData)

        // SHA-256 of empty data is a known value
        XCTAssertEqual(hash.count, 64)
        XCTAssertEqual(hash, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    func testComputeSHA256_matchesCryptoKit() {
        let testData = Data("Test string for hashing".utf8)

        let hash = sut.computeSHA256(from: testData)

        // Verify against direct CryptoKit call
        let expectedDigest = SHA256.hash(data: testData)
        let expectedHash = expectedDigest.map { String(format: "%02x", $0) }.joined()

        XCTAssertEqual(hash, expectedHash)
    }

    // MARK: - Metadata Extraction Tests

    func testExtractMetadata_setsDeviceInfo() async {
        let testData = Data("Fake image data".utf8)

        let metadata = await sut.extractMetadata(from: testData, asset: nil)

        XCTAssertNotNil(metadata.deviceModel)
        XCTAssertNotNil(metadata.osVersion)
        XCTAssertNotNil(metadata.timezone)
        XCTAssertNotNil(metadata.imageHash)
    }

    func testExtractMetadata_computesHash() async {
        let testData = Data("Test image data".utf8)

        let metadata = await sut.extractMetadata(from: testData, asset: nil)

        XCTAssertEqual(metadata.imageHash, sut.computeSHA256(from: testData))
    }

    func testExtractMetadata_setsTimezone() async {
        let testData = Data("Fake image data".utf8)

        let metadata = await sut.extractMetadata(from: testData, asset: nil)

        XCTAssertEqual(metadata.timezone, TimeZone.current.identifier)
    }

    func testExtractMetadata_withNilAsset() async {
        let testData = Data("Fake image data".utf8)

        let metadata = await sut.extractMetadata(from: testData, asset: nil)

        // Without PHAsset, location data should be nil
        XCTAssertNil(metadata.latitude)
        XCTAssertNil(metadata.longitude)
        XCTAssertNil(metadata.altitude)
        XCTAssertNil(metadata.hasDepthData)
        XCTAssertNil(metadata.isLivePhoto)
    }

    func testExtractMetadata_sourceTypeForNonImageData() async {
        let testData = Data("Not an image".utf8)

        let metadata = await sut.extractMetadata(from: testData, asset: nil)

        // For non-image data without EXIF, should return unknown or savedFromWeb
        XCTAssertNotNil(metadata.sourceType)
    }

    // MARK: - Protocol Conformance Tests

    func testPhotoMetadataExtractor_conformsToProtocol() {
        let _: PhotoMetadataExtractorProtocol = sut
        XCTAssertNotNil(sut)
    }

    func testPhotoMetadataExtractor_isSendable() {
        let _: any Sendable = sut
        XCTAssertNotNil(sut)
    }
}

// MARK: - Helpers

extension Character {
    var isHexDigit: Bool {
        return ("0"..."9").contains(self) || ("a"..."f").contains(self) || ("A"..."F").contains(self)
    }
}

import XCTest
@testable import Persistence

final class PhotoMetadataTests: XCTestCase {

    // MARK: - PhotoSourceType Tests

    func testPhotoSourceType_allCasesExist() {
        let cases: [PhotoSourceType] = [.camera, .screenshot, .savedFromWeb, .imported, .unknown]
        XCTAssertEqual(PhotoSourceType.allCases.count, 5)
        XCTAssertEqual(Set(PhotoSourceType.allCases), Set(cases))
    }

    func testPhotoSourceType_rawValues() {
        XCTAssertEqual(PhotoSourceType.camera.rawValue, "camera")
        XCTAssertEqual(PhotoSourceType.screenshot.rawValue, "screenshot")
        XCTAssertEqual(PhotoSourceType.savedFromWeb.rawValue, "savedFromWeb")
        XCTAssertEqual(PhotoSourceType.imported.rawValue, "imported")
        XCTAssertEqual(PhotoSourceType.unknown.rawValue, "unknown")
    }

    func testPhotoSourceType_codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for sourceType in PhotoSourceType.allCases {
            let encoded = try encoder.encode(sourceType)
            let decoded = try decoder.decode(PhotoSourceType.self, from: encoded)
            XCTAssertEqual(decoded, sourceType)
        }
    }

    // MARK: - PhotoMetadata Default Init Tests

    func testPhotoMetadata_defaultInit() {
        let metadata = PhotoMetadata()

        XCTAssertNil(metadata.latitude)
        XCTAssertNil(metadata.longitude)
        XCTAssertNil(metadata.altitude)
        XCTAssertNil(metadata.captureTimestamp)
        XCTAssertNil(metadata.timezone)
        XCTAssertNil(metadata.deviceModel)
        XCTAssertNil(metadata.osVersion)
        XCTAssertNil(metadata.sourceType)
        XCTAssertNil(metadata.imageHash)
        XCTAssertNil(metadata.lensType)
        XCTAssertNil(metadata.hasDepthData)
        XCTAssertNil(metadata.isLivePhoto)
        XCTAssertNil(metadata.imageWidth)
        XCTAssertNil(metadata.imageHeight)
    }

    // MARK: - PhotoMetadata Full Init Tests

    func testPhotoMetadata_fullInit() {
        let now = Date()
        let metadata = PhotoMetadata(
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 10.5,
            captureTimestamp: now,
            timezone: "America/Los_Angeles",
            deviceModel: "iPhone16,2",
            osVersion: "18.0",
            sourceType: .camera,
            imageHash: "abc123def456",
            lensType: "Wide Angle",
            hasDepthData: true,
            isLivePhoto: true,
            imageWidth: 4032,
            imageHeight: 3024
        )

        XCTAssertEqual(metadata.latitude, 37.7749)
        XCTAssertEqual(metadata.longitude, -122.4194)
        XCTAssertEqual(metadata.altitude, 10.5)
        XCTAssertEqual(metadata.captureTimestamp, now)
        XCTAssertEqual(metadata.timezone, "America/Los_Angeles")
        XCTAssertEqual(metadata.deviceModel, "iPhone16,2")
        XCTAssertEqual(metadata.osVersion, "18.0")
        XCTAssertEqual(metadata.sourceType, .camera)
        XCTAssertEqual(metadata.imageHash, "abc123def456")
        XCTAssertEqual(metadata.lensType, "Wide Angle")
        XCTAssertEqual(metadata.hasDepthData, true)
        XCTAssertEqual(metadata.isLivePhoto, true)
        XCTAssertEqual(metadata.imageWidth, 4032)
        XCTAssertEqual(metadata.imageHeight, 3024)
    }

    // MARK: - Firestore Encoding Tests

    func testPhotoMetadata_toFirestoreData_withAllFields() {
        let metadata = PhotoMetadata(
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 10.5,
            timezone: "America/Los_Angeles",
            deviceModel: "iPhone16,2",
            osVersion: "18.0",
            sourceType: .camera,
            imageHash: "abc123",
            lensType: "Wide Angle",
            hasDepthData: true,
            isLivePhoto: false,
            imageWidth: 4032,
            imageHeight: 3024
        )

        let firestoreData = metadata.toFirestoreData()

        XCTAssertEqual(firestoreData["latitude"] as? Double, 37.7749)
        XCTAssertEqual(firestoreData["longitude"] as? Double, -122.4194)
        XCTAssertEqual(firestoreData["altitude"] as? Double, 10.5)
        XCTAssertEqual(firestoreData["timezone"] as? String, "America/Los_Angeles")
        XCTAssertEqual(firestoreData["deviceModel"] as? String, "iPhone16,2")
        XCTAssertEqual(firestoreData["osVersion"] as? String, "18.0")
        XCTAssertEqual(firestoreData["sourceType"] as? String, "camera")
        XCTAssertEqual(firestoreData["imageHash"] as? String, "abc123")
        XCTAssertEqual(firestoreData["lensType"] as? String, "Wide Angle")
        XCTAssertEqual(firestoreData["hasDepthData"] as? Bool, true)
        XCTAssertEqual(firestoreData["isLivePhoto"] as? Bool, false)
        XCTAssertEqual(firestoreData["imageWidth"] as? Int, 4032)
        XCTAssertEqual(firestoreData["imageHeight"] as? Int, 3024)
    }

    func testPhotoMetadata_toFirestoreData_withNilFields() {
        let metadata = PhotoMetadata(
            latitude: 37.7749,
            imageHash: "abc123"
        )

        let firestoreData = metadata.toFirestoreData()

        // Only set fields should be present
        XCTAssertEqual(firestoreData["latitude"] as? Double, 37.7749)
        XCTAssertEqual(firestoreData["imageHash"] as? String, "abc123")

        // Nil fields should not be in dictionary
        XCTAssertNil(firestoreData["longitude"])
        XCTAssertNil(firestoreData["altitude"])
        XCTAssertNil(firestoreData["deviceModel"])
    }

    // MARK: - Firestore Decoding Tests

    func testPhotoMetadata_fromFirestoreData_withAllFields() {
        let firestoreData: [String: Any] = [
            "latitude": 37.7749,
            "longitude": -122.4194,
            "altitude": 10.5,
            "timezone": "America/Los_Angeles",
            "deviceModel": "iPhone16,2",
            "osVersion": "18.0",
            "sourceType": "camera",
            "imageHash": "abc123",
            "lensType": "Wide Angle",
            "hasDepthData": true,
            "isLivePhoto": false,
            "imageWidth": 4032,
            "imageHeight": 3024
        ]

        let metadata = PhotoMetadata(fromFirestoreData: firestoreData)

        XCTAssertEqual(metadata.latitude, 37.7749)
        XCTAssertEqual(metadata.longitude, -122.4194)
        XCTAssertEqual(metadata.altitude, 10.5)
        XCTAssertEqual(metadata.timezone, "America/Los_Angeles")
        XCTAssertEqual(metadata.deviceModel, "iPhone16,2")
        XCTAssertEqual(metadata.osVersion, "18.0")
        XCTAssertEqual(metadata.sourceType, .camera)
        XCTAssertEqual(metadata.imageHash, "abc123")
        XCTAssertEqual(metadata.lensType, "Wide Angle")
        XCTAssertEqual(metadata.hasDepthData, true)
        XCTAssertEqual(metadata.isLivePhoto, false)
        XCTAssertEqual(metadata.imageWidth, 4032)
        XCTAssertEqual(metadata.imageHeight, 3024)
    }

    func testPhotoMetadata_fromFirestoreData_withEmptyData() {
        let firestoreData: [String: Any] = [:]

        let metadata = PhotoMetadata(fromFirestoreData: firestoreData)

        XCTAssertNil(metadata.latitude)
        XCTAssertNil(metadata.longitude)
        XCTAssertNil(metadata.sourceType)
        XCTAssertNil(metadata.imageHash)
    }

    func testPhotoMetadata_fromFirestoreData_withInvalidSourceType() {
        let firestoreData: [String: Any] = [
            "sourceType": "invalid_type"
        ]

        let metadata = PhotoMetadata(fromFirestoreData: firestoreData)

        XCTAssertNil(metadata.sourceType)
    }

    // MARK: - Round Trip Tests

    func testPhotoMetadata_firestoreRoundTrip() {
        let original = PhotoMetadata(
            latitude: 37.7749,
            longitude: -122.4194,
            sourceType: .camera,
            imageHash: "abc123",
            imageWidth: 4032,
            imageHeight: 3024
        )

        let firestoreData = original.toFirestoreData()
        let restored = PhotoMetadata(fromFirestoreData: firestoreData)

        XCTAssertEqual(restored.latitude, original.latitude)
        XCTAssertEqual(restored.longitude, original.longitude)
        XCTAssertEqual(restored.sourceType, original.sourceType)
        XCTAssertEqual(restored.imageHash, original.imageHash)
        XCTAssertEqual(restored.imageWidth, original.imageWidth)
        XCTAssertEqual(restored.imageHeight, original.imageHeight)
    }

    // MARK: - Equatable Tests

    func testPhotoMetadata_equatable() {
        let metadata1 = PhotoMetadata(
            latitude: 37.7749,
            imageHash: "abc123"
        )
        let metadata2 = PhotoMetadata(
            latitude: 37.7749,
            imageHash: "abc123"
        )
        let metadata3 = PhotoMetadata(
            latitude: 37.7749,
            imageHash: "different"
        )

        XCTAssertEqual(metadata1, metadata2)
        XCTAssertNotEqual(metadata1, metadata3)
    }

    // MARK: - Sendable Tests

    func testPhotoMetadata_sendableConformance() {
        let metadata = PhotoMetadata()
        let _: any Sendable = metadata
        XCTAssertNotNil(metadata)
    }

    func testPhotoSourceType_sendableConformance() {
        let sourceType = PhotoSourceType.camera
        let _: any Sendable = sourceType
        XCTAssertNotNil(sourceType)
    }
}

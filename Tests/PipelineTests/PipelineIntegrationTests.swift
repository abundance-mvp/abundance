import Testing
@testable import CameraFeature
@testable import Core
@testable import Persistence

/// Integration tests for the image catalog pipeline
/// Validates data flows between capture, detection, and cataloging stages
@Suite("Pipeline Integration Tests")
struct PipelineIntegrationTests {

    // MARK: - Firebase Download URL Parsing

    @Test("extractStoragePath parses standard Firebase download URL")
    func testExtractStoragePath_standardUrl() {
        let url = "https://firebasestorage.googleapis.com/v0/b/abundance-mvp.firebasestorage.app/o/users%2Fuser-123%2Fsessions%2Fsession-abc%2Fcrops%2Fgroup1_crop_0.jpg?alt=media&token=abc-123"
        let path = CatalogService.extractStoragePath(from: url)
        #expect(path == "users/user-123/sessions/session-abc/crops/group1_crop_0.jpg")
    }

    @Test("extractStoragePath returns nil for non-Firebase URL")
    func testExtractStoragePath_nonFirebaseUrl() {
        let url = "https://example.com/image.jpg"
        let path = CatalogService.extractStoragePath(from: url)
        #expect(path == nil)
    }

    @Test("extractStoragePath returns nil for GCS URL format")
    func testExtractStoragePath_gcsUrl() {
        let url = "gs://abundance-mvp.firebasestorage.app/users/user-123/items/image.jpg"
        let path = CatalogService.extractStoragePath(from: url)
        #expect(path == nil)
    }

    @Test("extractStoragePath handles deeply nested paths")
    func testExtractStoragePath_deeplyNested() {
        let url = "https://firebasestorage.googleapis.com/v0/b/mybucket/o/a%2Fb%2Fc%2Fd%2Fe%2Ff.jpg?alt=media&token=tok"
        let path = CatalogService.extractStoragePath(from: url)
        #expect(path == "a/b/c/d/e/f.jpg")
    }

    @Test("extractStoragePath handles URL without query parameters")
    func testExtractStoragePath_noQueryParams() {
        let url = "https://firebasestorage.googleapis.com/v0/b/mybucket/o/path%2Fto%2Ffile.jpg"
        let path = CatalogService.extractStoragePath(from: url)
        #expect(path == "path/to/file.jpg")
    }

    @Test("extractStoragePath returns nil for empty string")
    func testExtractStoragePath_emptyString() {
        let path = CatalogService.extractStoragePath(from: "")
        #expect(path == nil)
    }

    @Test("extractStoragePath returns nil for malformed URL")
    func testExtractStoragePath_malformedUrl() {
        let path = CatalogService.extractStoragePath(from: "not a url at all")
        #expect(path == nil)
    }

    // MARK: - Item Status Transitions

    @Test("ItemStatus maps 'pending' to .processing")
    func testItemStatus_pending() {
        let status = ItemStatus.fromFirestoreValue("pending")
        #expect(status == .processing)
    }

    @Test("ItemStatus maps 'processing' to .processing")
    func testItemStatus_processing() {
        let status = ItemStatus.fromFirestoreValue("processing")
        #expect(status == .processing)
    }

    @Test("ItemStatus maps 'complete' to .complete")
    func testItemStatus_complete() {
        let status = ItemStatus.fromFirestoreValue("complete")
        #expect(status == .complete)
    }

    @Test("ItemStatus maps 'failed' to .failed")
    func testItemStatus_failed() {
        let status = ItemStatus.fromFirestoreValue("failed")
        #expect(status == .failed)
    }

    @Test("ItemStatus maps legacy 'layer2a_complete' to .processing")
    func testItemStatus_layer2aComplete() {
        let status = ItemStatus.fromFirestoreValue("layer2a_complete")
        #expect(status == .processing)
    }

    @Test("ItemStatus maps 'failed_layer2a' to .failed")
    func testItemStatus_failedLayer2a() {
        let status = ItemStatus.fromFirestoreValue("failed_layer2a")
        #expect(status == .failed)
    }

    @Test("ItemStatus maps unknown status to .processing")
    func testItemStatus_unknownValue() {
        let status = ItemStatus.fromFirestoreValue("some_new_status")
        #expect(status == .processing)
    }

    // MARK: - Item Display Name Fallback Chain

    @Test("displayName returns name when available")
    func testDisplayName_name() {
        let item = Item(
            id: "1", userId: "u", imageUrl: "url", status: .complete,
            name: "Apple Watch", layer1Label: "watch", layer1Category: "Electronics"
        )
        #expect(item.displayName == "Apple Watch")
    }

    @Test("displayName falls back to layer1Label when name is nil")
    func testDisplayName_layer1Label() {
        let item = Item(
            id: "1", userId: "u", imageUrl: "url", status: .complete,
            layer1Label: "watch", layer1Category: "Electronics"
        )
        #expect(item.displayName == "watch")
    }

    @Test("displayName falls back to category when name and layer1Label are nil")
    func testDisplayName_category() {
        let item = Item(
            id: "1", userId: "u", imageUrl: "url", status: .complete,
            category: "Electronics", layer1Category: "Gadgets"
        )
        #expect(item.displayName == "Electronics")
    }

    @Test("displayName falls back to layer1Category when all others are nil")
    func testDisplayName_layer1Category() {
        let item = Item(
            id: "1", userId: "u", imageUrl: "url", status: .complete,
            layer1Category: "Gadgets"
        )
        #expect(item.displayName == "Gadgets")
    }

    @Test("displayName returns 'Unknown Item' when all fields are nil")
    func testDisplayName_unknown() {
        let item = Item(id: "1", userId: "u", imageUrl: "url", status: .complete)
        #expect(item.displayName == "Unknown Item")
    }

    // MARK: - Session Item Creation Fields

    @Test("ServerDetectedObject contains required fields for item creation")
    func testServerDetectedObject_fields() {
        let obj = ServerDetectedObject(
            groupId: "grp-1",
            label: "leather armchair",
            category: "furniture",
            attributes: ["color": "brown", "material": "leather"],
            confidence: "high",
            croppedImageUrls: [
                "https://firebasestorage.googleapis.com/v0/b/bucket/o/path.jpg?alt=media&token=tok"
            ],
            boundingBoxes: []
        )
        #expect(obj.groupId == "grp-1")
        #expect(obj.label == "leather armchair")
        #expect(obj.category == "furniture")
        #expect(obj.confidence == "high")
        #expect(obj.croppedImageUrls.count == 1)
        #expect(obj.attributes["color"] == "brown")
    }

    // MARK: - Photo Count

    @Test("photoCount returns 1 for single image")
    func testPhotoCount_single() {
        let item = Item(id: "1", userId: "u", imageUrl: "url", status: .complete)
        #expect(item.photoCount == 1)
    }

    @Test("photoCount includes additional images")
    func testPhotoCount_multiple() {
        let item = Item(
            id: "1", userId: "u", imageUrl: "url", status: .complete,
            additionalImageUrls: ["url2", "url3"]
        )
        #expect(item.photoCount == 3)
    }

    @Test("allImageUrls combines primary and additional URLs")
    func testAllImageUrls() {
        let item = Item(
            id: "1", userId: "u", imageUrl: "primary", status: .complete,
            additionalImageUrls: ["additional1", "additional2"]
        )
        #expect(item.allImageUrls == ["primary", "additional1", "additional2"])
    }
}

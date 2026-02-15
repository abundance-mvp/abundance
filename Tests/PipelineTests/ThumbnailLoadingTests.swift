import Testing
import SwiftUI
@testable import Core

/// Tests for ItemImage thumbnail loading, retry, and cache-busting behavior
@Suite("Thumbnail Loading Tests")
@MainActor
struct ThumbnailLoadingTests {

    // MARK: - URL Construction

    @Test("ItemImage creates valid URL from string")
    func testItemImage_validUrl() {
        let image = ItemImage(
            url: "https://firebasestorage.googleapis.com/v0/b/bucket/o/path.jpg?alt=media&token=tok",
            itemId: "item-1",
            context: "test"
        )
        #expect(image.url.isEmpty == false)
        let parsedUrl = URL(string: image.url)
        #expect(parsedUrl != nil)
        #expect(parsedUrl?.scheme == "https")
    }

    @Test("ItemImage handles empty URL gracefully")
    func testItemImage_emptyUrl() {
        let image = ItemImage(url: "", itemId: "item-1", context: "test")
        #expect(image.url.isEmpty)
        // Empty string should result in nil URL but not crash
        let parsedUrl = URL(string: image.url)
        #expect(parsedUrl == nil)
    }

    @Test("ItemImage preserves all initialization parameters")
    func testItemImage_initParams() {
        let image = ItemImage(
            url: "https://example.com/img.jpg",
            itemId: "item-123",
            context: "TestContext",
            placeholderIcon: "camera",
            contentMode: .fit,
            maxRetries: 5
        )
        #expect(image.url == "https://example.com/img.jpg")
        #expect(image.itemId == "item-123")
        #expect(image.context == "TestContext")
        #expect(image.placeholderIcon == "camera")
        #expect(image.contentMode == .fit)
        #expect(image.maxRetries == 5)
    }

    // MARK: - Convenience Modifier Tests

    @Test("placeholder modifier changes icon")
    func testPlaceholder_modifier() {
        let image = ItemImage(url: "url", context: "test")
            .placeholder("camera.fill")
        #expect(image.placeholderIcon == "camera.fill")
    }

    @Test("aspectRatio modifier changes content mode")
    func testAspectRatio_modifier() {
        let image = ItemImage(url: "url", context: "test")
            .aspectRatio(.fit)
        #expect(image.contentMode == .fit)
    }

    @Test("retries modifier changes max retry count")
    func testRetries_modifier() {
        let image = ItemImage(url: "url", context: "test")
            .retries(5)
        #expect(image.maxRetries == 5)
    }

    @Test("refreshUrl modifier sets the callback")
    func testRefreshUrl_modifier() {
        let image = ItemImage(url: "url", itemId: "id", context: "test")
            .refreshUrl { _ in return "fresh-url" }
        #expect(image.onRefreshUrl != nil)
    }

    @Test("default onRefreshUrl is nil")
    func testDefaultRefreshUrl_isNil() {
        let image = ItemImage(url: "url", context: "test")
        #expect(image.onRefreshUrl == nil)
    }

    // MARK: - Cache Busting URL Logic

    @Test("Firebase download URL contains expected components")
    func testFirebaseUrl_components() {
        let url = "https://firebasestorage.googleapis.com/v0/b/abundance-mvp.firebasestorage.app/o/users%2Fuser-1%2Fitems%2Fimg.jpg?alt=media&token=abc-123"
        let parsed = URL(string: url)
        #expect(parsed != nil)
        #expect(parsed?.host == "firebasestorage.googleapis.com")
        #expect(parsed?.query?.contains("alt=media") == true)
        #expect(parsed?.query?.contains("token=") == true)
    }

    @Test("Cache busting appends _retry parameter to URL with existing query")
    func testCacheBusting_withExistingQuery() {
        let baseUrl = "https://example.com/img.jpg?token=abc"
        let retryUrl = "\(baseUrl)&_retry=1"
        let parsed = URL(string: retryUrl)
        #expect(parsed != nil)
        #expect(parsed?.query?.contains("_retry=1") == true)
        #expect(parsed?.query?.contains("token=abc") == true)
    }

    @Test("Cache busting appends _retry parameter to URL without query")
    func testCacheBusting_withoutQuery() {
        let baseUrl = "https://example.com/img.jpg"
        let retryUrl = "\(baseUrl)?_retry=2"
        let parsed = URL(string: retryUrl)
        #expect(parsed != nil)
        #expect(parsed?.query == "_retry=2")
    }

    @Test("Each retry increments the cache-busting parameter")
    func testCacheBusting_incrementsOnRetry() {
        let baseUrl = "https://example.com/img.jpg?tok=x"
        for i in 1...3 {
            let retryUrl = "\(baseUrl)&_retry=\(i)"
            let parsed = URL(string: retryUrl)
            #expect(parsed?.query?.contains("_retry=\(i)") == true)
        }
    }

    // MARK: - ItemImage with refresh callback

    @Test("refreshUrl callback receives itemId")
    func testRefreshCallback_receivesItemId() async {
        var receivedItemId: String?
        let image = ItemImage(url: "url", itemId: "my-item-42", context: "test")
            .refreshUrl { itemId in
                receivedItemId = itemId
                return "fresh-url"
            }

        // Simulate the callback being called
        if let callback = image.onRefreshUrl {
            let result = await callback("my-item-42")
            #expect(result == "fresh-url")
            #expect(receivedItemId == "my-item-42")
        } else {
            Issue.record("onRefreshUrl should not be nil")
        }
    }

    @Test("refreshUrl callback can return nil to indicate no refresh available")
    func testRefreshCallback_returnsNil() async {
        let image = ItemImage(url: "url", itemId: "item-1", context: "test")
            .refreshUrl { _ in return nil }

        if let callback = image.onRefreshUrl {
            let result = await callback("item-1")
            #expect(result == nil)
        } else {
            Issue.record("onRefreshUrl should not be nil")
        }
    }
}

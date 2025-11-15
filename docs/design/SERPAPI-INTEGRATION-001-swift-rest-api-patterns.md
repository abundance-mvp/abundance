# SERPAPI-INTEGRATION-001: Swift REST API Integration Patterns

**Document ID:** SERPAPI-INTEGRATION-001
**Date:** 2025-11-01
**Status:** APPROVED
**Related Documents:**
- DESIGN-005: Layer 2b Product Search Architecture
- [ADR-016-image-hosting-strategy](docs/adr/ADR-016-image-hosting-strategy.md): Image Hosting Strategy (GCS + Cloud CDN)
- [ADR-017-llm-parsing-architecture](docs/adr/ADR-017-llm-parsing-architecture.md): LLM Parsing Architecture (Claude Haiku)
- TECH-STACK-001: Complete Technology Map

---

## Executive Summary

SerpAPI Google Lens API does not have a native Swift SDK with Google Lens support. The official Swift package (serpapi-search-swift) is outdated (2021) and does not support Google Lens API calls. Therefore, we must integrate via **direct REST API calls using Swift URLSession**.

This document specifies the complete Swift implementation pattern for calling SerpAPI Google Lens from iOS to perform visual product searches.

---

## Critical Discovery: Why No Native SDK?

### SerpAPI Swift SDK Limitations

**Package:** `serpapi-search-swift`
**Status:** Early development (last updated May 2021)
**Issue:** No Google Lens API support

From the official documentation:
> "Swift 5 JSON parse is limited to static object... not all the field you're looking for might be present."

**Supported engines:** Google Search, Bing, Baidu, Yahoo, eBay, Home Depot
**NOT supported:** Google Lens

### Decision: Direct REST API Integration

**Rationale:**
1. Google Lens API is the core requirement for Layer 2b product search
2. No native Swift SDK provides Google Lens support
3. SerpAPI provides a well-documented REST API
4. Swift URLSession is production-ready for HTTPS REST calls

---

## Architecture Overview

### High-Level Flow

```
iOS App (Swift)
    ↓
1. Crop object using Vision Framework (Layer 1)
    ↓
2. Upload to GCS + Cloud CDN (Cloud Function)
    ↓
3. Receive public HTTPS URL
    ↓
4. Call SerpAPI Google Lens with URL (Swift URLSession)
    ↓
5. Parse visual_matches JSON response
    ↓
6. Send to Layer 3 for synthesis
```

### Why Public URLs Are Required

**From SerpAPI documentation:**
> "The only required parameter is `url`, which represents the URL of the image we want to search for."

**Critical limitation discovered:**
> "We have had our users have problems when using Amazon S3 as a hosting image provider. Google can't access those images on S3."

**Our solution:** Google Cloud Storage + Cloud CDN (GCS is Google infrastructure, should work reliably)

---

## Swift Implementation

### 1. SerpAPI Service Class

```swift
import Foundation

/// Service for calling SerpAPI Google Lens API
final class SerpAPIService {

    // MARK: - Configuration

    private let apiKey: String
    private let baseURL = "https://serpapi.com/search"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Public Methods

    /// Search for products using Google Lens visual search
    /// - Parameter imageURL: Public HTTPS URL of the image (from GCS + CDN)
    /// - Returns: Visual matches with product information
    func searchWithGoogleLens(imageURL: String) async throws -> SerpAPIResponse {
        // Build request URL
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "engine", value: "google_lens"),
            URLQueryItem(name: "url", value: imageURL),
            URLQueryItem(name: "api_key", value: apiKey)
        ]

        guard let url = components.url else {
            throw SerpAPIError.invalidURL
        }

        // Make request
        let (data, response) = try await URLSession.shared.data(from: url)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SerpAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw SerpAPIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse JSON
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let apiResponse = try decoder.decode(SerpAPIResponse.self, from: data)
        return apiResponse
    }
}

// MARK: - Error Types

enum SerpAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case parsingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Failed to construct SerpAPI request URL"
        case .invalidResponse:
            return "Invalid response from SerpAPI"
        case .httpError(let code):
            return "SerpAPI returned HTTP error: \(code)"
        case .parsingError(let message):
            return "Failed to parse SerpAPI response: \(message)"
        }
    }
}
```

---

### 2. Response Models

```swift
import Foundation

/// SerpAPI Google Lens response structure
struct SerpAPIResponse: Codable {
    let visualMatches: [VisualMatch]?
    let searchMetadata: SearchMetadata?
    let searchInformation: SearchInformation?
}

/// Individual visual match from Google Lens
struct VisualMatch: Codable {
    let title: String?
    let link: String?
    let source: String?
    let sourceIcon: String?
    let thumbnail: String?
    let price: Price?
}

/// Price information from shopping results
struct Price: Codable {
    let value: String?
    let extracted: Double?
    let currency: String?
}

/// Metadata about the search request
struct SearchMetadata: Codable {
    let id: String?
    let status: String?
    let jsonEndpoint: String?
    let createdAt: String?
    let processedAt: String?
    let totalTimeTaken: Double?
}

/// Information about search results
struct SearchInformation: Codable {
    let imageResultsState: String?
}
```

---

### 3. Integration with GCS Upload

```swift
import Foundation
import FirebaseFunctions

/// Uploads image to GCS and gets public CDN URL
final class ImageUploadService {

    private let functions = Functions.functions()

    /// Upload cropped image to GCS + CDN
    /// - Parameters:
    ///   - imageData: JPEG data of cropped object
    ///   - userId: User ID for path organization
    ///   - itemId: Item ID for path organization
    /// - Returns: Public HTTPS CDN URL
    func uploadToGCS(imageData: Data, userId: String, itemId: String) async throws -> String {
        // Convert to base64 for Cloud Function transmission
        let base64Image = imageData.base64EncodedString()

        // Call Cloud Function
        let uploadFunction = functions.httpsCallable("uploadImageToCDN")
        let result = try await uploadFunction.call([
            "userId": userId,
            "itemId": itemId,
            "imageData": base64Image
        ])

        // Extract public CDN URL
        guard let data = result.data as? [String: Any],
              let cdnUrl = data["cdnUrl"] as? String else {
            throw ImageUploadError.missingURL
        }

        return cdnUrl
    }
}

enum ImageUploadError: Error {
    case missingURL
    case uploadFailed(String)
}
```

---

### 4. Complete Workflow Integration

```swift
import UIKit

/// Orchestrates Layer 2b: Product Search workflow
final class ProductSearchService {

    private let imageUpload = ImageUploadService()
    private let serpAPI: SerpAPIService

    init(serpAPIKey: String) {
        self.serpAPI = SerpAPIService(apiKey: serpAPIKey)
    }

    /// Search for product using visual analysis
    /// - Parameters:
    ///   - croppedImage: UIImage of cropped object from Layer 1
    ///   - userId: User ID
    ///   - itemId: Item ID
    /// - Returns: Visual matches from Google Lens
    func searchProduct(
        croppedImage: UIImage,
        userId: String,
        itemId: String
    ) async throws -> [VisualMatch] {

        // Step 1: Convert to JPEG
        guard let jpegData = croppedImage.jpegData(compressionQuality: 0.8) else {
            throw ProductSearchError.imageCompressionFailed
        }

        // Step 2: Upload to GCS + CDN (get public URL)
        print("⬆️ Uploading image to GCS + Cloud CDN...")
        let publicURL = try await imageUpload.uploadToGCS(
            imageData: jpegData,
            userId: userId,
            itemId: itemId
        )
        print("✅ Public CDN URL: \(publicURL)")

        // Step 3: Call SerpAPI Google Lens
        print("🔍 Searching with SerpAPI Google Lens...")
        let response = try await serpAPI.searchWithGoogleLens(imageURL: publicURL)
        print("✅ Received \(response.visualMatches?.count ?? 0) visual matches")

        // Step 4: Return visual matches
        return response.visualMatches ?? []
    }
}

enum ProductSearchError: Error {
    case imageCompressionFailed
    case noMatches
}
```

---

### 5. Usage Example in ViewModel

```swift
import SwiftUI

@MainActor
final class ItemCatalogViewModel: ObservableObject {

    @Published var productMatches: [VisualMatch] = []
    @Published var isSearching = false
    @Published var errorMessage: String?

    private let productSearch: ProductSearchService

    init(serpAPIKey: String) {
        self.productSearch = ProductSearchService(serpAPIKey: serpAPIKey)
    }

    func searchForProduct(croppedImage: UIImage, userId: String, itemId: String) {
        isSearching = true
        errorMessage = nil

        Task {
            do {
                let matches = try await productSearch.searchProduct(
                    croppedImage: croppedImage,
                    userId: userId,
                    itemId: itemId
                )

                self.productMatches = matches

                // Log for debugging
                for (index, match) in matches.enumerated() {
                    print("""
                    Match #\(index + 1):
                    - Title: \(match.title ?? "N/A")
                    - Source: \(match.source ?? "N/A")
                    - Price: \(match.price?.value ?? "N/A")
                    - Link: \(match.link ?? "N/A")
                    """)
                }

            } catch {
                self.errorMessage = "Product search failed: \(error.localizedDescription)"
                print("❌ Product search error: \(error)")
            }

            self.isSearching = false
        }
    }
}
```

---

## Cloud Function: Upload to GCS

```javascript
const {Storage} = require('@google-cloud/storage');
const storage = new Storage();
const bucketName = 'abundance-cropped-images';

exports.uploadImageToCDN = functions.https.onCall(async (data, context) => {
  const {userId, itemId, imageData} = data;

  // Decode base64 image
  const imageBuffer = Buffer.from(imageData, 'base64');

  // Generate filename with timestamp
  const timestamp = Date.now();
  const filename = `items/${userId}/${itemId}-${timestamp}.jpg`;

  // Upload to GCS
  const bucket = storage.bucket(bucketName);
  const file = bucket.file(filename);

  await file.save(imageBuffer, {
    metadata: {
      contentType: 'image/jpeg',
      cacheControl: 'public, max-age=3600' // 1 hour cache for CDN
    }
  });

  // Generate public CDN URL
  const cdnUrl = `https://cdn.abundance.app/${filename}`;

  return {cdnUrl};
});
```

---

## GCS + Cloud CDN Setup

### 1. Create GCS Bucket

```bash
# Create bucket for cropped images
gcloud storage buckets create gs://abundance-cropped-images \
  --location=us-central1 \
  --uniform-bucket-level-access

# Enable public read access
gcloud storage buckets add-iam-policy-binding gs://abundance-cropped-images \
  --member=allUsers \
  --role=roles/storage.objectViewer
```

### 2. Configure Cloud CDN

```bash
# Create backend bucket
gcloud compute backend-buckets create abundance-image-backend \
  --gcs-bucket-name=abundance-cropped-images \
  --enable-cdn

# Create URL map
gcloud compute url-maps create abundance-cdn \
  --default-backend-bucket=abundance-image-backend

# Create HTTPS proxy
gcloud compute ssl-certificates create abundance-cdn-cert \
  --domains=cdn.abundance.app

gcloud compute target-https-proxies create abundance-cdn-proxy \
  --url-map=abundance-cdn \
  --ssl-certificates=abundance-cdn-cert

# Create forwarding rule
gcloud compute forwarding-rules create abundance-cdn-rule \
  --global \
  --target-https-proxy=abundance-cdn-proxy \
  --ports=443
```

---

## Testing Strategy

### Unit Tests

```swift
import XCTest
@testable import Abundance

final class SerpAPIServiceTests: XCTestCase {

    func testGoogleLensSearch() async throws {
        // Given
        let apiKey = ProcessInfo.processInfo.environment["SERPAPI_TEST_KEY"]!
        let service = SerpAPIService(apiKey: apiKey)
        let testImageURL = "https://cdn.abundance.app/test/sample-headphones.jpg"

        // When
        let response = try await service.searchWithGoogleLens(imageURL: testImageURL)

        // Then
        XCTAssertNotNil(response.visualMatches)
        XCTAssertGreaterThan(response.visualMatches?.count ?? 0, 0)

        if let firstMatch = response.visualMatches?.first {
            XCTAssertNotNil(firstMatch.title)
            XCTAssertNotNil(firstMatch.link)
        }
    }

    func testInvalidURL() async throws {
        // Given
        let service = SerpAPIService(apiKey: "test-key")
        let invalidURL = "not-a-valid-url"

        // Then
        do {
            _ = try await service.searchWithGoogleLens(imageURL: invalidURL)
            XCTFail("Should have thrown error")
        } catch SerpAPIError.httpError {
            // Expected error
        }
    }
}
```

### Integration Tests

```swift
final class ProductSearchIntegrationTests: XCTestCase {

    func testFullWorkflow() async throws {
        // Given: Test image
        let testImage = UIImage(named: "test-headphones")!
        let userId = "test-user-123"
        let itemId = "test-item-456"

        let apiKey = ProcessInfo.processInfo.environment["SERPAPI_TEST_KEY"]!
        let service = ProductSearchService(serpAPIKey: apiKey)

        // When: Search for product
        let matches = try await service.searchProduct(
            croppedImage: testImage,
            userId: userId,
            itemId: itemId
        )

        // Then: Should return matches
        XCTAssertGreaterThan(matches.count, 0)
        XCTAssertNotNil(matches.first?.title)
        XCTAssertNotNil(matches.first?.source)
    }
}
```

---

## Error Handling

### Common Errors & Resolutions

| Error | Cause | Resolution |
|-------|-------|------------|
| **HTTP 403** | Invalid API key | Verify SERPAPI_API_KEY in environment |
| **HTTP 400** | Invalid image URL | Check GCS public access, verify CDN URL format |
| **No visual matches** | Image not recognized | Fallback to Layer 2a (Gemini attributes only) |
| **GCS upload failed** | Permissions error | Verify Cloud Function service account has Storage Object Creator role |
| **CDN URL inaccessible** | Bucket not public | Run `gcloud storage buckets add-iam-policy-binding` |

### Retry Strategy

```swift
func searchWithRetry(imageURL: String, maxRetries: Int = 3) async throws -> SerpAPIResponse {
    var lastError: Error?

    for attempt in 1...maxRetries {
        do {
            return try await serpAPI.searchWithGoogleLens(imageURL: imageURL)
        } catch let error as SerpAPIError {
            lastError = error
            print("⚠️ SerpAPI attempt \(attempt) failed: \(error)")

            // Don't retry on client errors
            if case .httpError(let code) = error, (400...499).contains(code) {
                throw error
            }

            // Exponential backoff
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
        }
    }

    throw lastError ?? SerpAPIError.invalidResponse
}
```

---

## Cost Monitoring

### Track SerpAPI Usage

```swift
import FirebaseAnalytics

extension ProductSearchService {

    func trackSerpAPIUsage(matches: Int, cost: Double = 0.010) {
        Analytics.logEvent("serpapi_search", parameters: [
            "visual_matches_count": matches,
            "estimated_cost_usd": cost
        ])

        // Also log to Cloud Logging for cost analysis
        print("💰 SerpAPI usage: \(matches) matches, $\(cost)")
    }
}
```

### Monthly Cost Projection

```swift
// 75K items/month × $0.010/search = $750/month
let monthlySearches = 75_000
let costPerSearch = 0.010
let monthlyCost = Double(monthlySearches) * costPerSearch
print("💰 Projected monthly cost: $\(monthlyCost)")
```

---

## Performance Optimization

### Cache Results

```swift
final class SerpAPICacheService {

    private let cache = NSCache<NSString, CachedResponse>()

    func getCachedResponse(for imageURL: String) -> [VisualMatch]? {
        let key = NSString(string: imageURL)
        return cache.object(forKey: key)?.matches
    }

    func cacheResponse(_ matches: [VisualMatch], for imageURL: String) {
        let key = NSString(string: imageURL)
        let cached = CachedResponse(matches: matches, timestamp: Date())
        cache.setObject(cached, forKey: key)
    }
}

class CachedResponse {
    let matches: [VisualMatch]
    let timestamp: Date

    init(matches: [VisualMatch], timestamp: Date) {
        self.matches = matches
        self.timestamp = timestamp
    }
}
```

---

## Security Considerations

### 1. API Key Management

```swift
// Store API key in Keychain, not UserDefaults
import Security

final class KeychainService {

    func saveSerpAPIKey(_ key: String) throws {
        let data = key.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "serpapi_key",
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary) // Remove old value
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func getSerpAPIKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "serpapi_key",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.loadFailed(status)
        }

        return key
    }
}
```

### 2. Validate Public URLs

```swift
func isValidPublicURL(_ urlString: String) -> Bool {
    guard let url = URL(string: urlString),
          url.scheme == "https",
          url.host == "cdn.abundance.app" else {
        return false
    }
    return true
}
```

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-01 | 1.0 | Initial Swift REST API integration specification for SerpAPI Google Lens |

---

## References

1. **SerpAPI Google Lens API**: https://serpapi.com/google-lens-api
2. **SerpAPI Blog: Image Search**: https://serpapi.com/blog/building-an-image-based-search-app-with-google-lens-api/
3. **SerpAPI Swift (outdated)**: https://serpapi.com/integrations/swift
4. **GCS Public URLs**: https://cloud.google.com/storage/docs/access-control/making-data-public
5. **ADR-016**: Image Hosting Strategy (GCS + Cloud CDN)
6. **DESIGN-005**: Layer 2b Product Search Architecture

---

**Status:** ✅ APPROVED FOR IMPLEMENTATION
**Next Steps:** Integrate into Stage 2.2 iOS implementation plan


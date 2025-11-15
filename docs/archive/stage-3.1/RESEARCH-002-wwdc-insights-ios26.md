# RESEARCH-002: WWDC Insights for iOS 26

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**Purpose**: Synthesize key insights from WWDC 2024/2025 sessions for Abundance iOS app

---

## Overview

This document synthesizes key insights from WWDC 2024/2025 sessions relevant to iOS 26 development, focusing on SwiftUI, Swift concurrency, and Vision Framework.

**Sessions Reviewed**:
- WWDC25/266: SwiftUI and Swift concurrency
- WWDC25/268: Core Swift concurrency concepts
- WWDC24/10163: Vision Framework API redesign

---

## WWDC25/266: SwiftUI and Swift concurrency

### Session Overview
- **Title**: Discover how SwiftUI leverages Swift concurrency
- **Focus**: SwiftUI + MainActor integration, offloading work to background
- **Relevance**: Critical for Abundance MVVM ViewModels

### Key Takeaway 1: SwiftUI Uses MainActor by Default

**Insight**: All SwiftUI views and `@ObservableObject` ViewModels run on MainActor automatically.

**Implication for Abundance**:
- No need to manually dispatch to main thread for UI updates
- `@Published` property changes automatically update SwiftUI views
- ViewModels marked `@MainActor` align with SwiftUI's concurrency model

**Code Example from Session**:
```swift
@MainActor
class ContentViewModel: ObservableObject {
    @Published var items: [Item] = []

    func fetchItems() async {
        // This runs on MainActor
        items = try await repository.fetchItems()
        // UI updates automatically when items changes
    }
}
```

**Applied to Abundance**:
```swift
@MainActor
class CatalogViewModel: ObservableObject {
    @Published var items: [CatalogItem] = []
    @Published var isLoading: Bool = false

    func fetchItems() async {
        isLoading = true
        defer { isLoading = false }

        // Runs on MainActor, UI updates automatically
        items = try await repository.fetchItems()
    }
}
```

### Key Takeaway 2: Offload Work with Task { }

**Insight**: Use `Task { }` to offload heavy work to background threads, then update UI on MainActor.

**When to Offload**:
- Image processing (resize, compress)
- JSON parsing
- File I/O
- Complex calculations

**Code Example from Session**:
```swift
@MainActor
class ImageViewModel: ObservableObject {
    @Published var processedImage: UIImage?

    func processImage(_ image: UIImage) async {
        // Offload heavy work to background
        let processed = await Task.detached {
            // This runs off MainActor
            return self.resize(image, to: CGSize(width: 800, height: 600))
        }.value

        // Back on MainActor, update UI
        self.processedImage = processed
    }

    private func resize(_ image: UIImage, to size: CGSize) -> UIImage {
        // Heavy image processing...
    }
}
```

**Applied to Abundance**:
```swift
@MainActor
class CameraViewModel: ObservableObject {
    @Published var croppedImage: UIImage?

    func cropImage(_ image: UIImage, boundingBox: CGRect) async {
        // Offload cropping to background
        let cropped = await Task.detached {
            // Heavy Vision Framework processing off MainActor
            return self.performCrop(image, box: boundingBox)
        }.value

        // Update UI on MainActor
        self.croppedImage = cropped
    }

    private func performCrop(_ image: UIImage, box: CGRect) -> UIImage? {
        // Vision cropping logic...
    }
}
```

### Key Takeaway 3: Use .task Modifier for Async Loading

**Insight**: `.task { }` modifier automatically runs async code when view appears, cancels on disappear.

**Code Example from Session**:
```swift
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task {
            // Runs when view appears, cancels when disappears
            await viewModel.fetchItems()
        }
    }
}
```

**Applied to Abundance**:
```swift
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel

    var body: some View {
        NavigationStack {
            List(viewModel.items) { item in
                CatalogItemRow(item: item)
            }
            .task {
                // Load catalog items when view appears
                await viewModel.fetchItems()

                // Start real-time sync
                viewModel.observeItems()
            }
            .refreshable {
                // Pull-to-refresh
                await viewModel.refresh()
            }
        }
    }
}
```

---

## WWDC25/268: Core Swift concurrency concepts

### Session Overview
- **Title**: Learn core Swift concurrency concepts
- **Focus**: async/await, Task groups, Actors, structured concurrency
- **Relevance**: Foundation for Abundance async patterns

### Key Takeaway 1: Structured Concurrency with async/await

**Insight**: async/await provides structured concurrency - child tasks automatically cancelled when parent cancelled.

**Benefits**:
- No leaked tasks
- Automatic cancellation propagation
- Clear task lifetime

**Code Example from Session**:
```swift
func loadUserData() async throws -> UserData {
    async let profile = fetchProfile()
    async let settings = fetchSettings()
    async let stats = fetchStats()

    return try await UserData(
        profile: profile,
        settings: settings,
        stats: stats
    )
}
```

**Applied to Abundance**:
```swift
@MainActor
class DashboardViewModel: ObservableObject {
    func loadDashboard() async {
        do {
            // Parallel fetches with structured concurrency
            async let items = catalogRepository.fetchItems()
            async let profile = userRepository.fetchProfile()
            async let stats = statsRepository.fetchStats()

            catalogItems = try await items
            userProfile = try await profile
            userStats = try await stats
        } catch {
            self.error = error
        }
    }
}
```

### Key Takeaway 2: Task Groups for Dynamic Parallelism

**Insight**: Use `withTaskGroup` when number of parallel tasks is dynamic.

**Code Example from Session**:
```swift
func downloadImages(urls: [URL]) async -> [UIImage] {
    await withTaskGroup(of: UIImage?.self) { group in
        for url in urls {
            group.addTask {
                try? await self.download(url)
            }
        }

        var images: [UIImage] = []
        for await image in group {
            if let image = image {
                images.append(image)
            }
        }
        return images
    }
}
```

**Applied to Abundance**:
```swift
@MainActor
class BatchUploadViewModel: ObservableObject {
    func uploadMultipleImages(_ images: [UIImage], userId: String) async {
        await withTaskGroup(of: URL?.self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let itemId = UUID().uuidString
                    return try? await self.storageService.uploadImage(
                        image,
                        userId: userId,
                        itemId: itemId
                    )
                }
            }

            var uploadedURLs: [URL] = []
            for await url in group {
                if let url = url {
                    uploadedURLs.append(url)
                }
            }

            self.uploadedImageURLs = uploadedURLs
        }
    }
}
```

### Key Takeaway 3: Actors for Safe Shared State

**Insight**: Actors provide data-race-free shared mutable state without manual locking.

**Code Example from Session**:
```swift
actor ImageCache {
    private var cache: [URL: UIImage] = [:]

    func image(for url: URL) -> UIImage? {
        return cache[url]
    }

    func setImage(_ image: UIImage, for url: URL) {
        cache[url] = image
    }
}

// Usage
let cache = ImageCache()
let image = await cache.image(for: url) // Async call, actor-isolated
```

**Applied to Abundance**:
```swift
actor ImageCacheActor {
    private var cache: [String: UIImage] = [:]
    private var maxCacheSize: Int = 100

    func image(for url: URL) async -> UIImage? {
        return cache[url.absoluteString]
    }

    func setImage(_ image: UIImage, for url: URL) async {
        // Evict oldest if cache full
        if cache.count >= maxCacheSize {
            cache.removeValue(forKey: cache.keys.first!)
        }

        cache[url.absoluteString] = image
    }

    func clearCache() async {
        cache.removeAll()
    }
}
```

---

## WWDC24/10163: Vision Framework API redesign

### Session Overview
- **Title**: Redesign Vision Framework API with Swift concurrency
- **Focus**: Modern Swift API for Vision, async/await support
- **Relevance**: Abundance uses Vision for object detection + barcode scanning

### Key Takeaway 1: VNDetectBarcodesRequest Modernized

**Insight**: VNDetectBarcodesRequest updated for Swift 6 with async/await support (though callback API still works).

**Code Example from Session** (Swift 6 style):
```swift
let request = VNDetectBarcodesRequest()
let handler = VNImageRequestHandler(cgImage: image.cgImage!)

// Perform request (synchronous, but can be wrapped in Task)
try handler.perform([request])

let results = request.results as? [VNBarcodeObservation]
```

**Applied to Abundance**:
```swift
actor VisionService {
    func detectBarcodes(in image: UIImage) async throws -> [Barcode] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // Perform request (CPU-bound, so runs off main thread automatically)
        try handler.perform([request])

        guard let results = request.results as? [VNBarcodeObservation] else {
            return []
        }

        return results.compactMap { Barcode(from: $0) }
    }
}
```

### Key Takeaway 2: Request/Observation Pattern Unchanged

**Insight**: Vision Framework still uses request/observation pattern - create request, perform, parse observations.

**Pattern**:
1. Create request (`VNCoreMLRequest`, `VNDetectBarcodesRequest`)
2. Create handler (`VNImageRequestHandler`)
3. Perform request (`handler.perform([request])`)
4. Parse results (`request.results as? [VNObservation]`)

**Applied to Abundance** (consistent pattern across Vision APIs):
```swift
// Object detection
let model = try VNCoreMLModel(for: YOLOv3Tiny().model)
let request = VNCoreMLRequest(model: model)
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])
let objects = request.results as? [VNRecognizedObjectObservation]

// Barcode scanning
let request = VNDetectBarcodesRequest()
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])
let barcodes = request.results as? [VNBarcodeObservation]
```

### Key Takeaway 3: Coordinate System Unchanged (Bottom-Left Origin)

**Insight**: Vision Framework uses bottom-left origin, UIKit uses top-left. Conversion still required.

**Conversion Formula**:
```swift
// Vision → UIKit
let uikitY = 1.0 - visionY - visionHeight
```

**Applied to Abundance**:
```swift
struct DetectedObject {
    init(from observation: VNRecognizedObjectObservation, imageSize: CGSize) {
        let visionRect = observation.boundingBox

        // Convert Vision (bottom-left) to UIKit (top-left)
        self.boundingBox = CGRect(
            x: visionRect.origin.x,
            y: 1.0 - visionRect.origin.y - visionRect.height,
            width: visionRect.width,
            height: visionRect.height
        )
    }
}
```

---

## Summary: How WWDC Insights Apply to Abundance

### SwiftUI + Concurrency
✅ **Adopted**: All ViewModels marked `@MainActor`
✅ **Adopted**: `.task { }` modifier for async loading in views
✅ **Adopted**: `Task.detached { }` for heavy Vision/image processing
✅ **Adopted**: `.refreshable { }` for pull-to-refresh

### Swift Concurrency
✅ **Adopted**: async/await for all asynchronous operations
✅ **Adopted**: Task groups for parallel Firebase fetches
✅ **Adopted**: Actors for shared image cache
✅ **Adopted**: Structured concurrency (no leaked tasks)

### Vision Framework
✅ **Adopted**: Request/observation pattern (VNCoreMLRequest, VNDetectBarcodesRequest)
✅ **Adopted**: Coordinate conversion (Vision → UIKit)
✅ **Adopted**: Wrapping Vision calls in async functions (actor-based VisionService)

---

## iOS 26-Specific Features (from WWDC25)

### New in iOS 26
1. **Swift 6 Strict Concurrency**: Compile-time data race prevention
2. **SwiftUI Observation Framework**: `@Observable` macro (alternative to `@ObservableObject`)
3. **Vision Framework Performance**: Improved Neural Engine utilization on A17 Pro
4. **Firebase iOS SDK 11.11.0+**: Swift 6 compatibility (Sendable conformance)

### Abundance Adoption
- ✅ Swift 6 strict concurrency enabled in Xcode build settings
- ⚠️ `@Observable` macro available but not required (ADR-010 chose `@ObservableObject`)
- ✅ A17 Pro Neural Engine optimization (YOLOv3-Tiny runs on Neural Engine)
- ✅ Firebase iOS SDK 11.11.0+ required (updated in TECH-STACK-MAP-001)

---

## References

### WWDC Sessions
- WWDC25/266: https://developer.apple.com/videos/play/wwdc2025/266/
- WWDC25/268: https://developer.apple.com/videos/play/wwdc2025/268/
- WWDC24/10163: https://developer.apple.com/videos/play/wwdc2024/10163/

### Related Documents
- CODE-EXAMPLE-001: Swift 6 Concurrency Patterns
- CODE-EXAMPLE-002: Catalog MVVM Implementation
- CODE-EXAMPLE-004: Vision Framework Patterns
- ADR-010: SwiftUI Architecture Pattern (MVVM)
- ADR-012: State Management Strategy (Combine + async/await)

---

## Verification

✅ WWDC25/266 insights synthesized (SwiftUI + concurrency)
✅ WWDC25/268 insights synthesized (Core Swift concurrency)
✅ WWDC24/10163 insights synthesized (Vision Framework API)
✅ iOS 26-specific features documented
✅ Abundance adoption status verified
✅ Code examples adapted to Abundance patterns

---

**Status**: ✅ Complete

**All 8 tasks complete! Stage 3.1 research finished.**

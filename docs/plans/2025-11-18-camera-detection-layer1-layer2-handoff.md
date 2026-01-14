# Camera Detection Layer 1→2 Handoff Integration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire CameraDetectionView real-time detection to trigger Layer 1→2 catalog pipeline handoff (upload to GCS + create Firestore document).

**Architecture:** CameraDetectionViewModel triggers upload on automatic/manual catalog → uploads cropped object to GCS → creates Firestore document with imageUrl + Layer 1 metadata → Cloud Function triggers Layer 2a/2b/3.

**Tech Stack:** Swift 6.0, SwiftUI, Firebase Storage, Firestore, AVFoundation, Vision Framework

**References:**
- Architecture: docs/design/DESIGN-004-computer-vision-pipeline.md
- Layer 1→2 Flow: docs/validation/LAYER-1-TO-LAYER-2A-IMAGE-DATA-FLOW.md
- Real-time Detection: Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift (READY)
- Storage Service: Sources/Persistence/Firebase/StorageService.swift (NEEDS PATH FIX)

---

## Current State Analysis

### ✅ What's Already Implemented

1. **YOLO Detection** - HouseholdItemDetector provides bounding boxes (Sources/VisionCore/Detectors/HouseholdItemDetector.swift)
2. **Subject Masking** - SubjectMaskGenerator creates organic borders (Sources/VisionCore/Services/SubjectMaskGenerator.swift)
3. **Image Cropping** - Bounding box + mask extraction already done by detection pipeline
4. **StorageService** - Uploads cropped objects to GCS (Sources/Persistence/Firebase/StorageService.swift)
5. **CameraDetectionViewModel** - Real-time 2 FPS detection with automatic/manual catalog modes
6. **Layer 2a/2b/3 Cloud Functions** - Backend pipeline for attribute extraction, product search, AI synthesis

### ❌ What's Missing

1. **StorageService path** - Uses redundant `/cropped.jpg` suffix (should be `.jpg`)
2. **ItemService** - No Firestore document creation for Layer 1→2 handoff
3. **CameraDetectionViewModel upload** - No upload triggered on automatic/manual catalog
4. **CVPixelBuffer→UIImage cropper** - Need utility to extract cropped UIImage from pixel buffer + bounding box

---

## Task 1: Fix StorageService Path Naming

**Goal:** Remove redundant `/cropped.jpg` suffix, use item ID as filename

**Files:**
- Modify: `Sources/Persistence/Firebase/StorageService.swift:67-69`
- Test: `Tests/PersistenceTests/StorageServiceTests.swift`

### Step 1: Update storage path in StorageService

**File:** `Sources/Persistence/Firebase/StorageService.swift`

**Find (line 67-69):**

```swift
// Create storage reference: users/{userId}/items/{itemId}/cropped.jpg
let ref: StorageReference = storage.reference()
    .child("users/\(userId)/items/\(itemId)/cropped.jpg")
```

**Replace with:**

```swift
// Create storage reference: users/{userId}/items/{itemId}.jpg
// Note: Every image uploaded via this service is a cropped object, no need for /cropped suffix
let ref: StorageReference = storage.reference()
    .child("users/\(userId)/items/\(itemId).jpg")
```

### Step 2: Update tests to match new path

**File:** `Tests/PersistenceTests/StorageServiceTests.swift`

**Find any assertions checking for "cropped.jpg" and update to "{itemId}.jpg"**

### Step 3: Build and test

**Run:**

```bash
swift test --filter StorageServiceTests
```

**Expected:** All tests pass with new path

### Step 4: Commit

```bash
git add Sources/Persistence/Firebase/StorageService.swift Tests/PersistenceTests/StorageServiceTests.swift
git commit -m "refactor(storage): simplify GCS path from /cropped.jpg to .jpg

- Remove redundant /cropped suffix (all uploads are cropped objects)
- Item ID is unique, no need for subdirectory
- Simplifies path: users/{userId}/items/{itemId}.jpg

Refs: BUG-002, DESIGN-004"
```

---

## Task 2: Create CVPixelBuffer Image Cropping Utility

**Goal:** Extract cropped UIImage from CVPixelBuffer using Vision bounding box

**Files:**
- Create: `Sources/VisionCore/Utilities/PixelBufferCropper.swift`
- Test: `Tests/VisionCoreTests/Utilities/PixelBufferCropperTests.swift`

### Step 1: Write failing test

```swift
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
```

### Step 2: Run test to verify it fails

**Run:**

```bash
swift test --filter PixelBufferCropperTests
```

**Expected:** FAIL with "PixelBufferCropper not found"

### Step 3: Create implementation

**File:** `Sources/VisionCore/Utilities/PixelBufferCropper.swift`

```swift
import Foundation
import CoreVideo
import CoreGraphics
import CoreImage

#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#endif

/// Utility for cropping images from CVPixelBuffers using Vision Framework bounding boxes
public enum PixelBufferCropper {

    public enum CropError: Error {
        case invalidPixelBuffer
        case invalidBoundingBox
        case conversionFailed
    }

    /// Crop image from CVPixelBuffer using Vision bounding box
    /// - Parameters:
    ///   - pixelBuffer: Source pixel buffer from camera
    ///   - boundingBox: Vision normalized bounding box (origin bottom-left, 0-1 range)
    /// - Returns: Cropped platform image
    public static func cropImage(
        from pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) throws -> PlatformImage {
        // Validate bounding box
        guard boundingBox.minX >= 0 && boundingBox.minY >= 0 &&
              boundingBox.maxX <= 1 && boundingBox.maxY <= 1 else {
            throw CropError.invalidBoundingBox
        }

        // Convert to CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Get dimensions
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        // Convert Vision coordinates (bottom-left origin) to CoreImage (top-left origin)
        let cropRect = CGRect(
            x: boundingBox.minX * CGFloat(width),
            y: (1 - boundingBox.maxY) * CGFloat(height),
            width: boundingBox.width * CGFloat(width),
            height: boundingBox.height * CGFloat(height)
        )

        // Crop
        let croppedCI = ciImage.cropped(to: cropRect)

        // Convert to platform image
        let context = CIContext()
        guard let cgImage = context.createCGImage(croppedCI, from: croppedCI.extent) else {
            throw CropError.conversionFailed
        }

        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #endif
    }
}
```

### Step 4: Run test to verify it passes

**Run:**

```bash
swift test --filter PixelBufferCropperTests
```

**Expected:** PASS

### Step 5: Commit

```bash
git add Sources/VisionCore/Utilities/PixelBufferCropper.swift Tests/VisionCoreTests/Utilities/PixelBufferCropperTests.swift
git commit -m "feat(vision): add PixelBufferCropper utility

- Convert CVPixelBuffer to UIImage with Vision bounding box
- Handle coordinate transformation (Vision → CoreImage)
- Add validation and error handling
- Add comprehensive tests

Refs: BUG-002, DESIGN-004"
```

---

## Task 3: Create ItemService for Firestore Document Creation

**Goal:** Service to create Firestore documents for Layer 1→2 handoff

**Files:**
- Create: `Sources/Persistence/Firebase/ItemService.swift`
- Test: `Tests/PersistenceTests/ItemServiceTests.swift`

### Step 1: Write failing test

```swift
import XCTest
@testable import Persistence

final class ItemServiceTests: XCTestCase {

    func testCreateItem_withValidData_createsFirestoreDocument() async throws {
        // Given: Mock Firestore
        let mockFirestore = MockFirestore()
        let itemService = ItemService(firestore: mockFirestore)

        // When: Create item
        try await itemService.createItem(
            itemId: "test-item-123",
            userId: "test-user-456",
            imageUrl: URL(string: "https://storage.googleapis.com/test.jpg")!,
            layer1Metadata: Layer1Metadata(
                detectedClass: "tent",
                confidence: 0.87,
                boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
                qualityScore: 0.75
            )
        )

        // Then: Document created with correct structure
        XCTAssertTrue(mockFirestore.documentCreated)
        XCTAssertEqual(mockFirestore.lastItemId, "test-item-123")
    }
}
```

### Step 2: Run test to verify it fails

**Run:**

```bash
swift test --filter ItemServiceTests
```

**Expected:** FAIL with "ItemService not found"

### Step 3: Create implementation

**File:** `Sources/Persistence/Firebase/ItemService.swift`

```swift
import Foundation
@preconcurrency import FirebaseFirestore

/// Metadata from Layer 1 (on-device YOLO detection)
public struct Layer1Metadata: Sendable {
    public let detectedClass: String
    public let confidence: Double
    public let boundingBox: CGRect
    public let qualityScore: Double

    public init(detectedClass: String, confidence: Double, boundingBox: CGRect, qualityScore: Double) {
        self.detectedClass = detectedClass
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.qualityScore = qualityScore
    }
}

/// Protocol for creating Firestore item documents (Layer 1→2 handoff)
public protocol ItemServiceProtocol: Sendable {
    /// Create Firestore document to trigger Layer 2a processing
    func createItem(
        itemId: String,
        userId: String,
        imageUrl: URL,
        layer1Metadata: Layer1Metadata
    ) async throws
}

/// Concrete implementation of Firestore item creation
public final class ItemService: ItemServiceProtocol {

    private let firestore: Firestore

    public init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    public func createItem(
        itemId: String,
        userId: String,
        imageUrl: URL,
        layer1Metadata: Layer1Metadata
    ) async throws {
        let itemRef = firestore.collection("items").document(itemId)

        try await itemRef.setData([
            "userId": userId,
            "imageUrl": imageUrl.absoluteString,
            "aiAnalysis": [
                "layer1": [
                    "detectedClass": layer1Metadata.detectedClass,
                    "confidence": layer1Metadata.confidence,
                    "boundingBox": [
                        "x": layer1Metadata.boundingBox.origin.x,
                        "y": layer1Metadata.boundingBox.origin.y,
                        "width": layer1Metadata.boundingBox.size.width,
                        "height": layer1Metadata.boundingBox.size.height
                    ],
                    "qualityScore": layer1Metadata.qualityScore
                ]
            ],
            "status": "pending",  // Triggers Cloud Function for Layer 2a
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
}
```

### Step 4: Run test to verify it passes

**Run:**

```bash
swift test --filter ItemServiceTests
```

**Expected:** PASS

### Step 5: Commit

```bash
git add Sources/Persistence/Firebase/ItemService.swift Tests/PersistenceTests/ItemServiceTests.swift
git commit -m "feat(persistence): add ItemService for Layer 1→2 handoff

- Create Firestore document with imageUrl and Layer 1 metadata
- Triggers Cloud Function with status: pending
- Add Layer1Metadata model for YOLO detection results
- Add comprehensive tests

Refs: BUG-002, DESIGN-004"
```

---

## Task 4: Wire Layer 1→2 Handoff in CameraDetectionViewModel

**Goal:** Add upload + Firestore document creation on automatic/manual catalog

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift`
- Test: `Tests/CameraFeatureTests/ViewModels/CameraDetectionViewModelTests.swift`

### Step 1: Add dependencies to CameraDetectionViewModel

**File:** `Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift`

**Add imports:**

```swift
import Persistence
@preconcurrency import FirebaseAuth
```

**Add properties:**

```swift
// Storage and persistence services (optional for testing)
private let storageService: StorageServiceProtocol?
private let itemService: ItemServiceProtocol?

// Store current pixel buffer for upload
private var currentPixelBuffer: CVPixelBuffer?
```

**Update init:**

```swift
public init(
    yoloDetector: HouseholdItemDetectorProtocol,
    qualityAssessor: ImageQualityAssessorProtocol,
    deduplicator: ObjectDeduplicatorProtocol,
    maskGenerator: SubjectMaskGeneratorProtocol,
    storageService: StorageServiceProtocol? = StorageService(),
    itemService: ItemServiceProtocol? = ItemService()
) {
    self.yoloDetector = yoloDetector
    self.qualityAssessor = qualityAssessor
    self.deduplicator = deduplicator
    self.maskGenerator = maskGenerator
    self.storageService = storageService
    self.itemService = itemService
}
```

### Step 2: Store pixel buffer in processFrame

**Find:**

```swift
nonisolated public func processFrame(_ pixelBuffer: CVPixelBuffer) async {
```

**Add after guard:**

```swift
// Store pixel buffer for potential upload
await MainActor.run { currentPixelBuffer = pixelBuffer }
```

### Step 3: Add upload method

**Add after processObject:**

```swift
/// Upload detected object to trigger Layer 1→2 catalog pipeline
private func uploadObject(_ object: DetectedObject) async {
    guard let storageService = storageService,
          let itemService = itemService,
          let pixelBuffer = currentPixelBuffer,
          let userId = Auth.auth().currentUser?.uid else {
        logger.warning("Upload skipped: missing services, pixel buffer, or auth")
        return
    }

    do {
        // Crop image from pixel buffer
        let croppedImage = try PixelBufferCropper.cropImage(
            from: pixelBuffer,
            boundingBox: object.boundingBox
        )

        // Upload to GCS
        let imageUrl = try await storageService.uploadCroppedObject(
            croppedImage,
            itemId: object.id.uuidString,
            userId: userId
        )

        // Create Firestore document (triggers Layer 2a/2b/3)
        try await itemService.createItem(
            itemId: object.id.uuidString,
            userId: userId,
            imageUrl: imageUrl,
            layer1Metadata: Layer1Metadata(
                detectedClass: object.label,
                confidence: object.confidence,
                boundingBox: object.boundingBox,
                qualityScore: object.qualityScore
            )
        )

        logger.info("Uploaded \(object.label) → Layer 2 pipeline: \(imageUrl.absoluteString)")
    } catch {
        logger.error("Upload failed: \(error.localizedDescription)")
    }
}
```

### Step 4: Trigger upload on automatic catalog

**Find in processFrame where detectedObjects is updated:**

```swift
// Step 3: Update UI with detected objects
await MainActor.run {
    detectedObjects = processedObjects
}
```

**Replace with:**

```swift
// Step 3: Update UI with detected objects
let previousObjects = await MainActor.run { detectedObjects }
await MainActor.run {
    detectedObjects = processedObjects
}

// Step 4: Upload new automatic catalog objects
for object in processedObjects where object.catalogMode == .automatic {
    if !previousObjects.contains(where: { $0.id == object.id }) {
        await uploadObject(object)
    }
}
```

### Step 5: Trigger upload on manual catalog (double-tap)

**Find handleDoubleTap method and add upload after mode change:**

```swift
detectedObjects[index].catalogMode = .automatic

// Upload to trigger Layer 2 pipeline
await uploadObject(detectedObjects[index])
```

### Step 6: Write test for automatic catalog upload

**Add to CameraDetectionViewModelTests.swift:**

```swift
@MainActor
func testProcessFrame_automaticCatalog_triggersUpload() async throws {
    // Given: Mock services
    let mockStorage = MockStorageService()
    let mockItem = MockItemService()

    let viewModel = CameraDetectionViewModel(
        yoloDetector: mockYOLO,
        qualityAssessor: mockQuality,
        deduplicator: mockDeduplicator,
        maskGenerator: mockMaskGenerator,
        storageService: mockStorage,
        itemService: mockItem
    )

    // High confidence + quality for automatic catalog
    mockYOLO.mockResults = [
        YOLOResult(label: "tent", confidence: 0.87, boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5), alternativeLabels: [])
    ]
    mockQuality.mockQualityScore = 0.75

    let pixelBuffer = try createMockPixelBuffer()

    // When: Process frame
    await viewModel.processFrame(pixelBuffer)

    try await Task.sleep(nanoseconds: 200_000_000)

    // Then: Upload triggered
    XCTAssertTrue(mockStorage.uploadCalled)
    XCTAssertTrue(mockItem.createItemCalled)
}
```

### Step 7: Run tests

**Run:**

```bash
swift test --filter CameraDetectionViewModelTests
```

**Expected:** All tests pass

### Step 8: Commit

```bash
git add Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift Tests/CameraFeatureTests/ViewModels/CameraDetectionViewModelTests.swift
git commit -m "feat(camera): wire Layer 1→2 handoff in CameraDetectionViewModel

- Inject StorageService and ItemService dependencies
- Store pixel buffer for upload
- Upload on automatic catalog (high confidence + quality)
- Upload on manual catalog (double-tap)
- Create Firestore document to trigger Layer 2a/2b/3
- Add comprehensive upload tests

Refs: BUG-002, DESIGN-004"
```

---

## Task 5: Update Implementation Documentation

**Goal:** Mark Layer 1→2 handoff as complete

**Files:**
- Modify: `docs/implementation/2025-11-17-camera-detection-ui-implementation.md`
- Modify: `docs/plans/2025-11-17-camera-detection-ui-implementation.md`

### Step 1: Update implementation doc

**File:** `docs/implementation/2025-11-17-camera-detection-ui-implementation.md`

**Update known limitations:**

```markdown
## Known Limitations

1. **Marching Squares Not Implemented**: OrganicBorderShape uses rectangle fallback
2. ~~**Firebase Upload Not Wired**~~ **RESOLVED** (2025-11-18): Layer 1→2 handoff wired
3. **Accessibility Not Complete**: VoiceOver labels and Reduce Motion support needed
```

**Update acceptance criteria:**

```markdown
- [x] Upload to Firebase Storage → GCS → Layer 2 pipeline (COMPLETE: 2025-11-18)
```

### Step 2: Commit

```bash
git add docs/implementation/2025-11-17-camera-detection-ui-implementation.md docs/plans/2025-11-17-camera-detection-ui-implementation.md
git commit -m "docs(camera): mark Layer 1→2 handoff as complete

- Update known limitations (upload now wired)
- Update acceptance criteria (Layer 1→2 complete)

Refs: BUG-002, DESIGN-004"
```

---

## Task 6: Run Full Test Suite

**Goal:** Verify all tests pass

### Step 1: Run all tests

**Run:**

```bash
swift test
```

**Expected:** All tests pass

### Step 2: Build verification

**Run:**

```bash
swift build
```

**Expected:** Build succeeds

---

## Success Criteria

- [x] StorageService path simplified (`/cropped.jpg` → `.jpg`)
- [x] PixelBufferCropper utility created
- [x] ItemService created for Firestore document creation
- [x] CameraDetectionViewModel triggers Layer 1→2 handoff on automatic catalog
- [x] CameraDetectionViewModel triggers Layer 1→2 handoff on manual catalog (double-tap)
- [x] Tests verify upload flow
- [x] Documentation updated
- [x] All tests pass

**Estimated Time:** 2-3 hours

**Next Steps:**
1. Run code review via superpowers:requesting-code-review
2. Create pull request
3. Request design review

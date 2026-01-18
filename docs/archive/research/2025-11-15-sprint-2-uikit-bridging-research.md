# Sprint 2: UIKit Bridging Research for Camera & Vision

**Research Date**: 2025-11-15
**Purpose**: Validate UIKit bridging requirements for AVFoundation/Vision compliance with ADR-010
**Researcher**: Claude Code
**Status**: Validated

---

## Executive Summary

This research validates that **UIKit imports for AVFoundation and Vision Framework integration are acceptable under ADR-010's SwiftUI-only architecture**. UIViewRepresentable is an official SwiftUI protocol designed for bridging UIKit views, and both AVFoundation and Vision Framework provide UIKit-independent APIs for image processing.

**Key Finding**: UIKit usage is **PERMITTED** for framework bridging (UIViewRepresentable, UIImage data conversion) but **PROHIBITED** for UI architecture (UIViewController, UINavigationController, etc.).

---

## Research Questions

1. **Does AVCapturePhoto require UIImage for image data conversion?**
   - Answer: NO - Direct CGImage access via `cgImageRepresentation()`

2. **Does AVCaptureVideoPreviewLayer require UIViewRepresentable for SwiftUI integration?**
   - Answer: YES - AVCaptureVideoPreviewLayer is a CALayer subclass requiring UIView hosting

3. **Does Vision Framework's VNImageRequestHandler require UIImage input?**
   - Answer: NO - Accepts CGImage, CIImage, CVPixelBuffer, URL, or Data directly

4. **Is UIViewRepresentable considered a SwiftUI-native pattern?**
   - Answer: YES - It's an official SwiftUI protocol (part of SwiftUI framework)

5. **Are these UIKit imports acceptable under ADR-010's SwiftUI-only architecture?**
   - Answer: YES - Framework bridging is distinct from UI architecture

---

## Findings

### AVFoundation Requirements

#### AVCaptureVideoPreviewLayer Bridge

**Framework**: AVFoundation (UIKit component)
**SwiftUI Integration**: Requires UIViewRepresentable

**Implementation Pattern**:
```swift
import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update preview layer frame on size changes
        DispatchQueue.main.async {
            uiView.videoPreviewLayer.frame = uiView.bounds
        }
    }
}

// Custom UIView subclass with layerClass override
class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
```

**UIKit Dependencies**:
- `import UIKit` (required for UIView, UIViewRepresentable)
- `UIView` subclass (required for layerClass override)
- `UIViewRepresentable` protocol (SwiftUI framework, bridges UIKit)

**Justification**: AVCaptureVideoPreviewLayer is a CALayer subclass that requires a UIView container. There is no native SwiftUI equivalent as of iOS 18 (2025).

---

#### AVCapturePhoto Image Data Extraction

**Framework**: AVFoundation
**UIImage Required**: NO (but commonly used for convenience)

**Direct CGImage Access** (Recommended):
```swift
func photoOutput(_ output: AVCapturePhotoOutput,
                 didFinishProcessingPhoto photo: AVCapturePhoto,
                 error: Error?) {
    // Option 1: Direct CGImage (no UIImage needed)
    if let cgImageRepresentation = photo.cgImageRepresentation() {
        let cgImage = cgImageRepresentation.takeUnretainedValue()
        // Process CGImage directly with Vision Framework
        processImage(cgImage)
    }
}
```

**UIImage Conversion** (Optional):
```swift
func photoOutput(_ output: AVCapturePhotoOutput,
                 didFinishProcessingPhoto photo: AVCapturePhoto,
                 error: Error?) {
    // Option 2: UIImage conversion (for convenience)
    guard let photoData = photo.fileDataRepresentation() else { return }
    guard let image = UIImage(data: photoData) else { return }

    // Or with proper orientation handling:
    if let cgImageRep = photo.cgImageRepresentation(),
       let orientationInt = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
       let orientation = UIImage.Orientation.orientation(fromCGOrientationRaw: orientationInt) {
        let cgImage = cgImageRep.takeUnretainedValue()
        let image = UIImage(cgImage: cgImage, scale: 1, orientation: orientation)
    }
}
```

**UIKit Dependencies**:
- `import UIKit` (optional, only if using UIImage for convenience)
- `UIImage` (optional, for orientation handling or display)

**Justification**: AVCapturePhoto provides `cgImageRepresentation()` for direct CGImage access, eliminating UIImage dependency. UIImage is only needed for orientation metadata or SwiftUI Image display.

**API References** (Apple Developer Documentation):
- `cgImageRepresentation()`: Extracts and returns the captured photo's primary image as a Core Graphics image object
  - Docs: https://developer.apple.com/documentation/avfoundation/avcapturephoto/cgimagerepresentation()
- `fileDataRepresentation()`: Generates and returns a flat data representation of the photo and its attachments
  - Docs: https://developer.apple.com/documentation/avfoundation/avcapturephoto/2873919-filedatarepresentation

---

### Vision Framework Requirements

#### VNImageRequestHandler Input Types

**Framework**: Vision
**UIImage Required**: NO

**Supported Input Types**:
1. **CGImage** (Core Graphics)
2. **CIImage** (Core Image)
3. **CVPixelBuffer** (Core Video)
4. **URL** (file path)
5. **Data** (image bytes)

**Implementation Examples**:

```swift
import Vision

// Option 1: CGImage (from AVCapturePhoto)
func processWithCGImage(_ cgImage: CGImage) {
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    let request = VNDetectBarcodesRequest { request, error in
        guard let results = request.results as? [VNBarcodeObservation] else { return }
        // Process barcode results
    }
    try? handler.perform([request])
}

// Option 2: CVPixelBuffer (from camera stream)
func processWithPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
    try? handler.perform([barcodeRequest, objectDetectionRequest])
}

// Option 3: CIImage (from Core Image processing)
func processWithCIImage(_ ciImage: CIImage) {
    let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    try? handler.perform([request])
}

// Option 4: URL (from disk)
func processWithURL(_ imageURL: URL) {
    let handler = VNImageRequestHandler(url: imageURL, options: [:])
    try? handler.perform([request])
}
```

**UIImage Conversion** (Only if needed):
```swift
// If starting with UIImage, convert to CGImage
func processWithUIImage(_ image: UIImage) {
    guard let cgImage = image.cgImage else { return }
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? handler.perform([request])
}
```

**UIKit Dependencies**:
- `import UIKit` (NOT required for Vision Framework)
- `UIImage` (optional, only if converting from UIImage source)

**Justification**: Vision Framework is designed to work with Core Graphics (CGImage), Core Image (CIImage), and Core Video (CVPixelBuffer) directly. UIImage is only a convenience wrapper and not a requirement.

**Best Practices** (from Apple documentation and 2025 community resources):
- Use **CVPixelBuffer** for camera streams (best performance)
- Use **CGImage** for static images from AVCapturePhoto
- Use **URL** for images on disk (no need to pass EXIF orientation)
- **Do NOT pre-scale images** - Vision handles scaling automatically
- **Do pass EXIF orientation data** (except for URL-based images)

---

### UIViewRepresentable Pattern

#### Official Status

**Framework**: SwiftUI (part of SwiftUI module)
**Purpose**: Integrate UIKit views into SwiftUI view hierarchies
**Apple Documentation**: https://developer.apple.com/documentation/swiftui/uiviewrepresentable

**Protocol Definition** (Swift):
```swift
public protocol UIViewRepresentable : View where Self.Body == Never {
    associatedtype UIViewType : UIView

    func makeUIView(context: Self.Context) -> Self.UIViewType
    func updateUIView(_ uiView: Self.UIViewType, context: Self.Context)

    // Optional methods:
    static func dismantleUIView(_ uiView: Self.UIViewType, coordinator: Self.Coordinator)
    func makeCoordinator() -> Self.Coordinator

    typealias Context = UIViewRepresentableContext<Self>
}
```

**Required Methods**:
1. `makeUIView(context:)` - Creates and returns the UIView instance
2. `updateUIView(_:context:)` - Updates the UIView when SwiftUI state changes

**Optional Methods**:
1. `dismantleUIView(_:coordinator:)` - Cleans up the UIView when removed
2. `makeCoordinator()` - Creates a Coordinator for delegate pattern bridging

---

#### SwiftUI Integration Status

**Is UIViewRepresentable part of SwiftUI?**
- YES - It's a protocol defined in the SwiftUI framework
- Declared as: `@available(iOS 13.0, *)`
- Conforms to SwiftUI's `View` protocol

**Is it a "bridge" or "native" pattern?**
- BOTH - It's a **native SwiftUI protocol** designed for **bridging UIKit views**
- Analogy: It's like SwiftUI's "official embassy" in UIKit territory

**Apple's Intent** (from documentation and WWDC sessions):
- Designed for gradual SwiftUI migration
- Intended for UIKit components without SwiftUI equivalents
- Officially supported and recommended by Apple

**2025 Context**:
- Still the standard approach for camera preview (AVCaptureVideoPreviewLayer)
- Apple gradually adding native SwiftUI replacements (e.g., WebView in iOS 18.4)
- Expected to remain necessary for AVFoundation until Apple provides native SwiftUI camera APIs

---

#### Coordinator Pattern for Delegates

**Use Case**: When UIKit view uses delegation (e.g., UITextFieldDelegate, AVCapturePhotoCaptureDelegate)

**Implementation**:
```swift
struct CameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func photoOutput(_ output: AVCapturePhotoOutput,
                         didFinishProcessingPhoto photo: AVCapturePhoto,
                         error: Error?) {
            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else { return }
            parent.capturedImage = image
        }
    }
}
```

**UIKit Dependencies**:
- `import UIKit` (required for NSObject, delegate protocols)
- `NSObject` (required for Objective-C delegate conformance)

**Justification**: Coordinator bridges Swift/Objective-C delegate patterns between UIKit and SwiftUI.

---

## Conclusion

### Permitted UIKit Usage (ADR-010 Compliant)

The following UIKit imports are **APPROVED** for Sprint 2 camera and Vision Framework integration:

#### 1. UIViewRepresentable for Camera Preview
**File**: `Sources/Camera/CameraPreviewView.swift`
**Imports**:
```swift
import SwiftUI
import AVFoundation
import UIKit  // For UIView, UIViewRepresentable
```

**Justification**:
- UIViewRepresentable is a SwiftUI protocol (part of SwiftUI framework)
- AVCaptureVideoPreviewLayer has no SwiftUI-native equivalent (as of iOS 18/2025)
- This is framework bridging, not UI architecture

**ADR-010 Compliance**: PASS
- Not using UIKit for navigation (UINavigationController)
- Not using UIKit for view controllers (UIViewController)
- Using official SwiftUI bridging mechanism

---

#### 2. UIImage for Image Data Conversion (Optional)
**File**: `Sources/Camera/CameraViewModel.swift`
**Imports**:
```swift
import SwiftUI
import AVFoundation
import UIKit  // For UIImage (optional, can use CGImage instead)
```

**When UIImage is needed**:
- Converting AVCapturePhoto to SwiftUI's `Image` view
- Handling EXIF orientation metadata
- Interoperating with SwiftUI image APIs

**When UIImage is NOT needed**:
- Passing images to Vision Framework (use CGImage directly)
- Processing raw image data (use CVPixelBuffer or CGImage)

**Justification**:
- UIImage is a data model (like UIColor, UIFont) not a UI component
- SwiftUI's `Image` view accepts UIImage as input
- Alternative: Use CGImage and wrap in SwiftUI Image

**ADR-010 Compliance**: PASS
- Using UIImage as a data type, not a UI component
- Not building UI with UIImageView

---

#### 3. NSObject for Delegate Bridging (Coordinator)
**File**: `Sources/Camera/CameraView.swift`
**Imports**:
```swift
import SwiftUI
import AVFoundation
import UIKit  // For NSObject (Objective-C runtime)
```

**Use Case**: Coordinator conforming to AVCapturePhotoCaptureDelegate

**Justification**:
- NSObject is required for Objective-C delegate protocol conformance
- Coordinator pattern is standard UIViewRepresentable approach
- AVFoundation delegates use Objective-C runtime

**ADR-010 Compliance**: PASS
- Using NSObject for delegate conformance, not UI
- Coordinator is internal to UIViewRepresentable

---

### Prohibited UIKit Usage (ADR-010 Violations)

The following UIKit patterns are **PROHIBITED** and would violate ADR-010:

#### 1. UIViewController for Navigation
**Example (INVALID)**:
```swift
// ❌ PROHIBITED - Violates ADR-010
import UIKit

class CameraViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // ...
    }
}
```

**Why Prohibited**: Using UIViewController for app architecture violates SwiftUI-only pattern

**SwiftUI Alternative**: Use SwiftUI Views with NavigationStack
```swift
// ✅ APPROVED - SwiftUI pattern
import SwiftUI

struct CameraView: View {
    var body: some View {
        NavigationStack {
            CameraPreviewView()
                .navigationTitle("Camera")
        }
    }
}
```

---

#### 2. UINavigationController for Navigation
**Example (INVALID)**:
```swift
// ❌ PROHIBITED - Violates ADR-010
let navController = UINavigationController(rootViewController: cameraVC)
```

**Why Prohibited**: Using UIKit navigation system violates SwiftUI-only architecture

**SwiftUI Alternative**: Use NavigationStack, NavigationPath
```swift
// ✅ APPROVED - SwiftUI pattern
NavigationStack {
    CameraView()
        .navigationDestination(for: CatalogItem.self) { item in
            ItemDetailView(item: item)
        }
}
```

---

#### 3. UIImageView for Image Display
**Example (INVALID)**:
```swift
// ❌ PROHIBITED - Violates ADR-010
let imageView = UIImageView(image: capturedImage)
view.addSubview(imageView)
```

**Why Prohibited**: Using UIKit for UI components violates SwiftUI-only architecture

**SwiftUI Alternative**: Use SwiftUI's Image view
```swift
// ✅ APPROVED - SwiftUI pattern
import SwiftUI

struct PhotoPreview: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
    }
}
```

---

#### 4. UIButton, UILabel, UITextField (UI Components)
**Example (INVALID)**:
```swift
// ❌ PROHIBITED - Violates ADR-010
let button = UIButton(type: .system)
button.setTitle("Capture", for: .normal)
```

**Why Prohibited**: Using UIKit for UI components violates SwiftUI-only architecture

**SwiftUI Alternative**: Use SwiftUI native components
```swift
// ✅ APPROVED - SwiftUI pattern
Button("Capture") {
    capturePhoto()
}
.buttonStyle(.borderedProminent)
```

---

## ADR-010 Compliance

### Final Verdict: COMPLIANT

**UIKit bridging for AVFoundation and Vision Framework is acceptable under ADR-010's SwiftUI-only architecture.**

---

### Compliance Breakdown

| Component | UIKit Import | Permitted? | Reason |
|-----------|--------------|------------|--------|
| AVCaptureVideoPreviewLayer | YES | ✅ APPROVED | No SwiftUI equivalent, requires UIViewRepresentable |
| UIViewRepresentable | YES | ✅ APPROVED | Official SwiftUI protocol for bridging |
| AVCapturePhoto → CGImage | NO | ✅ APPROVED | Direct CGImage access, no UIKit needed |
| AVCapturePhoto → UIImage | YES | ✅ APPROVED | Optional convenience, data model not UI |
| VNImageRequestHandler | NO | ✅ APPROVED | Accepts CGImage/CVPixelBuffer directly |
| Coordinator (NSObject) | YES | ✅ APPROVED | Required for Objective-C delegate conformance |
| UIViewController | YES | ❌ PROHIBITED | Violates SwiftUI-only UI architecture |
| UINavigationController | YES | ❌ PROHIBITED | Violates SwiftUI-only navigation |
| UIImageView | YES | ❌ PROHIBITED | Violates SwiftUI-only UI components |

---

### ADR-010 Interpretation

**"SwiftUI-only" means**:
- ✅ SwiftUI for ALL UI components (View, Button, List, NavigationStack)
- ✅ SwiftUI for navigation architecture (NavigationStack, NavigationPath)
- ✅ SwiftUI for layout (VStack, HStack, ZStack, Grid)
- ✅ UIKit imports allowed for **framework bridging** (UIViewRepresentable)
- ✅ UIKit imports allowed for **data models** (UIImage, UIColor, UIFont)
- ❌ UIKit prohibited for **UI architecture** (UIViewController, UINavigationController)

**Framework Bridging vs UI Architecture**:
- **Framework Bridging** (Permitted): Using UIViewRepresentable to integrate UIKit-only frameworks (AVFoundation, MapKit, WebKit pre-iOS 18)
- **UI Architecture** (Prohibited): Using UIViewController, UINavigationController, UITableView for app structure

---

### P0/P1/P2 Classification (from ADR-010)

Based on ADR-010's enforcement tiers:

**P0 (Blocks PR Merge)**:
- ❌ Using UIViewController for app screens
- ❌ Using UINavigationController for navigation
- ❌ Using UIKit UI components (UIButton, UILabel, UIImageView)

**P1 (Requires Justification)**:
- ⚠️ Using UIViewRepresentable without checking for SwiftUI alternatives
  - Justification: AVCaptureVideoPreviewLayer has no SwiftUI equivalent (verified 2025)

**P2 (Warning Only)**:
- ⚠️ Using UIImage when CGImage would suffice
  - Justification: SwiftUI's `Image` view accepts UIImage directly

**Sprint 2 Status**: All UIKit usage falls under P1 (justified) or P2 (acceptable)

---

## Implementation Recommendations

### 1. Minimize UIKit Surface Area

**Recommended Architecture**:
```
CameraViewModel.swift          (Pure Swift, no UIKit)
    ↓
CameraView.swift              (SwiftUI View)
    ↓
CameraPreviewView.swift       (UIViewRepresentable bridge)
    ↓
CameraPreviewUIView.swift     (UIKit, minimal scope)
```

**Goal**: Isolate UIKit imports to smallest possible scope (CameraPreviewView only)

---

### 2. Prefer CGImage Over UIImage

**Image Processing Pipeline**:
```
AVCapturePhoto
    → cgImageRepresentation()
    → CGImage
    → VNImageRequestHandler
    → Vision Framework Results
```

**Only use UIImage when**:
- Displaying in SwiftUI's `Image` view
- Handling EXIF orientation metadata
- Saving to photo library (PHAsset)

---

### 3. Document UIKit Usage

**Comment Template**:
```swift
// MARK: - UIKit Bridge (ADR-010 Compliant)
// Justification: AVCaptureVideoPreviewLayer requires UIView container
// No SwiftUI equivalent as of iOS 18 (verified 2025-11-15)
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    // ...
}
```

---

### 4. Plan for Future Migration

**SwiftUI Evolution Watchlist**:
- Monitor WWDC for native SwiftUI camera APIs
- Track iOS release notes for AVFoundation SwiftUI wrappers
- Apple precedent: Added native WebView in iOS 18.4 (replacing UIViewRepresentable)

**Migration Path**:
When Apple releases native SwiftUI camera APIs:
1. Create feature flag: `useNativeSwiftUICamera`
2. Implement side-by-side (old and new)
3. A/B test for regressions
4. Deprecate UIViewRepresentable implementation
5. Remove UIKit imports

---

## References

### Apple Documentation
- UIViewRepresentable: https://developer.apple.com/documentation/swiftui/uiviewrepresentable
- AVCapturePhoto: https://developer.apple.com/documentation/avfoundation/avcapturephoto
- AVCapturePhoto.cgImageRepresentation(): https://developer.apple.com/documentation/avfoundation/avcapturephoto/cgimagerepresentation()
- AVCapturePhoto.fileDataRepresentation(): https://developer.apple.com/documentation/avfoundation/avcapturephoto/2873919-filedatarepresentation
- Vision Framework: https://developer.apple.com/documentation/vision

### Repository Documents
- ADR-010 SwiftUI Architecture Pattern: docs/adr/ADR-010-swiftui-architecture-pattern.md
- Sprint 2 Camera/Vision Backend Plan: docs/plans/2025-11-15-sprint-2-camera-vision-backend.md
- CLAUDE.md Quick Reference: /Users/w/code/abundance-mvp/CLAUDE.md

### Community Resources (2025)
- "Integrating Device Camera in SwiftUI Apps" - createwithswift.com
- "Live camera feed in SwiftUI with AVCaptureVideoPreview layer" - neuralception.com
- "UIViewRepresentable explained to host UIView instances in SwiftUI" - avanderlee.com
- Stack Overflow: AVCaptureVideoPreviewLayer SwiftUI integration (multiple threads)

---

## Appendix: Code Examples

### Minimal Camera Implementation (ADR-010 Compliant)

**File Structure**:
```
Sources/Camera/
├── CameraViewModel.swift           (Pure Swift, no UIKit)
├── CameraView.swift                (SwiftUI, minimal UIKit)
├── CameraPreviewView.swift         (UIViewRepresentable)
└── CameraPreviewUIView.swift       (UIKit, isolated)
```

**CameraViewModel.swift** (No UIKit):
```swift
import Foundation
import AVFoundation
import Vision

@MainActor
class CameraViewModel: ObservableObject {
    @Published var capturedImage: CGImage?
    @Published var detectedBarcodes: [VNBarcodeObservation] = []
    @Published var error: Error?

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    func setupCamera() async throws {
        captureSession.beginConfiguration()

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            throw CameraError.deviceUnavailable
        }

        captureSession.addInput(input)
        captureSession.addOutput(photoOutput)
        captureSession.commitConfiguration()

        captureSession.startRunning()
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func processImage(_ cgImage: CGImage) {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let results = request.results as? [VNBarcodeObservation] else { return }
            Task { @MainActor in
                self?.detectedBarcodes = results
            }
        }
        try? handler.perform([request])
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        // Direct CGImage access (no UIImage needed)
        guard let cgImageRep = photo.cgImageRepresentation() else { return }
        let cgImage = cgImageRep.takeUnretainedValue()

        Task { @MainActor in
            self.capturedImage = cgImage
            processImage(cgImage)
        }
    }
}

enum CameraError: Error {
    case deviceUnavailable
}
```

**CameraView.swift** (SwiftUI):
```swift
import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview (UIViewRepresentable)
                CameraPreviewView(session: viewModel.captureSession)
                    .ignoresSafeArea()

                // SwiftUI controls overlay
                VStack {
                    Spacer()

                    Button {
                        viewModel.capturePhoto()
                    } label: {
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                                    .frame(width: 80, height: 80)
                            }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Camera")
            .task {
                try? await viewModel.setupCamera()
            }
        }
    }
}
```

**CameraPreviewView.swift** (UIViewRepresentable):
```swift
import SwiftUI
import AVFoundation
import UIKit  // ADR-010 Compliant: UIViewRepresentable bridge

// MARK: - UIKit Bridge (ADR-010 Compliant)
// Justification: AVCaptureVideoPreviewLayer requires UIView container
// No SwiftUI equivalent as of iOS 18 (verified 2025-11-15)

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update frame on size changes
        DispatchQueue.main.async {
            uiView.videoPreviewLayer.frame = uiView.bounds
        }
    }
}
```

**CameraPreviewUIView.swift** (UIKit, isolated):
```swift
import UIKit
import AVFoundation

// MARK: - UIKit Component (Isolated)
// Minimal UIKit surface area for AVCaptureVideoPreviewLayer

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds
    }
}
```

**Import Summary**:
- CameraViewModel.swift: NO UIKit import (pure Swift)
- CameraView.swift: NO UIKit import (pure SwiftUI)
- CameraPreviewView.swift: UIKit import (UIViewRepresentable only)
- CameraPreviewUIView.swift: UIKit import (isolated UIView subclass)

**ADR-010 Compliance**: PASS
- Total UIKit surface area: 2 files (CameraPreviewView, CameraPreviewUIView)
- All UI components: SwiftUI (Button, Circle, VStack, ZStack, NavigationStack)
- All navigation: SwiftUI (NavigationStack)
- UIKit usage: Framework bridging only (UIViewRepresentable)

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-15 | 1.0 | Initial research validation | Claude Code |

---

**Status**: Validated
**ADR-010 Compliance**: PASS (UIKit bridging permitted for framework integration)
**Next Steps**: Implement camera feature following validated patterns (Sprint 2)

# Common Apple Documentation Lookups

Pre-defined paths to frequently used Apple Developer documentation.

## Swift Language

| API/Concept | Search Query | Direct Path |
|-------------|--------------|-------------|
| Swift Concurrency | "Swift concurrency" | `/documentation/swift/concurrency` |
| async/await | "Swift async await" | `/documentation/swift/asyncawait` |
| Actor | "Swift actor" | `/documentation/swift/actor` |
| MainActor | "Swift MainActor" | `/documentation/swift/mainactor` |
| Sendable | "Swift Sendable" | `/documentation/swift/sendable` |
| Task | "Swift Task" | `/documentation/swift/task` |
| Continuation | "Swift continuation" | `/documentation/swift/checkedcontinuation` |
| Observable macro | "@Observable Swift" | `/documentation/observation/observable()` |
| Result type | "Swift Result" | `/documentation/swift/result` |
| Error handling | "Swift error handling" | `/documentation/swift/error` |

## SwiftUI

| API/Concept | Search Query | Direct Path |
|-------------|--------------|-------------|
| View protocol | "SwiftUI View" | `/documentation/swiftui/view` |
| State | "SwiftUI State" | `/documentation/swiftui/state` |
| Binding | "SwiftUI Binding" | `/documentation/swiftui/binding` |
| StateObject | "SwiftUI StateObject" | `/documentation/swiftui/stateobject` |
| Observable | "SwiftUI Observable" | `/documentation/swiftui/observable` |
| NavigationStack | "SwiftUI NavigationStack" | `/documentation/swiftui/navigationstack` |
| NavigationSplitView | "SwiftUI NavigationSplitView" | `/documentation/swiftui/navigationsplitview` |
| List | "SwiftUI List" | `/documentation/swiftui/list` |
| LazyVGrid | "SwiftUI LazyVGrid" | `/documentation/swiftui/lazyvgrid` |
| GeometryReader | "SwiftUI GeometryReader" | `/documentation/swiftui/geometryreader` |
| containerRelativeFrame | "containerRelativeFrame" | `/documentation/swiftui/view/containerrelativeframe(_:alignment:)` |
| phaseAnimator | "phaseAnimator" | `/documentation/swiftui/view/phaseanimator(_:content:animation:)` |
| scrollTargetBehavior | "scrollTargetBehavior" | `/documentation/swiftui/view/scrolltargetbehavior(_:)` |
| Material | "SwiftUI Material" | `/documentation/swiftui/material` |

## AVFoundation (Camera/Video)

| API/Concept | Search Query | Direct Path |
|-------------|--------------|-------------|
| AVCaptureSession | "AVCaptureSession" | `/documentation/avfoundation/avcapturesession` |
| AVCaptureDevice | "AVCaptureDevice" | `/documentation/avfoundation/avcapturedevice` |
| AVCaptureVideoDataOutput | "AVCaptureVideoDataOutput" | `/documentation/avfoundation/avcapturevideodataoutput` |
| AVCapturePhotoOutput | "AVCapturePhotoOutput" | `/documentation/avfoundation/avcapturephotooutput` |
| CMSampleBuffer | "CMSampleBuffer" | `/documentation/coremedia/cmsamplebuffer` |
| CVPixelBuffer | "CVPixelBuffer" | `/documentation/corevideo/cvpixelbuffer` |

## Vision Framework

| API/Concept | Search Query | Direct Path |
|-------------|--------------|-------------|
| VNCoreMLRequest | "VNCoreMLRequest" | `/documentation/vision/vncoremlrequest` |
| VNCoreMLModel | "VNCoreMLModel" | `/documentation/vision/vncoremlmodel` |
| VNRecognizeTextRequest | "VNRecognizeTextRequest" | `/documentation/vision/vnrecognizetextrequest` |
| VNDetectBarcodesRequest | "VNDetectBarcodesRequest" | `/documentation/vision/vndetectbarcodesrequest` |
| VNImageRequestHandler | "VNImageRequestHandler" | `/documentation/vision/vnimagerequesthandler` |
| VNObservation | "VNObservation" | `/documentation/vision/vnobservation` |

## CoreML

| API/Concept | Search Query | Direct Path |
|-------------|--------------|-------------|
| MLModel | "MLModel" | `/documentation/coreml/mlmodel` |
| MLModelConfiguration | "MLModelConfiguration" | `/documentation/coreml/mlmodelconfiguration` |
| MLFeatureProvider | "MLFeatureProvider" | `/documentation/coreml/mlfeatureprovider` |

## LocalAuthentication

| API/Concept | Search Query | Direct Path |
|-------------|--------------|-------------|
| LAContext | "LAContext" | `/documentation/localauthentication/lacontext` |
| biometricType | "LAContext biometricType" | `/documentation/localauthentication/lacontext/biometrytype-swift.property` |
| evaluatePolicy | "LAContext evaluatePolicy" | `/documentation/localauthentication/lacontext/evaluatepolicy(_:localizedreason:reply:)` |

## SwiftData

| API/Concept | Search Query | Direct Path |
|-------------|--------------|-------------|
| SwiftData | "SwiftData" | `/documentation/swiftdata` |
| Model macro | "SwiftData @Model" | `/documentation/swiftdata/model()` |
| ModelContext | "SwiftData ModelContext" | `/documentation/swiftdata/modelcontext` |
| ModelContainer | "SwiftData ModelContainer" | `/documentation/swiftdata/modelcontainer` |
| Query macro | "SwiftData @Query" | `/documentation/swiftdata/query` |
| PersistentModel | "SwiftData PersistentModel" | `/documentation/swiftdata/persistentmodel` |

## Human Interface Guidelines

| Topic | Search Query | Direct Path |
|-------|--------------|-------------|
| Color | "HIG color" | `/design/human-interface-guidelines/foundations/color` |
| Typography | "HIG typography" | `/design/human-interface-guidelines/foundations/typography` |
| Layout | "HIG layout" | `/design/human-interface-guidelines/foundations/layout` |
| Icons | "HIG icons" | `/design/human-interface-guidelines/foundations/icons` |
| Materials | "HIG materials" | `/design/human-interface-guidelines/foundations/materials` |
| Motion | "HIG motion" | `/design/human-interface-guidelines/foundations/motion` |
| Accessibility | "HIG accessibility" | `/design/human-interface-guidelines/foundations/accessibility` |

## XCTest

| API/Concept | Search Query | Direct Path |
|-------------|--------------|-------------|
| XCTestCase | "XCTestCase" | `/documentation/xctest/xctestcase` |
| XCUIApplication | "XCUIApplication" | `/documentation/xctest/xcuiapplication` |
| XCUIElement | "XCUIElement" | `/documentation/xctest/xcuielement` |
| XCTAssert | "XCTAssert" | `/documentation/xctest/xctassert(_:_:file:line:)` |
| XCTestExpectation | "XCTestExpectation" | `/documentation/xctest/xctestexpectation` |

---

## Usage Examples

### Quick Lookup (Search)

```
mcp__sosumi__searchAppleDocumentation(query="AVCaptureSession")
```

### Direct Fetch (Known Path)

```
mcp__sosumi__fetchAppleDocumentation(path="/documentation/avfoundation/avcapturesession")
```

### Batch Lookup Strategy

For multiple related APIs, prioritize:

1. Framework overview first (e.g., `/documentation/vision`)
2. Specific classes second (e.g., `VNCoreMLRequest`)
3. Methods/properties only if needed

This minimizes token usage while providing sufficient context.

---

## Notes

- Paths are case-sensitive
- HIG paths start with `/design/`
- API paths start with `/documentation/`
- Search is fuzzy-matched, direct paths must be exact
- Some APIs have multiple documentation versions (prefer latest)

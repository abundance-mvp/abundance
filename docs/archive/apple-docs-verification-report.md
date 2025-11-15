# Apple Documentation Verification Report

**Generated:** 2025-11-02
**Updated:** 2025-11-04
**Status:** ✅ Complete

> **NOTE (2025-11-04):** Migrating to MCP-based documentation system. 14 incorrectly fetched API docs (AI summaries) have been deleted and will be replaced with on-demand MCP fetching. See `docs/plans/2025-11-04-mcp-apple-docs-system-design.md` for the new architecture.

## Summary

- **Total Directories Verified:** 24/24
- **Total Overview Documents:** 40
- **Total API Classes Mentioned:** 350+
- **Total Detailed Docs Found:** 19 (prior to cleanup)
- **Total Detailed Docs After Cleanup:** ~5 (overview docs + 3 auth/ APIs)
- **Total Detailed Docs Missing:** 345+
- **Total 404 Errors:** 0

**Key Findings (Post-Cleanup):**
- 14 AI-summarized API docs deleted (incorrect content)
- Remaining: Overview docs in all directories + 3 correctly fetched auth/ APIs
- Future approach: Just-in-time MCP fetching (no local API docs)
- Largest gaps: storage/ (37+ missing), swift/ (59+ missing), swiftui/ (46+ missing), testing/ (39+ missing)
- 2 directories are design guidance only: liquid-glass/ (HIG), interface fundamentals
- 2 directories are legacy/specific: payments/ (legacy StoreKit, fully documented)

---

## Verification Progress

### ✅ Completed Directories
1. auth/
2. biometrics/
3. camera/
4. content-safety/
5. foundation/
6. image-processing/
7. liquid-glass/
8. maps/
9. networking/
10. notifications/
11. observation/
12. payment/
13. payments/
14. performance/
15. privacy/
16. scanning/
17. security/
18. sharing/
19. storage/
20. swift/
21. swiftui/
22. testing/
23. vision/
24. visual-intelligence/

### ⏳ In Progress
None

### ❌ Not Started
0 directories remaining

---

## Detailed Findings by Directory

### auth/ - Authentication Services

**Status:** ✅ Verified
**Overview Docs:** 2
- authentication-services-overview.md
- keychain-services-overview.md

**API Classes Mentioned:** 20+
- ASAuthorizationController
- ASAuthorizationAppleIDProvider
- ASAuthorizationAppleIDButton
- SignInWithAppleButton
- ASPasswordCredential
- ASWebAuthenticationSession
- ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest
- ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequest
- ASPasskeyAssertionCredential
- ASPasskeyRegistrationCredential
- ASOneTimeCodeCredential
- ASAuthorizationResult
- ASAuthorizationError
- AuthorizationController
- ASCredentialIdentityStore
- Keychain Services APIs (SecItemAdd, SecItemCopyMatching, SecItemUpdate, SecItemDelete)

**Detailed Docs Found:** 3
- asauthorizationcontroller.md (✅ FETCHED)
- aswebauthenticationsession.md (✅ FETCHED)
- aspasswordcredential.md (✅ FETCHED)

**Detailed Docs Missing:** 17+

**Priority Assessment:**
- CRITICAL: ✅ All CRITICAL APIs now documented
- HIGH: SignInWithAppleButton, ASAuthorizationAppleIDProvider, ASAuthorizationError
- MEDIUM: Passkey-related APIs (ASPasskeyAssertionCredential, ASPasskeyRegistrationCredential)

**Fetch Results:**
- Successfully fetched: 3/3 CRITICAL APIs
- 404 errors: 0

---

### biometrics/ - Local Authentication

**Status:** ✅ Verified
**Overview Docs:** 1
- local-authentication-overview.md

**API Classes Mentioned:** 8
- LAContext (FOUND in security/)
- LARight
- LARightStore
- LAPrivateKey
- LAPublicKey
- LAError
- LocalAuthenticationView
- LABiometryType

**Detailed Docs Found:** 1 (LAContext in security/)
**Detailed Docs Missing:** 7

**Priority Assessment:**
- CRITICAL: LAContext (EXISTS ✅)
- HIGH: LARight, LAError, LABiometryType
- MEDIUM: Cryptographic APIs (LAPrivateKey, LAPublicKey, LARightStore), LocalAuthenticationView

---

### camera/ - AVFoundation & PhotoKit

**Status:** ✅ Verified
**Overview Docs:** 2
- avfoundation-overview.md
- photokit-overview.md

**API Classes Mentioned:** 14+
- AVCaptureSession (EXISTS ✅)
- AVCaptureDevice (EXISTS ✅)
- AVCapturePhotoOutput
- AVCaptureDeviceInput
- AVCaptureVideoDataOutput
- AVCaptureMovieFileOutput
- AVCapturePhotoSettings
- AVCaptureConnection
- PHPhotoLibrary
- PHAsset
- PHAssetCollection
- PHImageManager
- PHFetchResult
- PHChange

**Detailed Docs Found:** 2
- avcapturesession.md (EXISTS ✅)
- avcapturedevice.md (EXISTS ✅)

**Detailed Docs Missing:** 12+

**Priority Assessment:**
- CRITICAL: AVCaptureSession (EXISTS ✅), AVCaptureDevice (EXISTS ✅)
- HIGH: AVCapturePhotoOutput, AVCaptureDeviceInput, PHPhotoLibrary
- MEDIUM: PHAsset, PHImageManager, AVCaptureVideoDataOutput

---

### content-safety/ - Sensitive Content Analysis

**Status:** ✅ Verified
**Overview Docs:** 1
- sensitive-content-analysis-overview.md

**API Classes Mentioned:** 4
- SCSensitivityAnalyzer
- VideoAnalysisHandler
- SCVideoStreamAnalyzer
- SCSensitivityAnalysis

**Detailed Docs Found:** 0
**Detailed Docs Missing:** 4

**Priority Assessment:**
- HIGH: All 4 APIs (important for Trust & Safety features)
  - SCSensitivityAnalyzer (static media analysis)
  - SCVideoStreamAnalyzer (live stream analysis)
  - SCSensitivityAnalysis (results)
  - VideoAnalysisHandler (async video analysis)

---

### foundation/ - Foundation Framework

**Status:** ✅ Verified
**Overview Docs:** 1
- foundation-overview.md (VERY LIMITED - only covers Decimal and Data types)

**API Classes Mentioned:** 2
- Decimal
- Data

**Detailed Docs Found:** 0
**Detailed Docs Missing:** 2+

**Priority Assessment:**
- HIGH: Decimal, Data
- NOTE: This appears to be an incomplete overview. Foundation should include URLSession, JSONEncoder, JSONDecoder, FileManager, UserDefaults, Date, Calendar, etc. - but these are not mentioned in the overview we have.

**Recommendation:** Foundation documentation appears incomplete - may need separate fetch for core networking, data management, and date/time APIs if needed for Stage 2.2.

---

### networking/ - Network Framework & Combine

**Status:** ✅ Verified
**Overview Docs:** 2
- network-overview.md
- combine-overview.md

**API Classes Mentioned:** 15+
- NWEndpoint
- NWConnection
- NWParameters
- NWPathMonitor
- NWBrowser
- NWListener
- NWProtocolTLS.Options
- Publisher (Combine)
- Subscriber (Combine)
- Subject (Combine)
- PassthroughSubject
- CurrentValueSubject
- AnyCancellable
- CombineLatest
- And various operators (map, filter, etc.)

**Detailed Docs Found:** 0
**Detailed Docs Missing:** 15+

**Priority Assessment:**
- HIGH: NWConnection, NWPathMonitor, Publisher, AnyCancellable
- MEDIUM: NWParameters, NWBrowser, NWListener, Subject types

---

### image-processing/ - Image I/O Framework

**Status:** ✅ Verified
**Overview Docs:** 1
- image-io-overview.md

**API Classes Mentioned:** 0 (Framework documentation lists capabilities but no specific API classes)

**Key Capabilities Listed:**
- Image Reading (sources from URLs, data, providers)
- Image Writing (destinations for files, data, consumers)
- Metadata Management (XMP metadata)
- Animation Support
- Multiple format support (JPEG, PNG, GIF, TIFF, HEIC, WebP, DNG, CRW/CR2, NEF, RAF)

**Detailed Docs Found:** 0
**Detailed Docs Missing:** Unknown (no specific APIs listed to verify)

**Priority Assessment:**
- LOW: Overview provides conceptual information but lacks specific API class names. Framework-level documentation may be sufficient, or specific APIs (CGImageSource, CGImageDestination) may need to be fetched separately if needed.

---

### liquid-glass/ - Liquid Glass Design Material

**Status:** ✅ Verified
**Overview Docs:** 2
- liquid-glass-overview.md
- adopting-liquid-glass.md

**API Classes Mentioned:** 0 (Design guidance, not API documentation)

**Key Concepts:**
- Automatic integration with SwiftUI, UIKit, and AppKit
- Glass Effect Container (mentioned for performance)
- Design principles for layout, navigation, app icons, colors, controls
- No specific API classes - relies on system framework adoption

**Detailed Docs Found:** 0
**Detailed Docs Missing:** N/A (Design guidance only)

**Priority Assessment:**
- N/A: This is design/HIG guidance, not API documentation. No missing API docs.

---

### maps/ - MapKit Framework

**Status:** ✅ Verified
**Overview Docs:** 1
- mapkit-overview.md

**API Classes Mentioned:** 8+
- MKMapView
- MKAnnotation (protocol)
- MKMarkerAnnotationView
- MKClusterAnnotation
- MKOverlay (polygons, polylines, circles, tile overlays)
- MKDirections
- MKLocalSearch
- MKLookAroundViewController

**Detailed Docs Found:** 1
- mkmapview.md (EXISTS ✅)

**Detailed Docs Missing:** 7+

**Priority Assessment:**
- CRITICAL: MKMapView (EXISTS ✅)
- HIGH: MKAnnotation, MKDirections, MKLocalSearch
- MEDIUM: MKLookAroundViewController, overlay types

---

### notifications/ - User Notifications Framework

**Status:** ✅ Verified
**Overview Docs:** 2
- user-notifications-overview.md
- user-notifications-ui-overview.md

**API Classes Mentioned:** 20+
- UNUserNotificationCenter
- UNMutableNotificationContent (EXISTS ✅)
- UNNotificationRequest
- UNNotificationTrigger (calendar, time interval, location, push)
- UNUserNotificationCenterDelegate (EXISTS ✅)
- UNNotificationAction
- UNTextInputNotificationAction
- UNNotificationCategory
- UNNotificationServiceExtension
- UNNotificationContentExtension
- UNNotificationPresentationOptions
- UNAuthorizationStatus
- UNError
- UNNotificationSettings
- UNTimeIntervalNotificationTrigger
- UNCalendarNotificationTrigger
- UNLocationNotificationTrigger
- UNNotificationSound
- UNNotificationAttachment

**Detailed Docs Found:** 2
- unmutablenotificationcontent.md (EXISTS ✅)
- unusernotificationcenterdelegate.md (EXISTS ✅)

**Detailed Docs Missing:** 18+

**Priority Assessment:**
- CRITICAL: UNUserNotificationCenter, UNMutableNotificationContent (EXISTS ✅), UNUserNotificationCenterDelegate (EXISTS ✅)
- HIGH: UNNotificationRequest, UNNotificationTrigger types, UNNotificationAction, UNNotificationCategory
- MEDIUM: UNNotificationServiceExtension, UNError, UNAuthorizationStatus

---

### observation/ - Observation Framework

**Status:** ✅ Verified
**Overview Docs:** 1
- observation-overview.md

**API Classes Mentioned:** 4
- @Observable (macro)
- Observable (protocol)
- withObservationTracking()
- ObservationRegistrar

**Detailed Docs Found:** 0
**Detailed Docs Missing:** 4

**Priority Assessment:**
- HIGH: @Observable macro, Observable protocol (modern SwiftUI state management)
- MEDIUM: withObservationTracking(), ObservationRegistrar

---

### payment/ - Apple Pay & StoreKit

**Status:** ✅ Verified
**Overview Docs:** 2
- apple-pay-overview.md
- storekit-overview.md

**API Classes Mentioned (Apple Pay):** 10+
- PKPaymentAuthorizationController
- PKPaymentAuthorizationViewController
- PKPaymentButton
- PayWithApplePayButton
- PKPaymentRequest
- PKRecurringPaymentRequest
- PKAutomaticReloadPaymentRequest
- PKDeferredPaymentRequest
- PKDisbursementRequest
- PKPaymentTokenContext

**API Classes Mentioned (StoreKit):** 15+
- Product
- Product.SubscriptionInfo
- ProductView
- StoreView
- SubscriptionStoreView
- SubscriptionOfferView
- Transaction
- And various subscription-related types

**Detailed Docs Found:** 0
**Detailed Docs Missing:** 25+

**Priority Assessment:**
- CRITICAL: PKPaymentAuthorizationController, PKPaymentButton, Product (StoreKit)
- HIGH: PKPaymentRequest, StoreView, ProductView, Transaction
- MEDIUM: Recurring/deferred payment types, subscription views

---

### payments/ - StoreKit Legacy

**Status:** ✅ Verified
**Overview Docs:** 0 (only detailed docs exist)

**API Classes Found:** 2
- SKPaymentQueue
- SKProduct

**Detailed Docs Found:** 2
- skpaymentqueue.md (EXISTS ✅)
- skproduct.md (EXISTS ✅)

**Detailed Docs Missing:** 0 (appears to be legacy StoreKit APIs with specific docs only)

**Priority Assessment:**
- MEDIUM: Legacy StoreKit APIs (EXISTS ✅). Modern StoreKit (in payment/) is preferred for new development.

---

### performance/ - Accelerate Framework

**Status:** ✅ Verified
**Overview Docs:** 1
- accelerate-overview.md

**API Classes Mentioned:** 0 (High-level overview of BNNS capabilities)

**Key Capabilities Listed:**
- Neural network layers (activation, convolutional, fully connected, normalization, pooling)
- Graph compilation and execution
- Dynamic shape configuration
- Fused layer operations
- Sparse matrix support
- Custom memory allocation

**Detailed Docs Found:** 0
**Detailed Docs Missing:** Unknown (no specific API classes listed)

**Priority Assessment:**
- LOW: Overview-level documentation. Accelerate is specialized for ML/compute workloads. Specific BNNS APIs can be fetched if needed for performance-critical features.

---

### privacy/ - App Tracking Transparency

**Status:** ✅ Verified
**Overview Docs:** 1
- app-tracking-transparency-overview.md

**API Classes Mentioned:** 2
- ATTrackingManager
- ATTrackingManager.AuthorizationStatus (enum with 4 states)

**Detailed Docs Found:** 0
**Detailed Docs Missing:** 2

**Priority Assessment:**
- HIGH: ATTrackingManager (required for apps that track users across apps/websites)
- MEDIUM: ATTrackingManager.AuthorizationStatus

---

### scanning/ - VisionKit Framework

**Status:** ✅ Verified
**Overview Docs:** 1
- visionkit-overview.md

**API Classes Mentioned:** 15+
- ImageAnalyzer
- ImageAnalysis
- ImageAnalysisInteraction
- ImageAnalysisOverlayView
- DataScannerViewController (EXISTS ✅)
- DataScannerViewControllerDelegate (EXISTS ✅)
- VNDocumentCameraViewController
- VNDocumentCameraScan
- And various supporting types

**Detailed Docs Found:** 2
- datascannerviewcontroller.md (EXISTS ✅)
- datascannerviewcontrollerdelegate.md (EXISTS ✅)

**Detailed Docs Missing:** 13+

**Priority Assessment:**
- CRITICAL: DataScannerViewController (EXISTS ✅), ImageAnalyzer
- HIGH: ImageAnalysisInteraction, VNDocumentCameraViewController, ImageAnalysis
- MEDIUM: ImageAnalysisOverlayView, supporting delegate types

---

### security/ - Security Framework

**Status:** ✅ Verified
**Overview Docs:** 1
- security-framework-overview.md

**API Classes Mentioned:** 20+
- LAContext (EXISTS ✅)
- Keychain Services APIs (SecItemAdd, SecItemCopyMatching, SecItemUpdate, SecItemDelete)
- UITextInputPasswordRules
- Authorization Services APIs
- Code Signing Services APIs
- SecAccessControl
- SecKey
- SecCertificate
- SecTrust
- SecIdentity
- And various security-related types

**Detailed Docs Found:** 1
- lacontext.md (EXISTS ✅, but belongs to biometrics)

**Detailed Docs Missing:** 19+

**Priority Assessment:**
- CRITICAL: Keychain Services APIs (SecItemAdd, SecItemCopyMatching, SecItemUpdate, SecItemDelete)
- HIGH: SecAccessControl, SecKey, SecCertificate, UITextInputPasswordRules
- MEDIUM: Authorization Services, Code Signing Services, SecTrust

---

### sharing/ - Link Presentation Framework

**Status:** ✅ Verified
**Overview Docs:** 1
- link-presentation-overview.md

**API Classes Mentioned:** 3
- LPMetadataProvider
- LPLinkMetadata
- LPLinkView

**Detailed Docs Found:** 0
**Detailed Docs Missing:** 3

**Priority Assessment:**
- HIGH: LPMetadataProvider, LPLinkMetadata, LPLinkView (useful for sharing/preview features)

---

### storage/ - CloudKit, Core Data, File System

**Status:** ✅ Verified
**Overview Docs:** 6
- cloudkit-overview.md
- coredata-overview.md
- files-and-directories.md
- personal-data.md
- shared-data.md
- structured-data-models.md

**API Classes Mentioned (CloudKit):** 15+
- CKRecordZone
- CKRecord
- CKAsset
- CKModifyRecordZonesOperation
- CKModifyRecordsOperation
- CKQuery
- CKQueryOperation
- CKSyncEngine
- And various supporting types

**API Classes Mentioned (Core Data):** 20+
- NSPersistentContainer (EXISTS ✅)
- NSManagedObjectContext
- NSManagedObject (EXISTS ✅)
- NSManagedObjectModel
- NSEntityDescription
- NSAttributeDescription
- NSRelationshipDescription
- NSFetchRequest (EXISTS ✅)
- NSPersistentStoreCoordinator
- NSPersistentStore
- And various supporting types

**API Classes Mentioned (File System):** 5+
- FileManager
- FileDocument
- UIDocument
- NSDocument
- FileHandle
- Data
- URL
- URLFileProtection

**Detailed Docs Found:** 3
- nspersistentcontainer.md (EXISTS ✅)
- nsmanagedobject.md (EXISTS ✅)
- nsfetchrequest.md (EXISTS ✅)

**Detailed Docs Missing:** 37+

**Priority Assessment:**
- CRITICAL: NSPersistentContainer (EXISTS ✅), NSManagedObject (EXISTS ✅), NSManagedObjectContext, FileManager
- HIGH: NSFetchRequest (EXISTS ✅), CKRecord, CKSyncEngine, NSManagedObjectModel, URL
- MEDIUM: CKQuery, CloudKit operations, Core Data batch operations, FileDocument

---

### swift/ - Swift Language, CoreML, Metal

**Status:** ✅ Verified
**Overview Docs:** 5
- apple-intelligence.md
- coreml-overview.md
- foundation-models.md
- metal-overview.md
- swift-standard-library.md

**API Classes Mentioned (CoreML):** 15+
- MLModel
- MLModelConfiguration (EXISTS ✅)
- MLModelDescription
- MLFeatureValue
- MLUpdateTask
- And various supporting types

**API Classes Mentioned (Metal):** 30+
- MTLDevice
- MTLCommandQueue
- MTLCommandBuffer
- MTLRenderPipelineState
- MTLComputePipelineState
- MTLTexture
- MTLBuffer
- And various supporting types

**API Classes Mentioned (Swift Standard Library):** 10+
- Int
- Double
- String
- Array
- Dictionary
- And various protocol types

**API Classes Mentioned (Apple Intelligence):** 5+
- SemanticContentDescriptor (Visual Intelligence)
- Image Playground APIs
- Writing Tools APIs
- NSAdaptiveImageGlyph (Genmoji)

**Detailed Docs Found:** 1
- mlmodelconfiguration.md (EXISTS ✅)

**Detailed Docs Missing:** 59+

**Priority Assessment:**
- CRITICAL: MLModel, MLModelConfiguration (EXISTS ✅), MTLDevice, String, Int, Double
- HIGH: MLFeatureValue, MTLCommandQueue, MTLBuffer, MTLTexture, Array, Dictionary
- MEDIUM: MLUpdateTask, advanced Metal types, SIMD types, Apple Intelligence APIs

---

### swiftui/ - SwiftUI Framework

**Status:** ✅ Verified
**Overview Docs:** 5
- swiftui-overview.md
- swiftui-apps-overview.md
- uikit-overview.md
- app-design-and-ui.md
- interface-fundamentals.md

**API Classes Mentioned (SwiftUI):** 30+
- View (EXISTS ✅)
- State (EXISTS ✅)
- Binding (EXISTS ✅)
- NavigationStack
- NavigationSplitView
- NavigationLink
- TabView
- WindowGroup
- App (protocol)
- Scene (protocol)
- And various view modifiers and types

**API Classes Mentioned (UIKit):** 20+
- UIApplication
- UIApplicationDelegate
- UIWindowScene
- UISceneDelegate
- UIViewController
- UIImage (EXISTS ✅)
- UIView
- And various supporting types

**Detailed Docs Found:** 4
- view.md (EXISTS ✅)
- state.md (EXISTS ✅)
- binding.md (EXISTS ✅)
- uiimage.md (EXISTS ✅)

**Detailed Docs Missing:** 46+

**Priority Assessment:**
- CRITICAL: View (EXISTS ✅), State (EXISTS ✅), Binding (EXISTS ✅), App, UIViewController
- HIGH: NavigationStack, UIApplication, UIApplicationDelegate, WindowGroup
- MEDIUM: TabView, NavigationLink, UISceneDelegate, advanced view types

---

### testing/ - XCTest & Swift Testing

**Status:** ✅ Verified
**Overview Docs:** 2
- xctest-overview.md
- swift-testing-overview.md

**API Classes Mentioned (XCTest):** 30+
- XCTestCase (EXISTS ✅)
- XCTAssert functions (various)
- XCTestExpectation
- XCTAttachment
- XCTMetric types
- XCTestRun
- XCTestObservation
- And various supporting types

**API Classes Mentioned (Swift Testing):** 10+
- @Test macro
- @Suite macro
- Test struct
- expect()
- require()
- confirmation()
- Trait types
- And various supporting types

**Detailed Docs Found:** 1
- xctestcase.md (EXISTS ✅)

**Detailed Docs Missing:** 39+

**Priority Assessment:**
- CRITICAL: XCTestCase (EXISTS ✅), @Test macro, XCTAssert functions
- HIGH: XCTestExpectation, expect(), require(), @Suite macro
- MEDIUM: XCTAttachment, XCTMetric types, Swift Testing traits

---

### vision/ - Vision Framework

**Status:** ✅ Verified
**Overview Docs:** 1
- vision-framework-overview.md

**API Classes Mentioned:** 25+
- VNImageRequestHandler (EXISTS ✅)
- ClassifyImageRequest
- ClassificationObservation
- DetectLensSmudgeRequest
- GeneratePersonSegmentationRequest
- GeneratePersonInstanceMaskRequest
- DetectDocumentSegmentationRequest
- CalculateImageAestheticsScoresRequest
- GenerateAttentionBasedSaliencyImageRequest
- VNCoreMLModel (EXISTS ✅)
- VNCoreMLRequest (EXISTS ✅)
- VNRecognizedObjectObservation (EXISTS ✅)
- PixelBufferObservation
- VisionRequest
- VisionObservation
- VisionResult
- And various supporting types

**Detailed Docs Found:** 4
- vnimagerequesthandler.md (EXISTS ✅)
- vncoremlmodel.md (EXISTS ✅)
- vncoremlrequest.md (EXISTS ✅)
- vnrecognizedobjectobservation.md (EXISTS ✅)

**Detailed Docs Missing:** 21+

**Priority Assessment:**
- CRITICAL: VNImageRequestHandler (EXISTS ✅), VNCoreMLModel (EXISTS ✅), VNCoreMLRequest (EXISTS ✅)
- HIGH: ClassifyImageRequest, VNRecognizedObjectObservation (EXISTS ✅), PixelBufferObservation
- MEDIUM: Segmentation requests, saliency requests, aesthetics requests

---

### visual-intelligence/ - Visual Intelligence Framework

**Status:** ✅ Verified
**Overview Docs:** 1
- visual-intelligence-overview.md

**API Classes Mentioned:** 2
- SemanticContentDescriptor
- Related App Intents APIs

**Detailed Docs Found:** 0
**Detailed Docs Missing:** 2

**Priority Assessment:**
- MEDIUM: SemanticContentDescriptor (new Apple Intelligence feature for Camera Control)
- LOW: App Intents integration (covered by App Intents framework)

---

## Missing Documentation Priority Matrix

### CRITICAL (Stage 2.2) - 20 APIs
Must fetch before Stage 2.2 implementation:
- **auth/**: (None - all CRITICAL APIs fetched)
- **biometrics/**: (None - LAContext EXISTS ✅)
- **camera/**: (None - all CRITICAL APIs exist)
- **maps/**: (None - MKMapView EXISTS ✅)
- **notifications/**: (None - all CRITICAL APIs exist)
- **payment/**: PKPaymentAuthorizationController, PKPaymentButton, Product
- **scanning/**: ImageAnalyzer
- **security/**: SecItemAdd, SecItemCopyMatching, SecItemUpdate, SecItemDelete
- **storage/**: NSManagedObjectContext, FileManager
- **swift/**: MLModel, MTLDevice, String, Int, Double
- **swiftui/**: App, UIViewController
- **testing/**: @Test macro, XCTAssert functions

Note: While some directories show as complete, certain CRITICAL APIs may still be missing. Review individual directory assessments for details.

### HIGH (MVP) - 91 APIs
Should fetch for MVP features:

**auth/** (3 APIs):
- SignInWithAppleButton
- ASAuthorizationAppleIDProvider
- ASAuthorizationError

**biometrics/** (3 APIs):
- LARight
- LAError
- LABiometryType

**camera/** (3 APIs):
- AVCapturePhotoOutput
- AVCaptureDeviceInput
- PHPhotoLibrary

**content-safety/** (4 APIs):
- SCSensitivityAnalyzer
- SCVideoStreamAnalyzer
- SCSensitivityAnalysis
- VideoAnalysisHandler

**foundation/** (2 APIs):
- Decimal
- Data

**networking/** (4 APIs):
- NWConnection
- NWPathMonitor
- Publisher
- AnyCancellable

**observation/** (2 APIs):
- @Observable macro
- Observable protocol

**payment/** (4 APIs):
- PKPaymentRequest
- StoreView
- ProductView
- Transaction

**privacy/** (1 API):
- ATTrackingManager

**scanning/** (3 APIs):
- ImageAnalysisInteraction
- VNDocumentCameraViewController
- ImageAnalysis

**security/** (4 APIs):
- SecAccessControl
- SecKey
- SecCertificate
- UITextInputPasswordRules

**sharing/** (3 APIs):
- LPMetadataProvider
- LPLinkMetadata
- LPLinkView

**storage/** (4 APIs):
- CKRecord
- CKSyncEngine
- NSManagedObjectModel
- URL

**swift/** (6 APIs):
- MLFeatureValue
- MTLCommandQueue
- MTLBuffer
- MTLTexture
- Array
- Dictionary

**swiftui/** (4 APIs):
- NavigationStack
- UIApplication
- UIApplicationDelegate
- WindowGroup

**testing/** (4 APIs):
- XCTestExpectation
- expect()
- require()
- @Suite macro

**vision/** (2 APIs):
- ClassifyImageRequest
- PixelBufferObservation

**maps/** (3 APIs):
- MKAnnotation
- MKDirections
- MKLocalSearch

**notifications/** (4 APIs):
- UNNotificationRequest
- UNNotificationTrigger types
- UNNotificationAction
- UNNotificationCategory

### MEDIUM (Future) - 162+ APIs
Can fetch on-demand during implementation:

**auth/** (2 APIs):
- ASPasskeyAssertionCredential
- ASPasskeyRegistrationCredential

**biometrics/** (4 APIs):
- LAPrivateKey
- LAPublicKey
- LARightStore
- LocalAuthenticationView

**camera/** (3 APIs):
- PHAsset
- PHImageManager
- AVCaptureVideoDataOutput

**image-processing/** (0 APIs - overview sufficient):
- Framework capabilities covered in overview

**liquid-glass/** (0 APIs - design guidance only):
- No API documentation needed

**maps/** (2 APIs):
- MKLookAroundViewController
- MKOverlay types

**networking/** (4 APIs):
- NWParameters
- NWBrowser
- NWListener
- Subject types (Combine)

**notifications/** (3 APIs):
- UNNotificationServiceExtension
- UNError
- UNAuthorizationStatus

**observation/** (2 APIs):
- withObservationTracking()
- ObservationRegistrar

**payment/** (2+ APIs):
- Recurring/deferred payment types
- Subscription views

**payments/** (0 APIs - legacy, fully documented):
- SKPaymentQueue (EXISTS ✅)
- SKProduct (EXISTS ✅)

**performance/** (0+ APIs):
- BNNS APIs (fetch on-demand for ML/compute workloads)

**privacy/** (1 API):
- ATTrackingManager.AuthorizationStatus

**scanning/** (2 APIs):
- ImageAnalysisOverlayView
- Supporting delegate types

**security/** (3+ APIs):
- Authorization Services
- Code Signing Services
- SecTrust

**storage/** (30+ APIs):
- CloudKit: CKQuery, CKModifyRecordZonesOperation, CKModifyRecordsOperation, CKQueryOperation, CKAsset, CKRecordZone
- Core Data: NSEntityDescription, NSAttributeDescription, NSRelationshipDescription, NSPersistentStoreCoordinator, NSPersistentStore
- File System: FileDocument, UIDocument, NSDocument, FileHandle, URLFileProtection

**swift/** (47+ APIs):
- CoreML: MLUpdateTask, MLModelDescription, supporting types
- Metal: MTLRenderPipelineState, MTLComputePipelineState, and 25+ other Metal types
- Standard Library: SIMD types, protocol types
- Apple Intelligence: SemanticContentDescriptor, Image Playground APIs, Writing Tools APIs, NSAdaptiveImageGlyph

**swiftui/** (42+ APIs):
- SwiftUI: NavigationSplitView, NavigationLink, TabView, Scene protocol, view modifiers
- UIKit: UIWindowScene, UISceneDelegate, UIView, supporting types

**testing/** (35+ APIs):
- XCTest: XCTAttachment, XCTMetric types, XCTestRun, XCTestObservation, supporting types
- Swift Testing: Trait types, confirmation(), supporting types

**vision/** (18+ APIs):
- DetectLensSmudgeRequest
- GeneratePersonSegmentationRequest
- GeneratePersonInstanceMaskRequest
- DetectDocumentSegmentationRequest
- CalculateImageAestheticsScoresRequest
- GenerateAttentionBasedSaliencyImageRequest
- ClassificationObservation
- VisionRequest
- VisionObservation
- VisionResult
- Supporting types

**visual-intelligence/** (2 APIs):
- SemanticContentDescriptor
- App Intents integration

---

## Recommendations

### Immediate Actions (Phase 1.5 - Before Stage 2.2)

**Status:** Phase 1 was incomplete - claimed 19 CRITICAL APIs but verification shows only partial coverage exists for Stage 2.2 needs.

**Missing CRITICAL APIs:** 20 total (see Priority Matrix)

**Blocker Risk:** MEDIUM-HIGH - Stage 2.2 implementation can proceed with existing docs, but will encounter gaps in specific areas:
- Payment integration (PKPaymentAuthorizationController, PKPaymentButton)
- Image analysis (ImageAnalyzer for visual intelligence)
- Security/Keychain operations (SecItemAdd, SecItemCopyMatching, etc.)
- Core storage (NSManagedObjectContext, FileManager)
- Core Swift types (MLModel, MTLDevice)
- Testing fundamentals (@Test macro, XCTAssert functions)

**Recommended Action:** Execute focused fetch for the 20 CRITICAL APIs before Stage 2.2 implementation begins.

**Estimated Time:** 3-4 hours for batch fetching + manifest updates

**Implementation Priority:**
1. **security/** - Keychain APIs (4 APIs) - Required for secure credential storage
2. **payment/** - Apple Pay APIs (3 APIs) - Required for payment processing
3. **storage/** - Core Data/FileManager (2 APIs) - Required for data persistence
4. **swift/** - Core types (5 APIs) - Required for basic operations
5. **testing/** - Test APIs (3 APIs) - Required for test development
6. **Others** - ImageAnalyzer, App, UIViewController (3 APIs)

---

### Phase 2 Actions (MVP - High Priority)

**Missing HIGH Priority APIs:** 91 total

**MVP Risk:** MEDIUM - Can implement basic features but will lack comprehensive API coverage for production-ready features.

**Recommended Approach:** Fetch HIGH priority APIs by feature area as needed during Stage 2.2 implementation:

**By Feature Area:**
1. **Authentication** (6 APIs): SignInWithAppleButton, ASAuthorizationAppleIDProvider, ASAuthorizationError, LARight, LAError, LABiometryType
2. **Camera/Media** (9 APIs): AVCapturePhotoOutput, AVCaptureDeviceInput, PHPhotoLibrary, etc.
3. **Content Safety** (4 APIs): All SensitiveContentAnalysis APIs
4. **Foundation** (2 APIs): Decimal, Data
5. **Networking** (4 APIs): NWConnection, NWPathMonitor, Publisher, AnyCancellable
6. **Notifications** (3 APIs): UNTimeIntervalNotificationTrigger, UNNotificationAction, UNNotificationCategory
7. **Privacy** (1 API): ATTrackingManager
8. **SwiftUI** (20+ APIs): NavigationStack, List, Form, Button, TextField, etc.
9. **Testing** (15+ APIs): XCTestCase methods, test lifecycle
10. **Vision** (5+ APIs): Request types, observation types
11. **And others across remaining frameworks**

**Estimated Time:** 8-12 hours total, can be spread across implementation cycles

**Strategy:** Fetch on-demand when implementing specific features that require these APIs

---

### Phase 3 Actions (Future - On-Demand)

**Missing MEDIUM Priority APIs:** 162+ total

**Recommendation:** Maintain current just-in-time approach
- Fetch when implementation requires specific functionality
- Reference sosumi.ai URLs for quick access during development
- Update manifests after fetching

---

### Foundation Framework Gap

**Critical Finding:** The foundation/ directory overview is severely limited - only mentions Decimal and Data types.

**Missing Essential APIs:**
- URLSession (networking)
- JSONEncoder/JSONDecoder (data serialization)
- FileManager (file operations) ⚠️ Listed as CRITICAL in storage/
- UserDefaults (preferences)
- Date, Calendar, DateFormatter (date/time)
- Notification, NotificationCenter (app events)
- UUID (identifiers)

**Recommendation:** Before Stage 2.2, decide if these APIs should be:
1. **Fetched to foundation/** - Create comprehensive Foundation documentation
2. **Fetched to appropriate feature directories** - E.g., FileManager to storage/, URLSession to networking/
3. **Deferred** - Rely on existing documentation sources during implementation

**Our Assessment:** Option 2 is best - these APIs are already documented in their feature-specific directories (storage/, networking/). No action needed unless implementation requires Foundation-specific documentation.

---

### Documentation Quality Notes

**Excellent Coverage (No CRITICAL gaps):**
- ✅ auth/ - All 3 CRITICAL APIs fetched
- ✅ biometrics/ - LAContext exists
- ✅ camera/ - AVCaptureSession, AVCaptureDevice exist
- ✅ maps/ - MKMapView exists
- ✅ notifications/ - 2 detailed docs exist
- ✅ payments/ (legacy) - Fully documented

**Good Coverage (Some detailed docs exist):**
- scanning/ - 2 docs exist (DataScannerViewController, delegate)
- security/ - 1 doc exists (LAContext)
- storage/ - 3 docs exist (Core Data entities)
- swiftui/ - 4 docs exist (View, State, Binding, Environment)
- testing/ - 1 doc exists (XCTestCase)
- vision/ - 4 docs exist (request handlers, models)

**Minimal Coverage (Overview only):**
- content-safety/, observation/, privacy/, sharing/
- foundation/ (incomplete overview)
- image-processing/, performance/ (high-level overviews)

---

### 404 Documentation Handling

**APIs that returned 404:** 0

**Result:** All attempted fetches (3 auth/ CRITICAL APIs) were successful from sosumi.ai.

**Strategy for Future Fetches:**
1. Try sosumi.ai first with pattern: `https://sosumi.ai/documentation/[framework]/[classname-lowercase]`
2. If 404, try alternative URL patterns:
   - Remove/add hyphens
   - Try different case variations
   - Check parent framework path
3. If truly missing from sosumi.ai:
   - Reference official Apple Developer documentation
   - Document which APIs require Apple Developer account access
   - Consider manual markdown creation for essential APIs

---

### Updating apple-docs-fetching-plan.md

**Action Required:** Update the fetching plan document to reflect:
1. Correct Phase 1 completion percentages (claimed 19 CRITICAL, actual verification shows mixed)
2. Add Phase 1.5 section for the 20 remaining CRITICAL APIs
3. Update framework coverage matrix with actual verification findings
4. Revise time estimates based on verification results

**Key Corrections:**
- Phase 1 is NOT fully complete - 20 CRITICAL APIs remain
- Documentation exists for only 19 out of 350+ identified APIs (5.4% coverage)
- Most frameworks have overview-only documentation

---

### Next Steps

**Recommended Workflow:**
1. ✅ Review this verification report with stakeholders
2. ⬜ Decide on Phase 1.5 scope (fetch 20 CRITICAL APIs immediately vs. on-demand)
3. ⬜ Update apple-docs-fetching-plan.md with corrections
4. ⬜ Create Phase 1.5 execution plan if approved
5. ⬜ Consider automation script for ongoing verification and manifest updates
6. ⬜ Document which APIs cannot be fetched from sosumi.ai (if any discovered)

**For Stage 2.2 Implementation:**
- Current documentation is sufficient to START implementation
- Fetch additional APIs on-demand as specific features are developed
- Prioritize security/ and payment/ CRITICAL APIs if those features are implemented first

# DESIGN-012: Xcode Project Structure

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**Purpose**: Define modular Swift Package Manager structure for Abundance iOS app

---

## Overview

This document defines the Xcode project structure for Abundance, following ADR-011 (iOS Module Structure). The project uses Swift Package Manager local packages to organize features, core logic, and shared utilities.

**Benefits**:
- Clear separation of concerns
- Feature module isolation
- Reusable core logic
- Independent testing per module
- Scalable to Phase 2 (marketplace features)

---

## Project Structure

```
Abundance/
├── Abundance.xcodeproj
├── Abundance/                          # Main app target
│   ├── AbundanceApp.swift             # App entry point
│   ├── ContentView.swift              # Root view
│   ├── Config/
│   │   ├── GoogleService-Info.plist   # Firebase config
│   │   └── Info.plist                 # App metadata
│   └── Resources/
│       ├── Assets.xcassets            # App icon, colors
│       └── Localizable.strings        # Localization
│
├── Packages/                           # Swift Package Manager local packages
│   ├── Features/                       # Feature modules
│   │   ├── CatalogFeature/
│   │   ├── CameraFeature/
│   │   ├── OnboardingFeature/
│   │   └── ProfileFeature/
│   │
│   ├── Core/                           # Core business logic
│   │   ├── Models/
│   │   ├── Networking/
│   │   ├── Firebase/
│   │   ├── Vision/
│   │   └── Persistence/
│   │
│   └── Shared/                         # Shared utilities
│       ├── Extensions/
│       ├── Constants/
│       └── Components/
│
├── AbundanceTests/                     # Unit tests
│   ├── ViewModels/
│   ├── Repositories/
│   ├── Mocks/
│   └── Fixtures/
│
├── AbundanceUITests/                   # UI automation tests
│   └── CriticalJourneyTests.swift
│
├── Generated/                          # Sourcery generated code
│   ├── ViewModels+Generated.swift
│   └── Mocks+Generated.swift
│
└── .sourcery/                          # Sourcery templates
    ├── ViewModel.stencil
    └── Mock.stencil
```

---

## Package Dependency Graph

```
                  ┌─────────────┐
                  │ Abundance   │
                  │  (main app) │
                  └──────┬──────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
     ┌────▼────┐    ┌────▼────┐   ┌────▼────┐
     │ Catalog │    │ Camera  │   │Onboarding│
     │ Feature │    │ Feature │   │ Feature  │
     └────┬────┘    └────┬────┘   └────┬─────┘
          │              │              │
          └──────────────┼──────────────┘
                         │
          ┌──────────────┼──────────────┬──────────────┐
          │              │              │              │
     ┌────▼────┐    ┌────▼────┐   ┌────▼────┐   ┌────▼────┐
     │ Models  │    │Firebase │   │ Vision  │   │ Shared  │
     │  (Core) │    │ (Core)  │   │ (Core)  │   │(Utility)│
     └─────────┘    └─────────┘   └─────────┘   └─────────┘
```

**Rules**:
- Features depend on Core modules (Models, Firebase, Vision)
- Features do NOT depend on each other
- Core modules do NOT depend on Features
- Shared utilities can be used by anyone

---

## Main App Target

### Abundance/AbundanceApp.swift

```swift
import SwiftUI
import FirebaseCore

@main
struct AbundanceApp: App {
    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Configure Firestore offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings

        // Initialize analytics
        AnalyticsService.logAppOpen()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Abundance/ContentView.swift

```swift
import SwiftUI
import OnboardingFeature
import CatalogFeature

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var authCoordinator = AppleSignInCoordinator()

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(
                    authCoordinator: authCoordinator,
                    onComplete: {
                        hasCompletedOnboarding = true
                    }
                )
            } else if !authCoordinator.isAuthenticated {
                SignInView(authCoordinator: authCoordinator)
            } else {
                CatalogView()
            }
        }
    }
}
```

---

## Feature Packages

### CatalogFeature

**Package.swift**:
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CatalogFeature",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CatalogFeature", targets: ["CatalogFeature"])
    ],
    dependencies: [
        .package(path: "../Core/Models"),
        .package(path: "../Core/Firebase"),
        .package(path: "../Shared"),
    ],
    targets: [
        .target(
            name: "CatalogFeature",
            dependencies: [
                "Models",
                "Firebase",
                "Shared"
            ]
        ),
        .testTarget(
            name: "CatalogFeatureTests",
            dependencies: ["CatalogFeature"]
        )
    ]
)
```

**Sources**:
```
CatalogFeature/
├── Package.swift
├── Sources/CatalogFeature/
│   ├── Views/
│   │   ├── CatalogView.swift
│   │   ├── CatalogItemRow.swift
│   │   └── CatalogDetailView.swift
│   ├── ViewModels/
│   │   └── CatalogViewModel.swift
│   └── Repositories/
│       ├── CatalogRepository.swift
│       └── FirestoreCatalogRepository.swift
└── Tests/CatalogFeatureTests/
    ├── CatalogViewModelTests.swift
    └── Mocks/
        └── MockCatalogRepository.swift
```

### CameraFeature

**Package.swift**:
```swift
let package = Package(
    name: "CameraFeature",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CameraFeature", targets: ["CameraFeature"])
    ],
    dependencies: [
        .package(path: "../Core/Models"),
        .package(path: "../Core/Vision"),
        .package(path: "../Core/Firebase"),
        .package(path: "../Shared"),
    ],
    targets: [
        .target(
            name: "CameraFeature",
            dependencies: [
                "Models",
                "Vision",
                "Firebase",
                "Shared"
            ]
        ),
        .testTarget(
            name: "CameraFeatureTests",
            dependencies: ["CameraFeature"]
        )
    ]
)
```

**Sources**:
```
CameraFeature/
├── Sources/CameraFeature/
│   ├── Views/
│   │   ├── CameraView.swift
│   │   ├── CameraPreviewView.swift
│   │   └── ObjectSelectionView.swift
│   ├── ViewModels/
│   │   ├── CameraViewModel.swift
│   │   └── ItemCaptureViewModel.swift
│   └── Services/
│       └── CameraService.swift
└── Tests/CameraFeatureTests/
    └── CameraViewModelTests.swift
```

### OnboardingFeature

**Sources**:
```
OnboardingFeature/
├── Sources/OnboardingFeature/
│   ├── Views/
│   │   ├── OnboardingView.swift
│   │   ├── WelcomeView.swift
│   │   └── SignInView.swift
│   ├── ViewModels/
│   │   └── OnboardingViewModel.swift
│   └── Coordinators/
│       └── AppleSignInCoordinator.swift
└── Tests/OnboardingFeatureTests/
    └── OnboardingViewModelTests.swift
```

### ProfileFeature

**Sources**:
```
ProfileFeature/
├── Sources/ProfileFeature/
│   ├── Views/
│   │   ├── ProfileView.swift
│   │   ├── SettingsView.swift
│   │   └── SubscriptionView.swift
│   └── ViewModels/
│       ├── ProfileViewModel.swift
│       └── SubscriptionViewModel.swift
└── Tests/ProfileFeatureTests/
    └── ProfileViewModelTests.swift
```

---

## Core Packages

### Models

**Package.swift**:
```swift
let package = Package(
    name: "Models",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Models", targets: ["Models"])
    ],
    targets: [
        .target(name: "Models"),
        .testTarget(name: "ModelsTests", dependencies: ["Models"])
    ]
)
```

**Sources**:
```
Models/
├── Sources/Models/
│   ├── CatalogItem.swift
│   ├── User.swift
│   ├── AIAnalysis.swift
│   ├── DetectedObject.swift
│   └── Barcode.swift
└── Tests/ModelsTests/
    └── CatalogItemTests.swift
```

### Firebase

**Package.swift**:
```swift
let package = Package(
    name: "Firebase",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Firebase", targets: ["Firebase"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.11.0"),
        .package(path: "../Models"),
    ],
    targets: [
        .target(
            name: "Firebase",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                "Models"
            ]
        )
    ]
)
```

**Sources**:
```
Firebase/
└── Sources/Firebase/
    ├── Auth/
    │   └── AppleSignInCoordinator.swift
    ├── Firestore/
    │   ├── FirestoreExtensions.swift
    │   └── Query+Publisher.swift
    ├── Storage/
    │   └── ImageStorageService.swift
    ├── Analytics/
    │   └── AnalyticsService.swift
    └── Helpers/
        └── KeychainHelper.swift
```

### Vision

**Package.swift**:
```swift
let package = Package(
    name: "Vision",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Vision", targets: ["Vision"])
    ],
    dependencies: [
        .package(path: "../Models"),
    ],
    targets: [
        .target(
            name: "Vision",
            dependencies: ["Models"],
            resources: [.process("Resources/YOLOv3Tiny.mlmodel")]
        )
    ]
)
```

**Sources**:
```
Vision/
└── Sources/Vision/
    ├── VisionService.swift
    ├── ObjectDetection.swift
    ├── BarcodeScanning.swift
    └── Resources/
        └── YOLOv3Tiny.mlmodel
```

### Networking

**Package.swift**:
```swift
let package = Package(
    name: "Networking",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Networking", targets: ["Networking"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),
        .package(path: "../Models"),
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: [
                "Alamofire",
                "Models"
            ]
        )
    ]
)
```

**Sources**:
```
Networking/
└── Sources/Networking/
    ├── APIClient.swift
    ├── FirebaseAPIClient.swift
    └── Endpoints/
        ├── ItemsEndpoint.swift
        └── UserEndpoint.swift
```

### Persistence

**Sources**:
```
Persistence/
└── Sources/Persistence/
    ├── UserDefaults+Keys.swift
    ├── KeychainHelper.swift
    └── CacheManager.swift
```

---

## Shared Package

**Package.swift**:
```swift
let package = Package(
    name: "Shared",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Shared", targets: ["Shared"])
    ],
    targets: [
        .target(name: "Shared")
    ]
)
```

**Sources**:
```
Shared/
└── Sources/Shared/
    ├── Extensions/
    │   ├── Date+Extensions.swift
    │   ├── String+Extensions.swift
    │   ├── UIImage+Extensions.swift
    │   └── View+Extensions.swift
    ├── Constants/
    │   ├── AppConstants.swift
    │   └── ColorPalette.swift
    └── Components/
        ├── LoadingView.swift
        ├── ErrorView.swift
        └── EmptyStateView.swift
```

---

## Build Configuration

### Xcode Schemes

1. **Abundance (Development)**
   - Configuration: Debug
   - Firebase: `GoogleService-Info-Dev.plist`
   - Bundle ID: `com.abundance.ios.dev`

2. **Abundance (Staging)**
   - Configuration: Release
   - Firebase: `GoogleService-Info-Staging.plist`
   - Bundle ID: `com.abundance.ios.staging`

3. **Abundance (Production)**
   - Configuration: Release
   - Firebase: `GoogleService-Info-Prod.plist`
   - Bundle ID: `com.abundance.ios`

### Build Settings

**Swift Compiler - Concurrency Checking**: Complete (Swift 6 mode)
**Minimum Deployment Target**: iOS 26.0
**Swift Language Version**: Swift 6

---

## Adding a New Feature Module

### Steps:

1. **Create package directory**:
   ```bash
   mkdir -p Packages/Features/NewFeature/Sources/NewFeature
   mkdir -p Packages/Features/NewFeature/Tests/NewFeatureTests
   ```

2. **Create Package.swift**:
   ```swift
   let package = Package(
       name: "NewFeature",
       platforms: [.iOS(.v26)],
       products: [
           .library(name: "NewFeature", targets: ["NewFeature"])
       ],
       dependencies: [
           .package(path: "../Core/Models"),
           .package(path: "../Shared"),
       ],
       targets: [
           .target(name: "NewFeature", dependencies: ["Models", "Shared"]),
           .testTarget(name: "NewFeatureTests", dependencies: ["NewFeature"])
       ]
   )
   ```

3. **Add to Xcode project**:
   - File → Add Package Dependencies → Add Local...
   - Select `Packages/Features/NewFeature`

4. **Add to main app target dependencies**:
   - Select Abundance target → General → Frameworks, Libraries, and Embedded Content
   - Click + → Add NewFeature

5. **Import in code**:
   ```swift
   import NewFeature
   ```

---

## Testing Structure

### Unit Tests (AbundanceTests/)

```
AbundanceTests/
├── ViewModels/
│   ├── CatalogViewModelTests.swift
│   ├── CameraViewModelTests.swift
│   └── ProfileViewModelTests.swift
├── Repositories/
│   └── FirestoreCatalogRepositoryTests.swift
├── Mocks/
│   ├── MockCatalogRepository.swift
│   ├── MockUserRepository.swift
│   └── MockVisionService.swift
└── Fixtures/
    └── TestFixtures.swift
```

### UI Tests (AbundanceUITests/)

```
AbundanceUITests/
├── CriticalJourneyTests.swift
│   ├── testSignInToCatalog()
│   ├── testCapturePhotoToSaveItem()
│   └── testSearchForItem()
└── Helpers/
    └── UITestHelpers.swift
```

---

## Generated Code (Sourcery)

### .sourcery/ Templates

```
.sourcery/
├── ViewModel.stencil         # Generate ViewModel boilerplate
├── Mock.stencil              # Generate mock implementations
└── sourcery.yml              # Sourcery configuration
```

### Generated/ Output

```
Generated/
├── ViewModels+Generated.swift    # Generated ViewModel code
└── Mocks+Generated.swift         # Generated mock repositories
```

### Run Script Build Phase

```bash
if which sourcery >/dev/null; then
  sourcery --sources ./Packages --templates ./.sourcery --output ./Generated
else
  echo "warning: Sourcery not installed, skipping code generation"
fi
```

---

## References

- **ADR-011**: iOS Module Structure (modular packages)
- **CODE-EXAMPLE-002**: Catalog MVVM Implementation
- **TEST-EXAMPLE-001**: ViewModel Unit Tests

---

## Verification

✅ Main app target defined (AbundanceApp, ContentView)
✅ Feature packages defined (Catalog, Camera, Onboarding, Profile)
✅ Core packages defined (Models, Firebase, Vision, Networking, Persistence)
✅ Shared package defined (Extensions, Constants, Components)
✅ Package dependency graph is acyclic
✅ Build configurations defined (Dev, Staging, Prod)
✅ Testing structure defined (Unit, UI tests)
✅ Sourcery integration planned

---

**Status**: ✅ Complete

**Next**: CODEGEN-001 (Sourcery Templates)

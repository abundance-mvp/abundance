# DESIGN-006: iOS Module Dependencies

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Approved
**References**: ADR-011 (iOS Module Structure)

---

## Overview

This document provides a visual representation of the Abundance iOS module structure and dependency graph. The modular architecture uses Swift Package Manager local packages organized into three layers: Features, Core, and Shared.

---

## Module Dependency Graph

```
┌─────────────────────────────────────────────────────────────────┐
│                          App Target                              │
│                    (AbundanceApp.swift)                          │
│                                                                   │
│  Dependencies: CatalogFeature, CameraFeature,                    │
│                OnboardingFeature, ProfileFeature                 │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Feature Layer                             │
│  (UI + ViewModels + Feature-Specific Business Logic)             │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐        │
│  │   Catalog    │  │   Camera     │  │   Onboarding    │        │
│  │   Feature    │  │   Feature    │  │    Feature      │        │
│  └──────┬───────┘  └──────┬───────┘  └────────┬────────┘        │
│         │                  │                   │                 │
│  ┌──────────────────────────────────────────────────────┐        │
│  │                  Profile Feature                     │        │
│  └──────────────────────┬───────────────────────────────┘        │
└─────────────────────────┼──────────────────────────────────────

─┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Core Layer                               │
│        (Data, Networking, Firebase, Vision, Persistence)         │
│                                                                   │
│  ┌─────────┐  ┌────────────┐  ┌──────────┐  ┌────────┐          │
│  │ Models  │  │ Networking │  │ Firebase │  │ Vision │          │
│  └────┬────┘  └─────┬──────┘  └────┬─────┘  └───┬────┘          │
│       │             │               │            │               │
│  ┌────────────────────────────────────────────────────┐          │
│  │               Persistence                          │          │
│  └────────────────────┬───────────────────────────────┘          │
└─────────────────────────┼──────────────────────────────────────

─┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Shared Layer                              │
│          (Extensions, Constants, Reusable Components)            │
│                                                                   │
│  ┌────────────┐  ┌───────────┐  ┌─────────────┐                 │
│  │ Extensions │  │ Constants │  │ Components  │                 │
│  └────────────┘  └───────────┘  └─────────────┘                 │
│                                                                   │
│  Foundation Layer (No Dependencies)                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module Descriptions

### Feature Layer

**CatalogFeature**
- **Purpose**: Inventory list, search, item detail views
- **Dependencies**: Models, Networking, Firebase, Extensions, Constants, Components
- **ViewModels**: `CatalogViewModel`, `ItemDetailViewModel`, `SearchViewModel`
- **Views**: `CatalogView`, `ItemDetailView`, `SearchView`, `CatalogItemRow`

**CameraFeature**
- **Purpose**: Camera capture, Vision processing, object detection
- **Dependencies**: Models, Vision, Networking, Firebase, Extensions, Components
- **ViewModels**: `CameraViewModel`, `ObjectCaptureViewModel`
- **Views**: `CameraView`, `ObjectCaptureView`, `DetectedObjectsView`

**OnboardingFeature**
- **Purpose**: Welcome, permissions, Apple Sign-In
- **Dependencies**: Firebase, Persistence, Extensions, Components
- **ViewModels**: `OnboardingViewModel`, `AuthViewModel`
- **Views**: `WelcomeView`, `SignInView`, `PermissionsView`

**ProfileFeature**
- **Purpose**: User settings, subscription, export
- **Dependencies**: Models, Firebase, Extensions, Components
- **ViewModels**: `ProfileViewModel`, `ExportViewModel`, `SubscriptionViewModel`
- **Views**: `ProfileView`, `SettingsView`, `ExportView`, `SubscriptionView`

---

### Core Layer

**Models**
- **Purpose**: Codable structs for API/Firestore (CatalogItem, User, AIAnalysis)
- **Dependencies**: None
- **Files**: `CatalogItem.swift`, `User.swift`, `AIAnalysis.swift`, `SubscriptionStatus.swift`

**Networking**
- **Purpose**: REST API client (Alamofire wrapper)
- **Dependencies**: Models, Alamofire
- **Files**: `APIClient.swift`, `APIError.swift`, `APIEndpoint.swift`

**Firebase**
- **Purpose**: Firebase SDK wrappers (Auth, Firestore, Storage, Analytics)
- **Dependencies**: Models, Firebase iOS SDK (FirebaseAuth, FirebaseFirestore, FirebaseStorage, FirebaseAnalytics)
- **Files**: `AuthService.swift`, `FirestoreService.swift`, `StorageService.swift`, `AnalyticsService.swift`

**Vision**
- **Purpose**: Vision Framework integration (object detection, barcode scanning)
- **Dependencies**: Models
- **Files**: `VisionService.swift`, `ObjectDetector.swift`, `BarcodeScanner.swift`

**Persistence**
- **Purpose**: Local storage (UserDefaults, Keychain)
- **Dependencies**: None
- **Files**: `SettingsService.swift`, `KeychainService.swift`

---

### Shared Layer

**Extensions**
- **Purpose**: Swift/SwiftUI extensions
- **Dependencies**: None
- **Files**: `View+Extensions.swift`, `String+Extensions.swift`, `Date+Extensions.swift`

**Constants**
- **Purpose**: App constants (API URLs, colors, font sizes)
- **Dependencies**: None
- **Files**: `AppConstants.swift`, `ColorPalette.swift`, `LayoutConstants.swift`

**Components**
- **Purpose**: Reusable UI components (buttons, loading states, errors)
- **Dependencies**: Kingfisher (for AsyncImage component)
- **Files**: `LoadingView.swift`, `ErrorView.swift`, `PrimaryButton.swift`, `AsyncImageView.swift`

---

## Dependency Rules

### Enforced by Swift Package Manager

1. **Features** depend on **Core** and **Shared** (NOT other Features)
2. **Core** depends on **Shared** only (NOT Features)
3. **Shared** depends on nothing (foundation layer)
4. **App** depends on **Features** only (NOT Core or Shared directly)

### Circular Dependencies

SPM prevents circular dependencies at compile time:
- ❌ **CatalogFeature** → **CameraFeature** → **CatalogFeature** (circular, build fails)
- ✅ **CatalogFeature** → **Models** ← **CameraFeature** (shared dependency, valid)

---

## Package.swift Configuration

```swift
let package = Package(
    name: "AbundancePackages",
    platforms: [.iOS(.v26)],
    products: [
        // Features
        .library(name: "CatalogFeature", targets: ["CatalogFeature"]),
        .library(name: "CameraFeature", targets: ["CameraFeature"]),
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "ProfileFeature", targets: ["ProfileFeature"]),

        // Core
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Firebase", targets: ["Firebase"]),
        .library(name: "Vision", targets: ["Vision"]),
        .library(name: "Persistence", targets: ["Persistence"]),

        // Shared
        .library(name: "Extensions", targets: ["Extensions"]),
        .library(name: "Constants", targets: ["Constants"]),
        .library(name: "Components", targets: ["Components"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.5.0"),
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.9.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.11.0"),
    ],
    targets: [
        .target(name: "CatalogFeature", dependencies: ["Models", "Networking", "Firebase", "Extensions", "Constants", "Components"]),
        .target(name: "CameraFeature", dependencies: ["Models", "Vision", "Networking", "Firebase", "Extensions", "Components"]),
        .target(name: "OnboardingFeature", dependencies: ["Firebase", "Persistence", "Extensions", "Components"]),
        .target(name: "ProfileFeature", dependencies: ["Models", "Firebase", "Extensions", "Components"]),

        .target(name: "Models", dependencies: []),
        .target(name: "Networking", dependencies: ["Models", "Alamofire"]),
        .target(name: "Firebase", dependencies: ["Models", "FirebaseAuth", "FirebaseFirestore", "FirebaseStorage", "FirebaseAnalytics"]),
        .target(name: "Vision", dependencies: ["Models"]),
        .target(name: "Persistence", dependencies: []),

        .target(name: "Extensions", dependencies: []),
        .target(name: "Constants", dependencies: []),
        .target(name: "Components", dependencies: ["Kingfisher"]),
    ]
)
```

---

## Build Performance

### Parallel Compilation

Xcode compiles independent packages in parallel:
- `Models`, `Extensions`, `Constants`, `Persistence` compile simultaneously (no dependencies)
- `Networking`, `Firebase`, `Vision`, `Components` compile after `Models` (depend on Models)
- `CatalogFeature`, `CameraFeature` compile after Core layer (depend on Core)

### Incremental Builds

Xcode caches unchanged packages:
- Editing `CatalogFeature` only rebuilds `CatalogFeature` + `App` target
- Core modules (`Models`, `Networking`, `Firebase`) cached if unchanged
- **Result**: Faster incremental builds (5-10 seconds vs. 30+ seconds monolithic)

---

## Testing Strategy

### Unit Tests Per Module

Each package has its own test target:
- `CatalogFeatureTests` tests `CatalogViewModel` with mocked `CatalogRepository`
- `NetworkingTests` tests `APIClient` with mocked URLSession
- `FirebaseTests` tests `FirestoreService` with Firebase Emulator

### Test Execution

Run tests for specific modules:
```bash
# Test only CatalogFeature (fast, isolated)
xcodebuild test -scheme CatalogFeature

# Test all Core modules
xcodebuild test -scheme Models -scheme Networking -scheme Firebase

# Test all features
xcodebuild test -scheme CatalogFeature -scheme CameraFeature -scheme OnboardingFeature -scheme ProfileFeature
```

---

## Scalability (Phase 2/3)

### Phase 2: Marketplace Features

Add new packages without modifying existing code:
```
Packages/
├── Features/
│   ├── CatalogFeature/      # Existing
│   ├── CameraFeature/       # Existing
│   ├── OnboardingFeature/   # Existing
│   ├── ProfileFeature/      # Existing
│   ├── MarketplaceFeature/  # NEW (Phase 2)
│   └── MessagingFeature/    # NEW (Phase 2)
```

### Phase 3: PWA (Web App)

Extract Core modules into shared framework:
```
Packages/
├── Core/ (iOS + Web)
│   ├── Models/              # Shared (iOS + Web)
│   ├── Networking/          # Shared (iOS + Web)
│   └── Firebase/            # Shared (iOS + Web)
│
├── iOSFeatures/             # iOS-specific
│   ├── CatalogFeature/
│   └── CameraFeature/
│
└── WebFeatures/             # Web-specific
    ├── CatalogWebFeature/
    └── MarketplaceWebFeature/
```

---

## References

- **ADR**: docs/adr/ADR-011-ios-module-structure.md (Module structure decision)
- **Implementation Plan**: docs/plans/2025-11-08-stage-2.2-ios-client-architecture.md (Task 2)
- **Tech Stack**: docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Swift Package Manager)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial module dependency diagram | iOS Architecture Expert |

---

**Status**: ✅ **Approved**

**Module Structure**: Features → Core → Shared (3-layer architecture, clear dependencies, SPM-enforced)

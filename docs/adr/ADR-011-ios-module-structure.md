# ADR-011: iOS Module Structure

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Approved
**Decision**: Modular Package Architecture (Swift Package Manager)

---

## Context

The Abundance iOS app requires a module structure that supports:
- **Separation of concerns** (features isolated from core logic)
- **Testability** (each module testable independently)
- **Reusability** (core modules shared across features)
- **Scalability** (Phase 2 marketplace features, Phase 3 PWA)
- **Single developer velocity** (not over-engineered, clear structure)

**Options Considered**:
1. **Monolithic** - All code in main app target (no module boundaries)
2. **Swift Package Manager (SPM) Local Packages** - Feature/Core/Shared packages
3. **CocoaPods Workspace** - Podspec-based modules
4. **Carthage Frameworks** - Binary frameworks

---

## Decision

**We will use Swift Package Manager (SPM) local packages** with a **Feature/Core/Shared** modular architecture.

---

## Rationale

### Why Modular Architecture?

1. **Separation of Concerns**: Features (UI + business logic) separated from Core (data, networking, Firebase)
2. **Testability**: Each package has its own test target → isolated unit tests → faster test execution
3. **Reusability**: Core modules (Networking, Firebase, Models) shared across features → DRY principle
4. **Scalability**: Phase 2 marketplace features add new packages without modifying existing code
5. **Build Performance**: Xcode caches unchanged packages → faster incremental builds
6. **Clarity**: Clear module boundaries → easier to understand codebase (critical for single developer)

### Why Swift Package Manager?

1. **Native Integration**: Built into Xcode → no third-party tools (CocoaPods, Carthage)
2. **Modern**: Apple's recommended dependency management (replaced CocoaPods)
3. **Fast**: Resolves dependencies faster than CocoaPods (no Ruby runtime)
4. **Simple**: `Package.swift` manifest → no Podfile, no Cartfile
5. **Git-Friendly**: No need to commit `Pods/` or framework binaries
6. **Cross-Platform**: Works with Swift on Linux (future server-side Swift if needed)

### Why Not Monolithic?

**Monolithic Weaknesses**:
- ❌ No module boundaries → easy to create tight coupling
- ❌ All tests run together → slow test execution
- ❌ Hard to reuse code → copy-paste between features
- ❌ Difficult to scale → Phase 2/3 features clutter main target

**Verdict**: Monolithic might work for 2-3 screen apps, but Abundance has 5-10 screens + Phase 2/3 growth → modular architecture prevents technical debt.

### Why Not CocoaPods?

**CocoaPods Weaknesses**:
- ❌ Requires Ruby runtime (external dependency)
- ❌ Generates `.xcworkspace` (clutters project structure)
- ❌ Slower dependency resolution (compared to SPM)
- ❌ Legacy tool (Apple has deprecated CocoaPods support in favor of SPM)

**Verdict**: CocoaPods is outdated. SPM is the modern standard.

### Why Not Carthage?

**Carthage Weaknesses**:
- ❌ Requires manual framework linking (Xcode build phases)
- ❌ No automatic dependency resolution (must run `carthage update` manually)
- ❌ Binary frameworks only (no source packages)
- ❌ Slow build times (rebuilds frameworks frequently)

**Verdict**: Carthage is more complex than SPM without significant benefits.

---

## Module Structure

### Directory Layout

```
Abundance.xcodeproj/
├── App/                              # Main app target (iOS 26)
│   ├── AbundanceApp.swift            # @main entry point
│   ├── ContentView.swift             # Root navigation
│   ├── GoogleService-Info.plist      # Firebase config
│   └── Info.plist                    # App metadata
│
├── Packages/                         # Local Swift packages
│   ├── Features/                     # Feature modules (UI + ViewModels)
│   │   ├── CatalogFeature/           # Inventory list, search, item detail
│   │   │   ├── Sources/
│   │   │   │   ├── Views/            # CatalogView, ItemDetailView, SearchView
│   │   │   │   ├── ViewModels/       # CatalogViewModel, ItemDetailViewModel
│   │   │   │   └── CatalogFeature.swift
│   │   │   └── Tests/
│   │   │       └── CatalogViewModelTests.swift
│   │   │
│   │   ├── CameraFeature/            # Camera capture, Vision processing
│   │   │   ├── Sources/
│   │   │   │   ├── Views/            # CameraView, ObjectCaptureView
│   │   │   │   ├── ViewModels/       # CameraViewModel
│   │   │   │   └── CameraFeature.swift
│   │   │   └── Tests/
│   │   │       └── CameraViewModelTests.swift
│   │   │
│   │   ├── OnboardingFeature/        # Welcome, permissions, sign-in
│   │   │   ├── Sources/
│   │   │   │   ├── Views/            # WelcomeView, SignInView
│   │   │   │   ├── ViewModels/       # OnboardingViewModel, AuthViewModel
│   │   │   │   └── OnboardingFeature.swift
│   │   │   └── Tests/
│   │   │       └── AuthViewModelTests.swift
│   │   │
│   │   └── ProfileFeature/           # User settings, subscription, export
│   │       ├── Sources/
│   │       │   ├── Views/            # ProfileView, SettingsView, ExportView
│   │       │   ├── ViewModels/       # ProfileViewModel, ExportViewModel
│   │       │   └── ProfileFeature.swift
│   │       └── Tests/
│   │           └── ProfileViewModelTests.swift
│   │
│   ├── Core/                         # Core business logic (reusable)
│   │   ├── Models/                   # Codable models (CatalogItem, User, etc.)
│   │   │   ├── Sources/
│   │   │   │   ├── CatalogItem.swift
│   │   │   │   ├── User.swift
│   │   │   │   ├── AIAnalysis.swift
│   │   │   │   └── Models.swift
│   │   │   └── Tests/
│   │   │       └── CatalogItemTests.swift
│   │   │
│   │   ├── Networking/               # REST API client (Alamofire wrapper)
│   │   │   ├── Sources/
│   │   │   │   ├── APIClient.swift
│   │   │   │   ├── APIError.swift
│   │   │   │   └── Networking.swift
│   │   │   └── Tests/
│   │   │       └── APIClientTests.swift
│   │   │
│   │   ├── Firebase/                 # Firebase SDK wrappers
│   │   │   ├── Sources/
│   │   │   │   ├── AuthService.swift
│   │   │   │   ├── FirestoreService.swift
│   │   │   │   ├── StorageService.swift
│   │   │   │   ├── AnalyticsService.swift
│   │   │   │   └── Firebase.swift
│   │   │   └── Tests/
│   │   │       └── FirestoreServiceTests.swift
│   │   │
│   │   ├── Vision/                   # Vision Framework integration
│   │   │   ├── Sources/
│   │   │   │   ├── VisionService.swift
│   │   │   │   ├── ObjectDetector.swift
│   │   │   │   ├── BarcodeScanner.swift
│   │   │   │   └── Vision.swift
│   │   │   └── Tests/
│   │   │       └── ObjectDetectorTests.swift
│   │   │
│   │   └── Persistence/              # Local storage (UserDefaults, Keychain)
│   │       ├── Sources/
│   │       │   ├── SettingsService.swift
│   │       │   ├── KeychainService.swift
│   │       │   └── Persistence.swift
│   │       └── Tests/
│   │           └── KeychainServiceTests.swift
│   │
│   └── Shared/                       # Shared utilities
│       ├── Extensions/               # Swift/SwiftUI extensions
│       │   ├── Sources/
│       │   │   ├── View+Extensions.swift
│       │   │   ├── String+Extensions.swift
│       │   │   └── Extensions.swift
│       │   └── Tests/
│       │
│       ├── Constants/                # App constants (API URLs, colors, etc.)
│       │   └── Sources/
│       │       ├── AppConstants.swift
│       │       ├── ColorPalette.swift
│       │       └── Constants.swift
│       │
│       └── Components/               # Reusable UI components
│           ├── Sources/
│           │   ├── LoadingView.swift
│           │   ├── ErrorView.swift
│           │   ├── PrimaryButton.swift
│           │   └── Components.swift
│           └── Tests/
│
└── Tests/
    ├── AbundanceTests/               # Unit tests (ViewModels, business logic)
    ├── IntegrationTests/             # Integration tests (Networking, Firebase)
    └── UITests/                      # XCUITest E2E tests
```

---

## Package Dependencies

### Package.swift (Local Package Manifest)

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AbundancePackages",
    platforms: [.iOS(.v26)],
    products: [
        // Feature modules (UI + ViewModels)
        .library(name: "CatalogFeature", targets: ["CatalogFeature"]),
        .library(name: "CameraFeature", targets: ["CameraFeature"]),
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "ProfileFeature", targets: ["ProfileFeature"]),

        // Core modules (data, networking, Firebase, Vision)
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Firebase", targets: ["Firebase"]),
        .library(name: "Vision", targets: ["Vision"]),
        .library(name: "Persistence", targets: ["Persistence"]),

        // Shared utilities
        .library(name: "Extensions", targets: ["Extensions"]),
        .library(name: "Constants", targets: ["Constants"]),
        .library(name: "Components", targets: ["Components"]),
    ],
    dependencies: [
        // Third-party dependencies
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.5.0"),
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.9.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.11.0"),
    ],
    targets: [
        // Feature targets
        .target(
            name: "CatalogFeature",
            dependencies: [
                "Models",
                "Networking",
                "Firebase",
                "Extensions",
                "Constants",
                "Components"
            ]
        ),
        .testTarget(name: "CatalogFeatureTests", dependencies: ["CatalogFeature"]),

        .target(
            name: "CameraFeature",
            dependencies: [
                "Models",
                "Vision",
                "Networking",
                "Firebase",
                "Extensions",
                "Components"
            ]
        ),
        .testTarget(name: "CameraFeatureTests", dependencies: ["CameraFeature"]),

        .target(
            name: "OnboardingFeature",
            dependencies: [
                "Firebase",
                "Persistence",
                "Extensions",
                "Components"
            ]
        ),
        .testTarget(name: "OnboardingFeatureTests", dependencies: ["OnboardingFeature"]),

        .target(
            name: "ProfileFeature",
            dependencies: [
                "Models",
                "Firebase",
                "Extensions",
                "Components"
            ]
        ),
        .testTarget(name: "ProfileFeatureTests", dependencies: ["ProfileFeature"]),

        // Core targets
        .target(name: "Models", dependencies: []),
        .testTarget(name: "ModelsTests", dependencies: ["Models"]),

        .target(
            name: "Networking",
            dependencies: [
                "Models",
                .product(name: "Alamofire", package: "Alamofire")
            ]
        ),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking"]),

        .target(
            name: "Firebase",
            dependencies: [
                "Models",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ]
        ),
        .testTarget(name: "FirebaseTests", dependencies: ["Firebase"]),

        .target(name: "Vision", dependencies: ["Models"]),
        .testTarget(name: "VisionTests", dependencies: ["Vision"]),

        .target(name: "Persistence", dependencies: []),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence"]),

        // Shared targets
        .target(name: "Extensions", dependencies: []),
        .target(name: "Constants", dependencies: []),
        .target(
            name: "Components",
            dependencies: [
                .product(name: "Kingfisher", package: "Kingfisher")
            ]
        ),
    ]
)
```

---

## Module Dependency Rules

### Dependency Graph

```
App
 └─> Features (CatalogFeature, CameraFeature, OnboardingFeature, ProfileFeature)
      └─> Core (Models, Networking, Firebase, Vision, Persistence)
           └─> Shared (Extensions, Constants, Components)
```

### Rules

1. **App** depends on **Features** only (not Core or Shared directly)
2. **Features** depend on **Core** and **Shared** (not other Features)
3. **Core** depends on **Shared** only (not Features)
4. **Shared** depends on nothing (foundation layer)

**Enforcement**: Swift Package Manager enforces dependency rules at compile time (circular dependencies cause build errors).

---

## Benefits

### 1. Clear Separation of Concerns

- **Features**: UI + ViewModels (business logic) → isolated per feature
- **Core**: Data layer, networking, Firebase, Vision → shared across features
- **Shared**: Utilities, extensions, constants → foundation for everything

### 2. Testability

- Each package has its own test target → isolated unit tests
- Core modules (Networking, Firebase, Vision) testable independently
- Feature modules test ViewModels with mocked Core dependencies

### 3. Build Performance

- Xcode caches unchanged packages → faster incremental builds
- Parallel compilation (Xcode compiles independent packages concurrently)
- Example: Editing `CatalogFeature` doesn't rebuild `CameraFeature`

### 4. Reusability

- Core modules (Models, Networking, Firebase) shared across features
- Shared components (LoadingView, ErrorView, PrimaryButton) reused in all features
- No code duplication

### 5. Scalability (Phase 2/3)

- Phase 2 marketplace: Add `MarketplaceFeature` package without touching existing code
- Phase 3 PWA: Extract Core modules into shared framework (iOS + web)

### 6. Single Developer Velocity

- Clear structure → easy to navigate codebase
- Xcode "Show Package Dependencies" visualizes module graph
- Less cognitive load (work on one feature at a time)

---

## Consequences

### Positive Consequences

✅ **Clear Boundaries**: Features isolated → no accidental coupling
✅ **Fast Tests**: Isolated test targets → run tests for changed modules only
✅ **Reusable Code**: Core modules shared → DRY principle
✅ **Scalable**: Add features without modifying existing code
✅ **Fast Builds**: Xcode caches unchanged packages

### Negative Consequences

⚠️ **Initial Overhead**: Setting up packages takes time (mitigated by one-time setup)
⚠️ **Learning Curve**: New developers must understand package structure (mitigated by clear documentation)
⚠️ **Dependency Management**: Must update `Package.swift` when adding dependencies (mitigated by Xcode UI)

### Mitigations

**For Initial Overhead**:
- Create package template (boilerplate `Package.swift`, folder structure)
- Document package creation process in DESIGN-006

**For Learning Curve**:
- Create module dependency diagram (visual guide)
- Document package structure in README

**For Dependency Management**:
- Use Xcode UI to add dependencies (automatically updates `Package.swift`)
- Document dependency rules in this ADR

---

## Alternatives Considered

### Option 1: Monolithic (All Code in Main Target)

**Pros**: Simple, no package overhead
**Cons**: No module boundaries, tight coupling, slow tests, hard to scale
**Verdict**: Rejected (doesn't scale to Phase 2/3)

### Option 2: CocoaPods Workspace

**Pros**: Mature dependency manager
**Cons**: Requires Ruby, generates `.xcworkspace`, legacy tool
**Verdict**: Rejected (SPM is modern standard)

### Option 3: Carthage Frameworks

**Pros**: Binary frameworks (fast builds)
**Cons**: Manual linking, no automatic resolution, slow dependency updates
**Verdict**: Rejected (more complex than SPM)

### Option 4: Tuist (Project Generation)

**Pros**: Generates Xcode project from manifest, supports modular architecture
**Cons**: Third-party tool, learning curve, overkill for single developer
**Verdict**: Rejected (SPM native is simpler)

---

## References

- **Implementation Plan**: docs/plans/2025-11-08-stage-2.2-ios-client-architecture.md (Task 2)
- **Design Document**: docs/design/DESIGN-006-ios-module-dependencies.md (Detailed module diagram)
- **Tech Stack**: docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Swift Package Manager)
- **Related ADRs**:
  - ADR-010-swiftui-architecture-pattern.md (MVVM pattern)
  - ADR-013-dependency-injection-strategy.md (Constructor injection for modules)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial ADR, modular SPM architecture | iOS Architecture Expert |

---

**Decision**: ✅ **Modular Package Architecture (Swift Package Manager)**

**Justification**: Clear separation of concerns, testability, reusability, scalability. Swift Package Manager is Apple's modern standard for dependency management.

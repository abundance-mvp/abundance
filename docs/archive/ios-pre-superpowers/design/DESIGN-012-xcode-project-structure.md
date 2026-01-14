# DESIGN-012: Xcode Project Structure

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**References**:
- docs/adr/ADR-011-ios-module-structure.md (Modular packages)
- docs/plans/PLAN-SUMMARY-stage-2.2.md
**Status**: Production-Ready

---

## Directory Layout

```
Abundance.xcodeproj/
├── App/
│   ├── AbundanceApp.swift
│   ├── ContentView.swift
│   ├── GoogleService-Info.plist
│   └── Info.plist
│
├── Packages/
│   ├── Features/
│   │   ├── CatalogFeature/Package.swift
│   │   ├── CameraFeature/Package.swift
│   │   ├── OnboardingFeature/Package.swift
│   │   └── ProfileFeature/Package.swift
│   ├── Core/
│   │   ├── Models/Package.swift
│   │   ├── Networking/Package.swift
│   │   ├── Firebase/Package.swift
│   │   ├── Vision/Package.swift
│   │   └── Persistence/Package.swift
│   └── Shared/
│       ├── Components/Package.swift
│       ├── Extensions/Package.swift
│       └── Constants/Package.swift
│
└── Tests/
```

## Package.swift Example (CatalogFeature)

```swift
// swift-tools-version: 6.0
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
        .package(path: "../Shared/Components")
    ],
    targets: [
        .target(
            name: "CatalogFeature",
            dependencies: [
                .product(name: "Models", package: "Models"),
                .product(name: "Firebase", package: "Firebase"),
                .product(name: "Components", package: "Components")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CatalogFeatureTests",
            dependencies: ["CatalogFeature"]
        )
    ]
)
```

## Build Configurations

- **Debug**: Firebase Dev, verbose logging, SwiftLint strict
- **Staging**: Firebase Staging, TestFlight
- **Release**: Firebase Prod, App Store, optimizations enabled

## SwiftLint Configuration

```yaml
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - force_unwrapping
  - implicitly_unwrapped_optional
excluded:
  - Pods
  - .build
line_length: 120
identifier_name:
  min_length: 2
```

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial Xcode project structure | iOS Architecture Expert |
| 2025-11-11 | 1.1 | Fixed Swift 6 syntax: `.enableExperimentalFeature` → `.enableUpcomingFeature` (ref: RESEARCH-VALIDATION-stage-4.1.md) | iOS Architecture Expert |

---

**Status**: ✅ **Complete**

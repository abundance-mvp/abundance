# Module Scaffold Structure - Swift Package Template

**Created**: 2025-11-11
**Stage**: 4.1 - iOS Project Scaffolding
**References**:
- docs/adr/ADR-011-ios-module-structure.md (Modular packages)
- docs/design/DESIGN-012-xcode-project-structure.md (Project structure)
- docs/tech-stack/Package.swift (Root manifest)
**Status**: Production-Ready

---

## Overview

This document provides templates for creating new Swift Package modules in the Abundance iOS project. Use these templates to ensure consistency across all modules (Features, Core, Shared).

**Module Types**:
1. **Feature Modules**: UI + ViewModels + business logic (vertical slices)
2. **Core Modules**: Services, repositories, domain logic (horizontal layers)
3. **Shared Modules**: Reusable components, extensions, constants

---

## Quick Start: Creating a New Module

### Step 1: Choose Module Type and Location

**Feature Module**: `Packages/Features/{ModuleName}/`
**Core Module**: `Packages/Core/{ModuleName}/`
**Shared Module**: `Packages/Shared/{ModuleName}/`

### Step 2: Create Directory Structure

```bash
# Example: Creating a new Feature module called "ExportFeature"
mkdir -p Packages/Features/ExportFeature/Sources/ExportFeature/Views
mkdir -p Packages/Features/ExportFeature/Sources/ExportFeature/ViewModels
mkdir -p Packages/Features/ExportFeature/Tests/ExportFeatureTests/ViewModels
```

### Step 3: Create Package.swift

Copy the appropriate template below and customize for your module.

### Step 4: Add Module to Root Package.swift

Add your new module to the root `Package.swift` products and targets lists.

---

## Template 1: Feature Module Package.swift

**Use For**: CatalogFeature, CameraFeature, OnboardingFeature, ProfileFeature, ExportFeature, etc.

**Location**: `Packages/Features/{FeatureName}/Package.swift`

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ExampleFeature",
    platforms: [
        .iOS(.v26) // iOS 26.0+ minimum deployment target
    ],
    products: [
        .library(
            name: "ExampleFeature",
            targets: ["ExampleFeature"]
        )
    ],
    dependencies: [
        // MARK: - Core Dependencies
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Firebase"),
        .package(path: "../../Core/Networking"),

        // MARK: - Shared Dependencies
        .package(path: "../../Shared/Components"),
        .package(path: "../../Shared/Extensions")
    ],
    targets: [
        // MARK: - Main Target
        .target(
            name: "ExampleFeature",
            dependencies: [
                .product(name: "Models", package: "Models"),
                .product(name: "FirebaseIntegration", package: "Firebase"),
                .product(name: "Networking", package: "Networking"),
                .product(name: "Components", package: "Components"),
                .product(name: "Extensions", package: "Extensions")
            ],
            path: "Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency") // Swift 6 strict concurrency
            ]
        ),

        // MARK: - Test Target
        .testTarget(
            name: "ExampleFeatureTests",
            dependencies: ["ExampleFeature"],
            path: "Tests"
        )
    ]
)
```

**File Structure**:
```
ExampleFeature/
├── Package.swift
├── Sources/
│   └── ExampleFeature/
│       ├── Views/
│       │   ├── ExampleView.swift
│       │   └── ExampleDetailView.swift
│       ├── ViewModels/
│       │   └── ExampleViewModel.swift
│       └── ExampleFeature.swift (optional entry point)
└── Tests/
    └── ExampleFeatureTests/
        └── ViewModels/
            └── ExampleViewModelTests.swift
```

---

## Template 2: Core Module Package.swift

**Use For**: Models, Networking, Firebase, Vision, Persistence, etc.

**Location**: `Packages/Core/{ModuleName}/Package.swift`

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ExampleService",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "ExampleService",
            targets: ["ExampleService"]
        )
    ],
    dependencies: [
        // MARK: - Core Dependencies (if needed)
        .package(path: "../Models"),

        // MARK: - Shared Dependencies
        .package(path: "../../Shared/Extensions"),

        // MARK: - External Dependencies (if needed)
        // Example: Firebase, Alamofire
        // .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.11.0")
    ],
    targets: [
        // MARK: - Main Target
        .target(
            name: "ExampleService",
            dependencies: [
                .product(name: "Models", package: "Models"),
                .product(name: "Extensions", package: "Extensions")
                // .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),

        // MARK: - Test Target
        .testTarget(
            name: "ExampleServiceTests",
            dependencies: ["ExampleService"],
            path: "Tests"
        )
    ]
)
```

**File Structure**:
```
ExampleService/
├── Package.swift
├── Sources/
│   └── ExampleService/
│       ├── ExampleService.swift
│       ├── ExampleRepository.swift
│       └── ExampleError.swift
└── Tests/
    └── ExampleServiceTests/
        └── ExampleServiceTests.swift
```

---

## Template 3: Shared Module Package.swift

**Use For**: Components, Extensions, Constants, etc.

**Location**: `Packages/Shared/{ModuleName}/Package.swift`

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ExampleUtility",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "ExampleUtility",
            targets: ["ExampleUtility"]
        )
    ],
    dependencies: [
        // MARK: - No Dependencies (Shared modules should be self-contained)
        // Only depend on Foundation/SwiftUI frameworks
    ],
    targets: [
        // MARK: - Main Target
        .target(
            name: "ExampleUtility",
            dependencies: [],
            path: "Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),

        // MARK: - Test Target
        .testTarget(
            name: "ExampleUtilityTests",
            dependencies: ["ExampleUtility"],
            path: "Tests"
        )
    ]
)
```

**File Structure**:
```
ExampleUtility/
├── Package.swift
├── Sources/
│   └── ExampleUtility/
│       ├── HelperFunction.swift
│       └── UtilityExtension.swift
└── Tests/
    └── ExampleUtilityTests/
        └── HelperFunctionTests.swift
```

---

## Module Naming Conventions

### Module Names
- **Features**: `{Name}Feature` (e.g., `CatalogFeature`, `ExportFeature`)
- **Core**: `{Name}` or `{Name}Service` (e.g., `Networking`, `VisionService`)
- **Shared**: `{Name}` (e.g., `Components`, `Extensions`)

### File Names
- **Views**: `{Name}View.swift` (e.g., `CatalogView.swift`)
- **ViewModels**: `{Name}ViewModel.swift` (e.g., `CatalogViewModel.swift`)
- **Models**: `{Name}.swift` (e.g., `CatalogItem.swift`)
- **Protocols**: `{Name}.swift` or `{Name}Protocol.swift` (e.g., `CatalogRepository.swift`)
- **Services**: `{Name}Service.swift` (e.g., `VisionService.swift`)
- **Extensions**: `{Type}+{Category}.swift` (e.g., `Date+Extensions.swift`)

### Type Names (Swift Code)
- **Classes/Structs/Protocols**: `PascalCase` (e.g., `CatalogViewModel`, `CatalogItem`)
- **Functions/Variables**: `camelCase` (e.g., `fetchItems()`, `isLoading`)
- **Constants**: `camelCase` or `UPPER_CASE` (e.g., `defaultTimeout` or `API_KEY`)

---

## Dependency Rules

### Allowed Dependencies

**Features** can depend on:
- ✅ Core modules (Models, Networking, Firebase, Vision, Persistence)
- ✅ Shared modules (Components, Extensions, Constants)
- ❌ Other Features (avoid circular dependencies)

**Core** can depend on:
- ✅ Other Core modules (e.g., Networking depends on Models)
- ✅ Shared modules (Extensions, Constants)
- ❌ Features

**Shared** can depend on:
- ✅ Nothing (self-contained, only Foundation/SwiftUI)
- ❌ Features
- ❌ Core

### Dependency Graph

```
App
 └─→ Features (CatalogFeature, CameraFeature, etc.)
      └─→ Core (Models, Networking, Firebase, Vision, Persistence)
           └─→ Shared (Components, Extensions, Constants)
```

---

## Adding a New Module to Root Package.swift

After creating your module, add it to the root `docs/tech-stack/Package.swift`:

### Step 1: Add to `products` Array

```swift
products: [
    // ... existing products
    .library(name: "ExampleFeature", targets: ["ExampleFeature"]),
]
```

### Step 2: Add to `targets` Array

```swift
targets: [
    // ... existing targets
    .target(
        name: "ExampleFeature",
        dependencies: [
            "Models",
            "FirebaseIntegration",
            "Components"
        ],
        path: "Packages/Features/ExampleFeature/Sources",
        swiftSettings: [
            .enableUpcomingFeature("StrictConcurrency")
        ]
    ),
    .testTarget(
        name: "ExampleFeatureTests",
        dependencies: ["ExampleFeature"],
        path: "Packages/Features/ExampleFeature/Tests"
    ),
]
```

### Step 3: Verify Build

```bash
swift package resolve
swift build
```

---

## Example: Complete Feature Module (ExportFeature)

### Directory Structure

```bash
mkdir -p Packages/Features/ExportFeature/Sources/ExportFeature/Views
mkdir -p Packages/Features/ExportFeature/Sources/ExportFeature/ViewModels
mkdir -p Packages/Features/ExportFeature/Tests/ExportFeatureTests/ViewModels
touch Packages/Features/ExportFeature/Package.swift
touch Packages/Features/ExportFeature/Sources/ExportFeature/Views/ExportView.swift
touch Packages/Features/ExportFeature/Sources/ExportFeature/ViewModels/ExportViewModel.swift
touch Packages/Features/ExportFeature/Tests/ExportFeatureTests/ViewModels/ExportViewModelTests.swift
```

### Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ExportFeature",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "ExportFeature", targets: ["ExportFeature"])
    ],
    dependencies: [
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Firebase"),
        .package(path: "../../Shared/Components")
    ],
    targets: [
        .target(
            name: "ExportFeature",
            dependencies: [
                .product(name: "Models", package: "Models"),
                .product(name: "FirebaseIntegration", package: "Firebase"),
                .product(name: "Components", package: "Components")
            ],
            path: "Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ExportFeatureTests",
            dependencies: ["ExportFeature"],
            path: "Tests"
        )
    ]
)
```

### ExportView.swift

```swift
import SwiftUI
import Models
import Components

struct ExportView: View {
    @State private var viewModel: ExportViewModel

    init(repository: ExportRepository = FirebaseExportRepository()) {
        self._viewModel = State(initialValue: ExportViewModel(repository: repository))
    }

    var body: some View {
        VStack {
            Text("Export Feature")
            PrimaryButton(title: "Export CSV", action: viewModel.exportCSV)
        }
    }
}
```

### ExportViewModel.swift

```swift
import Foundation
import Models
import Observation

@Observable
@MainActor
class ExportViewModel {
    var isExporting: Bool = false
    var error: Error?

    private let repository: ExportRepository

    init(repository: ExportRepository) {
        self.repository = repository
    }

    func exportCSV() async {
        isExporting = true
        defer { isExporting = false }

        do {
            try await repository.exportToCSV()
        } catch {
            self.error = error
        }
    }
}
```

---

## Acceptance Criteria

### Module Creation Checklist

- [ ] Package.swift created with correct Swift 6 syntax (`.enableUpcomingFeature("StrictConcurrency")`)
- [ ] iOS 26 platform specified (`.iOS(.v26)`)
- [ ] Dependencies follow allowed rules (Features → Core → Shared)
- [ ] Test target included
- [ ] Module added to root Package.swift
- [ ] `swift package resolve` succeeds
- [ ] `swift build` succeeds without errors

---

## References

### Architecture Decision Records
- docs/adr/ADR-011-ios-module-structure.md (Modular packages)

### Design Documents
- docs/design/DESIGN-012-xcode-project-structure.md (Project structure)
- docs/tech-stack/Package.swift (Root manifest)

### Validation
- docs/validation/RESEARCH-VALIDATION-stage-4.1.md (Swift 6 syntax verified)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0 | Initial module scaffold templates | iOS Architecture Expert |

---

**Status**: ✅ **Production-Ready**

Complete templates for creating new Feature, Core, and Shared modules with Swift 6 support and modular architecture.

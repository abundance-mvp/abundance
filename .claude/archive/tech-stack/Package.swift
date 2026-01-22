// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Abundance iOS App - Root Package Manifest
// Created: 2025-11-11
// Stage: 4.1 - iOS Project Scaffolding
// References:
//   - docs/adr/ADR-011-ios-module-structure.md (Modular packages)
//   - docs/design/DESIGN-012-xcode-project-structure.md (Project structure)
//   - docs/validation/RESEARCH-VALIDATION-stage-4.1.md (Verified syntax)

import PackageDescription

let package = Package(
    name: "Abundance",
    platforms: [
        .iOS(.v26) // iOS 26.0+ minimum deployment target (released Sept 15, 2025)
    ],
    products: [
        // MARK: - Feature Modules
        .library(name: "CatalogFeature", targets: ["CatalogFeature"]),
        .library(name: "CameraFeature", targets: ["CameraFeature"]),
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "ProfileFeature", targets: ["ProfileFeature"]),

        // MARK: - Core Modules
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "FirebaseIntegration", targets: ["FirebaseIntegration"]),
        .library(name: "VisionProcessing", targets: ["VisionProcessing"]),
        .library(name: "Persistence", targets: ["Persistence"]),

        // MARK: - Shared Modules
        .library(name: "Components", targets: ["Components"]),
        .library(name: "Extensions", targets: ["Extensions"]),
        .library(name: "Constants", targets: ["Constants"])
    ],
    dependencies: [
        // MARK: - Firebase iOS SDK
        // Version: 11.11.0+ (async/await support, requires @preconcurrency workaround)
        // Source: RESEARCH-VALIDATION-stage-4.1.md, Claim 10
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.11.0"),

        // MARK: - HTTP Networking
        // Version: 5.9.0+ (Swift 6 compatible, async/await)
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),

        // MARK: - Image Loading & Caching
        // Version: 7.11.0+ (Swift 6 compatible, async/await)
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.11.0")
    ],
    targets: [
        // MARK: - Feature Targets

        .target(
            name: "CatalogFeature",
            dependencies: [
                "Models",
                "FirebaseIntegration",
                "Components",
                "Extensions",
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            path: "Packages/Features/CatalogFeature/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency") // Swift 6 strict concurrency
            ]
        ),
        .testTarget(
            name: "CatalogFeatureTests",
            dependencies: ["CatalogFeature"],
            path: "Packages/Features/CatalogFeature/Tests"
        ),

        .target(
            name: "CameraFeature",
            dependencies: [
                "Models",
                "VisionProcessing",
                "FirebaseIntegration",
                "Components",
                "Extensions"
            ],
            path: "Packages/Features/CameraFeature/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CameraFeatureTests",
            dependencies: ["CameraFeature"],
            path: "Packages/Features/CameraFeature/Tests"
        ),

        .target(
            name: "OnboardingFeature",
            dependencies: [
                "Models",
                "FirebaseIntegration",
                "Components",
                "Extensions"
            ],
            path: "Packages/Features/OnboardingFeature/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "OnboardingFeatureTests",
            dependencies: ["OnboardingFeature"],
            path: "Packages/Features/OnboardingFeature/Tests"
        ),

        .target(
            name: "ProfileFeature",
            dependencies: [
                "Models",
                "FirebaseIntegration",
                "Components",
                "Extensions"
            ],
            path: "Packages/Features/ProfileFeature/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ProfileFeatureTests",
            dependencies: ["ProfileFeature"],
            path: "Packages/Features/ProfileFeature/Tests"
        ),

        // MARK: - Core Targets

        .target(
            name: "Models",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "Packages/Core/Models/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ModelsTests",
            dependencies: ["Models"],
            path: "Packages/Core/Models/Tests"
        ),

        .target(
            name: "Networking",
            dependencies: [
                "Models",
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Packages/Core/Networking/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"],
            path: "Packages/Core/Networking/Tests"
        ),

        .target(
            name: "FirebaseIntegration",
            dependencies: [
                "Models",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "Packages/Core/Firebase/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "FirebaseIntegrationTests",
            dependencies: ["FirebaseIntegration"],
            path: "Packages/Core/Firebase/Tests"
        ),

        .target(
            name: "VisionProcessing",
            dependencies: [
                "Models",
                "Extensions"
            ],
            path: "Packages/Core/Vision/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VisionProcessingTests",
            dependencies: ["VisionProcessing"],
            path: "Packages/Core/Vision/Tests"
        ),

        .target(
            name: "Persistence",
            dependencies: [
                "Models",
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "Packages/Core/Persistence/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Persistence"],
            path: "Packages/Core/Persistence/Tests"
        ),

        // MARK: - Shared Targets

        .target(
            name: "Components",
            dependencies: [
                "Extensions",
                "Constants"
            ],
            path: "Packages/Shared/Components/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ComponentsTests",
            dependencies: ["Components"],
            path: "Packages/Shared/Components/Tests"
        ),

        .target(
            name: "Extensions",
            dependencies: [],
            path: "Packages/Shared/Extensions/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ExtensionsTests",
            dependencies: ["Extensions"],
            path: "Packages/Shared/Extensions/Tests"
        ),

        .target(
            name: "Constants",
            dependencies: [],
            path: "Packages/Shared/Constants/Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ConstantsTests",
            dependencies: ["Constants"],
            path: "Packages/Shared/Constants/Tests"
        )
    ]
)

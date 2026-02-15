// swift-tools-version: 6.0
import PackageDescription

let package: Package = Package(
    name: "Abundance",
    platforms: [.iOS(.v18), .macOS(.v14)], // iOS 18 and macOS 14 for @Observable support
    products: [
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "CameraFeature", targets: ["CameraFeature"]),
        .library(name: "CollectionFeature", targets: ["CollectionFeature"]),
        .library(name: "ProfileFeature", targets: ["ProfileFeature"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "VisionCore", targets: ["VisionCore"]),
        .library(name: "EdgeTAMFeature", targets: ["EdgeTAMFeature"]),
        .library(name: "Core", targets: ["Core"]),
        .executable(name: "AbundanceApp", targets: ["AbundanceApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.11.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.28.2")
    ],
    targets: [
        // Features
        .target(
            name: "OnboardingFeature",
            dependencies: [
                "CameraFeature",
                "Core",
                "Persistence",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "OnboardingFeatureTests",
            dependencies: [
                "OnboardingFeature",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ]
        ),
        .target(
            name: "CameraFeature",
            dependencies: [
                "Core",
                "Persistence",
                "VisionCore",
                "EdgeTAMFeature",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CameraFeatureTests",
            dependencies: [
                "CameraFeature",
                "Persistence",
                "VisionCore",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ]
        ),
        .target(
            name: "CollectionFeature",
            dependencies: [
                "Core",
                "CameraFeature",
                "Persistence",
                "VisionCore",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CollectionFeatureTests",
            dependencies: [
                "CollectionFeature",
                "Persistence",
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ]
        ),
        .target(
            name: "ProfileFeature",
            dependencies: [
                "Core",
                "Persistence",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ProfileFeatureTests",
            dependencies: ["ProfileFeature"]
        ),

        // Core
        .target(
            name: "Persistence",
            dependencies: [
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: [
                "Persistence",
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ]
        ),
        .target(
            name: "VisionCore",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VisionCoreTests",
            dependencies: ["VisionCore"],
            resources: [
                .copy("Resources")
            ]
        ),
        .target(
            name: "EdgeTAMFeature",
            dependencies: ["VisionCore"],
            resources: [
                .copy("Resources/edgetam_image_encoder.mlpackage"),
                .copy("Resources/edgetam_prompt_encoder.mlpackage"),
                .copy("Resources/edgetam_mask_decoder.mlpackage"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EdgeTAMFeatureTests",
            dependencies: ["EdgeTAMFeature"]
        ),
        .target(
            name: "Core",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        ),
        .testTarget(
            name: "AXeTests",
            dependencies: ["Core"]
        ),
        .testTarget(
            name: "PipelineTests",
            dependencies: ["Core", "CameraFeature", "Persistence", "CollectionFeature"]
        ),

        // App
        .executableTarget(
            name: "AbundanceApp",
            dependencies: [
                "OnboardingFeature",
                "CameraFeature",
                "CollectionFeature",
                "ProfileFeature",
                "Persistence",
                "VisionCore",
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: "App",
            exclude: ["Info.plist"],
            resources: [
                .process("GoogleService-Info.plist"),
                .process("Assets.xcassets"),
                .process("DebugResources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)

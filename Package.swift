// swift-tools-version: 6.0
import PackageDescription

let package: Package = Package(
    name: "Abundance",
    platforms: [.iOS(.v18), .macOS(.v14)], // iOS 18 and macOS 14 for @Observable support
    products: [
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "CameraFeature", targets: ["CameraFeature"]),
        .library(name: "InventoryFeature", targets: ["InventoryFeature"]),
        .library(name: "ProfileFeature", targets: ["ProfileFeature"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "VisionCore", targets: ["VisionCore"]),
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
                "Persistence",
                "VisionCore",
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
            name: "InventoryFeature",
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
            name: "InventoryFeatureTests",
            dependencies: [
                "InventoryFeature",
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
            resources: [
                .copy("Resources/yolo11n.mlmodelc")
            ],
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

        // App
        .executableTarget(
            name: "AbundanceApp",
            dependencies: [
                "OnboardingFeature",
                "CameraFeature",
                "InventoryFeature",
                "Persistence",
                "VisionCore",
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: "App",
            resources: [
                .process("GoogleService-Info.plist"),
                .process("Assets.xcassets")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)

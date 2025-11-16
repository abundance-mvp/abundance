// swift-tools-version: 6.0
import PackageDescription

let package: Package = Package(
    name: "Abundance",
    platforms: [.iOS(.v18), .macOS(.v14)], // iOS 18 and macOS 14 for @Observable support
    products: [
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "CameraFeature", targets: ["CameraFeature"]),
        .library(name: "InventoryFeature", targets: ["InventoryFeature"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "VisionCore", targets: ["VisionCore"]),
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
                "VisionCore"
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
                "VisionCore"
            ]
        ),
        .target(
            name: "InventoryFeature",
            dependencies: [
                "Persistence",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
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
                .process("GoogleService-Info.plist")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)

// swift-tools-version: 6.0
import PackageDescription

let package: Package = Package(
    name: "Abundance",
    platforms: [.iOS(.v18), .macOS(.v14)], // iOS 18 and macOS 14 for @Observable support
    products: [
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "CameraFeature", targets: ["CameraFeature"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "VisionCore", targets: ["VisionCore"])
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
            dependencies: ["Persistence"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CameraFeatureTests",
            dependencies: [
                "CameraFeature",
                "Persistence"
            ]
        ),

        // Core
        .target(
            name: "Persistence",
            dependencies: [
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
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
            dependencies: ["VisionCore"]
        )
    ]
)

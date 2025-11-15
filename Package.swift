// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Abundance",
    platforms: [.iOS(.v18), .macOS(.v10_15)], // iOS 26 maps to iOS 18 in Package.swift
    products: [
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "Persistence", targets: ["Persistence"])
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
            dependencies: ["OnboardingFeature"]
        ),

        // Core
        .target(
            name: "Persistence",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Persistence"]
        )
    ]
)

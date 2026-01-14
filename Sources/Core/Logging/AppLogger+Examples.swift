// AppLogger+Examples.swift
// Usage examples for AppLogger
//
// This file demonstrates how to use AppLogger throughout the Abundance app
// Copy these patterns into your ViewModels, Views, and Services

import Foundation

// MARK: - Example 1: ViewModel with logging

/*
class CatalogViewModel: ObservableObject {
    @Published var items: [CatalogItem] = []
    @Published var isLoading = false

    func fetchItems() async {
        let startTime = Date()
        AppLogger.log(.firestoreQueryStarted(collection: "items", filter: "userId == currentUser"))

        isLoading = true

        do {
            let items = try await AppLogger.measureAsync("fetchItems") {
                try await firestoreService.fetchItems()
            }

            let duration = Date().timeIntervalSince(startTime)
            AppLogger.log(.firestoreQueryCompleted(
                collection: "items",
                resultCount: items.count,
                duration: duration
            ))

            // SPEC CHECK: Per mvp-vision-features, data should load quickly
            if duration > 2.0 {
                AppLogger.log(.specViolation(
                    spec: "mvp-vision-features",
                    section: "Data Loading",
                    expected: "< 2 seconds",
                    actual: "\(duration)s",
                    severity: .medium
                ))
            }

            self.items = items
        } catch {
            AppLogger.log(.dataLoadFailed(
                type: "CatalogItem",
                error: error,
                context: ["userId": "currentUserId"]
            ))
        }

        isLoading = false
    }
}
*/

// MARK: - Example 2: SwiftUI View with button logging

/*
struct HomeView: View {
    @StateObject var viewModel = CatalogViewModel()

    var body: some View {
        VStack {
            Button("Catalog Item") {
                AppLogger.log(.buttonTapped(
                    button: "Catalog Item",
                    screen: "HomeView"
                ))

                let success = viewModel.startCataloging()

                if !success {
                    AppLogger.log(.buttonUnresponsive(
                        button: "Catalog Item",
                        screen: "HomeView",
                        reason: "User not authenticated"
                    ))
                }
            }
        }
        .onAppear {
            AppLogger.log(.screenAppeared(screen: "HomeView"))
        }
    }
}
*/

// MARK: - Example 3: Vision Framework integration

/*
class VisionService {
    func detectObjects(in image: UIImage) async throws -> VisionResult {
        let imageSize = image.jpegData(compressionQuality: 1.0)?.count ?? 0

        AppLogger.log(.visionDetectionStarted(imageSize: imageSize))

        do {
            let result = try await AppLogger.measureAsync("visionDetection") {
                try await performVisionDetection(image)
            }

            AppLogger.log(.visionDetectionCompleted(
                detectedClass: result.detectedClass,
                confidence: result.confidence,
                duration: result.duration
            ))

            // SPEC CHECK: Per mvp-vision-features, processing should be < 6 seconds
            if result.duration > 6.0 {
                AppLogger.log(.specViolation(
                    spec: "mvp-vision-features",
                    section: "Processing Time",
                    expected: "< 6 seconds",
                    actual: "\(result.duration)s",
                    severity: .high
                ))
            }

            return result
        } catch {
            AppLogger.log(.visionDetectionFailed(error: error, imageSize: imageSize))
            throw error
        }
    }

    func detectBarcode(in image: UIImage) async -> String? {
        do {
            let barcode = try await performBarcodeDetection(image)
            AppLogger.log(.barcodeDetected(type: barcode.type, value: barcode.value))
            return barcode.value
        } catch {
            AppLogger.log(.barcodeDetectionFailed(reason: error.localizedDescription))
            return nil
        }
    }
}
*/

// MARK: - Example 4: Silent failure detection

/*
struct CatalogItemCell: View {
    let item: CatalogItem
    @State private var tapCount = 0

    var body: some View {
        HStack {
            Text(item.name)
        }
        .onTapGesture {
            tapCount += 1

            // Detect if button is not responding after multiple taps
            if tapCount > 3 {
                AppLogger.log(.silentFailure(
                    feature: "Catalog Item Detail Navigation",
                    expectedBehavior: "Tap once to open detail view",
                    actualBehavior: "Tapped 3+ times, detail view did not open",
                    reproSteps: [
                        "1. Open Catalog screen",
                        "2. Tap on any item",
                        "3. Detail view does not appear"
                    ]
                ))
            }

            // Navigate to detail
            navigateToDetail(item)
        }
    }
}
*/

// MARK: - Example 5: Authentication flow

/*
class AuthViewModel: ObservableObject {
    func signInWithApple() async {
        AppLogger.log(.authSignInStarted(provider: "Apple"))

        let startTime = Date()

        do {
            let result = try await performAppleSignIn()

            let duration = Date().timeIntervalSince(startTime)
            // SECURITY: userId is automatically sanitized by AppLogger
            // Only first 4 chars + hash suffix appear in logs
            AppLogger.log(.authSignInCompleted(
                userId: result.userId,  // Sanitized automatically
                duration: duration
            ))

        } catch {
            AppLogger.log(.authSignInFailed(
                provider: "Apple",
                error: error
            ))
        }
    }
}
*/

// MARK: - Example 6: Performance monitoring

/*
class ImageProcessor {
    func processLargeImage(_ image: UIImage) {
        let result = AppLogger.measure("imageProcessing") {
            // Expensive image processing
            return processImage(image)
        }

        // If processing is slow, log it
        if result.duration > 1000 { // 1 second
            AppLogger.log(.performanceMetric(
                operation: "imageProcessing",
                duration: result.duration,
                metadata: [
                    "imageSize": image.size,
                    "memoryUsage": getMemoryUsage()
                ]
            ))
        }
    }
}
*/

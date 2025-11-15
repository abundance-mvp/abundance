# CODE-EXAMPLE-003: Firebase iOS SDK Integration Patterns

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**Purpose**: Firebase Auth, Firestore, Storage, Analytics integration patterns

---

## Overview

This document provides Firebase iOS SDK integration patterns for the Abundance app, following ADR-005 (Authentication Strategy), ADR-006 (Database Selection), and ADR-008 (Image Storage Architecture).

**Firebase iOS SDK Version**: 11.11.0+ (Swift 6 compatible)
**Integration Areas**: Auth, Firestore, Storage, Analytics

---

## Firebase iOS SDK Setup

### Package.swift Dependencies

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.11.0")
],
targets: [
    .target(
        name: "Firebase",
        dependencies: [
            .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
            .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
        ]
    )
]
```

### App Initialization

```swift
import SwiftUI
import FirebaseCore

@main
struct AbundanceApp: App {
    init() {
        // Configure Firebase on app launch
        FirebaseApp.configure()

        // Enable Firestore offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## Pattern 1: Apple Sign-In + Firebase Auth

### Purpose
Authenticate users with Apple Sign-In, exchange Apple ID token for Firebase token, store securely in Keychain.

### Implementation

```swift
import AuthenticationServices
import FirebaseAuth
import CryptoKit

// MARK: - Apple Sign-In Coordinator

@MainActor
class AppleSignInCoordinator: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var error: Error?

    private var currentNonce: String?

    /// Start Apple Sign-In flow
    func signIn() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    /// Sign out
    func signOut() async throws {
        try Auth.auth().signOut()
        isAuthenticated = false

        // Clear Keychain token
        try KeychainHelper.delete(key: "firebase-id-token")
    }

    // MARK: - Private Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }

            // Exchange Apple token for Firebase token
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            Task {
                do {
                    let result = try await Auth.auth().signIn(with: credential)
                    let firebaseToken = try await result.user.getIDToken()

                    // Store Firebase ID token in Keychain
                    try KeychainHelper.save(key: "firebase-id-token", value: firebaseToken)

                    isAuthenticated = true
                } catch {
                    self.error = error
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.error = error
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window scene available")
        }
        return window
    }
}
```

### Keychain Helper

```swift
import Foundation
import Security

struct KeychainHelper {
    /// Save value to Keychain
    static func save(key: String, value: String) throws {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Retrieve value from Keychain
    static func get(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }

        return value
    }

    /// Delete value from Keychain
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

enum KeychainError: Error {
    case unhandledError(status: OSStatus)
    case unexpectedData
}
```

---

## Pattern 2: Firestore Real-Time Listeners with Combine

### Purpose
Listen to Firestore document/collection changes in real-time, convert snapshots to Combine publishers.

### Implementation

```swift
import FirebaseFirestore
import Combine

// MARK: - Firestore Combine Extensions

extension Query {
    /// Convert Firestore query to Combine publisher
    func publisher<T: Decodable>() -> AnyPublisher<[T], Error> {
        let subject = PassthroughSubject<[T], Error>()

        let listener = addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }

            do {
                let items = try documents.map { doc in
                    try doc.data(as: T.self)
                }
                subject.send(items)
            } catch {
                subject.send(completion: .failure(error))
            }
        }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }
}

extension DocumentReference {
    /// Convert Firestore document to Combine publisher
    func publisher<T: Decodable>() -> AnyPublisher<T?, Error> {
        let subject = PassthroughSubject<T?, Error>()

        let listener = addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }

            guard let snapshot = snapshot else {
                subject.send(nil)
                return
            }

            do {
                let item = try snapshot.data(as: T.self)
                subject.send(item)
            } catch {
                subject.send(completion: .failure(error))
            }
        }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }
}
```

### Usage in Repository

```swift
class FirestoreCatalogRepository: CatalogRepository {
    private let db = Firestore.firestore()

    func observeItems() -> AnyPublisher<[CatalogItem], Never> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Just([]).eraseToAnyPublisher()
        }

        return db.collection("items")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .publisher() // Use Combine extension
            .catch { error -> Just<[CatalogItem]> in
                print("Firestore observe error: \(error)")
                return Just([])
            }
            .eraseToAnyPublisher()
    }
}
```

### Offline Persistence Configuration

```swift
// Enable offline persistence (in AppDelegate or @main App init)
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true
settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
Firestore.firestore().settings = settings
```

**Benefits**:
- Writes queued when offline, synced when online
- Reads return cached data when offline
- Real-time listeners continue working offline

---

## Pattern 3: Firebase Storage Photo Uploads

### Purpose
Upload cropped object images from Vision Framework to Firebase Storage, generate signed URLs.

### Implementation

```swift
import FirebaseStorage
import UIKit

// MARK: - Image Storage Service

actor ImageStorageService {
    private let storage = Storage.storage()

    /// Upload image to Firebase Storage
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - userId: User ID (for path)
    ///   - itemId: Item ID (for path)
    /// - Returns: Public download URL
    func uploadImage(_ image: UIImage, userId: String, itemId: String) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.compressionFailed
        }

        let path = "items/\(userId)/\(itemId)_cropped.jpg"
        let storageRef = storage.reference().child(path)

        // Upload with metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "userId": userId,
            "itemId": itemId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }

    /// Upload with progress tracking
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - userId: User ID
    ///   - itemId: Item ID
    ///   - progress: Progress closure (0.0-1.0)
    /// - Returns: Public download URL
    func uploadImageWithProgress(
        _ image: UIImage,
        userId: String,
        itemId: String,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.compressionFailed
        }

        let path = "items/\(userId)/\(itemId)_cropped.jpg"
        let storageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Start upload task
        let uploadTask = storageRef.putData(imageData, metadata: metadata)

        // Observe progress
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)
            progress(percentComplete)
        }

        // Await completion
        _ = try await uploadTask
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }

    /// Delete image from Firebase Storage
    /// - Parameters:
    ///   - userId: User ID
    ///   - itemId: Item ID
    func deleteImage(userId: String, itemId: String) async throws {
        let path = "items/\(userId)/\(itemId)_cropped.jpg"
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
    }
}

enum StorageError: Error, LocalizedError {
    case compressionFailed
    case uploadFailed
    case downloadURLFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed:
            return "Image upload failed"
        case .downloadURLFailed:
            return "Failed to get download URL"
        }
    }
}
```

### Usage in ViewModel

```swift
@MainActor
class CameraViewModel: ObservableObject {
    @Published var uploadProgress: Double = 0.0
    @Published var uploadedImageURL: URL?

    private let storageService: ImageStorageService

    init(storageService: ImageStorageService = ImageStorageService()) {
        self.storageService = storageService
    }

    func uploadCroppedImage(_ image: UIImage, userId: String, itemId: String) async {
        do {
            let url = try await storageService.uploadImageWithProgress(
                image,
                userId: userId,
                itemId: itemId
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.uploadProgress = progress
                }
            }

            self.uploadedImageURL = url
        } catch {
            // Handle error
        }
    }
}
```

---

## Pattern 4: Firebase Analytics Event Tracking

### Purpose
Track user behavior with Firebase Analytics for product insights.

### Implementation

```swift
import FirebaseAnalytics

// MARK: - Analytics Service

struct AnalyticsService {
    /// Log custom event
    /// - Parameters:
    ///   - name: Event name
    ///   - parameters: Event parameters (optional)
    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    // MARK: - Predefined Events

    /// Log app open
    static func logAppOpen() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }

    /// Log sign-in
    /// - Parameter method: Sign-in method (e.g., "apple")
    static func logSignIn(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    /// Log item captured
    /// - Parameter category: Item category
    static func logItemCaptured(category: String) {
        logEvent("item_captured", parameters: [
            "category": category,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    /// Log item saved
    /// - Parameters:
    ///   - itemId: Item ID
    ///   - category: Item category
    ///   - estimatedValue: Estimated value (optional)
    static func logItemSaved(itemId: String, category: String, estimatedValue: Double?) {
        var parameters: [String: Any] = [
            "item_id": itemId,
            "category": category
        ]

        if let value = estimatedValue {
            parameters["estimated_value"] = value
        }

        logEvent("item_saved", parameters: parameters)
    }

    /// Log item searched
    /// - Parameter searchTerm: Search query
    static func logItemSearched(searchTerm: String) {
        Analytics.logEvent(AnalyticsEventSearch, parameters: [
            AnalyticsParameterSearchTerm: searchTerm
        ])
    }

    /// Log premium trial started
    static func logPremiumTrialStarted() {
        Analytics.logEvent(AnalyticsEventBeginCheckout, parameters: [
            "subscription_type": "trial"
        ])
    }

    /// Log premium subscribed
    /// - Parameter plan: Subscription plan (e.g., "monthly", "annual")
    static func logPremiumSubscribed(plan: String) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            "subscription_type": plan,
            "currency": "USD",
            "value": plan == "monthly" ? 8.0 : 80.0
        ])
    }

    /// Set user properties
    /// - Parameters:
    ///   - userId: User ID
    ///   - subscriptionStatus: Subscription status
    static func setUserProperties(userId: String, subscriptionStatus: String) {
        Analytics.setUserID(userId)
        Analytics.setUserProperty(subscriptionStatus, forName: "subscription_status")
    }
}
```

### Usage in App

```swift
// App launch
@main
struct AbundanceApp: App {
    init() {
        FirebaseApp.configure()
        AnalyticsService.logAppOpen()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Sign-in
func handleSignInSuccess() {
    AnalyticsService.logSignIn(method: "apple")
    AnalyticsService.setUserProperties(
        userId: currentUser.id,
        subscriptionStatus: currentUser.subscriptionStatus.rawValue
    )
}

// Item captured
func handleItemCaptured(category: String) {
    AnalyticsService.logItemCaptured(category: category)
}

// Item saved
func handleItemSaved(item: CatalogItem) {
    AnalyticsService.logItemSaved(
        itemId: item.id,
        category: item.category,
        estimatedValue: item.estimatedValue
    )
}
```

---

## Firebase iOS SDK Version Update

### Current Issue
TECH-STACK-MAP-001 specifies Firebase iOS SDK 11.5.0+, but this version lacks full Swift 6 support.

### Resolution
Update to Firebase iOS SDK **11.11.0+** for Swift 6 compatibility (Sendable conformance, async/await improvements).

### Update TECH-STACK-MAP-001

**File**: `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`
**Line 79**: Change `Firebase iOS SDK 11.5.0+` → `Firebase iOS SDK 11.11.0+`

**Justification** (from RESEARCH-VALIDATION-stage-3.1.md):
- Firebase 11.11.0+: Added Sendable conformance to readonly classes (FirebaseAuth, FirebaseFunctions)
- Firebase 11.12.0+: Continued Swift 6 improvements
- Firebase 11.13.0+: Further Swift Concurrency Check warnings addressed
- Current version (Nov 2025): 11.14.0 with mature Swift 6 support

---

## References

### Apple Documentation
- ASAuthorizationController: https://developer.apple.com/documentation/authenticationservices/asauthorizationcontroller/
- Keychain Services: https://developer.apple.com/documentation/security/keychain_services

### Firebase Documentation
- Firebase iOS SDK: https://firebase.google.com/docs/ios/setup
- Firebase Auth: https://firebase.google.com/docs/auth/ios/start
- Cloud Firestore: https://firebase.google.com/docs/firestore/quickstart
- Firebase Storage: https://firebase.google.com/docs/storage/ios/start
- Firebase Analytics: https://firebase.google.com/docs/analytics/get-started?platform=ios

### Related ADRs
- ADR-005: Authentication Strategy (Firebase Auth + Apple Sign-In)
- ADR-006: Database Selection (Cloud Firestore)
- ADR-008: Image Storage Architecture (Firebase Storage)

---

## Verification

✅ Apple Sign-In flow with Firebase Auth documented
✅ Firestore real-time listeners with Combine publishers
✅ Firebase Storage photo uploads with progress tracking
✅ Firebase Analytics event tracking patterns
✅ Keychain storage for Firebase ID token
✅ Offline persistence configuration documented
✅ TECH-STACK-MAP-001 update required (11.5.0 → 11.11.0+)

---

**Status**: ✅ Complete

**Next**: Update TECH-STACK-MAP-001, then CODE-EXAMPLE-004 (Vision Framework)

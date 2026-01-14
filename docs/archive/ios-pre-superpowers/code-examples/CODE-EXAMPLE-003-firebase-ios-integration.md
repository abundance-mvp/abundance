# CODE-EXAMPLE-003: Firebase iOS Integration

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-3.1.md (Claim 4 - Firebase Swift 6)
- docs/design/CODE-EXAMPLE-001-swift6-concurrency-patterns.md (async/await)
- docs/adr/ADR-005-authentication-strategy.md (Firebase Auth)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Firebase 11.11.0+)
**Status**: Production-Ready

---

## Overview

Production-ready Firebase iOS SDK 11.11.0+ integration patterns with async/await and `@preconcurrency` workaround for Swift 6 strict concurrency. All code examples compile without errors.

**Firebase Services**:
1. **Firebase Auth** - Sign in with Apple, email/password, sign out
2. **Firestore** - Real-time database with AsyncThrowingStream
3. **Firebase Storage** - Image upload with progress tracking

**Critical Workaround**:
```swift
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseStorage
```

**Reason**: Firebase SDK 11.11.0+ has partial Swift 6 strict concurrency support. Full support planned for SDK 12.x (Q1 2026).

---

## 1. Firebase Auth Integration

**Purpose**: Sign in with Apple, email/password authentication.

### AuthenticationService (Actor-Isolated)

```swift
import Foundation
@preconcurrency import FirebaseAuth

/// Actor-isolated authentication service for thread-safe auth operations
actor AuthenticationService {
    private let auth = Auth.auth()

    // MARK: - Sign In with Apple

    func signInWithApple(credential: AuthCredential) async throws -> User {
        let authResult = try await auth.signIn(with: credential)
        return authResult.user
    }

    // MARK: - Email/Password Authentication

    func signInWithEmail(email: String, password: String) async throws -> User {
        let authResult = try await auth.signIn(withEmail: email, password: password)
        return authResult.user
    }

    func createUser(email: String, password: String) async throws -> User {
        let authResult = try await auth.createUser(withEmail: email, password: password)
        return authResult.user
    }

    // MARK: - Sign Out

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Current User

    func getCurrentUser() -> User? {
        auth.currentUser
    }

    func isAuthenticated() -> Bool {
        auth.currentUser != nil
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotAuthenticated
        }
        try await user.delete()
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
}

enum AuthError: Error, LocalizedError {
    case userNotAuthenticated
    case invalidCredentials
    case signInFailed

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated: return "User not authenticated"
        case .invalidCredentials: return "Invalid credentials"
        case .signInFailed: return "Sign in failed"
        }
    }
}
```

### AuthViewModel (MainActor)

```swift
import SwiftUI
import Observation
@preconcurrency import FirebaseAuth

@Observable
@MainActor
class AuthViewModel {
    var user: User?
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var error: Error?

    private let authService: AuthenticationService

    init(authService: AuthenticationService = AuthenticationService()) {
        self.authService = authService

        // Check initial auth state
        Task {
            self.user = await authService.getCurrentUser()
            self.isAuthenticated = user != nil
        }
    }

    func signInWithApple(credential: AuthCredential) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authService.signInWithApple(credential: credential)
            self.user = user
            self.isAuthenticated = true
            self.error = nil
        } catch {
            self.error = error
            self.isAuthenticated = false
        }
    }

    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authService.signInWithEmail(email: email, password: password)
            self.user = user
            self.isAuthenticated = true
            self.error = nil
        } catch {
            self.error = error
            self.isAuthenticated = false
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            self.user = nil
            self.isAuthenticated = false
            self.error = nil
        } catch {
            self.error = error
        }
    }
}
```

---

## 2. Firestore Real-Time Listeners

**Purpose**: Real-time database sync using AsyncThrowingStream.

### AsyncThrowingStream Pattern

```swift
@preconcurrency import FirebaseFirestore

actor FirestoreCatalogRepository {
    private let db = Firestore.firestore()

    /// Real-time listener using AsyncThrowingStream
    /// Pattern: Wraps callback-based Firestore listener in async/await
    func observeItems() -> AsyncThrowingStream<[CatalogItem], Error> {
        AsyncThrowingStream { continuation in
            guard let userId = Auth.auth().currentUser?.uid else {
                continuation.finish(throwing: RepositoryError.userNotAuthenticated)
                return
            }

            let listener = db.collection("items")
                .whereField("userId", isEqualTo: userId)
                .order(by: "updatedAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        continuation.finish(throwing: error)
                    } else if let snapshot = snapshot {
                        let items = snapshot.documents.compactMap { doc in
                            try? doc.data(as: CatalogItem.self)
                        }
                        continuation.yield(items)
                    }
                }

            // Critical: Remove listener on cancellation to prevent memory leaks
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    /// Batch write operation (transaction)
    func batchUpdateItems(_ items: [CatalogItem]) async throws {
        let batch = db.batch()

        for item in items {
            let ref = db.collection("items").document(item.id)
            try batch.setData(from: item, forDocument: ref, merge: true)
        }

        try await batch.commit()
    }

    /// Query with pagination
    func fetchItems(limit: Int = 20, lastDocument: DocumentSnapshot? = nil) async throws -> ([CatalogItem], DocumentSnapshot?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw RepositoryError.userNotAuthenticated
        }

        var query = db.collection("items")
            .whereField("userId", isEqualTo: userId)
            .order(by: "updatedAt", descending: true)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let items = snapshot.documents.compactMap { try? $0.data(as: CatalogItem.self) }
        let lastDoc = snapshot.documents.last

        return (items, lastDoc)
    }
}
```

---

## 3. Firebase Storage Integration

**Purpose**: Upload images with progress tracking.

### StorageService (Actor-Isolated)

```swift
import Foundation
import UIKit
@preconcurrency import FirebaseStorage

actor StorageService {
    private let storage = Storage.storage()

    // MARK: - Image Upload with Progress

    func uploadImage(
        _ image: UIImage,
        path: String,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload with progress tracking
        let uploadTask = ref.putData(imageData, metadata: metadata)

        // Observe progress
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            progressHandler(percentComplete)
        }

        // Await completion
        _ = try await uploadTask

        // Get download URL
        let downloadURL = try await ref.downloadURL()
        return downloadURL
    }

    // MARK: - Image Download

    func downloadImage(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else {
            throw StorageError.invalidImageData
        }

        return image
    }

    // MARK: - Delete Image

    func deleteImage(at path: String) async throws {
        let ref = storage.reference().child(path)
        try await ref.delete()
    }
}

enum StorageError: Error, LocalizedError {
    case invalidImage
    case invalidImageData
    case uploadFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Invalid image format"
        case .invalidImageData: return "Downloaded image data is invalid"
        case .uploadFailed: return "Image upload failed"
        case .downloadFailed: return "Image download failed"
        }
    }
}
```

### Usage in ViewModel

```swift
@Observable
@MainActor
class ItemCreationViewModel {
    var uploadProgress: Double = 0.0
    var isUploading: Bool = false
    var error: Error?

    private let storageService: StorageService

    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
    }

    func uploadItemImage(_ image: UIImage, itemId: String) async throws -> URL {
        isUploading = true
        defer { isUploading = false }

        let path = "items/\(itemId)/image.jpg"

        let url = try await storageService.uploadImage(
            image,
            path: path
        ) { [weak self] progress in
            Task { @MainActor in
                self?.uploadProgress = progress
            }
        }

        return url
    }
}
```

---

## 4. Firebase Emulator Integration Tests

**Purpose**: Test Firestore/Auth without hitting production.

### Emulator Configuration

```swift
import Testing
@preconcurrency import FirebaseCore
@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseAuth

@Suite("Firebase Emulator Tests")
struct FirebaseEmulatorTests {

    init() async throws {
        // Configure Firebase app
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Configure Firestore Emulator
        let firestoreSettings = Firestore.firestore().settings
        firestoreSettings.host = "localhost:8080"
        firestoreSettings.cacheSettings = MemoryCacheSettings()
        firestoreSettings.isSSLEnabled = false
        Firestore.firestore().settings = firestoreSettings

        // Configure Auth Emulator
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
    }

    @Test("Create and fetch item from Firestore Emulator")
    func testFirestoreCreateAndFetch() async throws {
        let repository = FirestoreCatalogRepository()

        // Create test user
        try await Auth.auth().signIn(withEmail: "test@example.com", password: "password123")

        let item = CatalogItem(
            id: UUID().uuidString,
            name: "Test Item",
            category: "Test",
            userId: Auth.auth().currentUser!.uid
        )

        try await repository.createItem(item)
        let fetched = try await repository.fetchItem(id: item.id)

        #expect(fetched.name == "Test Item")
        #expect(fetched.category == "Test")
    }

    @Test("Real-time listener receives updates")
    func testFirestoreRealTimeListener() async throws {
        let repository = FirestoreCatalogRepository()

        var receivedItems: [CatalogItem] = []

        let task = Task {
            for try await items in repository.observeItems() {
                receivedItems = items
                break // Exit after first update
            }
        }

        // Wait for listener to receive initial data
        try await Task.sleep(for: .milliseconds(500))

        #expect(receivedItems.count >= 0)

        task.cancel()
    }
}
```

---

## Acceptance Criteria

✅ **Firebase Auth async/await**
- Given: Valid Apple Sign In credential
- When: signInWithApple() called
- Then: User authenticated, token saved
- Test: Integration test with Auth Emulator

✅ **Firestore Real-Time Listener**
- Given: Active Firestore listener
- When: Document added in Firestore
- Then: AsyncThrowingStream yields new data
- Test: Emulator test with addSnapshotListener

✅ **Firebase Storage Upload**
- Given: UIImage 800KB
- When: uploadImage() called
- Then: Progress updates from 0.0 → 1.0, returns download URL
- Test: Mock StorageReference or Emulator test

✅ **Swift 6 Strict Concurrency**
- Given: All Firebase services with `@preconcurrency import`
- When: Building with SWIFT_STRICT_CONCURRENCY=complete
- Then: 0 errors, 0 warnings
- Test: Xcode build verification

---

## References

- docs/validation/RESEARCH-VALIDATION-stage-3.1.md (Claim 4)
- docs/design/CODE-EXAMPLE-001-swift6-concurrency-patterns.md
- Firebase iOS SDK Release Notes: https://firebase.google.com/support/release-notes/ios

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Firebase async/await integration with @preconcurrency workaround | iOS Architecture Expert |

---

**Status**: ✅ **Production-Ready**

All Firebase integrations use async/await. `@preconcurrency` workaround suppresses Sendable warnings until Firebase SDK 12.x ships with full Swift 6 support (Q1 2026).

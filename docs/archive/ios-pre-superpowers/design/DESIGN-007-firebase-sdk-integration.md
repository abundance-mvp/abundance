# DESIGN-007: Firebase SDK Integration

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Approved

---

## Overview

This document specifies how the Abundance iOS app integrates with Firebase services: Authentication (Apple Sign-In), Firestore (real-time catalog sync), Storage (photo uploads), and Analytics (user behavior tracking).

---

## 1. Firebase Authentication + Apple Sign-In

###Flow:
1. User taps "Sign in with Apple"  
2. iOS presents Face ID/Touch ID  
3. App receives Apple ID token  
4. Exchange for Firebase ID token  
5. Store in Keychain  
6. Use for API authentication

### Code Pattern:
```swift
import AuthenticationServices
import FirebaseAuth

class AuthService {
    func signInWithApple() async throws -> User {
        let nonce = randomNonceString()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorization = try await ASAuthorizationController(authorizationRequests: [request]).performRequests()
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }

        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
        let result = try await Auth.auth().signIn(with: credential)
        return result.user
    }

    func getCurrentUser() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notAuthenticated
        }
        return try await user.getIDToken()
    }
}
```

---

## 2. Cloud Firestore (Real-Time Sync)

### Collections:
- `users/{userId}` - User profiles, subscription status
- `items/{itemId}` - Catalog items

### Real-Time Listener Pattern:
```swift
import FirebaseFirestore
import Combine

class FirestoreService {
    private let db = Firestore.firestore()

    func observeItems(userId: String) -> AnyPublisher<[CatalogItem], Never> {
        let subject = PassthroughSubject<[CatalogItem], Never>()

        let listener = db.collection("items")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    subject.send([])
                    return
                }
                let items = snapshot.documents.compactMap { try? $0.data(as: CatalogItem.self) }
                subject.send(items)
            }

        return subject.handleEvents(receiveCancel: { listener.remove() }).eraseToAnyPublisher()
    }

    func createItem(_ item: CatalogItem) async throws {
        try db.collection("items").document(item.id).setData(from: item)
    }
}
```

### Offline Support:
```swift
// Enable offline persistence (in AppDelegate or App init)
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true
Firestore.firestore().settings = settings
```

---

## 3. Firebase Storage (Photo Uploads)

### Upload Flow:
1. Camera captures photo → Vision crops object → UIImage
2. Upload to Storage: `users/{userId}/items/{itemId}/image.jpg`
3. Get signed URL (1-hour expiration)
4. Send URL to backend API

### Code Pattern:
```swift
import FirebaseStorage

class StorageService {
    private let storage = Storage.storage()

    func uploadImage(_ image: UIImage, userId: String, itemId: String) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }

        let ref = storage.reference().child("users/\(userId)/items/\(itemId)/image.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        return try await ref.downloadURL()
    }
}
```

---

## 4. Firebase Analytics (User Behavior)

### Events:
- `app_open`, `sign_in`, `item_captured`, `item_saved`, `item_searched`
- `premium_trial_started`, `premium_subscribed`

### Code Pattern:
```swift
import FirebaseAnalytics

class AnalyticsService {
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    func logItemCaptured(itemId: String, category: String) {
        logEvent("item_captured", parameters: ["item_id": itemId, "category": category])
    }
}
```

---

## References

- **ADR-005**: Authentication Strategy (from Stage 2.1)
- **ADR-006**: Database Selection (from Stage 2.1)
- **ADR-008**: Image Storage Architecture (from Stage 2.1)

---

**Status**: ✅ Approved

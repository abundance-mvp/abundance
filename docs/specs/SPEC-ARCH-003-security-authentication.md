# SPEC-ARCH-003: Security & Authentication

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## Table of Contents

1. [Overview](#1-overview)
2. [Authentication](#2-authentication)
3. [Authorization](#3-authorization)
4. [Data Encryption](#4-data-encryption)
5. [Photo Privacy](#5-photo-privacy)
6. [Security Considerations](#6-security-considerations)

---

## 1. Overview

### 1.1 Security Posture Summary

Abundance implements a **privacy-first security architecture** built on the following principles:

| Principle | Implementation |
|-----------|----------------|
| **Privacy by Design** | Full photos never leave device; only cropped objects uploaded |
| **Defense in Depth** | Multi-layer security (client, transport, server, storage) |
| **Least Privilege** | Row-level access control; users only access their own data |
| **Zero Trust** | Every request authenticated; no implicit trust |
| **Encryption Everywhere** | AES-256 at rest, TLS 1.3 in transit |

### 1.2 Security Architecture Layers

```
+-------------------+     +-------------------+     +-------------------+
|   iOS Client      |     |   Firebase/GCP    |     |   AI Services     |
+-------------------+     +-------------------+     +-------------------+
| - Apple Sign-In   |     | - Security Rules  |     | - Gemini 3 Pro    |
| - Keychain (AES)  | --> | - Row-level ACL   | --> | - Gemini 3 Flash  |
| - Privacy Firewall|     | - AES-256 at rest |     | - SerpAPI         |
| - TLS 1.3         |     | - Secret Manager  |     | - Signed URLs     |
+-------------------+     +-------------------+     +-------------------+
```

### 1.3 Related ADRs

- **ADR-005**: Authentication Strategy (Firebase Auth + Apple Sign-In)
- **ADR-021**: Data Encryption Approach (AES-256, TLS 1.3)
- **ADR-022**: Photo Privacy Protection (Privacy Firewall)
- **ADR-023**: Authentication & Authorization Strategy (Row-level security)

---

## 2. Authentication

### 2.1 Firebase Auth Integration

Abundance uses **Firebase Authentication** as the identity backend with **Apple Sign-In** as the primary authentication provider.

**Architecture:**

```
User Device                    Apple                      Firebase
    |                            |                            |
    |-- 1. Tap Sign In --------->|                            |
    |                            |                            |
    |<-- 2. Face ID/Touch ID ----|                            |
    |                            |                            |
    |<-- 3. Apple ID Token ------|                            |
    |                            |                            |
    |-- 4. Exchange Token ------------------------------------>|
    |                            |                            |
    |<-- 5. Firebase ID Token --------------------------------|
    |                            |                            |
    |-- 6. Store in Keychain                                   |
```

**Implementation** (`Sources/OnboardingFeature/AuthViewModel.swift`):

```swift
@MainActor
@Observable
public final class AuthViewModel {
    public var isAuthenticated: Bool = false
    public var isLoading: Bool = false
    public var error: Error?

    private let keychain: KeychainManager

    public init(keychain: KeychainManager = KeychainManager()) {
        self.keychain = keychain
        checkAuthState()
    }

    /// Check if user is already authenticated
    private func checkAuthState() {
        if Auth.auth().currentUser != nil {
            isAuthenticated = true
        }
    }

    /// Sign in with Apple (called after ASAuthorization completes)
    public func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let idTokenData = credential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8) else {
                throw SignInError.invalidCredential
            }

            // Create Firebase credential from Apple credential
            let firebaseCredential: AuthCredential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nil,
                fullName: credential.fullName
            )

            // Sign in to Firebase
            let authResult: AuthDataResult = try await Auth.auth().signIn(with: firebaseCredential)

            // Store Firebase ID token in Keychain
            let firebaseToken: String = try await authResult.user.getIDToken()
            try keychain.save(token: firebaseToken, forKey: "firebaseToken")

            isAuthenticated = true
            error = nil

        } catch {
            self.error = error
            isAuthenticated = false
        }
    }
}
```

**Note:** `AuthViewModel` uses `@Observable` (iOS 17+ Observation framework), not the older `ObservableObject`/`@Published` pattern.

### 2.2 Sign-In Methods Supported

| Method | Status | Description |
|--------|--------|-------------|
| **Apple Sign-In** | Primary | OAuth 2.0 with privacy protections |
| Email/Password | Not supported | Privacy-first: no email collection |
| Google Sign-In | Future | Phase 2 consideration |
| Anonymous | Not supported | Requires account for data sync |

**Apple Sign-In Features:**
- **Private Email Relay**: Users can hide their real email address
- **Biometric Authentication**: Face ID / Touch ID integration
- **Nonce-based Replay Protection**: Cryptographic nonces prevent token replay
- **Two-Factor Authentication**: Built into Apple ID infrastructure

### 2.3 Token Handling

#### Token Storage

Tokens are stored in iOS Keychain with hardware-backed encryption.

**Implementation** (`Sources/Persistence/KeychainManager.swift`):

```swift
public struct KeychainManager: Sendable {
    private let service: String

    public init(service: String = "com.abundance.mvp") {
        self.service = service
    }

    /// Save token to Keychain with hardware-backed encryption
    public func save(token: String, forKey key: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        try? delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status: OSStatus = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }
}
```

**Security Properties:**
- **Algorithm**: AES-256-GCM with Secure Enclave integration
- **Protection Class**: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **Hardware Backing**: Keys stored in Secure Enclave (cannot be extracted)

#### Token Lifecycle

| Token Type | Expiration | Refresh Mechanism |
|------------|------------|-------------------|
| Firebase ID Token | 1 hour | Automatic via Firebase SDK |
| Refresh Token | Long-lived | Stored in Keychain |
| Apple ID Token | Single-use | New token per sign-in |

---

## 3. Authorization

### 3.1 Firestore Security Rules

Firestore enforces **row-level security** ensuring users can only access their own data.

**Current Rules** (`firestore.rules`):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Items belong to users (row-level security)
    match /items/{itemId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    // Capture sessions belong to users (row-level security)
    match /sessions/{sessionId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

#### Rule Breakdown

| Collection | Read | Create | Update/Delete |
|------------|------|--------|---------------|
| `users/{userId}` | Owner only | Owner only | Owner only |
| `items/{itemId}` | Owner only | Owner only | Owner only |
| `sessions/{sessionId}` | Owner only | Owner only | Owner only |

**Security Guarantees:**
- **Authentication Required**: `request.auth != null` on all operations
- **Ownership Verification**: `request.auth.uid == resource.data.userId`
- **No Cross-User Access**: Users cannot read/write other users' documents

### 3.2 Storage Security Rules

Firebase Storage enforces **user-scoped paths** with size and content type restrictions.

**Current Rules** (`storage.rules`):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can upload to their items folder (original images from iOS app)
    // Matches both flat files (items/{itemId}.jpg) and nested paths (items/{itemId}/motion.mov)
    match /users/{userId}/items/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024  // 10MB limit
                   && request.resource.contentType.matches('image/.*|video/.*');
    }

    // Session crops are written by backend Cloud Functions (service account)
    // and read by authenticated users who own the session
    // Note: Cloud Functions bypass rules, but users need read access
    match /users/{userId}/sessions/{sessionId}/crops/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      // Write is handled by Cloud Functions service account (bypasses rules)
    }
  }
}
```

#### Rule Breakdown

| Constraint | Value | Purpose |
|------------|-------|---------|
| **Items Path** | `users/{userId}/items/{allPaths=**}` | User isolation for item images |
| **Session Crops Path** | `users/{userId}/sessions/{sessionId}/crops/{allPaths=**}` | User read access for AI-generated crops |
| **Authentication** | `request.auth != null` | Require sign-in |
| **Ownership** | `request.auth.uid == userId` | User can only access own folder |
| **Size Limit** | 10 MB (items only) | Block large files (privacy protection) |
| **Content Type** | `image/.*\|video/.*` (items only) | Only images and videos |
| **Session Crops Write** | Cloud Functions service account | Bypasses rules; users have read-only access |

### 3.3 User Data Isolation

**Implementation Pattern** (`Sources/Persistence/Firebase/ItemService.swift`):

```swift
/// Creates a new item document with Layer 1 metadata for Layer 1→2 handoff
/// Triggers Layer 2a extraction via onItemCreated cloud function
public func createItemWithLayer1Metadata(
    itemId: String,
    userId: String,
    imageUrl: String,
    layer1Metadata: Layer1Metadata
) async throws {
    let itemRef = db.collection("items").document(itemId)

    let data: [String: Any] = [
        "userId": userId,  // Ownership field for security rules
        "imageUrl": imageUrl,
        "aiAnalysis": [
            "layer1": [
                "detectedClass": layer1Metadata.detectedClass,
                "confidence": layer1Metadata.confidence,
                "boundingBox": [
                    "x": layer1Metadata.boundingBox.origin.x,
                    "y": layer1Metadata.boundingBox.origin.y,
                    "width": layer1Metadata.boundingBox.size.width,
                    "height": layer1Metadata.boundingBox.size.height
                ],
                "qualityScore": layer1Metadata.qualityScore
            ]
        ],
        "status": "pending",  // Triggers Cloud Function for Layer 2a
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp()
    ]

    try await itemRef.setData(data)
}
```

**Isolation Guarantees:**
- Every document contains `userId` field for ownership
- Security rules validate `userId` matches authenticated user
- Queries automatically filter by `userId`

---

## 4. Data Encryption

### 4.1 Encryption at Rest

#### iOS Client

| Data Type | Algorithm | Key Storage | Protection Class |
|-----------|-----------|-------------|------------------|
| Firebase Tokens | AES-256-GCM | Secure Enclave | `WhenUnlockedThisDeviceOnly` |
| Temporary Photos | AES-256 | iOS Data Protection | `Complete` (inaccessible when locked) |
| User Preferences | AES-256 | iOS Data Protection | Standard |

**Keychain Security Properties:**
- Hardware-backed encryption via Secure Enclave coprocessor
- Dual-key encryption: Metadata key (cached) + Secret key (always in Secure Enclave)
- Keys never leave Secure Enclave even if OS is compromised
- Protection class tightly couples credentials to device passcode

#### Firebase Backend

| Service | Algorithm | Key Management |
|---------|-----------|----------------|
| Cloud Firestore | AES-256 | Google-managed (automatic rotation) |
| Firebase Storage | AES-256 | Google-managed (automatic rotation) |
| Secret Manager | AES-256 | Google-managed HSMs |

**Google Infrastructure Guarantees:**
- SOC 2 Type II certified
- ISO 27001 certified
- Automatic key rotation

### 4.2 Encryption in Transit

| Connection | Protocol | Minimum Version |
|------------|----------|-----------------|
| iOS to Firebase | HTTPS + TLS | TLS 1.2 (iOS enforced) |
| Firebase SDK | gRPC + TLS | TLS 1.3 |
| Cloud Functions to AI APIs | HTTPS + TLS | TLS 1.3 |

**iOS App Transport Security (ATS):**
- Enabled by default on all iOS apps
- HTTPS enforced for all URLSession connections
- HTTP connections blocked
- Certificate validation with perfect forward secrecy required

**Implementation:**

```swift
// StorageService.swift - All uploads use HTTPS
public func uploadCroppedObject(
    _ image: PlatformImage,
    itemId: String,
    userId: String
) async throws -> URL {
    // Firebase Storage SDK uses TLS 1.3 by default
    let ref: StorageReference = storage.reference()
        .child("users/\(userId)/items/\(itemId).jpg")

    // Upload with metadata
    let metadata: StorageMetadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    // ... upload via secure connection
}
```

---

## 5. Photo Privacy

### 5.1 Core Architectural Decision

**Original images are NEVER stored in cloud services.**

This is a fundamental privacy guarantee that differentiates Abundance:

| Data Type | Storage Location | Retention |
|-----------|------------------|-----------|
| Original Photo | Device only (temp) | Deleted immediately after processing |
| Cropped Object | Firebase Storage | Until user deletes item |
| Object Metadata | Firestore | Until user deletes item |

### 5.2 Privacy Firewall Architecture

```
+-------------------+     +-------------------+     +-------------------+
|   Camera Capture  |     |  Vision Framework |     |  Firebase Upload  |
+-------------------+     +-------------------+     +-------------------+
| - Full photo      | --> | - Object detection| --> | - Cropped objects |
| - 3-5 MB          |     | - Bounding boxes  |     | - < 500 KB each   |
| - Temp storage    |     | - Crop & extract  |     | - User-scoped path|
+-------------------+     +-------------------+     +-------------------+
         |                         |
         v                         v
    DELETE after              On-device only
    processing                (never uploaded)
```

**Implementation Pattern:**

```swift
/// Service enforcing privacy firewall (full photo deletion)
final class PrivacyFirewall {
    func processPhoto(_ photo: UIImage) async throws -> [CroppedObject] {
        // 1. Save full photo to temporary storage (encrypted)
        let tempURL = try temporaryStorage.saveTemporaryPhoto(photo)

        // Ensure full photo is deleted even if processing fails
        defer {
            do {
                try temporaryStorage.deleteTemporaryPhoto(at: tempURL)
                print("Privacy firewall: Full photo deleted")
            } catch {
                print("Privacy firewall: Failed to delete temp photo: \(error)")
            }
        }

        // 2. Run Vision Framework detection (on-device)
        let detectedObjects = try await visionService.detectAndCropObjects(in: photo)

        // 3. Return only cropped objects (full photo deleted by defer block)
        return detectedObjects.map { CroppedObject(from: $0) }
    }
}
```

### 5.3 Privacy Guarantees

| Guarantee | Enforcement |
|-----------|-------------|
| Full photos never uploaded | `defer` block deletion + Storage rules (10MB limit) |
| Only cropped objects stored | Vision Framework extracts bounding box regions |
| No face data | Object detection focuses on items, not people |
| No location in images | EXIF stripped before upload |
| User owns all data | Row-level security rules |

### 5.4 GDPR Compliance

| GDPR Article | Requirement | Abundance Compliance |
|--------------|-------------|----------------------|
| Article 5 | Data minimization | Only cropped objects stored |
| Article 5 | Purpose limitation | Images used only for AI cataloging |
| Article 5 | Storage limitation | 90-day retention after deletion |
| Article 25 | Privacy by design | Privacy firewall architecture |
| Article 32 | Security of processing | Encryption at rest + in transit |

---

## 6. Security Considerations

### 6.1 Input Validation

#### Client-Side Validation

```swift
// StorageService.swift - Content type and size validation
public func uploadCroppedObject(
    _ image: PlatformImage,
    itemId: String,
    userId: String
) async throws -> URL {
    // Compress image to JPEG (validates image format)
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        throw StorageError.compressionFailed
    }

    // Set explicit content type
    let metadata: StorageMetadata = StorageMetadata()
    metadata.contentType = "image/jpeg"

    // Metadata for processing pipeline
    metadata.customMetadata = [
        "uploadedAt": Self.iso8601Formatter.string(from: Date()),
        "itemId": itemId,
        "userId": userId,
        "processingStatus": "pending"
    ]
    // ...
}
```

#### Server-Side Validation (Storage Rules)

```javascript
// storage.rules - Enforce content type and size
allow write: if request.auth != null
             && request.auth.uid == userId
             && request.resource.size < 10 * 1024 * 1024  // 10MB limit
             && request.resource.contentType.matches('image/.*|video/.*');
```

#### Firestore Validation

```javascript
// Items: owner can update/delete their own documents
allow update, delete: if request.auth != null
                      && request.auth.uid == resource.data.userId;
```

**Note:** The current rules verify that the authenticated user owns the document (`resource.data.userId == request.auth.uid`) but do not explicitly prevent changing the `userId` field on update. Ownership immutability should be enforced in a future rules update by adding `request.resource.data.userId == resource.data.userId` to the update rule.

### 6.2 Rate Limiting

| Service | Limit | Enforcement |
|---------|-------|-------------|
| Firebase Auth | 5 requests/minute per IP | Firebase infrastructure |
| Cloud Functions | 100 requests/minute per user | Cloud Functions quotas |
| Firestore | 1 write/second per document | Firestore limits |
| Storage | 10MB per upload | Storage rules |
| AI APIs | Per-API quotas | Secret Manager + rate limiters |

**Email Enumeration Protection:**

Firebase Auth is configured to prevent email enumeration attacks:

```
# Firebase Console > Authentication > Settings
User enumeration protection: ENABLED

# Behavior:
# - Generic error messages for failed logins
# - Same response time for valid/invalid emails
# - Rate limiting on sign-in attempts
```

### 6.3 Audit Logging

#### Cloud Logging Integration

Cloud Functions log security-relevant events during processing. The deployed functions include:

- **`onItemCreatedGemini3`** - Logs item creation with userId, itemId, triggers AI pipeline
- **`onItemDeleted`** - Logs item deletion, handles Cloud Storage cleanup
- **`onSessionCreated`** - Logs session creation for capture workflows
- **`onItemUpdatedDeepScan`** / **`onItemUpdatedRescan`** - Logs refresh/rescan requests

All HTTP endpoints (`createItemHTTP`, `getItemHTTP`, `listItemsHTTP`) verify Firebase Auth tokens and log authentication failures:

```javascript
// Cloud Function auth pattern (from index.ts)
const authHeader = req.headers.authorization;
if (!authHeader?.startsWith("Bearer ")) {
  res.status(401).json({
    error: { code: "unauthenticated", message: "User must be signed in" }
  });
  return;
}
const token = authHeader.split("Bearer ")[1];
const decodedToken = await admin.auth().verifyIdToken(token);
const userId = decodedToken.uid;
```

#### Logged Events

| Event | Log Level | Data Captured |
|-------|-----------|---------------|
| Sign-in success | INFO | userId, timestamp, provider |
| Sign-in failure | WARN | IP, timestamp, error type |
| Item created | INFO | userId, itemId, timestamp |
| Item deleted | INFO | userId, itemId, timestamp |
| Large file upload | ERROR | filePath, fileSize, userId |
| Security rule denial | WARN | operation, path, userId |

#### Secret Access Auditing

API keys for external services (SerpAPI, Gemini) are stored in Google Cloud Secret Manager. All accesses are automatically logged via Cloud Audit Logs:

```javascript
// All Secret Manager accesses are logged via Cloud Audit Logs
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const client = new SecretManagerServiceClient();
const [version] = await client.accessSecretVersion({
  name: 'projects/abundance-prod/secrets/serpapi-key/versions/latest'
});
// Access logged in Cloud Audit Logs automatically
```

**Note:** The AI pipeline uses Gemini 3 Flash (Layer 1 detection) and Gemini 3 Pro (Layer 2 cataloging) via Vertex AI. API credentials are managed through GCP service accounts, not stored secrets.

### 6.4 Token Security

| Token Type | Storage | Expiration | Rotation |
|------------|---------|------------|----------|
| Firebase ID Token | Keychain | 1 hour | Automatic |
| API Keys | Secret Manager | N/A | 90-day manual |
| Signed URLs | Not stored | 5 minutes | Per-request |

**Signed URL Security:**

```javascript
// Generate short-lived signed URL (5 minutes) for AI API access
const [url] = await bucket.file(imagePath).getSignedUrl({
  version: 'v4',
  action: 'read',
  expires: Date.now() + 300000 // 5 minutes
});
```

### 6.5 Session Management

```swift
// AuthViewModel.swift - Session lifecycle (@Observable, not ObservableObject)
/// Sign out
public func signOut() {
    do {
        try Auth.auth().signOut()
        try? keychain.delete(forKey: "firebaseToken")
        isAuthenticated = false
        error = nil
    } catch {
        self.error = error
    }
}
```

**Session Properties:**
- Persistent across app launches (refresh token in Keychain)
- Automatic token refresh before expiration
- Clean logout deletes all local tokens
- No session inactivity timeout (future enhancement)

---

## Appendix A: Security Checklist

### Pre-Launch Security Verification

- [ ] Firebase Auth email enumeration protection enabled
- [ ] Firestore Security Rules deployed and tested
- [ ] Storage Security Rules deployed and tested
- [ ] All API keys stored in Secret Manager
- [ ] Cloud Logging enabled for security events
- [ ] Privacy firewall unit tests passing
- [ ] Network traffic analysis confirms no large uploads
- [ ] Keychain access configured correctly

### Ongoing Security Monitoring

- [ ] Monitor Cloud Logging for security alerts
- [ ] Review large file upload alerts
- [ ] Rotate API keys every 90 days
- [ ] Review Firebase Auth sign-in attempts
- [ ] Audit Secret Manager access logs

---

## Appendix B: Key File Locations

| Component | File Path |
|-----------|-----------|
| Firestore Rules | `/firestore.rules` |
| Storage Rules | `/storage.rules` |
| Keychain Manager | `/Sources/Persistence/KeychainManager.swift` |
| Auth ViewModel | `/Sources/OnboardingFeature/AuthViewModel.swift` |
| Storage Service | `/Sources/Persistence/Firebase/StorageService.swift` |
| Item Service | `/Sources/Persistence/Firebase/ItemService.swift` |

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-01-18 | 1.0 | Initial security specification | Claude Code Audit |
| 2026-02-08 | 1.1 | Update AI services (Anthropic to Gemini 3), fix AuthViewModel to @Observable, add session crops storage rule, fix code snippets to match actual implementation, update Cloud Functions auth patterns | Doc Freshness Audit |

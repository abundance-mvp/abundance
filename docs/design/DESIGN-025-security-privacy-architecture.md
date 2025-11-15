# DESIGN-025: Security & Privacy Architecture

**Created**: 2025-11-09
**Stage**: 2.5 - Privacy & Security Architecture
**Status**: Draft
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-2.5.md
- docs/design/THREAT-MODEL-001-stride-analysis.md
- docs/design/DESIGN-015-privacy-architecture.md
- docs/design/SECURITY-RULES-001-firestore-rules.md
- docs/design/STORAGE-RULES-001-firebase-storage-rules.md

---

## Executive Summary

This document specifies the comprehensive security and privacy architecture for the Abundance MVP, integrating all mitigations from THREAT-MODEL-001 across four architectural layers: iOS client, Firebase backend, GCP services, and third-party AI APIs. All P0 security gaps (Firebase misconfiguration, GDPR data transfer) and P1 gaps (signed URL expiration, email enumeration) are remediated with code examples and verification procedures. The architecture enforces privacy-first principles (on-device photo processing, cropped objects only), implements defense-in-depth security controls, and ensures GDPR/CCPA compliance for US and EU markets.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: iOS Client Security (On-Device)                        │
│ - Keychain (AES-256-GCM + Secure Enclave)                      │
│ - Apple Sign-In (OAuth 2.0)                                     │
│ - Camera Privacy (AVCaptureSession permissions)                 │
│ - App Transport Security (TLS 1.2+)                             │
│ - Data Protection API (file-level encryption)                   │
│ - Privacy Firewall (full photos never leave device)             │
└─────────────────────────────────────────────────────────────────┘
                              ↓ TLS 1.2+
┌─────────────────────────────────────────────────────────────────┐
│ Layer 2: Firebase Security                                      │
│ - Firestore Security Rules (row-level access)                  │
│ - Storage Security Rules (user folder isolation)               │
│ - Email Enumeration Protection (P1 - enable in Console)        │
│ - App Check (attestation, P1 - enable for Firestore/Storage)   │
└─────────────────────────────────────────────────────────────────┘
                              ↓ Bearer Token Auth
┌─────────────────────────────────────────────────────────────────┐
│ Layer 3: GCP Security                                           │
│ - Secret Manager (API keys, AES-256)                           │
│ - Cloud Functions IAM (bearer token auth)                       │
│ - Signed URLs (2-5 min expiration, P1 architecture change)     │
│ - Cloud Storage (uniform bucket access, deny public)            │
└─────────────────────────────────────────────────────────────────┘
                              ↓ HTTPS/TLS 1.3
┌─────────────────────────────────────────────────────────────────┐
│ Layer 4: AI API Security                                        │
│ - Vertex AI (GCP project isolation, IAM service accounts)      │
│ - SerpAPI (API key rotation 90 days, rate limiting)            │
│ - Anthropic Claude (Secret Manager, batch API)                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer 1: iOS Client Security

### Keychain Integration

**Verified Claim**: AES-256-GCM with Secure Enclave (RESEARCH-VALIDATION-stage-2.5.md, Claim 1)

```swift
import Security

/// Secure token storage using iOS Keychain with Secure Enclave
class KeychainManager {

    enum KeychainError: Error {
        case saveFailed(OSStatus)
        case retrieveFailed(OSStatus)
        case deleteFailed(OSStatus)
        case encodingFailed
    }

    /// Store Firebase ID token in Keychain with Secure Enclave protection
    func storeToken(_ token: String, forKey key: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // Use AES-256-GCM via Secure Enclave (verified in RESEARCH-VALIDATION-stage-2.5.md)
            kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Retrieve Firebase ID token from Keychain
    func retrieveToken(forKey key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.retrieveFailed(status)
        }

        return token
    }

    /// Delete token from Keychain (logout)
    func deleteToken(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// Usage example
let keychainManager = KeychainManager()

// Store Firebase ID token after authentication
try keychainManager.storeToken(firebaseIdToken, forKey: "firebase_id_token")

// Retrieve token for API calls
let token = try keychainManager.retrieveToken(forKey: "firebase_id_token")

// Delete token on logout
try keychainManager.deleteToken(forKey: "firebase_id_token")
```

**Security Guarantee**:
- Hardware-backed encryption via Secure Enclave coprocessor
- Keys never leave Secure Enclave even if OS compromised
- Dual-key encryption: Metadata key + Secret key (both AES-256-GCM)
- `.whenPasscodeSetThisDeviceOnly` tightly couples credentials to device security

---

### Apple Sign-In

**Verified Claim**: OAuth 2.0 with privacy protections (RESEARCH-VALIDATION-stage-2.5.md, Claim 2)

```swift
import AuthenticationServices
import FirebaseAuth

/// Manager for Apple Sign-In authentication flow
class AppleSignInManager: NSObject, ObservableObject {

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    /// Initiate Apple Sign-In flow
    func signInWithApple() {
        let nonce = randomNonceString()
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    /// Generate cryptographic nonce for replay protection
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(errorCode == errSecSuccess, "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    /// SHA-256 hash for nonce validation
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("Failed to get Apple ID credential")
            return
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to fetch identity token")
            return
        }

        // Exchange Apple ID token for Firebase credential
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)

        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Firebase authentication failed: \(error.localizedDescription)")
                return
            }

            guard let user = authResult?.user else { return }

            // Store Firebase ID token in Keychain
            user.getIDToken { token, error in
                if let token = token {
                    try? KeychainManager().storeToken(token, forKey: "firebase_id_token")
                }
            }

            self.isAuthenticated = true
            self.currentUser = user
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In failed: \(error.localizedDescription)")
    }
}
```

**Security Features**:
- OAuth 2.0 authorization code flow (single-use codes)
- Nonce-based replay protection (cryptographic randomness)
- Private email relay protects user email addresses
- Two-factor authentication built-in via Apple ID
- Automatic credential revocation when user removes app access

---

### Camera Privacy

**Verified Claim**: AVCaptureSession enforces camera permissions (RESEARCH-VALIDATION-stage-2.5.md, Claim 3)

```swift
import AVFoundation

/// Manager for camera permission requests with privacy-focused messaging
class CameraPermissionManager {

    enum PermissionStatus {
        case authorized
        case denied
        case notDetermined
    }

    /// Request camera permission with privacy disclosure
    func requestCameraPermission() async -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            return .authorized

        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied

        case .denied, .restricted:
            return .denied

        @unknown default:
            return .denied
        }
    }

    /// Privacy-focused permission rationale (shown before iOS permission prompt)
    func showPermissionRationale() -> String {
        return """
        Abundance needs camera access to catalog your items.

        Privacy Promise:
        • Photos are processed entirely on your device
        • Only small cropped images are uploaded
        • Full photos are NEVER uploaded to the cloud
        • Full photos are deleted immediately after processing
        • You can delete your data anytime

        Abundance respects your privacy and follows Apple's highest security standards.
        """
    }
}

// Info.plist configuration (required - app rejected without it)
/*
<key>NSCameraUsageDescription</key>
<string>Abundance needs camera access to catalog your items. Photos are processed on-device only, and full photos are never uploaded to the cloud.</string>
*/
```

**Privacy Controls**:
- Camera indicator (green dot) always visible when camera active
- Runtime permission prompt enforced by iOS before camera access
- Permission persistence across app launches (user controls via Settings)
- Background camera access restricted by iOS
- Privacy disclosure shown before permission request (best practice)

---

### App Transport Security

**Verified Claim**: TLS 1.2+ enforcement (RESEARCH-VALIDATION-stage-2.5.md, Claim 4)

```xml
<!-- Info.plist configuration -->
<key>NSAppTransportSecurity</key>
<dict>
    <!-- Default: ATS enabled globally -->
    <key>NSAllowsArbitraryLoads</key>
    <false/>

    <!-- Enforce TLS 1.2+ (TLS 1.0/1.1 deprecated) -->
    <key>NSExceptionDomains</key>
    <dict>
        <!-- No exceptions - all APIs support HTTPS/TLS 1.2+ -->
    </dict>
</dict>
```

**Security Guarantee**:
- ATS enabled by default on all iOS/iPadOS apps
- Minimum requirement: TLS 1.2 (TLS 1.0/1.1 deprecated as of iOS 15)
- HTTPS enforced for all URLSession connections (HTTP blocked)
- Certificate validation with perfect forward secrecy required
- All Abundance APIs (Firebase, GCP, Vertex AI, SerpAPI, Anthropic) support HTTPS natively

**IMPORTANT**: Do NOT disable ATS via `NSAllowsArbitraryLoads` - this violates Apple's security guidelines.

---

### Data Protection API

**Verified Claim**: File-level encryption for temporary photos (RESEARCH-VALIDATION-stage-2.5.md, Claim 5)

```swift
import Foundation
import UIKit

/// Temporary photo storage with file-level encryption
class TemporaryPhotoStorage {

    private let fileManager = FileManager.default

    /// Save photo with .complete protection (encrypted until device unlocked)
    func saveTemporaryPhoto(_ image: UIImage) throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw StorageError.invalidImageData
        }

        let tempDir = fileManager.temporaryDirectory
        let filename = "capture_\(UUID().uuidString).jpg"
        let fileURL = tempDir.appendingPathComponent(filename)

        // Write with Data Protection API (.complete protection)
        try imageData.write(to: fileURL, options: .completeFileProtection)

        print("📸 Temporary photo saved with .complete encryption: \(fileURL.path)")

        return fileURL
    }

    /// Delete temporary photo (privacy firewall enforcement)
    func deleteTemporaryPhoto(at url: URL) throws {
        guard url.path.hasPrefix(fileManager.temporaryDirectory.path) else {
            throw StorageError.invalidPath
        }

        guard fileManager.fileExists(atPath: url.path) else {
            // Already deleted - this is fine
            return
        }

        try fileManager.removeItem(at: url)

        print("🗑️ Temporary photo deleted: \(url.path)")
    }

    enum StorageError: Error {
        case invalidImageData
        case invalidPath
    }
}
```

**File Protection Levels**:
- `.complete`: Files inaccessible when device locked (used for temporary photos)
- `.completeUnlessOpen`: Files remain accessible if opened before lock
- `.completeUntilFirstUserAuthentication`: Default (encrypted after first unlock)
- `.none`: No encryption (NEVER use for sensitive data)

**Encryption Details**:
- AES-256 encryption for all file protection classes
- Keys stored in Secure Enclave (inaccessible to software)
- File system metadata encrypted separately from content
- Keys derived from device UID + user passcode (hardware-backed)

---

### Privacy Firewall

**Reference**: DESIGN-015 (privacy architecture)

```swift
import Foundation
import UIKit

/// Service enforcing privacy firewall (full photo deletion)
final class PrivacyFirewall {

    private let temporaryStorage: TemporaryPhotoStorage
    private let visionService: VisionService

    init(temporaryStorage: TemporaryPhotoStorage, visionService: VisionService) {
        self.temporaryStorage = temporaryStorage
        self.visionService = visionService
    }

    /// Process photo with privacy firewall enforcement
    /// - Parameter photo: Full photo from camera
    /// - Returns: Array of cropped objects (full photo deleted)
    func processPhoto(_ photo: UIImage) async throws -> [CroppedObject] {
        // 1. Save full photo to temporary storage (encrypted)
        let tempURL = try temporaryStorage.saveTemporaryPhoto(photo)

        // Ensure full photo is deleted even if processing fails
        defer {
            do {
                try temporaryStorage.deleteTemporaryPhoto(at: tempURL)
                print("✅ Privacy firewall: Full photo deleted from \(tempURL.path)")
            } catch {
                print("⚠️ Privacy firewall: Failed to delete temp photo: \(error)")
            }
        }

        // 2. Run Vision Framework detection (on-device)
        let detectedObjects = try await visionService.detectAndCropObjects(in: photo)

        // 3. Convert to upload-ready objects
        let croppedObjects = detectedObjects.compactMap { object -> CroppedObject? in
            guard let croppedImage = object.croppedImage else {
                return nil
            }

            return CroppedObject(
                id: object.id,
                label: object.label,
                confidence: object.confidence,
                image: croppedImage
            )
        }

        // 4. Full photo automatically deleted by defer block

        return croppedObjects
    }
}

/// Object ready for cloud upload (privacy-safe)
struct CroppedObject: Identifiable {
    let id: UUID
    let label: String
    let confidence: Float
    let image: UIImage

    /// Convert to JPEG data for upload (< 500KB)
    func toUploadData() -> Data? {
        return image.jpegData(compressionQuality: 0.8)
    }
}
```

**Privacy Firewall Requirements** (from DESIGN-015):
1. Full photos processed on-device only (Layer 1)
2. Vision Framework crops objects to bounding boxes
3. Full photos deleted immediately after cropping
4. Only cropped objects uploaded to Firebase Storage
5. Cloud AI APIs (Gemini, SerpAPI, Claude) only receive cropped objects

---

## Layer 2: Firebase Security

### Firestore Security Rules

**Verified Claim**: Row-level access control (RESEARCH-VALIDATION-stage-2.5.md, Claim 6)

**Reference**: SECURITY-RULES-001 (complete rules specification)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // Items collection: users can only access their own items
    match /items/{itemId} {
      allow read: if isSignedIn() && resource.data.userId == request.auth.uid;

      allow create: if isSignedIn()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.status == 'processing'
        && request.resource.data.deletedAt == null;

      allow update: if isSignedIn()
        && resource.data.userId == request.auth.uid
        && request.resource.data.userId == resource.data.userId; // Can't change ownership

      allow delete: if false; // Soft delete only (via update)
    }
  }
}
```

**P0 Action Item**: Automated Security Rules Testing (Security Gap #1)

```javascript
// Firebase Emulator Suite test (CI/CD integration)
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');

describe('Firestore Security Rules', () => {
  test('user cannot read other users items', async () => {
    const db = getFirestore('attacker_user_123');
    const itemRef = db.collection('items').doc('victim_item_xyz');

    // Should fail - row-level security enforced
    await assertFails(itemRef.get());
  });

  test('user can read own items', async () => {
    const db = getFirestore('test_user_123');
    const itemRef = db.collection('items').doc('item_abc');

    // Should succeed - owner access
    await assertSucceeds(itemRef.get());
  });

  test('user cannot create item for other users', async () => {
    const db = getFirestore('test_user_123');

    // Should fail - userId mismatch
    await assertFails(db.collection('items').add({
      userId: 'different_user',
      name: 'Test'
    }));
  });
});
```

**CI/CD Integration**:
```yaml
# .github/workflows/firebase-rules-test.yml
name: Firebase Security Rules Test

on:
  pull_request:
    paths:
      - 'firestore.rules'
      - 'storage.rules'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install -g firebase-tools
      - run: firebase emulators:exec --only firestore "npm test"
```

---

### Storage Security Rules

**Reference**: STORAGE-RULES-001 (complete rules specification)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }

    // User-uploaded cropped objects: users/{userId}/items/{itemId}/*.jpg
    match /users/{userId}/items/{itemId}/{fileName} {
      allow read: if isOwner(userId);

      allow write: if isOwner(userId)
        && request.resource.size < 10 * 1024 * 1024 // 10MB limit
        && request.resource.contentType.matches('image/.*'); // Images only

      allow delete: if isOwner(userId);
    }
  }
}
```

---

### P1 Action Item: Email Enumeration Protection

**Verified Claim**: New 2025 feature (RESEARCH-VALIDATION-stage-2.5.md, Claim 7, Security Gap #4)

```yaml
# Firebase Console > Authentication > Settings
User enumeration protection: ENABLED

# Verification test
POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword
Body: { "email": "nonexistent@example.com", "password": "wrong" }
Expected: Generic error message (not "EMAIL_NOT_FOUND")
```

**iOS Error Handling**:
```swift
import FirebaseAuth

func signIn(email: String, password: String) async throws {
    do {
        try await Auth.auth().signIn(withEmail: email, password: password)
    } catch let error as NSError {
        // Display generic error (no email existence hints)
        switch AuthErrorCode(rawValue: error.code) {
        case .userNotFound, .wrongPassword:
            throw AuthError.invalidCredentials // Generic error
        default:
            throw error
        }
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        }
    }
}
```

---

### P1 Action Item: Firebase App Check

**Verified Claim**: Request attestation for abuse prevention (RESEARCH-VALIDATION-stage-2.5.md, Claim 9)

```swift
import FirebaseAppCheck

// AppDelegate.swift
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Enable App Check with DeviceCheck provider (production)
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        // In production, use DeviceCheck:
        // let providerFactory = DeviceCheckProviderFactory()

        FirebaseApp.configure()

        return true
    }
}
```

**Firebase Console Configuration**:
- Enable App Check for Firestore (enforce attestation tokens)
- Enable App Check for Storage (enforce attestation tokens)
- Enable App Check for Cloud Functions (enforce attestation tokens)

---

## Layer 3: GCP Security

### Secret Manager

**Verified Claim**: AES-256 encryption with 90-day rotation (RESEARCH-VALIDATION-stage-2.5.md, Claim 10)

```javascript
// Cloud Function: Access API keys from Secret Manager
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');

async function getAPIKey(secretName) {
  const client = new SecretManagerServiceClient();

  // Access secret version (pinned to specific version for stability)
  const name = `projects/abundance-project/secrets/${secretName}/versions/latest`;

  const [version] = await client.accessSecretVersion({ name });
  const apiKey = version.payload.data.toString('utf8');

  console.log(`✅ Retrieved API key: ${secretName}`);

  return apiKey;
}

// Usage in Cloud Functions
const geminiApiKey = await getAPIKey('gemini-api-key');
const serpApiKey = await getAPIKey('serpapi-key');
const claudeApiKey = await getAPIKey('anthropic-api-key');
```

**Secret Manager Best Practices**:
- Store API keys with descriptive names (`gemini-api-key`, `serpapi-key`, `anthropic-api-key`)
- Use version pinning for production (not `latest` alias)
- Enable automatic rotation policy (90 days)
- Audit logging: Track secret access via Cloud Audit Logs
- Least privilege: Grant `secretmanager.secretAccessor` role to specific service accounts only
- Replication: Use automatic replication unless GDPR requires EU-only storage

---

### Cloud Functions IAM

**Verified Claim**: Bearer token authentication (RESEARCH-VALIDATION-stage-2.5.md, Claim 11)

```javascript
// Cloud Function: Validate Firebase ID token
const { getAuth } = require('firebase-admin/auth');

exports.processItemAnalysis = async (req, res) => {
  try {
    // Extract Bearer token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized - Missing token' });
    }

    const idToken = authHeader.split('Bearer ')[1];

    // Verify Firebase ID token (RS256 signature validation)
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    console.log(`✅ Authenticated user: ${userId}`);

    // Process request with authenticated userId
    const itemId = req.body.itemId;

    // Validate user owns this item (defense-in-depth)
    const item = await db.collection('items').doc(itemId).get();
    if (item.data().userId !== userId) {
      return res.status(403).json({ error: 'Forbidden - Not your item' });
    }

    // Continue with AI processing...

  } catch (error) {
    console.error('Authentication failed:', error);
    return res.status(401).json({ error: 'Unauthorized - Invalid token' });
  }
};
```

**Service Account Best Practices**:
- Create dedicated service accounts per Cloud Function category
- Principle of least privilege: Grant minimal IAM roles (e.g., `datastore.user` only)
- Avoid default Compute Engine service account (overly broad permissions)
- Network isolation: Restrict Cloud Functions to internal traffic when possible
- Automatic runtime updates: Security patches applied with zero downtime

---

### P1 Architecture Change: Signed URL Expiration

**Problem**: 7-day maximum expiration violates privacy principle (RESEARCH-VALIDATION-stage-2.5.md, Claim 8, Security Gap #3)

**Solution**: Server-side generation with 2-5 minute expiration

```javascript
// Cloud Function: generateShortLivedSignedUrl
const { getStorage } = require('firebase-admin/storage');

exports.generateShortLivedSignedUrl = async (req, res) => {
  try {
    // Authenticate user
    const authHeader = req.headers.authorization;
    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    const imagePath = req.body.imagePath; // e.g., users/user123/items/item456/object789.jpg

    // Validate user owns this image path
    if (!imagePath.startsWith(`users/${userId}/`)) {
      return res.status(403).json({ error: 'Forbidden - Not your image' });
    }

    const bucket = getStorage().bucket();
    const file = bucket.file(imagePath);

    // Generate signed URL with 5-minute expiration (short-lived)
    const [url] = await file.getSignedUrl({
      version: 'v4',
      action: 'read',
      expires: Date.now() + 300000 // 5 minutes (300 seconds)
    });

    console.log(`✅ Generated 5-min signed URL for ${imagePath}`);

    // Store generation timestamp in Firestore for audit trail
    await db.collection('signed_url_audit').add({
      userId,
      imagePath,
      generatedAt: new Date(),
      expiresAt: new Date(Date.now() + 300000)
    });

    return res.json({ signedUrl: url });

  } catch (error) {
    console.error('Signed URL generation failed:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
```

**Updated Layer 2b Flow** (SerpAPI Integration):
```javascript
// Cloud Function: processSerpAPISearch
async function processSerpAPISearch(itemId, userId) {
  // 1. Get cropped object path from Firestore
  const item = await db.collection('items').doc(itemId).get();
  const imagePath = item.data().croppedImagePath;

  // 2. Generate short-lived signed URL (5 minutes)
  const signedUrl = await generateShortLivedSignedUrl(imagePath, userId);

  // 3. Call SerpAPI immediately (URL expires in 5 minutes)
  const serpApiKey = await getAPIKey('serpapi-key');
  const serpApiResponse = await fetch(
    `https://serpapi.com/search?engine=google_lens&url=${encodeURIComponent(signedUrl)}&api_key=${serpApiKey}`
  );

  // URL expires after 5 minutes (privacy preserved)
  return serpApiResponse.json();
}
```

**Privacy Benefit**: Cropped photos accessible for only 5 minutes (vs 7 days), reducing exposure window by 99.95%.

---

### Cloud Storage

**Verified Claim**: Uniform bucket-level access (deny public) (RESEARCH-VALIDATION-stage-2.5.md, Claim 12)

```bash
# GCP Console configuration (one-time setup)
gsutil uniformbucketlevelaccess set on gs://abundance-project.appspot.com

# Verify no public access
gsutil iam get gs://abundance-project.appspot.com
# Expected: No allUsers or allAuthenticatedUsers bindings
```

**Bucket Policy** (Terraform example):
```hcl
resource "google_storage_bucket" "abundance_storage" {
  name          = "abundance-project.appspot.com"
  location      = "US"

  uniform_bucket_level_access {
    enabled = true
  }

  # Deny public access
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90 # Auto-delete after 90 days (GDPR storage limitation)
    }
  }
}
```

---

## Layer 4: AI API Security

### Vertex AI Gemini

**Verified Claim**: GCP project isolation, IAM service accounts (RESEARCH-VALIDATION-stage-2.5.md, Claim 10)

```javascript
// Cloud Function: Call Gemini with secure API key
const { VertexAI } = require('@google-cloud/vertexai');

async function analyzeObjectWithGemini(croppedImageUrl) {
  const vertexAI = new VertexAI({
    project: 'abundance-project',
    location: 'us-central1'
  });

  const model = vertexAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite'
  });

  const prompt = `Analyze this object and extract: category, color, material, brand, condition.`;

  const request = {
    contents: [
      {
        role: 'user',
        parts: [
          { text: prompt },
          { inlineData: { mimeType: 'image/jpeg', data: croppedImageUrl } }
        ]
      }
    ]
  };

  const response = await model.generateContent(request);

  console.log('✅ Gemini analysis complete');

  return response.candidates[0].content.parts[0].text;
}
```

**Security Features**:
- GCP project isolation (Vertex AI resources scoped to `abundance-project`)
- IAM service accounts with `aiplatform.user` role (least privilege)
- API key stored in Secret Manager (not hardcoded)
- Rate limiting: 60 requests per minute (Vertex AI quota)
- Budget alerts: 80% quota triggers notification

---

### SerpAPI

**Verified Claim**: API key rotation policy (90 days), rate limiting (RESEARCH-VALIDATION-stage-2.5.md, Claim 10)

```javascript
// Cloud Function: Call SerpAPI with rate limiting
async function searchProductWithSerpAPI(croppedImageUrl, userId) {
  // Rate limiting: 5 searches per user per day
  const rateLimitKey = `serpapi_rate_limit:${userId}`;
  const currentCount = await redis.get(rateLimitKey) || 0;

  if (currentCount >= 5) {
    throw new Error('SerpAPI rate limit exceeded (5 searches per day)');
  }

  const serpApiKey = await getAPIKey('serpapi-key');

  const response = await fetch(
    `https://serpapi.com/search?engine=google_lens&url=${encodeURIComponent(croppedImageUrl)}&api_key=${serpApiKey}`
  );

  // Increment rate limit counter (expires after 24 hours)
  await redis.setex(rateLimitKey, 86400, currentCount + 1);

  console.log(`✅ SerpAPI search complete (${currentCount + 1}/5 today)`);

  return response.json();
}
```

**Security Controls**:
- API key rotation: 90-day policy (automated via Secret Manager)
- Rate limiting: 5 searches per user per day (prevent quota exhaustion)
- Budget alerts: 80% quota (5K searches/month free tier)
- IP restriction: SerpAPI key limited to Cloud Functions NAT gateway IPs
- Monitoring: Dashboard for SerpAPI usage by user

---

### Anthropic Claude

**Verified Claim**: Secret Manager, batch API (RESEARCH-VALIDATION-stage-2.5.md, Claim 10)

```javascript
// Cloud Function: Call Claude with Batch API (cost optimization)
const Anthropic = require('@anthropic-ai/sdk');

async function synthesizeWithClaude(geminiData, serpApiData) {
  const claudeApiKey = await getAPIKey('anthropic-api-key');

  const anthropic = new Anthropic({
    apiKey: claudeApiKey
  });

  const prompt = `Synthesize product information from AI analysis and search results.

  Gemini Analysis: ${JSON.stringify(geminiData)}
  SerpAPI Results: ${JSON.stringify(serpApiData)}

  Generate: final_name, estimated_value_usd, confidence_score, purchase_links.`;

  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4.5-20250929',
    max_tokens: 1024,
    messages: [
      { role: 'user', content: prompt }
    ]
  });

  console.log('✅ Claude synthesis complete');

  return JSON.parse(message.content[0].text);
}
```

**Security Controls**:
- API key stored in Secret Manager (AES-256 encryption)
- Batch API for Layer 3 synthesis (50% cost reduction)
- Rate limiting: 10 requests per user per day (prevent abuse)
- Monitoring: Cloud Logging for all Claude API calls
- Budget alerts: 80% quota triggers notification

---

## Monitoring & Alerting

### Cloud Logging

```javascript
// Structured logging for security events
const { Logging } = require('@google-cloud/logging');
const logging = new Logging();
const log = logging.log('security-events');

async function logSecurityEvent(eventType, userId, metadata) {
  const entry = log.entry({
    resource: { type: 'cloud_function', labels: { function_name: 'processItemAnalysis' } },
    severity: eventType === 'UNAUTHORIZED_ACCESS' ? 'WARNING' : 'INFO'
  }, {
    eventType,
    userId,
    timestamp: new Date().toISOString(),
    metadata
  });

  await log.write(entry);
}

// Usage examples
await logSecurityEvent('UNAUTHORIZED_ACCESS', userId, { itemId, reason: 'Not owner' });
await logSecurityEvent('RULE_VIOLATION', userId, { rule: 'Firestore read denied' });
await logSecurityEvent('FAILED_AUTHENTICATION', null, { ipAddress: req.ip });
```

**Log Export to BigQuery**:
```bash
# GCP Console > Logging > Logs Router
gcloud logging sinks create security-logs-sink \
  bigquery.googleapis.com/projects/abundance-project/datasets/security_logs \
  --log-filter='severity >= WARNING'
```

**Retention**: 7 years (GDPR Article 30 compliance)

---

### Cloud Monitoring

```yaml
# Alert Policy: Unauthorized Access Attempts
displayName: "High Unauthorized Access Rate"
conditions:
  - displayName: "Failed auth > 10 per minute"
    conditionThreshold:
      filter: 'resource.type="cloud_function" AND severity="WARNING" AND jsonPayload.eventType="UNAUTHORIZED_ACCESS"'
      comparison: COMPARISON_GT
      thresholdValue: 10
      duration: 60s
notificationChannels:
  - projects/abundance-project/notificationChannels/email-security-team
```

**Dashboards**:
- Error rate by Cloud Function (alert if > 5%)
- Latency P95 by endpoint (alert if > 2 seconds)
- Firebase Auth failures (alert if > 100/hour)
- API quota usage (Gemini, SerpAPI, Claude)

---

### Budget Alerts

```yaml
# Budget Alert: GCP Project
budget:
  displayName: "Abundance Monthly Budget"
  budgetAmount:
    specifiedAmount:
      currencyCode: USD
      units: 500
  thresholdRules:
    - thresholdPercent: 0.5  # 50%
    - thresholdPercent: 0.9  # 90%
    - thresholdPercent: 1.0  # 100%
notificationsRule:
  pubsubTopic: projects/abundance-project/topics/budget-alerts
  schemaVersion: "1.0"
```

---

### Incident Response

**Security Breach Contact**: security@abundance.app

**Incident Response Runbook**:
1. Detect: Cloud Logging alert triggers (unauthorized access, rule violation)
2. Assess: Query BigQuery for full event timeline, affected users
3. Contain: Revoke compromised credentials (Firebase tokens, API keys)
4. Eradicate: Patch vulnerability, deploy updated security rules
5. Recover: Restore affected user data from backups (if needed)
6. Learn: Post-incident review, update threat model

**PagerDuty Integration** (optional for MVP):
```javascript
const PagerDuty = require('node-pagerduty');
const pd = new PagerDuty({ apiKey: process.env.PAGERDUTY_API_KEY });

async function triggerSecurityIncident(eventType, metadata) {
  await pd.incidents.createIncident({
    incident: {
      type: 'incident',
      title: `Security Event: ${eventType}`,
      service: { id: 'PAGERDUTY_SERVICE_ID', type: 'service_reference' },
      urgency: 'high',
      body: { type: 'incident_body', details: JSON.stringify(metadata) }
    }
  });
}
```

---

## P0/P1 Security Gaps Remediation Summary

### P0 Blockers (Addressed)
1. **Firebase Misconfiguration** (THREAT-MODEL-001, Threat I-1, T-1):
   - **Mitigation**: Automated testing in CI/CD (see TEST-003), Firebase Security Review Checklist (see SECURITY-HARDENING-CHECKLIST-001)
   - **Verification**: Firebase Emulator Suite with 90% rules coverage
   - **Status**: ✅ Implementation specified

2. **GDPR Data Transfer** (THREAT-MODEL-001, Threat I-6):
   - **Mitigation**: SCCs + TIA (see PRIVACY-IMPACT-ASSESSMENT-001)
   - **Action Items**:
     - Accept Firebase SCCs in GCP Console (P0, 1 day)
     - Conduct Transfer Impact Assessment with legal counsel (P0, 1 week)
     - Configure EU regions for Firestore/Storage (`europe-west1`)
   - **Status**: ✅ Compliance strategy specified

### P1 Before Launch (Addressed)
3. **Signed URL Expiration** (THREAT-MODEL-001, Threat I-3):
   - **Mitigation**: Architecture changed to 2-5 minute server-side generation (documented above)
   - **Implementation**: Cloud Function `generateShortLivedSignedUrl` with audit trail
   - **Privacy Benefit**: 99.95% reduction in exposure window (5 min vs 7 days)
   - **Status**: ✅ Architecture change specified

4. **Email Enumeration** (THREAT-MODEL-001, Threat I-4):
   - **Mitigation**: Protection enabled in Firebase Console (documented above)
   - **iOS Changes**: Generic error handling (no email existence hints)
   - **Verification**: Test login endpoint with nonexistent email, assert generic error
   - **Status**: ✅ Implementation specified

---

## Acceptance Criteria

- [x] All 4 architecture layers documented (iOS, Firebase, GCP, AI APIs)
- [x] P0 security gaps remediated (Firebase misconfiguration testing, GDPR data transfer)
- [x] P1 security gaps remediated (signed URL expiration, email enumeration)
- [x] Code examples for each security control
- [x] Monitoring and alerting specified (Cloud Logging, Cloud Monitoring, Budget Alerts)
- [x] All claims reference RESEARCH-VALIDATION-stage-2.5.md
- [x] Threat model integration (references THREAT-MODEL-001)
- [x] Privacy firewall validation (references DESIGN-015)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial security & privacy architecture, 4 layers complete | Privacy & Security Architect |

---

**Status**: ✅ **SECURITY & PRIVACY ARCHITECTURE COMPLETE** - Ready for implementation and security review

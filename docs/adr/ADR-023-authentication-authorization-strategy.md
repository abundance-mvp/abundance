# ADR-023: Authentication & Authorization Strategy

**Status**: Approved
**Date**: 2025-11-09
**Deciders**: Privacy & Security Architect
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-2.5.md (Claims 2, 6, 7)
- docs/design/DESIGN-025-security-privacy-architecture.md
- docs/design/THREAT-MODEL-001-stride-analysis.md (Threats S-1, S-2, I-4, E-2)
- docs/design/SECURITY-RULES-001-firestore-rules.md

---

## Context

Abundance MVP requires a secure authentication and authorization strategy that:
1. Provides seamless user authentication with privacy protections (Apple Sign-In)
2. Enforces row-level access control in Firestore and Firebase Storage
3. Supports premium feature authorization via custom claims
4. Prevents email enumeration attacks (P1 security gap from THREAT-MODEL-001)
5. Maintains session security with automatic token refresh and logout

This ADR documents the complete authentication flow (Apple Sign-In → Firebase), authorization patterns (Firestore rules, Storage rules, Cloud Functions), and session management strategy with code examples and verification procedures.

---

## Decision

We will implement **Apple Sign-In as the primary authentication provider** with Firebase Authentication as the identity backend, enforcing **row-level authorization** via Firestore Security Rules and **custom claims** for premium feature access.

---

## Authentication Flow

### Apple Sign-In → Firebase Authentication

**Verified Claim**: OAuth 2.0 with privacy protections (RESEARCH-VALIDATION-stage-2.5.md, Claim 2)

#### Step-by-Step Flow

1. **User taps "Sign in with Apple"**
2. **ASAuthorizationController** presents Face ID/Touch ID prompt (OAuth 2.0 authorization)
3. **iOS returns ASAuthorizationAppleIDCredential** (ID token with cryptographic signature)
4. **App exchanges Apple token for Firebase ID token** (via Firebase Auth SDK)
5. **Firebase ID token stored in Keychain** (AES-256-GCM encryption, ADR-021)
6. **Token refresh**: Automatic via Firebase SDK (1 hour expiration, refresh token in Keychain)

#### Implementation

```swift
import AuthenticationServices
import FirebaseAuth

/// Manager for Apple Sign-In authentication flow
class AppleSignInManager: NSObject, ObservableObject {

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private var currentNonce: String?

    /// Initiate Apple Sign-In flow
    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce

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

        guard let nonce = currentNonce else {
            print("Invalid state: Nonce missing")
            return
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to fetch identity token")
            return
        }

        // Exchange Apple ID token for Firebase credential
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )

        // Sign in to Firebase
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Firebase authentication failed: \(error.localizedDescription)")
                return
            }

            guard let user = authResult?.user else { return }

            // Store Firebase ID token in Keychain (AES-256-GCM encryption)
            user.getIDToken { token, error in
                if let token = token {
                    do {
                        try KeychainManager().storeToken(token, forKey: "firebase_id_token")
                        print("✅ Firebase ID token stored in Keychain")
                    } catch {
                        print("⚠️ Failed to store token: \(error)")
                    }
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

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}
```

#### Security Features
- **OAuth 2.0 authorization code flow**: Single-use codes prevent replay attacks
- **Nonce-based replay protection**: Cryptographic randomness (32 bytes)
- **Private email relay**: Protects user email addresses (optional feature)
- **Two-factor authentication**: Built-in via Apple ID infrastructure
- **Automatic credential revocation**: When user removes app access in Apple ID settings
- **TLS 1.2+ encryption**: All network requests via App Transport Security (ADR-021)

---

## Authorization Patterns

### Firestore Row-Level Security

**Verified Claim**: `request.auth.uid` validation (RESEARCH-VALIDATION-stage-2.5.md, Claim 6)

#### Firestore Security Rules (SECURITY-RULES-001)

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

    function isPremium() {
      return isSignedIn() && request.auth.token.premium == true;
    }

    // Users collection: users can only access their own profile
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
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

    // Premium features: require custom claim
    match /premium_templates/{templateId} {
      allow read: if isPremium();
      allow write: if false; // Admin-only
    }

    // Admin operations: require admin custom claim
    match /admin/{document=**} {
      allow read, write: if request.auth.token.admin == true;
    }
  }
}
```

#### Rule Validation Test

```javascript
// Firebase Emulator Suite test (CI/CD integration)
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');

describe('Firestore Authorization', () => {
  test('user cannot read other users items', async () => {
    const db = getFirestore('attacker_user_123');
    const itemRef = db.collection('items').doc('victim_item_xyz');

    // Should fail - row-level security enforced
    await assertFails(itemRef.get());
  });

  test('user can read own items', async () => {
    const db = getFirestore('test_user_123');
    const itemRef = db.collection('items').doc('item_owned_by_test_user_123');

    // Should succeed - owner access
    await assertSucceeds(itemRef.get());
  });

  test('user cannot create item for other users', async () => {
    const db = getFirestore('test_user_123');

    // Should fail - userId mismatch
    await assertFails(db.collection('items').add({
      userId: 'different_user',
      name: 'Test Item',
      status: 'processing'
    }));
  });

  test('user cannot access premium features without custom claim', async () => {
    const db = getFirestore('free_user_123'); // No premium claim

    // Should fail - requires premium custom claim
    await assertFails(db.collection('premium_templates').doc('template_xyz').get());
  });

  test('premium user can access premium features', async () => {
    const db = getFirestore('premium_user_123', { premium: true }); // Has premium claim

    // Should succeed - premium custom claim present
    await assertSucceeds(db.collection('premium_templates').doc('template_xyz').get());
  });
});
```

---

### Firebase Storage Authorization

#### Storage Security Rules (STORAGE-RULES-001)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }

    // User-uploaded cropped objects: users/{userId}/items/{itemId}/objects/*.jpg
    match /users/{userId}/items/{itemId}/objects/{fileName} {
      allow read: if isOwner(userId);

      allow write: if isOwner(userId)
        && request.resource.size < 10 * 1024 * 1024 // 10MB limit
        && request.resource.contentType.matches('image/.*'); // Images only

      allow delete: if isOwner(userId);
    }

    // Block all other paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

### Cloud Functions Authorization

#### Bearer Token Validation

```javascript
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

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
    const db = getFirestore();
    const itemDoc = await db.collection('items').doc(itemId).get();

    if (!itemDoc.exists) {
      return res.status(404).json({ error: 'Item not found' });
    }

    if (itemDoc.data().userId !== userId) {
      return res.status(403).json({ error: 'Forbidden - Not your item' });
    }

    // Continue with AI processing...
    const result = await analyzeItem(itemId, userId);

    return res.json({ success: true, result });

  } catch (error) {
    console.error('Authentication failed:', error);
    return res.status(401).json({ error: 'Unauthorized - Invalid token' });
  }
};
```

---

## Session Management

### Token Lifecycle

#### 1. Token Expiration
- **Firebase ID Token**: 1 hour (Firebase default)
- **Refresh Token**: Long-lived (stored in Keychain), used to obtain new ID tokens
- **Automatic Refresh**: Firebase SDK handles token refresh automatically before expiration

#### 2. Token Refresh Strategy

```swift
import FirebaseAuth

class SessionManager {

    /// Get valid Firebase ID token (automatic refresh if expired)
    func getValidIDToken() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw SessionError.notAuthenticated
        }

        // Firebase SDK automatically refreshes if token expired
        let token = try await currentUser.getIDToken(forcingRefresh: false)

        print("✅ Valid ID token obtained")

        return token
    }

    /// Force token refresh (for testing or manual refresh)
    func forceRefreshToken() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw SessionError.notAuthenticated
        }

        let token = try await currentUser.getIDToken(forcingRefresh: true)

        // Store refreshed token in Keychain
        try KeychainManager().storeToken(token, forKey: "firebase_id_token")

        print("✅ Token manually refreshed")

        return token
    }
}

enum SessionError: Error {
    case notAuthenticated
    case tokenRefreshFailed
}
```

#### 3. Logout Flow

```swift
class SessionManager {

    /// Logout user (delete Keychain tokens, revoke Firebase session)
    func logout() throws {
        // Delete Firebase ID token from Keychain
        try KeychainManager().deleteToken(forKey: "firebase_id_token")

        // Revoke Firebase session
        try Auth.auth().signOut()

        print("✅ User logged out, tokens deleted")
    }
}
```

#### 4. Session Persistence
- **Default**: Session persists across app launches (refresh token in Keychain)
- **No automatic timeout**: Session remains active until user logs out or revokes access
- **Optional**: Implement inactivity timeout (future enhancement)

```swift
// Optional: Inactivity timeout (future enhancement)
class SessionManager {
    private var lastActivityTime: Date?
    private let inactivityTimeout: TimeInterval = 15 * 60 // 15 minutes

    func checkSessionTimeout() throws {
        guard let lastActivity = lastActivityTime else { return }

        let elapsed = Date().timeIntervalSince(lastActivity)

        if elapsed > inactivityTimeout {
            print("⚠️ Session expired due to inactivity")
            try logout()
            throw SessionError.sessionExpired
        }
    }

    func updateActivity() {
        lastActivityTime = Date()
    }
}
```

---

## P1 Security Gap: Email Enumeration Protection

**Verified Claim**: New 2025 feature (RESEARCH-VALIDATION-stage-2.5.md, Claim 7, Security Gap #4)

### Firebase Console Configuration

```yaml
# Firebase Console > Authentication > Settings
User enumeration protection: ENABLED

# Configuration applies to:
# - Sign-in endpoint (identitytoolkit.googleapis.com/v1/accounts:signInWithPassword)
# - Password reset endpoint (identitytoolkit.googleapis.com/v1/accounts:resetPassword)
# - Email verification endpoint

# Behavior:
# - Generic error messages for failed logins (no distinction between "user not found" vs "wrong password")
# - Rate limiting on sign-in attempts (configurable quota)
# - Same response time for valid/invalid emails (prevents timing attacks)
```

### iOS Error Handling (Generic Errors)

```swift
import FirebaseAuth

class AuthenticationService {

    enum AuthError: Error, LocalizedError {
        case invalidCredentials
        case networkError
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid email or password. Please try again."
            case .networkError:
                return "Network error. Please check your connection."
            case .unknown:
                return "An error occurred. Please try again."
            }
        }
    }

    /// Sign in with email/password (generic error handling)
    func signIn(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let error as NSError {
            // Display generic error (no email existence hints)
            switch AuthErrorCode(rawValue: error.code) {
            case .userNotFound, .wrongPassword, .invalidEmail:
                throw AuthError.invalidCredentials // Generic error
            case .networkError:
                throw AuthError.networkError
            default:
                throw AuthError.unknown
            }
        }
    }
}
```

### Verification Test

```bash
# Test email enumeration protection (should return generic error)
POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword
Content-Type: application/json

{
  "email": "nonexistent@example.com",
  "password": "wrong_password",
  "returnSecureToken": true
}

# Expected Response (with email enumeration protection ENABLED):
{
  "error": {
    "code": 400,
    "message": "INVALID_LOGIN_CREDENTIALS", // Generic error (not "EMAIL_NOT_FOUND")
    "errors": [
      {
        "message": "INVALID_LOGIN_CREDENTIALS",
        "domain": "global",
        "reason": "invalid"
      }
    ]
  }
}

# Old Response (without email enumeration protection):
{
  "error": {
    "code": 400,
    "message": "EMAIL_NOT_FOUND", // ⚠️ Reveals email existence
    ...
  }
}
```

---

## Premium Feature Authorization

### Custom Claims Management

#### Set Custom Claims (Cloud Function - Admin Only)

```javascript
const { getAuth } = require('firebase-admin/auth');

exports.setPremiumClaim = async (req, res) => {
  try {
    // Verify admin authorization
    const adminToken = req.headers.authorization.split('Bearer ')[1];
    const decodedToken = await getAuth().verifyIdToken(adminToken);

    if (!decodedToken.admin) {
      return res.status(403).json({ error: 'Forbidden - Admin only' });
    }

    const userId = req.body.userId;
    const isPremium = req.body.isPremium;

    // Set custom claim
    await getAuth().setCustomUserClaims(userId, { premium: isPremium });

    console.log(`✅ Premium claim set for user ${userId}: ${isPremium}`);

    return res.json({ success: true });

  } catch (error) {
    console.error('Failed to set custom claim:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
```

#### Verify Custom Claims (iOS Client)

```swift
import FirebaseAuth

class PremiumFeatureManager {

    /// Check if user has premium access
    func isPremiumUser() async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            return false
        }

        // Get ID token result (includes custom claims)
        let result = try await currentUser.getIDTokenResult(forcingRefresh: false)

        // Check premium custom claim
        if let premium = result.claims["premium"] as? Bool {
            return premium
        }

        return false
    }

    /// Enforce premium access for feature
    func requirePremiumAccess() async throws {
        let isPremium = try await isPremiumUser()

        guard isPremium else {
            throw PremiumError.subscriptionRequired
        }
    }
}

enum PremiumError: Error, LocalizedError {
    case subscriptionRequired

    var errorDescription: String? {
        switch self {
        case .subscriptionRequired:
            return "This feature requires a premium subscription."
        }
    }
}
```

---

## Consequences

### Positive
- ✅ Seamless authentication via Apple Sign-In (OAuth 2.0 with privacy protections)
- ✅ Row-level access control enforced via Firestore Security Rules (verified Claim 6)
- ✅ Email enumeration protection enabled (P1 security gap resolved, verified Claim 7)
- ✅ Automatic token refresh (1 hour expiration, no manual intervention required)
- ✅ Hardware-backed token storage (iOS Keychain with AES-256-GCM, ADR-021)
- ✅ Premium feature authorization via custom claims (no client-side bypass possible)

### Negative
- ⚠️ Apple Sign-In requires Apple Developer account (annual fee)
  - **Mitigation**: Cost justified by privacy guarantees and seamless UX
- ⚠️ Custom claims require Cloud Function deployment for updates
  - **Mitigation**: Acceptable overhead for premium feature authorization
- ⚠️ Email enumeration protection requires Firebase Console configuration (manual step)
  - **Mitigation**: Documented in SECURITY-HARDENING-CHECKLIST-001 (P1 pre-launch)

### Trade-offs
- **Privacy vs. Email Sharing**: Apple Sign-In private email relay hides user email
  - **Decision**: Accept private email (enhances privacy positioning)
  - **Impact**: Support communication requires in-app messaging (not direct email)
- **Session Persistence vs. Security**: No automatic timeout (session persists until logout)
  - **Decision**: Accept persistent sessions for better UX
  - **Future Enhancement**: Optional inactivity timeout for high-security users

---

## Compliance

### GDPR
- **Article 5**: Data minimization (only email + userId stored, no unnecessary data) ✅
- **Article 25**: Privacy by design (private email relay, minimal data collection) ✅
- **Article 32**: Security of processing (hardware-backed encryption, TLS 1.2+) ✅

### CCPA
- **Section 1798.100**: Notice at collection (privacy policy discloses email/userId) ✅
- **Section 1798.105**: Right to delete (account deletion removes auth data) ✅

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial authentication & authorization strategy | Privacy & Security Architect |

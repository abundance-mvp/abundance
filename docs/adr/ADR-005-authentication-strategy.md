# ADR-005: Authentication Strategy

**Status**: Approved
**Date**: 2025-11-08
**Decision Makers**: Engineering Leadership, iOS Developer, Security Engineer
**Related Documents**:
- docs/adr/ADR-001-strategic-positioning.md (privacy-first requirement)
- docs/adr/ADR-002-platform-strategy.md (product strategy)
- docs/archive/adr/ADR-004-ios-26-only-launch.md (iOS 26 requirement, archived)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Context

Abundance needs user authentication for:
- Catalog ownership (items belong to specific users)
- Premium subscription management (free vs premium tier)
- Multi-device sync (catalog accessible on all user devices)
- Privacy enforcement (users only see their own data)

**Requirements**:
- Privacy-first (ADR-001): No email/password collection if possible
- iOS 26-only (ADR-004): Leverage latest iOS auth capabilities
- GCP platform: Seamless Firebase integration
- Free tier sustainable: Low cost for 85% of users

---

## Decision

**Use Firebase Authentication with Apple Sign-In as the primary authentication method.**

### Specifications

- **Identity Provider**: Apple Sign-In (ASAuthorizationController, iOS 13+)
- **Auth Service**: Firebase Authentication
- **Token Management**: Firebase ID tokens (JWT)
- **Session Persistence**: Keychain storage (iOS Keychain Services)
- **Premium Status**: Firebase Auth Custom Claims (set by Cloud Functions)

---

## Rationale

### 1. Privacy-First Compliance

**Requirement** (ADR-001): Minimize personal data collection.

**Solution**: Apple Sign-In allows users to hide email addresses (Apple relay email) or authenticate without email at all.

**Flow**:
1. User taps "Sign in with Apple"
2. iOS prompts for Face ID/Touch ID (biometric auth)
3. Apple returns opaque user ID (no email required)
4. Firebase Auth creates user account with Apple UID

**Outcome**: Zero email addresses collected if user chooses privacy option.

---

### 2. Native iOS Integration

**Requirement** (ADR-004): iOS 26-only app, leverage platform capabilities.

**Solution**: AuthenticationServices framework provides native Apple Sign-In UI.

**Benefits**:
- **Native UI**: iOS system sheet (no custom login screen)
- **Biometric Auth**: Face ID/Touch ID integration
- **Security**: No password storage, Apple handles auth flow
- **User Trust**: "Sign in with Apple" badge signals privacy

**Code Example** (iOS 26):
```swift
import AuthenticationServices
import FirebaseAuth

func signInWithApple() {
    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()
    request.requestedScopes = [.fullName] // Email optional

    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.performRequests()
}

func didCompleteAuthorization(_ authorization: ASAuthorization) {
    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
    let idToken = appleIDCredential.identityToken
    let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: String(data: idToken, encoding: .utf8)!)

    Auth.auth().signIn(with: credential) { result, error in
        // User signed in, Firebase user created
    }
}
```

---

### 3. Firebase Auth Cost Efficiency

**Requirement**: Free tier must support 85% of users (4,250 users @ Month 6).

**Solution**: Firebase Auth free tier = 10,000 monthly active users (MAU).

**Cost Comparison**:

| Service | Free Tier | Cost (5,000 MAU) |
|---------|-----------|------------------|
| **Firebase Auth** | **10K MAU** | **$0** |
| Auth0 | 7K MAU | $23/month (5K users) |
| Supabase Auth | Unlimited (self-hosted) | $25/month (hosting) |
| Custom OAuth | N/A | $50/month (server) |

**Outcome**: Month 6 (5,000 users) = $0 auth cost. Scales to 10K users before paid tier.

---

### 4. GCP Ecosystem Integration

**Requirement** (ADR-002): GCP/Firebase platform for backend.

**Solution**: Firebase Auth natively integrates with Cloud Functions and Firestore.

**Integration Benefits**:
- **Cloud Functions Auth Context**: `context.auth.uid` automatically available
- **Firestore Security Rules**: `request.auth.uid` for row-level security
- **No Token Verification Code**: Firebase SDK handles JWT validation
- **Custom Claims**: Set premium status in user token (readable by iOS app)

**Example** (Cloud Functions):
```javascript
exports.analyzeItem = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
    }

    const userId = context.auth.uid;
    const isPremium = context.auth.token.premium || false; // Custom claim

    // Process item catalog for userId...
});
```

**Example** (Firestore Security Rules):
```javascript
match /items/{itemId} {
  allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
}
```

**Outcome**: Seamless auth enforcement across iOS, Cloud Functions, Firestore.

---

## Alternatives Considered

### Alternative 1: Custom OAuth (Email/Password)

**Approach**: Build custom authentication with email/password, JWT tokens.

**Pros**:
- Full control over auth flow
- No third-party dependency

**Cons**:
- **Privacy violation**: Email collection conflicts with ADR-001
- **Development overhead**: 2-3 weeks to build secure auth
- **Security risk**: Password storage, hashing, token refresh logic
- **Cost**: Custom server required ($50/month minimum)

**Why Rejected**: Contradicts privacy-first positioning, high development cost.

---

### Alternative 2: Auth0

**Approach**: Use Auth0 SaaS for authentication, integrate with Firebase.

**Pros**:
- Enterprise-grade auth
- Social login options (Google, Facebook, Apple)
- Advanced features (MFA, passwordless)

**Cons**:
- **Cost**: $23/month for 5K users (vs $0 Firebase)
- **Complexity**: Dual integration (Auth0 + Firebase)
- **Over-engineered**: MVP doesn't need MFA or enterprise features

**Why Rejected**: Cost and complexity unjustified for Phase 1 MVP.

---

### Alternative 3: Supabase Auth

**Approach**: Use Supabase (open-source Firebase alternative) for auth + database.

**Pros**:
- Free tier (unlimited auth)
- PostgreSQL database (vs Firestore NoSQL)

**Cons**:
- **Platform mismatch**: Requires switching from GCP to Supabase hosting (contradicts ADR-002)
- **Ecosystem fragmentation**: AI stack (Vertex AI, Cloud Functions) stays on GCP, split architecture
- **Offline support**: Weaker than Firestore for real-time sync

**Why Rejected**: Platform fragmentation, contradicts GCP platform decision.

---

## Implications & Consequences

### Positive

1. **Privacy Compliance**: Apple Sign-In satisfies privacy-first requirement (no email required)
2. **Zero Auth Cost**: Firebase free tier covers 10K MAU (Phase 1 + Phase 2)
3. **Native iOS UX**: AuthenticationServices framework = seamless biometric auth
4. **GCP Integration**: Cloud Functions + Firestore auth context automatic

---

### Negative

1. **iOS-Only Auth**: Apple Sign-In works best on iOS (web version less elegant)
   - **Mitigation**: Phase 2 PWA can use Firebase Auth UI (email/password fallback)
2. **Vendor Lock-In**: Firebase Auth proprietary (migration to custom auth = major refactor)
   - **Mitigation**: Standard JWT tokens, can export user IDs if needed

---

## Implementation Details

### iOS Sign-In Flow

1. User opens app → "Sign in with Apple" button
2. iOS prompts for Face ID/Touch ID
3. Apple returns `ASAuthorizationAppleIDCredential`
4. iOS app sends credential to Firebase Auth
5. Firebase creates user account, returns Firebase ID token
6. iOS app stores token in Keychain
7. Subsequent API calls include token in `Authorization: Bearer <token>` header

---

### Premium Subscription Management

**Custom Claims** (set by Cloud Functions when user subscribes):

```javascript
// Cloud Function (triggered by Stripe webhook)
exports.handleSubscriptionCreated = functions.firestore
    .document('subscriptions/{subscriptionId}')
    .onCreate(async (snap, context) => {
        const subscription = snap.data();
        await admin.auth().setCustomUserClaims(subscription.userId, { premium: true });
    });
```

**iOS App** (reads custom claim from token):
```swift
Auth.auth().currentUser?.getIDTokenResult { result, error in
    let isPremium = result?.claims["premium"] as? Bool ?? false
    // Show premium features if isPremium == true
}
```

---

### Firestore Security Rules

**Row-Level Security** (users only access their own items):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /items/{itemId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Acceptance Criteria

- [x] ✅ Apple Sign-In integrated with Firebase Auth
- [x] ✅ Firebase ID tokens stored in iOS Keychain
- [x] ✅ Cloud Functions verify auth via `context.auth.uid`
- [x] ✅ Firestore Security Rules enforce row-level access
- [x] ✅ Custom claims support premium tier (set by Cloud Functions)
- [x] ✅ Free tier cost = $0 for 10K MAU

---

## Related Decisions

- **ADR-001**: Strategic positioning (privacy-first) → Requires Apple Sign-In (no email)
- **ADR-002**: Platform strategy (product strategy) → Firebase Auth native integration
- **ADR-004**: iOS 26-only launch (archived: `docs/archive/adr/ADR-004-ios-26-only-launch.md`) → Leverage AuthenticationServices framework
- **ADR-006**: Database selection (Firestore) → Security Rules use `request.auth.uid`

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, Firebase Auth + Apple Sign-In | Software Architecture Expert |

---

**This authentication strategy supports privacy-first positioning (ADR-001), GCP/Firebase platform integration, and iOS 26 premium UX (ADR-004, archived).**

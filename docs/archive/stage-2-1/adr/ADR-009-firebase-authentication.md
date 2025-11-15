# ADR-009: Firebase Authentication

**Status:** Approved
**Date:** 2025-10-24
**Decision Makers:** Engineering Leadership, Security Lead
**Related Documents:** TECH-STACK-001, ADR-005

---

## Context

Authentication provider selection for Abundance MVP: Firebase Auth vs. custom solution

---

## Decision

**We will use Firebase Authentication with Apple Sign-In as primary method.**

### Authentication Methods

| Method | Purpose | Expected Adoption |
|--------|---------|-------------------|
| **Apple Sign-In** | Primary (Sign in with Apple) | 70% |
| **Email/Password** | Fallback | 25% |
| **Anonymous** | Trial (10 items max, then upgrade) | 5% |

---

## Rationale

### 1. Apple Sign-In Integration (2 Lines of Code)

**Firebase:**
```swift
import FirebaseAuth

let provider = OAuthProvider(providerID: "apple.com")
Auth.auth().signIn(with: provider) { result, error in
    // Done - user is authenticated
}
```

**Custom Solution:**
- Requires Apple Developer setup (Sign in with Apple capability)
- Manual JWT validation
- User management database
- **Estimated effort:** 2-4 weeks

---

### 2. Anonymous Upgrade Flow

**Requirement:** Users try app without signing in (10 items max), then upgrade to permanent account

**Firebase:**
```swift
// 1. Anonymous sign-in (automatic)
Auth.auth().signInAnonymously()

// 2. User catalogs 10 items

// 3. Upgrade to permanent account
let credential = OAuthProvider.credential(...)
Auth.auth().currentUser?.link(with: credential)  // Anonymous → Apple Sign-In
```

**Custom Solution:**
- Complex migration logic (anonymous → permanent)
- Risk of data loss during upgrade

---

### 3. Free Tier (50K MAU)

**Cost (Month 6, 5,000 users):**
- Firebase Auth: $0 (within 50K MAU limit)
- Custom solution: $50-100/month (server costs + maintenance)

---

## Alternatives Considered

### Alternative 1: Custom Auth (Roll Our Own)

**Pros:**
- Full control (custom user fields, custom logic)
- No vendor lock-in

**Cons:**
- **Security risk:** Password hashing, JWT signing, token refresh logic (easy to get wrong)
- **Time:** 2-4 weeks to build, 1-2 weeks/month to maintain
- **No Apple Sign-In SDK:** Would need to implement OAuth flow manually

**Why Rejected:** Firebase Auth is more secure, faster, cheaper

---

### Alternative 2: Auth0 / Supabase Auth

**Pros:**
- More features than Firebase (custom user metadata, webhooks)
- Open-source (Supabase)

**Cons:**
- **Cost:** Auth0 = $25/month minimum, Supabase = $25/month
- **Firebase integration:** Would need to sync Auth0 users → Firebase UID (complex)

**Why Rejected:** Firebase Auth is better integrated with Firestore, free tier is sufficient

---

## Security Considerations

### App Check (Anti-Abuse)

**Problem:** Without App Check, anyone can call Cloud Functions directly (bypass app)

**Solution:**
```swift
// iOS: Enable App Check
FirebaseApp.configure()
AppCheck.setAppCheckProviderFactory(AppAttestProvider.self)

// Cloud Functions: Require App Check token
exports.enrichItem = functions.https.onCall({ enforceAppCheck: true }, async (data, context) => {
    // Only accepts requests from verified iOS app
});
```

---

### JWT Token Refresh

**Firebase:** Automatic token refresh (iOS SDK handles it)
- Tokens expire in 1 hour
- SDK refreshes automatically before expiration

**Custom Solution:** Would need to implement refresh logic manually

---

## Stakeholder Sign-Off

- [ ] **Engineering Leadership**
- [ ] **Security Lead** (approve App Check strategy)

**Timeline:** Finalized by 2025-10-31

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial Firebase Auth decision | Stage 2.1 Execution |

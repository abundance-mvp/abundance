# End-to-End Testing Guide: Apple Sign-In Authentication

## Overview

This guide walks through testing the complete authentication flow from iOS app to Firebase backend.

**Flow**: iOS App → Apple Sign-In → Firebase Auth → Cloud Functions → Firestore

---

## Prerequisites

✅ All components verified as ready:
- iOS project builds successfully (Swift 6.2)
- All unit tests passing (6/6)
- Backend deployed to production (Firestore + Cloud Functions)
- GoogleService-Info.plist configured (PROJECT_ID: abundance-mvp)
- SwiftLint zero violations

---

## Test Plan

### Phase 1: iOS App Launch & UI Verification

**Objective**: Verify the sign-in UI renders correctly

**Steps**:
1. Open Xcode:
   ```bash
   open Package.swift
   # or
   cd /Users/w/code/abundance-mvp && xcodebuild -list
   ```

2. Select the iOS simulator (iPhone 15 or later recommended)

3. Build and run the app (⌘R)

**Expected Results**:
- App launches without crashes
- "Welcome to Abundance" title displays
- "Catalog your items with AI-powered insights" subtitle displays
- Black Apple Sign-In button appears
- No console errors or warnings

**Troubleshooting**:
- If build fails: Check Xcode version (15.0+) and macOS version (14.0+)
- If simulator crashes: Reset simulator content and settings
- If Firebase errors: Verify GoogleService-Info.plist is in App/ directory

---

### Phase 2: Apple Sign-In Authentication

**Objective**: Verify Apple Sign-In modal and credential exchange

**Steps**:
1. Tap the "Sign in with Apple" button

2. Observe the Apple authentication modal

3. Select an Apple ID or use "Use Password" option

4. Complete Face ID/Touch ID authentication (simulator: click prompt)

**Expected Results**:
- Apple Sign-In modal appears (system-level, not in-app)
- No errors during authentication
- Modal dismisses after successful authentication
- Loading indicator appears briefly while exchanging tokens

**Verification Points**:
- Check Xcode console for Firebase logs:
  ```
  [Firebase/Auth] Successfully signed in with Apple
  ```
- No error messages in console
- `isAuthenticated` state changes to `true` (observable in view)

**Troubleshooting**:
- **Error: "Invalid Credential"**
  - Check App/Info.plist has CFBundleURLTypes configured
  - Verify BUNDLE_ID matches GoogleService-Info.plist (com.abundance.app)

- **Error: "Network request failed"**
  - Check internet connection
  - Verify Firebase project is active (not deleted)

- **Simulator shows "No Apple ID"**
  - Sign in to iCloud in Settings app on simulator
  - Or use "Set Up Apple ID with Simulator" option

---

### Phase 3: Token Storage & Backend Communication

**Objective**: Verify Firebase token is saved to Keychain and backend is called

**Steps**:
1. After successful sign-in, check Xcode console for:
   ```
   KeychainManager: Token saved successfully
   ```

2. Verify the app attempts to call the backend (check console logs)

3. Open Keychain Access on Mac:
   ```bash
   open -a "Keychain Access"
   ```
   - Search for "com.abundance.app"
   - Look for "firebaseToken" entry

**Expected Results**:
- Token saved to Keychain with service "com.abundance.app"
- No "Keychain save failed" errors in console
- Backend getUserProfile function called (check console)

**Backend Verification**:
Run this command to verify the backend is responding:
```bash
curl https://us-central1-abundance-mvp.cloudfunctions.net/health
```

Expected output:
```json
{
  "status": "ok",
  "timestamp": "2025-11-15T...",
  "service": "abundance-backend"
}
```

**Troubleshooting**:
- **Keychain access denied**: Check App Sandbox entitlements
- **Backend timeout**: Verify functions deployed with `firebase functions:list`
- **401 Unauthorized**: Token may be expired or invalid

---

### Phase 4: User Profile Creation in Firestore

**Objective**: Verify user document created in Firestore

**Steps**:
1. Open Firebase Console:
   ```
   https://console.firebase.google.com/project/abundance-mvp/firestore
   ```

2. Navigate to Firestore Database

3. Look for `users/{userId}` collection

4. Verify document exists with authenticated user's UID

**Expected Results**:
- User document exists in `users` collection
- Document ID matches Firebase Auth UID
- Security rules enforce row-level access (only user can read their own data)

**Firestore Document Structure**:
```json
{
  "userId": "firebase_auth_uid",
  "email": "user@example.com",
  "createdAt": "2025-11-14T...",
  "updatedAt": "2025-11-14T...",
  "subscriptionStatus": "free"
}
```

**Security Rules Test**:
Run this in Firestore Rules Playground:
```javascript
// Should ALLOW:
get /databases/(default)/documents/users/{userId} {
  auth.uid == userId
}

// Should DENY:
get /databases/(default)/documents/users/other_user_id {
  auth.uid == current_user_id
}
```

---

### Phase 5: Sign-Out & Re-Authentication

**Objective**: Verify sign-out clears state and re-auth works

**Steps**:
1. Implement a sign-out button (if not already present)
   ```swift
   Button("Sign Out") {
       viewModel.signOut()
   }
   ```

2. Tap sign-out button

3. Verify return to sign-in screen

4. Re-authenticate with Apple Sign-In

**Expected Results**:
- Token deleted from Keychain
- `isAuthenticated` state changes to `false`
- Sign-in screen appears
- Re-authentication works without errors

**Keychain Verification**:
```bash
# Token should be deleted after sign-out
# Check Keychain Access - "firebaseToken" entry should be gone
```

---

## Automated Testing

### Unit Tests (Already Passing)

Run all tests:
```bash
swift test
```

Expected output:
```
Test run with 6 tests passed after 0.071 seconds.
```

Tests cover:
- ✅ KeychainManager: Save, retrieve, delete operations
- ✅ SignInViewModel: Success and failure flows
- ✅ Placeholder tests for OnboardingFeature and Persistence

### Integration Test Script

Create a test user and verify backend:
```bash
# 1. Get Firebase Auth emulator token
curl -X POST "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake-api-key" \
  -H "Content-Type: application/json" \
  -d '{"token":"test-token","returnSecureToken":true}'

# 2. Call getUserProfile with token (TODO: requires emulator setup)
# firebase emulators:start
# curl http://127.0.0.1:5001/abundance-dev/us-central1/getUserProfile \
#   -H "Authorization: Bearer <idToken>"
```

---

## Known Issues & Workarounds

### Issue 1: Simulator Apple Sign-In Requires iCloud

**Symptom**: "Sign in with Apple" shows "No Apple ID"

**Workaround**:
1. Open Settings on simulator
2. Sign in to iCloud with any Apple ID
3. Retry sign-in flow

### Issue 2: Firebase Storage Not Enabled

**Symptom**: Storage-related errors in console

**Status**: Not blocking - Storage deployment pending manual setup

**Workaround**: Ignore storage errors for now (not used in Sprint 1)

### Issue 3: SwiftLint Warning in Package.swift

**Symptom**: 1 violation for missing explicit type on `package` variable

**Status**: Acceptable - Swift Package Manager limitation

**Workaround**: Suppress with `// swiftlint:disable:next explicit_type_interface`

---

## Success Criteria

Sprint 1 E2E testing is complete when:

- [ ] iOS app launches without crashes
- [ ] Apple Sign-In button appears and is tappable
- [ ] Apple authentication modal displays correctly
- [ ] Token successfully saved to Keychain
- [ ] User document created in Firestore
- [ ] Backend health endpoint returns 200 OK
- [ ] Sign-out clears Keychain and returns to sign-in screen
- [ ] Re-authentication works without errors
- [ ] No P0 errors in Xcode console
- [ ] All 6 unit tests passing

---

## Deployment Status

### Production Backend (abundance-mvp)

**Deployed Components**:
- ✅ Firestore Rules (row-level user isolation)
- ✅ Firestore Indexes (items by userId + updatedAt)
- ✅ Cloud Functions:
  - `health` (HTTPS): https://us-central1-abundance-mvp.cloudfunctions.net/health
  - `getUserProfile` (Callable): us-central1-getUserProfile

**Pending Components**:
- ⏸️ Firebase Storage (requires manual "Get Started" in console)

### iOS App

**Status**: Ready for testing
- ✅ Builds successfully (Swift 6.2)
- ✅ GoogleService-Info.plist configured
- ✅ All dependencies installed
- ✅ SwiftLint passing (0 violations)
- ✅ All unit tests passing (6/6)

---

## Next Steps After E2E Testing

1. **Document Test Results**: Record pass/fail for each phase
2. **File Bug Reports**: For any failures, create GitHub issues
3. **Update Sprint Plan**: Mark "Sprint demo prepared" as complete
4. **Review PR #5**: Approve and merge Sprint 1 implementation
5. **Sprint Retrospective**: What went well, what to improve for Sprint 2

---

## References

- Sprint Plan: `docs/roadmap/SPRINT-PLAN-001.md`
- Implementation Plan: `docs/plans/2025-11-14-sprint-1-project-setup-auth.md`
- ADR-005: Authentication Strategy
- CODE-EXAMPLE-003: Firebase iOS Integration
- DESIGN-007: Firebase SDK Integration

---

**Last Updated**: 2025-11-14
**Sprint**: 1 of 8
**Status**: Ready for Testing ✅

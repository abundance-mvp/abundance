---
date: 2026-02-09
status: Fixed
priority: P1
type: bug
component: ios
source: manual
related-files:
  - App/AbundanceApp.swift
  - Sources/OnboardingFeature/AuthViewModel.swift
  - Sources/ProfileFeature/ProfileView.swift
  - Sources/ProfileFeature/ProfileViewModel.swift
  - Sources/CameraFeature/Views/CaptureOverlays.swift
  - Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift
screenshots:
  - 020926-sign-out-002.png
  - 020926-sign-out-001.png
  - 020926-sign-in-001.png
  - 020926-sign-in-003.png
axiom-agent: null
branch: claude/pedantic-bhabha
fix-commit: 6e299a4
design-doc: null
---

## Summary

Sign-out leaves app in broken state instead of redirecting to login screen; subsequent sign-in fails with AuthorizationError.

## Description

After tapping Sign Out on the Profile tab, the app does not navigate back to the login screen. Instead the user remains on the main tab view in a half-signed-out state:

1. **Profile tab** still renders as if authenticated (shows user card, settings, sign-out button)
2. **Collection tab** shows "Error Loading Items — Missing or insufficient permissions" because Firestore rejects the unauthenticated request
3. **Scan tab** shows "Sign In Required" overlay with "Tap to sign in" — but tapping it is non-functional (the overlay's action only dismisses/retries camera setup, it does not navigate to login)
4. When the user eventually reaches the login screen, **Sign in with Apple fails** with `com.apple.AuthenticationServices.AuthorizationError`

## Expected Behavior

1. Tapping Sign Out should immediately navigate to `SignInView` (the root auth gate in `AbundanceApp`)
2. The user should never see Collection or Scan errors caused by being unauthenticated — the auth gate should prevent access
3. Sign in with Apple should succeed on the login screen after a sign-out

## Actual Behavior

1. After sign-out the user stays on `MainTabView` — the `@Observable` `isAuthenticated` flag on `AuthViewModel` either doesn't propagate to `AbundanceApp`'s view body, or the `onSignOut` closure from `ProfileView` is not wired to it
2. Collection and Scan tabs are accessible in a signed-out state, showing confusing errors
3. Sign in with Apple fails with `com.apple.AuthenticationServices.AuthorizationError` (screenshot 020926-sign-in-003.png)

## Technical Context

**Device:** iPhone 16 Pro (w-16e), iOS 26
**Time:** 2026-02-09 ~9:02–9:05 PM

### Auth flow architecture

- `AbundanceApp.swift` holds `@State private var authViewModel: AuthViewModel` and conditionally renders `MainTabView` vs `SignInView` based on `authViewModel.isAuthenticated`
- `AuthViewModel` (`@Observable`) sets `isAuthenticated = false` in `signOut()` (line 66)
- `ProfileView` calls `viewModel.signOut()` then `onSignOut?()` (lines 63–73)
- `ProfileViewModel.signOut()` delegates to `FirebaseAuthService.signOut()` (lines 117–129)

### Likely root causes

1. **`onSignOut` closure not connected** — `ProfileView.onSignOut` may not be wired through `MainTabView` back to `AbundanceApp`'s `authViewModel.isAuthenticated`, so the root view never swaps
2. **Two sign-out paths diverged** — `ProfileViewModel` calls `FirebaseAuthService.signOut()` but the `isAuthenticated` flag lives on `AuthViewModel`, which may not be the same instance or may not observe the Firebase auth state change
3. **Sign-in failure after sign-out** — Apple Sign In may be in a bad state because the previous session wasn't fully torn down, or the ASAuthorizationController is being presented from a view that's in a stale state

## Proposed Solution

1. Ensure `AbundanceApp` observes Firebase auth state changes reactively (e.g., `Auth.auth().addStateDidChangeListener`) rather than relying solely on manual `isAuthenticated` flag setting — this guarantees the view gate responds to sign-out regardless of which code path triggers it
2. Wire `ProfileView.onSignOut` through `MainTabView` to `AuthViewModel` as a belt-and-suspenders measure
3. Investigate the `AuthorizationError` on re-sign-in — may need to reset `ASAuthorizationController` state or ensure the presenting window is valid

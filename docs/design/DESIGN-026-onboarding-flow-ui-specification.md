# DESIGN-026: Onboarding Flow UI Specification

**Created**: 2025-11-10
**Stage**: 2.6 - iOS UI/UX Design & Liquid Glass Integration
**Status**: Approved
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.6.md
- docs/specs/user-journey-maps.md
- shared/abundance-brand/abundance-brand-bible.md

---

## Overview

This document specifies the complete onboarding flow for the Abundance iOS app, consisting of 3 screens that introduce users to the app's value proposition, request necessary permissions, and authenticate via Apple Sign-In. The onboarding experience embodies the brand's "Refractive Retro-Futurism" aesthetic with 2D depth simulation, glass materials, and spring-based animations.

**User Journey**: First-time app launch → Welcome → Permissions → Sign In → Catalog View

**Success Criteria**:
- User completes onboarding in < 60 seconds
- Camera and notification permissions granted (> 80% acceptance rate)
- Apple Sign-In successful (Firebase Auth integration)
- User lands on empty Catalog view ready to capture first item

---

## Screen 1: Welcome Screen

### Purpose

Introduce Abundance's core value proposition: "Own More, Waste Less" - intelligent cataloging of household items with AI-powered metadata extraction.

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                         Status Bar                               │
│                                                                   │
│                                                                   │
│                      [App Icon - 3D Glass]                       │
│                         120x120pt                                 │
│                                                                   │
│                       "Abundance"                                │
│                    (Custom Script Logo)                          │
│                      48pt, Primary Text                          │
│                                                                   │
│                    "Own More, Waste Less"                        │
│                  17pt, SF Pro Rounded Regular                    │
│                      Secondary Vibrancy                          │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                           │   │
│  │         [Floating Glass Card - Value Prop 1]             │   │
│  │                                                           │   │
│  │  📸  "Scan any item with your camera"                    │   │
│  │      15pt, .secondary vibrancy                           │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                        (offset y: -20)                           │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                           │   │
│  │         [Floating Glass Card - Value Prop 2]             │   │
│  │                                                           │   │
│  │  🤖  "AI identifies and catalogs automatically"          │   │
│  │      15pt, .secondary vibrancy                           │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                        (offset y: 0)                             │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                           │   │
│  │         [Floating Glass Card - Value Prop 3]             │   │
│  │                                                           │   │
│  │  🔒  "Private by design - your data stays yours"         │   │
│  │      15pt, .secondary vibrancy                           │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                        (offset y: +20)                           │
│                                                                   │
│                                                                   │
│                   [Get Started Button]                           │
│              Capsule, Bright Blue Glow, 24pt                     │
│                                                                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Components

**App Icon**:
- Multi-layered glass cube (from brand assets)
- Size: 120x120pt (standard Large size)
- Shadow: Soft drop shadow (radius 16, opacity 0.2)
- Animation: Gentle float on appear (brandGentle spring)

**Logotype**:
- Custom script font (glass-style rendering if available, else SF Pro Rounded Bold)
- Size: 48pt
- Color: textPrimary (#3B2E3A)
- Accessibility: Semantic label "Abundance app"

**Tagline**:
- "Own More, Waste Less"
- Font: SF Pro Rounded Regular, 17pt (Dynamic Type Body)
- Color: .secondary vibrancy
- Centered below logo

**Value Prop Cards** (3 cards with 2D depth simulation):
- Material: .thickMaterial
- Shape: ConcentricRectangle(cornerRadius: 16, inset: 0) [iOS 26+]
- Fallback: RoundedRectangle(cornerRadius: 16) [iOS 25]
- Padding: 20pt horizontal, 16pt vertical
- Shadow: Soft shadow (radius 8, y offset varies per card for depth)
- Offset: Card 1 (y: -20), Card 2 (y: 0), Card 3 (y: +20) - creates parallax effect
- Animation: Sequential entrance (0.1s delay between cards), brandBouncy spring
- Emoji + Text layout: HStack with 12pt spacing

**Get Started Button**:
- Type: PrimaryButton (from component library)
- Title: "Get Started"
- Action: Navigate to Permissions screen
- Position: Bottom safe area + 32pt
- Haptics: .impact(weight: .medium) on tap

### SwiftUI Implementation Pattern

```swift
struct WelcomeView: View {
    @State private var isAnimating = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color.backgroundDefault
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // App Icon
                Image("AppIcon")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
                    .offset(y: isAnimating ? -5 : 5)
                    .animation(.brandGentle.repeatForever(autoreverses: true), value: isAnimating)
                    .accessibilityHidden(true)

                // Logotype
                Text("Abundance")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)

                // Tagline
                Text("Own More, Waste Less")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)

                // Value Prop Cards with depth simulation
                VStack(spacing: 20) {
                    ValuePropCard(emoji: "📸", text: "Scan any item with your camera")
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
                        .offset(y: -20)

                    ValuePropCard(emoji: "🤖", text: "AI identifies and catalogs automatically")
                        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 0)

                    ValuePropCard(emoji: "🔒", text: "Private by design - your data stays yours")
                        .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 2)
                        .offset(y: 20)
                }
                .padding(.horizontal, 24)

                Spacer()

                // CTA Button
                PrimaryButton(title: "Get Started") {
                    // Navigate to permissions
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct ValuePropCard: View {
    let emoji: String
    let text: String
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 32))

            Text(text)
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            if reduceTransparency {
                Color.backgroundDefault
            } else {
                if #available(iOS 26, *) {
                    ConcentricRectangle(cornerRadius: 16, inset: 0)
                        .fill(.thickMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.thickMaterial)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
```

### Accessibility

**Dynamic Type**: All text scales from .xSmall to .xxxLarge
**VoiceOver**:
- App icon hidden from VoiceOver (decorative)
- Logotype + tagline combined: "Abundance. Own More, Waste Less."
- Each value prop card read as single element: "[emoji description]. [card text]"
- Get Started button: "Get Started. Button. Navigates to permissions screen."

**Reduce Transparency**: Value prop cards use opaque backgroundDefault color
**Reduce Motion**: Remove floating icon animation, use fade-in only

---

## Screen 2: Permissions Screen

### Purpose

Request camera and notification permissions with clear explanations of why each is needed.

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  [< Back]                                    [Skip - .tertiary]  │
│                                                                   │
│                    "We'll need access to"                        │
│                  28pt, SF Pro Rounded Bold                       │
│                      Primary Vibrancy                            │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                           │   │
│  │              [Permission Card - Camera]                   │   │
│  │                                                           │   │
│  │  📷  Camera                                               │   │
│  │      20pt Bold                                            │   │
│  │                                                           │   │
│  │      "Required to scan and identify your items"          │   │
│  │      15pt Regular, .secondary vibrancy                   │   │
│  │                                                           │   │
│  │      [Enable Camera - Primary Button]                    │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                           │   │
│  │            [Permission Card - Notifications]              │   │
│  │                                                           │   │
│  │  🔔  Notifications                                        │   │
│  │      20pt Bold                                            │   │
│  │                                                           │   │
│  │      "Get notified when AI finishes cataloging"          │   │
│  │      15pt Regular, .secondary vibrancy                   │   │
│  │                                                           │   │
│  │      [Enable Notifications - Secondary Button]           │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│                                                                   │
│                      [Continue Button]                           │
│                   (Enabled after camera granted)                 │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Components

**Permission Cards** (2 cards):
- Material: .thickMaterial
- Shape: ConcentricRectangle(cornerRadius: 20, inset: 0) [iOS 26+]
- Padding: 24pt all sides
- Spacing: 24pt between cards
- Shadow: Soft shadow (radius 12, y: 4)

**Permission State Indicators**:
- Not requested: "Enable [Permission]" button visible
- Granted: Green checkmark (Mint Green) + "Granted" text, button hidden
- Denied: Red warning icon + "Open Settings" button

**Navigation**:
- Back button: Navigate to Welcome screen
- Skip button: Navigate to Sign In screen (camera not granted = limited functionality warning)
- Continue button: Enabled only after camera permission granted

### State Management

```swift
@MainActor
class PermissionsViewModel: ObservableObject {
    @Published var cameraStatus: PermissionStatus = .notDetermined
    @Published var notificationStatus: PermissionStatus = .notDetermined

    enum PermissionStatus {
        case notDetermined
        case granted
        case denied
    }

    func requestCameraPermission() async {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        cameraStatus = status ? .granted : .denied
    }

    func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            notificationStatus = granted ? .granted : .denied
        } catch {
            notificationStatus = .denied
        }
    }

    var canContinue: Bool {
        cameraStatus == .granted
    }
}
```

### Accessibility

**VoiceOver**:
- Each permission card read as: "[Permission name]. [Description]. [Button action or status]"
- Continue button disabled state announced: "Continue. Button. Disabled. Grant camera permission to continue."

**Dynamic Type**: All text scales appropriately
**Reduce Transparency**: Permission cards use opaque backgrounds

---

## Screen 3: Sign In Screen

### Purpose

Authenticate user via Apple Sign-In (Firebase Auth integration from Stage 2.2, ADR-005).

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  [< Back]                                                        │
│                                                                   │
│                                                                   │
│                      [App Icon - Small]                          │
│                         80x80pt                                   │
│                                                                   │
│                    "Sign in to Abundance"                        │
│                  28pt, SF Pro Rounded Bold                       │
│                      Primary Vibrancy                            │
│                                                                   │
│              "Your catalog syncs across devices"                 │
│                  15pt, .secondary vibrancy                       │
│                                                                   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                           │   │
│  │         [Apple Sign-In Button - Native Style]            │   │
│  │                                                           │   │
│  │  🍎  Sign in with Apple                                  │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│                                                                   │
│                "By signing in, you agree to our"                 │
│              [Terms of Service] and [Privacy Policy]             │
│                  13pt, .tertiary vibrancy                        │
│                  (Links styled in accentPrimary)                 │
│                                                                   │
│                                                                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Components

**Apple Sign-In Button**:
- Native `SignInWithAppleButton` from AuthenticationServices framework
- Style: .black (follows system appearance automatically)
- Corner radius: 12pt (matches brand aesthetic)
- Height: 56pt (accessible tap target)
- Width: Full width - 48pt horizontal padding

**Legal Links**:
- Terms of Service: Opens Safari View Controller (in-app browser)
- Privacy Policy: Opens Safari View Controller
- Color: accentPrimary (Bright Blue) for links
- Font: 13pt SF Pro Rounded Regular

### Sign-In Flow

```swift
import AuthenticationServices
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isSigningIn = false
    @Published var error: Error?
    @Published var isAuthenticated = false

    func signInWithApple() async {
        isSigningIn = true
        defer { isSigningIn = false }

        do {
            // Request Apple Sign-In
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.email, .fullName]

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            // ... (delegate pattern, see ADR-005 for full implementation)

            // Exchange Apple token for Firebase token
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: appleIDToken,
                rawNonce: nonce
            )

            let result = try await Auth.auth().signIn(with: credential)

            // Success - navigate to Catalog
            isAuthenticated = true

        } catch {
            self.error = error
            // Show error alert
        }
    }
}
```

### Error Handling

**Sign-In Cancelled**: No error shown, user can retry
**Sign-In Failed**: Alert with .ultraThickMaterial background:
- Title: "Sign In Failed"
- Message: "Please try again or check your internet connection."
- Actions: "Try Again", "Cancel"

### Accessibility

**VoiceOver**:
- Apple Sign-In button uses native accessibility labels from Apple
- Legal text: "By signing in, you agree to our Terms of Service and Privacy Policy. Links available."

**Reduce Motion**: No animations on this screen
**Reduce Transparency**: Alert backgrounds use opaque colors

---

## Navigation Flow

### State Machine

```
Welcome Screen
    ↓ (Get Started tapped)
Permissions Screen
    ↓ (Continue tapped, camera granted)
Sign In Screen
    ↓ (Sign in successful)
Catalog View (main app)
```

### Skip Patterns

- **Skip from Permissions**: Warning sheet shown: "Camera access required to scan items. You can still browse but won't be able to add new items."
  - User confirms → Navigate to Sign In
  - User cancels → Stays on Permissions

- **Back Navigation**: Allowed at any point, preserves permission state

### Persistent State

Store onboarding completion in UserDefaults:

```swift
extension UserDefaults {
    var hasCompletedOnboarding: Bool {
        get { bool(forKey: "hasCompletedOnboarding") }
        set { set(newValue, forKey: "hasCompletedOnboarding") }
    }
}
```

---

## Animations

### Welcome Screen

- App icon: Gentle float (brandGentle spring, repeat forever)
- Value prop cards: Sequential entrance with brandBouncy spring
  - Card 1: 0.0s delay
  - Card 2: 0.1s delay
  - Card 3: 0.2s delay
- Get Started button: Fade in at 0.3s delay

### Permissions Screen

- Permission cards: Slide in from right with brandDefault spring
- Button state changes: brandSnappy spring (0.3s response)
- Checkmark appearance: brandBouncy spring with scale effect

### Sign In Screen

- Apple Sign-In button: Pulse glow on appear (subtle, brandGentle)
- Success transition: Full-screen fade to Catalog with brandDefault spring

---

## Testing Checklist

### Functional Tests
- [ ] Welcome screen displays correctly on all device sizes (SE, Pro, Pro Max, iPad)
- [ ] Value prop cards have proper depth simulation (shadow offsets visible)
- [ ] Get Started button navigates to Permissions screen
- [ ] Back button on Permissions/Sign In returns to previous screen
- [ ] Camera permission request triggers native iOS alert
- [ ] Notification permission request triggers native iOS alert
- [ ] Continue button disabled until camera permission granted
- [ ] Apple Sign-In button triggers ASAuthorizationController
- [ ] Successful sign-in navigates to Catalog view
- [ ] Sign-in error shows alert with retry option
- [ ] Onboarding completion persisted in UserDefaults

### Accessibility Tests
- [ ] All screens work with VoiceOver enabled
- [ ] All text scales correctly with Dynamic Type (XS to XXXL)
- [ ] Reduce Transparency replaces glass materials with opaque backgrounds
- [ ] Reduce Motion disables animations, uses cross-fades only
- [ ] All buttons have minimum 44x44pt tap targets
- [ ] Legal links are keyboard-navigable

### Brand Compliance
- [ ] Color tokens match brand palette (textPrimary, accentPrimary, etc.)
- [ ] Typography uses SF Pro Rounded at specified weights
- [ ] Animations use brand spring presets (brandGentle, brandBouncy, etc.)
- [ ] ConcentricRectangle shapes used on iOS 26+, RoundedRectangle fallback on iOS 25
- [ ] Materials use correct thickness (.thickMaterial for cards)

---

## References

- **Architecture**: docs/adr/ADR-010-swiftui-architecture-pattern.md (MVVM)
- **Authentication**: docs/adr/ADR-005-authentication-strategy.md (Apple Sign-In + Firebase)
- **Component Library**: docs/design/DESIGN-031-swiftui-component-library.md (PrimaryButton)
- **Color System**: docs/design/DESIGN-032-color-system-design-tokens.md
- **Animation Presets**: docs/design/DESIGN-034-animation-motion-specifications.md
- **User Journeys**: docs/specs/user-journey-maps.md

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial onboarding flow specification | iOS UI/UX Designer |

---

**Status**: ✅ **APPROVED**

**Implementation Ready**: All screens specified with SwiftUI code patterns, state management, and accessibility support.

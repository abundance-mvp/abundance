# View Spec: SignInView

**Source:** `Sources/OnboardingFeature/SignInView.swift`
**Module:** OnboardingFeature
**Priority:** P1
**Last updated:** 2026-02-06

---

## 1. Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| Background gradient start | `peach` @ 0.3 opacity | `#EDBE9E` | `Color.peach.opacity(0.3)` — top-leading |
| Background gradient end | `salmon` @ 0.2 opacity | `#E8907A` | `Color.salmon.opacity(0.2)` — bottom-trailing |
| Background (reduceTransparency) | `backgroundDefault` | `#FAF6F0` | Solid fallback via `Color.backgroundDefault` |
| Leaf icon | `softTeal` | `#8ECAC0` | `Color.softTeal` fill |
| Leaf shadow | `softTeal` @ 0.4 opacity | `#8ECAC0` | `Color.softTeal.opacity(0.4)` shadow |
| Title text | `textPrimary` | `#3B2E3A` | `Color.textPrimary` (semantic alias for `deepPlum`) |
| Subtitle text | `.secondary` (system) | — | `foregroundStyle(.secondary)` |
| Legal text | `.tertiary` (system) | — | `foregroundStyle(.tertiary)` |
| Offline warning text | `salmon` | `#E8907A` | `Color.salmon` foreground |
| Offline warning bg | `salmon` @ 0.15 opacity | `#E8907A` | `Color.salmon.opacity(0.15)` capsule |
| Error icon | `errorColor` | `#E8907A` | `Color.errorColor` (semantic alias for `salmon`) |
| Error text | `errorColor` | `#E8907A` | `Color.errorColor` foreground |
| Retry button text | `accentPrimary` | `#E8907A` | `Color.accentPrimary` (semantic alias for `salmon`) |
| Error card bg | `cream` / `peach` | — | Via `.abundanceCardStyle(cornerRadius: 12)` |
| Sign In button | system | — | `SignInWithAppleButton` — `.black` / `.white` per `colorScheme` |

**Known violations:** None — `.secondary` and `.tertiary` are acceptable system semantic colors.

## 2. Accessibility

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| Offline warning | "No internet connection. Sign in requires internet access." | Combined | Auto | Caption / Subheadline |
| Leaf icon | Hidden (`accessibilityHidden(true)`) | — | — | `@ScaledMetric` capped at `.accessibility2` |
| Title + subtitle | Combined (`children: .combine`) | — | — | Title / Body |
| Sign In with Apple | System-provided | `.isButton` | 56pt height, full-width | System managed |
| Loading spinner | "Signing in" | `.updatesFrequently` | — | — |
| Error card | "Error: {description}" | Combined (`children: .combine`) | — | Caption (rounded) |
| Retry button | "Check Connection" | `.isButton` | Needs review | Caption |

**Known violations:**
- Retry "Check Connection" button has no explicit 44x44pt minimum touch target

## 3. Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Offline warning bg | `.glassEffect(in: Capsule())` | `salmon` @ 0.15 | `Capsule().fill(Color.salmon.opacity(0.15))` |
| Error card | None — uses `abundanceCardStyle` | — | Cream bg + peach stroke |
| Background | None — gradient only | — | — |

**Notes:**
- Glass on offline warning correctly checks `reduceTransparency` and falls back to solid capsule fill
- iOS 26 availability check uses `#available(iOS 26.0, macOS 26.0, *)`

**Opportunities:**
- Error card could use `adaptiveGlass()` instead of solid `abundanceCardStyle`

## 4. Layout

| Element | Constraint | Value |
|---------|-----------|-------|
| Root VStack | spacing | 32pt |
| Root VStack | horizontal padding | 24pt |
| Offline warning HStack | spacing | 8pt |
| Offline warning | padding h/v | 16pt / 10pt |
| Title VStack | spacing | 12pt |
| Sign-in section VStack | spacing | 16pt |
| Sign In with Apple button | height | 56pt (fixed) |
| Sign In with Apple button | width | full (`maxWidth: .infinity`) |
| Sign In with Apple button | corner radius | 12pt |
| Error view VStack | spacing | 12pt |
| Error view HStack | spacing | 8pt |
| Error view | padding h/v | 16pt / 12pt |
| Error card | corner radius | 12pt (via `abundanceCardStyle`) |
| Legal text | bottom padding | 32pt |
| Leaf icon shadow | radius | 16pt, y-offset 8pt |
| Loading spinner | scale | 1.2x |

## 5. Animations & Haptics

| Trigger | Animation | Haptic | Duration |
|---------|-----------|--------|----------|
| Network status change | `.easeInOut(duration: 0.2)` | None | 200ms |

**Known violations:**
- Raw `.easeInOut(duration: 0.2)` instead of brand animation token
- No `accessibilityReduceMotion` check on animation

---

## Subviews (private)

### offlineWarning
- HStack with `wifi.slash` icon and warning text
- Glass capsule on iOS 26+, solid fill fallback

### backgroundGradient
- LinearGradient from `peach` to `salmon`
- Solid `backgroundDefault` fallback when `reduceTransparency` is on

### leafIcon
- `leaf.fill` SF Symbol at `@ScaledMetric` 80pt, capped at `.accessibility2`
- Decorative only (`accessibilityHidden(true)`)

### titleSection
- Combined accessibility element merging title + subtitle

### signInSection
- Switches between `ProgressView` (loading) and `SignInWithAppleButton` + error

### errorView(error:)
- `abundanceCardStyle` card with contextual icon
- Retry button only shown for network-related errors

# View Spec: ProfileView

**Source:** `Sources/ProfileFeature/ProfileView.swift`
**Module:** ProfileFeature
**Priority:** P1
**Last updated:** 2026-02-06

---

## 1. Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| View background | `backgroundDefault` | `#FAF6F0` | `.background(Color.backgroundDefault)` |
| Section headers | `textPrimary` | `#3B2E3A` | `.foregroundStyle(Color.textPrimary)` via `sectionHeader()` |
| Settings row icon | `salmon` | `#E8907A` | `.foregroundStyle(Color.salmon)` |
| Settings row text | `textPrimary` | `#3B2E3A` | `.foregroundStyle(Color.textPrimary)` |
| Settings chevron | `.secondary` | (system) | `.foregroundStyle(.secondary)` |
| Export icon (tablecells) | `salmon` | `#E8907A` | `.foregroundStyle(Color.salmon)` |
| Export label text | `textPrimary` | `#3B2E3A` | `.foregroundStyle(Color.textPrimary)` |
| Export share icon | `.secondary` | (system) | `.foregroundStyle(.secondary)` |
| Sign out text + icon | `errorColor` | `#E8907A` | `.foregroundStyle(Color.errorColor)` |
| Settings card bg | `cream` | `#F0DCC0` | Via `.abundanceCardStyle()` |
| Settings card stroke | `peach` | `#EDBE9E` | Via `.abundanceCardStyle()` |
| Export card bg | `cream` | `#F0DCC0` | Via `.abundanceCardStyle()` |
| Sign out card bg | `cream` | `#F0DCC0` | Via `.abundanceCardStyle()` |
| Loading overlay bg | `Color.black.opacity(0.3)` | (raw) | Scrim behind ProgressView |
| Loading spinner | `.white` | (raw) | `.tint(.white)` |
| **UserInfoCard** | | | |
| Display name text | `textPrimary` | `#3B2E3A` | `.foregroundStyle(Color.textPrimary)` |
| Email text | `.secondary` | (system) | `.foregroundStyle(.secondary)` |
| Avatar circle fill | `accentPrimary` @ 0.2 | `#E8907A` | `Color.accentPrimary.opacity(0.2)` |
| Avatar initials | `salmon` | `#E8907A` | `.foregroundStyle(Color.salmon)` |
| Item count icon | `salmon` | `#E8907A` | `.foregroundStyle(Color.salmon)` |
| Item count text | `textPrimary` | `#3B2E3A` | `.foregroundStyle(Color.textPrimary)` |
| Item count badge bg | `accentPrimary` @ 0.1 | `#E8907A` | `Color.accentPrimary.opacity(0.1)` in Capsule |
| User info card bg | `cream` | `#F0DCC0` | `.abundanceCardStyle(cornerRadius: 20)` |
| User info card stroke | `peach` | `#EDBE9E` | `.abundanceCardStyle(cornerRadius: 20)` |

**Known violations:**

| # | Element | Issue | Severity | Fix |
|---|---------|-------|----------|-----|
| V1 | Loading overlay bg | Raw `Color.black.opacity(0.3)` -- not a brand token | Minor | Add semantic alias `Color.scrimOverlay` |
| V2 | Loading spinner tint | Raw `.white` -- not a brand token | Minor | Add semantic alias `Color.scrimContent` or use `Color.warmWhite` |
| V3 | Settings chevron | System `.secondary` -- not a brand token | Low | Acceptable for tertiary chrome; consider `Color.deepPlum.opacity(0.5)` for brand consistency |
| V4 | Email text (UserInfoCard) | System `.secondary` -- not a brand token | Low | Same as V3 |
| V5 | Export share icon | System `.secondary` -- not a brand token | Low | Same as V3 |

## 2. Accessibility

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| UserInfoCard | "User profile: {name}, {email}, {count} items" | `.combine` children | N/A (info card) | Title2 / Subheadline / Callout |
| Avatar circle | (hidden) | `accessibilityHidden(true)` | N/A | N/A |
| Notifications row | "Notifications" | `.isButton` (explicit) | 44pt (`padding(.vertical, 14)` = ~48pt) | Body |
| Privacy row | "Privacy" | `.isButton` (explicit) | 44pt (`padding(.vertical, 14)` = ~48pt) | Body |
| Help row | "Help" | `.isButton` (explicit) | 44pt (`padding(.vertical, 14)` = ~48pt) | Body |
| Export CSV button | "Export as CSV" | `.isButton` (implicit via Button) | 44pt (`minHeight: 44` explicit) | Body |
| Sign Out button | "Sign out" | `.isButton` (implicit via Button) | 44pt (`padding(.vertical, 16)` = ~52pt) | Body |
| Sign Out alert - Cancel | "Cancel" | `.isButton` | System | System |
| Sign Out alert - Confirm | "Sign Out" | `.isButton, .isDestructiveAction` | System | System |
| Loading ProgressView | (none) | (none) | N/A | N/A |

**Known violations:**

| # | Element | Issue | Severity | Fix |
|---|---------|-------|----------|-----|
| A1 | Loading ProgressView | No `accessibilityLabel` -- VoiceOver silent during loading | P1 | Add `.accessibilityLabel("Loading profile")` |
| A2 | Settings row hints | Generic hint pattern "Double tap to open {x} settings" -- "help settings" reads oddly | Low | Consider custom hint for Help row: "Double tap to get help" |
| A3 | ProgressView scaleEffect | `scaleEffect(1.5)` used instead of `controlSize(.large)` -- does not scale with Dynamic Type | Minor | Replace with `.controlSize(.large)` |

## 3. Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Navigation bar | System default | -- | System default |
| UserInfoCard | `.abundanceCardStyle(cornerRadius: 20)` | -- | Cream bg + peach stroke (solid) |
| Settings section card | `.abundanceCardStyle()` | -- | Cream bg + peach stroke (solid) |
| Export CSV card | `.abundanceCardStyle()` | -- | Cream bg + peach stroke (solid) |
| Sign Out card | `.abundanceCardStyle()` | -- | Cream bg + peach stroke (solid) |
| Loading overlay | Raw `Color.black.opacity(0.3)` | -- | Same (no material/glass) |

**Known violations:**

| # | Element | Issue | Severity | Fix |
|---|---------|-------|----------|-----|
| G1 | All cards | Use solid `abundanceCardStyle()` instead of `adaptiveGlass()` -- no Liquid Glass on iOS 26 | P2 | Migrate to `adaptiveGlass(cornerRadius:)` for iOS 26 glass, keeping cream+peach as < iOS 26 fallback |
| G2 | Loading overlay | Raw `Color.black.opacity(0.3)` instead of `.ultraThinMaterial` or glass scrim | Minor | Use `.ultraThinMaterial` or `adaptiveGlass()` for overlay background |

**Opportunities:**
- UserInfoCard is the hero element; `adaptiveGlass(cornerRadius: 20, tint: .salmonBehindGlass)` would give it visual prominence behind glass
- Settings card could use `adaptiveGlass()` to match other glass-enabled views (FloatingTabBar, SearchBar)
- Sign Out button could use `adaptiveGlass()` with a subtle salmon tint for destructive emphasis

## 4. Layout

| Element | Constraint | Value |
|---------|-----------|-------|
| ScrollView VStack | spacing | 24pt |
| ScrollView content | padding | 16pt (`.padding()` default) |
| UserInfoCard inner | padding | 24pt |
| UserInfoCard | maxWidth | `.infinity` |
| UserInfoCard | cornerRadius | 20pt (via `abundanceCardStyle(cornerRadius: 20)`) |
| Avatar circle | size | 80 x 80pt |
| User info VStack | spacing | 4pt |
| Item count badge | horizontal padding | 16pt |
| Item count badge | vertical padding | 8pt |
| Item count HStack | spacing | 8pt |
| Section header | leading padding | 4pt |
| Settings section VStack | spacing (outer) | 12pt |
| Settings rows VStack | spacing | 0pt (Divider-separated) |
| Settings row HStack | spacing | 16pt |
| Settings row | horizontal padding | 16pt |
| Settings row | vertical padding | 14pt |
| Settings row icon | frame width | 24pt |
| Settings Divider | leading padding | 48pt |
| Settings card | cornerRadius | 16pt (default `abundanceCardStyle()`) |
| Export button HStack | horizontal padding | 16pt |
| Export button HStack | vertical padding | 14pt |
| Export button | minHeight | 44pt (explicit) |
| Export card | cornerRadius | 16pt (default) |
| Sign Out button | vertical padding | 16pt |
| Sign Out card | cornerRadius | 16pt (default) |

## 5. Animations & Haptics

| Trigger | Animation | Haptic | Duration |
|---------|-----------|--------|----------|
| (none found) | -- | -- | -- |

**Known violations:**

| # | Element | Issue | Severity | Fix |
|---|---------|-------|----------|-----|
| H1 | Loading overlay | Appears/disappears instantly with no transition | Minor | Add `.transition(.opacity).animation(.easeInOut(duration: 0.2))` wrapped in `withAnimation` |
| H2 | Sign Out confirmation | No haptic on destructive action trigger | Minor | Add `.sensoryFeedback(.warning, trigger: showingSignOutConfirmation)` |
| H3 | Export CSV tap | No haptic feedback on export action | Low | Add `.sensoryFeedback(.impact(flexibility: .solid), trigger:)` on export |
| H4 | All animations | No `@Environment(\.accessibilityReduceMotion)` check | Low | Currently moot (no animations), but should be added when H1 is implemented |

---

## Subviews

### UserInfoCard (public, separate file)

**Source:** `Sources/ProfileFeature/Components/UserInfoCard.swift`

- Displays avatar (initials in tinted circle), display name, email, item count badge
- Uses `.abundanceCardStyle(cornerRadius: 20)` for card treatment
- Combined accessibility element with descriptive label
- Avatar is `accessibilityHidden(true)` -- correct pattern

### SettingsRow (private)

- Reusable row with icon, title, and chevron disclosure indicator
- Each row is a `Button` with `.buttonStyle(.plain)` and `.contentShape(Rectangle())`
- Explicit `.accessibilityAddTraits(.isButton)` and custom hint
- Icon frame width fixed at 24pt for visual alignment
- Touch target: full-width, ~48pt tall (14pt vertical padding x2 + body text)

### Loading Overlay (private)

- Full-screen scrim with centered `ProgressView`
- Uses raw colors (see violations V1, V2)
- No accessibility label (violation A1)
- No enter/exit animation (violation H1)

---

## Summary of Violations

| ID | Category | Severity | Description |
|----|----------|----------|-------------|
| V1 | Palette | Minor | Loading overlay uses raw `Color.black.opacity(0.3)` |
| V2 | Palette | Minor | Spinner uses raw `.white` tint |
| V3-V5 | Palette | Low | System `.secondary` used for tertiary chrome (3 instances) |
| A1 | Accessibility | **P1** | Loading ProgressView has no VoiceOver label |
| A2 | Accessibility | Low | Help row hint reads "help settings" |
| A3 | Accessibility | Minor | ProgressView uses `scaleEffect` instead of `controlSize` |
| G1 | Liquid Glass | P2 | All cards use solid `abundanceCardStyle` with no glass path |
| G2 | Liquid Glass | Minor | Loading overlay uses raw color instead of material |
| H1 | Animation | Minor | Loading overlay has no transition animation |
| H2 | Haptics | Minor | No haptic on destructive sign-out trigger |
| H3 | Haptics | Low | No haptic on export action |
| H4 | Animation | Low | No `reduceMotion` environment check (currently moot) |

# Brainstorm: Profile View Development

**Date:** 2026-02-08
**Status:** Brainstorming
**Context:** ProfileFeature is ~50% complete — core display, auth, and sign-out work. Settings, export, editing, and value-add features are stubbed or missing.

---

## What Exists Today

ProfileView currently shows:
- **User info card** — initials avatar, name, email, item count badge
- **Settings section** — 3 rows (Notifications, Privacy, Help) with placeholder actions
- **Export section** — CSV button (placeholder, no actual export)
- **Sign out** — confirmation alert + Firebase Auth sign-out

Architecture is solid: MVVM with `@Observable`, constructor injection, `ItemRepository` protocol, full test coverage for existing logic.

---

## What's Missing (Opportunity Space)

### Tier 1: Core Profile Functionality (Foundation)

1. **Settings destination screens** — Notifications, Privacy, Help rows currently do nothing
2. **Profile editing** — No way to change display name
3. **CSV export implementation** — Button exists but `exportData()` is a 500ms sleep stub
4. **Error recovery** — Basic error text, no retry or contextual guidance

### Tier 2: Value-Add Features (Differentiation)

5. **Collection statistics dashboard** — Item count exists but no breakdown (categories, value totals, recent activity)
6. **Storage/usage indicators** — How many items vs. any limit, photo storage used
7. **Profile photo** — Currently initials-only avatar
8. **App version/build info** — Standard for profile screens

### Tier 3: Growth Features (Future)

9. **Account management** — Delete account, email change, password change
10. **Subscription/premium tier** — If monetization is planned
11. **Data import** — Complement to export
12. **Sharing/collaboration** — Share collection with household members

---

## Ideas to Explore

### A. Settings Architecture

**Option A1: NavigationLink destinations within ProfileFeature**
- Each settings row pushes a new view via NavigationStack
- Self-contained within ProfileFeature module
- Simplest to implement, appropriate for MVP

**Option A2: Settings as a separate SettingsFeature module**
- Dedicated module alongside ProfileFeature
- Better separation if settings grow complex
- Overkill for MVP — revisit post-launch

**Option A3: Inline expandable settings (no navigation)**
- Disclosure groups that expand in-place
- Simpler UX but can feel cramped
- Works for simple toggles (notifications on/off)

**Recommendation:** **A1** — NavigationLink within ProfileFeature. Keep it simple, matches the existing NavigationStack. Extract to a separate module only if it grows beyond 5-6 screens.

---

### B. What Should Each Settings Screen Contain?

**Notifications:**
- Toggle for push notifications (on/off)
- Toggle for "Item Ready" alerts (when AI processing completes)
- Toggle for "Weekly Collection Summary" (future)
- Note: Requires push notification permission request flow

**Privacy:**
- Analytics opt-in/out toggle (if analytics exist)
- "Delete My Data" button (account deletion — Apple requirement)
- Link to privacy policy (web URL)
- Camera/photo library permission status display

**Help:**
- FAQ accordion or list
- "Contact Support" (email link)
- "Report a Bug" (feedback form or email)
- App version and build number
- Link to terms of service

---

### C. Collection Statistics Dashboard

**What makes this valuable for Abundance specifically:**
- Users are cataloging household belongings — they want to know *what they have* and *what it's worth*
- Insurance use case: "Total estimated value: $X,XXX"
- Organization insight: "Most items in Kitchen (23), Living Room (15)"

**Possible stats to show:**
- Total items in collection
- Total estimated value (sum of item values)
- Items by category/room (bar chart or grouped list)
- Items by AI status (Ready vs. Analyzing vs. Try Again)
- Recently added items (last 7 days)
- Collection growth over time (sparkline)

**Data availability:** All of this can be derived from `ItemRepository.getItems()` — the `Item` model already has `estimatedValue`, `category`, `room`, `status`, `createdAt` fields. No backend changes needed.

**Recommendation:** Start with a simple stats card (total items, total value, items by status) below the user info card. Expand to categories/rooms in a detail view later.

---

### D. CSV Export Implementation

**What should be exported:**
- Item name, category, room/location, estimated value, condition, AI status
- Created date, last modified date
- Photo URLs (or note that photos are cloud-stored)
- One row per item, standard CSV headers

**How to implement:**
- Generate CSV string from `[Item]` array
- Present via `ShareLink` or `UIActivityViewController` (wrapped for SwiftUI)
- Save to temp file, share via system share sheet
- Consider: JSON export as future option

**Recommendation:** Use SwiftUI `ShareLink` with a `Transferable` conformance on a custom `CSVDocument` type. Clean, native, no UIKit needed.

---

### E. Profile Photo

**Options:**
- E1: PhotosPicker for local image selection → upload to Firebase Storage
- E2: Gravatar integration based on email
- E3: SF Symbol-based avatar customization (color/icon picker)
- E4: Keep initials-only (simplest)

**Recommendation:** **E4 for MVP**, with **E1** as a fast follow. Profile photo upload requires Firebase Storage integration and adds complexity. Initials avatar is clean and functional.

---

### F. Account Deletion (Apple Requirement)

**Context:** Apple requires apps with account creation to offer account deletion. This is an App Store review requirement.

**Implementation:**
- "Delete Account" button in Privacy settings (red, destructive)
- Confirmation dialog explaining what will be deleted
- Backend: Cloud Function to delete user data (Firestore docs, Storage files, Auth account)
- Client: Sign out after deletion confirmed

**Recommendation:** Must be implemented before App Store submission. Can be a simple confirmation + Cloud Function call. The backend `cleanupDeleted` scheduled job already exists for related cleanup.

---

### G. Profile Editing

**What can users edit?**
- Display name (stored in Firebase Auth profile)
- Profile photo (if implemented)
- Email change requires re-authentication (complex flow)
- Password change requires re-authentication

**Recommendation:** Start with display name editing only. Present as an edit sheet or inline editing on the UserInfoCard. Firebase Auth `updateProfile(displayName:)` is straightforward.

---

## Prioritized Feature Groups

### Phase 1: "Make What Exists Work" (This Branch)
1. Settings navigation with real destination views
2. Notifications settings (toggle + permission request)
3. Privacy settings (delete account + privacy policy link)
4. Help screen (version info + support contact)
5. Display name editing (tap to edit on UserInfoCard)
6. CSV export implementation (real export via ShareLink)

### Phase 2: "Add Value" (Next Branch)
7. Collection statistics card (total value, category breakdown)
8. Stats detail view (full breakdown with visualizations)
9. Profile photo upload
10. Enhanced error handling with retry

### Phase 3: "Growth" (Post-MVP)
11. Data import
12. Sharing/collaboration
13. Subscription management
14. Weekly summary notifications

---

## Design Considerations

### Visual Design
- Follow existing Abundance design system (salmon accent, peach borders, cream cards)
- Liquid Glass on iOS 26+, thickMaterial fallback
- Consistent with UserInfoCard's established visual language
- Settings rows already have the right pattern (icon + label + chevron)

### Accessibility
- Every interactive element needs AX identifier, label, hint (pattern already established)
- Settings toggles need proper accessibility traits
- Stats should be readable by VoiceOver (aggregate descriptions, not raw numbers)

### Architecture
- Keep MVVM pattern — each settings screen gets its own ViewModel if it has logic
- Simple display-only screens (Help, Privacy Policy) don't need ViewModels
- Reuse `ItemRepository` for stats — no new data layer needed
- `AuthServiceProtocol` already abstracts auth operations

### Testing
- Each new ViewModel gets unit tests
- Navigation can be tested via XCUITest or snapshot tests
- Export can be unit tested (CSV generation) + integration tested (share sheet)

---

## Open Questions for User

1. **Scope for this branch:** All of Phase 1, or a subset?
2. **Notifications:** Does the app currently use push notifications? (Affects whether notifications settings is real or placeholder)
3. **Account deletion backend:** Does a Cloud Function exist for full user data deletion, or does it need to be created?
4. **Stats priority:** Should collection statistics be in Phase 1 or Phase 2?
5. **Design preferences:** Any specific design direction beyond the existing Abundance design system?

---

## Files That Will Be Created/Modified

### New Files (Phase 1)
- `Sources/ProfileFeature/Views/NotificationsSettingsView.swift`
- `Sources/ProfileFeature/Views/PrivacySettingsView.swift`
- `Sources/ProfileFeature/Views/HelpView.swift`
- `Sources/ProfileFeature/Views/EditProfileSheet.swift`
- `Sources/ProfileFeature/ViewModels/NotificationsSettingsViewModel.swift`
- `Sources/ProfileFeature/Models/CSVExporter.swift`

### Modified Files
- `Sources/ProfileFeature/ProfileView.swift` — Add NavigationLinks, edit trigger
- `Sources/ProfileFeature/ProfileViewModel.swift` — Real export, edit profile method
- `Sources/ProfileFeature/Components/UserInfoCard.swift` — Edit button/tap target
- `Tests/ProfileFeatureTests/` — New tests for each addition

---

*This brainstorm is ready for review. Select which ideas to pursue, then we'll create a formal plan.*

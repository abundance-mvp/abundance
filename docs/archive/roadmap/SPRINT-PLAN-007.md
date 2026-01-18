# SPRINT-PLAN-007: Item Detail, Editing & Onboarding

**Sprint**: 7 of 8
**Theme**: Item detail view, editing, and complete onboarding flow

---

## Sprint Goals

1. ✅ Item detail view shows all metadata
2. ✅ User can edit AI-suggested fields
3. ✅ Onboarding flow complete (3 screens)
4. ✅ Profile view with subscription status

---

## Stories

### Story 7.1: ItemDetailView

**Epic**: Epic 7 (Item Detail)

**Tasks:**
1. Implement ItemDetailView (SwiftUI)
2. Display all metadata (name, category, tags, location, value, AI analysis)
3. Photo viewer (full-screen, pinch-to-zoom)
4. Edit button transitions to edit mode
5. UI tests

**Acceptance Criteria:**
- All metadata displays correctly
- Photo viewer supports swipe gestures
- Edit button shows correctly
- UI tests pass

**Files:**
- Create: Packages/Features/CatalogFeature/Sources/ItemDetailView.swift
- Create: Packages/Features/CatalogFeature/Tests/ItemDetailViewTests.swift

**References:**
- [DESIGN-029-item-detail-view-specification](../design/DESIGN-029-item-detail-view-specification.md): Item Detail View Specification

---

### Story 7.2: Edit Mode

**Epic**: Epic 7 (Item Detail)

**Tasks:**
1. Implement edit mode UI (pickers, text fields)
2. Category picker (15 categories)
3. Tag editor (add/remove tags)
4. Location dropdown (suggestions)
5. Save changes to Firestore (PUT /items/:id)

**Acceptance Criteria:**
- User can edit category in < 10 seconds
- Tags persist across sessions
- Location suggestions work
- Updates sync to Firestore < 1s

**Files:**
- Modify: Packages/Features/CatalogFeature/Sources/ItemDetailView.swift

**References:**
- [DESIGN-029-item-detail-view-specification](../design/DESIGN-029-item-detail-view-specification.md): Item Detail View Specification
- [API-CONTRACTS-001-rest-endpoints](../design/API-CONTRACTS-001-rest-endpoints.md): REST Endpoints

---

### Story 7.3: Onboarding Flow

**Epic**: Epic 8 (Onboarding)

**Tasks:**
1. Implement OnboardingView (3-screen flow)
2. Welcome screen (app intro)
3. Permissions screen (camera, notifications)
4. Sign-in screen (Apple Sign-In)
5. Navigation flow (swipe, skip, next)
6. UI tests

**Acceptance Criteria:**
- Onboarding completes in < 2 minutes
- User can skip to sign-in
- Permissions requested correctly
- UI tests pass

**Files:**
- Create: Packages/Features/OnboardingFeature/Sources/OnboardingView.swift
- Create: Packages/Features/OnboardingFeature/Tests/OnboardingViewTests.swift

**References:**
- [DESIGN-026-onboarding-flow-ui-specification](../design/DESIGN-026-onboarding-flow-ui-specification.md): Onboarding Flow UI Specification

---

### Story 7.4: Profile View

**Epic**: Epic 8 (Onboarding)

**Tasks:**
1. Implement ProfileView (settings, export, subscription)
2. Display user info (name, email, subscription status)
3. Export to PDF/CSV (premium feature)
4. Settings (theme, notifications, privacy)
5. UI tests

**Acceptance Criteria:**
- Subscription status displays correctly
- Export works for premium users
- Settings persist
- UI tests pass

**Files:**
- Create: Packages/Features/ProfileFeature/Sources/ProfileView.swift
- Create: Packages/Features/ProfileFeature/Tests/ProfileViewTests.swift

**References:**
- [DESIGN-030-profile-export-view-specification](../design/DESIGN-030-profile-export-view-specification.md): Profile Export View Specification

---

## Sprint Risks

### P2: Export Feature Complexity

**Impact**: Low (premium feature, can defer)
**Mitigation**:
- Use PDFKit for iOS export
- CSV export simpler, prioritize
- Defer PDF if time-constrained

---

## Definition of Done

- [ ] Item detail view complete
- [ ] Edit mode functional
- [ ] Onboarding flow complete
- [ ] Profile view with export
- [ ] All unit + UI tests pass
- [ ] Sprint demo shows complete user journey

---

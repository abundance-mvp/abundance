# SPRINT-PLAN-006: Catalog View & Search

**Sprint**: 6 of 8
**Theme**: iOS catalog browsing with real-time sync and search

---

## Sprint Goals

1. ✅ Catalog view displays all user items
2. ✅ Real-time Firestore sync updates catalog
3. ✅ Search returns results in < 500ms
4. ✅ Filters and sorting functional

---

## Stories

### Story 6.1: CatalogViewModel & Repository

**Epic**: Epic 6 (Catalog View)

**Tasks:**
1. Implement CatalogRepository (Firestore queries)
2. Implement CatalogViewModel (MVVM pattern)
3. Real-time listener with Combine publisher
4. Unit tests with mock repository

**Acceptance Criteria:**
- Firestore listener updates @Published items
- ViewModel fetches user items correctly
- Real-time sync works (< 1s latency)
- Unit tests pass (90%+ coverage)

**Files:**
- Create: Packages/Features/CatalogFeature/Sources/CatalogRepository.swift
- Create: Packages/Features/CatalogFeature/Sources/CatalogViewModel.swift
- Create: Packages/Features/CatalogFeature/Tests/CatalogViewModelTests.swift

**References:**
- [CODE-EXAMPLE-002-catalog-mvvm-implementation](../design/CODE-EXAMPLE-002-catalog-mvvm-implementation.md): Catalog MVVM Implementation
- [DESIGN-024-firestore-listener-patterns](../design/DESIGN-024-firestore-listener-patterns.md): Firestore Listener Patterns

---

### Story 6.2: CatalogView UI

**Epic**: Epic 6 (Catalog View)

**Tasks:**
1. Implement CatalogView (SwiftUI grid/list)
2. Grid/list toggle button
3. Image loading with Kingfisher
4. Empty state + loading state
5. UI tests

**Acceptance Criteria:**
- Grid view displays 2 columns
- List view displays full width
- Images cached with Kingfisher
- Toggle preference persists
- UI tests pass

**Files:**
- Create: Packages/Features/CatalogFeature/Sources/CatalogView.swift
- Create: Packages/Features/CatalogFeature/Tests/CatalogViewTests.swift

**References:**
- [DESIGN-028-catalog-view-specification](../design/DESIGN-028-catalog-view-specification.md): Catalog View Specification
- [DESIGN-031-swiftui-component-library](../design/DESIGN-031-swiftui-component-library.md): SwiftUI Component Library

---

### Story 6.3: Search & Filters

**Epic**: Epic 6 (Catalog View)

**Tasks:**
1. Implement search bar (instant search)
2. Implement filters (category, location, value, date)
3. Implement sorting (alphabetical, value, date, category)
4. Unit tests

**Acceptance Criteria:**
- Search returns results < 500ms
- 90%+ search relevance (top 3 results)
- Filters combine correctly (AND logic)
- Sort persists preference

**Files:**
- Modify: Packages/Features/CatalogFeature/Sources/CatalogViewModel.swift
- Add: Search/filter/sort logic

**References:**
- [DESIGN-028-catalog-view-specification](../design/DESIGN-028-catalog-view-specification.md): Catalog View Specification

---

## Sprint Risks

### P1: Firestore Query Performance

**Impact**: High (slow search)
**Mitigation**:
- Monitor query latency in Cloud Logging
- Add indexes if needed
- Cache search results locally

---

## Definition of Done

- [ ] Catalog view displays all items
- [ ] Real-time sync works correctly
- [ ] Search < 500ms, 90%+ relevance
- [ ] Filters and sorting functional
- [ ] All unit + UI tests pass
- [ ] Sprint demo shows catalog navigation

---

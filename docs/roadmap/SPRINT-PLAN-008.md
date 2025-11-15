# SPRINT-PLAN-008: Testing, Polish & TestFlight Launch

**Sprint**: 8 of 8
**Theme**: QA, testing, bug fixes, TestFlight beta launch

---

## Sprint Goals

1. ✅ All unit/integration/E2E tests pass
2. ✅ Golden dataset accuracy targets met
3. ✅ Zero P0 blockers remaining
4. ✅ TestFlight beta live with 25 internal testers

---

## Stories

### Story 8.1: E2E Test Automation

**Epic**: Epic 9 (Testing)

**Tasks:**
1. Implement 3 critical E2E tests (XCUITest)
   - Sign in → Catalog
   - Capture photo → AI processing → Item saved
   - Search item → View detail → Edit
2. Run tests on GitHub Actions (iOS CI)
3. Document test results

**Acceptance Criteria:**
- All 3 E2E tests pass
- Tests run in < 10 minutes
- GitHub Actions integration works
- Test coverage report generated

**Files:**
- Create: AbundanceUITests/SignInFlowTests.swift
- Create: AbundanceUITests/CaptureFlowTests.swift
- Create: AbundanceUITests/SearchFlowTests.swift

**References:**
- [TEST-STRATEGY-001-mvp-testing-approach](docs/test/TEST-STRATEGY-001-mvp-testing-approach.md): MVP Testing Approach

---

### Story 8.2: Golden Dataset Validation

**Epic**: Epic 9 (Testing)

**Tasks:**
1. Run golden dataset (100 items) through full pipeline
2. Calculate accuracy metrics (Layer 1-3)
3. Document failure modes
4. Generate validation report

**Acceptance Criteria:**
- Layer 1 > 60% accuracy
- Layer 2a > 80% accuracy
- Layer 2b > 75% accuracy
- Layer 3 > 75% accuracy
- Validation report complete

**Files:**
- Update: tests/golden-dataset/validation-report.md

**References:**
- [TEST-EXAMPLE-004-ml-cv-testing-patterns](docs/test/TEST-EXAMPLE-004-ml-cv-testing-patterns.md): ML/CV Testing Patterns

---

### Story 8.3: Bug Fixes & Polish

**Epic**: Epic 9 (Testing)

**Tasks:**
1. Fix all P0 bugs (zero tolerance)
2. Fix P1 bugs (best effort)
3. Polish UI (animations, transitions, loading states)
4. Code review + refactoring

**Acceptance Criteria:**
- Zero P0 bugs remaining
- P1 bugs documented with mitigations
- UI polish complete
- Code review approved

---

### Story 8.4: TestFlight Launch

**Epic**: Epic 9 (Testing)

**Tasks:**
1. Create TestFlight build (GitHub Actions)
2. Upload to App Store Connect
3. Invite 25 internal testers
4. Monitor Crashlytics for crashes
5. Document known issues

**Acceptance Criteria:**
- TestFlight beta live
- 25 internal testers invited
- Zero crashes in first 48 hours
- Known issues documented

**Files:**
- Create: docs/known-issues.md

**References:**
- [ADR-009-ios-deployment-cicd](docs/adr/ADR-009-ios-deployment-cicd.md): iOS Deployment & CI/CD

---

## Sprint Risks

### P0: Last-Minute P0 Bug Discovery

**Impact**: BLOCKING (cannot launch)
**Mitigation**:
- Daily triage of new issues
- Reserve capacity for emergency fixes
- Extend sprint if needed

---

## Definition of Done

- [ ] All tests pass (unit, integration, E2E)
- [ ] Golden dataset accuracy targets met
- [ ] Zero P0 bugs, P1 bugs documented
- [ ] TestFlight beta live
- [ ] 25 internal testers invited
- [ ] Sprint demo = launch celebration 🎉

---

## Success Metrics

**By End of Sprint 8:**
- [ ] TestFlight beta live with 25 internal testers
- [ ] All MUST HAVE features implemented
- [ ] 90%+ code coverage (unit tests)
- [ ] Layer 1-3 accuracy targets met
- [ ] Zero P0 blockers
- [ ] < $1000/month infrastructure costs

**Next Phase**: Stage 5.2 (Agent Prompts & Pre-Development Validation)

---

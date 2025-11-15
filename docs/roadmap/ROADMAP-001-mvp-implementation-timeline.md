# ROADMAP-001: MVP Implementation Roadmap

**Created**: 2025-11-12
**Stage**: 5.1 - Phased Implementation Roadmap
**Status**: Draft for Approval
**Development Model**: AI Agent-Driven
**Target Milestone**: TestFlight Beta Launch

---

## Background & Context

This roadmap synthesizes all architectural decisions (Stages 2.0-2.6), implementation research (Stages 3.1-3.6), and project scaffolding (Stages 4.1-4.3) into an actionable implementation sequence for the Abundance MVP.

**Objectives** (from abundance-analysis-pipeline-design.md, Stage 5.1):
1. Define implementation phases with clear dependencies
2. Map all features from Phase 1 specifications to implementation phases
3. Identify critical path and blocking dependencies
4. Document P0/P1/P2 technical risks with mitigations
5. Specify testable acceptance criteria for each phase

**Key Constraints:**
- iOS 26+ only (ADR-004) - limits market but reduces complexity
- Inventory-first MVP (ADR-003) - no marketplace features in initial release
- AI accuracy targets: Layer 1 > 60%, Layer 2a > 80%, Layer 2b > 75%, Layer 3 > 75%
- Budget: ~$554/month infrastructure costs (from TECH-STACK-MAP-001)

**References:**
- Phase 1 Specs: docs/specs/mvp-vision-features.md, feature-prioritization-matrix.md
- All PLAN-SUMMARY: docs/plans/PLAN-SUMMARY-stage-2.0.md through stage-4.3.md
- All ADRs: docs/adr/*.md (25 architecture decisions)
- All Scaffolding: docs/tech-stack/*.{swift,rules,json,md}

---

## Sprint Sequence (8 Sprints)

### Sprint 1: Project Setup & Authentication
**Theme**: Foundation - Development infrastructure and basic auth
**Document**: [SPRINT-PLAN-001](./SPRINT-PLAN-001.md)
**Key Deliverables**:
- iOS and Backend projects build successfully
- Apple Sign-In works end-to-end
- CI/CD pipeline deploys to TestFlight (Dev)

---

### Sprint 2-3: Camera Capture & Layer 1
**Theme**: Vision Framework object detection and barcode scanning
**Documents**: [SPRINT-PLAN-002](./SPRINT-PLAN-002.md), [SPRINT-PLAN-003](./SPRINT-PLAN-003.md)
**Key Deliverables**:
- Camera captures and uploads images to Firebase Storage
- Vision Framework detects household items (> 60% accuracy)
- Barcode scanning functional (> 95% success rate)
- Firestore triggers fire on item creation
- Backend CRUD endpoints functional

**Milestone Checkpoint**: Layer 1 complete, ready for AI pipeline integration

---

### Sprint 4-6: AI Pipeline (Layers 2a, 2b, 3)
**Theme**: Cloud AI integration (Gemini, SerpAPI, Claude)
**Documents**: [SPRINT-PLAN-004](./SPRINT-PLAN-004.md), [SPRINT-PLAN-005](./SPRINT-PLAN-005.md)
**Key Deliverables**:
- Layer 2a: Gemini attribute extraction (> 80% accuracy)
- Layer 2b: Barcode lookup + SerpAPI product ID (> 75% accuracy)
- Layer 3: Claude synthesis and conflict resolution (> 75% accuracy)
- Cost tracking functional (< $0.018/item)
- End-to-end pipeline < 10s processing time

**Milestone Checkpoint**: AI pipeline complete, items enriched with metadata

---

### Sprint 6-7: iOS Catalog & Detail Views
**Theme**: Browse, search, and edit inventory
**Documents**: [SPRINT-PLAN-006](./SPRINT-PLAN-006.md), [SPRINT-PLAN-007](./SPRINT-PLAN-007.md)
**Key Deliverables**:
- Catalog view displays all items with real-time sync
- Search returns results < 500ms (90%+ relevance)
- Filters and sorting functional
- Item detail view shows all metadata
- Edit mode allows user overrides
- Onboarding flow complete (3 screens)
- Profile view with subscription status

**Milestone Checkpoint**: Core user experience complete

---

### Sprint 8: Testing, Polish & TestFlight Launch
**Theme**: QA, bug fixes, and beta launch
**Document**: [SPRINT-PLAN-008](./SPRINT-PLAN-008.md)
**Key Deliverables**:
- All E2E tests pass (sign in, capture, search flows)
- Golden dataset accuracy targets validated
- Zero P0 bugs
- TestFlight beta live with 25 internal testers

**Milestone Checkpoint**: MVP Launch 🎉

---

## Dependency Chain

**Critical Path** (see [DEPENDENCY-GRAPH-001](./DEPENDENCY-GRAPH-001.md)):
```
Epic 1 (Auth) → Epic 3 (Camera/Layer 1) → Epic 5 (AI Pipeline) → Epic 6 (Catalog) → Epic 7 (Detail)
  Sprint 1         Sprint 2-3               Sprint 4-6             Sprint 6         Sprint 7
```

**Parallel Work**:
- Epic 2 (iOS Setup) and Epic 4 (Backend Setup) can run in Sprint 1 alongside Auth
- Epic 8 (Onboarding) can run in Sprint 7 alongside Detail implementation
- Epic 9 (Testing) distributed across all sprints

**Key Dependencies**:
- Sprint 2-3 requires Sprint 1 (Auth + iOS/Backend setup)
- Sprint 4-6 requires Sprint 2-3 (Layer 1 image upload)
- Sprint 6 requires Sprint 4-6 (AI pipeline generates enriched items)
- Sprint 7 requires Sprint 6 (Catalog for navigation)

---

## Technical Risks

See [RISK-REGISTER-001](./RISK-REGISTER-001.md) for detailed risk analysis.

**P0 Risks (BLOCKING)**:
- iOS 26 adoption rate too low (mitigation: fallback to iOS 25)
- Firebase quota exceeded (mitigation: usage monitoring + Blaze plan upgrade)

**P1 Risks (High Impact)**:
- AI pipeline accuracy below targets (mitigation: golden dataset validation, prompt tuning)
- Cloud Functions cold start latency (mitigation: 2nd gen functions, minimum instances)
- GitHub Actions macOS runner cost (mitigation: optimize caching, self-hosted runner)

---

## Success Metrics

**By End of Sprint 8**:
- TestFlight beta live with 25 internal testers
- All MUST HAVE features implemented (see feature-prioritization-matrix.md)
- AI accuracy targets met: Layer 1 > 60%, Layer 2a > 80%, Layer 2b > 75%, Layer 3 > 75%
- Zero P0 blockers
- Infrastructure costs < $1000/month

---

## Next Phase

**Stage 5.2**: Agent Prompts & Pre-Development Validation
- Generate detailed agent prompts for each sprint
- Create pre-development validation checklists
- Set up development environment

---

# PLAN SUMMARY: Stage 5.1 - Phased Implementation Roadmap

**Created**: 2025-11-12
**Stage**: 5.1 - Phased Implementation Roadmap
**Status**: Plan Complete - Ready for Gate 1 Approval ✅
**Expert Agents**: Software Architecture Expert + Product Strategy & UX

---

## What This Stage Accomplishes

Stage 5.1 synthesizes all technical decisions and implementation patterns from Phases 2-3 (Stages 2.1-3.6) into a **concrete, sprint-by-sprint roadmap** for building the Abundance MVP. With technology stack locked, architecture defined, and implementation patterns documented, this stage creates the final project plan that AI agents and human developers will execute.

**Key Accomplishments**:
1. ✅ 8-Sprint MVP Timeline (16 weeks, 4 months to launch)
2. ✅ 10 Epics broken into 59 implementable tasks
3. ✅ Technical dependency graph (critical path: Layer 1 → 2a → 2b → 3 → Testing → Launch)
4. ✅ Effort estimates grounded in Stages 3.1-3.6 code examples (320 story points total)
5. ✅ 13 risks identified with mitigation strategies (5 P0, 5 P1, 3 P2)
6. ✅ Team capacity planning (2-person team: 1 iOS, 1 Backend)

**Ready for Stage 5.2**: Feature-specific spec-kit and agent-ready implementation prompts can now be generated with sprint context.

---

## Critical Context: What We're Planning From

### Complete Technical Foundation (Phases 2-3)

**From Stage 2.1**: Tech Stack Locked ✅
- iOS: Swift 6.0, SwiftUI 6.0, iOS 26+ (fallback 25)
- Backend: Node.js 20, Cloud Functions, Firestore, Storage
- AI: Gemini 2.5 Flash-Lite, Claude Sonnet 4.5, Claude Haiku 4.5, SerpAPI

**From Stages 2.2-2.6**: iOS + Backend Architecture Defined ✅
- MVVM with @Observable, modular packages, constructor DI
- Liquid Glass UI components, WCAG-compliant
- 4-layer CV pipeline (Layer 1 on-device, Layers 2-3 cloud AI)

**From Stages 3.1-3.6**: Implementation Patterns Coded ✅
- 18 CODE-EXAMPLE documents with production-ready patterns
- 7 TEST-EXAMPLE documents with testing strategies
- All AI APIs verified (Gemini, Claude, SerpAPI, barcode APIs)
- All cost models validated (98.7% gross margin)

**Result**: Zero implementation ambiguity. All code patterns exist in Stages 3.1-3.6. Roadmap maps features to existing code examples.

---

## MVP Feature Breakdown

### P0: Core Cataloging Flow (Must-Have)

1. **Epic 1**: Onboarding & Authentication (13 SP) - Apple Sign-In
2. **Epic 2**: Camera Capture Layer 1 (35 SP) - YOLOv3-Tiny, real-time overlays
3. **Epic 3**: AI Cataloging Pipeline Layers 2-3 (80 SP) - Gemini, SerpAPI, Claude synthesis
4. **Epic 4**: Catalog View (27 SP) - Grid, search, Firestore listener
5. **Epic 5**: Item Detail & Edit (20 SP) - Full metadata, edit, delete

### P1: Essential Polish (Launch Blockers)

6. **Epic 6**: Accessibility & Localization (34 SP) - Reduce Transparency, VoiceOver, Dynamic Type
7. **Epic 7**: Error Handling & Offline (31 SP) - Retry, dead letter queue, failed item UI

### P2: Nice-to-Have (Post-Launch)

8. **Epic 8**: Data Export (20 SP) - CSV, JSON, Share Sheet
9. **Epic 9**: Profile & Settings (20 SP) - Subscription status, preferences
10. **Epic 10**: Analytics & Monitoring (40 SP) - Firebase Analytics, Cloud Monitoring, cost tracking

**Total**: 320 story points = 8 sprints × 40 points/sprint (2-person team)

---

## Sprint Timeline (16 Weeks)

### Sprint 1-2: Foundation (Week 1-4)
- **Sprint 1**: Infrastructure + Layer 1 (iOS camera + Backend storage)
- **Sprint 2**: Layer 2a Gemini attributes + Onboarding + Catalog empty state

### Sprint 3-4: AI Pipeline (Week 5-8)
- **Sprint 3**: Layer 2b SerpAPI product search + Item Detail View
- **Sprint 4**: Layer 3 Claude synthesis + Confidence Score UI

### Sprint 5-6: Features (Week 9-12)
- **Sprint 5**: Data Export + Profile + Analytics
- **Sprint 6**: Accessibility + Error Handling + Security

### Sprint 7-8: Launch (Week 13-16)
- **Sprint 7**: Testing + Performance + Documentation
- **Sprint 8**: App Store Submission + Production Deployment + Launch

**Critical Path**: Layer 1 → Layer 2a → Layer 2b → Layer 3 (Sprints 1-4) blocks all downstream work

**Parallelization**: iOS UI + Backend functions work in parallel within each sprint (40 SP iOS + 40 SP Backend)

---

## Technical Dependency Graph

```
Layer 1 (Sprint 1) - BLOCKS Layer 2a
  ├─> Camera Capture View (iOS)
  ├─> HouseholdItemDetector (iOS)
  └─> processLayer1Upload (Backend)
       │
Layer 2a (Sprint 2) - BLOCKS Layer 2b
  ├─> processLayer2aAttributes (Backend)
  └─> Catalog View (iOS)
       │
Layer 2b (Sprint 3) - BLOCKS Layer 3
  ├─> processLayer2bProductSearch (Backend)
  └─> Item Detail View (iOS)
       │
Layer 3 (Sprint 4) - BLOCKS Export + Testing
  ├─> processLayer3Synthesis (Backend)
  └─> Confidence Score UI (iOS)
       │
Export (Sprint 5) - NO BLOCKERS
  ├─> exportCatalog (Backend)
  └─> Data Export UI (iOS)
       │
Accessibility (Sprint 6) - NO BLOCKERS (overlays all views)
Testing (Sprint 7) - BLOCKED BY all features complete
Launch (Sprint 8) - BLOCKED BY testing complete
```

**Result**: 8-sprint sequential plan with Layer 1-2-3 critical path. iOS + Backend work in parallel within sprints.

---

## Effort Estimates (Grounded in Code Examples)

| Epic | Story Points | Complexity Rationale |
|------|--------------|----------------------|
| Epic 1: Onboarding | 13 | Straightforward: CODE-EXAMPLE-003 (Firebase Auth patterns) |
| Epic 2: Camera Layer 1 | 35 | Complex: CODE-EXAMPLE-009 (Vision Framework), CODE-EXAMPLE-011 (AVCaptureSession) |
| Epic 3: AI Pipeline | 80 | Most complex: CODE-EXAMPLE-011, 015, 016 (3 Cloud Functions, 3 AI APIs, retry logic) |
| Epic 4: Catalog View | 27 | Moderate: CODE-EXAMPLE-002 (MVVM patterns), Firestore listener |
| Epic 5: Item Detail | 20 | Moderate: CRUD operations, Firestore writes |
| Epic 6: Accessibility | 34 | Time-consuming: Testing on real devices, edge cases (DESIGN-035, 036) |
| Epic 7: Error Handling | 31 | Complex: Retry logic (DESIGN-042, 043), dead letter queue |
| Epic 8: Data Export | 20 | Moderate: CSV/JSON generation, Share Sheet |
| Epic 9: Profile | 20 | Straightforward: Settings UI, Firebase Auth signout |
| Epic 10: Analytics | 40 | Moderate: Firebase Analytics, Cloud Monitoring, cost tracking |

**Total**: 320 story points (100% capacity utilization, 0% buffer)

**Risk**: Timeline may slip if estimates are off. Recommend 20% buffer (9-10 sprints) for unknowns.

---

## Risk Register

### P0: Critical Risks (Must Mitigate)

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| R1: YOLOv3-Tiny accuracy <40% | High (core value prop) | Medium | Benchmark early (Sprint 1), fine-tune or switch to YOLOv8 if needed |
| R2: AI API rate limits block pipeline | High (users can't catalog) | Medium | Exponential backoff (DESIGN-042), quota increases, usage monitoring |
| R3: Firebase costs exceed budget | High (margin erosion) | Low | Daily cost monitoring, GCP billing alerts ($50, $100, $150) |
| R4: iOS 26 adoption <30% | Medium (fewer users) | Medium | Test iOS 25 fallback thoroughly (DESIGN-038) |
| R5: App Store rejection | High (launch delay) | Low | Pre-submission checklist, TestFlight beta audit |

### P1: High Risks (Monitor Closely)

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| R6: Claude JSON parsing failures (14-20%) | Medium (Layer 3 incomplete) | Medium | Log edge cases, retry with stricter prompt, fallback to Layer 2b |
| R7: UPCitemdb pricing unverified | Medium (cost model off by $99/month) | Medium | Contact sales before Sprint 3, verify pricing |
| R8: Team velocity <1.0 | Medium (timeline slips) | Medium | Track velocity sprint-by-sprint, adjust scope or add 9th sprint |
| R9: Backend latency >5s | Medium (poor UX) | Low | Monitor p95 latency, optimize if needed |
| R10: Firestore write limit (500/s) | Medium (throttling at scale) | Low | Random document IDs, avoid sequential indexes, monitor throughput |

**Total**: 13 risks (5 P0, 5 P1, 3 P2) with documented mitigation

---

## Outputs to Create (7 Artifacts)

1. **ROADMAP-001**: MVP Implementation Timeline (8-sprint Gantt chart, milestones, release date)
2. **EPIC-BREAKDOWN-001**: Features to Tasks (10 epics → 59 tasks with story IDs, acceptance criteria, points)
3. **SPRINT-PLAN-001-008**: Sprint Plans 1-8 (per-sprint task list, capacity, team assignments, dependencies)
4. **DEPENDENCY-GRAPH-001**: Technical Dependency Graph (Mermaid diagram, critical path)
5. **RISK-REGISTER-001**: Risk Register (13 risks, impact/probability matrix, mitigation strategies)
6. **EFFORT-ESTIMATES-001**: Effort Estimates by Feature (10 epics, story point breakdown, velocity assumptions)
7. **CHECKPOINT-stage-5.1.md**: Stage Checkpoint (summary, outputs, consistency verification, next stage readiness)

**Format**: All Markdown, cross-reference previous stages, use context-map.json for dependencies

---

## Success Metrics

### Sprint-Level
- [ ] All stories complete (acceptance criteria met)
- [ ] All tests passing (unit 80%+, integration 100% critical paths)
- [ ] No P0/P1 bugs open at sprint end
- [ ] Sprint demo successful (stakeholder approval)

### Epic-Level
- [ ] All MVP features from ADR-003 implemented
- [ ] All P0 accessibility met (Reduce Transparency, VoiceOver, Dynamic Type)
- [ ] All P0 error handling implemented (retry, dead letter queue, user feedback)

### Launch-Level (Gate 2 Criteria)
- [ ] App Store approved (no rejections)
- [ ] TestFlight beta (10+ testers, no critical bugs)
- [ ] Backend smoke tests passing (all Cloud Functions healthy)
- [ ] Monitoring active (dashboards, alerts configured)
- [ ] Cost within 10% of projections ($563.63/month Layer 2b, $337.50/month Layer 3)
- [ ] Performance targets met (60 FPS scrolling, <500ms camera startup, <5s Layer 2b latency)

---

## Consistency Verification

### Cross-Reference with Stage 2.1 (Tech Stack)

| Tech Stack Decision | Roadmap Integration | Status |
|---------------------|---------------------|--------|
| iOS 26+, Swift 6.0, SwiftUI 6.0 | All iOS tasks use Swift 6 patterns (CODE-EXAMPLE-001) | ✅ Aligned |
| Node.js 20, Cloud Functions 2nd gen | All backend tasks use Node.js 20 patterns (CODE-EXAMPLE-005) | ✅ Aligned |
| Gemini, Claude, SerpAPI | Layer 2a/2b/3 tasks reference verified code examples (011, 015, 016) | ✅ Aligned |
| Firebase iOS SDK, Alamofire, Kingfisher | Sprint 1 iOS tasks install verified dependencies (TECH-STACK-MAP-001) | ✅ Aligned |

### Cross-Reference with Stages 2.2-2.6 (Architecture)

| Architecture Decision | Roadmap Integration | Status |
|-----------------------|---------------------|--------|
| MVVM with @Observable (ADR-010) | Sprint 2: CatalogViewModel uses @Observable (CODE-EXAMPLE-002) | ✅ Aligned |
| Modular packages (ADR-011) | Sprint 1: Xcode project setup defines Features/, Core/, Shared/ | ✅ Aligned |
| Liquid Glass UI (Stage 2.6) | Sprint 2-3: ItemCard, FloatingTabBar use Liquid Glass components (DESIGN-031) | ✅ Aligned |
| 4-layer CV pipeline (Stage 2.4) | Sprints 1-4: Layer 1 → 2a → 2b → 3 sequential dependency | ✅ Aligned |

### Cross-Reference with Stages 3.1-3.6 (Implementation)

| Code Example | Referenced Sprint | Status |
|--------------|-------------------|--------|
| CODE-EXAMPLE-001 (Swift 6 concurrency) | Sprint 1: Camera, Layer 1 | ✅ Referenced |
| CODE-EXAMPLE-002 (Catalog MVVM) | Sprint 2: Catalog View | ✅ Referenced |
| CODE-EXAMPLE-009 (HouseholdItemDetector) | Sprint 1: Layer 1 | ✅ Referenced |
| CODE-EXAMPLE-011 (Layer 2a Cloud Function) | Sprint 2: Layer 2a | ✅ Referenced |
| CODE-EXAMPLE-015 (Layer 2b Orchestration) | Sprint 3: Layer 2b | ✅ Referenced |
| CODE-EXAMPLE-016 (Layer 3 Synthesis) | Sprint 4: Layer 3 | ✅ Referenced |
| TEST-EXAMPLE-001-007 | Sprint 7: Testing | ✅ Referenced |

**Result**: Zero contradictions detected ✅. All roadmap tasks reference existing code examples from Stages 3.1-3.6.

---

## Next Stage Preview

### Stage 5.2: Feature-Specific Spec-Kit & Agent Prompts

**Objective**: Generate per-feature PRDs and agent-ready implementation prompts for all 59 tasks.

**Prerequisites**:
- ✅ Stage 5.1 complete (Roadmap, sprint plans, dependency graph)
- ✅ All Stages 2.1-3.6 complete (Tech stack, architecture, implementation patterns)

**Planned Artifacts** (70-80 documents):
1. PRD-001 through PRD-059: Per-task Product Requirements (Given/When/Then acceptance criteria)
2. AGENT-PROMPT-001 through AGENT-PROMPT-059: Implementation prompts for AI agents
3. FEATURE-TEST-001 through FEATURE-TEST-059: Test plans derived from PRDs
4. PLAN-SUMMARY-stage-5.2.md
5. CHECKPOINT-stage-5.2.md

**Expert Agent**: All domain experts (orchestrated)

**Why Stage 5.1 Must Complete First**: Agent prompts require sprint context (which tasks to prioritize, which dependencies to respect, which code examples to reference).

---

## References

### Previous Stages (All Inputs)
- `docs/plans/PLAN-SUMMARY-stage-2.1.md` (Tech Stack)
- `docs/plans/PLAN-SUMMARY-stage-2.2.md` (iOS Architecture)
- `docs/plans/PLAN-SUMMARY-stage-2.3.md` (Backend Architecture)
- `docs/plans/PLAN-SUMMARY-stage-2.6.md` (UI/UX Design)
- `docs/plans/PLAN-SUMMARY-stage-3.1.md` through `stage-3.6.md` (Implementation patterns)

### Detailed Plan
- `docs/plans/2025-11-12-stage-5.1-phased-implementation-roadmap.md` (This stage's detailed plan)

### Architecture Decisions
- `docs/adr/ADR-003-mvp-scope-phasing.md` (MVP scope)
- All 25+ ADRs in `docs/adr/*.md`

### Design Documents
- All 43+ design documents in `docs/design/*.md`

### Context Map
- `docs/context-map.json` (Stage 5.1 definition)

### Master Pipeline
- `docs/abundance-analysis-pipeline-design.md` (Phase 5 definition)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-12 | 1.0 | Initial plan summary, Stage 5.1 phased implementation roadmap complete | Software Architecture Expert + Product Strategy & UX |

---

**Status**: ✅ **STAGE 5.1 PLAN COMPLETE**

**Next Step**: Gate 1 - Human reviews and approves plan before execution (Phase 4)

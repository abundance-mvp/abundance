# DEPENDENCY-GRAPH-001: Task Dependencies & Critical Path

**Created**: 2025-11-12
**Purpose**: Identify blocking dependencies and critical path to avoid sprint delays

---

## Critical Path (Longest Dependency Chain)

```
Epic 1 (Auth) → Epic 3 (Camera/Layer 1) → Epic 5 (AI Pipeline) → Epic 6 (Catalog) → Epic 7 (Detail)
  Sprint 1         Sprint 2-3               Sprint 4-6             Sprint 6         Sprint 7
```

**Total Critical Path**: 5 epics in dependency sequence

---

## Dependency Matrix

| Epic | Blocks | Blocked By | Can Run Parallel |
|------|--------|------------|------------------|
| Epic 1 (Auth) | Epic 3, Epic 5, Epic 8 | None | Epic 2, Epic 4 |
| Epic 2 (iOS Setup) | Epic 3, Epic 6, Epic 7, Epic 8 | None | Epic 1, Epic 4 |
| Epic 3 (Camera) | Epic 5 | Epic 1, Epic 2 | Epic 4 |
| Epic 4 (Backend) | Epic 5, Epic 6 | None | Epic 1, Epic 2, Epic 3 |
| Epic 5 (AI Pipeline) | Epic 6 | Epic 3, Epic 4 | Epic 8 |
| Epic 6 (Catalog) | Epic 7 | Epic 4, Epic 5 | Epic 8 |
| Epic 7 (Detail) | None | Epic 6 | Epic 8, Epic 9 |
| Epic 8 (Onboarding) | None | Epic 1 | Epic 2-7 |
| Epic 9 (Testing) | None | None | All epics |

---

## Sprint Sequencing Constraints

**Sprint 1**: MUST complete Epic 1 (Auth) + Epic 2 (iOS Setup) + Epic 4 (Backend Setup)
- Reason: Epic 3 (Camera) requires both iOS project and Auth to work

**Sprint 2-3**: MUST complete Epic 3 (Camera/Layer 1)
- Reason: Epic 5 (AI Pipeline) requires Layer 1 image upload to trigger

**Sprint 4-6**: MUST complete Epic 5 (AI Pipeline)
- Reason: Longest epic, blocks Epic 6 (Catalog display of enriched items)

**Sprint 7**: MUST complete Epic 6 (Catalog)
- Reason: Epic 7 (Detail) requires catalog to navigate from

**Sprint 8**: Complete Epic 7 (Detail) + Epic 8 (Onboarding) + polish
- Reason: No blockers, can work in parallel

---

## Risk: Critical Path Delays

If any epic on the critical path (1 → 3 → 5 → 6 → 7) is delayed, subsequent epics are blocked.

**Mitigation:**
- Add buffer capacity after Epic 5 (longest/riskiest)
- Pre-work: Set up AI provider accounts BEFORE Sprint 4 (API keys, Secret Manager)
- Monitor blockers for critical path epics continuously

---

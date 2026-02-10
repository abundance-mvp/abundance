---
title: "PR #34 Documentation Updates"
status: "Not Started"
created: 2026-02-10
scope: docs
priority: P1
---

# PR #34 Documentation Updates

> Audit-driven plan to bring docs in sync with `claude/pedantic-bhabha` (PR #34).

## Findings Summary

| Priority | Count | Description |
|----------|-------|-------------|
| P0 | 3 | Docs describe non-existent code or missing critical sections |
| P1 | 22 | Code has diverged significantly from spec |
| P2 | 33 | Incomplete coverage of new features |
| P3 | 19 | Style, formatting, minor gaps |

---

## Phase 1 — P0 Critical Fixes (before merge)

### Task 1: Fix SPEC-PIPE-004-A stale code references

**Files:** `docs/specs/SPEC-PIPE-004-camera-sweep-option-a-edgetam.md`

The spec references classes/protocols that have been renamed or restructured:
- `EdgeTAMProcessor` → verify actual class name in `Sources/EdgeTAMFeature/`
- Sweep capture flow references → reconcile with `SweepCaptureViewModel.swift`
- Segment overlay → reconcile with `SegmentOverlayView.swift` and `SegmentSelectionTray.swift`

### Task 2: Fix profile view-spec missing subviews

**Files:** `docs/specs/view-specs/profile-view.md`

Profile view spec is missing documentation for subviews added in PR #34 (stats cards, settings rows, etc.).

### Task 3: Fix AXe testing docs missing sweep coverage

**Files:** `docs/testing/` (AXe scenario files)

Sweep mode UI elements are not covered in any AXe test scenarios. Add sweep capture screen accessibility identifiers and test paths.

---

## Phase 2 — P1 Spec Accuracy Fixes (before merge)

### Task 4: Update SPEC-PIPE-004-A sweep pipeline details

**Files:** `docs/specs/SPEC-PIPE-004-camera-sweep-option-a-edgetam.md`

- Update segment selection UX to match current `SegmentSelectionTray.swift`
- Update sweep labeling pipeline to match `functions/src/ai-pipeline/layer1/sweep-labeling.ts`
- Add sweep mode segment picker (single vs burst) flow

### Task 5: Update SPEC-UI-001 camera capture flow

**Files:** `docs/specs/SPEC-UI-001-camera-capture-flow.md`

- Add sweep mode segment to state machine diagram
- Update CameraMode enum to include `.sweep`
- Document sweep ↔ single/burst mode transitions

### Task 6: Update SPEC-UI-003 design system

**Files:** `docs/specs/SPEC-UI-003-design-system.md`

- Document new sweep mode colors/icons added in PR #34
- Update component inventory with sweep-related components

### Task 7: Update SPEC-UI-004 Liquid Glass adoption

**Files:** `docs/specs/SPEC-UI-004-liquid-glass-adoption.md`

- Reconcile glass effect adoption status with actual implementation

### Task 8: Update SPEC-ARCH-002 layer1/layer2 pipeline

**Files:** `docs/specs/SPEC-ARCH-002-layer1-layer2-pipeline.md`

- Add sweep-labeling as Layer 1 variant
- Update pipeline diagram to show sweep path

### Task 9: Update SPEC-API-001 cloud functions

**Files:** `docs/specs/SPEC-API-001-cloud-functions.md`

- Add any new/modified Cloud Functions from PR #34
- Update function signatures if changed

### Task 10: Update view-specs for changed views

**Files:** `docs/specs/view-specs/*.md`

- Update view-specs for views modified in PR #34
- Reconcile accessibility identifiers with actual code

### Task 11: Update CLAUDE.md

**Files:** `CLAUDE.md`

- Verify module listing matches current `Sources/` structure
- Update any stale command references

---

## Phase 3 — P2 Completeness (separate PR)

P2 and P3 findings are lower priority and can be addressed in a follow-up PR:
- Add missing architecture diagrams for sweep pipeline
- Complete API parameter documentation
- Add missing examples and usage notes
- Style and formatting fixes

---

## Execution Notes

- Phase 1 + 2 should be completed before merging PR #34
- Phase 3 can be a separate documentation PR
- Use `uv run scripts/check_doc_freshness.py --update <doc>` after each doc update
- Run `uv run scripts/validate_docs.py` before committing

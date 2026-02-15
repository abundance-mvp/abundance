# Plan: Rebase main onto claude/pedantic-bhabha

**Status:** In Progress
**Created:** 2026-02-08
**Branch:** claude/pedantic-bhabha

---

## Context

- **main** has 30 commits since divergence (4cda1ae): camera fixes, pipeline improvements, bounding box fixes, catalog documentation, architecture diagrams, skill refactors, Xcode MCP bridge integration
- **claude/pedantic-bhabha** has 18 commits since divergence: EdgeTAM on-device detection feature, sweep capture mode, spatial deduplication, ARKit integration, performance-adaptive UX, comprehensive audit fixes
- **9 conflicting files** modified on both branches

## Strategy

Use `git rebase` to replay pedantic-bhabha's 18 commits on top of main's HEAD. This preserves both sets of work with main's changes as the base.

## Conflict Resolution Plan

### 1. Package.swift
- **main:** No EdgeTAMFeature target, has PipelineTests target
- **pedantic-bhabha:** Added EdgeTAMFeature target + dependency, no PipelineTests
- **Resolution:** KEEP BOTH — Add EdgeTAMFeature target AND PipelineTests target. CameraFeature depends on EdgeTAMFeature.

### 2. App/AbundanceApp.swift
- **main:** Has `configureFirebase()` static method separation, simulator debug bypass
- **pedantic-bhabha:** Inline Firebase config, simpler init
- **Resolution:** KEEP MAIN's structure (static configureFirebase method) — it's the better pattern. Apply pedantic-bhabha's changes on top if any.

### 3. Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift
- **main:** Uses `@Observable` (correct per architecture), has `catalogSelectedObjects` method, no deinit
- **pedantic-bhabha:** Regressed to `ObservableObject`/@Published, removed `catalogSelectedObjects`, added `deinit`, added `catalogObject`/`catalogAllObjects` public methods
- **Resolution:** KEEP @Observable from main. Port over the new public API methods (`catalogObject`, `catalogAllObjects`) and the removal of `catalogSelectedObjects`. Skip ObservableObject regression and deinit (not needed with @Observable).

### 4. Sources/CameraFeature/Views/CaptureView.swift
- **main:** Has teardown serialization, improved camera lifecycle, frozenFrame clearing fixes
- **pedantic-bhabha:** Added sweep mode UI (SweepCaptureView overlay, SweepModeToggle, captureMode state), `@StateObject` for viewModel (wrong with @Observable), frozenFrameImage
- **Resolution:** MERGE BOTH — Keep main's camera lifecycle fixes. Add sweep UI features. Use `@State` (not @StateObject) since we keep @Observable. Keep frozenFrameImage optimization.

### 5. Sources/CameraFeature/Views/DetectionResultsView.swift
- **main:** Has selection-based catalog button UI
- **pedantic-bhabha:** Changed to per-object catalog + catalog-all buttons
- **Resolution:** KEEP PEDANTIC-BHABHA's UI (catalog per-object is the better UX direction)

### 6. Sources/InventoryFeature/ItemCard.swift
- **main:** Updated styling/layout
- **pedantic-bhabha:** Added PhotoCarouselView integration
- **Resolution:** MERGE BOTH — Keep main's styling + add PhotoCarouselView

### 7. Sources/OnboardingFeature/AuthViewModel.swift & SignInView.swift
- **main:** Various fixes and improvements
- **pedantic-bhabha:** Minor changes
- **Resolution:** KEEP MAIN, apply any non-conflicting pedantic-bhabha changes

### 8. functions/src/triggers/onSessionCreated.ts
- **main:** Pipeline improvements
- **pedantic-bhabha:** Added sweep branch handling
- **Resolution:** MERGE BOTH — Keep main's pipeline code + add sweep session handling

## New Files from pedantic-bhabha (no conflicts)
- EdgeTAMFeature/ (entire module — 8 files)
- Sweep views: SweepCaptureView, SweepModeToggle, SegmentOverlayView, SegmentSelectionTray, OrganicBorderShape
- SweepCaptureViewModel, SweepARSessionManager
- CaptureSession model updates, SessionService
- ObjectDeduplicator
- Tests: 8 new test files
- Docs: sweep specs and plans

## Execution Steps

1. Commit this plan document
2. Run `git rebase main` on claude/pedantic-bhabha
3. Resolve conflicts commit-by-commit following the resolution plan above
4. After rebase completes, run `swift build` to verify
5. Run `swift test` to verify tests pass
6. Fix any build/test failures

## Success Criteria
- All 18 pedantic-bhabha commits rebased onto main
- Build succeeds (`swift build`)
- Tests pass (`swift test`)
- EdgeTAM and sweep features preserved
- Main's camera fixes and pipeline improvements preserved

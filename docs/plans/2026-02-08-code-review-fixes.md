# Code Review Fixes Plan

**Branch:** `claude/pedantic-bhabha`
**Date:** 2026-02-08
**Status:** In Progress

## Critical iOS Fixes (C1-C3)

### C1. Remove `ObservableObject` from `SweepARSessionManager`
**File:** `Sources/CameraFeature/Services/SweepARSessionManager.swift:15`
**Issue:** Uses `ObservableObject` instead of `@Observable` — violates project architecture. No view subscribes to it as `ObservableObject`.
**Fix:** Drop `ObservableObject` conformance and remove `@Published` property wrappers. Class is dead code (I5) but should still follow project patterns.

### C2. Remove direct `UIImpactFeedbackGenerator` from `SweepModeToggle` View
**File:** `Sources/CameraFeature/Views/SweepModeToggle.swift:41-43`
**Issue:** ADR-010 violation — direct UIKit API call in a View. `HapticFeedbackProviding` protocol exists for this.
**Fix:** Use SwiftUI `sensoryFeedback` modifier (iOS 17+) instead. This eliminates UIKit dependency entirely.

### C3. Fix `deinit` accessing `@MainActor`-isolated property
**File:** `Sources/CameraFeature/Services/SweepARSessionManager.swift:36-39`
**Issue:** `deinit` is `nonisolated` in Swift 6 but accesses `@MainActor`-isolated `arSession`.
**Fix:** Remove the `deinit` body. `stopTracking()` already handles cleanup and should be called explicitly.

## Important iOS Fixes (I1-I7)

### I1. Remove redundant `isSelected` from `SegmentedObject`
**File:** `Sources/EdgeTAMFeature/Models/SegmentedObject.swift:12`
**Issue:** Dual source of truth — ViewModel uses `selectedSegmentIds: Set<UUID>` exclusively.
**Fix:** Remove `isSelected` property. Update initializer and any references.

### I2. Fix semantic error case mismatch in `catalogSelectedSegments`
**File:** `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift:174`
**Issue:** Uses `.modelLoadFailed` for upload/session errors.
**Fix:** Add `.catalogFailed(String)` case to `SweepError` and use it here.

### I3. Fix `EdgeTAMService` cache eviction to be actually FIFO
**File:** `Sources/EdgeTAMFeature/Services/EdgeTAMService.swift:112-115`
**Issue:** `Dictionary.keys.first` is random, not FIFO despite comment.
**Fix:** Track insertion order with an array of keys, or use comment that says "evict arbitrary entry" since true FIFO isn't needed for this cache.

### I4. Document A18 exclusion as intentional in `DeviceEligibility`
**File:** `Sources/EdgeTAMFeature/Utilities/DeviceEligibility.swift`
**Fix:** Add comment documenting that A18 (non-Pro iPhone 16) is excluded intentionally due to Neural Engine throughput requirements.

### I5. Mark `SweepARSessionManager` as Phase 3 infrastructure
**File:** `Sources/CameraFeature/Services/SweepARSessionManager.swift`
**Issue:** Never instantiated — dead code.
**Fix:** Add doc comment marking it as Phase 3 infrastructure awaiting integration.

### I6. Add `@Bindable` to `SweepCaptureView.viewModel`
**File:** `Sources/CameraFeature/Views/SweepCaptureView.swift:11`
**Fix:** Change `var viewModel` to `@Bindable var viewModel` for recommended `@Observable` pattern.

### I7. Add `Equatable` conformance to `SegmentedObject`
**File:** `Sources/EdgeTAMFeature/Models/SegmentedObject.swift`
**Issue:** Missing `Equatable` causes full SwiftUI redraws.
**Fix:** Add `Equatable` conformance, excluding `maskData` from equality.

## Important Backend Fixes (B1-B3)

### B1. Validate `cropUrl` against allowed buckets
**File:** `functions/src/triggers/onSessionCreated.ts:300,326`
**Issue:** Latent SSRF vector — `cropUrl` not validated before use.
**Fix:** Add bucket validation for `sweepCrops[].cropUrl` using existing `ALLOWED_BUCKETS` pattern.

### B2. Add `failedAt` to outer catch block
**File:** `functions/src/triggers/onSessionCreated.ts:413-417`
**Issue:** Outer catch missing `failedAt: FieldValue.serverTimestamp()`.
**Fix:** Add `failedAt` field to the catch block's Firestore update.

### B3. Update SPEC-DATA-001 for sweep fields
**File:** `docs/specs/SPEC-DATA-001-firestore-schema.md`
**Fix:** Add `'sweep'` to `CaptureMode`, document `sweepCrops` field and `SweepCropInfo` schema.

## Suggestions (Nice to Have)

### S1. Remove unused `maxCacheMemoryBytes`
**File:** `Sources/EdgeTAMFeature/Services/EdgeTAMService.swift:38`

### S2. Remove emoji prefixes from `OrganicBorderShape` logger
**File:** `Sources/CameraFeature/Views/OrganicBorderShape.swift:27-37`

### S3. Add `groupId` fallback in sweep trigger
**File:** `functions/src/triggers/onSessionCreated.ts:322`
**Fix:** `groupId: sweepCrops[index].groupId || uuidv4()`

### S4. Add upper bound on `sweepCrops` array length
**File:** `functions/src/triggers/onSessionCreated.ts`
**Fix:** Cap at 50 crops with `SWEEP_TOO_MANY_CROPS` error.

## Parallel Agent Dispatch

Split into 3 independent work streams:
1. **iOS Critical + Important** (C1-C3, I1-I7, S1-S2) — Swift files
2. **Backend Fixes** (B1-B2, S3-S4) — TypeScript trigger
3. **Docs Update** (B3) — SPEC-DATA-001 schema

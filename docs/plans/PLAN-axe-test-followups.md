# AXe Test Follow-Up Plan

**Source:** AXe test run (Feb 2026) — 8 PASS, 3 PARTIAL PASS, 2 SKIP
**Status:** Completed

---

## Completed

- [x] P0: Delete dialog shows category instead of item name (`CollectionView.swift:109`)
- [x] P0: Grid overlap from AsyncImage `.fill` expanding beyond column (`ItemCard.swift`)
- [x] P1: Export button touch targets below 44pt HIG minimum (`ProfileView.swift`)
- [x] P2: Test doc `tab.capture` → `tab.camera` mismatch (`AXE-TEST-SCENARIOS.md`)
- [x] Simulator interaction toolkit (`scripts/sim-interact.sh` + docs)

---

## Remaining Items

### 1. Scenario 12: Refresh from Collection View

**Problem:** Scenario 12 (Deep Catalog Trigger) currently requires DetectionResultsView with a camera capture session. It should be triggerable from the collection view without a camera.

**Investigation:** No "Refresh" button exists in the collection view or item detail view. The catalog process is only triggered by new photo captures via the camera flow.

**Proposed Solution:**
- Add "Refresh" action to item context menu (long press) and item detail view
- Implementation: Set `item.status` back to `.pending`, which re-triggers the Cloud Function AI pipeline
- UI: Show confirmation dialog before re-triggering (costs API credits)
- Files to modify:
  - `Sources/CollectionFeature/ItemCard.swift` — add Refresh to context menu
  - `Sources/CollectionFeature/ItemDetailView.swift` — add Refresh button
  - `Sources/CollectionFeature/CollectionViewModel.swift` — add `refreshItem()` method
  - `Sources/Persistence/ItemRepository.swift` — may need status update method

**Effort:** ~2 hours

### 2. E2E Testing with Firebase Infrastructure

**Problem:** Current simulator testing uses `SimulatorItemRepository` (in-memory mock). No way to test real Firebase infrastructure, storage uploads, or AI pipeline during UX testing.

**Proposed Solution:**
- Add launch argument `--e2e-test-mode` detected in `AbundanceApp.swift`
- Create `E2ETestMainTabView` that:
  - Connects to real Firebase (dev project)
  - Bypasses camera with image injection (bundled test images or PHPicker)
  - Uses a dedicated test user account
- Image injection flow:
  - Bundle 2-3 test photos with multiple items in the app's test assets
  - "Capture" button loads a bundled image instead of opening camera
  - Image is uploaded to Firebase Storage → triggers Cloud Function pipeline
  - Real Firestore writes flow back to the UI

**Files to create/modify:**
- `App/E2ETestMainTabView.swift` — new test harness view
- `App/AbundanceApp.swift` — detect launch argument
- `App/TestAssets/` — bundled test images
- `Sources/CameraFeature/` — optional mock camera that returns bundled images

**Effort:** ~4-6 hours

### 3. Parallel Test Execution

**Problem:** Running all 13 AXe scenarios sequentially takes ~15-20 minutes. Parallelizing across simulators would cut this significantly.

**Proposed Solution:** Claude Team-based parallelism
- Spawn 3 worker agents, each assigned a booted simulator
- Partition scenarios across workers (e.g., 1-5, 6-9, 10-13)
- Each worker sources `scripts/sim-interact.sh` for standardized interaction
- Leader agent collects results and produces unified summary

**Prerequisites:**
- Multiple simulator device IDs (create via `xcrun simctl create`)
- Simulator-aware coordinate mapping (each sim window at different position)
- XcodeBuildMCP session defaults per worker (different `deviceId`)

**Constraints:**
- Each simulator needs its own window position (coordinate mapping depends on window pos)
- Build only needs to happen once; install to each sim separately
- Workers must not interfere with each other's simulator windows

**Effort:** ~3-4 hours

### 4. Select Button Height (P1 — deferred)

**Problem:** Collection "Select" toolbar button reports 34pt height, below the 44pt HIG minimum.

**Note:** This is a `.borderedProminent` SwiftUI button in a `.toolbar`. SwiftUI toolbar buttons have system-managed sizing. Adding `.frame(minHeight: 44)` may not work in toolbar context. Needs investigation — may require custom toolbar content or `.controlSize(.large)`.

**Effort:** ~30 min investigation

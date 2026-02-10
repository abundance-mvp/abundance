# PR #34 Documentation Audit Plan

> Generated: 2026-02-09
> Branch: `claude/pedantic-bhabha`
> PR: #34 — feat: on-device object detection + comprehensive docs audit
> Status: In Progress

---

## Context

PR #34 includes 100 changed files: EdgeTAM sweep capture mode + a 40-file docs audit. After the PR's doc audit, 3 subsequent code commits re-staled 25 docs, and 7 docs were never touched by the PR at all. Additionally, 5 of 12 architecture diagrams are stale.

### Post-PR Commits That Caused Re-Staleness

```
4899ee9 fix: use RotationCoordinator for device-orientation-aware capture and preview
b0696cf fix: resolve burst mode CancellationError on capture completion
446f968 feat: wire sweep mode onCatalog to catalogSelectedSegments pipeline
```

Changed files:
- `Sources/CameraFeature/Services/CameraSessionActor.swift`
- `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift`
- `Sources/CameraFeature/Views/CameraPreviewView.swift`
- `Sources/CameraFeature/Views/CaptureView.swift`
- `Sources/CameraFeature/Views/SweepCaptureView.swift`

---

## Phase 1: Diagrams (5 stale + 1 minor)

Regenerate using Mermaid MCP (`mcp__mermaid__generate_mermaid_diagram`). For each diagram, read the corresponding section of `docs/architecture/catalog-pipeline.md` (already updated) as the source of truth, then regenerate the PNG.

### 1.1 — 09-firestore-schema.png (P0)

**Issues:**
- ITEMS table missing fields: `material` (string?), `layer1Label` (string?), `layer1Category` (string?), `userEditedFields` (array[string]?), `photoMetadata` (object?), `marketPriceRange` (string?)
- SESSIONS table missing: `sweepCrops` (array[object]?)
- ITEMS `status` field should note iOS maps `pending`→`.processing`

**Source of truth:** catalog-pipeline.md Section 9 (lines 696-771)

**Mermaid type:** Entity-relationship diagram

### 1.2 — 01-system-overview.png (P0)

**Issues:**
- iOS App group missing "EdgeTAMFeature" component box
- iOS App shows "Inventory Grid" — should be "Collection Grid" (ADR-027)
- Cloud Functions group missing `onItemCreatedGemini3` (direct item trigger)
- AI Models group missing "Gemini 2.5 Flash Lite" for sweep labeling
- No sweep data flow shown (EdgeTAM crops → sweep labeling → Layer 2)

**Source of truth:** catalog-pipeline.md Section 2 (lines 43-80) + Section 2.5 (lines 83-105)

**Mermaid type:** Flowchart (groups: iOS App, Firebase, Cloud Functions, AI Models, External APIs)

### 1.3 — 03-layer1-detection.png (P1)

**Issues:**
- Only shows standard detection path (fetch images → Gemini Flash → bounding boxes → crop)
- Missing sweep branch: when `captureMode === "sweep"`, skips detection, runs Gemini 2.5 Flash Lite via `sweep-labeling.ts` for labeling only
- Should show an `alt` block: [captureMode=single|burst] standard path vs [captureMode=sweep] labeling-only path

**Source of truth:** catalog-pipeline.md Section 4 (lines 269-378) + sweep branch in Section 2.5 line 105

**Mermaid type:** Sequence diagram with alt block

### 1.4 — 02-capture-upload-flow.png (P1)

**Issues:**
- Only shows single/burst capture path (Double-tap or Long-press → upload to GCS Temp Bucket)
- Missing entire sweep upload path: EdgeTAM crops → sweepCrops field → session doc
- Upload target shown as "GCS Temp Bucket" but iOS code uploads to permanent bucket path `users/{uid}/items/{sid}_{idx}.jpg`

**Source of truth:** catalog-pipeline.md Section 3 (lines 219-266)

**Mermaid type:** Sequence diagram — add sweep alt path after existing single/burst

### 1.5 — 06-layer2-tool-calling.png (P1)

**Issues:**
- Cache key shown as `sha256(prompt+tools+schema)` — should be "Gemini API-managed (cachedContent.name)"
- Final JSON output missing `material` field
- Minor: trigger description accurate but could note `onDocumentCreated` with internal guards

**Source of truth:** catalog-pipeline.md Section 6 (lines 426-589)

**Mermaid type:** Sequence diagram — update cache key label and output fields

### 1.6 — 11-status-state-machine.png (P2, minor)

**Issues:**
- Missing `refreshItem()` as trigger label alongside `requestDeepScan()`
- No indication that iOS `ItemStatus` enum maps Firestore statuses to 3 values

**Source of truth:** catalog-pipeline.md Section 11 (lines 814-856)

**Mermaid type:** State diagram — add note about iOS enum mapping

---

## Phase 2: Untouched Docs (7 never updated by PR #34)

These docs were never included in the PR's audit. Each needs a full review against its code_refs.

### 2.1 — docs/GLOSSARY.md (P1)

**Code refs changed:** `Sources/CollectionFeature/`, `Sources/CameraFeature/`, `App/`
**Review focus:**
- Verify all glossary terms still match code (especially sweep mode terminology)
- Check if new terms need adding: `RotationCoordinator`, `MotionKeyframeDetector`, `SweepSessionState`, `SegmentedObject`
- Verify ADR-027 rename status: `InventoryFeature` → `CollectionFeature` (done?), `requestDeepScan()` → `refreshItem()` (done?)

### 2.2 — docs/view-specs/collection-view.md (P1)

**Code refs changed:** `Sources/CollectionFeature/`
**Review focus:**
- Compare view spec against current `CollectionView.swift` implementation
- Check if ItemCard changes (non-uniform sizes fix from `2026-02-08-collection-view-non-uniform-item-sizes.md`) are reflected
- Verify status indicators match current `ItemStatus` enum (3-state: `.processing`, `.complete`, `.failed`)

### 2.3 — docs/view-specs/item-card.md (P1)

**Code refs changed:** `Sources/CollectionFeature/Components/`
**Review focus:**
- Compare against current `ItemCard.swift` (modified in PR #34 for `withAnimation` async boundary fix)
- Check if card layout, status badge, and image display match implementation
- Verify accessibility identifiers

### 2.4 — docs/specs/SPEC-OPS-001-cicd-workflows.md (P2)

**Code refs changed:** `.github/workflows/`
**Review focus:**
- Verify all workflow names, triggers, and job configurations match current `.github/workflows/` files
- Check if any new workflows were added or existing ones modified

### 2.5 — docs/specs/SPEC-OPS-002-dev-workflow.md (P2)

**Code refs changed:** `scripts/`, `.claude/`
**Review focus:**
- Verify dev workflow commands match current `.claude/commands/` and `scripts/`
- Check if new scripts (e.g., `export_edgetam_coreml.py`) need documenting
- Verify environment setup instructions

### 2.6 — docs/testing/SIMULATOR-INTERACTION.md (P2)

**Code refs changed:** `scripts/`
**Review focus:**
- Verify simulator interaction coordinates and methods still match `scripts/sim-interact.sh`
- Check if new interaction patterns needed for sweep mode testing

### 2.7 — docs/view-specs/sign-in-view.md (P3)

**Code refs changed:** `Sources/OnboardingFeature/`
**Review focus:**
- Likely minimal drift — OnboardingFeature changes were probably minor
- Quick check that sign-in flow still matches spec

---

## Phase 3: Re-Staled Camera Docs (2 with real content drift)

These were updated by PR #34's audit but have actual content drift from the 3 post-PR commits.

### 3.1 — docs/specs/SPEC-UI-001-camera-capture-flow.md (P1)

**Re-staled by:** `4899ee9` (RotationCoordinator), `b0696cf` (burst CancellationError fix), `446f968` (sweep onCatalog wiring)
**Review focus:**
- Check if RotationCoordinator for device-orientation-aware capture is documented
- Verify burst mode error handling matches the CancellationError fix
- Check sweep mode `catalogSelectedSegments` wiring is documented
- Read: `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift`, `Sources/CameraFeature/Services/CameraSessionActor.swift`

### 3.2 — docs/view-specs/capture-view.md (P1)

**Re-staled by:** `4899ee9` (CaptureView.swift changed)
**Review focus:**
- Check if `CameraPreviewView` orientation handling is documented
- Verify capture view layout matches current implementation
- Read: `Sources/CameraFeature/Views/CaptureView.swift`, `Sources/CameraFeature/Views/CameraPreviewView.swift`

---

## Phase 4: Bulk Hash Refresh (23 re-staled docs)

These were updated by PR #34 and re-staled only because their broad `code_refs` (e.g., `functions/src/`, `Sources/`) detected unrelated changes. The 3 post-PR commits only touched CameraFeature, so `functions/`-referenced docs have zero content drift.

**Verification:** Confirm that none of the 3 post-PR commits changed files referenced by these docs, then run hash refresh.

### Docs to bulk-refresh after verification:

**Specs (functions/ refs — no drift):**
- `docs/specs/SPEC-ARCH-001-system-overview.md`
- `docs/specs/SPEC-ARCH-002-layer1-layer2-pipeline.md`
- `docs/specs/SPEC-ARCH-003-security-authentication.md`
- `docs/specs/SPEC-API-001-cloud-functions.md`
- `docs/specs/SPEC-DATA-001-firestore-schema.md`
- `docs/specs/SPEC-DATA-002-storage-architecture.md`
- `docs/specs/SPEC-PIPE-001-layer1-detection.md`
- `docs/specs/SPEC-PIPE-002-layer2-cataloging.md`
- `docs/specs/SPEC-PIPE-003-session-persistence.md`
- `docs/specs/SPEC-UI-002-catalog-inventory-flow.md`
- `docs/specs/SPEC-UI-003-design-system.md`

**ADRs (broad refs — no drift):**
- `docs/adr/ADR-006-database-selection.md`
- `docs/adr/ADR-007-api-architecture.md`
- `docs/adr/ADR-008-image-storage-architecture.md`
- `docs/adr/ADR-016-image-hosting-strategy.md`
- `docs/adr/ADR-018-barcode-product-lookup-strategy.md`
- `docs/adr/ADR-019-firestore-data-model-rationale.md`
- `docs/adr/ADR-020-cloud-functions-organization.md`
- `docs/adr/ADR-022-photo-privacy-protection.md`

**View specs and testing (CollectionFeature refs — only ItemCard changed, covered in Phase 2):**
- `docs/view-specs/detection-results-view.md`
- `docs/view-specs/edit-item-sheet.md`
- `docs/view-specs/item-detail-view.md`
- `docs/testing/AXE-TEST-SCENARIOS.md`

**Hash refresh command:**
```bash
for doc in <list>; do
  uv run scripts/check_doc_freshness.py --update "$doc"
done
```

---

## Execution Summary

| Phase | Items | Priority | Estimated Effort |
|-------|-------|----------|-----------------|
| 1. Diagrams | 6 diagrams | P0-P2 | Heavy (Mermaid generation) |
| 2. Untouched docs | 7 docs | P1-P3 | Medium (full review each) |
| 3. Re-staled camera docs | 2 docs | P1 | Light (focused review) |
| 4. Bulk hash refresh | 23 docs | P3 | Trivial (script run) |
| **Total** | **38 items** | | |

### Recommended execution order:
1. Phase 4 first (5 min) — clears noise from stale list
2. Phase 3 next (15 min) — small, high-value fixes
3. Phase 2 (30-45 min) — 7 doc reviews in parallel
4. Phase 1 last (45-60 min) — diagram regeneration requires Mermaid MCP

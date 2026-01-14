# Architecture Cleanup & iOS Superpowers Migration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Archive obsolete Stage 6 content, archive iOS specs created without ios-superpowers grounding, update verified-stage-development skill to enforce ios-superpowers + Axiom routing, and update context-map.json to reflect new architecture.

**Architecture:** This is a cleanup and migration task. Stage 6 (4-model AI pipeline validation) is superseded by Stage 7.0 (Gemini 3 Pro with tool calling). iOS specification documents created before the ios-superpowers skill was integrated lack proper Apple documentation grounding and Axiom skill patterns. These will be archived and regenerated using verified-stage-development with ios-superpowers.

**Tech Stack:** Bash (file operations), JSON (context-map.json), Markdown (skill files)

**Parallelization:** Tasks 1-5 are independent file archive operations. Tasks 6-7 are config updates. All 7 tasks CAN run in parallel.

---

## Task 1: Archive Stage 6 Validation Content

**Purpose:** Move obsolete 4-model pipeline validation infrastructure to archive.

**Files:**
- Create: `docs/archive/stage-6-pre-gemini3/` (directory)
- Move: `docs/validation/VALIDATION-MASTER-001.md`
- Move: `docs/validation/layer1/` (entire directory)
- Move: `docs/validation/RESEARCH-VALIDATION-stage-6.2.md`
- Move: `docs/validation/RESEARCH-VALIDATION-stage-6.3.md`
- Move: `docs/validation/RESEARCH-VALIDATION-stage-6.4.md`

**Step 1: Create archive directory**

```bash
mkdir -p docs/archive/stage-6-pre-gemini3
```

**Step 2: Move validation master document**

```bash
mv docs/validation/VALIDATION-MASTER-001.md docs/archive/stage-6-pre-gemini3/
```

**Step 3: Move layer1 validation directory**

```bash
mv docs/validation/layer1 docs/archive/stage-6-pre-gemini3/
```

**Step 4: Move Stage 6 research validation files**

```bash
mv docs/validation/RESEARCH-VALIDATION-stage-6.2.md docs/archive/stage-6-pre-gemini3/
mv docs/validation/RESEARCH-VALIDATION-stage-6.3.md docs/archive/stage-6-pre-gemini3/
mv docs/validation/RESEARCH-VALIDATION-stage-6.4.md docs/archive/stage-6-pre-gemini3/
```

**Step 5: Create archive README**

Create `docs/archive/stage-6-pre-gemini3/README.md`:

```markdown
# Stage 6 Archive (Pre-Gemini 3 Pro)

**Archived**: 2026-01-14
**Reason**: Superseded by Stage 7.0 (Gemini 3 Pro with native tool calling)

## What Was Archived

Stage 6 defined a validation framework for the original 4-model AI pipeline:
- Layer 1: iOS Vision + YOLO (on-device)
- Layer 2a: Gemini Flash-Lite (attribute extraction)
- Layer 2b: SerpAPI + Claude Haiku (product search + parsing)
- Layer 3: Claude Sonnet (synthesis)

## Why Archived

Stage 7.0 replaced the 4-model pipeline with a unified Gemini 3 Pro approach
that uses native tool calling (google_lens, barcode_lookup, web_search).
The validation framework for 4 separate layers is no longer applicable.

## Contents

- `VALIDATION-MASTER-001.md` - Master validation strategy for 4-model pipeline
- `layer1/` - iOS Layer 1 validation docs (still relevant for VisionCore)
- `RESEARCH-VALIDATION-stage-6.*.md` - Research validation reports

## Note on Layer 1

Layer 1 (iOS Vision Framework) validation is still relevant since on-device
object detection remains part of the architecture. Consider extracting
`layer1/` contents for use in future iOS validation work.
```

**Step 6: Verify archive**

```bash
ls -la docs/archive/stage-6-pre-gemini3/
```

Expected output: README.md, VALIDATION-MASTER-001.md, layer1/, RESEARCH-VALIDATION-stage-6.*.md

**Step 7: Commit**

```bash
git add docs/archive/stage-6-pre-gemini3/
git add -u docs/validation/
git commit -m "chore: archive Stage 6 validation content (superseded by Stage 7.0)"
```

---

## Task 2: Archive iOS ADRs (010-013)

**Purpose:** Archive iOS architecture ADRs created without ios-superpowers grounding.

**Files:**
- Create: `docs/archive/ios-pre-superpowers/adr/` (directory)
- Move: `docs/adr/ADR-010-swiftui-architecture-pattern.md`
- Move: `docs/adr/ADR-011-ios-module-structure.md`
- Move: `docs/adr/ADR-012-state-management-strategy.md`
- Move: `docs/adr/ADR-013-dependency-injection-strategy.md`

**Step 1: Create archive directory**

```bash
mkdir -p docs/archive/ios-pre-superpowers/adr
```

**Step 2: Move iOS ADRs**

```bash
mv docs/adr/ADR-010-swiftui-architecture-pattern.md docs/archive/ios-pre-superpowers/adr/
mv docs/adr/ADR-011-ios-module-structure.md docs/archive/ios-pre-superpowers/adr/
mv docs/adr/ADR-012-state-management-strategy.md docs/archive/ios-pre-superpowers/adr/
mv docs/adr/ADR-013-dependency-injection-strategy.md docs/archive/ios-pre-superpowers/adr/
```

**Step 3: Verify archive**

```bash
ls docs/archive/ios-pre-superpowers/adr/
```

Expected: ADR-010-*.md, ADR-011-*.md, ADR-012-*.md, ADR-013-*.md

**Step 4: Commit**

```bash
git add docs/archive/ios-pre-superpowers/adr/
git add -u docs/adr/
git commit -m "chore: archive iOS ADRs 010-013 (pre-ios-superpowers)"
```

---

## Task 3: Archive iOS Design Docs (006-014)

**Purpose:** Archive iOS architecture design docs created without ios-superpowers grounding.

**Files:**
- Create: `docs/archive/ios-pre-superpowers/design/` (directory)
- Move: `docs/design/DESIGN-006-ios-module-dependencies.md`
- Move: `docs/design/DESIGN-007-firebase-sdk-integration.md`
- Move: `docs/design/DESIGN-008-vision-framework-integration.md`
- Move: `docs/design/DESIGN-009-ios-networking-layer.md`
- Move: `docs/design/DESIGN-010-ios-data-persistence.md`
- Move: `docs/design/DESIGN-011-ios-data-models.md`
- Move: `docs/design/DESIGN-012-xcode-project-structure.md`
- Move: `docs/design/DESIGN-012-camera-capture-implementation.md`
- Move: `docs/design/DESIGN-013-vision-framework-integration-patterns.md`
- Move: `docs/design/DESIGN-014-barcode-detection-implementation.md`

**Step 1: Create archive directory**

```bash
mkdir -p docs/archive/ios-pre-superpowers/design
```

**Step 2: Move iOS design docs**

```bash
mv docs/design/DESIGN-006-ios-module-dependencies.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-007-firebase-sdk-integration.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-008-vision-framework-integration.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-009-ios-networking-layer.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-010-ios-data-persistence.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-011-ios-data-models.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-012-xcode-project-structure.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-012-camera-capture-implementation.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-013-vision-framework-integration-patterns.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-014-barcode-detection-implementation.md docs/archive/ios-pre-superpowers/design/
```

**Step 3: Verify archive**

```bash
ls docs/archive/ios-pre-superpowers/design/ | grep -E "DESIGN-0(0[6-9]|1[0-4])"
```

Expected: 10 DESIGN files

**Step 4: Commit**

```bash
git add docs/archive/ios-pre-superpowers/design/
git add -u docs/design/
git commit -m "chore: archive iOS design docs 006-014 (pre-ios-superpowers)"
```

---

## Task 4: Archive iOS UI/UX Specs (026-040)

**Purpose:** Archive iOS UI/UX specification docs created without ios-superpowers + Axiom grounding.

**Files:**
- Move to `docs/archive/ios-pre-superpowers/design/`:
  - `docs/design/DESIGN-026-onboarding-flow-ui-specification.md`
  - `docs/design/DESIGN-027-camera-capture-view-specification.md`
  - `docs/design/DESIGN-028-catalog-view-specification.md`
  - `docs/design/DESIGN-029-item-detail-view-specification.md`
  - `docs/design/DESIGN-030-profile-export-view-specification.md`
  - `docs/design/DESIGN-031-swiftui-component-library.md`
  - `docs/design/DESIGN-032-color-system-design-tokens.md`
  - `docs/design/DESIGN-033-typography-specifications.md`
  - `docs/design/DESIGN-034-animation-motion-specifications.md`
  - `docs/design/DESIGN-035-accessibility-implementation-guide.md`
  - `docs/design/DESIGN-036-wcag-compliance-checklist.md`
  - `docs/design/DESIGN-037-ui-mvvm-integration-patterns.md`
  - `docs/design/DESIGN-038-ios-25-compatibility-patterns.md`
  - `docs/design/DESIGN-039-layer-1-performance-optimization.md`
  - `docs/design/DESIGN-040-layer-1-edge-case-handling.md`

**Step 1: Move UI/UX specs (directory already created in Task 3)**

```bash
mv docs/design/DESIGN-026-onboarding-flow-ui-specification.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-027-camera-capture-view-specification.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-028-catalog-view-specification.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-029-item-detail-view-specification.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-030-profile-export-view-specification.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-031-swiftui-component-library.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-032-color-system-design-tokens.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-033-typography-specifications.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-034-animation-motion-specifications.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-035-accessibility-implementation-guide.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-036-wcag-compliance-checklist.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-037-ui-mvvm-integration-patterns.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-038-ios-25-compatibility-patterns.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-039-layer-1-performance-optimization.md docs/archive/ios-pre-superpowers/design/
mv docs/design/DESIGN-040-layer-1-edge-case-handling.md docs/archive/ios-pre-superpowers/design/
```

**Step 2: Verify archive**

```bash
ls docs/archive/ios-pre-superpowers/design/ | grep -E "DESIGN-0(2[6-9]|3[0-9]|40)" | wc -l
```

Expected: 15

**Step 3: Commit**

```bash
git add docs/archive/ios-pre-superpowers/design/
git add -u docs/design/
git commit -m "chore: archive iOS UI/UX specs 026-040 (pre-ios-superpowers)"
```

---

## Task 5: Archive iOS Code Examples and Test Examples

**Purpose:** Archive iOS code examples and test patterns created without ios-superpowers grounding.

**Files:**
- Create: `docs/archive/ios-pre-superpowers/code-examples/`
- Create: `docs/archive/ios-pre-superpowers/test-examples/`
- Move iOS-specific code examples (001-004, 009)
- Move iOS-specific test examples (001, 002, 004)

**Step 1: Create archive directories**

```bash
mkdir -p docs/archive/ios-pre-superpowers/code-examples
mkdir -p docs/archive/ios-pre-superpowers/test-examples
```

**Step 2: Move iOS code examples**

```bash
mv docs/design/CODE-EXAMPLE-001-swift6-concurrency-patterns.md docs/archive/ios-pre-superpowers/code-examples/
mv docs/design/CODE-EXAMPLE-002-catalog-mvvm-implementation.md docs/archive/ios-pre-superpowers/code-examples/
mv docs/design/CODE-EXAMPLE-003-firebase-ios-integration.md docs/archive/ios-pre-superpowers/code-examples/
mv docs/design/CODE-EXAMPLE-004-vision-framework-patterns.md docs/archive/ios-pre-superpowers/code-examples/
mv docs/design/CODE-EXAMPLE-009-household-item-detector.md docs/archive/ios-pre-superpowers/code-examples/
```

**Step 3: Move iOS test examples**

```bash
mv docs/test/TEST-EXAMPLE-001-viewmodel-unit-tests.md docs/archive/ios-pre-superpowers/test-examples/
mv docs/test/TEST-EXAMPLE-002-ios-testing-patterns.md docs/archive/ios-pre-superpowers/test-examples/
mv docs/test/TEST-EXAMPLE-004-ml-cv-testing-patterns.md docs/archive/ios-pre-superpowers/test-examples/
```

**Step 4: Create archive README**

Create `docs/archive/ios-pre-superpowers/README.md`:

```markdown
# iOS Pre-Superpowers Archive

**Archived**: 2026-01-14
**Reason**: Created without ios-superpowers skill (Apple docs + Axiom grounding)

## What Was Archived

iOS specification documents created before the ios-superpowers skill was
integrated into the verified-stage-development workflow. These documents
lack:

1. **Apple Documentation Grounding** - No verification against official
   Apple Developer documentation via sosumi.ai MCP
2. **Axiom Skill Patterns** - No integration with Axiom iOS skills:
   - axiom-swiftui-26-ref (iOS 26 SwiftUI patterns)
   - axiom-liquid-glass (Liquid Glass styling)
   - axiom-swift-concurrency (async/await, actors)
   - axiom-xcode-debugging (build issues)
   - axiom-memory-debugging (leaks, profiling)
   - axiom-ui-testing (XCTest, XCUITest)

## Contents

### ADRs (4 files)
- ADR-010: SwiftUI Architecture Pattern
- ADR-011: iOS Module Structure
- ADR-012: State Management Strategy
- ADR-013: Dependency Injection Strategy

### Design Docs (25 files)
- DESIGN-006 through DESIGN-014: iOS Architecture
- DESIGN-026 through DESIGN-040: iOS UI/UX Specifications

### Code Examples (5 files)
- CODE-EXAMPLE-001: Swift 6 Concurrency Patterns
- CODE-EXAMPLE-002: Catalog MVVM Implementation
- CODE-EXAMPLE-003: Firebase iOS Integration
- CODE-EXAMPLE-004: Vision Framework Patterns
- CODE-EXAMPLE-009: Household Item Detector

### Test Examples (3 files)
- TEST-EXAMPLE-001: ViewModel Unit Tests
- TEST-EXAMPLE-002: iOS Testing Patterns
- TEST-EXAMPLE-004: ML/CV Testing Patterns

## Regeneration Plan

These documents will be regenerated using:
1. `/verified-stage-development stage-2.2` - iOS Client Architecture
2. `/verified-stage-development stage-2.6` - iOS UI/UX Design
3. `/verified-stage-development stage-3.1` - iOS Implementation Research
4. `/verified-stage-development stage-3.3` - Layer 1 On-Device ML

Each stage will use ios-superpowers which automatically:
- Fetches Apple documentation via sosumi.ai MCP
- Routes to appropriate Axiom skills based on task type
- Grounds all specifications in official Apple patterns
```

**Step 5: Verify archive**

```bash
find docs/archive/ios-pre-superpowers -type f -name "*.md" | wc -l
```

Expected: 38 (4 ADR + 25 DESIGN + 5 CODE-EXAMPLE + 3 TEST-EXAMPLE + 1 README)

**Step 6: Commit**

```bash
git add docs/archive/ios-pre-superpowers/
git add -u docs/design/
git add -u docs/test/
git commit -m "chore: archive iOS code/test examples (pre-ios-superpowers)"
```

---

## Task 6: Update verified-stage-development Skill

**Purpose:** Add Axiom skill routing to the Agent Routing Matrix.

**Files:**
- Modify: `.claude/skills/verified-stage-development/SKILL.md`

**Step 1: Read current skill file**

Read `.claude/skills/verified-stage-development/SKILL.md` to find the Agent Routing table.

**Step 2: Update Agent Routing Matrix**

Find the existing table (around line 20-35):

```markdown
| Task Type | Skill | MCP Servers |
|-----------|-------|-------------|
| iOS UI/Logic | ios-superpowers | sosumi |
| Swift/SwiftUI | ios-superpowers | sosumi |
```

Replace with expanded table including Axiom skills:

```markdown
| Task Type | Skill | MCP Servers | Axiom Skills |
|-----------|-------|-------------|--------------|
| iOS UI/Logic | ios-superpowers | sosumi | axiom-swiftui-26-ref, axiom-liquid-glass |
| Swift/SwiftUI | ios-superpowers | sosumi | axiom-swiftui-26-ref |
| iOS Concurrency | ios-superpowers | sosumi | axiom-swift-concurrency |
| iOS Debugging | ios-superpowers | sosumi | axiom-xcode-debugging, axiom-memory-debugging |
| iOS Testing | ios-superpowers | sosumi | axiom-ui-testing |
| iOS Data/Persistence | ios-superpowers | sosumi | axiom-swiftdata |
| Firestore operations | firebase-superpowers | firebase | - |
| Cloud Functions | firebase-superpowers | firebase | - |
| Firebase Auth | firebase-superpowers | firebase | - |
| Firebase Storage | firebase-superpowers | firebase | - |
| Security Rules | firebase-superpowers | firebase | - |
| Non-Firebase GCP | gcp-superpowers | gcloud, observability, storage | - |
| AI/Gemini pipeline | gemini-integration | gcloud | - |
| Documentation/ADRs | general-purpose | - | - |
```

**Step 3: Update Key Principles section**

Find:

```markdown
**Key principles:**
- iOS stages (2.2, 3.1, 4.1) → Always use `ios-superpowers` for code tasks
```

Replace with:

```markdown
**Key principles:**
- iOS stages (2.2, 2.6, 3.1, 3.3, 4.1) → Always use `ios-superpowers` for code tasks
- ios-superpowers automatically routes to appropriate Axiom sub-skill based on task type
- Axiom skills provide iOS-specific patterns, debugging workflows, and best practices
- sosumi.ai MCP provides Apple Developer documentation grounding
- Backend stages → Use `firebase-superpowers` for Firebase, `gcp-superpowers` for other GCP
- AI pipeline stages → Use `gemini-integration` for Gemini tool calling patterns
- Research/docs → Use general-purpose agent
```

**Step 4: Verify changes**

```bash
grep -A 20 "Agent Routing" .claude/skills/verified-stage-development/SKILL.md | head -25
```

Expected: Updated table with Axiom Skills column

**Step 5: Commit**

```bash
git add .claude/skills/verified-stage-development/SKILL.md
git commit -m "feat(skill): add Axiom skill routing to verified-stage-development"
```

---

## Task 7: Update context-map.json

**Purpose:** Mark Stage 6.x as archived, update iOS stages to require re-run, update project status.

**Files:**
- Modify: `docs/context-map.json`

**Step 1: Read current context-map.json**

Read `docs/context-map.json` to understand current structure.

**Step 2: Update _meta section**

Change:
```json
"current_stage": "7.2",
"project_status": "Stage 7.1: completed (Gemini 3 Pro integration testing and deployment ready for staging)",
```

To:
```json
"current_stage": "architecture-cleanup",
"project_status": "Architecture cleanup: Archiving Stage 6 and iOS pre-superpowers content, preparing for iOS stages re-run with ios-superpowers",
"last_updated": "2026-01-14 (Architecture cleanup in progress)",
```

**Step 3: Update Stage 6.0 entry**

Change status to `archived` and add archive info:
```json
"stage-6.0": {
  "name": "Master Validation Document",
  "status": "archived",
  "archive_date": "2026-01-14",
  "archive_reason": "Superseded by Stage 7.0 Gemini 3 Pro unified pipeline",
  "archive_location": "docs/archive/stage-6-pre-gemini3/",
  ...
}
```

**Step 4: Update Stage 6.1 entry**

```json
"stage-6.1": {
  "status": "archived",
  "archive_date": "2026-01-14",
  "archive_reason": "Superseded by Stage 7.0 Gemini 3 Pro unified pipeline",
  "archive_location": "docs/archive/stage-6-pre-gemini3/",
  ...
}
```

**Step 5: Update Stage 6.2 entry**

```json
"stage-6.2": {
  "status": "archived",
  "archive_date": "2026-01-14",
  "archive_reason": "Superseded by Stage 7.0 Gemini 3 Pro unified pipeline",
  "archive_location": "docs/archive/stage-6-pre-gemini3/",
  ...
}
```

**Step 6: Update Stage 6.3 entry**

```json
"stage-6.3": {
  "status": "archived",
  "archive_date": "2026-01-14",
  "archive_reason": "Superseded by Stage 7.0 Gemini 3 Pro unified pipeline",
  "archive_location": "docs/archive/stage-6-pre-gemini3/",
  ...
}
```

**Step 7: Update Stage 6.4 entry**

```json
"stage-6.4": {
  "status": "archived",
  "archive_date": "2026-01-14",
  "archive_reason": "Superseded by Stage 7.0 Gemini 3 Pro unified pipeline",
  ...
}
```

**Step 8: Update iOS stages to require re-run**

For stages 2.2, 2.6, 3.1, 3.3, add:

```json
"stage-2.2": {
  "status": "requires_rerun",
  "rerun_reason": "Original outputs created without ios-superpowers grounding",
  "outputs_archived": "docs/archive/ios-pre-superpowers/",
  "outputs_created": []  // Clear this - will be repopulated on re-run
  ...
}
```

**Step 9: Update Stage 5.1**

```json
"stage-5.1": {
  "status": "requires_rerun",
  "rerun_reason": "Sprint plans reference obsolete Stage 6 validation stages and 4-model pipeline architecture",
  ...
}
```

**Step 10: Verify JSON validity**

```bash
python3 -c "import json; json.load(open('docs/context-map.json'))" && echo "Valid JSON"
```

Expected: "Valid JSON"

**Step 11: Commit**

```bash
git add docs/context-map.json
git commit -m "chore: update context-map.json for architecture cleanup"
```

---

## Summary Commit (After All Tasks Complete)

**Step 1: Create summary commit**

```bash
git add -A
git commit -m "chore: complete architecture cleanup for ios-superpowers migration

- Archive Stage 6 validation content (superseded by Stage 7.0)
- Archive iOS specs created without ios-superpowers (ADRs, designs, examples)
- Update verified-stage-development with Axiom skill routing
- Update context-map.json to reflect archived stages

Next steps:
- Re-run Stage 2.2 (iOS Client Architecture) with ios-superpowers
- Re-run Stage 2.6 (iOS UI/UX Design) with ios-superpowers
- Re-run Stage 3.1 (iOS Implementation Research) with ios-superpowers
- Re-run Stage 3.3 (Layer 1 On-Device ML) with ios-superpowers
- Re-run Stage 5.1 (Sprint Plans) with updated architecture"
```

---

## Post-Cleanup: Stages to Re-run

After this cleanup completes, the following stages need re-running with ios-superpowers:

| Stage | Name | Priority | Dependency |
|-------|------|----------|------------|
| 2.2 | iOS Client Architecture | HIGH | Foundation for all iOS work |
| 2.6 | iOS UI/UX Design | HIGH | Depends on 2.2 |
| 3.1 | iOS Implementation Research | MEDIUM | Depends on 2.2, 2.6 |
| 3.3 | Layer 1 On-Device ML | MEDIUM | Depends on 3.1 |
| 5.1 | Sprint Plans | HIGH | Depends on all above |

---

**Plan complete and saved to `docs/plans/2026-01-14-architecture-cleanup-ios-superpowers-migration.md`.**

**Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Agents (your preference)** - You dispatch parallel agents for Tasks 1-5 (independent file ops), then Tasks 6-7 (config updates)

**Which approach?**

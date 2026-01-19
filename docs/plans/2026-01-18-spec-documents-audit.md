# Spec Documents Audit Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:dispatching-parallel-agents to generate spec documents in parallel batches.

**Goal:** Create 14 comprehensive specification documents that capture the current implementation state of the Abundance iOS app.

**Architecture:** Parallel agent dispatch in 4 batches, with each agent responsible for 2-4 related spec documents. Agents read source code, extract implementation details, and write professional engineering specs.

**Tech Stack:** Markdown documentation, referencing Swift 6.0 (iOS), TypeScript (Firebase Functions), Firestore, GCS

---

## Document List

| ID | Document | Status | Priority |
|----|----------|--------|----------|
| SPEC-ARCH-001 | System Overview | New | P0 |
| SPEC-ARCH-002 | Layer 1/Layer 2 Pipeline | Update existing | P0 |
| SPEC-ARCH-003 | Security & Authentication | New | P0 |
| SPEC-DATA-001 | Firestore Schema | New | P0 |
| SPEC-DATA-002 | Storage Architecture | New | P0 |
| SPEC-PIPE-001 | Layer 1 Detection | New | P0 |
| SPEC-PIPE-002 | Layer 2 Cataloging | New | P0 |
| SPEC-PIPE-003 | Session Persistence | New (Design) | P1 |
| SPEC-API-001 | Cloud Functions API | New | P0 |
| SPEC-UI-001 | Camera Capture Flow | New | P1 |
| SPEC-UI-002 | Catalog/Inventory Flow | New | P1 |
| SPEC-OPS-001 | CI/CD Workflows | New | P2 |
| SPEC-OPS-002 | Dev Workflow | New | P2 |
| SPEC-OPS-003 | Cost Model | New | P2 |

---

## Batch Organization

### Batch 1: Core Architecture (3 agents in parallel)

**Agent 1A: System Overview**
- Create: `docs/specs/SPEC-ARCH-001-system-overview.md`
- Sources to read:
  - `README.md`, `CLAUDE.md`
  - `Sources/` directory structure
  - `functions/` directory structure
  - `docs/adr/` for architectural decisions

**Agent 1B: Layer 1/Layer 2 Pipeline**
- Update: `docs/specs/SPEC-LAYER1-LAYER2-ARCHITECTURE.md` → rename to `SPEC-ARCH-002-layer1-layer2-pipeline.md`
- Sources to read:
  - `functions/src/ai-pipeline/layer1/` (prompts.ts, layer1-service.ts, schemas/)
  - `functions/src/ai-pipeline/gemini/` (gemini-service.ts, prompts.ts, orchestrator.ts)
  - `functions/src/triggers/onSessionCreated.ts`
  - `functions/src/triggers/onItemCreatedGemini3.ts`

**Agent 1C: Security & Authentication**
- Create: `docs/specs/SPEC-ARCH-003-security-authentication.md`
- Sources to read:
  - `docs/adr/ADR-021-data-encryption-overview.md`
  - `docs/adr/ADR-022-photo-privacy-architecture.md`
  - `docs/adr/ADR-023-user-authentication-architecture.md`
  - `firestore.rules`, `storage.rules`
  - `Sources/Persistence/` for auth usage

---

### Batch 2: Data Layer (3 agents in parallel)

**Agent 2A: Firestore Schema**
- Create: `docs/specs/SPEC-DATA-001-firestore-schema.md`
- Sources to read:
  - `functions/src/triggers/` (all trigger files for document structures)
  - `Sources/Persistence/Services/` (Swift models)
  - `firestore.indexes.json`
  - `firestore.rules`

**Agent 2B: Storage Architecture**
- Create: `docs/specs/SPEC-DATA-002-storage-architecture.md`
- Sources to read:
  - `docs/adr/ADR-022-photo-privacy-architecture.md`
  - `functions/src/ai-pipeline/layer1/layer1-service.ts` (cropping, upload)
  - `Sources/CameraFeature/Services/StorageService.swift`
  - `storage.rules`

**Agent 2C: Cloud Functions API**
- Create: `docs/specs/SPEC-API-001-cloud-functions.md`
- Sources to read:
  - `functions/src/index.ts` (exports)
  - `functions/src/triggers/` (all triggers)
  - `functions/src/callable/` (callable functions)
  - `functions/package.json` (dependencies)

---

### Batch 3: Pipeline Details (3 agents in parallel)

**Agent 3A: Layer 1 Detection**
- Create: `docs/specs/SPEC-PIPE-001-layer1-detection.md`
- Sources to read:
  - `functions/src/ai-pipeline/layer1/prompts.ts`
  - `functions/src/ai-pipeline/layer1/layer1-service.ts`
  - `functions/src/ai-pipeline/layer1/schemas/detection-result.ts`
  - `functions/src/triggers/onSessionCreated.ts`

**Agent 3B: Layer 2 Cataloging**
- Create: `docs/specs/SPEC-PIPE-002-layer2-cataloging.md`
- Sources to read:
  - `functions/src/ai-pipeline/gemini/prompts.ts`
  - `functions/src/ai-pipeline/gemini/gemini-service.ts`
  - `functions/src/ai-pipeline/gemini/orchestrator.ts`
  - `functions/src/ai-pipeline/tools/tool-executor.ts`
  - `functions/src/triggers/onItemCreatedGemini3.ts`

**Agent 3C: Session Persistence (Design Spec)**
- Create: `docs/specs/SPEC-PIPE-003-session-persistence.md`
- Sources to read:
  - Current stateless implementation in `gemini-service.ts`
  - Research notes on hybrid approach (context caching + Firestore history)
  - No existing code - this is a DESIGN document for future implementation

---

### Batch 4: UI & Operations (5 agents in parallel)

**Agent 4A: Camera Capture Flow**
- Create: `docs/specs/SPEC-UI-001-camera-capture-flow.md`
- Sources to read:
  - `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift`
  - `Sources/CameraFeature/Views/` (capture-related views)
  - `Sources/CameraFeature/Services/`

**Agent 4B: Catalog/Inventory Flow**
- Create: `docs/specs/SPEC-UI-002-catalog-inventory-flow.md`
- Sources to read:
  - `Sources/CatalogFeature/` (all files)
  - `Sources/Persistence/Services/CatalogService.swift`

**Agent 4C: CI/CD Workflows**
- Create: `docs/specs/SPEC-OPS-001-cicd-workflows.md`
- Sources to read:
  - `.github/workflows/` (all workflow files)
  - `scripts/` (automation scripts)

**Agent 4D: Dev Workflow**
- Create: `docs/specs/SPEC-OPS-002-dev-workflow.md`
- Sources to read:
  - `CLAUDE.md`
  - `.claude/` directory structure
  - `docs/adr/` (dev-related ADRs)
  - `scripts/validate-environment.sh`

**Agent 4E: Cost Model**
- Create: `docs/specs/SPEC-OPS-003-cost-model.md`
- Sources to read:
  - `functions/src/ai-pipeline/layer1/prompts.ts` (LAYER1_TIMEOUTS, model ID)
  - `functions/src/ai-pipeline/gemini/prompts.ts` (model ID, token limits)
  - Existing cost estimates in `docs/specs/SPEC-LAYER1-LAYER2-ARCHITECTURE.md`

---

## Spec Document Template

Each agent should produce a document following this structure:

```markdown
# SPEC-{CATEGORY}-{NUMBER}: {Title}

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## Overview

[2-3 sentence summary of what this spec covers]

---

## Architecture

[Diagrams, component descriptions, data flow]

---

## Implementation Details

[Code references, configuration, schemas]

---

## API/Interface

[Public APIs, function signatures, data structures]

---

## Security Considerations

[Relevant security aspects]

---

## Future Considerations

[Known gaps, planned improvements]

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-18 | 1.0 | Initial spec from code audit |
```

---

## Task 1: Execute Batch 1 (Core Architecture)

### Step 1: Dispatch 3 parallel agents

Dispatch agents 1A, 1B, 1C simultaneously using Task tool with subagent_type="general-purpose".

**Agent 1A Prompt:**
```
Create SPEC-ARCH-001-system-overview.md

Read the following files to understand the system:
- README.md
- CLAUDE.md
- Sources/ directory structure (use Glob)
- functions/ directory structure (use Glob)
- docs/adr/ (read key ADRs)

Write a comprehensive system overview spec covering:
1. Project purpose and goals
2. Technology stack (Swift 6.0, TypeScript, Firebase, Gemini)
3. High-level architecture diagram (ASCII or Mermaid)
4. Module breakdown (iOS app, Cloud Functions, AI Pipeline)
5. Key dependencies and integrations

Save to: docs/specs/SPEC-ARCH-001-system-overview.md
```

**Agent 1B Prompt:**
```
Update SPEC-ARCH-002-layer1-layer2-pipeline.md

Read the current spec and the following implementation files:
- docs/specs/SPEC-LAYER1-LAYER2-ARCHITECTURE.md (existing)
- functions/src/ai-pipeline/layer1/prompts.ts
- functions/src/ai-pipeline/layer1/layer1-service.ts
- functions/src/ai-pipeline/layer1/schemas/detection-result.ts
- functions/src/ai-pipeline/gemini/prompts.ts
- functions/src/ai-pipeline/gemini/gemini-service.ts
- functions/src/ai-pipeline/gemini/orchestrator.ts
- functions/src/triggers/onSessionCreated.ts
- functions/src/triggers/onItemCreatedGemini3.ts

Update the spec to:
1. Reflect current implementation (Gemini 3 Flash/Pro)
2. Document actual tool definitions (google_lens_search, barcode_lookup, web_search)
3. Include thought signature handling requirements
4. Add code references with file:line format

Save as: docs/specs/SPEC-ARCH-002-layer1-layer2-pipeline.md
```

**Agent 1C Prompt:**
```
Create SPEC-ARCH-003-security-authentication.md

Read the following files:
- docs/adr/ADR-021-data-encryption-overview.md
- docs/adr/ADR-022-photo-privacy-architecture.md
- docs/adr/ADR-023-user-authentication-architecture.md
- firestore.rules
- storage.rules
- Sources/Persistence/ (auth-related code)

Write a security spec covering:
1. Authentication flow (Firebase Auth)
2. Authorization model (Firestore rules)
3. Data encryption (at rest, in transit)
4. Photo privacy (original images never stored)
5. Storage security rules

Save to: docs/specs/SPEC-ARCH-003-security-authentication.md
```

### Step 2: Wait for agent completion

Wait for all 3 agents to complete and return results.

### Step 3: Verify outputs

Run: `ls -la docs/specs/SPEC-ARCH-*.md`
Expected: 3 files created/updated

### Step 4: Commit Batch 1

```bash
git add docs/specs/SPEC-ARCH-*.md
git commit -m "docs: add architecture specs (SPEC-ARCH-001, 002, 003)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Execute Batch 2 (Data Layer)

### Step 1: Dispatch 3 parallel agents

Dispatch agents 2A, 2B, 2C simultaneously.

**Agent 2A Prompt:**
```
Create SPEC-DATA-001-firestore-schema.md

Read the following files to understand data models:
- functions/src/triggers/onSessionCreated.ts (CaptureSession interface)
- functions/src/triggers/onItemCreatedGemini3.ts (Item interfaces)
- firestore.indexes.json
- firestore.rules
- Sources/Persistence/Models/ (Swift models if they exist)

Document:
1. All Firestore collections (sessions, items, users)
2. Document schemas with TypeScript interfaces
3. Index definitions
4. Security rules per collection
5. Relationships between documents

Save to: docs/specs/SPEC-DATA-001-firestore-schema.md
```

**Agent 2B Prompt:**
```
Create SPEC-DATA-002-storage-architecture.md

Read the following files:
- docs/adr/ADR-022-photo-privacy-architecture.md
- functions/src/ai-pipeline/layer1/layer1-service.ts (cropping, upload logic)
- Sources/CameraFeature/Services/StorageService.swift
- storage.rules

Document:
1. Bucket structure (temp vs permanent)
2. Object naming conventions
3. Upload flows (client → temp → processed → permanent)
4. Privacy model (originals discarded)
5. Storage rules and access patterns

Save to: docs/specs/SPEC-DATA-002-storage-architecture.md
```

**Agent 2C Prompt:**
```
Create SPEC-API-001-cloud-functions.md

Read the following files:
- functions/src/index.ts (all exports)
- functions/src/triggers/ (all trigger files)
- functions/src/callable/ (all callable functions)
- functions/package.json

Document:
1. All deployed functions (triggers and callables)
2. Function signatures and parameters
3. Trigger conditions (Firestore paths, HTTP)
4. Dependencies and environment
5. Timeout and memory configurations

Save to: docs/specs/SPEC-API-001-cloud-functions.md
```

### Step 2: Wait for agent completion

### Step 3: Verify outputs

Run: `ls -la docs/specs/SPEC-DATA-*.md docs/specs/SPEC-API-*.md`
Expected: 3 files created

### Step 4: Commit Batch 2

```bash
git add docs/specs/SPEC-DATA-*.md docs/specs/SPEC-API-*.md
git commit -m "docs: add data layer specs (SPEC-DATA-001, 002, SPEC-API-001)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Execute Batch 3 (Pipeline Details)

### Step 1: Dispatch 3 parallel agents

Dispatch agents 3A, 3B, 3C simultaneously.

**Agent 3A Prompt:**
```
Create SPEC-PIPE-001-layer1-detection.md

Read the following files:
- functions/src/ai-pipeline/layer1/prompts.ts
- functions/src/ai-pipeline/layer1/layer1-service.ts
- functions/src/ai-pipeline/layer1/schemas/detection-result.ts
- functions/src/triggers/onSessionCreated.ts

Document in detail:
1. Gemini 3 Flash model configuration (thinking_level: LOW)
2. System prompt (full text)
3. Detection schema (DetectedObject interface)
4. Bounding box format ([ymin, xmin, ymax, xmax] normalized 0-1000)
5. Multi-image grouping logic (groupId)
6. Cropping and upload flow
7. Error handling and timeouts
8. Cost estimates per detection

Save to: docs/specs/SPEC-PIPE-001-layer1-detection.md
```

**Agent 3B Prompt:**
```
Create SPEC-PIPE-002-layer2-cataloging.md

Read the following files:
- functions/src/ai-pipeline/gemini/prompts.ts
- functions/src/ai-pipeline/gemini/gemini-service.ts
- functions/src/ai-pipeline/gemini/orchestrator.ts
- functions/src/ai-pipeline/tools/tool-executor.ts
- functions/src/triggers/onItemCreatedGemini3.ts

Document in detail:
1. Gemini 3 Pro model configuration
2. System prompt (full text)
3. Tool definitions (google_lens_search, barcode_lookup, web_search)
4. Thought signature handling (CRITICAL)
5. Tool execution flow
6. Catalog output schema
7. Error handling and retries
8. Cost estimates per catalog

Save to: docs/specs/SPEC-PIPE-002-layer2-cataloging.md
```

**Agent 3C Prompt:**
```
Create SPEC-PIPE-003-session-persistence.md

This is a DESIGN SPEC for future implementation.

Read the current stateless implementation:
- functions/src/ai-pipeline/gemini/gemini-service.ts

Design a hybrid session persistence approach:

1. Problem Statement
   - Current: Each Layer 2 call is stateless
   - Need: Resume context when user adds photos or requests re-catalog

2. Proposed Solution: Hybrid Approach
   a) Store previous Layer 2 results in Firestore (per item)
   b) Use Explicit Context Caching for system prompts (90% token savings)
   c) Construct prompts with previous context for updates

3. Data Model
   - items/{itemId}/catalogHistory subcollection
   - Fields: timestamp, model, prompt, response, toolCalls

4. Context Caching Strategy
   - Cache system prompt + tool definitions (min 2048 tokens)
   - 90% cost reduction on repeated calls
   - TTL: 1 hour minimum

5. Implementation Steps (high-level)

Save to: docs/specs/SPEC-PIPE-003-session-persistence.md
```

### Step 2: Wait for agent completion

### Step 3: Verify outputs

Run: `ls -la docs/specs/SPEC-PIPE-*.md`
Expected: 3 files created

### Step 4: Commit Batch 3

```bash
git add docs/specs/SPEC-PIPE-*.md
git commit -m "docs: add pipeline specs (SPEC-PIPE-001, 002, 003)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Execute Batch 4 (UI & Operations)

### Step 1: Dispatch 5 parallel agents

Dispatch agents 4A, 4B, 4C, 4D, 4E simultaneously.

**Agent 4A Prompt:**
```
Create SPEC-UI-001-camera-capture-flow.md

Read the following files:
- Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift
- Sources/CameraFeature/Views/ (all view files)
- Sources/CameraFeature/Services/

Document:
1. Capture modes (single tap, burst hold)
2. Burst capture parameters (500ms interval, 1-4 sec hold, max 8 photos)
3. UI states (idle, capturing, uploading, analyzing, results, error)
4. State machine diagram
5. Error handling and recovery
6. Haptic feedback triggers

Save to: docs/specs/SPEC-UI-001-camera-capture-flow.md
```

**Agent 4B Prompt:**
```
Create SPEC-UI-002-catalog-inventory-flow.md

Read the following files:
- Sources/CatalogFeature/ (all files)
- Sources/Persistence/Services/CatalogService.swift

Document:
1. Catalog view layout and navigation
2. Item card components
3. Item detail view
4. Edit flow
5. Layer 2 trigger ("Catalog" button)
6. Status indicators (pre-catalogued, cataloging, complete)

Save to: docs/specs/SPEC-UI-002-catalog-inventory-flow.md
```

**Agent 4C Prompt:**
```
Create SPEC-OPS-001-cicd-workflows.md

Read the following files:
- .github/workflows/ (all workflow files)
- scripts/ (automation scripts)

Document:
1. All GitHub Actions workflows
2. Trigger conditions
3. Jobs and steps
4. Required secrets
5. Deployment targets
6. Testing requirements

Save to: docs/specs/SPEC-OPS-001-cicd-workflows.md
```

**Agent 4D Prompt:**
```
Create SPEC-OPS-002-dev-workflow.md

Read the following files:
- CLAUDE.md
- .claude/ directory structure
- docs/adr/ (dev-related ADRs)
- scripts/validate-environment.sh

Document:
1. Development environment setup
2. Branch naming conventions
3. Commit message format
4. Claude Code integration
5. Skills and commands available
6. Testing requirements before PR

Save to: docs/specs/SPEC-OPS-002-dev-workflow.md
```

**Agent 4E Prompt:**
```
Create SPEC-OPS-003-cost-model.md

Read the following files:
- functions/src/ai-pipeline/layer1/prompts.ts (model ID, timeouts)
- functions/src/ai-pipeline/gemini/prompts.ts (model ID, token limits)
- docs/specs/SPEC-LAYER1-LAYER2-ARCHITECTURE.md (existing cost estimates)

Document:
1. Layer 1 costs (Gemini 3 Flash per image)
2. Layer 2 costs (Gemini 3 Pro + tool calls)
3. Storage costs (GCS, Firestore)
4. Firebase costs (Auth, Functions)
5. Cost optimization strategies
6. Projected costs at scale

Save to: docs/specs/SPEC-OPS-003-cost-model.md
```

### Step 2: Wait for agent completion

### Step 3: Verify outputs

Run: `ls -la docs/specs/SPEC-UI-*.md docs/specs/SPEC-OPS-*.md`
Expected: 5 files created

### Step 4: Commit Batch 4

```bash
git add docs/specs/SPEC-UI-*.md docs/specs/SPEC-OPS-*.md
git commit -m "docs: add UI and ops specs (SPEC-UI-001, 002, SPEC-OPS-001, 002, 003)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Final Verification

### Step 1: List all created specs

Run: `ls -la docs/specs/SPEC-*.md`
Expected: 14 files

### Step 2: Verify content quality

Spot-check 2-3 documents for:
- Proper structure (Overview, Architecture, Implementation, etc.)
- Code references with file:line format
- No placeholder text

### Step 3: Create index document

Create `docs/specs/README.md` with table of contents linking all specs.

### Step 4: Final commit

```bash
git add docs/specs/README.md
git commit -m "docs: add spec index and complete audit

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Execution Options

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per batch, review between batches, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?

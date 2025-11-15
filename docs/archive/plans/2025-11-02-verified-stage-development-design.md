# Verified Stage Development: Design Document

**Created**: 2025-11-02
**Status**: Design Complete - Ready for Phased Implementation
**Type**: Process Automation Skill
**Purpose**: Deterministic stage development with research verification, quality gates, and approval workflows

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Problem Statement](#problem-statement)
3. [Design Goals](#design-goals)
4. [Architecture Overview](#architecture-overview)
5. [Component Specifications](#component-specifications)
6. [Workflow Details](#workflow-details)
7. [Error Handling](#error-handling)
8. [Usage Examples](#usage-examples)
9. [Phased Implementation Plan](#phased-implementation-plan)
10. [Success Metrics](#success-metrics)
11. [Open Questions](#open-questions)

---

## Executive Summary

The Verified Stage Development system transforms the ad-hoc, non-deterministic process of stage execution into a structured, verifiable workflow. It wraps `superpowers:write-plan` and `superpowers:execute-plan` with quality gates that ensure:

1. **Research Verification**: All technical claims (pricing, capabilities, latency) are verified against official documentation
2. **Context Completeness**: All previous stage artifacts are explicitly loaded
3. **Human Control**: Two approval gates prevent unverified work from proceeding
4. **Documentation Integrity**: Master pipeline design stays synchronized with implementation reality

**Key Innovation**: One-time Apple documentation fetching via Sosumi.ai provides fast, accurate local reference for all iOS stages.

**Scope**: Applies to all 17 stages of the Abundance Analysis Pipeline (Phases 1-6).

---

## Problem Statement

### Current Pain Points

When using `superpowers:write-plan` directly for stage development:

1. **Non-Deterministic Behavior**:
   - Agent doesn't consistently fetch correct/complete list of previous stage documents
   - Missing context leads to contradictions and rework
   - No guarantee original stage design in `abundance-analysis-pipeline-design.md` is followed

2. **Unverified Technical Claims**:
   - Pricing, latency, and capability numbers invented or outdated
   - No requirement to cite official documentation
   - Expensive errors discovered late in implementation

3. **Code Quality Issues**:
   - Code examples use fake libraries or non-existent APIs
   - Test examples don't follow TDD patterns
   - No verification before document creation

4. **Documentation Drift**:
   - Stage implementation diverges from original design
   - Master pipeline document becomes stale
   - No mechanism to track or reconcile changes

5. **Lack of Approval Gates**:
   - Work proceeds without human review of research or plans
   - Quality issues discovered too late
   - No checkpoints before expensive operations

### Impact

- Hours lost to rework when contradictions discovered
- Cost overruns from incorrect pricing assumptions
- Implementation failures from fake API usage
- Loss of confidence in agent-generated specifications

---

## Design Goals

### Primary Goals

1. **Determinism**: Same stage invocation always collects same context, follows same process
2. **Verification**: All technical claims verified against official sources before planning
3. **Quality Gates**: Human approval required at critical decision points
4. **Traceability**: Complete audit trail from requirements → research → plan → execution → approval
5. **Maintainability**: Master pipeline design stays current with implementation reality

### Non-Goals (Explicit)

- **Not a replacement** for write-plan/execute-plan (enhancement only)
- **Not fully automated** (human gates are intentional, not a limitation)
- **Not a testing framework** (validates documentation, not running code)
- **Not a CI/CD system** (pre-implementation verification only)

---

## Architecture Overview

### System Context

```
┌─────────────────────────────────────────────────────────────────┐
│                    Abundance Pipeline (17 Stages)                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ User invokes
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              Verified Stage Development Orchestrator             │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Context    │→ │   Research   │→ │   Planning   │→ ...     │
│  │  Collection  │  │     Hook     │  │  (write-plan)│          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                 ┌────────────┼────────────┐
                 ▼            ▼            ▼
         ┌──────────┐  ┌──────────┐  ┌──────────┐
         │  Apple   │  │Previous  │  │ Master   │
         │   Docs   │  │  Stage   │  │ Pipeline │
         │(Sosumi)  │  │Artifacts │  │  Design  │
         └──────────┘  └──────────┘  └──────────┘
```

### Component Diagram (Full Vision)

```
┌─────────────────────────────────────────────────────────────────┐
│                Verified Stage Development Skill                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Phase 1: Context Collection                                     │
│  ├─ Explicit file list (hardcoded, not glob)                    │
│  ├─ Verify docs/apple/ exists (for iOS stages)                  │
│  └─ Load master pipeline design                                 │
│                                                                   │
│  Phase 2: Research Hook (Sub-Agent)                             │
│  ├─ Identify technical claims in stage requirements             │
│  ├─ Search docs/apple/ for iOS/Swift claims (Grep)              │
│  ├─ WebSearch + WebFetch for GCP/Firebase/other                 │
│  ├─ Resolve contradictions automatically                         │
│  └─ Output: docs/validation/RESEARCH-VALIDATION-stage-X.X.md    │
│                                                                   │
│  Phase 3: Planning (superpowers:write-plan)                     │
│  ├─ Pass verified context + research report                      │
│  ├─ Enforce real library usage from TECH-STACK-MAP-001          │
│  ├─ Require TDD patterns in all test examples                   │
│  └─ Output: docs/plans/PLAN-SUMMARY-stage-X.X.md                │
│                                                                   │
│  Phase 4: Verification Hook (Sub-Agent)                         │
│  ├─ Consistency check against master pipeline                   │
│  ├─ Code example validation (real libraries)                    │
│  ├─ TDD compliance check                                         │
│  ├─ Cross-stage dependency verification                          │
│  └─ Output: docs/validation/STAGE-X.X-CHECKLIST.md              │
│                                                                   │
│  ──────────────── GATE 1: Human Approval ────────────────       │
│  └─ Review verification reports → "proceed" or "override"       │
│                                                                   │
│  Phase 5: Execution (superpowers:execute-plan)                  │
│  ├─ Create all stage artifacts (specs, designs, ADRs)           │
│  ├─ Follow TDD patterns                                          │
│  └─ Save to correct directories                                 │
│                                                                   │
│  Phase 6: Checkpoint & Master Doc Drift                         │
│  ├─ Generate checkpoint document                                 │
│  ├─ Detect deviations from master pipeline design               │
│  ├─ Show diff of proposed master doc updates                    │
│  └─ Update PROJECT-STATUS.md                                    │
│                                                                   │
│  ──────────────── GATE 2: Human Approval ────────────────       │
│  └─ Review checkpoint → "approved" → Manual master doc update   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│              Apple Docs Fetcher (One-Time Setup)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. Analyze:                                                      │
│     ├─ docs/abundance-analysis-pipeline-design.md                │
│     ├─ docs/specs/PRD-*.md                                       │
│     └─ Identify ALL Apple technologies needed                    │
│                                                                   │
│  2. Fetch (developer.apple.com → sosumi.ai):                    │
│     ├─ Swift 6.x documentation                                   │
│     ├─ SwiftUI framework                                         │
│     ├─ Vision Framework                                          │
│     ├─ Visual Intelligence (iOS 26)                              │
│     ├─ Liquid Glass Design System (iOS 26)                       │
│     ├─ StoreKit / Apple Pay                                      │
│     ├─ Sign in with Apple / Keychain                             │
│     ├─ Core Data / CloudKit                                      │
│     ├─ AVFoundation (Camera)                                     │
│     └─ Security APIs                                             │
│                                                                   │
│  3. Save:                                                         │
│     ├─ docs/apple/{technology}/[docs].md                         │
│     ├─ docs/apple/{technology}/manifest.json                     │
│     └─ docs/apple/README.md                                      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Specifications

### 1. Apple Docs Fetcher

**Type**: Separate skill (one-time setup)
**Location**: `.claude/skills/apple-docs-fetcher/SKILL.md`
**Invocation**: `/apple-docs-fetcher` or `/apple-docs-fetcher --refresh`

#### Responsibilities

1. Analyze project scope to identify ALL Apple technologies needed
2. Fetch documentation from Sosumi.ai (markdown conversion of Apple docs)
3. Save to structured local cache: `docs/apple/{technology}/`
4. Generate manifests with fetch metadata
5. Create README with refresh instructions

#### Technology Mapping Logic

```
Input: docs/abundance-analysis-pipeline-design.md + docs/specs/*.md
Output: List of Apple technologies

Algorithm:
1. Extract iOS-related stages: 2.2, 3.1, 4.1
2. Extract features requiring Apple APIs:
   - AI Cataloging → Vision, Visual Intelligence, AVFoundation
   - UI/UX → SwiftUI, Liquid Glass
   - Payment → StoreKit, Apple Pay
   - Auth → Sign in with Apple, Keychain
   - Storage → Core Data, CloudKit
   - Security → Secure Enclave, Data Protection
3. Add base requirement: Swift 6.x language docs
4. Return comprehensive technology list
```

#### Output Structure

```
docs/apple/
├── README.md (refresh instructions, last fetch date)
├── swift/
│   ├── manifest.json
│   ├── swift-6-overview.md
│   ├── concurrency.md
│   └── ...
├── swiftui/
│   ├── manifest.json
│   ├── views-and-controls.md
│   ├── state-and-data-flow.md
│   └── ...
├── liquid-glass/
│   ├── manifest.json
│   └── design-system-ios26.md
├── vision/
│   ├── manifest.json
│   ├── object-detection.md
│   └── ...
├── visual-intelligence/
│   ├── manifest.json
│   └── ...
├── payment/
│   ├── manifest.json
│   ├── storekit.md
│   └── apple-pay.md
├── auth/
│   ├── manifest.json
│   ├── sign-in-with-apple.md
│   └── keychain.md
├── storage/
│   ├── manifest.json
│   ├── core-data.md
│   └── cloudkit.md
├── camera/
│   ├── manifest.json
│   └── avfoundation.md
└── security/
    ├── manifest.json
    ├── secure-enclave.md
    └── data-protection.md
```

#### Manifest Format

```json
{
  "technology": "swiftui",
  "fetched_date": "2025-11-02",
  "fetch_source": "sosumi.ai",
  "docs": [
    {
      "title": "SwiftUI Views and Controls",
      "original_url": "https://developer.apple.com/documentation/swiftui/views",
      "sosumi_url": "https://sosumi.ai/documentation/swiftui/views",
      "local_path": "views-and-controls.md",
      "fetch_date": "2025-11-02",
      "size_kb": 124
    }
  ]
}
```

#### README.md Template

```markdown
# Apple Developer Documentation (Local Cache)

**Last Updated**: 2025-11-02
**Fetch Source**: [Sosumi.ai](https://sosumi.ai) - Clean markdown conversion of Apple Developer docs
**Purpose**: Fast, accurate local reference for iOS stage development

## Technology Coverage

- ✅ Swift 6.x Language Documentation
- ✅ SwiftUI Framework
- ✅ Vision Framework (Object Detection, Image Analysis)
- ✅ Visual Intelligence (iOS 26 AI Features)
- ✅ Liquid Glass Design System (iOS 26 UI/UX)
- ✅ StoreKit / Apple Pay (Payment APIs)
- ✅ Sign in with Apple / Keychain (Authentication)
- ✅ Core Data / CloudKit (Storage)
- ✅ AVFoundation (Camera APIs)
- ✅ Security APIs (Secure Enclave, Data Protection)

## Refresh Documentation

### When to Refresh

Documentation is considered stale after **30 days**. The stage orchestrator will warn (but not block) if docs are older than 30 days.

### How to Refresh

**Option 1: Full Refresh (Recommended)**
```bash
/apple-docs-fetcher --refresh
```

**Option 2: Manual Refresh**
```bash
rm -rf docs/apple/
/apple-docs-fetcher
```

## Usage

These docs are automatically searched by the `verified-stage-development` skill when running iOS-related stages (2.2, 3.1, 4.1). The research verification agent uses `Grep` to search local markdown files instead of `WebFetch`, providing:

- ✅ Faster searches (local files vs. web requests)
- ✅ More accurate results (clean markdown vs. HTML parsing)
- ✅ Offline capability
- ✅ Cost savings (no repeated web fetches)

## Structure

Each technology has its own directory with:
- `manifest.json` - Metadata about fetched docs
- `*.md` - Markdown documentation files

The orchestrator skill knows to search these directories when verifying iOS/Swift technical claims.
```

---

### 2. Verified Stage Development Orchestrator

**Type**: Main orchestration skill
**Location**: `.claude/skills/verified-stage-development/SKILL.md`
**Aliases**: `stage-orchestrator`
**Invocation**: `/verified-stage-development stage-X.X [--force]`

#### Parameters

- `stage-number` (required): Stage identifier (e.g., `stage-2.2`, `stage-3.1`)
- `--force` (optional): Skip verification blocks and proceed with human override

#### Phase-by-Phase Specification

---

#### Phase 1: Context Collection

**Purpose**: Load all relevant documents with deterministic file list

**Algorithm**:

```
1. Determine stage number from invocation (e.g., "stage-2.2")
2. Check prerequisites:
   - If iOS stage (2.2, 3.1, 4.1) → verify docs/apple/ exists
   - If not first stage → verify previous PLAN-SUMMARY exists
3. Build explicit file list:
   - Master: docs/abundance-analysis-pipeline-design.md
   - Previous stage: docs/plans/PLAN-SUMMARY-stage-[X.Y-1].md
   - All ADRs: docs/adr/*.md (read all)
   - All designs: docs/design/*.md (read all)
   - All specs: docs/specs/*.md (read all)
   - Tech stack: docs/tech-stack/*.md (read all)
   - Roadmap: docs/roadmap/*.md (if exists)
   - Apple docs: docs/apple/ (if iOS stage)
4. Read all files into context
5. If any required file missing → ERROR with clear message
```

**Error Handling**:

- `docs/apple/` missing for iOS stage → ERROR: "Run /apple-docs-fetcher first before running iOS stages"
- Previous PLAN-SUMMARY missing → ERROR: "Complete Stage X.Y first"
- Other missing files → List files, ask human to resolve

**Output**: Complete context object passed to next phase

---

#### Phase 2: Research Hook (Sub-Agent Dispatch)

**Purpose**: Verify all technical claims against official documentation

**Sub-Agent Prompt**:

```markdown
You are a research verification agent for Stage X.X of the Abundance Analysis Pipeline.

## CONTEXT
[All files from Phase 1 loaded here]

## YOUR TASK

1. **Identify Technical Claims**
   Read the stage requirements from abundance-analysis-pipeline-design.md (Stage X.X section).
   Extract ALL technical claims that require verification:
   - Pricing (cost per request, monthly fees, storage costs)
   - Performance (latency, throughput, response times)
   - Capabilities (supported features, API availability, version requirements)
   - Limitations (rate limits, quotas, restrictions)

2. **Verify iOS/Apple Claims**
   For any claim involving Apple technologies:
   - Use Grep tool to search docs/apple/{technology}/*.md
   - Example: Grep pattern:"VNRecognizeObjects" path:"docs/apple/vision/"
   - Extract accurate information from local markdown files
   - Note: These docs are pre-fetched from developer.apple.com via sosumi.ai

3. **Verify GCP/Firebase/Other Claims**
   For non-Apple claims:
   - Use WebSearch to find official documentation
   - Use WebFetch to extract specific information
   - Prioritize official sources (cloud.google.com, firebase.google.com)

4. **Resolve Contradictions**
   If you find conflicting information:
   - Fetch latest documentation from official source
   - Document which source is authoritative and why
   - Update verification with resolved information

5. **Build Curated Source List**
   For this stage's specific technologies, compile list of official documentation URLs for future reference.

## OUTPUT FORMAT

Create: docs/validation/RESEARCH-VALIDATION-stage-X.X.md

Structure:
---
# Research Validation Report: Stage X.X

**Created**: [date]
**Stage**: [stage number and name]
**Technologies Verified**: [list]

## Executive Summary
[2-3 sentences: what was verified, sources used, any issues found]

## Verified Technical Claims

### Claim 1: [Statement from requirements]
- **Verification Status**: ✅ VERIFIED / ⚠️ PARTIALLY VERIFIED / ❌ CONTRADICTS
- **Actual Value**: [from official source]
- **Source**: [URL]
- **Notes**: [any important context]

### Claim 2: [Statement]
...

## Contradictions Resolved

### Issue 1: [Description]
- **Original Claim**: [what was stated]
- **Conflict**: [why it was wrong/outdated]
- **Resolution**: [accurate information]
- **Source**: [authoritative URL]

## Curated Sources for This Stage

### Apple/iOS Sources
- [Technology]: [sosumi.ai URL] (local: docs/apple/[path])
- ...

### GCP/Firebase Sources
- [Service]: [official URL]
- ...

## Warnings

[Any warnings about stale data, deprecated APIs, or uncertainty]

## Verification Summary

- Total claims verified: X
- Verified as accurate: X
- Updated/corrected: X
- Unable to verify: X
---
```

**Sub-Agent Dispatch**:
```
Task tool with:
- subagent_type: "general-purpose"
- description: "Research verification for stage X.X"
- prompt: [above prompt]
```

**Validation**: Check that `docs/validation/RESEARCH-VALIDATION-stage-X.X.md` was created successfully.

---

#### Phase 3: Planning (superpowers:write-plan)

**Purpose**: Create implementation plan with verified context

**Integration with write-plan**:

```
Invoke: SlashCommand tool with "/superpowers:write-plan"

Context passed to write-plan:
- All files from Phase 1
- Research validation report from Phase 2

Additional instructions injected:
---
MANDATORY REQUIREMENTS FOR THIS PLAN:

1. **Verified Claims Only**
   All pricing, performance, and capability claims MUST reference the research validation report.
   Format: "Firebase Storage costs $0.026/GB/month (ref: RESEARCH-VALIDATION-stage-X.X.md, Claim 3)"

2. **Apple Documentation**
   For iOS-related APIs, you have access to docs/apple/ directory with pre-fetched documentation.
   Use Grep to search these files for accurate API usage.
   Example: Grep pattern:"VNRecognizeObjects" path:"docs/apple/vision/"

3. **Real Libraries Only**
   All code examples MUST use libraries specified in TECH-STACK-MAP-001.
   Verify imports and package names are real and available.

4. **Test-Driven Development**
   For each feature implementation task, include:
   - Given/When/Then acceptance criteria
   - Example test case structure
   - Reference to TEST-STRATEGY-001 for test pyramid guidance

5. **Previous Stage Context**
   This plan builds on previous stages. Reference and maintain consistency with:
   - Previous stage: docs/plans/PLAN-SUMMARY-stage-[X.Y-1].md
   - Relevant ADRs: [list]
   - Relevant designs: [list]

6. **Master Pipeline Alignment**
   Your plan must accomplish the objectives defined in:
   docs/abundance-analysis-pipeline-design.md (Stage X.X section)

OUTPUT STRUCTURE:

docs/plans/[YYYY-MM-DD]-stage-X.X-[topic].md:
- Background & Context (links to previous artifacts)
- Objectives (from master pipeline design)
- Verified Technical Constraints (from research report)
- Implementation Tasks (detailed, with test examples)
- Acceptance Criteria (traceable to master design)
- Dependencies & Risks

docs/plans/PLAN-SUMMARY-stage-X.X.md:
- Concise summary (500-1000 words)
- Key decisions
- Next stage preview
- This becomes the master reference for this stage
---
```

**Output Validation**:
- Verify both files created
- Check PLAN-SUMMARY references research validation report
- Confirm alignment with master pipeline design (manual check)

---

#### Phase 4: Verification Hook (Sub-Agent Dispatch)

**Purpose**: Check plan quality, consistency, and compliance

**Sub-Agent Prompt**:

```markdown
You are a consistency verification agent for Stage X.X of the Abundance Analysis Pipeline.

## INPUTS

- **Plan**: docs/plans/[YYYY-MM-DD]-stage-X.X-[topic].md
- **Plan Summary**: docs/plans/PLAN-SUMMARY-stage-X.X.md
- **Master Pipeline**: docs/abundance-analysis-pipeline-design.md
- **Research Report**: docs/validation/RESEARCH-VALIDATION-stage-X.X.md
- **Previous Stage**: docs/plans/PLAN-SUMMARY-stage-[X.Y-1].md
- **All ADRs**: docs/adr/*.md
- **All Designs**: docs/design/*.md

## VERIFICATION CHECKS

### 1. Master Pipeline Alignment
Compare plan objectives against Stage X.X definition in abundance-analysis-pipeline-design.md:
- Does plan accomplish all stated objectives?
- Are all required outputs listed?
- Is the expert agent specification followed?
- Are any requirements missing or ignored?

Result: PASS / FAIL with specific issues

### 2. Code Example Validation
Scan plan for code snippets and imports:
- Extract all import statements and library references
- Cross-reference against TECH-STACK-MAP-001
- Flag any libraries not in approved tech stack
- Flag pseudocode or placeholder APIs

Result: List of code issues (or "All examples valid")

### 3. TDD Compliance
Check that implementation tasks include test-first approach:
- Are acceptance criteria defined in Given/When/Then format?
- Are test examples provided?
- Is testing strategy referenced?

Result: PASS / FAIL with specific tasks missing tests

### 4. Technical Claims Verification
Scan plan for pricing, latency, capability statements:
- Do claims reference RESEARCH-VALIDATION-stage-X.X.md?
- Are numbers cited with sources?
- Are there unsourced claims?

Result: List of unsourced claims (or "All claims verified")

### 5. Cross-Stage Consistency
Compare with previous stage artifacts:
- Are APIs/interfaces from previous stages honored?
- Are there contradictions with previous decisions?
- Are dependencies properly acknowledged?

Result: List of consistency issues (or "No conflicts found")

### 6. Dependency Completeness
Check that all required inputs are available:
- Previous stage PLAN-SUMMARY exists and referenced
- Required ADRs exist and referenced
- Required tech stack documents exist

Result: PASS / FAIL with missing dependencies

## OUTPUT FORMAT

Create: docs/validation/STAGE-X.X-CHECKLIST.md

Structure:
---
# Verification Checklist: Stage X.X

**Created**: [date]
**Plan**: docs/plans/[filename]
**Verification Agent**: Consistency Checker v1.0

## Overall Status

- ✅ PASS - All checks passed, safe to proceed
- ⚠️ WARNINGS - Issues found but not blocking
- ❌ FAIL - Critical issues, must fix before execution

## Detailed Results

### 1. Master Pipeline Alignment: [PASS/FAIL]
[Details of check]
- ✅ All objectives covered
- ❌ Missing requirement: [description]

### 2. Code Example Validation: [PASS/FAIL]
[Details]

### 3. TDD Compliance: [PASS/FAIL]
[Details]

### 4. Technical Claims Verification: [PASS/FAIL]
[Details]

### 5. Cross-Stage Consistency: [PASS/FAIL]
[Details]

### 6. Dependency Completeness: [PASS/FAIL]
[Details]

## Blocking Issues

[List of issues that MUST be fixed before execution]

## Warnings

[List of issues that should be addressed but aren't blocking]

## Recommendation

- ✅ APPROVED - Safe to proceed to execution phase
- ❌ BLOCKED - Fix issues above before proceeding
- ⚠️ PROCEED WITH CAUTION - Warnings noted, human should review
---
```

**Sub-Agent Dispatch**:
```
Task tool with:
- subagent_type: "general-purpose"
- description: "Consistency verification for stage X.X"
- prompt: [above prompt]
```

**Gate Logic**:
```
Read: docs/validation/STAGE-X.X-CHECKLIST.md

If status == "BLOCKED":
  Display: Verification report with blocking issues
  Prompt: "Verification failed. Type 'override' to proceed anyway, or fix issues and re-run."
  Wait for: "override" or "fix"

If status == "WARNINGS" or "PASS":
  Display: Verification report
  Prompt: "Verification complete. Type 'proceed to execute' to continue."
  Wait for: user approval

If user types "override":
  Log: Override recorded in checkpoint
  Continue to Phase 5

If user approves:
  Continue to Phase 5
```

---

#### GATE 1: Human Approval (Post-Verification)

**Display to Human**:
```
═══════════════════════════════════════════════════════════
STAGE X.X VERIFICATION COMPLETE
═══════════════════════════════════════════════════════════

Research Validation:
✅ docs/validation/RESEARCH-VALIDATION-stage-X.X.md
   - X claims verified
   - X contradictions resolved
   - X sources documented

Plan Created:
✅ docs/plans/PLAN-SUMMARY-stage-X.X.md
✅ docs/plans/[YYYY-MM-DD]-stage-X.X-[topic].md

Consistency Check:
[PASS/WARNINGS/FAIL] docs/validation/STAGE-X.X-CHECKLIST.md
   - [Summary of results]

[If BLOCKED]
⚠️  BLOCKING ISSUES FOUND:
   - [Issue 1]
   - [Issue 2]

═══════════════════════════════════════════════════════════
NEXT: Execute plan to create stage artifacts

Type 'proceed to execute' to continue
Type 'override' to bypass verification blocks
Type 'abort' to stop
═══════════════════════════════════════════════════════════
```

**Wait for human response**. Do not proceed until approved.

---

#### Phase 5: Execution (superpowers:execute-plan)

**Purpose**: Create all stage artifacts per the verified plan

**Integration with execute-plan**:

```
Invoke: SlashCommand tool with "/superpowers:execute-plan"

Context passed:
- Plan: docs/plans/[YYYY-MM-DD]-stage-X.X-[topic].md
- All context from Phase 1
- Research validation report
- Verification checklist

Additional instructions:
---
EXECUTION REQUIREMENTS:

1. Follow the verified plan exactly
2. Create all artifacts in correct locations:
   - Specs: docs/specs/
   - Designs: docs/design/
   - ADRs: docs/adr/
   - Tech stack: docs/tech-stack/
   - Test plans: docs/test/
3. Include document metadata headers:
   - Created: [date]
   - Stage: [stage number]
   - References: [list of related documents]
   - Status: [Draft/Review/Approved]
4. Cross-reference related artifacts in document body
5. Follow TDD pattern for all test examples
6. Use batch execution with review checkpoints per execute-plan skill
---
```

**Execution Monitoring**:
- Track which artifacts are created
- Log any errors or deviations
- Capture completion status

---

#### Phase 6: Checkpoint & Master Document Drift Detection

**Purpose**: Generate checkpoint, detect drift, update status

**Algorithm**:

```
1. Collect execution results:
   - List all artifacts created
   - Note any execution errors
   - Capture key decisions made

2. Detect master document drift:
   a. Read current stage definition from abundance-analysis-pipeline-design.md
   b. Compare with actual execution:
      - Were objectives achieved as defined?
      - Were outputs different than specified?
      - Did scope expand or contract?
      - Did architecture decisions deviate?
   c. If deviations detected:
      - Generate proposed changes to master document
      - Create diff showing current vs. proposed text
      - Document rationale for changes

3. Generate checkpoint document:
   Create: docs/checkpoints/CHECKPOINT-stage-X.X-[name].md
   [Use standard checkpoint format from pipeline design]

4. Update PROJECT-STATUS.md:
   - Mark Stage X.X as "✅ Complete - [date]"
   - Update progress tracker table
   - Add artifact links
   - Update "Next Steps" section

5. Present to human:
   - Show checkpoint summary
   - Show all artifacts created
   - If drift detected: show master document diff
   - Request approval
```

**Checkpoint Document Format**:

```markdown
# CHECKPOINT: Stage X.X - [Stage Name]

**Date**: 2025-11-02
**Status**: Awaiting Approval
**Plan**: docs/plans/PLAN-SUMMARY-stage-X.X.md

---

## Executive Summary

[3-5 sentences: what was accomplished, key findings, recommendation]

---

## Work Completed

- ✅ Research validation completed (X claims verified)
- ✅ Implementation plan created and verified
- ✅ [Major deliverable 1]
- ✅ [Major deliverable 2]
- ✅ [Major deliverable 3]

---

## Key Decisions Made

### Decision 1: [Decision Name]

**Rationale**: [2-3 sentences explaining why]
**Impact**: [What this enables or constrains]
**Documented in**: [ADR-XXX reference]

### Decision 2: [Decision Name]

**Rationale**: [...]
**Impact**: [...]
**Documented in**: [...]

---

## Artifacts Generated

**Specifications:**
- 📄 [docs/specs/XXX.md](../specs/XXX.md) - [One-line description]

**Design Documents:**
- 📄 [docs/design/DESIGN-XXX.md](../design/DESIGN-XXX.md) - [Description]

**Architecture Decision Records:**
- 📄 [docs/adr/ADR-XXX.md](../adr/ADR-XXX.md) - [Description]

**Validation Reports:**
- 📄 [docs/validation/RESEARCH-VALIDATION-stage-X.X.md](../validation/...) - Research verification
- 📄 [docs/validation/STAGE-X.X-CHECKLIST.md](../validation/...) - Consistency checks

**Plans:**
- 📄 [docs/plans/PLAN-SUMMARY-stage-X.X.md](../plans/...) - Master stage reference

---

## Master Pipeline Document Drift

[If no deviations detected:]
✅ **No drift detected** - Stage execution aligned perfectly with master pipeline design.

[If deviations detected:]
⚠️ **Deviations from master design detected**

The following aspects of stage execution differed from the original design in `docs/abundance-analysis-pipeline-design.md`:

### Deviation 1: [Description]

**Original Design Said:**
```
[Quote from master document]
```

**Actual Execution:**
```
[What actually happened]
```

**Rationale for Change:**
[Why this deviation occurred]

**Proposed Master Document Update:**
```diff
- [Original text]
+ [Proposed updated text]
```

### Deviation 2: [...]

**Recommendation**: Review proposed changes above. If approved, manually update `docs/abundance-analysis-pipeline-design.md` with the proposed text.

---

## Risks & Concerns Identified

⚠️ **[Risk 1: Risk Name]**
- **Description**: [What could go wrong]
- **Impact**: High/Medium/Low
- **Probability**: High/Medium/Low
- **Mitigation**: [Proposed approach]

⚠️ **[Risk 2: Risk Name]**
- [...]

---

## Dependencies for Next Stage

The next stage ([X.Y+1 - Stage Name]) requires:

- ✅ [PLAN-SUMMARY-stage-X.X.md - Complete]
- ✅ [ADR-XXX - Complete]
- ✅ [DESIGN-XXX - Complete]
- ⏳ [Item waiting on external factor]

---

## Next Stage Preview

**Stage [X.Y+1]**: [Stage Name]

- **Expert Agent**: [Name and domain]
- **Will accomplish**: [1-2 sentences]
- **Will produce**: [Key outputs]
- **Prerequisites**: [This checkpoint approval + any other items]

---

## Required Human Action

Please review this checkpoint and:

- [ ] Review all artifacts generated (links above)
- [ ] Review key decisions made
- [ ] Review and acknowledge risks
- [ ] If drift detected: Review proposed master document changes
- [ ] **Provide approval to proceed**

### How to Respond

- **"Approved - proceed to Stage X.Y+1"** - Mark stage complete, ready for next stage
- **"Approved with changes: [details]"** - Make changes, regenerate checkpoint
- **"Request revision: [what needs to change]"** - Fix issues, re-run verification

### If Master Document Changes Proposed

After approval, manually update `docs/abundance-analysis-pipeline-design.md`:
1. Open the master document
2. Find the Stage X.X section
3. Apply the proposed changes shown in "Master Pipeline Document Drift" section above
4. Commit changes with message: "docs: Update Stage X.X definition based on execution (CHECKPOINT-stage-X.X)"

---

**Generated by**: verified-stage-development orchestrator
**Verification Status**: [VERIFIED / WARNINGS / OVERRIDDEN]
```

---

#### GATE 2: Human Approval (Post-Checkpoint)

**Display to Human**:

```
═══════════════════════════════════════════════════════════
STAGE X.X EXECUTION COMPLETE
═══════════════════════════════════════════════════════════

Checkpoint Generated:
📋 docs/checkpoints/CHECKPOINT-stage-X.X-[name].md

Artifacts Created: [X total]
✅ [X] Specifications
✅ [X] Design Documents
✅ [X] ADRs
✅ [X] Validation Reports

[If drift detected]
⚠️  MASTER DOCUMENT DRIFT DETECTED
    Proposed changes to abundance-analysis-pipeline-design.md
    Review checkpoint for details and proposed updates

PROJECT-STATUS.md Updated:
✅ Stage X.X marked complete
✅ Progress tracker updated
✅ Next steps updated

═══════════════════════════════════════════════════════════
NEXT: Review checkpoint and approve to continue

Type 'approved - proceed to Stage X.Y+1' to complete
Type 'approved with changes: [details]' to revise
═══════════════════════════════════════════════════════════
```

**Wait for human approval**.

**On Approval**:
```
1. If drift detected and human approved:
   - Display: "Please manually update abundance-analysis-pipeline-design.md with proposed changes from checkpoint."
   - Wait: For human to confirm update complete

2. Mark stage complete:
   - Final update to PROJECT-STATUS.md with approval timestamp

3. Skill exits successfully with message:
   "Stage X.X complete. Ready to run: /verified-stage-development stage-[X.Y+1]"
```

---

## Workflow Details

### Complete Flow Diagram

```
┌──────────────────────────────────────────────────────────┐
│ Human: /verified-stage-development stage-2.2             │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│ Phase 1: Context Collection                              │
│ • Read master pipeline design                            │
│ • Read previous stage PLAN-SUMMARY                       │
│ • Read all ADRs, designs, specs                          │
│ • Check docs/apple/ exists (if iOS stage)                │
│ • Build complete context object                          │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│ Phase 2: Research Hook (Sub-Agent)                      │
│ • Identify technical claims from stage requirements      │
│ • Search docs/apple/ for iOS claims (Grep)               │
│ • WebSearch + WebFetch for GCP/Firebase claims           │
│ • Resolve contradictions automatically                    │
│ • Output: RESEARCH-VALIDATION-stage-X.X.md               │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│ Phase 3: Planning (superpowers:write-plan)              │
│ • Pass verified context + research report                │
│ • Enforce real library usage                             │
│ • Require TDD patterns                                   │
│ • Output: PLAN-SUMMARY-stage-X.X.md                      │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│ Phase 4: Verification Hook (Sub-Agent)                  │
│ • Check master pipeline alignment                        │
│ • Validate code examples (real libraries)                │
│ • Check TDD compliance                                   │
│ • Verify cross-stage consistency                         │
│ • Output: STAGE-X.X-CHECKLIST.md                         │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│                  🚧 GATE 1: HUMAN APPROVAL 🚧            │
│                                                           │
│ Display: Verification reports (research + consistency)   │
│ Status: [PASS / WARNINGS / BLOCKED]                      │
│                                                           │
│ Wait for: "proceed to execute" or "override"             │
└────────────────────┬─────────────────────────────────────┘
                     │ [Human approves]
                     ▼
┌──────────────────────────────────────────────────────────┐
│ Phase 5: Execution (superpowers:execute-plan)           │
│ • Create all stage artifacts                             │
│ • Follow verified plan                                   │
│ • Use TDD patterns                                       │
│ • Save to correct directories                            │
│ • Outputs: specs, designs, ADRs, tests, etc.            │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│ Phase 6: Checkpoint & Drift Detection                   │
│ • Collect execution results                              │
│ • Detect deviations from master design                   │
│ • Generate diff of proposed master doc updates           │
│ • Create checkpoint document                             │
│ • Update PROJECT-STATUS.md                               │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│                  🚧 GATE 2: HUMAN APPROVAL 🚧            │
│                                                           │
│ Display: Checkpoint + artifacts + drift (if any)         │
│                                                           │
│ If drift: Show proposed master doc changes               │
│                                                           │
│ Wait for: "approved - proceed to Stage X.Y+1"            │
└────────────────────┬─────────────────────────────────────┘
                     │ [Human approves]
                     ▼
┌──────────────────────────────────────────────────────────┐
│ Completion                                                │
│ • Mark stage complete in PROJECT-STATUS.md               │
│ • If drift: Remind human to update master doc manually   │
│ • Exit successfully                                       │
│ • Ready for next stage                                   │
└──────────────────────────────────────────────────────────┘
```

### Context Flow Through Phases

```
Phase 1 Output (Context Object):
├─ master_design: abundance-analysis-pipeline-design.md content
├─ previous_stage: PLAN-SUMMARY-stage-[X.Y-1].md content
├─ adrs: [list of all ADR contents]
├─ designs: [list of all DESIGN contents]
├─ specs: [list of all spec contents]
├─ tech_stack: [list of tech stack contents]
├─ apple_docs_path: "docs/apple/" (if iOS stage)
└─ stage_number: "X.X"

Phase 2 Output (Research Report):
├─ verified_claims: [list of claims with sources]
├─ contradictions_resolved: [list]
├─ curated_sources: [list of official URLs]
└─ file: RESEARCH-VALIDATION-stage-X.X.md

Phase 3 Input:
├─ Context Object from Phase 1
├─ Research Report from Phase 2
└─ write-plan instructions

Phase 3 Output:
├─ detailed_plan: [YYYY-MM-DD]-stage-X.X-[topic].md
└─ summary: PLAN-SUMMARY-stage-X.X.md

Phase 4 Input:
├─ Context Object from Phase 1
├─ Research Report from Phase 2
├─ Plans from Phase 3
└─ verification-agent prompt

Phase 4 Output:
├─ checklist: STAGE-X.X-CHECKLIST.md
└─ status: PASS / WARNINGS / BLOCKED

GATE 1: Human reviews Phase 2 + Phase 4 outputs

Phase 5 Input:
├─ All previous context
├─ Plans from Phase 3
└─ execute-plan instructions

Phase 5 Output:
├─ artifacts: [list of created files]
└─ execution_log: [what was done]

Phase 6 Input:
├─ All previous context
├─ Execution results from Phase 5
└─ Master design for comparison

Phase 6 Output:
├─ checkpoint: CHECKPOINT-stage-X.X.md
├─ drift_detected: true/false
├─ proposed_changes: [diff] (if drift)
└─ updated_status: PROJECT-STATUS.md

GATE 2: Human reviews Phase 6 outputs + approves
```

---

## Error Handling

### Prerequisite Errors

| Error Condition | Message | Resolution |
|-----------------|---------|------------|
| docs/apple/ missing (iOS stage) | "ERROR: Apple documentation not found. Run `/apple-docs-fetcher` before executing iOS stages (2.2, 3.1, 4.1)." | Run apple-docs-fetcher |
| Previous PLAN-SUMMARY missing | "ERROR: Previous stage not complete. Cannot find `docs/plans/PLAN-SUMMARY-stage-[X.Y-1].md`. Complete Stage [X.Y-1] first." | Complete previous stage |
| Master design missing | "ERROR: Master pipeline design not found at `docs/abundance-analysis-pipeline-design.md`. This file is required." | Restore master design file |
| Required ADR/design missing | "WARNING: Referenced document not found: [filename]. Continuing with available context, but plan may be incomplete." | Human decides: continue or fix |

### Research Hook Errors

| Error Condition | Handling | Resolution |
|-----------------|----------|------------|
| Contradictory pricing found | Agent resolves automatically by fetching latest official source. Documents resolution in report. | No human action required |
| Cannot verify claim (source unavailable) | Mark as "⚠️ UNABLE TO VERIFY" in report. Continue. | Human reviews in Gate 1 |
| Apple docs stale (>30 days) | Warning in checkpoint. Not blocking. | Human can refresh later |
| WebSearch/WebFetch fails | Retry once. If fails again, mark claim as unverified. Continue. | Human reviews in Gate 1 |
| Sub-agent timeout | Error displayed. Offer retry. | Human: retry or abort |

### Verification Hook Errors

| Error Condition | Handling | Gate 1 Behavior |
|-----------------|----------|-----------------|
| Fake library detected | Status: BLOCKED. List issues. | Human can override or fix |
| Missing TDD compliance | Status: BLOCKED. List issues. | Human can override or fix |
| Consistency conflicts | Status: BLOCKED. List conflicts. | Human can override or fix |
| Unsourced technical claims | Status: WARNINGS. Not blocking. | Human reviews and approves |
| Missing dependency | Status: BLOCKED. List missing files. | Must fix (no override) |
| Sub-agent timeout | Error displayed. Offer retry. | Human: retry or abort |

### Planning/Execution Errors

| Error Condition | Handling | Resolution |
|-----------------|----------|------------|
| write-plan fails | Display error. Offer retry with adjusted context. | Human: retry or abort |
| execute-plan fails mid-execution | Checkpoint partial progress. Log error. | Human: resume or abort |
| Artifact creation fails | Log error. Continue with other artifacts. Note in checkpoint. | Human reviews in Gate 2 |
| File write permission error | Error displayed. Check permissions. | Fix permissions, retry |

### Human Override

| Scenario | Command | Behavior |
|----------|---------|----------|
| Verification BLOCKED, want to proceed anyway | Type: `"override"` at Gate 1 | Logs override in checkpoint with timestamp. Proceeds to Phase 5. Checkpoint includes override notice. |
| Want to abort at any gate | Type: `"abort"` | Skill exits. Progress saved up to current phase. Can resume manually. |
| Want to revise plan after Gate 1 | Type: `"revise plan"` | Skill re-invokes write-plan with feedback. Returns to Gate 1. |

### Stale Documentation Warning

```
Apple docs age check (manifest.json):
- If < 30 days: No warning
- If 30-90 days: ⚠️ Warning in checkpoint
- If > 90 days: ⚠️⚠️ Strong warning in checkpoint

Warning format in checkpoint:
"⚠️ Apple documentation is X days old (fetched: YYYY-MM-DD).
Consider refreshing: /apple-docs-fetcher --refresh"

Note: This is informational only, not blocking.
```

---

## Usage Examples

### Example 1: Running Stage 2.2 (iOS Architecture)

```bash
# One-time setup (before first iOS stage)
$ /apple-docs-fetcher
Analyzing project scope...
Identified Apple technologies: Swift 6, SwiftUI, Vision, Visual Intelligence, Liquid Glass, StoreKit, Keychain, Core Data, AVFoundation, Security
Fetching from Sosumi.ai...
✅ docs/apple/swift/ (12 documents)
✅ docs/apple/swiftui/ (18 documents)
✅ docs/apple/vision/ (8 documents)
✅ docs/apple/visual-intelligence/ (4 documents)
✅ docs/apple/liquid-glass/ (3 documents)
✅ docs/apple/payment/ (6 documents)
✅ docs/apple/auth/ (5 documents)
✅ docs/apple/storage/ (7 documents)
✅ docs/apple/camera/ (6 documents)
✅ docs/apple/security/ (9 documents)
✅ docs/apple/README.md created

Apple documentation fetched successfully. Total: 78 documents.

# Run stage 2.2
$ /verified-stage-development stage-2.2

Phase 1: Context Collection
✅ Read: docs/abundance-analysis-pipeline-design.md
✅ Read: docs/plans/PLAN-SUMMARY-stage-2.1.md
✅ Read: 4 ADRs from docs/adr/
✅ Read: 3 designs from docs/design/
✅ Read: 2 specs from docs/specs/
✅ Read: 1 tech stack doc from docs/tech-stack/
✅ Verified: docs/apple/ exists

Phase 2: Research Hook (launching sub-agent)
Verifying technical claims for Stage 2.2...
- Searching docs/apple/swift/ for Swift 6 concurrency features
- Searching docs/apple/swiftui/ for architecture patterns
- Searching docs/apple/vision/ for VNRecognizeObjects capabilities
- WebSearch: Firebase iOS SDK pricing and features
✅ Created: docs/validation/RESEARCH-VALIDATION-stage-2.2.md
   - 14 claims verified
   - 2 contradictions resolved
   - 12 sources documented

Phase 3: Planning (invoking superpowers:write-plan)
Creating implementation plan...
✅ Created: docs/plans/2025-11-02-stage-2.2-ios-architecture.md
✅ Created: docs/plans/PLAN-SUMMARY-stage-2.2.md

Phase 4: Verification Hook (launching sub-agent)
Running consistency checks...
✅ Master pipeline alignment: PASS
✅ Code example validation: PASS (all libraries in tech stack)
✅ TDD compliance: PASS
✅ Technical claims: PASS (all sourced)
✅ Cross-stage consistency: PASS
✅ Dependencies: PASS
✅ Created: docs/validation/STAGE-2.2-CHECKLIST.md

═══════════════════════════════════════════════════════════
STAGE 2.2 VERIFICATION COMPLETE
═══════════════════════════════════════════════════════════

Research Validation:
✅ docs/validation/RESEARCH-VALIDATION-stage-2.2.md
   - 14 claims verified
   - 2 contradictions resolved (Firebase Auth pricing updated)
   - 12 sources documented

Plan Created:
✅ docs/plans/PLAN-SUMMARY-stage-2.2.md
✅ docs/plans/2025-11-02-stage-2.2-ios-architecture.md

Consistency Check:
✅ PASS - docs/validation/STAGE-2.2-CHECKLIST.md
   - All checks passed
   - No blocking issues

═══════════════════════════════════════════════════════════
NEXT: Execute plan to create stage artifacts

Type 'proceed to execute' to continue
═══════════════════════════════════════════════════════════

# Human reviews reports, then:
$ proceed to execute

Phase 5: Execution (invoking superpowers:execute-plan)
Executing plan...
✅ Created: docs/design/DESIGN-002-ios-client-architecture.md
✅ Created: docs/adr/ADR-008-swiftui-architecture-pattern.md
✅ Created: docs/adr/ADR-009-state-management-approach.md
✅ Created: docs/adr/ADR-010-dependency-injection-strategy.md
✅ Created: docs/design/MODULE-STRUCTURE-001-ios-modules.md
✅ Created: docs/design/INTEGRATION-SPEC-001-firebase-sdk.md

Phase 6: Checkpoint & Drift Detection
Generating checkpoint...
Detecting drift from master design...
⚠️ Drift detected: Architecture pattern chosen (MVVM) differs from "TBD" in master design
✅ Created: docs/checkpoints/CHECKPOINT-stage-2.2-ios-architecture.md
✅ Updated: PROJECT-STATUS.md

═══════════════════════════════════════════════════════════
STAGE 2.2 EXECUTION COMPLETE
═══════════════════════════════════════════════════════════

Checkpoint Generated:
📋 docs/checkpoints/CHECKPOINT-stage-2.2-ios-architecture.md

Artifacts Created: 8 total
✅ 2 Design Documents
✅ 3 ADRs
✅ 2 Validation Reports
✅ 1 Plan Summary

⚠️  MASTER DOCUMENT DRIFT DETECTED
    Stage 2.2 selected MVVM architecture pattern.
    Master design had this marked as "TBD by iOS expert in 2.2"

    Proposed update: Replace "TBD" with "MVVM (see ADR-008)"
    See checkpoint for full diff and rationale.

PROJECT-STATUS.md Updated:
✅ Stage 2.2 marked complete
✅ Progress tracker updated
✅ Next steps updated to Stage 2.3

═══════════════════════════════════════════════════════════
NEXT: Review checkpoint and approve to continue

Type 'approved - proceed to Stage 2.3' to complete
═══════════════════════════════════════════════════════════

# Human reviews checkpoint, then:
$ approved - proceed to Stage 2.3

Please manually update docs/abundance-analysis-pipeline-design.md:
- Line 483: Replace "Architecture Pattern: [TBD by iOS expert in 2.2]"
  With: "Architecture Pattern: MVVM (see ADR-008)"

Have you updated the master document? Type 'yes' to confirm.

# Human updates file, then:
$ yes

✅ Stage 2.2 complete.
✅ PROJECT-STATUS.md finalized.

Ready to run: /verified-stage-development stage-2.3
```

---

### Example 2: Override After Verification Block

```bash
$ /verified-stage-development stage-3.1

Phase 1: Context Collection
✅ [... context loaded ...]

Phase 2: Research Hook
✅ Created: docs/validation/RESEARCH-VALIDATION-stage-3.1.md

Phase 3: Planning
✅ Created: docs/plans/PLAN-SUMMARY-stage-3.1.md

Phase 4: Verification Hook
⚠️ Issues found during verification
❌ Created: docs/validation/STAGE-3.1-CHECKLIST.md (STATUS: BLOCKED)

═══════════════════════════════════════════════════════════
STAGE 3.1 VERIFICATION COMPLETE
═══════════════════════════════════════════════════════════

Research Validation:
✅ docs/validation/RESEARCH-VALIDATION-stage-3.1.md

Plan Created:
✅ docs/plans/PLAN-SUMMARY-stage-3.1.md

Consistency Check:
❌ BLOCKED - docs/validation/STAGE-3.1-CHECKLIST.md

   BLOCKING ISSUES:
   1. Code example on line 156 uses library "FakeNetworking"
      not found in TECH-STACK-MAP-001
   2. Implementation task "Camera Integration" missing test examples

═══════════════════════════════════════════════════════════
OPTIONS:
- Type 'override' to proceed despite verification failures
- Fix issues and run verification again
- Type 'abort' to stop
═══════════════════════════════════════════════════════════

# Human decides to proceed anyway:
$ override

⚠️  Override acknowledged. Proceeding to execution.
    Verification failures will be noted in checkpoint.

Phase 5: Execution
✅ [... artifacts created ...]

Phase 6: Checkpoint
✅ Created: docs/checkpoints/CHECKPOINT-stage-3.1.md

[Checkpoint includes:]
"⚠️ WARNING: Verification failed but human override applied.
    Issues logged:
    1. Fake library "FakeNetworking" in plan
    2. Missing TDD examples for Camera Integration

    These issues should be addressed before implementation."

[... rest of checkpoint flow ...]
```

---

### Example 3: Refreshing Stale Apple Docs

```bash
$ /verified-stage-development stage-4.1

Phase 1: Context Collection
✅ Read: docs/abundance-analysis-pipeline-design.md
⚠️ Warning: Apple docs are 45 days old (fetched: 2025-09-18)
   Consider refreshing: /apple-docs-fetcher --refresh
✅ Read: docs/apple/ (continuing with existing docs)
[... continues normally ...]

# Later, human decides to refresh:
$ /apple-docs-fetcher --refresh

Checking for updates to Apple documentation...
Re-fetching from Sosumi.ai...
✅ docs/apple/swift/ updated (2 new documents, 3 updated)
✅ docs/apple/swiftui/ updated (1 new document, 5 updated)
✅ docs/apple/vision/ updated (1 updated)
[... etc ...]

Apple documentation refreshed successfully.
Fetch date updated to: 2025-11-02
```

---

## Phased Implementation Plan

### Full Feature Set vs. Phase 1 Implementation

This design document describes the **complete vision** for verified stage development with all quality gates and verification layers. However, we will implement in phases to reduce risk and prove value incrementally.

---

### Phase 1: Core Orchestration with Research Verification (IMPLEMENT FIRST)

**Scope**: Minimum viable orchestration with proven value

**Features Included**:
- ✅ Apple Docs Fetcher (one-time setup)
- ✅ Context Collection (explicit file list)
- ✅ Research Verification Hook (sub-agent)
- ✅ Planning Integration (superpowers:write-plan)
- ✅ Two-Gate Approval Flow (post-research, post-checkpoint)
- ✅ Checkpoint Generation
- ✅ Master Document Drift Detection (manual application)
- ✅ PROJECT-STATUS.md updates
- ✅ Error handling and prerequisites

**Features EXCLUDED from Phase 1**:
- ❌ Verification Hook (code validation, TDD enforcement, consistency checks)
- ❌ Auto-update of master document (show diff only, human applies)
- ❌ Advanced error recovery
- ❌ Dry-run mode
- ❌ Structured JSON verification output

**Rationale**:
- Research verification solves the biggest pain point (hallucinated numbers)
- Apple docs fetching provides immediate speed/accuracy gains
- Two approval gates give human control
- Simpler implementation = faster delivery, easier debugging
- Proves value before adding complexity

**Gate 1 Simplified** (Phase 1):
```
After Planning:
- Display research validation report
- Display plan summary
- Wait for: "proceed to execute"
- No verification sub-agent (that's Phase 2)
```

**Gate 2 Unchanged**:
```
After Execution:
- Display checkpoint
- Show drift diff (manual application)
- Wait for: "approved - proceed to Stage X.Y+1"
```

**Phase 1 Workflow**:
```
Phase 1: Context Collection
  └─ Explicit file list, verify prerequisites

Phase 2: Research Hook (Sub-Agent)
  └─ Verify technical claims, output report

Phase 3: Planning (write-plan)
  └─ Create plan with verified context

──────── GATE 1: Human Approval ────────
  └─ Review research + plan

Phase 4: Execution (execute-plan)
  └─ Create artifacts

Phase 5: Checkpoint & Drift Detection
  └─ Generate checkpoint, show diff

──────── GATE 2: Human Approval ────────
  └─ Review checkpoint, manually update master doc
```

---

### Phase 2: Add Verification Hook (FUTURE)

**Additions**:
- ✅ Verification sub-agent (consistency, code validation, TDD)
- ✅ Enhanced Gate 1 with verification checklist
- ✅ Override mechanism with logging

**When to implement**: After Phase 1 proves stable and valuable

---

### Phase 3: Advanced Features (FUTURE)

**Additions**:
- ✅ Dry-run mode
- ✅ Structured JSON verification output
- ✅ Advanced error recovery (resume from failure)
- ✅ Telemetry and debugging logs

**When to implement**: After Phase 2 shows verification is reliable

---

### Implementation Priority

```
┌────────────────────────────────────────────────────────┐
│ Phase 1: Core Orchestration (IMPLEMENT NOW)           │
│                                                         │
│ Week 1: Apple Docs Fetcher                            │
│ - Skill implementation                                 │
│ - Test on real project                                 │
│ - Validate Sosumi.ai integration                       │
│                                                         │
│ Week 2: Research Hook + Context Collection            │
│ - Context collection logic                             │
│ - Research sub-agent prompt                            │
│ - Test on Stage 2.2                                    │
│                                                         │
│ Week 3: Planning Integration + Gate 1                 │
│ - write-plan integration                               │
│ - Gate 1 approval flow                                 │
│ - Test end-to-end through Gate 1                       │
│                                                         │
│ Week 4: Execution + Checkpoint + Gate 2               │
│ - execute-plan integration                             │
│ - Checkpoint generation                                │
│ - Drift detection (manual)                             │
│ - Gate 2 approval flow                                 │
│ - Full end-to-end test                                 │
│                                                         │
│ Week 5: Error Handling + Documentation                │
│ - Comprehensive error handling                         │
│ - Skill documentation                                  │
│ - Usage examples                                       │
│ - PROJECT-STATUS integration                           │
└────────────────────────────────────────────────────────┘

Validate Phase 1 with real stages (2.2, 2.3, 2.4)
Gather feedback, refine
Then consider Phase 2
```

---

## Success Metrics

### Phase 1 Success Criteria

**Determinism**:
- [ ] Same stage invocation loads same file list 100% of time
- [ ] Context collection never misses required files
- [ ] No variance in prerequisite checks

**Research Verification**:
- [ ] 95%+ of technical claims get verified with sources
- [ ] Contradictions resolved automatically in >80% of cases
- [ ] Apple docs search faster than WebFetch by >3x

**Quality Gates**:
- [ ] Both gates always pause and wait for human approval
- [ ] No stage proceeds without explicit human command
- [ ] Override mechanism works and logs correctly

**Documentation Integrity**:
- [ ] Drift detection catches 100% of intentional deviations (test with known changes)
- [ ] Diff shows accurate proposed changes
- [ ] PROJECT-STATUS.md stays in sync

**Usability**:
- [ ] Human can complete stage 2.2 end-to-end with skill
- [ ] Checkpoint documents contain all expected information
- [ ] Error messages are clear and actionable

**Performance**:
- [ ] Context collection: <10 seconds
- [ ] Research hook: <3 minutes (vs. 10+ minutes with repeated WebFetch)
- [ ] Total stage time: <30 minutes for average stage

---

### Phase 2 Success Criteria (Future)

**Verification Quality**:
- [ ] Catches 90%+ of fake library usage
- [ ] Catches 80%+ of missing TDD examples
- [ ] False positive rate <10%

---

## Open Questions

### For Phase 1 Implementation

1. **Apple Docs Fetcher**:
   - Q: Should we fetch all docs upfront, or lazy-load per stage?
   - A (Design Decision): Fetch all upfront. One-time cost, faster stages.

2. **Research Sub-Agent Reliability**:
   - Q: What if research agent misses a claim or provides wrong info?
   - A (Risk Acceptance): Human reviews at Gate 1. Not 100% automated verification, human is final check.

3. **Master Doc Drift Accuracy**:
   - Q: How reliably can we detect "deviations" programmatically?
   - A (Design Decision): Best-effort detection. Show diff, human decides if it's significant.

4. **Context Collection Size**:
   - Q: Reading all ADRs/designs/specs could be 100+ files for later stages. Token limits?
   - A (Monitor): Track token usage. If becomes issue, implement selective loading in Phase 2.

5. **Gate Timeout**:
   - Q: What if human walks away and doesn't respond at gate?
   - A (Design Decision): Skill waits indefinitely. Human can abort and resume later.

---

### For Future Phases

6. **Verification Sub-Agent** (Phase 2):
   - Q: Can sub-agent reliably parse code and validate libraries?
   - A: TBD - will test in Phase 2 prototype

7. **Structured Verification Output** (Phase 3):
   - Q: JSON output vs. markdown? Tooling compatibility?
   - A: TBD - depends on debugging needs in Phase 1-2

8. **Resume from Failure** (Phase 3):
   - Q: How to checkpoint mid-stage and resume?
   - A: TBD - depends on failure modes discovered in Phase 1

---

## Appendix A: File Locations Summary

### Created by Apple Docs Fetcher

```
docs/apple/
├── README.md
├── swift/
│   ├── manifest.json
│   └── *.md
├── swiftui/
│   ├── manifest.json
│   └── *.md
└── [8 more technology directories]
```

### Created by Verified Stage Development (per stage)

```
docs/validation/
├── RESEARCH-VALIDATION-stage-X.X.md
└── STAGE-X.X-CHECKLIST.md (Phase 2+)

docs/plans/
├── YYYY-MM-DD-stage-X.X-[topic].md
└── PLAN-SUMMARY-stage-X.X.md

docs/checkpoints/
└── CHECKPOINT-stage-X.X-[name].md

docs/specs/ (via execute-plan)
docs/design/ (via execute-plan)
docs/adr/ (via execute-plan)
docs/test/ (via execute-plan)
docs/tech-stack/ (via execute-plan)

PROJECT-STATUS.md (updated)
```

---

## Appendix B: Skill File Structure

### Recommended Repository Structure

```
.claude/skills/
├── apple-docs-fetcher/
│   └── SKILL.md (Apple docs fetching skill)
│
└── verified-stage-development/
    ├── SKILL.md (main orchestrator - Phase 1)
    └── README.md (usage instructions)
```

### Skill Metadata

**apple-docs-fetcher/SKILL.md**:
```markdown
---
name: apple-docs-fetcher
description: One-time setup to fetch Apple Developer documentation via Sosumi.ai for fast local reference
---
[Implementation details...]
```

**verified-stage-development/SKILL.md**:
```markdown
---
name: verified-stage-development
aliases: [stage-orchestrator]
description: Orchestrates deterministic stage development with research verification, planning, execution, and approval gates
---
[Implementation details - Phase 1 scope]
```

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-02 | 1.0 | Initial design - Full vision documented, Phase 1 implementation scoped | Claude Code (Brainstorming Session) |

---

**End of Design Document**

# Bug Filing and Triage Workflow

**Created**: 2025-12-11
**Status**: Active
**References**: DEV-ITERATION-SYSTEM-001

---

## Overview

This document describes the complete workflow for capturing, triaging, and resolving bugs in the Abundance project. The workflow ensures consistent bug tracking, prevents file naming collisions, and integrates with AI-powered triage and dispatch agents.

---

## Directory Structure

```
.debug/issues/
├── raw/                    # Newly captured, unprocessed issues
│   └── issue-NNN.md       # Raw issue capture
├── enriched/              # Auto-generated context
│   └── enriched-NNN.json  # Pre-fetched specs, logs, Apple docs
├── triaged/               # Processed by AI triage agent
│   ├── issue-NNN.md       # Original issue (moved here)
│   └── issue-NNN.json     # Metadata for dispatch
├── in-progress/           # Currently being worked on
│   └── issue-NNN.md       # Issue assigned to agent
└── .next-issue-number     # Persistent counter (prevents collisions)

.debug/completed/
├── issues/                # Resolved issues
│   ├── issue-NNN.md       # Resolved issue doc
│   └── issue-NNN.json     # Metadata
└── logs/                  # Completed enrichment logs

docs/bugs/                  # Final specification documents
├── BUG-NNN-description.md      # Bug specifications
├── BLOCKER-NNN-description.md  # Urgent blockers
└── PERF-NNN-description.md     # Performance issues

docs/refinements/           # UX improvements
└── REF-NNN-description.md  # UX refinement specs
```

---

## Issue Types

| Type | Description | Output Location | Priority |
|------|-------------|-----------------|----------|
| `blocker` | Urgent showstopper, blocks development/testing | `docs/bugs/BLOCKER-NNN-*.md` | P0 (Immediate) |
| `bug` | Code is broken, produces errors | `docs/bugs/BUG-NNN-*.md` | P1-P2 |
| `silent-failure` | No error but doesn't work | `docs/bugs/BUG-NNN-*.md` | P1-P2 |
| `performance` | Too slow, violates specs | `docs/bugs/PERF-NNN-*.md` | P2 |
| `ux-issue` | Works but UX is poor | `docs/refinements/REF-NNN-*.md` | P3 |
| `spec-drift` | Implementation doesn't match spec | Update existing spec | P2 |

---

## Workflow Steps

### Step 1: Capture an Issue

When you encounter a problem during testing, tell Claude:
- "capture this issue"
- "file a bug"
- "log this problem"

Claude uses the `capture-issue` skill (`.claude/skills/capture-issue/SKILL.md`) which handles everything in-session:

**Information gathered**:
1. What did you expect to happen?
2. What actually happened?
3. Which screen/feature?
4. Issue type:
   - Bug
   - UX Issue
   - Spec Drift
   - Silent Failure
   - Performance
   - **BLOCKER** (urgent showstopper)
5. Related spec document (optional)

**For BLOCKERS**, additional questions:
- What is this blocking? (testing/deployment/development)
- Impact level (1-10)

**Output**: `.debug/issues/raw/issue-NNN.md`

> **Note**: The old `capture-issue.sh` script is deprecated. Use the skill instead for unified capture + enrichment in a single session.

### Step 1.5: Auto-Enrichment (In-Session)

The `capture-issue` skill automatically enriches the issue in the same session:

**What happens**:
1. Validates spec path (resolves `mvp-vision-features` → `docs/specs/mvp-vision-features.md`)
2. Parses FULL log file (not just 50 lines) - extracts errors, warnings, stack traces
3. Detects iOS frameworks from keywords and file paths
4. Fetches Apple documentation (if iOS detected) - 3-5 relevant APIs
5. Identifies affected files from logs and stack traces
6. Provides preliminary classification with confidence score

**Output**: `.debug/issues/enriched/enriched-NNN.json`

**Schema**: See `docs/dev-workflow/ENRICHED-ISSUE-SCHEMA.md` for full JSON structure.

**Manual re-enrichment** (if needed):
```bash
claude enrich-issue 3        # Enrich specific issue
claude enrich-issue          # Enrich all unenriched issues
```

> **Why in-session?** The old workflow spawned `claude enrich-issue` as a subprocess from `capture-issue.sh`, but the subprocess couldn't get file write approval (parent Claude owned the terminal). The skill runs everything in-session, avoiding this issue.

### Step 2: Triage Issues (AI Agent)

Process all captured issues:

```bash
claude triage-issues
```

**What happens**:
1. Checks for enriched JSON (`.debug/issues/enriched/enriched-NNN.json`)
2. If enriched: Uses pre-fetched data (FASTER - skips redundant fetches)
3. If not enriched: Falls back to manual data gathering
4. Classifies and determines root cause
5. Creates spec document in `docs/bugs/` or `docs/refinements/`
6. Moves issue to `.debug/issues/triaged/` with JSON metadata

**Note**: If enriched data exists, triage skips:
- Spec file reading (uses `spec_reference.relevant_excerpts`)
- Log parsing (uses `log_analysis.errors`)
- Apple docs fetch (uses `ios_context.apple_docs_findings`)

### Step 3: Dispatch Agents

Work on issues in parallel:

```bash
claude dispatch --parallel
```

**What happens**:
1. Creates git worktree for each issue
2. Dispatches specialized agent
3. Agent uses TDD to fix issue
4. Agent creates PR when done

---

## File Naming Conventions

### Raw Issues
- **Pattern**: `issue-NNN.md` (e.g., `issue-001.md`, `issue-042.md`)
- **Numbers**: Sequential, NEVER reused
- **Counter**: Stored in `.debug/issues/.next-issue-number`

### Bug Specifications
- **Pattern**: `TYPE-NNN-short-description.md`
- **TYPE**: `BUG`, `BLOCKER`, or `PERF`
- **NNN**: Three-digit number matching issue number
- **short-description**: Hyphenated, lowercase summary (max 5 words)

**Examples**:
- `BUG-001-camera-upload-hardcoded-user-id.md`
- `BLOCKER-001-firebase-bundle-id-mismatch.md`
- `PERF-003-image-loading-timeout.md`

### Refinement Specifications
- **Pattern**: `REF-NNN-short-description.md`

---

## Handling BLOCKERs

BLOCKERs are urgent issues that require immediate attention.

### When to Use BLOCKER Type
- Cannot run app on simulator
- Cannot deploy to device/TestFlight
- Core feature completely broken
- Security vulnerability discovered
- Build system failure
- CI/CD pipeline blocked

### BLOCKER Document Structure

```markdown
# BLOCKER-NNN: Title

**Status**: Blocking
**Severity**: Critical
**Blocking**: [What is blocked]
**Created**: [Date]

## Executive Summary
One paragraph explaining issue, root cause, and impact.

## Root Cause Analysis
Detailed technical analysis.

## Immediate Workaround
Steps for temporary fix (if available).

## Proper Solution
Steps for permanent fix.

## Timeline
- Workaround: [Time estimate]
- Proper fix: [Time estimate]
```

---

## Common Mistakes to Avoid

### 1. Filing bugs to wrong location
- **WRONG**: Creating `docs/BLOCKER-*.md` manually in root
- **RIGHT**: Tell Claude "capture this issue" and select type `blocker`

### 2. Skipping the triage step
- **WRONG**: Manually creating docs in `docs/bugs/`
- **RIGHT**: Run `claude triage-issues` to process captured issues

### 3. Reusing issue numbers
- **WRONG**: Manually creating `issue-001.md` when it exists in `triaged/`
- **RIGHT**: Let the counter file manage numbering automatically

### 4. Forgetting descriptive suffix
- **WRONG**: `BUG-001.md`
- **RIGHT**: `BUG-001-camera-upload-fails.md`

### 5. Filing non-urgent issues as BLOCKER
- **WRONG**: Using BLOCKER for minor bugs
- **RIGHT**: Reserve BLOCKER for true showstoppers that halt development

---

## Mental Model

```
User finds bug
       │
       ▼
Tell Claude: "capture this issue"
       │
       ▼
Claude uses capture-issue skill (IN-SESSION)
       │
       ├──► Gathers details via conversation
       ├──► Creates .debug/issues/raw/issue-NNN.md
       │
       ├──► Auto-enriches:
       │    ├──► Validates spec path
       │    ├──► Parses FULL log file
       │    ├──► Detects iOS frameworks
       │    ├──► Fetches Apple docs (if iOS)
       │    ├──► Identifies affected files
       │    │
       │    ▼
       │    .debug/issues/enriched/enriched-NNN.json
       │
       ▼
[USER] claude triage-issues
       │
       ├──► Uses enriched JSON (skips redundant fetches)
       ├──► Classifies and determines root cause
       │
       ├──► .debug/issues/triaged/issue-NNN.md
       │    .debug/issues/triaged/issue-NNN.json
       │
       └──► docs/bugs/BUG-NNN-description.md
            docs/bugs/BLOCKER-NNN-description.md
            docs/bugs/PERF-NNN-description.md
            docs/refinements/REF-NNN-description.md
       │
       ▼
claude dispatch
       │
       ▼
Agent fixes in worktree → PR
       │
       ▼
Resolved → .debug/completed/issues/
```

---

## Integration with Existing Workflow

This workflow integrates with:
- **DEV-ITERATION-SYSTEM-001**: Main development workflow
- **apple-docs-fetcher**: Mandatory for iOS issue triage
- **superpowers:systematic-debugging**: Used by dispatch agents
- **superpowers:test-driven-development**: Used for fixes

---

## Troubleshooting

### Issue numbers seem wrong
Check the counter file:
```bash
cat .debug/issues/.next-issue-number
```

Reset if corrupted:
```bash
# Find highest existing issue
find .debug/issues -name "issue-*.md" | grep -oE '[0-9]+' | sort -n | tail -1
# Set counter to next number
echo "N" > .debug/issues/.next-issue-number  # Replace N with next number
```

### Triage agent isn't finding issues
Verify issues are in raw directory:
```bash
ls -la .debug/issues/raw/
```

### Dispatch fails to create worktree
Check for existing worktrees:
```bash
git worktree list
```

### Enrichment didn't run or failed
Check enrichment log:
```bash
cat .debug/enrichment.log
```

Re-run enrichment manually:
```bash
claude enrich-issue NNN
```

### Enriched JSON is missing or corrupt
Delete and re-enrich:
```bash
rm .debug/issues/enriched/enriched-NNN.json
claude enrich-issue NNN
```

### Triage isn't using enriched data
Verify enriched file exists:
```bash
ls -la .debug/issues/enriched/enriched-NNN.json
cat .debug/issues/enriched/enriched-NNN.json | head -20
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Capture issue | Tell Claude: "capture this issue" (uses skill) |
| Re-enrich issue | `claude enrich-issue NNN` |
| Enrich all | `claude enrich-issue` |
| Triage issues | `claude triage-issues` |
| Dispatch agents | `claude dispatch --parallel` |
| Check health | `./scripts/check-health.sh` |
| View raw issues | `ls .debug/issues/raw/` |
| View enriched | `ls .debug/issues/enriched/` |
| View completed | `ls .debug/completed/issues/` |

---

**See also**:
- `docs/dev-workflow/QUICK-REFERENCE.md` - Quick reference card
- `docs/dev-workflow/ENRICHED-ISSUE-SCHEMA.md` - Enriched JSON schema

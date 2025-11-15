# Verified Stage Development - Usage Guide

**Phase 1 Implementation**

## Quick Start

### First Time Setup (Before Any iOS Stage)

```bash
/apple-docs-fetcher
```

This fetches Apple developer documentation locally for fast, accurate verification.

### Running a Stage

```bash
/verified-stage-development stage-2.2
```

Replace `stage-2.2` with your stage number (e.g., `stage-2.3`, `stage-3.1`).

### Complete Flow

```
1. Context Collection
   → Loads all previous artifacts

2. Research Verification
   → Verifies technical claims with sources

3. Planning
   → Creates implementation plan (write-plan)

🚧 GATE 1: Human Approval
   → Review research + plan
   → Type: "proceed to execute"

4. Execution
   → Creates all stage artifacts (execute-plan)

5. Checkpoint & Drift Detection
   → Generates checkpoint document
   → Detects deviations from master design
   → Updates PROJECT-STATUS.md

🚧 GATE 2: Human Approval
   → Review checkpoint
   → Type: "approved - proceed to Stage X.Y+1"
   → Manually update master doc if drift detected
```

## What Phase 1 Includes

✅ Apple Docs Fetcher (one-time setup)
✅ Context Collection (explicit file list)
✅ Research Verification Hook (sub-agent)
✅ Planning Integration (write-plan)
✅ Two-Gate Approval Flow
✅ Checkpoint Generation
✅ Master Document Drift Detection (manual application)
✅ PROJECT-STATUS.md updates

## What Phase 1 Does NOT Include

❌ Verification hook (code validation, TDD enforcement) - Phase 2
❌ Auto-update master document - Phase 2
❌ Dry-run mode - Phase 3
❌ Advanced error recovery - Phase 3

## Files Created Per Stage

```
docs/validation/
└── RESEARCH-VALIDATION-stage-X.X.md

docs/plans/
├── YYYY-MM-DD-stage-X.X-[topic].md
└── PLAN-SUMMARY-stage-X.X.md

docs/checkpoints/
└── CHECKPOINT-stage-X.X-[name].md

docs/specs/ (via execute-plan)
docs/design/ (via execute-plan)
docs/adr/ (via execute-plan)
docs/test/ (via execute-plan)

PROJECT-STATUS.md (updated)
```

## Troubleshooting

**"ERROR: Apple documentation not found"**
→ Run `/apple-docs-fetcher` first

**"ERROR: Previous stage not complete"**
→ Complete previous stage first

**Research sub-agent times out**
→ Type 'retry' to run again

**Planning or execution fails**
→ Check error message, type 'retry' or 'abort'

**Apple docs stale warning**
→ Non-blocking, refresh after stage: `/apple-docs-fetcher --refresh`

## Examples

See design document for detailed examples:
`docs/plans/2025-11-02-verified-stage-development-design.md`

## Design Reference

Full design and rationale:
`docs/plans/2025-11-02-verified-stage-development-design.md`

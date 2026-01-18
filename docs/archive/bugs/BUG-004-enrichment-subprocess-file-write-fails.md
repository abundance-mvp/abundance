# BUG-004: Enrichment Subprocess Cannot Write Files from capture-issue.sh

**Status**: Resolved
**Severity**: Medium
**Type**: Silent Failure
**Created**: 2025-12-11
**Resolved**: 2025-12-11
**Solution**: `capture-issue` skill (`.claude/skills/capture-issue/SKILL.md`)

## Description

When `capture-issue.sh` invokes `claude enrich-issue NNN` as a subprocess, the enrichment agent performs full analysis (validates spec, parses logs, detects iOS context, identifies affected files) but fails to write the enriched JSON output file to `.debug/issues/enriched/enriched-NNN.json`.

## Expected Behavior

The `claude enrich-issue` command should:
1. Analyze the raw issue completely
2. Write enriched JSON to `.debug/issues/enriched/enriched-NNN.json`
3. Return success

## Actual Behavior

The enrichment agent:
1. Analyzes the raw issue completely (analysis is correct)
2. Outputs analysis summary to stdout/tee
3. Does NOT write the JSON file
4. Script detects missing file and shows warning:
   ```
   Enrichment did not produce output. Raw issue still available.
   You can run manually: claude enrich-issue 3
   ```

## Root Cause Analysis

**Core Issue: Nested Claude Invocation**

The typical workflow is:
```
User → Claude (interactive, owns terminal) → capture-issue.sh → claude enrich-issue (subprocess)
```

The subprocess Claude **cannot get user approval** because the parent Claude session already owns the terminal. This is not just a non-interactive mode issue—it's a fundamental constraint of nested Claude invocations.

**Evidence**:

1. **capture-issue.sh:217** spawns Claude as subprocess:
   ```bash
   claude enrich-issue "$ISSUE_NUM" 2>&1 | tee -a "$PROJECT_ROOT/.debug/enrichment.log"
   ```

2. **enrichment.log** shows Claude completed analysis but was waiting for permission it cannot receive:
   ```
   I've completed the analysis for **Issue #003**. Waiting for file write permission to save the enriched JSON.
   ```

3. Running `claude enrich-issue NNN` manually works because no parent Claude is blocking the terminal.

## Affected Files

- `scripts/capture-issue.sh:215-231` (subprocess invocation)
- `.claude/commands/enrich-issue.md` (command definition)

## Solution: capture-issue Skill

**Implemented**: `.claude/skills/capture-issue/SKILL.md`

The solution replaces the bash script + subprocess pattern with a unified Claude skill that runs entirely in the parent session:

1. User invokes `capture-issue` skill (or Claude recognizes bug capture intent)
2. Skill gathers issue details via AskUserQuestion
3. Skill creates raw issue markdown (in-session, has approval)
4. Skill immediately enriches (validates spec, parses logs, detects iOS, fetches Apple docs)
5. Skill writes enriched JSON (in-session, has approval)
6. Reports summary to user

**Why this works**: Everything runs in the parent Claude session which already has terminal access and can approve file writes. No subprocess, no permission issues.

**Usage**:
```
User: "I found a bug - the camera button doesn't respond after auth failure"
Claude: [Uses capture-issue skill to gather details and create enriched issue]
```

## Rejected Options

### Option A: Pre-approve File Writes
Would require Claude Code configuration changes. May not be supported.

### Option B: Accept Manual Workflow
Works but poor UX - user must remember to run `claude enrich-issue NNN` separately.

### Option C: Queue for Later
Background jobs don't help because parent Claude is still running and owns the terminal.

## Test Plan

- [ ] Unit test: Verify subprocess behavior with different invocation methods
- [ ] Integration test: Run `capture-issue.sh` end-to-end
- [ ] Verify enriched JSON file is created
- [ ] Verify enrichment content matches analysis
- [ ] Test with manual `claude enrich-issue NNN` as control

## Workaround

User runs enrichment manually after capture completes:
```bash
./scripts/capture-issue.sh
# ... capture issue ...
claude enrich-issue NNN
```

## References

- Original issue: `.debug/issues/triaged/issue-004.md`
- Enrichment log: `.debug/enrichment.log`
- Enrichment command: `.claude/commands/enrich-issue.md`

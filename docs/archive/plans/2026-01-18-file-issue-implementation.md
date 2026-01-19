# File-Issue Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a standardized issue-filing skill that integrates with device-tester, code-review, and dispatch coordinator.

**Architecture:** Single skill (`file-issue`) with user command, hybrid info gathering, guided classification, and smart routing to brainstorming or dispatch based on issue type.

**Tech Stack:** Claude Code skills/commands (Markdown), YAML frontmatter for issue metadata

**Design Doc:** `docs/plans/2026-01-18-file-issue-skill-design.md`

---

## Task 1: Create File-Issue Skill Core

**Files:**
- Create: `.claude/skills/file-issue/SKILL.md`

**Step 1: Create the skill directory**

```bash
mkdir -p .claude/skills/file-issue
```

**Step 2: Write the skill file**

Create `.claude/skills/file-issue/SKILL.md`:

```markdown
---
name: file-issue
description: |
  Standardized issue filing for bugs, features, and improvements.
  Integrates with device-tester, code-review, and dispatch coordinator.

  Invoke manually or programmatically from other skills.

  Arguments:
  - --source: manual | device-tester | code-review
  - --context: JSON with pre-populated fields (for programmatic use)
user-invocable: false
---

# File Issue Skill

File issues with standardized format, guided classification, and smart routing.

## Entry Points

| Source | Context | Behavior |
|--------|---------|----------|
| `manual` | User description | Hybrid: accept inline, ask for missing |
| `device-tester` | Logs, device info, screenshots | Minimal questions, auto-populate |
| `code-review` | File, line, finding, severity | Minimal questions, auto-populate |

---

## 1. Gather Information

### Manual Source (Hybrid Approach)

IF user provided description:
  - Extract: summary, expected/actual behavior
  - Ask only for missing critical info

IF no description:
  - Ask: "What issue are you seeing?"
  - Then: "What did you expect to happen?"
  - Then: "Any relevant files or screenshots?"

### device-tester Source

Auto-populate from context:
- Console logs (last 50 relevant lines)
- Device: w-16e, iOS version
- Recent screenshots in `./screenshots/`
- Current test scenario

Only ask: "Brief summary of the issue?"

### code-review Source

Auto-populate from context:
- File and line number
- Finding description
- Severity from auditor

Only ask: "Confirm this should be filed as an issue?"

---

## 2. Classify (Guided with Defaults)

### Detect Component

| Signal | Component |
|--------|-----------|
| `.swift` files, SwiftUI, UIKit, AVFoundation, CoreData | `ios` |
| `.ts` files, Firebase, Firestore, Cloud Functions | `backend` |
| Gemini, AI pipeline, tool calling | `backend` |
| GCP, Cloud Logging, deployment | `backend` |
| **Ambiguous** | `ios` (default) |

### Detect Type

| Signal | Type |
|--------|------|
| "crash", "broken", "doesn't work", "error" | `bug` |
| "used to work", "regression", "broke" | `regression` |
| "slow", "lag", "memory", "battery" | `performance` |
| "add", "new", "implement", "create" | `feature` |
| "improve", "better", "enhance" | `enhancement` |
| "UI", "design", "layout", "user experience" | `ux` |
| "refactor", "restructure", "architecture" | `architecture` |
| "optimize", "faster", "cleaner" | `optimization` |
| "security", "vulnerability", "credentials" | `security` |
| "test", "coverage", "flaky" | `test` |

### Detect Priority

| Signal | Priority |
|--------|----------|
| "crash", "can't use", "blocking", security issues | `P0` |
| bugs, regressions, performance issues | `P1` |
| features, enhancements, ux | `P2` |
| tests, optimization, architecture | `P3` |

### Present Classification

```
I'd classify this as:
- **Type:** bug
- **Priority:** P1 (high)
- **Component:** ios

Is this correct? (Enter to confirm, or specify changes)
```

---

## 3. Write Issue File

### Generate Filename

```
docs/issues/YYYY-MM-DD-<slug>.md

Slug rules:
- Lowercase
- Hyphens for spaces
- Max 50 characters
- Remove articles (a, an, the)
```

### Issue Template

```markdown
---
date: YYYY-MM-DD
status: open
priority: P1
type: bug
component: ios
source: manual
related-files:
  - path/to/file.swift
screenshots:
  - filename.png
axiom-agent: null
branch: null
design-doc: null
implementation-plan: null
---

## Summary

[One-line description]

## Description

[Detailed verbose description]

## Expected Behavior

[What should happen]

## Actual Behavior

[What actually happens]

## Technical Context

- Device: [device info if available]
- iOS: [version if available]
- Source: [source]
- Console logs:
  ```
  [relevant logs if available]
  ```

## Proposed Solution (optional)

[Initial thoughts on fix]
```

### Confirm Filing

```
Issue filed: docs/issues/2026-01-18-camera-freezes-after-error.md

Type: bug | Priority: P1 | Component: ios
```

---

## 4. Route Next Action

### By Issue Type

| Type | Next Action |
|------|-------------|
| bug, regression, performance, security, test | "Ready for dispatch. Run `/project:dispatch` when ready." |
| feature, enhancement, ux, architecture | Invoke brainstorming |
| optimization | Ask: "Is this a code-level optimization (file directly) or architectural (brainstorm)?" |

### By Source (Smart Continuation)

| Source | After Filing |
|--------|--------------|
| device-tester | "Continue testing or stop to investigate?" |
| code-review | Return to review, continue with other findings |
| manual + bug type | "Ready for dispatch" |
| manual + feature type | Invoke brainstorming |

---

## 5. Brainstorming Flow

When type triggers brainstorming (feature, enhancement, ux, architecture):

```
1. Detect component (ios/backend)

2. IF component == ios:
   Skill(skill="ios-superpowers", args="brainstorm <issue-summary>")

   IF component == backend:
   Skill(skill="backend-superpowers")
   → Then invoke superpowers:brainstorming

3. Design doc written to docs/plans/YYYY-MM-DD-<topic>-design.md

4. Update issue with design-doc field

5. Ask: "Design complete. Create implementation plan?"
   - Yes → Skill(skill="superpowers:writing-plans")
   - No → "Issue ready for future dispatch"
```

---

## 6. Issue Types Reference

| Type | Triggers Brainstorming | Priority Default |
|------|----------------------|------------------|
| `bug` | No | P1 |
| `regression` | No | P1 |
| `performance` | No | P1 |
| `feature` | Yes | P2 |
| `enhancement` | Yes | P2 |
| `ux` | Yes | P2 |
| `architecture` | Yes | P3 |
| `optimization` | Depends | P3 |
| `security` | No | P0 |
| `test` | No | P3 |

---

## 7. Screenshots

Screenshots are stored in `./screenshots/` (symlinked to iCloud).

When referencing screenshots:
- Use just the filename: `screenshots: [IMG_1234.png]`
- Check for recent screenshots: `ls -lt screenshots/ | head -5`
- Read screenshot to analyze (Claude is multimodal)
```

**Step 3: Verify file was created**

```bash
cat .claude/skills/file-issue/SKILL.md | head -20
```

Expected: See skill frontmatter and first section

**Step 4: Commit**

```bash
git add .claude/skills/file-issue/SKILL.md
git commit -m "feat: add file-issue skill core

Standardized issue filing with:
- Hybrid info gathering (inline + follow-up)
- Guided classification with defaults
- Component routing (iOS vs Backend)
- Smart continuation by source
- Brainstorming trigger for feature types

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Create File-Issue Command

**Files:**
- Create: `.claude/commands/file-issue.md`

**Step 1: Write the command file**

Create `.claude/commands/file-issue.md`:

```markdown
# File Issue Command

File a standardized issue for bugs, features, or improvements.

## Usage

```
/project:file-issue [description]
```

## Examples

```bash
# Interactive (no description)
/project:file-issue

# With inline description
/project:file-issue camera freezes after dismissing error dialog

# With full context
/project:file-issue camera freezes after error, should resume preview, see screenshot IMG_1234.png
```

## What Happens

1. **Gather info** - Accept inline description, ask for missing critical info
2. **Classify** - Propose type, priority, component (you confirm or override)
3. **File** - Write to `docs/issues/YYYY-MM-DD-<slug>.md`
4. **Route** - Bugs → ready for dispatch; Features → start brainstorming

## Instructions

Invoke the `file-issue` skill with source=manual:

```
Skill(skill="file-issue", args="--source manual")
```

Then follow the skill instructions exactly.

If user provided a description in the command args, pass it to the skill as initial context.
```

**Step 2: Verify file was created**

```bash
cat .claude/commands/file-issue.md
```

Expected: Full command content

**Step 3: Commit**

```bash
git add .claude/commands/file-issue.md
git commit -m "feat: add /project:file-issue command

User-facing command for filing issues manually.
Invokes file-issue skill with source=manual.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Update Device-Tester with Issue Filing

**Files:**
- Modify: `.claude/skills/device-tester.md`

**Step 1: Read current device-tester.md**

```bash
cat .claude/skills/device-tester.md
```

**Step 2: Add issue filing section after "Iterative Workflow" section (around line 300)**

Insert after the "Iterative Workflow" diagram and before "Quick Commands Reference":

```markdown
---

## Issue Filing Integration

When an issue is discovered during device testing, use the file-issue skill to create a standardized issue.

### Automatic Context Gathering

Before invoking file-issue, gather:

1. **Console logs** (last 50 relevant lines from launch output)
2. **Device info**: w-16e, iOS version
3. **Recent screenshots**:
   ```bash
   ls -lt screenshots/ | head -5
   ```
4. **Current test scenario** (what was being tested)

### Invoke File-Issue

```
Skill(skill="file-issue", args="--source device-tester --context <gathered>")
```

Context JSON structure:
```json
{
  "source": "device-tester",
  "device": "w-16e",
  "ios_version": "18.x",
  "console_logs": "[last 50 lines]",
  "screenshots": ["IMG_1234.png"],
  "test_scenario": "Testing camera capture flow"
}
```

### After Issue Filed

Ask user:
- **"Continue testing?"** → Resume testing loop at step 1
- **"Stop to investigate?"** → Offer to start debugging with `ios-superpowers debug`

### Quick Filing

For obvious bugs during testing:

```
"I noticed [issue]. Should I file this as an issue?"
- Yes → Invoke file-issue with gathered context
- No → Continue testing
```
```

**Step 3: Update the Iterative Workflow diagram (around line 291-295)**

Find the section:
```markdown
│  4. IF ISSUE FOUND                                      │
│     ├─ Crash? → Invoke crash-analyzer agent             │
│     ├─ Slow? → Invoke performance-profiler agent        │
│     ├─ Test fail? → Invoke test-debugger agent          │
│     └─ Bug? → Fix code, go to step 1                    │
```

Replace with:
```markdown
│  4. IF ISSUE FOUND                                      │
│     ├─ Crash? → Invoke crash-analyzer agent             │
│     ├─ Slow? → Invoke performance-profiler agent        │
│     ├─ Test fail? → Invoke test-debugger agent          │
│     ├─ Bug? → Offer to file issue, then fix or continue │
│     └─ Feature idea? → File as enhancement              │
```

**Step 4: Verify changes**

```bash
grep -A5 "Issue Filing Integration" .claude/skills/device-tester.md
```

Expected: See the new section

**Step 5: Commit**

```bash
git add .claude/skills/device-tester.md
git commit -m "feat(device-tester): integrate file-issue skill

Add issue filing integration:
- Auto-gather context (logs, device, screenshots)
- Invoke file-issue skill with source=device-tester
- Smart continuation (continue testing vs investigate)
- Update workflow diagram with issue filing step

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Update ios-superpowers with Review→File-Issue Flow

**Files:**
- Modify: `.claude/skills/ios-superpowers/SKILL.md`

**Step 1: Read the review section of ios-superpowers**

```bash
grep -A20 "### review Action" .claude/skills/ios-superpowers/SKILL.md
```

**Step 2: Add issue filing to review execution (after line 184)**

Find the review Execution section:
```markdown
### review Execution

```
1. changed_files = `git diff --name-only`
2. FOR file IN changed_files (parallel):
   domain = DETECT(file_content)
   agent = SELECT_AUDITOR(domain)
   IF agent:
     Task(subagent_type=agent)
3. COMBINE audit_results
4. Skill(skill="superpowers:requesting-code-review", context=audit_results)
5. VERIFY()
```
```

Replace with:
```markdown
### review Execution

```
1. changed_files = `git diff --name-only`
2. FOR file IN changed_files (parallel):
   domain = DETECT(file_content)
   agent = SELECT_AUDITOR(domain)
   IF agent:
     Task(subagent_type=agent)
3. COMBINE audit_results
4. Skill(skill="superpowers:requesting-code-review", context=audit_results)
5. IF critical_findings (P0/P1):
   OFFER_ISSUE_FILING(findings)
6. VERIFY()
```

### Issue Filing from Review

When code review finds critical issues (P0/P1 severity):

```
1. FOR each critical_finding:
   - Extract: file, line, description, severity
   - Present: "Found critical issue: [description] in [file]:[line]"

2. Ask: "File as issue(s)? (y/n/select)"
   - y → File all as separate issues
   - n → Skip, continue review
   - select → Let user pick which to file

3. FOR each selected_finding:
   Skill(skill="file-issue", args="--source code-review --context <finding>")

   Context:
   {
     "source": "code-review",
     "file": "path/to/file.swift",
     "line": 123,
     "finding": "description",
     "severity": "P0",
     "auditor": "axiom:concurrency-auditor"
   }

4. Continue with remaining review
5. Summary includes: "Filed X issues: [links]"
```
```

**Step 3: Verify changes**

```bash
grep -A10 "Issue Filing from Review" .claude/skills/ios-superpowers/SKILL.md
```

Expected: See the new section

**Step 4: Commit**

```bash
git add .claude/skills/ios-superpowers/SKILL.md
git commit -m "feat(ios-superpowers): add review→file-issue flow

When code review finds critical issues (P0/P1):
- Extract findings from parallel auditors
- Offer to file as issues
- Invoke file-issue with source=code-review
- Continue review after filing
- Summary includes filed issue links

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Update Dispatch with Backend-Superpowers Routing

**Files:**
- Modify: `.claude/commands/dispatch.md`

**Step 1: Read current dispatch architecture section**

```bash
head -30 .claude/commands/dispatch.md
```

**Step 2: Update the Architecture diagram (lines 9-23)**

Find:
```markdown
## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        DISPATCH COORDINATOR                          │
├─────────────────────────────────────────────────────────────────────┤
│  1. Parse triaged issues from docs/issues/
│  2. Classify each issue → select Axiom agent                         │
│  3. Create isolated git worktrees                                    │
│  4. Dispatch agents in parallel with:                                │
│     - ios-superpowers (Apple docs grounding)                         │
│     - Axiom agent (iOS-specific patterns + debugging)                │
│  5. Monitor and report progress                                      │
└─────────────────────────────────────────────────────────────────────┘
```
```

Replace with:
```markdown
## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        DISPATCH COORDINATOR                          │
├─────────────────────────────────────────────────────────────────────┤
│  1. Parse triaged issues from docs/issues/                           │
│  2. Classify each issue:                                             │
│     - component: ios → ios-superpowers + Axiom agent                 │
│     - component: backend → backend-superpowers + MCP tools           │
│     - component: shared → ios-superpowers (primary) + flag backend   │
│  3. Create isolated git worktrees                                    │
│  4. Dispatch agents in parallel                                      │
│  5. Update issue metadata (axiom-agent, branch, status)              │
│  6. Monitor and report progress                                      │
└─────────────────────────────────────────────────────────────────────┘
```
```

**Step 3: Add Backend Routing section after Axiom Agent Routing Matrix (around line 110)**

Insert after the "Default (General iOS)" table:

```markdown
---

## Backend Routing (component: backend)

When issue has `component: backend`, route to backend-superpowers instead of ios-superpowers.

### Backend Issue Detection

| Issue Contains | Routes To |
|----------------|-----------|
| Firestore, database, queries, documents | Firestore MCP tools |
| Cloud Functions, deployment, functions | Functions MCP + deploy workflow |
| Auth, users, permissions, Firebase Auth | Auth MCP tools |
| Gemini, AI pipeline, tool calling, prompts | `gemini-integration` skill |
| Logs, errors, monitoring, metrics | Observability MCP tools |
| Storage, buckets, GCS, files | Storage MCP tools |
| FCM, push notifications, messaging | FCM MCP tools |
| Remote Config, feature flags | Remote Config MCP tools |

### Backend Agent Prompt Template

```markdown
## Task: Fix [ISSUE-ID] - [Title]

### Context
- **Worktree:** ../abundance-worktrees/[branch-name]
- **Spec:** [path to issue in docs/issues/]
- **Component:** backend

### Instructions

1. **Navigate to worktree:**
   ```bash
   cd ../abundance-worktrees/[branch-name]
   ```

2. **Read the issue:**
   ```bash
   cat docs/issues/[issue-file].md
   ```

3. **Invoke backend-superpowers:**
   ```
   Skill(skill="backend-superpowers")
   ```

   This will:
   - Detect backend domain (Firestore, Functions, Auth, etc.)
   - Route Gemini patterns to gemini-integration skill
   - Use appropriate MCP tools for Firebase/GCP operations
   - Verify deployments and check logs

4. **For Gemini/AI Pipeline issues:**
   - Skill auto-routes to gemini-integration
   - Follow thought signature patterns
   - Test tool calling with proper SDK usage

5. **Verify fix:**
   - Check Cloud Functions logs for errors
   - Verify Firestore operations succeed
   - Test end-to-end if applicable

6. **Commit changes:**
   ```bash
   git add -A
   git commit -m "[type]: [description]"
   ```

7. **Report completion:**
   ```
   ✅ [ISSUE-ID] fixed
   - Backend domain: [firestore/functions/auth/gemini/etc.]
   - MCP tools used: [list]
   - Deployment verified: yes/no
   - Ready for PR
   ```
```
```

**Step 4: Update Process section (around line 136) to include component routing**

Find the classification section:
```markdown
### 2. Classify and select Axiom agent

For each issue, use the routing matrix above:
```

Update to:
```markdown
### 2. Classify by component and select agent

For each issue, first check the `component` field from issue metadata:

```
IF issue.component == "backend":
    # Use backend-superpowers routing
    Skill(skill="backend-superpowers")
    # See "Backend Routing" section above

ELSE IF issue.component == "ios" OR issue.component == "shared":
    # Use ios-superpowers + Axiom routing (existing logic)
    IF issue.symptoms contains "BUILD FAILED" OR "module not found":
        axiom_agent = "axiom:build-fixer"
    ELSE IF issue.symptoms contains "memory leak" OR "retain cycle":
        axiom_agent = "axiom:memory-auditor"
    ...
```

If issue doesn't have `component` field, detect from content:
- `.swift`, SwiftUI, UIKit, Apple frameworks → `ios`
- `.ts`, Firebase, Firestore, GCP → `backend`
- Ambiguous → default to `ios`
```

**Step 5: Update the dispatch parallel section (around line 182)**

Find:
```markdown
### 4. Dispatch agents in parallel
```

Update to include backend routing:
```markdown
### 4. Dispatch agents in parallel

Use the Task tool to launch agents. For EACH issue, create ONE agent.

**iOS Issues (component: ios):**
```
Task(
  description="Fix [ISSUE-ID] (iOS)",
  prompt="[iOS agent template]",
  subagent_type="[axiom_agent from routing matrix]"
)
```

**Backend Issues (component: backend):**
```
Task(
  description="Fix [ISSUE-ID] (Backend)",
  prompt="[Backend agent template with backend-superpowers invocation]",
  subagent_type="general-purpose"
)
```

**Shared Issues (component: shared):**
```
# Dispatch iOS agent as primary
Task(
  description="Fix [ISSUE-ID] (iOS - primary)",
  prompt="[iOS agent template, note backend implications]",
  subagent_type="[axiom_agent]"
)

# Flag for backend follow-up after iOS fix
```
```

**Step 6: Verify changes**

```bash
grep -A5 "Backend Routing" .claude/commands/dispatch.md
```

Expected: See the new backend routing section

**Step 7: Commit**

```bash
git add .claude/commands/dispatch.md
git commit -m "feat(dispatch): add backend-superpowers routing

Update dispatch coordinator to route based on component:
- component: ios → ios-superpowers + Axiom agents
- component: backend → backend-superpowers + MCP tools
- component: shared → ios-superpowers (primary) + backend flag

Add backend routing matrix:
- Firestore, Functions, Auth → Firebase MCP
- Gemini, AI pipeline → gemini-integration skill
- Logs, metrics → Observability MCP

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Create docs/issues Directory if Needed

**Files:**
- Create: `docs/issues/.gitkeep` (if directory doesn't exist)

**Step 1: Check if directory exists**

```bash
ls -la docs/issues/ 2>/dev/null || echo "Directory does not exist"
```

**Step 2: Create directory if needed**

```bash
mkdir -p docs/issues
touch docs/issues/.gitkeep
```

**Step 3: Commit if created**

```bash
git add docs/issues/.gitkeep 2>/dev/null && git commit -m "chore: create docs/issues directory for issue tracking

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>" || echo "Directory already exists or nothing to commit"
```

---

## Task 7: Integration Test - Manual Issue Filing

**Files:**
- Test: `.claude/skills/file-issue/SKILL.md`
- Test: `.claude/commands/file-issue.md`

**Step 1: Simulate manual issue filing**

Run the command mentally or in a test session:
```
/project:file-issue camera preview freezes after dismissing error dialog
```

Expected flow:
1. Skill extracts: summary="camera preview freezes", context mentions "error dialog"
2. Classification proposed: type=bug, priority=P1, component=ios
3. User confirms
4. Issue written to: `docs/issues/2026-01-18-camera-preview-freezes-after-error.md`
5. Next action: "Ready for dispatch"

**Step 2: Verify issue file format**

If an issue was created, check:
```bash
head -30 docs/issues/2026-01-18-*.md
```

Expected: YAML frontmatter + all body sections

**Step 3: Document test results**

```
Test: Manual issue filing
Result: PASS/FAIL
Notes: [any issues found]
```

---

## Task 8: Integration Test - Device-Tester Flow

**Files:**
- Test: `.claude/skills/device-tester.md`
- Test: `.claude/skills/file-issue/SKILL.md`

**Step 1: Simulate device-tester finding an issue**

Mental walkthrough:
1. Device tester runs, captures console logs
2. User says "the camera is frozen"
3. Device-tester gathers context: logs, device info, recent screenshots
4. Asks: "Should I file this as an issue?"
5. User says yes
6. Invokes file-issue with source=device-tester
7. Minimal questions (context is rich)
8. Issue filed
9. Asks: "Continue testing or stop to investigate?"

**Step 2: Verify context passing**

Check that device-tester's context includes:
- `source: device-tester`
- `device: w-16e`
- `console_logs: [...]`
- `screenshots: [...]`

**Step 3: Document test results**

```
Test: Device-tester issue filing
Result: PASS/FAIL
Notes: [any issues found]
```

---

## Task 9: Integration Test - Code Review Flow

**Files:**
- Test: `.claude/skills/ios-superpowers/SKILL.md`
- Test: `.claude/skills/file-issue/SKILL.md`

**Step 1: Simulate code review finding critical issue**

Mental walkthrough:
1. `ios-superpowers review` runs
2. concurrency-auditor finds: "@MainActor missing on UI update"
3. Severity: P1
4. Review asks: "Found 1 critical issue. File as issue?"
5. User says yes
6. Invokes file-issue with source=code-review
7. Context: file, line, finding, auditor
8. Issue filed
9. Review continues, summary includes issue link

**Step 2: Verify review continuation**

After filing, review should:
- Continue with other findings
- Include filed issue in summary

**Step 3: Document test results**

```
Test: Code review issue filing
Result: PASS/FAIL
Notes: [any issues found]
```

---

## Task 10: Integration Test - Dispatch with Backend

**Files:**
- Test: `.claude/commands/dispatch.md`

**Step 1: Create test backend issue**

Create `docs/issues/2026-01-18-test-backend-issue.md`:
```markdown
---
date: 2026-01-18
status: open
priority: P2
type: bug
component: backend
source: manual
related-files:
  - functions/src/ai-pipeline.ts
---

## Summary

Gemini tool calling fails with thought signature error.

## Description

When calling barcode_lookup tool, Gemini returns 400 error about missing thought_signature.
```

**Step 2: Run dispatch dry-run**

```
/project:dispatch --dry-run
```

Expected output should show:
- Issue detected as `component: backend`
- Routes to `backend-superpowers`
- Mentions `gemini-integration` skill for Gemini issues

**Step 3: Clean up test issue**

```bash
rm docs/issues/2026-01-18-test-backend-issue.md
```

**Step 4: Document test results**

```
Test: Dispatch backend routing
Result: PASS/FAIL
Notes: [any issues found]
```

---

## Task 11: Final Verification and Documentation

**Files:**
- Verify: All created/modified files
- Update: `CLAUDE.md` if needed

**Step 1: List all changes**

```bash
git log --oneline -10
```

Expected: 5-7 commits for this implementation

**Step 2: Verify file structure**

```bash
ls -la .claude/skills/file-issue/
ls -la .claude/commands/file-issue.md
```

**Step 3: Update CLAUDE.md Quick Commands section if needed**

Check if `/project:file-issue` should be added to quick commands:
```bash
grep "file-issue" CLAUDE.md
```

If not present, add to Quick Commands section:
```markdown
/project:file-issue [description]       # File standardized issue
```

**Step 4: Final commit if CLAUDE.md updated**

```bash
git add CLAUDE.md
git commit -m "docs: add file-issue to CLAUDE.md quick commands

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

**Step 5: Summary**

```
Implementation complete:
- [x] file-issue skill created
- [x] file-issue command created
- [x] device-tester integrated
- [x] ios-superpowers review flow added
- [x] dispatch backend routing added
- [x] Integration tests documented
- [x] CLAUDE.md updated

Ready for use:
- /project:file-issue [description]
- device-tester auto-files issues
- ios-superpowers review offers issue filing
- dispatch routes iOS vs Backend
```

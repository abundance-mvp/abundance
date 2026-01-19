# Claude Commands & Skills Audit and Refactor Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Clean up redundant commands and ensure all iOS workflows use the ios-superpowers orchestrator as the single entry point for superpowers integration.

**Architecture:** Remove duplicate commands, update remaining commands/skills to delegate to ios-superpowers for iOS work instead of calling raw superpowers skills directly.

**Tech Stack:** Claude commands (markdown), skill invocations

---

## Audit Findings Summary

### PR #21 Merge Analysis

**What happened:**
1. Branch `fix/ios-simulator-crashes` performed a **reverse merge** (main INTO branch) at commit `d1052052`
2. This is a legitimate pattern to bring a branch up-to-date before merging
3. Merge conflicts in `apple-docs-fetcher-lite` files were resolved by accepting main's version

**apple-docs-fetcher-lite status:**
- **Correctly deprecated** in November 2025 (commit b787914)
- Consolidated into main `apple-docs-fetcher` with sosumi.ai fallback (PR #26)
- Git showing "D" is expected (symlink vs actual files issue, like `docs/`)
- **No action needed** - this is intentional

---

## Complete Commands/Skills Audit

### Commands to DELETE (Redundant)

| Command | Issue | Replacement |
|---------|-------|-------------|
| `super-code-review.md` | Duplicates ios-superpowers review | `/ios-superpowers review` |
| `troubleshoot.md` | Duplicates ios-superpowers debug | `/ios-superpowers debug <issue>` |

**Why redundant:** Both manually implement the same 3-phase pattern (detect iOS → fetch Apple docs → invoke superpowers) that `ios-superpowers` orchestrator already handles.

### Commands to UPDATE (Use ios-superpowers)

| Command | Current Issue | Fix |
|---------|--------------|-----|
| `verified-stage-development.md` | Lines 6,8: References `/superpowers:write-plan` and `/superpowers:execute-plan` directly | Delegate to ios-superpowers for iOS stages |
| `ios-sprint-executor.md` | Lines 3,6,10: References raw superpowers skills | Update to clarify ios-superpowers is the underlying orchestrator |
| `dispatch.md` | Lines 45-50, 83-88: Uses `superpowers:systematic-debugging` and `superpowers:test-driven-development` directly | Use ios-superpowers debug/tdd for iOS work |

### Skills to UPDATE (Use ios-superpowers)

| Skill | Current Issue | Fix |
|-------|--------------|-----|
| `verified-stage-development/SKILL.md` | Lines 349-350, 547-548: Invokes superpowers directly via SlashCommand | Delegate to ios-superpowers for iOS stages |
| `ios-sprint-executor/SKILL.md` | Lines 361-373, 513-524: Uses superpowers directly; Lines 229-251, 555-569: Uses raw superpowers:brainstorm and superpowers:requesting-code-review | Delegate to ios-superpowers for all superpowers invocations |

### Commands Already Correct (No Changes Needed)

| Command | Status |
|---------|--------|
| `ios-superpowers.md` | ✅ The orchestrator itself |
| `apple-docs-fetcher.md` | ✅ Direct Apple docs fetch |
| `validate-docs.md` | ✅ Not iOS-related |
| `check-drift.md` | ✅ Not iOS-related |
| `show-sprint-status.md` | ✅ Not iOS-related |
| `triage-issues.md` | ✅ Uses apple-docs-fetcher correctly |
| `enrich-issue.md` | ✅ Uses apple-docs-fetcher correctly |

---

## Task 1: Remove super-code-review.md

**Files:**
- Delete: `.claude/commands/super-code-review.md`

**Step 1: Delete the file**

```bash
trash .claude/commands/super-code-review.md
```

**Step 2: Verify deletion**

```bash
ls .claude/commands/ | grep super
```

Expected: No output (file removed).

**Step 3: Commit**

```bash
git add .claude/commands/super-code-review.md
git commit -m "$(cat <<'EOF'
refactor(commands): remove super-code-review.md

Duplicates ios-superpowers review functionality.
Use /ios-superpowers review instead.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Remove troubleshoot.md

**Files:**
- Delete: `.claude/commands/troubleshoot.md`

**Step 1: Delete the file**

```bash
trash .claude/commands/troubleshoot.md
```

**Step 2: Verify deletion**

```bash
ls .claude/commands/ | grep troubleshoot
```

Expected: No output (file removed).

**Step 3: Commit**

```bash
git add .claude/commands/troubleshoot.md
git commit -m "$(cat <<'EOF'
refactor(commands): remove troubleshoot.md

Duplicates ios-superpowers debug functionality.
Use /ios-superpowers debug <issue> instead.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Update verified-stage-development.md Command

**Files:**
- Modify: `.claude/commands/verified-stage-development.md`

**Step 1: Read current file**

```bash
cat .claude/commands/verified-stage-development.md
```

**Step 2: Update command to delegate to ios-superpowers for iOS stages**

Replace entire file with:

```markdown
Orchestrate stage development with research verification, planning, execution, and approval gates.

Invoke the Skill tool with skill="verified-stage-development" to dispatch a stage orchestration agent that will:
1. Load required context from docs/context-map.json for the specified stage
2. Research & verify technical claims (creates RESEARCH-VALIDATION-stage-X.Y.md)
3. **For iOS stages**: Use `/ios-superpowers plan` for implementation planning
4. **For non-iOS stages**: Use `/superpowers:write-plan`
5. Gate 1: Get your approval before execution
6. **For iOS stages**: Use `/ios-superpowers execute` for plan execution
7. **For non-iOS stages**: Use `/superpowers:execute-plan` with batch review
8. Gate 2: Generate checkpoint and validate against master documents

**iOS stages** (require ios-superpowers): 2.2, 3.1, 4.1, and any stage touching Swift code

Stage: $ARGUMENTS

Examples:
- `/verified-stage-development stage-2.2` - Execute Stage 2.2 (iOS Client Architecture)
- `/verified-stage-development stage-3.1` - Execute Stage 3.1 (iOS Implementation Research)
- `/verified-stage-development stage-5.3` - Execute Stage 5.3 (CI/CD & Automation)

See docs/context-map.json for available stages and their status.
```

**Step 3: Commit**

```bash
git add .claude/commands/verified-stage-development.md
git commit -m "$(cat <<'EOF'
refactor(commands): update verified-stage-development to use ios-superpowers

- iOS stages now delegate to ios-superpowers for planning and execution
- Non-iOS stages continue using raw superpowers skills
- Documents which stages require ios-superpowers (2.2, 3.1, 4.1)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Update verified-stage-development/SKILL.md

**Files:**
- Modify: `.claude/skills/verified-stage-development/SKILL.md`

**Step 1: Read current skill file (already read above)**

**Step 2: Update Phase 3 (Planning Integration) to use ios-superpowers for iOS stages**

Find lines ~347-477 and update to add iOS detection and ios-superpowers delegation.

**Changes needed:**

1. **Add iOS stage detection** at start of Phase 3:
```markdown
### Phase 3: Planning Integration

**Purpose:** Create implementation plan with verified context.

**iOS Stage Detection:**

First, check if this is an iOS stage:
- iOS stages: 2.2, 3.1, 4.1 (any stage with `apple_docs: true` in context-map.json)
- Check: `required_inputs` includes Swift/iOS files or `apple_docs` flag is set

**If iOS stage detected:**
- Use ios-superpowers orchestrator instead of raw superpowers
- This ensures Apple documentation is fetched and verified before planning
```

2. **Update superpowers invocation** (~lines 433-443):

For iOS stages:
```markdown
2. **Invoke ios-superpowers plan (iOS stages)**

   ```
   Tool: Skill
   Parameters:
     skill: ios-superpowers
     args: plan [stage description]
   ```
```

For non-iOS stages:
```markdown
2. **Invoke superpowers:write-plan (non-iOS stages)**

   ```
   Tool: SlashCommand
   Command: /superpowers:write-plan
   ```
```

3. **Update Phase 4 (Execution)** similarly (~lines 547-627):

For iOS stages:
```markdown
2. **Invoke ios-superpowers execute (iOS stages)**

   ```
   Tool: Skill
   Parameters:
     skill: ios-superpowers
     args: execute [plan path]
   ```
```

**Step 3: Apply edits using Edit tool**

(Multiple edits needed - see detailed changes in execution)

**Step 4: Commit**

```bash
git add .claude/skills/verified-stage-development/SKILL.md
git commit -m "$(cat <<'EOF'
refactor(skills): update verified-stage-development to use ios-superpowers

- Add iOS stage detection at start of Phase 3
- iOS stages (2.2, 3.1, 4.1) delegate to ios-superpowers plan/execute
- Non-iOS stages continue using raw superpowers skills
- Ensures Apple docs verification for all iOS planning/execution

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Update ios-sprint-executor.md Command

**Files:**
- Modify: `.claude/commands/ios-sprint-executor.md`

**Step 1: Read current file (already read above)**

**Step 2: Update to clarify ios-superpowers delegation**

The current command already mentions apple-docs-fetcher, but it lists raw superpowers skills. Update to clarify that ios-superpowers orchestrates everything.

Replace entire file with:

```markdown
Orchestrate iOS sprint development with superpowers integration, Apple docs fetching, and quality gates.

Invoke the Skill tool with skill="ios-sprint-executor" to dispatch a specialized iOS development agent that will:

1. Load sprint plan and context from docs/roadmap/SPRINT-PLAN-{N}.md
2. Detect iOS frameworks and fetch Apple documentation via apple-docs-fetcher
3. **Create implementation plan** via `/ios-superpowers plan` (ensures Apple docs grounding)
4. Get your approval before proceeding (Gate 1)
5. **Execute plan** via `/ios-superpowers execute` with quality checkpoints
6. **Run code review** via `/ios-superpowers review`
7. Create pull request with comprehensive documentation cross-references

**Note:** This skill uses ios-superpowers orchestrator for all superpowers interactions, ensuring Apple documentation is verified at every step.

Sprint: $ARGUMENTS

If no arguments provided, show available sprints from docs/roadmap/ROADMAP-001-mvp-implementation-timeline.md.

Examples:

- `/ios-sprint-executor sprint-1` - Execute Sprint 1 (iOS Project Setup & Authentication)
- `/ios-sprint-executor sprint-2` - Execute Sprint 2 (Camera Capture & Vision Layer 1)
- `/ios-sprint-executor sprint-3` - Execute Sprint 3 (Backend AI Pipeline)
```

**Step 3: Commit**

```bash
git add .claude/commands/ios-sprint-executor.md
git commit -m "$(cat <<'EOF'
refactor(commands): update ios-sprint-executor to use ios-superpowers

- Clarify that ios-superpowers orchestrates all superpowers interactions
- Replace raw superpowers:* references with ios-superpowers equivalents
- Add note explaining the orchestration pattern

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Update ios-sprint-executor/SKILL.md

**Files:**
- Modify: `.claude/skills/ios-sprint-executor/SKILL.md`

**Step 1: Identify all raw superpowers references**

Found at:
- Line 229-251: `superpowers:brainstorm`
- Lines 361-373: `/superpowers:write-plan`
- Lines 513-524: `/superpowers:execute-plan`
- Lines 555-569: `superpowers:requesting-code-review`

**Step 2: Update all superpowers invocations to use ios-superpowers**

**Change 1: Phase 1.5 UI/UX Brainstorming (~line 229)**

Replace:
```markdown
   ```
   Tool: Skill
   Parameters:
     skill: superpowers:brainstorm
   ```
```

With:
```markdown
   ```
   Tool: Skill
   Parameters:
     skill: ios-superpowers
     args: brainstorm [UI/UX gaps identified]
   ```
```

**Change 2: Phase 2 Planning (~line 364)**

Replace:
```markdown
3. **Invoke superpowers:write-plan**

   ```
   Tool: SlashCommand
   Command: /superpowers:write-plan
```

With:
```markdown
3. **Invoke ios-superpowers plan**

   ```
   Tool: Skill
   Parameters:
     skill: ios-superpowers
     args: plan [sprint description]
```

**Change 3: Phase 3 Execution (~line 513)**

Replace:
```markdown
2. **Invoke superpowers:execute-plan**

   ```
   Tool: SlashCommand
   Command: /superpowers:execute-plan
```

With:
```markdown
2. **Invoke ios-superpowers execute**

   ```
   Tool: Skill
   Parameters:
     skill: ios-superpowers
     args: execute [plan from Phase 2]
```

**Change 4: Phase 4 Code Review (~line 556)**

Replace:
```markdown
1. **Invoke code reviewer**

   ```
   Tool: Skill
   Parameters:
     skill: superpowers:requesting-code-review
   ```
```

With:
```markdown
1. **Invoke code reviewer via ios-superpowers**

   ```
   Tool: Skill
   Parameters:
     skill: ios-superpowers
     args: review
   ```
```

**Step 3: Apply edits using Edit tool**

(Multiple edits needed - see detailed changes in execution)

**Step 4: Commit**

```bash
git add .claude/skills/ios-sprint-executor/SKILL.md
git commit -m "$(cat <<'EOF'
refactor(skills): update ios-sprint-executor to use ios-superpowers

- Phase 1.5: Use ios-superpowers brainstorm instead of raw superpowers:brainstorm
- Phase 2: Use ios-superpowers plan instead of /superpowers:write-plan
- Phase 3: Use ios-superpowers execute instead of /superpowers:execute-plan
- Phase 4: Use ios-superpowers review instead of superpowers:requesting-code-review

All superpowers interactions now go through ios-superpowers orchestrator.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Update dispatch.md Command

**Files:**
- Modify: `.claude/commands/dispatch.md`

**Step 1: Read current file (already read above)**

**Step 2: Update superpowers references for iOS work**

Find lines 45-50, 83-88 that reference `superpowers:systematic-debugging` and `superpowers:test-driven-development`.

Update to use ios-superpowers when dispatching iOS work:

**Change at line ~44-50:**

Replace:
```markdown
     4. Instructions to:
       1. Read the spec document
       2. Use `superpowers:systematic-debugging` if it's a bug
       3. Use `superpowers:test-driven-development` when implementing the fix
```

With:
```markdown
     4. Instructions to:
       1. Read the spec document
       2. **For iOS bugs**: Use `ios-superpowers debug` (ensures Apple docs grounding)
       3. **For non-iOS bugs**: Use `superpowers:systematic-debugging`
       4. **For iOS features**: Use `ios-superpowers tdd` when implementing the fix
       5. **For non-iOS features**: Use `superpowers:test-driven-development`
```

**Change at lines ~83-88:**

Replace:
```markdown
Use superpowers:systematic-debugging and superpowers:test-driven-development skills.
```

With:
```markdown
For iOS work: Use ios-superpowers debug and ios-superpowers tdd skills.
For non-iOS work: Use superpowers:systematic-debugging and superpowers:test-driven-development skills.
```

**Step 3: Apply edits using Edit tool**

**Step 4: Commit**

```bash
git add .claude/commands/dispatch.md
git commit -m "$(cat <<'EOF'
refactor(commands): update dispatch to use ios-superpowers for iOS work

- iOS bugs use ios-superpowers debug (ensures Apple docs grounding)
- iOS features use ios-superpowers tdd
- Non-iOS work continues using raw superpowers skills
- Add clear decision criteria for iOS vs non-iOS work

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Update README.md

**Files:**
- Modify: `.claude/commands/README.md`

**Step 1: Replace with consolidated content**

```markdown
# Claude Code Commands

Custom slash commands for the Abundance MVP project.

## Available Commands

### iOS Development (REQUIRED: ios-superpowers)

**CRITICAL:** For ALL iOS/Swift work, use `/ios-superpowers` instead of raw superpowers skills.

#### `/ios-superpowers <action> <context>`

iOS-aware orchestrator that ensures Apple documentation is fetched before any superpowers workflow.

**Actions:**
| Action | Example | Replaces |
|--------|---------|----------|
| `brainstorm <topic>` | `/ios-superpowers brainstorm biometric auth` | `superpowers:brainstorming` |
| `plan <feature>` | `/ios-superpowers plan camera capture` | `superpowers:writing-plans` |
| `execute <plan-path>` | `/ios-superpowers execute docs/plans/xxx.md` | `superpowers:executing-plans` |
| `review` | `/ios-superpowers review` | `superpowers:requesting-code-review` |
| `debug <issue>` | `/ios-superpowers debug CI failure` | `superpowers:systematic-debugging` |
| `tdd <feature>` | `/ios-superpowers tdd HouseholdItemDetector` | `superpowers:test-driven-development` |
| `parallel <tasks>` | `/ios-superpowers parallel "task1, task2"` | `superpowers:dispatching-parallel-agents` |

**See**: `.claude/commands/ios-superpowers.md`

---

#### `/ios-sprint-executor {sprint-number}`

Orchestrate iOS sprint development with ios-superpowers integration.

**Example**: `/ios-sprint-executor sprint-1`

**Note**: Uses ios-superpowers orchestrator internally for all superpowers interactions.

**See**: `.claude/skills/ios-sprint-executor/SKILL.md`

---

#### `/verified-stage-development stage-X.Y`

Orchestrate stage development with research verification and approval gates.

**Example**: `/verified-stage-development stage-6.2`

**Note**: iOS stages (2.2, 3.1, 4.1) use ios-superpowers; non-iOS stages use raw superpowers.

**See**: `.claude/skills/verified-stage-development/SKILL.md`

---

#### `/apple-docs-fetcher {query}`

Fetch Apple Developer documentation via MCP.

**Example**: `/apple-docs-fetcher SwiftUI.View`

**See**: `.claude/skills/apple-docs-fetcher/SKILL.md`

---

### Project Management Commands

#### `/validate-docs`

Run documentation validator to check for broken links and stale content.

**Example**: `/validate-docs`

**Uses**: `.claude/agents/doc-reviewer.md` agent specification

---

#### `/check-drift`

Check for architecture drift from ADRs with severity-based reporting (P0/P1/P2).

**Example**: `/check-drift`

**Uses**: `.claude/agents/drift-detector.md` agent specification

---

#### `/show-sprint-status`

Display current sprint progress from git branch and sprint plan.

**Example**: `/show-sprint-status`

---

### Issue Management Commands

#### `/capture-issue`

Capture bugs, UX issues, or spec drift during testing.

**Example**: `/capture-issue "Camera preview shows black screen on iOS 17"`

**See**: `.claude/skills/capture-issue/SKILL.md`

---

#### `/enrich-issue {issue-file}`

Post-capture issue enrichment with log analysis and Apple docs.

**Example**: `/enrich-issue .claude/.debug/issues/raw/2026-01-13-camera-black-screen.json`

**See**: `.claude/commands/enrich-issue.md`

---

#### `/triage-issues`

Triage and prioritize captured issues.

**Example**: `/triage-issues`

**See**: `.claude/commands/triage-issues.md`

---

#### `/dispatch`

Dispatch parallel agents for independent tasks.

**Example**: `/dispatch`

**Note**: For iOS work, agents use ios-superpowers; for non-iOS work, agents use raw superpowers.

**See**: `.claude/commands/dispatch.md`

---

## Command Architecture

Commands in this project follow two patterns:

### Skill-Based Commands

Commands that invoke project-specific skills:
- Command file (`.claude/commands/feature.md`) invokes skill via Skill tool
- Skill file (`.claude/skills/feature-name/SKILL.md`) contains full implementation
- **iOS commands**: Use ios-superpowers orchestrator for Apple docs grounding

### Standalone Commands

Commands that use agent specifications:
- Commands invoke Claude Code's conversational interface directly
- Agent specifications (`.claude/agents/*.md`) guide Claude's behavior
- No external skill dependencies (portable to any repo)

## Integration with CI/CD

Some commands are also invoked by GitHub Actions:

- `/validate-docs` → Runs in `docs-auto-update.yml` workflow
- `/check-drift` → Runs in `security-pr-review.yml` workflow

See `.github/workflows/` for automation configurations.

## References

- **Best Practices**: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands
- **Skill Documentation**: `.claude/skills/*/SKILL.md`
- **Agent Specifications**: `.claude/agents/*.md`
- **Context Map**: `docs/context-map.json`
```

**Step 2: Commit**

```bash
git add .claude/commands/README.md
git commit -m "$(cat <<'EOF'
docs(commands): update README to reflect ios-superpowers consolidation

- Remove super-code-review and troubleshoot (deleted)
- Add ios-superpowers as primary iOS workflow entry point
- Document all available ios-superpowers actions
- Update ios-sprint-executor, verified-stage-development, dispatch notes
- Add capture-issue, enrich-issue, triage-issues commands

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Verify No Broken References

**Step 1: Search for references to removed commands**

```bash
grep -r "super-code-review" .claude/ --include="*.md"
grep -r "/troubleshoot" .claude/ --include="*.md"
```

Expected: No matches (or only this plan file).

**Step 2: Search for raw superpowers references that should use ios-superpowers**

```bash
grep -r "superpowers:brainstorming\|superpowers:writing-plans\|superpowers:executing-plans\|superpowers:requesting-code-review\|superpowers:systematic-debugging\|superpowers:test-driven-development" .claude/commands/ .claude/skills/ --include="*.md" | grep -v "ios-superpowers.md"
```

Expected: Only ios-superpowers.md should contain these (as the orchestrator that delegates to them).

**Step 3: Fix any remaining references (if found)**

If issues found, fix them and commit.

---

## Task 10: Final Verification

**Step 1: List remaining commands**

```bash
ls -la .claude/commands/
```

Expected files (11 total):
- `README.md`
- `apple-docs-fetcher.md`
- `check-drift.md`
- `dispatch.md`
- `enrich-issue.md`
- `ios-sprint-executor.md`
- `ios-superpowers.md`
- `show-sprint-status.md`
- `triage-issues.md`
- `validate-docs.md`
- `verified-stage-development.md`

**Step 2: List remaining skills**

```bash
ls -la .claude/skills/
```

Expected directories (4 total):
- `apple-docs-fetcher/`
- `capture-issue/`
- `ios-sprint-executor/`
- `verified-stage-development/`

**Step 3: Verify git status**

```bash
git status
```

Expected: Clean working tree (except for docs/ symlink issue which is expected).

---

## Summary of All Changes

| Action | File | Reason |
|--------|------|--------|
| DELETE | `.claude/commands/super-code-review.md` | Duplicates `/ios-superpowers review` |
| DELETE | `.claude/commands/troubleshoot.md` | Duplicates `/ios-superpowers debug` |
| UPDATE | `.claude/commands/verified-stage-development.md` | Use ios-superpowers for iOS stages |
| UPDATE | `.claude/commands/ios-sprint-executor.md` | Clarify ios-superpowers delegation |
| UPDATE | `.claude/commands/dispatch.md` | Use ios-superpowers for iOS work |
| UPDATE | `.claude/commands/README.md` | Reflect all changes |
| UPDATE | `.claude/skills/verified-stage-development/SKILL.md` | Delegate to ios-superpowers for iOS stages |
| UPDATE | `.claude/skills/ios-sprint-executor/SKILL.md` | Delegate all superpowers to ios-superpowers |
| VERIFY | All `.claude/**/*.md` | No broken references |

---

## Post-Refactor Architecture

```
.claude/
├── commands/
│   ├── README.md                    # Index (UPDATED)
│   ├── ios-superpowers.md           # PRIMARY iOS entry point (orchestrator)
│   ├── apple-docs-fetcher.md        # Direct Apple docs fetch
│   ├── ios-sprint-executor.md       # Sprint orchestration (UPDATED - uses ios-superpowers)
│   ├── verified-stage-development.md # Stage orchestration (UPDATED - uses ios-superpowers for iOS)
│   ├── capture-issue.md             # Issue capture
│   ├── enrich-issue.md              # Issue enrichment
│   ├── triage-issues.md             # Issue triage
│   ├── dispatch.md                  # Agent dispatch (UPDATED - uses ios-superpowers for iOS)
│   ├── check-drift.md               # ADR compliance
│   ├── show-sprint-status.md        # Sprint status
│   └── validate-docs.md             # Doc validation
│
└── skills/
    ├── apple-docs-fetcher/          # Apple docs MCP integration
    ├── capture-issue/               # Issue capture workflow
    ├── ios-sprint-executor/         # Sprint execution (UPDATED - uses ios-superpowers)
    └── verified-stage-development/  # Stage verification (UPDATED - uses ios-superpowers for iOS)
```

---

## Execution Order

1. Task 1: Delete super-code-review.md
2. Task 2: Delete troubleshoot.md
3. Task 3: Update verified-stage-development.md command
4. Task 4: Update verified-stage-development/SKILL.md
5. Task 5: Update ios-sprint-executor.md command
6. Task 6: Update ios-sprint-executor/SKILL.md
7. Task 7: Update dispatch.md command
8. Task 8: Update README.md
9. Task 9: Verify no broken references
10. Task 10: Final verification

---

**Plan complete. Ready for execution.**

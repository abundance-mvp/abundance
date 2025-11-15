# Claude Commands & Skills Audit and Refactor Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Audit and refactor all Claude commands and skills to follow official best practices with proper Skill tool invocation pattern.

**Architecture:** Commands invoke skills via Skill tool. Skills contain full implementation logic with comprehensive documentation. Follows pattern from official Anthropic documentation and frontend-development example.

**Tech Stack:** Claude Code commands (Markdown), Claude Code skills (Markdown with YAML frontmatter)

---

## Background

**Problem**: Current commands don't follow best practices:
- Commands describe what to do but don't invoke the Skill tool
- Some "commands" are actually skills without corresponding command files
- Inconsistent patterns between spec-kit and abundance-scaffold commands
- Missing integration with superpowers plugin patterns

**Best Practice Pattern** (from https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands and frontend-development example):

**Command file** (`.claude/commands/feature-name.md`):
```markdown
Orchestrate [feature] with [capabilities].

Invoke the Skill tool with skill="feature-name" to dispatch a specialized agent that will:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Task: $ARGUMENTS

If no arguments provided, [default behavior].
```

**Skill file** (`.claude/skills/feature-name/SKILL.md`):
```markdown
---
name: feature-name
aliases: [alt-name-1, alt-name-2]
description: One-line description
---

# Feature Name

Comprehensive documentation...

## Parameters
## Process
## Error Handling
```

---

## Audit Results

### Files to Refactor

**spec-kit/.claude/commands/**:
1. `ios-sprint-executor.md` - ❌ Doesn't invoke Skill tool
2. `verified-stage-development.md` - ❌ Doesn't invoke Skill tool
3. `apple-docs-fetcher.md` - ❌ Doesn't invoke Skill tool

**spec-kit/.claude/skills/**:
1. `ios-sprint-executor/SKILL.md` - ⚠️ Exists, needs review for best practices
2. `verified-stage-development/SKILL.md` - ⚠️ Exists, needs review
3. `apple-docs-fetcher/SKILL.md` - ⚠️ Exists, needs review
4. `apple-docs-fetcher-lite/SKILL.md` - ⚠️ Exists, needs review

**abundance-scaffold/.claude/commands/**:
1. `validate-docs.md` - ❌ Says "invokes agent" but doesn't (should be command that calls Claude Code)
2. `check-drift.md` - ❌ Says "invokes agent" but doesn't
3. `show-sprint-status.md` - ❌ Describes behavior but doesn't implement

**abundance-scaffold/.claude/agents/**:
1. `doc-reviewer.md` - ✅ Agent definition (correct location)
2. `drift-detector.md` - ✅ Agent definition (correct location)
3. `cost-watchdog.md` - ✅ Agent definition (correct location)

### Architecture Decisions

**Decision 1**: Abundance scaffold commands should NOT invoke skills
- **Rationale**: Scaffold is a template for abundance-mvp repo. Skills live in spec-kit (project repo). Commands in scaffold should invoke agents directly or provide instructions for manual actions.
- **Impact**: Refactor scaffold commands to be standalone or reference local agents

**Decision 2**: Spec-kit commands should invoke spec-kit skills
- **Rationale**: Follows best practice pattern. Commands are entry points, skills contain logic.
- **Impact**: All spec-kit commands must use Skill tool invocation

**Decision 3**: Add SlashCommand integration examples
- **Rationale**: Frontend-development example shows integration with superpowers plugin via SlashCommand tool
- **Impact**: Skills that orchestrate workflows should document SlashCommand tool usage

---

## Task Breakdown

### Task 1: Refactor spec-kit Commands (ios-sprint-executor)

**Files:**
- Modify: `.claude/commands/ios-sprint-executor.md`
- Reference: `.claude/skills/ios-sprint-executor/SKILL.md`

**Step 1: Read current command**

Current content:
```markdown
Use the `/ios-sprint-executor` skill to develop iOS code and documentation.
```

**Step 2: Read current skill**

```bash
cat .claude/skills/ios-sprint-executor/SKILL.md | head -50
```

**Step 3: Write new command following best practice**

Create: `.claude/commands/ios-sprint-executor.md`

```markdown
Orchestrate iOS sprint development with superpowers integration, Apple docs fetching, and quality gates.

Invoke the Skill tool with skill="ios-sprint-executor" to dispatch a specialized iOS development agent that will:
1. Load sprint plan and context from docs/roadmap/SPRINT-PLAN-{N}.md
2. Fetch relevant Apple documentation via apple-docs-fetcher skill
3. Create implementation plan via `/superpowers:write-plan`
4. Get your approval before proceeding
5. Execute plan via `/superpowers:execute-plan` with quality checkpoints
6. Generate review checkpoint for completed work

Sprint: $ARGUMENTS

If no arguments provided, show available sprints from docs/roadmap/ROADMAP-001-mvp-implementation-timeline.md.

Examples:
- `/ios-sprint-executor 1` - Execute Sprint 1
- `/ios-sprint-executor 2` - Execute Sprint 2
```

**Step 4: Verify skill has proper frontmatter**

Check: `.claude/skills/ios-sprint-executor/SKILL.md`

Should have:
```yaml
---
name: ios-sprint-executor
aliases: [sprint-executor, ios-sprint]
description: Orchestrates iOS sprint development with superpowers integration and quality gates
---
```

**Step 5: Update skill to reference SlashCommand tool**

If skill uses `/superpowers:write-plan` or `/superpowers:execute-plan`, ensure it documents:

```markdown
## Integration with Superpowers

This skill invokes superpowers plugin commands via SlashCommand tool:

**Planning phase:**
```
Tool: SlashCommand
Parameters:
  command: "/superpowers:write-plan"
```

**Execution phase:**
```
Tool: SlashCommand
Parameters:
  command: "/superpowers:execute-plan"
```
```

**Step 6: Test command**

Run in Claude Code:
```
/ios-sprint-executor 1
```

Expected: Skill tool invoked, sprint 1 context loaded

**Step 7: Commit**

```bash
git add .claude/commands/ios-sprint-executor.md
git add .claude/skills/ios-sprint-executor/SKILL.md
git commit -m "refactor(ios-sprint-executor): follow command/skill best practices

- Command now invokes Skill tool correctly
- Added sprint number parameter handling
- Added examples and default behavior
- Skill updated with SlashCommand integration docs

Refs: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands"
```

---

### Task 2: Refactor spec-kit Commands (verified-stage-development)

**Files:**
- Modify: `.claude/commands/verified-stage-development.md`
- Reference: `.claude/skills/verified-stage-development/SKILL.md`

**Step 1: Read current command**

```bash
cat .claude/commands/verified-stage-development.md
```

**Step 2: Write new command following best practice**

Create: `.claude/commands/verified-stage-development.md`

```markdown
Orchestrate stage development with research verification, planning, execution, and approval gates.

Invoke the Skill tool with skill="verified-stage-development" to dispatch a stage orchestration agent that will:
1. Load required context from docs/context-map.json for the specified stage
2. Research & verify technical claims (creates RESEARCH-VALIDATION-stage-X.Y.md)
3. Create implementation plan via `/superpowers:write-plan`
4. Gate 1: Get your approval before execution
5. Execute plan via `/superpowers:execute-plan` with batch review
6. Gate 2: Generate checkpoint and validate against master documents

Stage: $ARGUMENTS

Examples:
- `/verified-stage-development stage-5.3` - Execute Stage 5.3
- `/verified-stage-development stage-6.2` - Execute Stage 6.2

See docs/context-map.json for available stages and their status.
```

**Step 3: Update skill documentation**

Ensure skill has:
- YAML frontmatter with name, aliases, description
- Clear integration points with superpowers
- Error handling section
- Examples section

**Step 4: Test command**

```
/verified-stage-development stage-6.4
```

Expected: Context map loaded, stage 6.4 prerequisites checked

**Step 5: Commit**

```bash
git add .claude/commands/verified-stage-development.md
git add .claude/skills/verified-stage-development/SKILL.md
git commit -m "refactor(verified-stage-development): follow command/skill best practices

- Command now invokes Skill tool correctly
- Added stage parameter handling with examples
- Updated skill with comprehensive documentation
- Added SlashCommand integration patterns

Refs: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands"
```

---

### Task 3: Refactor spec-kit Commands (apple-docs-fetcher)

**Files:**
- Modify: `.claude/commands/apple-docs-fetcher.md`
- Reference: `.claude/skills/apple-docs-fetcher/SKILL.md`

**Step 1: Read current files**

```bash
cat .claude/commands/apple-docs-fetcher.md
cat .claude/skills/apple-docs-fetcher/SKILL.md | head -50
```

**Step 2: Write new command**

Create: `.claude/commands/apple-docs-fetcher.md`

```markdown
Fetch Apple Developer documentation using MCP server with context map guidance.

Invoke the Skill tool with skill="apple-docs-fetcher" to dispatch a documentation agent that will:
1. Parse requested API/framework from arguments
2. Check docs/apple-context-map.json for recommended documentation paths
3. Use MCP tool (mcp__sosumi__fetchAppleDocumentation) to fetch docs
4. Format as markdown for use in implementation
5. Cache locally in docs/apple/ for future reference

Query: $ARGUMENTS

Examples:
- `/apple-docs-fetcher SwiftUI.View` - Fetch SwiftUI View documentation
- `/apple-docs-fetcher AVFoundation.AVCaptureSession` - Fetch camera session docs
- `/apple-docs-fetcher LAContext` - Fetch biometric auth docs

If no arguments provided, list available documentation categories from docs/apple-context-map.json.
```

**Step 3: Verify skill uses MCP tools correctly**

Check skill documents MCP integration:

```markdown
## MCP Integration

This skill uses the sosumi MCP server to fetch Apple documentation:

**Search for docs:**
```
Tool: mcp__sosumi__searchAppleDocumentation
Parameters:
  query: "SwiftUI View"
```

**Fetch specific doc:**
```
Tool: mcp__sosumi__fetchAppleDocumentation
Parameters:
  path: "/documentation/swiftui/view"
```
```

**Step 4: Test command**

```
/apple-docs-fetcher SwiftUI.View
```

Expected: MCP tool invoked, documentation fetched

**Step 5: Commit**

```bash
git add .claude/commands/apple-docs-fetcher.md
git add .claude/skills/apple-docs-fetcher/SKILL.md
git commit -m "refactor(apple-docs-fetcher): follow command/skill best practices

- Command now invokes Skill tool correctly
- Added query parameter with examples
- Skill updated with MCP tool integration docs
- Added context map reference

Refs: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands"
```

---

### Task 4: Refactor abundance-scaffold Commands (validate-docs)

**Files:**
- Modify: `abundance-scaffold/.claude/commands/validate-docs.md`
- Reference: `abundance-scaffold/.claude/agents/doc-reviewer.md`

**Step 1: Understand purpose**

Current: "Invokes the doc-reviewer agent"

**Analysis**: This is a scaffold template. The command will be copied to abundance-mvp repo. It should NOT invoke a skill (skills live in spec-kit). It should either:
- Provide instructions for manual invocation
- Invoke a Claude Code workflow directly
- Reference the agent definition

**Step 2: Write new command**

Create: `abundance-scaffold/.claude/commands/validate-docs.md`

```markdown
Run documentation validator to check for broken links, stale content, and missing sections.

This command uses Claude Code's conversational interface to analyze documentation:

1. Reviews all Markdown files in docs/
2. Checks for broken internal links
3. Identifies stale documents (>90 days since last update)
4. Validates required sections in ADRs, PRDs, design docs
5. Reports file:line locations with recommended fixes

Usage:
```
/validate-docs
```

When this command runs, Claude will:
- Load the doc-reviewer agent specification from `.claude/agents/doc-reviewer.md`
- Scan the entire docs/ directory
- Generate a validation report

Expected output:
```
❌ docs/adr/ADR-010.md:15 → Broken link: ../design/AUTH-001.md
⚠️  docs/design/DESIGN-003.md → Stale (last updated 120 days ago)
✅ docs/specs/PRD-001.md → All checks passed
```

To fix issues:
1. Review the validation report
2. Update broken links to point to existing files
3. Refresh stale documents with current information
4. Re-run `/validate-docs` to verify fixes

Agent Specification: `.claude/agents/doc-reviewer.md`
```

**Step 3: Update agent reference**

Ensure `abundance-scaffold/.claude/agents/doc-reviewer.md` has clear specification for what Claude should do when this command is invoked.

**Step 4: Test command**

Create test in abundance-scaffold:
```bash
mkdir -p abundance-scaffold/docs/test
echo "[Broken](nonexistent.md)" > abundance-scaffold/docs/test/test.md
```

Run: `/validate-docs`

Expected: Claude analyzes docs using agent specification

**Step 5: Commit**

```bash
git add abundance-scaffold/.claude/commands/validate-docs.md
git add abundance-scaffold/.claude/agents/doc-reviewer.md
git commit -m "refactor(scaffold): update validate-docs command for standalone usage

- Command now provides clear usage instructions
- Explains how Claude uses doc-reviewer agent
- No dependency on spec-kit skills (scaffold is standalone)
- Added examples and expected output

Refs: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands"
```

---

### Task 5: Refactor abundance-scaffold Commands (check-drift)

**Files:**
- Modify: `abundance-scaffold/.claude/commands/check-drift.md`
- Reference: `abundance-scaffold/.claude/agents/drift-detector.md`

**Step 1: Write new command**

Create: `abundance-scaffold/.claude/commands/check-drift.md`

```markdown
Check codebase for architecture drift from ADRs and design documents.

This command uses Claude Code's conversational interface with severity-based reporting:

1. Loads all ADR constraints from docs/adr/
2. Scans codebase for violations (Swift, TypeScript, rules)
3. Assigns severity: P0 (blocks PR), P1 (requires approval), P2 (warn)
4. Reports file:line locations with fix suggestions

Usage:
```
/check-drift
```

When this command runs, Claude will:
- Load the drift-detector agent specification from `.claude/agents/drift-detector.md`
- Scan ios/, backend/, and configuration files
- Generate a drift report with severity levels

Expected output:
```
🚫 P0 VIOLATION (BLOCKS PR):
  File: ios/Views/LoginView.swift:3
  Rule: ADR-010 (SwiftUI-only architecture)
  Found: import UIKit
  Fix: Replace UIKit components with SwiftUI equivalents

⚠️  P1 VIOLATION (REQUIRES REVIEW):
  File: Package.swift:12
  Rule: ADR-015 (Dependency approval process)
  Found: Unauthorized dependency 'Alamofire'
  Fix: Open ADR to justify or use URLSession per ADR-007

ℹ️  P2 WARNING:
  File: ios/Models/User.swift:25
  Rule: ADR-020 (Naming conventions)
  Found: Variable 'usr_id' violates camelCase rule
  Fix: Rename to 'userId'
```

Severity Levels:
- **P0**: CI fails, PR blocked - fix immediately
- **P1**: CI passes with warning, requires 1 additional approval
- **P2**: Informational only, trending tracked in retros

Integration with CI:
This command is also invoked by the drift-detector GitHub Action on PR creation.
See: `.github/workflows/security-pr-review.yml`

Agent Specification: `.claude/agents/drift-detector.md`
```

**Step 2: Ensure agent has P0/P1/P2 rules**

Verify `abundance-scaffold/.claude/agents/drift-detector.md` documents:
- How to assign severity levels
- Which ADRs map to which severity
- Example violations for each level

**Step 3: Test command**

```
/check-drift
```

Expected: Claude scans for ADR violations using agent spec

**Step 4: Commit**

```bash
git add abundance-scaffold/.claude/commands/check-drift.md
git add abundance-scaffold/.claude/agents/drift-detector.md
git commit -m "refactor(scaffold): update check-drift command with severity levels

- Command explains P0/P1/P2 severity system
- Added usage instructions and examples
- References CI integration workflow
- Standalone command (no spec-kit dependency)

Refs: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands"
```

---

### Task 6: Refactor abundance-scaffold Commands (show-sprint-status)

**Files:**
- Modify: `abundance-scaffold/.claude/commands/show-sprint-status.md`

**Step 1: Understand purpose**

Current: Describes output format but doesn't implement

**Analysis**: This command should parse sprint plan files and git status to show progress. No agent needed - this is a data aggregation command.

**Step 2: Write new command**

Create: `abundance-scaffold/.claude/commands/show-sprint-status.md`

```markdown
Display current sprint progress and remaining tasks.

This command analyzes sprint plan and git branch status to show completion:

1. Detects current sprint from active git branch (e.g., `feature/sprint-2-camera-layer-1`)
2. Loads sprint plan from docs/roadmap/SPRINT-PLAN-{N}.md
3. Checks git commit history for completed tasks
4. Displays progress with task status

Usage:
```
/show-sprint-status
```

When this command runs, Claude will:
- Run: `git branch --show-current` to detect active sprint
- Load: `docs/roadmap/SPRINT-PLAN-{N}.md` (parsed from branch name)
- Check: `git log --oneline` for task completion markers
- Display: Formatted progress report

Expected output:
```
Sprint 2: Camera Capture & Vision Layer 1
Progress: 75% (6/8 tasks complete)

✅ Task 1: CameraView UI (commit: a3b2c1d)
✅ Task 2: CameraViewModel (commit: b4c3d2e)
✅ Task 3: VisionService (commit: c5d4e3f)
✅ Task 4: Barcode detection (commit: d6e5f4g)
⏳ Task 5: Unit tests (in progress, branch: feature/sprint-2-tests)
⏳ Task 6: Integration tests (pending)
⏳ Task 7: SwiftLint fixes (pending)
⏳ Task 8: PR creation (pending)

Current branch: feature/sprint-2-camera-layer-1
Commits this sprint: 12
Files changed: 18

Next steps:
1. Complete Task 5 (unit tests)
2. Run Task 6 (integration tests)
3. Fix any SwiftLint warnings (Task 7)
4. Create PR for review (Task 8)
```

Task Completion Detection:
Claude looks for commit messages matching patterns:
- `feat(task-1): ...` or `Task 1: ...` → Task 1 complete
- `test(task-5): ...` → Task 5 complete

Sprint Plan Format:
Sprint plans should list tasks as:
```markdown
### Task 1: Component Name
**Status**: Pending | In Progress | Complete
```

If no active sprint branch detected:
```
No active sprint detected.

Available sprints:
1. Sprint 1: Project Scaffolding
2. Sprint 2: Camera Capture & Vision Layer 1
3. Sprint 3: AI Pipeline Integration

To start a sprint:
1. Create branch: git checkout -b feature/sprint-N-name
2. Load sprint plan: docs/roadmap/SPRINT-PLAN-N.md
3. Begin tasks following DEVELOPMENT-WORKFLOW-003.md
```
```

**Step 3: Test command**

Create test branch:
```bash
git checkout -b feature/sprint-2-test
```

Run: `/show-sprint-status`

Expected: Claude detects sprint 2, loads SPRINT-PLAN-002.md, shows progress

**Step 4: Commit**

```bash
git add abundance-scaffold/.claude/commands/show-sprint-status.md
git commit -m "refactor(scaffold): implement show-sprint-status command

- Command now has full implementation instructions
- Explains task completion detection via commit messages
- Added examples for both active sprint and no-sprint scenarios
- Documents sprint plan format requirements

Refs: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands"
```

---

### Task 7: Add README to Commands Directories

**Files:**
- Create: `.claude/commands/README.md` (spec-kit)
- Create: `abundance-scaffold/.claude/commands/README.md` (scaffold)

**Step 1: Create spec-kit README**

Create: `.claude/commands/README.md`

```markdown
# Claude Code Commands

Custom slash commands for the Abundance spec-kit project.

## Available Commands

### `/ios-sprint-executor {sprint-number}`

Orchestrate iOS sprint development with superpowers integration.

**Example**: `/ios-sprint-executor 1`

**Invokes**: `ios-sprint-executor` skill

**See**: `.claude/skills/ios-sprint-executor/SKILL.md`

---

### `/verified-stage-development stage-X.Y`

Orchestrate stage development with research verification and approval gates.

**Example**: `/verified-stage-development stage-6.2`

**Invokes**: `verified-stage-development` skill

**See**: `.claude/skills/verified-stage-development/SKILL.md`

---

### `/apple-docs-fetcher {query}`

Fetch Apple Developer documentation via MCP.

**Example**: `/apple-docs-fetcher SwiftUI.View`

**Invokes**: `apple-docs-fetcher` skill

**See**: `.claude/skills/apple-docs-fetcher/SKILL.md`

---

## Command Pattern

All commands follow this pattern:

**Command file** (`.claude/commands/feature.md`):
```markdown
Orchestrate [feature] with [capabilities].

Invoke the Skill tool with skill="feature-name" to dispatch...
```

**Skill file** (`.claude/skills/feature-name/SKILL.md`):
```yaml
---
name: feature-name
description: One-line description
---

# Full Implementation
...
```

## Integration with Superpowers

Many skills integrate with the superpowers plugin via SlashCommand tool:
- `/superpowers:write-plan` - Create implementation plans
- `/superpowers:execute-plan` - Execute plans with batch review

See individual skill documentation for integration details.

## References

- **Best Practices**: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands
- **Skill Documentation**: `.claude/skills/*/SKILL.md`
- **Context Map**: `docs/context-map.json`
```

**Step 2: Create abundance-scaffold README**

Create: `abundance-scaffold/.claude/commands/README.md`

```markdown
# Claude Code Commands (Abundance Scaffold)

Custom slash commands for the Abundance MVP project (template from scaffold).

## Available Commands

### `/validate-docs`

Run documentation validator to check for broken links and stale content.

**Example**: `/validate-docs`

**Uses**: `.claude/agents/doc-reviewer.md` agent specification

**Output**: File:line locations of issues with fix suggestions

---

### `/check-drift`

Check for architecture drift from ADRs with severity-based reporting (P0/P1/P2).

**Example**: `/check-drift`

**Uses**: `.claude/agents/drift-detector.md` agent specification

**Output**: Violations categorized by severity

---

### `/show-sprint-status`

Display current sprint progress from git branch and sprint plan.

**Example**: `/show-sprint-status`

**Uses**: Git status + docs/roadmap/SPRINT-PLAN-{N}.md

**Output**: Task completion percentage with next steps

---

## Command Architecture

These commands are **standalone** and do not depend on skills from spec-kit:

- Commands invoke Claude Code's conversational interface
- Agent specifications (`.claude/agents/*.md`) guide Claude's behavior
- No external skill dependencies (portable to any repo)

## Integration with CI/CD

Some commands are also invoked by GitHub Actions:

- `/validate-docs` → Runs in `docs-auto-update.yml` workflow
- `/check-drift` → Runs in `security-pr-review.yml` workflow

See `.github/workflows/` for automation configurations.

## References

- **Best Practices**: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands
- **Agent Specifications**: `.claude/agents/*.md`
- **CI/CD Architecture**: `docs/tech-stack/GITHUB-ACTIONS-ARCHITECTURE-001.md`
```

**Step 3: Commit**

```bash
git add .claude/commands/README.md
git add abundance-scaffold/.claude/commands/README.md
git commit -m "docs(commands): add README for command directories

- Explains available commands in both repos
- Documents command/skill pattern
- References agent specifications
- Notes CI/CD integration

Helps developers understand command architecture"
```

---

### Task 8: Update CLAUDE-CODE-AUTOMATION-001 Documentation

**Files:**
- Modify: `abundance-scaffold/docs/tech-stack/CLAUDE-CODE-AUTOMATION-001.md`

**Step 1: Read current documentation**

```bash
cat abundance-scaffold/docs/tech-stack/CLAUDE-CODE-AUTOMATION-001.md | grep -A 20 "## 5 Plugin Types"
```

**Step 2: Add Command/Skill Best Practices Section**

Add after the "## 5 Plugin Types" section:

```markdown
## Command/Skill Best Practices

**Pattern**: Commands invoke skills via Skill tool. Skills contain implementation.

### Command Structure

**Location**: `.claude/commands/feature-name.md`

**Format**:
```markdown
Orchestrate [feature] with [capabilities].

Invoke the Skill tool with skill="feature-name" to dispatch a specialized agent that will:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Task: $ARGUMENTS

If no arguments provided, [default behavior].

Examples:
- `/feature-name arg1` - [Description]
- `/feature-name arg2` - [Description]
```

### Skill Structure

**Location**: `.claude/skills/feature-name/SKILL.md`

**Format**:
```yaml
---
name: feature-name
aliases: [alt-name-1, alt-name-2]
description: One-line description
---

# Feature Name

Comprehensive documentation...

## Parameters

[Parameter documentation]

## Process

### Phase 1: Context Collection
[Steps...]

### Phase 2: Planning
[Steps...]

## Error Handling

[Error scenarios and recovery]

## References

[Links to related docs]
```

### Integration with Superpowers

Skills that orchestrate multi-step workflows should integrate with superpowers plugin:

**Invoke /superpowers:write-plan**:
```
Tool: SlashCommand
Parameters:
  command: "/superpowers:write-plan"
```

**Invoke /superpowers:execute-plan**:
```
Tool: SlashCommand
Parameters:
  command: "/superpowers:execute-plan"
```

**Pattern**: Skill coordinates workflow, superpowers handles plan creation/execution.

### Standalone Commands (Scaffold)

Commands in `abundance-scaffold/.claude/commands/` are **standalone**:
- No skill dependencies (portable)
- Use agent specifications (`.claude/agents/*.md`)
- Can be copied to any project

**Example**: `/validate-docs`
- Reads: `.claude/agents/doc-reviewer.md`
- Analyzes: `docs/` directory
- Reports: File:line issues

**Example**: `/check-drift`
- Reads: `.claude/agents/drift-detector.md`
- Scans: Codebase for ADR violations
- Reports: P0/P1/P2 severity violations

### Testing Commands

**Manual test**:
```
/command-name arg1
```

**Verify**:
- Command invokes Skill tool (or agent for standalone)
- Arguments passed correctly
- Expected output produced

**CI test** (if applicable):
- Command runs in GitHub Actions workflow
- Exit codes correct (0 = success, 1 = failure)
- Output captured in logs
```

**Step 3: Commit**

```bash
git add abundance-scaffold/docs/tech-stack/CLAUDE-CODE-AUTOMATION-001.md
git commit -m "docs(automation): add command/skill best practices section

- Explains command/skill pattern with examples
- Documents Skill tool invocation
- Covers standalone command pattern (scaffold)
- Adds SlashCommand integration examples

Refs: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands"
```

---

### Task 9: Create Verification Script

**Files:**
- Create: `scripts/verify-commands.sh` (spec-kit)

**Step 1: Write verification script**

Create: `scripts/verify-commands.sh`

```bash
#!/bin/bash
# Verify Claude Code Commands/Skills Follow Best Practices

set -e

echo "🔍 Verifying Claude Code Commands & Skills..."
echo ""

ERRORS=0

# Check spec-kit commands
echo "Checking spec-kit commands..."
for cmd in .claude/commands/*.md; do
  if [ -f "$cmd" ]; then
    cmd_name=$(basename "$cmd" .md)
    echo "  📄 $cmd_name"

    # Check if command invokes Skill tool
    if ! grep -q "Invoke the Skill tool" "$cmd"; then
      echo "    ❌ Missing 'Invoke the Skill tool' pattern"
      ((ERRORS++))
    else
      echo "    ✅ Invokes Skill tool"
    fi

    # Check if corresponding skill exists
    if [ ! -d ".claude/skills/$cmd_name" ]; then
      echo "    ⚠️  Warning: No matching skill directory found"
    else
      echo "    ✅ Matching skill exists"

      # Check skill has SKILL.md
      if [ ! -f ".claude/skills/$cmd_name/SKILL.md" ]; then
        echo "    ❌ Missing SKILL.md in skill directory"
        ((ERRORS++))
      else
        echo "    ✅ SKILL.md found"

        # Check skill has YAML frontmatter
        if ! head -1 ".claude/skills/$cmd_name/SKILL.md" | grep -q "^---$"; then
          echo "    ❌ Missing YAML frontmatter in SKILL.md"
          ((ERRORS++))
        else
          echo "    ✅ YAML frontmatter present"
        fi
      fi
    fi
  fi
done
echo ""

# Check abundance-scaffold commands
echo "Checking abundance-scaffold commands..."
for cmd in abundance-scaffold/.claude/commands/*.md; do
  if [ -f "$cmd" ]; then
    cmd_name=$(basename "$cmd" .md)
    echo "  📄 $cmd_name"

    # Scaffold commands should NOT invoke Skill tool (standalone)
    if grep -q "Invoke the Skill tool" "$cmd"; then
      echo "    ⚠️  Warning: Scaffold command should be standalone (not invoke Skill tool)"
    else
      echo "    ✅ Standalone command (correct for scaffold)"
    fi

    # Check if references agent
    if grep -q ".claude/agents/" "$cmd"; then
      echo "    ✅ References agent specification"
    fi
  fi
done
echo ""

# Summary
if [ $ERRORS -eq 0 ]; then
  echo "✅ All checks passed!"
  exit 0
else
  echo "❌ Found $ERRORS error(s)"
  exit 1
fi
```

**Step 2: Make executable**

```bash
chmod +x scripts/verify-commands.sh
```

**Step 3: Test script**

```bash
./scripts/verify-commands.sh
```

Expected: Report on all commands/skills with pass/fail status

**Step 4: Add to CI**

Create: `.github/workflows/verify-commands.yml`

```yaml
name: Verify Claude Code Commands

on:
  pull_request:
    paths:
      - ".claude/commands/**"
      - ".claude/skills/**"
      - "abundance-scaffold/.claude/commands/**"

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run verification script
        run: ./scripts/verify-commands.sh
```

**Step 5: Commit**

```bash
chmod +x scripts/verify-commands.sh
git add scripts/verify-commands.sh
git add .github/workflows/verify-commands.yml
git commit -m "ci: add command/skill verification script

- Checks all commands invoke Skill tool correctly
- Verifies matching skill directories exist
- Validates YAML frontmatter in skills
- Runs in CI on command/skill changes

Ensures commands follow best practices"
```

---

### Task 10: Final Documentation Update

**Files:**
- Modify: `abundance-scaffold/README.md`

**Step 1: Add commands section**

Add after "## What's Included" section:

```markdown
### Commands (`/command-name`)

| Command | Purpose | References |
|---------|---------|------------|
| `/validate-docs` | Check docs for broken links, stale content | `.claude/agents/doc-reviewer.md` |
| `/check-drift` | ADR compliance with P0/P1/P2 severity | `.claude/agents/drift-detector.md` |
| `/show-sprint-status` | Display sprint progress | `docs/roadmap/SPRINT-PLAN-*.md` |

**Usage**:
```
/validate-docs
/check-drift
/show-sprint-status
```

**See**: `.claude/commands/README.md` for full documentation
```

**Step 2: Commit**

```bash
git add abundance-scaffold/README.md
git commit -m "docs(scaffold): add commands section to README

- Lists available Claude Code commands
- Shows usage examples
- References agent specifications

Makes commands discoverable for new users"
```

---

## Acceptance Criteria

### All Commands

- [ ] Every command in spec-kit invokes Skill tool correctly
- [ ] Every command has examples and default behavior documented
- [ ] Every command has matching skill with YAML frontmatter
- [ ] Abundance-scaffold commands are standalone (no Skill tool dependency)
- [ ] README files exist in both command directories

### Skills

- [ ] All skills have YAML frontmatter with name, aliases, description
- [ ] Skills that orchestrate workflows document SlashCommand integration
- [ ] Skills have comprehensive Process and Error Handling sections
- [ ] Skills reference relevant documentation and ADRs

### Documentation

- [ ] CLAUDE-CODE-AUTOMATION-001 has best practices section
- [ ] Abundance-scaffold README lists commands
- [ ] Verification script exists and passes

### Testing

- [ ] All commands tested manually (`/command-name`)
- [ ] Verification script runs in CI
- [ ] No errors reported by verify-commands.sh

---

## Rollout Plan

1. **Phase 1**: Refactor spec-kit commands (Tasks 1-3)
   - Least risk, highest impact
   - Establishes pattern for others

2. **Phase 2**: Refactor scaffold commands (Tasks 4-6)
   - Standalone pattern different from spec-kit
   - Ensures portability

3. **Phase 3**: Documentation (Tasks 7-8)
   - READMEs and best practices
   - Makes changes discoverable

4. **Phase 4**: CI Integration (Tasks 9-10)
   - Verification script
   - Prevents regression

**Timeline**: 2-3 hours total (can execute in one session)

---

## References

- **Official Best Practices**: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands
- **Frontend Development Example**: Provided in task description
- **Current CLAUDE-CODE-AUTOMATION-001**: `abundance-scaffold/docs/tech-stack/CLAUDE-CODE-AUTOMATION-001.md`
- **Superpowers Plugin**: Installed via Claude Code marketplace

---

**Plan Created**: 2025-11-14
**Total Tasks**: 10
**Estimated Time**: 2-3 hours
**Prerequisites**: None (can start immediately)

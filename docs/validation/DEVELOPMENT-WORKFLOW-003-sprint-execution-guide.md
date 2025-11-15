# DEVELOPMENT-WORKFLOW-003: Sprint Execution Guide

## Sprint Lifecycle (via ios-sprint-executor)

```
SETUP → PLAN → APPROVE → EXECUTE → REVIEW → PR → CLEANUP
```

The ios-sprint-executor skill orchestrates this 7-phase lifecycle automatically with human approval gates.

---

## Phase 1: Setup (Pre-Sprint)

**Duration**: 2-5 minutes
**Automated by**: ios-sprint-executor Phase 1

### Actions

1. **Load sprint plan**
   - File: `docs/roadmap/SPRINT-PLAN-00X.md`
   - Validates: Sprint plan exists, has theme, deliverables, dependencies

2. **Detect iOS work**
   - Scans for keywords: Vision, SwiftUI, AVFoundation, UIKit, Combine, CoreML
   - Scans for APIs: VNCoreMLRequest, AVCaptureSession, @MainActor, @Observable
   - Result: `ios_work_detected = true/false`

3. **Fetch Apple documentation** (if iOS work detected)
   - Uses: `apple-docs-fetcher-lite` skill (NOT full fetcher)
   - Strategy: Extract 3-5 focused APIs from sprint plan
   - Token budget: 8K per API max, 25K total max
   - Output: `docs/apple/sprint-X-api-verification.md` (concise summaries)

4. **Create git worktree** (optional but recommended)
   - Path: `../abundance-sprint-X/`
   - Branch: `feature/sprint-X-description`
   - Uses: `superpowers:using-git-worktrees` skill (if available)

5. **Create feature branch**
   - Naming: `feature/sprint-X-description`
   - Example: `feature/sprint-2-camera-capture-vision`

### Output

```
Phase 1: Pre-Sprint Setup - COMPLETE

Environment:
- Sprint: 2 (Camera Capture & Vision Layer 1)
- iOS work: YES (Vision Framework, AVFoundation)
- Apple docs: FETCHED (7.6K tokens, 4 APIs)
- Branch: feature/sprint-2-camera-capture-vision
- Worktree: ../abundance-sprint-2/

Ready for planning...
```

---

## Phase 2: Planning (Superpowers Integration)

**Duration**: 5-10 minutes
**Automated by**: ios-sprint-executor Phase 2

### Actions

1. **Load context documents**
   - From sprint plan: ADRs, DESIGN docs, CODE-EXAMPLEs, TEST-EXAMPLEs
   - Apple docs verification summary (if iOS sprint)
   - Token tracking: Should be 18K-25K total per sprint plan

2. **Build enhanced instructions**
   - Sprint objectives from SPRINT-PLAN-00X
   - Reference Stage 4 scaffolding (Package.swift, firebase.json, ai-provider-adapters)
   - Enforce TDD workflow (test first, watch fail, implement, watch pass)
   - Cross-reference documentation in code comments

3. **Invoke /superpowers:write-plan**
   - Input: All context documents + enhanced instructions
   - Output: Detailed implementation plan with tasks, batches, token budget
   - Plan includes: Background, tasks, batch grouping, acceptance criteria, dependencies

### Output

```
Phase 2: Planning - COMPLETE

Implementation plan created:
- Tasks: 12 total (grouped into 4 batches)
- Token budget: 22K (within 25K limit)
- Batch 1 (8K): CameraView UI
- Batch 2 (10K): VisionService implementation
- Batch 3 (6K): Barcode detection
- Batch 4 (4K): Unit tests

Plan includes cross-references to:
- 3 ADRs (ADR-010, ADR-011, ADR-013)
- 5 DESIGN docs (DESIGN-027, DESIGN-013, etc.)
- 3 CODE-EXAMPLEs (CODE-EXAMPLE-004, etc.)
- 2 TEST-EXAMPLEs (TEST-EXAMPLE-004, etc.)

Proceeding to Gate 1 (Human Approval)...
```

---

## GATE 1: Human Approval (Post-Planning)

**Purpose**: Human reviews implementation plan before execution begins

### Display

```
═══════════════════════════════════════════════════════════
SPRINT X PLAN READY FOR REVIEW
═══════════════════════════════════════════════════════════

Sprint: X ([sprint name])
Tasks: X total (X batches)
Token budget: XK
Cross-references: X ADRs, X DESIGNs, X CODE-EXAMPLEs

═══════════════════════════════════════════════════════════
NEXT: Execute plan in batches with review checkpoints

Please review the implementation plan.

Type 'proceed' to continue
Type 'revise plan: [feedback]' to regenerate plan
Type 'abort' to stop
═══════════════════════════════════════════════════════════
```

### Human Actions

- **proceed**: Continue to Phase 3 (Execution)
- **revise plan: [feedback]**: Re-run write-plan with feedback, return to Gate 1
- **abort**: Exit gracefully, preserve work in worktree

---

## Phase 3: Execution (Superpowers Batch Processing)

**Duration**: 2-4 hours (varies by sprint complexity)
**Automated by**: ios-sprint-executor Phase 3

### Actions

1. **Invoke /superpowers:execute-plan**
   - Input: Implementation plan from Phase 2 + all context documents
   - Execution mode: Batches with human review checkpoints
   - TDD workflow enforced: Test first → fail → implement → pass

2. **Execute tasks in batches**
   - Batch 1: First set of tasks (typically UI/structure)
   - Report for review
   - Batch 2: Next set (typically services/business logic)
   - Report for review
   - Batch 3: Integration/glue code
   - Report for review
   - Batch 4: Tests and final polish
   - Report for review

3. **Cross-reference documentation**
   - Code comments reference ADRs: `// See ADR-XXX for rationale`
   - Code comments reference DESIGNs: `// Implements DESIGN-XXX pattern`
   - Code comments reference tests: `// Tested per TEST-EXAMPLE-XXX`

### Output (per batch)

```
Batch 1 Complete: CameraView UI

Implemented:
- CameraView.swift (120 lines)
- CameraViewModel.swift (85 lines)
- CameraViewModelTests.swift (65 lines)

Tests: 8/8 passing (100%)
Build: ✅ PASSING
SwiftLint: ✅ PASSING

Ready for feedback on Batch 1 before proceeding to Batch 2.
```

### Final Output

```
Phase 3: Execution - COMPLETE

Sprint X implementation complete:
✅ Batch 1: CameraView UI (8K tokens, 45 min)
✅ Batch 2: VisionService (10K tokens, 1.2 hours)
✅ Batch 3: Barcode detection (6K tokens, 40 min)
✅ Batch 4: Unit tests (4K tokens, 30 min)

Files created/modified: 18
Tests added: 24 (87% coverage)
Build status: ✅ PASSING

Proceeding to Phase 4 (Code Review)...
```

---

## Phase 4: Code Review (Superpowers Quality Gate)

**Duration**: 5-10 minutes
**Automated by**: ios-sprint-executor Phase 4

### Actions

1. **Invoke superpowers:requesting-code-review**
   - Dispatch: `superpowers:code-reviewer` subagent
   - Reviews: Implementation vs. plan, ADR compliance, test coverage, code quality

2. **Validation checks**
   - Implementation matches plan ✓
   - Follows ADR patterns (e.g., ADR-010 MVVM, ADR-012 State Management) ✓
   - Test coverage adequate (80%+) ✓
   - Code quality (no lint errors) ✓
   - No security issues ✓

3. **Address feedback** (if issues found)
   - Fix issues immediately
   - Re-run tests
   - Re-run code review
   - Repeat until clean

### Output

```
Phase 4: Code Review - COMPLETE

Code review passed:
✅ Implementation matches plan
✅ Follows ADR-010 (MVVM), ADR-011 (modules), ADR-013 (DI)
✅ Test coverage: 87% (exceeds 80% target)
✅ No lint errors
✅ No security issues

Reviewer comments: [summary of positive findings]

Proceeding to Phase 5 (PR Creation)...
```

---

## Phase 5: PR Creation (Automated)

**Duration**: 1-2 minutes
**Automated by**: ios-sprint-executor Phase 5

### Actions

1. **Commit changes**
   ```bash
   git add .
   git commit -m "feat(sprint-X): implement [sprint description]

   - Task 1: [description]
   - Task 2: [description]
   - Task 3: [description]

   Closes #X (if sprint task issue exists)

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

2. **Push branch**
   ```bash
   git push -u origin feature/sprint-X-{description}
   ```

3. **Generate PR body**
   - Uses: `.github/PULL_REQUEST_TEMPLATE/sprint.md`
   - Fills in: Sprint reference, documentation cross-references, success criteria, testing evidence, agent execution summary

4. **Create PR**
   ```bash
   gh pr create --title "Sprint X: [Sprint Description]" --body "[generated body]"
   ```

### Output

```
Phase 5: PR Creation - COMPLETE

Pull Request Created:
🔗 https://github.com/user/repo/pull/XX

PR Details:
- Branch: feature/sprint-2-camera-capture-vision
- Commits: 4 (squashed from batches)
- Files changed: 18
- Tests added: 24
- Documentation cross-references: 8 (3 ADRs, 5 DESIGN docs)

Next Steps:
1. Wait for CI checks to pass (iOS build, lint, tests)
2. Request human review (1+ approvals required)
3. Merge when approved
```

---

## Phase 6: Completion & Cleanup

**Duration**: 1 minute
**Automated by**: ios-sprint-executor Phase 6

### Actions

1. **Display completion banner**
   ```
   ═══════════════════════════════════════════════════════════
   ✅ SPRINT X COMPLETE
   ═══════════════════════════════════════════════════════════

   Summary:
   - Sprint: X ([sprint name])
   - Implementation: COMPLETE (3.5 hours)
   - Code Review: PASSED
   - PR Created: #XX
   - CI Status: ⏳ Running

   Sprint Artifacts:
   - 18 files created/modified
   - 24 unit tests (87% coverage)
   - 8 documentation cross-references
   - Apple docs verified (4 APIs)

   Next Sprint: X+1 ([next sprint name])

   Run: /ios-sprint-executor sprint-X+1
   ═══════════════════════════════════════════════════════════
   ```

2. **Optional: Git worktree cleanup** (after PR merged)
   ```bash
   # After PR merged, clean up worktree
   cd [original directory]
   git worktree remove ../abundance-sprint-X/
   git branch -d feature/sprint-X-{description}
   ```

---

## Usage

### Execute a Sprint

```bash
/ios-sprint-executor sprint-1
/ios-sprint-executor sprint-2
/ios-sprint-executor sprint-3
...
```

The skill handles all 7 phases automatically with human approval gates at:
- Gate 1: After planning, before execution

### Skip iOS Work Detection

If sprint has NO iOS work (e.g., backend-only sprint):
- Skill automatically detects (no iOS keywords found)
- Skips Apple docs fetching
- Proceeds directly to planning

### Manual Worktree Management

If NOT using worktrees:
- Skill creates feature branch in current directory
- Use `git checkout` to switch branches manually

---

## Sprint Metrics Tracking

After each sprint, track:

### Time Metrics
- Planning time: X minutes
- Execution time: X hours (per batch)
- Code review time: X minutes
- Total time: X hours

### Token Metrics
- Context loading: XK tokens
- Apple docs: XK tokens (if iOS)
- Planning: XK tokens
- Execution: XK tokens (per batch)
- Total: XK tokens

### Code Metrics
- Files created/modified: X
- Lines of code added: X
- Tests added: X
- Test coverage: X%

### Quality Metrics
- Code review issues: X
- Lint errors: X
- Build failures: X (should be 0)

---

## Troubleshooting

### "Sprint plan not found"
```
ERROR: Sprint plan not found.

Expected: docs/roadmap/SPRINT-PLAN-00X.md

Run Stage 5.1 first to generate sprint plans:
/verified-stage-development stage-5.1
```

**Fix**: Run Stage 5.1 to create sprint plans

### "Apple docs fetch failed"
```
ERROR: Apple documentation fetch failed.

iOS work detected but apple-docs-fetcher-lite failed.

Options:
1. Type 'retry' to re-run apple-docs-fetcher-lite
2. Type 'skip' to continue without Apple docs (NOT RECOMMENDED)
3. Type 'abort' to stop
```

**Fix**: Retry (usually transient network issue) or check MCP connection

### "Token budget exceeded"
```
ERROR: Token budget exceeded.

Sprint token budget: 25K
Context loaded: 28.5K (over limit by 3.5K)

Possible causes:
- Too many documents loaded from sprint plan
- Apple docs fetch exceeded 25K limit

Recommendation: Reduce apple-docs-fetcher-lite scope (fewer APIs)
```

**Fix**: Reduce number of Apple APIs fetched (focus on 3-5 most critical)

### "Superpowers plugin not installed"
```
ERROR: Superpowers plugin not installed.

This skill requires the superpowers plugin.

Install via:
1. Visit marketplace: https://claude.ai/marketplace
2. Search for "superpowers"
3. Click "Install"
4. Restart Claude Code
5. Retry: /ios-sprint-executor sprint-X
```

**Fix**: Install Superpowers plugin from Claude marketplace

### "Git branch already exists"
```
WARNING: Branch already exists: feature/sprint-X-{description}

Options:
1. Type 'continue' to use existing branch (continue sprint work)
2. Type 'new branch: [name]' to create different branch
3. Type 'abort' to stop
```

**Fix**: Choose 'continue' to resume sprint, or create new branch with different name

---

## References

- ios-sprint-executor skill: `.claude/skills/ios-sprint-executor/SKILL.md`
- Superpowers plugin: https://claude.ai/marketplace (search "superpowers")
- Git worktrees: `superpowers:using-git-worktrees` skill
- Sprint plans: `docs/roadmap/SPRINT-PLAN-001.md` through `SPRINT-PLAN-008.md`
- PR template: `.github/PULL_REQUEST_TEMPLATE/sprint.md`

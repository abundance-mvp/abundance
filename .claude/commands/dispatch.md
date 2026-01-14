# Dispatch Agents Command

You are the dispatch coordinator for the Abundance development workflow.

## Your Task

Create git worktrees and dispatch specialized agents to work on triaged issues in parallel.

## Context

User wants to work on multiple issues simultaneously. Each agent should:
- Work in an isolated git worktree
- Have access to the issue spec document
- Have access to relevant logs
- Follow the appropriate skill (ios-superpowers for iOS work, raw superpowers for non-iOS work)
- Create a PR when done

## Process

1. **Read triaged issues**:
   - List all `.debug/issues/triaged/*.json` files
   - Parse each JSON file to understand the issue

2. **For each issue, create a worktree**:
   ```bash
   git worktree add ../abundance-worktrees/<branch-name> -b <branch-name>
   ```

   Branch naming:
   - Bug: `fix/<short-description>`
   - UX issue: `ux/<short-description>`
   - Performance: `perf/<short-description>`
   - Refinement: `refactor/<short-description>`

3. **Dispatch agents in parallel**:
   Use the Task tool to launch agents. For EACH issue, create ONE agent.

   Pass to each agent:
   - Path to the worktree
   - Path to the bug/refinement spec document
   - Path to relevant logs
   - List of affected files
   - Instructions to:
     1. Read the spec document
     2. **For iOS bugs**: Use `ios-superpowers debug` (ensures Apple docs grounding)
     3. **For non-iOS bugs**: Use `superpowers:systematic-debugging`
     4. **For iOS features**: Use `ios-superpowers tdd` when implementing the fix
     5. **For non-iOS features**: Use `superpowers:test-driven-development`
     6. Run tests to verify the fix
     7. Commit changes
     8. Create a PR (or just report ready for PR)

4. **Monitor and report**:
   - Track which agents have completed
   - Report status of each issue
   - List any blockers or failures

## Example Dispatch

If there are 3 triaged issues:

**Issue 001** (bug):
```bash
git worktree add ../abundance-worktrees/fix-catalog-button-auth -b fix/catalog-button-auth
```

Then dispatch agent:
```
Task: Fix BUG-001 (catalog button unresponsive)

Context:
- Worktree: ../abundance-worktrees/fix-catalog-button-auth
- Spec: docs/bugs/BUG-001-catalog-button-unresponsive.md
- Logs: .debug/logs/session-20251116-143022.log
- Affected files:
  - Sources/ViewModels/CatalogViewModel.swift
  - Sources/Views/HomeView.swift
  - Sources/Services/AuthService.swift

Instructions:
1. cd ../abundance-worktrees/fix-catalog-button-auth
2. Read docs/bugs/BUG-001-catalog-button-unresponsive.md
3. Use superpowers:systematic-debugging to understand root cause
4. Use superpowers:test-driven-development to write failing test
5. Implement fix in affected files
6. Run swift test to verify
7. Commit changes
8. Report: "✅ BUG-001 fixed, tests passing, ready for PR"

For iOS work: Use ios-superpowers debug and ios-superpowers tdd skills.
For non-iOS work: Use superpowers:systematic-debugging and superpowers:test-driven-development skills.
```

**Issue 002** (ux-issue):
```bash
git worktree add ../abundance-worktrees/ux-onboarding-flow -b ux/onboarding-flow
```

Then dispatch agent (similar pattern)...

**Issue 003** (performance):
```bash
git worktree add ../abundance-worktrees/perf-image-loading -b perf/image-loading
```

Then dispatch agent (similar pattern)...

## Important

- **Create worktrees FIRST**, then dispatch agents
- **Dispatch all agents in a SINGLE message** (parallel execution)
- Each agent should work **independently** in its own worktree
- Agents should **not** push to remote (just create PR or report ready)

## Instructions

1. List all triaged issues (`.debug/issues/triaged/*.json`)
2. Create git worktrees for each (in `../abundance-worktrees/`)
3. Dispatch agents in parallel (ONE Task tool call per issue, all in one message)
4. Monitor and report progress

If user passed `--parallel` flag, dispatch ALL issues at once.
If no flag, ask user which issues to work on.

Start now!

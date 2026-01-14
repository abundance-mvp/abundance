# iOS Sprint Executor Skill

## Overview

The `ios-sprint-executor` skill orchestrates deterministic agentic development for Abundance MVP sprints by wrapping the superpowers plugin with automatic Apple documentation fetching for iOS work.

## Key Features

1. **Automatic iOS Detection**: Scans sprint plans for iOS-specific keywords (Vision, SwiftUI, AVFoundation, etc.)
2. **Apple Docs Integration**: Automatically fetches Apple documentation using apple-docs-fetcher pattern (8K per API, 25K max)
3. **Superpowers Orchestration**: Wraps `/superpowers:write-plan` → `/superpowers:execute-plan` workflow
4. **Token Budget Enforcement**: Ensures 18K-25K token budget per sprint
5. **Git Workflow Integration**: Creates feature branches, commits, and PRs following Stage 5.2 patterns
6. **Code Review Integration**: Uses `superpowers:requesting-code-review` after execution

## Usage

```
/ios-sprint-executor sprint-2
```

This will:
1. Load sprint plan (docs/roadmap/SPRINT-PLAN-002.md)
2. Detect iOS work (Vision Framework, AVFoundation)
3. Fetch Apple docs (VNCoreMLRequest, AVCaptureSession, etc.)
4. Create feature branch (feature/sprint-2-camera-capture-vision)
5. Run superpowers:write-plan to generate implementation plan
6. Wait for human approval
7. Run superpowers:execute-plan in batches
8. Run code review
9. Create PR with proper template

## Dependencies

- **Superpowers plugin** (required): Must be installed from marketplace
- **apple-docs-fetcher** (required for iOS sprints): Automatically invoked when iOS work detected
- **Stage 5.2 deliverables** (required): Workflow documentation, agent prompts, sprint plans

## Token Budget Strategy

- **Sprint 1-2**: ~20K tokens (iOS-heavy, CODE-EXAMPLEs)
- **Sprint 3**: ~25K tokens (AI pipeline, multiple CODE-EXAMPLEs)
- **Sprint 4-6**: ~18K tokens (UI implementation)
- **Sprint 7-8**: ~15K tokens (testing, polish)

Apple docs are fetched using lite pattern:
- 8K tokens per API max
- 25K tokens total max
- 3-5 focused APIs per sprint (not broad frameworks)

## Relationship to Stage 5.2

This skill implements the development workflow documented in Stage 5.2:

- **DEVELOPMENT-WORKFLOW-001**: Git branching strategy
- **DEVELOPMENT-WORKFLOW-002**: PR creation automation
- **DEVELOPMENT-WORKFLOW-003**: Sprint execution guide
- **IOS-DEVELOPMENT-WORKFLOW-001**: Apple docs integration

## Error Handling

The skill provides clear error messages for:
- Missing sprint plans (run Stage 5.1 first)
- Apple docs fetch failures (retry or skip)
- Token budget exceeded (reduce apple-docs-fetcher scope)
- Superpowers plugin not installed (install from marketplace)
- Git branch conflicts (continue or create new branch)

## Examples

### Sprint 1: iOS Project Setup & Authentication
```
/ios-sprint-executor sprint-1
```
- No iOS framework work (Firebase Auth only)
- No Apple docs needed
- Creates: AuthService, AuthViewModel, unit tests

### Sprint 2: Camera Capture & Vision Layer 1
```
/ios-sprint-executor sprint-2
```
- iOS work: Vision Framework, AVFoundation
- Apple docs: VNCoreMLRequest, AVCaptureSession, Task.detached
- Creates: CameraView, VisionService, barcode detection

### Sprint 3: Backend AI Pipeline
```
/ios-sprint-executor sprint-3
```
- No iOS work (backend only)
- No Apple docs needed
- Creates: Cloud Functions for Layers 2a, 2b, 3

## Development Status

**Status**: Ready for Stage 5.2 execution

This skill is designed to be used after Stage 5.2 completes and all sprint plans, agent prompts, and workflow documentation are generated.

## Related Skills

- `verified-stage-development`: Executes pipeline stages (Stages 1.1 through 6.2)
- `apple-docs-fetcher`: Fetches Apple docs with token budget constraints
- Superpowers plugin skills:
  - `superpowers:write-plan`: Creates implementation plans
  - `superpowers:execute-plan`: Executes plans in batches
  - `superpowers:requesting-code-review`: Reviews code after execution
  - `superpowers:using-git-worktrees`: Creates isolated worktrees for sprint work

## Design Philosophy

This skill guarantees deterministic agentic development by:

1. **Enforcing token budgets** to prevent context overflow
2. **Using apple-docs-fetcher pattern** instead of full apple-docs-fetcher (avoids token explosion)
3. **Following Stage 5.2 workflows** exactly (git, PR, sprint execution)
4. **Automating iOS detection** so developers don't forget to fetch Apple docs
5. **Creating structured PRs** with cross-references to ADRs, DESIGN docs, CODE-EXAMPLEs

This ensures that every sprint execution follows the same pattern, making development predictable and repeatable.

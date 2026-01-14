# DEV-ITERATION-SYSTEM-001: Abundance Fast Iteration & Quality Observatory

**Created**: 2025-11-16
**Status**: Active
**Type**: Development Workflow
**References**: MONITORING-001, TEST-STRATEGY-001, ADR-013

---

## Executive Summary

This document defines the complete iteration and quality assurance system for post-MVP Abundance development. The system enables:

1. **Fast iteration**: Edit code → test on simulator in < 30 seconds
2. **Comprehensive logging**: Capture everything (UI events, Firebase, AI pipeline, spec violations, silent failures)
3. **Issue discovery**: Quick capture of bugs found during manual testing
4. **Automated triage**: AI agents analyze logs and classify issues
5. **Parallel development**: Multiple agents work on different issues simultaneously

**Tech Stack**:
- iOS: AppLogger (OSLog) → local JSON logs
- Scripts: `sim.sh` (fast simulator loop)
- Skills: `capture-issue` (in-session bug capture + enrichment)
- AI Triage: Claude agents analyze logs and create spec documents
- Parallel Dispatch: Git worktrees + parallel agent execution

---

## The Four Layers

### Layer 1: Instrumentation

**Goal**: Log everything that matters for debugging

**iOS AppLogger Framework**:
- File: `Sources/Core/Logging/AppLogger.swift`
- Structured logging (mirrors backend MONITORING-001 pattern)
- Event types:
  - UI interactions (button taps, navigation)
  - Data operations (Firestore queries, loads, failures)
  - AI pipeline (Vision detection, barcode scanning)
  - Authentication (sign-in, token refresh)
  - Spec violations (implementation vs spec)
  - Silent failures (no error but doesn't work)

**Usage**:
```swift
import AppLogger

// Button tap
AppLogger.log(.buttonTapped(button: "Catalog Item", screen: "HomeView"))

// Firestore query
AppLogger.log(.firestoreQueryStarted(collection: "items", filter: "userId == \(uid)"))
AppLogger.log(.firestoreQueryCompleted(collection: "items", resultCount: 10, duration: 0.5))

// Spec violation
if duration > 6.0 {
    AppLogger.log(.specViolation(
        spec: "mvp-vision-features",
        section: "Processing Time",
        expected: "< 6 seconds",
        actual: "\(duration)s",
        severity: .high
    ))
}

// Silent failure
AppLogger.log(.silentFailure(
    feature: "Catalog Button",
    expectedBehavior: "Navigate to camera",
    actualBehavior: "Button tap has no effect",
    reproSteps: ["Open app", "Tap catalog button", "Nothing happens"]
))
```

**Log Output**:
- Development: `.debug/logs/session-<timestamp>.jsonl` (JSON Lines format)
- Production: Firebase Analytics (future)

---

### Layer 2: Spec Verification

**Goal**: Verify implementation matches spec documents

**Spec Assertion Framework**:
- Script: `scripts/extract-spec-assertions.py`
- Extracts testable assertions from spec documents
- Generates:
  - XCTest test cases (automated)
  - Manual testing checklist
  - Runtime assertion helpers

**Adding Assertions to Specs**:

In your spec documents (e.g., `docs/specs/mvp-vision-features.md`), add:

```markdown
## Processing Time

**Behavior**: AI analysis MUST complete within 6 seconds.

```spec-assertions
- ASSERT: Vision detection completes in < 500ms
- ASSERT: Total processing time < 6 seconds
- ASSERT: Loading spinner shown during processing
\```
```

**Generate Tests**:
```bash
python3 scripts/extract-spec-assertions.py
```

**Output**:
- `Tests/Generated/SpecAssertionTests.swift` (automated tests)
- `.debug/manual-testing-checklist.md` (checklist for manual testing)

---

### Layer 3: Health Monitoring

**Goal**: Monitor external dependencies (Firebase, AI APIs, network)

**Health Check Script**:
```bash
./scripts/check-health.sh
```

**Checks**:
- Network connectivity
- Firebase APIs reachable
- GCP service status
- Simulator status
- Recent logs availability
- Unprocessed issues count

**Output**: `.debug/health/health-<timestamp>.json`

**When to Run**:
- Before starting development session
- When experiencing unexplained errors
- Before deploying to staging/production

---

### Layer 4: Issue Discovery & Triage

**Goal**: Capture bugs during testing and dispatch agents to fix them

#### Step 1: Capture Issues (In-Session with Claude)

While testing the app, if you find a bug, tell Claude:
- "capture this issue"
- "file a bug"
- "log this problem"

Claude uses the `capture-issue` skill (`.claude/skills/capture-issue/SKILL.md`) which:

1. **Gathers details** via conversation:
   - What did you expect?
   - What actually happened?
   - Which screen/feature?
   - Issue type (bug/ux/spec-drift/silent-failure/performance/blocker)
   - Related spec document (optional)

2. **Creates raw issue**: `.debug/issues/raw/issue-NNN.md`

3. **Auto-enriches** (in same session):
   - Validates spec reference
   - Parses full log file (errors, warnings, stack traces)
   - Detects iOS frameworks
   - Fetches Apple docs (if iOS detected)
   - Identifies affected files

4. **Writes enriched JSON**: `.debug/issues/enriched/enriched-NNN.json`

**Why skill instead of script**: The old `capture-issue.sh` spawned a subprocess to enrich, which failed due to nested Claude invocation (parent owns terminal). The skill does everything in-session.

#### Step 2: Triage Issues (AI Agent)

When ready to process captured issues:

```bash
claude triage-issues
```

**What it does**:
1. Reads all `.debug/issues/raw/*.md` files
2. Analyzes attached logs
3. Classifies issues (bug/ux/spec-drift/performance)
4. Determines root cause
5. Creates spec documents:
   - `docs/bugs/BUG-NNN.md` (for bugs)
   - `docs/refinements/REF-NNN.md` (for UX issues)
   - `docs/bugs/PERF-NNN.md` (for performance)
6. Moves issues to `.debug/issues/triaged/` with JSON metadata

#### Step 3: Dispatch Agents (Parallel)

Work on multiple issues simultaneously:

```bash
claude dispatch --parallel
```

**What it does**:
1. Reads all `.debug/issues/triaged/*.json` files
2. Creates git worktrees (one per issue):
   - `../abundance-worktrees/fix-<issue>`
   - `../abundance-worktrees/ux-<issue>`
   - `../abundance-worktrees/perf-<issue>`
3. Dispatches specialized agents (in parallel):
   - Each agent works in its own worktree
   - Uses `superpowers:systematic-debugging` for bugs
   - Uses `superpowers:test-driven-development` for fixes
   - Runs tests to verify
   - Creates PR when done

**Agent Output**:
- ✅ BUG-001 fixed, tests passing, PR #42 ready
- ✅ UX-002 improved, PR #43 ready
- ⏳ PERF-003 in progress, needs Apple docs research
- ❌ BUG-004 blocked, need clarification on SPEC-007

---

## Daily Workflow

### Morning Setup

```bash
cd ~/code/abundance-mvp

# Check system health
./scripts/check-health.sh

# Pull latest changes
git checkout main && git pull
```

### Development Loop (Repeat Every Few Minutes)

```bash
# 1. Edit code in VSCode/Cursor
#    ~/code/abundance-mvp/Sources/...

# 2. Test on simulator
./scripts/sim.sh

# 3. Manually test features using checklist
open .debug/manual-testing-checklist.md

# 4. Found a bug? Tell Claude: "capture this issue"
#    Claude uses capture-issue skill (in-session capture + enrichment)

# 5. Continue editing...
```

### End of Day

```bash
# Triage all captured issues
claude triage-issues

# Review triaged issues
ls -la .debug/issues/triaged/

# Dispatch agents to work on them
claude dispatch --parallel

# Agents report back with PRs

# Review PRs, merge when ready
```

---

## File Structure

```
~/code/abundance-mvp/                # PRIMARY (SPM)
├── Sources/
│   └── Core/Logging/
│       ├── AppLogger.swift          # Logging framework
│       └── AppLogger+Examples.swift # Usage examples
├── Tests/
│   └── Generated/
│       └── SpecAssertionTests.swift # Auto-generated from specs
├── .debug/                          # Git-ignored debug artifacts
│   ├── logs/                        # Simulator session logs
│   ├── issues/
│   │   ├── raw/                     # Captured during testing
│   │   ├── enriched/                # Auto-enriched JSON
│   │   ├── triaged/                 # Agent-processed
│   │   └── in-progress/             # Being worked on
│   ├── completed/
│   │   ├── issues/                  # Resolved issues
│   │   └── logs/                    # Completed enrichment logs
│   ├── crashes/                     # Crash reports
│   └── health/                      # Health check results
├── scripts/
│   ├── sim.sh                       # Fast simulator loop
│   ├── check-health.sh              # Health monitoring
│   └── extract-spec-assertions.py   # Spec assertion extractor
├── .claude/skills/
│   └── capture-issue/               # In-session bug capture + enrichment
└── .claude/commands/
    ├── triage-issues.md             # AI triage command
    ├── dispatch.md                  # Parallel dispatch command
    └── troubleshoot.md              # iOS debugging command

~/code/abundance-mvp-xcode/          # SECONDARY (Xcode, ephemeral)
└── Abundance/
    └── Abundance.xcodeproj          # Can regenerate from SPM

~/code/abundance-worktrees/          # AGENT WORKSPACES
├── fix-catalog-button-auth/         # Agent 1 working here
├── ux-onboarding-flow/              # Agent 2 working here
└── perf-image-loading/              # Agent 3 working here
```

### Xcode Project Regeneration

The Xcode project is **ephemeral** and regenerated from the SPM project using XcodeGen.

**When to regenerate**:
- First time setup
- Build failures with duplicate file references
- After adding new source files or resources
- Manually: `./scripts/regenerate-xcode-project.sh`

**Automatic regeneration**:
- `./scripts/sim.sh` auto-detects missing project
- Add `--regenerate` flag to force regeneration

**Configuration**:
- `project.yml` - Declarative Xcode project definition
- Preserves: Team ID, Bundle ID, Info.plist, Firebase config, entitlements

**Critical files** (version controlled in SPM, copied to Xcode):
- `App/Info.plist`
- `App/GoogleService-Info.plist`
- `Abundance/Abundance.entitlements` (generated from project.yml)

---

## Key Commands

| Command | Purpose |
|---------|---------|
| `./scripts/sim.sh` | Run app on simulator with log capture |
| Tell Claude: "capture this issue" | In-session bug capture + enrichment (uses `capture-issue` skill) |
| `./scripts/check-health.sh` | Check Firebase/AI/network status |
| `python3 scripts/extract-spec-assertions.py` | Generate tests from specs |
| `claude triage-issues` | AI agent triages captured issues (uses `apple-docs-fetcher` for iOS) |
| `claude dispatch --parallel` | Dispatch agents to fix issues |
| `claude troubleshoot` | Debug iOS-specific issues (uses `apple-docs-fetcher` MANDATORY) |
| `/super-code-review` | Code review with Apple docs verification (uses `apple-docs-fetcher` for iOS) |

---

## Integration with Existing Workflow

This system **extends** (not replaces) your existing workflow:

- **TEST-STRATEGY-001**: Still use 80/15/5 testing pyramid
- **MONITORING-001**: AppLogger mirrors backend logging patterns
- **ADR-013**: Firebase Analytics/Crashlytics still planned for production
- **verified-stage-development**: Use for new features, this system for maintenance
- **apple-docs-fetcher**: MANDATORY for all iOS code review, debug, and triage workflows

**When to Use What**:
- **New feature development**: `verified-stage-development` skill
- **Bug fixes**: This iteration system (capture → triage → dispatch)
- **Spec updates**: Extract spec assertions after updating docs
- **Testing**: Manual checklist + automated tests

---

## Troubleshooting

**Issue**: `sim.sh` can't find simulator

**Solution**:
```bash
xcrun simctl list devices | grep iPhone
# Use exact name from output
./scripts/sim.sh "iPhone 16 Pro"
```

**Issue**: Logs not being written

**Solution**: Ensure `.debug/logs/` directory exists and AppLogger is integrated

**Issue**: Agents can't create worktrees

**Solution**:
```bash
mkdir -p ~/code/abundance-worktrees
git worktree list  # Check for conflicts
```

---

## Metrics & Success Criteria

**Iteration Speed**:
- ✅ Edit code → running on simulator < 30 seconds
- ✅ Find bug → captured in issue document < 2 minutes

**Issue Resolution**:
- ✅ 80%+ of issues triaged automatically
- ✅ 3+ issues worked on in parallel
- ✅ < 24 hours from bug capture → PR ready

**Quality**:
- ✅ Zero silent failures go unnoticed (AppLogger catches them)
- ✅ All spec violations are logged
- ✅ < 5% spec drift (implementation matches docs)

---

## Future Enhancements

**Phase 2** (Q1 2026):
- Screenshot diffing (visual regression testing)
- Automated spec drift detection (code vs docs)
- Firebase health monitoring (backend checks)
- AI pipeline monitoring (Layer 2/3 health)

**Phase 3** (Q2 2026):
- Production log streaming (Firebase → local analysis)
- Automated performance regression detection
- User-reported issue integration (TestFlight feedback → triage)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-16 | 1.0 | Initial iteration system | AI Infrastructure Agent |

---

**This iteration system enables rapid, high-quality development for Abundance post-MVP.**

# Abundance Iteration System - Quick Reference Card

**Save this for quick access during development!**

---

## 🚀 Fast Iteration Loop (30 seconds)

```bash
# Edit code → test on simulator
./scripts/sim.sh
```

**What happens**:
1. Regenerates Xcode project if needed (cached, instant)
2. Builds app
3. Launches simulator
4. Captures logs to `.debug/logs/`

---

## 🐛 Found a Bug? Capture It!

Tell Claude:
- "capture this issue"
- "file a bug"
- "log this problem"

Claude uses the `capture-issue` skill which:
1. Asks for details (expected, actual, screen, type)
2. Creates raw issue: `.debug/issues/raw/issue-NNN.md`
3. Auto-enriches: `.debug/issues/enriched/enriched-NNN.json`

**Issue types**:
- `bug` - Something is broken
- `ux-issue` - Works but feels wrong
- `spec-drift` - Doesn't match spec
- `silent-failure` - No error but doesn't work
- `performance` - Too slow
- `blocker` - **URGENT** showstopper (use for blocking issues!)

**See**: `docs/dev-workflow/BUG-FILING-WORKFLOW.md` for full workflow details

---

## 🔍 Triage Issues (AI Agent)

```bash
claude triage-issues
```

**What it does**:
- Reads all raw issues
- Analyzes logs
- **iOS issues:** Invokes `apple-docs-fetcher` for API verification (MANDATORY)
- Classifies and creates spec documents
- Moves to `.debug/issues/triaged/`

---

## 🤖 Dispatch Agents (Parallel)

```bash
claude dispatch --parallel
```

**What it does**:
- Creates git worktrees
- Dispatches agents to fix issues
- Each agent works independently
- Reports back with PRs

---

## 🏥 Health Check

```bash
./scripts/check-health.sh
```

**Checks**:
- Network, Firebase, GCP status
- Simulator status
- Recent logs
- Open issues

---

## 🔨 Regenerate Xcode Project

```bash
# Force clean regeneration
./scripts/regenerate-xcode-project.sh

# Or with sim.sh
./scripts/sim.sh --regenerate
```

**When to use**:
- Xcode project corruption
- After editing project.yml
- Build errors that don't make sense

---

## 📝 Spec Assertions

```bash
# After updating spec docs, regenerate tests
python3 scripts/extract-spec-assertions.py
```

**Output**:
- `Tests/Generated/SpecAssertionTests.swift`
- `.debug/manual-testing-checklist.md`

---

## 🆘 Troubleshooting

```bash
claude troubleshoot
```

**Uses**:
- `superpowers:systematic-debugging`
- **iOS issues:** `apple-docs-fetcher` before and after fix (MANDATORY)
- Detects iOS frameworks → fetches Apple docs → debugs → verifies fix

---

## 📝 Code Review

```bash
/super-code-review          # Review current branch
/super-code-review #123     # Review specific PR
```

**What it does**:
- **iOS code:** Invokes `apple-docs-fetcher` for API verification (MANDATORY)
- Uses `superpowers:requesting-code-review`
- Validates against CLAUDE.md and ADRs

---

## 📊 Daily Workflow

**Morning**:
```bash
./scripts/check-health.sh
git checkout main && git pull
```

**Development Loop** (repeat every few minutes):
```bash
# Edit code
./scripts/sim.sh
# Test
# If bug found, tell Claude: "capture this issue"
```

**End of Day**:
```bash
claude triage-issues
claude dispatch --parallel
# Review PRs
```

---

## 📁 Key Directories

- `Sources/Core/Logging/` - AppLogger framework
- `.debug/logs/` - Simulator session logs
- `.debug/issues/raw/` - Captured issues
- `.debug/issues/enriched/` - Enriched issue JSON
- `.debug/issues/triaged/` - Ready for agents
- `.debug/completed/issues/` - Resolved issues
- `docs/bugs/` - Bug specifications
- `~/code/abundance-worktrees/` - Agent workspaces

---

## 🎯 AppLogger Usage

```swift
// UI interaction
AppLogger.log(.buttonTapped(button: "Catalog", screen: "Home"))

// Firestore operation
AppLogger.log(.firestoreQueryStarted(collection: "items", filter: "userId"))

// Spec violation
AppLogger.log(.specViolation(
    spec: "mvp-vision-features",
    section: "Processing Time",
    expected: "< 6s",
    actual: "\(duration)s",
    severity: .high
))

// Silent failure
AppLogger.log(.silentFailure(
    feature: "Navigation",
    expectedBehavior: "Navigate to detail",
    actualBehavior: "Tap has no effect",
    reproSteps: ["Open app", "Tap item", "Nothing happens"]
))
```

---

## 🔧 Common Issues

**Simulator not found**:
```bash
xcrun simctl list devices | grep iPhone
./scripts/sim.sh "iPhone 16 Pro"  # Use exact name
```

**Build failed**:
```bash
# Check logs
cat .debug/logs/session-latest.log | grep "error:"
```

**Health check failed**:
```bash
# Check specific issue
cat .debug/health/health-latest.json | jq .
```

---

## 📖 Full Documentation

See: `docs/dev-workflow/DEV-ITERATION-SYSTEM-001.md`

---

**Questions? Run:** `claude troubleshoot`

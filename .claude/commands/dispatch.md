# Dispatch Agents Command

You are the dispatch coordinator for the Abundance development workflow with **maximum iOS skill grounding** via Axiom agents and ios-superpowers orchestration.

## Your Task

Create git worktrees and dispatch specialized agents to work on triaged issues in parallel, with automatic routing to the most appropriate Axiom agent for each issue type.

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

---

## Axiom Agent Routing Matrix

**CRITICAL:** Use this matrix to select the appropriate Axiom agent for each issue type.

### Build & Environment Issues

| Issue Contains | Axiom Agent | Task Tool subagent_type |
|----------------|-------------|-------------------------|
| "BUILD FAILED", "module not found", "compile error" | Build Fixer | `axiom:build-fixer` |
| "slow build", "build time", "incremental" | Build Optimizer | `axiom:build-optimizer` |
| "SPM", "package resolution", "dependency conflict" | SPM Resolver | `axiom:spm-conflict-resolver` |

### Performance Issues

| Issue Contains | Axiom Agent | Task Tool subagent_type |
|----------------|-------------|-------------------------|
| "memory leak", "retain cycle", "memory warning" | Memory Auditor | `axiom:memory-auditor` |
| "battery", "energy", "power consumption" | Energy Auditor | `axiom:energy-auditor` |
| "slow", "performance", "lag", "frame drop" | Swift Performance | `axiom:swift-performance-analyzer` |
| "SwiftUI slow", "view updates", "janky scroll" | SwiftUI Performance | `axiom:swiftui-performance-analyzer` |

### Concurrency & Threading

| Issue Contains | Axiom Agent | Task Tool subagent_type |
|----------------|-------------|-------------------------|
| "@MainActor", "actor", "Sendable", "data race" | Concurrency Auditor | `axiom:concurrency-auditor` |
| "Swift 6", "strict concurrency", "isolation" | Concurrency Auditor | `axiom:concurrency-auditor` |

### UI/UX Issues

| Issue Contains | Axiom Agent | Task Tool subagent_type |
|----------------|-------------|-------------------------|
| "accessibility", "VoiceOver", "Dynamic Type" | Accessibility Auditor | `axiom:accessibility-auditor` |
| "SwiftUI architecture", "state management", "@State" | SwiftUI Architecture | `axiom:swiftui-architecture-auditor` |
| "navigation", "deep link", "NavigationStack" | SwiftUI Nav Auditor | `axiom:swiftui-nav-auditor` |
| "Liquid Glass", "glass effect", "blur", "material" | Liquid Glass Auditor | `axiom:liquid-glass-auditor` |
| "TextKit", "UITextView", "Writing Tools" | TextKit Auditor | `axiom:textkit-auditor` |
| "iOS 17/18", "deprecated", "modernize" | Modernization Helper | `axiom:modernization-helper` |

### Data & Storage

| Issue Contains | Axiom Agent | Task Tool subagent_type |
|----------------|-------------|-------------------------|
| "Core Data", "migration", "schema" | Core Data Auditor | `axiom:core-data-auditor` |
| "file storage", "documents", "backup" | Storage Auditor | `axiom:storage-auditor` |
| "iCloud", "CloudKit", "sync" | iCloud Auditor | `axiom:icloud-auditor` |
| "Codable", "JSON", "encoding/decoding" | Codable Auditor | `axiom:codable-auditor` |

### Camera & Media

| Issue Contains | Axiom Agent | Task Tool subagent_type |
|----------------|-------------|-------------------------|
| "camera", "AVCapture", "video", "photo" | Camera Auditor | `axiom:camera-auditor` |

### Networking & Security

| Issue Contains | Axiom Agent | Task Tool subagent_type |
|----------------|-------------|-------------------------|
| "networking", "URLSession", "API", "connection" | Networking Auditor | `axiom:networking-auditor` |
| "security", "privacy", "credentials", "keychain" | Security Scanner | `axiom:security-privacy-scanner` |

### Testing Issues

| Issue Contains | Axiom Agent | Task Tool subagent_type |
|----------------|-------------|-------------------------|
| "test fail", "flaky test", "CI fail" | Test Failure Analyzer | `axiom:test-failure-analyzer` |
| "run tests", "XCUITest", "test results" | Test Runner | `axiom:test-runner` |
| "debug test", "fix test" | Test Debugger | `axiom:test-debugger` |
| "test quality", "test audit" | Testing Auditor | `axiom:testing-auditor` |

### In-App Purchase

| Issue Contains | Axiom Agent | Task Tool subagent_type |
|----------------|-------------|-------------------------|
| "IAP", "StoreKit", "purchase", "subscription" | IAP Auditor | `axiom:iap-auditor` |

### Default (General iOS)

| Fallback | Command | Notes |
|----------|---------|-------|
| General iOS question | `/axiom:ask` | Routes to appropriate skill |
| Visual verification needed | `axiom:simulator-tester` | Screenshots + logs |

---

## ios-superpowers Integration

**Every dispatched agent MUST use ios-superpowers** for Apple documentation grounding:

```
ios-superpowers <action> <context>

Actions:
- debug <issue>     # Systematic debugging with Apple docs
- tdd <feature>     # Test-driven development with API verification
- review            # Code review with API compliance check
- plan <feature>    # Implementation planning
```

**Why:** ios-superpowers automatically:
1. Detects iOS APIs in the task (SwiftUI, AVFoundation, Vision, etc.)
2. Fetches Apple documentation via `axiom-apple-docs-research`
3. Selects appropriate Axiom skill for patterns
4. Verifies implementation against docs

---

## Process

### 1. Read triaged issues

```bash
ls .debug/issues/triaged/*.json
```

Parse each JSON file to extract:
- `issue_type`: bug, ux-issue, performance, refinement
- `title`: Short description
- `affected_files`: List of files to modify
- `symptoms`: Error messages, behaviors
- `severity`: P0, P1, P2

### 2. Classify and select Axiom agent

For each issue, use the routing matrix above:

```
IF issue.symptoms contains "BUILD FAILED" OR "module not found":
    axiom_agent = "axiom:build-fixer"
ELSE IF issue.symptoms contains "memory leak" OR "retain cycle":
    axiom_agent = "axiom:memory-auditor"
ELSE IF issue.symptoms contains "@MainActor" OR "Sendable":
    axiom_agent = "axiom:concurrency-auditor"
ELSE IF issue.type == "ux-issue" AND issue.symptoms contains "accessibility":
    axiom_agent = "axiom:accessibility-auditor"
ELSE IF issue.type == "performance":
    axiom_agent = "axiom:swift-performance-analyzer"
ELSE:
    axiom_agent = None  # Use ios-superpowers only
```

### 3. Create worktrees

```bash
git worktree add ../abundance-worktrees/<branch-name> -b <branch-name>
```

Branch naming:
- Bug: `fix/<short-description>`
- UX issue: `ux/<short-description>`
- Performance: `perf/<short-description>`
- Refinement: `refactor/<short-description>`

### 4. Dispatch agents in parallel

Use the Task tool to launch agents. For EACH issue, create ONE agent.

**Agent Prompt Template:**

```markdown
## Task: Fix [ISSUE-ID] - [Title]

### Context
- **Worktree:** ../abundance-worktrees/[branch-name]
- **Spec:** [path to issue spec document]
- **Logs:** [path to relevant logs]
- **Affected Files:**
  - [file1.swift]
  - [file2.swift]

### Axiom Agent Selected
**Agent:** [axiom_agent from routing matrix]
**Reason:** Issue contains [matching keywords]

### Instructions

1. **Navigate to worktree:**
   ```bash
   cd ../abundance-worktrees/[branch-name]
   ```

2. **Read the spec document:**
   ```bash
   cat [path to spec]
   ```

3. **Run Axiom audit (if applicable):**
   Use Task tool with subagent_type="[axiom_agent]" to scan affected files

4. **Debug with ios-superpowers:**
   ```
   ios-superpowers debug "[issue description]"
   ```
   This will:
   - Fetch Apple documentation for detected APIs
   - Apply Axiom patterns for debugging
   - Provide systematic debugging workflow

5. **Implement fix with TDD:**
   ```
   ios-superpowers tdd "[feature/fix description]"
   ```

6. **Verify fix:**
   ```bash
   swift test
   swiftlint
   ```

7. **Commit changes:**
   ```bash
   git add -A
   git commit -m "[type]: [description]"
   ```

8. **Report completion:**
   ```
   ✅ [ISSUE-ID] fixed
   - Axiom agent used: [axiom_agent]
   - Apple docs fetched: [list of APIs]
   - Tests: PASS
   - Ready for PR
   ```

### Important Notes
- ios-superpowers auto-detects iOS APIs and fetches Apple docs
- Axiom agent provides iOS-specific debugging patterns
- Both work together for maximum grounding
```

### 5. Monitor and report

Track which agents have completed and report:
- Status of each issue (in-progress, completed, blocked)
- Axiom agent used for each issue
- Apple docs fetched (if any)
- Any blockers or failures

---

## Example Dispatch

### Scenario: 3 triaged issues

**Issue 001** (bug - build failure):
```json
{
  "id": "BUG-001",
  "type": "bug",
  "title": "Module 'AVFoundation' not found after Xcode update",
  "symptoms": "BUILD FAILED - No such module 'AVFoundation'",
  "affected_files": ["Sources/CameraFeature/CameraService.swift"]
}
```

**Classification:**
- Symptoms contain "BUILD FAILED", "module not found"
- **Axiom Agent:** `axiom:build-fixer`

**Worktree:**
```bash
git worktree add ../abundance-worktrees/fix-avfoundation-module -b fix/avfoundation-module
```

---

**Issue 002** (ux-issue - accessibility):
```json
{
  "id": "UX-002",
  "type": "ux-issue",
  "title": "VoiceOver doesn't announce item values",
  "symptoms": "VoiceOver skips price labels, accessibility audit failed",
  "affected_files": ["Sources/InventoryFeature/ItemCard.swift"]
}
```

**Classification:**
- Symptoms contain "VoiceOver", "accessibility"
- **Axiom Agent:** `axiom:accessibility-auditor`

**Worktree:**
```bash
git worktree add ../abundance-worktrees/ux-voiceover-prices -b ux/voiceover-prices
```

---

**Issue 003** (performance - memory):
```json
{
  "id": "PERF-003",
  "type": "performance",
  "title": "Memory spike when loading large catalog",
  "symptoms": "Memory warning after loading 500+ items, possible retain cycle",
  "affected_files": ["Sources/InventoryFeature/InventoryViewModel.swift"]
}
```

**Classification:**
- Symptoms contain "memory", "retain cycle"
- **Axiom Agent:** `axiom:memory-auditor`

**Worktree:**
```bash
git worktree add ../abundance-worktrees/perf-memory-catalog -b perf/memory-catalog
```

---

### Dispatch All Three (Single Message)

```
Task 1: Fix BUG-001 (build failure)
- subagent_type: "axiom:build-fixer"
- prompt: [agent template with BUG-001 details]

Task 2: Fix UX-002 (accessibility)
- subagent_type: "axiom:accessibility-auditor"
- prompt: [agent template with UX-002 details]

Task 3: Fix PERF-003 (memory)
- subagent_type: "axiom:memory-auditor"
- prompt: [agent template with PERF-003 details]
```

---

## Axiom Commands Reference

These commands can be used directly by agents or coordinator:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/axiom:status` | Project health dashboard | Before starting, see environment status |
| `/axiom:fix-build` | Diagnose build failures | BUILD FAILED errors |
| `/axiom:optimize-build` | Speed up build times | Slow incremental builds |
| `/axiom:run-tests` | Run and parse test results | After implementing fix |
| `/axiom:screenshot` | Capture simulator screenshot | Visual verification |
| `/axiom:audit <type>` | Run specific audit | Pre-PR quality check |

### Audit Types

```bash
/axiom:audit accessibility     # VoiceOver, Dynamic Type, WCAG
/axiom:audit concurrency       # Swift 6, @MainActor, Sendable
/axiom:audit memory            # Retain cycles, leaks
/axiom:audit swiftui-performance  # View updates, frame drops
/axiom:audit swift-performance # General Swift performance
/axiom:audit security          # Credentials, privacy manifest
/axiom:audit liquid-glass      # iOS 26+ Liquid Glass adoption
/axiom:audit core-data         # Core Data schema, migrations
/axiom:audit storage           # File storage, backup exclusions
/axiom:audit icloud            # CloudKit, iCloud sync
/axiom:audit codable           # JSON encoding/decoding
/axiom:audit camera            # AVCapture, video handling
/axiom:audit networking        # URLSession, API connections
/axiom:audit energy            # Battery, power consumption
/axiom:audit swiftui-nav       # Navigation, deep links
/axiom:audit swiftui-architecture  # State management, patterns
/axiom:audit textkit           # TextKit 2, Writing Tools
/axiom:audit modernization     # Deprecated APIs, iOS 17/18
/axiom:audit testing           # Test quality, coverage
/axiom:audit test-failures     # Flaky tests, CI failures
/axiom:audit iap               # StoreKit, purchases
```

---

## Important Rules

1. **Create worktrees FIRST**, then dispatch agents
2. **Dispatch all agents in a SINGLE message** (parallel execution)
3. Each agent works **independently** in its own worktree
4. Agents should **not** push to remote (just commit, report ready for PR)
5. **Always use ios-superpowers** for Apple docs grounding
6. **Use Axiom agent routing** for iOS-specific patterns

---

## Instructions

1. List all triaged issues (`.debug/issues/triaged/*.json`)
2. Classify each issue using the routing matrix
3. Create git worktrees for each (in `../abundance-worktrees/`)
4. Dispatch agents in parallel (ONE Task tool call per issue, all in one message)
5. Monitor and report progress with Axiom agent + Apple docs summary

**Flags:**
- `--parallel`: Dispatch ALL issues at once
- `--dry-run`: Show routing without dispatching
- No flag: Ask user which issues to work on

Start now!

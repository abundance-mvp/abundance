# iOS Superpowers Enhancement Plan: Axiom Integration

**Date:** 2026-01-16
**Status:** Draft
**Author:** Claude

## Executive Summary

This plan outlines enhancements to the `ios-superpowers` skill to leverage the full capabilities of the Axiom iOS plugin. The goal is to create a robust, domain-aware orchestrator that routes to the most appropriate Axiom agent/skill based on the iOS sub-domain (e.g., Xcode debugging, Liquid Glass, concurrency, etc.).

**Key Changes:**
1. **Remove redundant `apple-docs-fetcher`** - Axiom provides integrated sosumi.ai MCP access
2. **Expand Axiom agent routing** - From 8 skills to 25+ specialized agents
3. **Add domain-specific workflows** - Different actions route to different Axiom capabilities
4. **Improve task classification** - More precise routing based on issue patterns

---

## Current State Analysis

### ios-superpowers Today

```
ios-superpowers
├── Apple Docs (apple-docs-fetcher or apple-docs-fetcher-lite)
│   └── sosumi.ai MCP integration
├── Axiom Skill Selection (8 skills)
│   ├── axiom-xcode-debugging
│   ├── axiom-memory-debugging
│   ├── axiom-swift-concurrency
│   ├── axiom-swiftui-26-ref
│   ├── axiom-liquid-glass
│   ├── axiom-swiftdata
│   ├── axiom-database-migration
│   └── axiom-ui-testing
└── Superpowers Delegation
    ├── brainstorming
    ├── writing-plans
    ├── executing-plans
    ├── requesting-code-review
    ├── systematic-debugging
    ├── test-driven-development
    └── dispatching-parallel-agents
```

### Axiom Plugin Capabilities (Task Tool Agents)

The Axiom plugin provides **25+ specialized agents** via the Task tool's `subagent_type` parameter:

| Category | Axiom Agent | subagent_type |
|----------|-------------|---------------|
| **Build & Environment** | Build Fixer | `axiom:build-fixer` |
| | Build Optimizer | `axiom:build-optimizer` |
| | SPM Conflict Resolver | `axiom:spm-conflict-resolver` |
| **Performance** | Memory Auditor | `axiom:memory-auditor` |
| | Energy Auditor | `axiom:energy-auditor` |
| | Swift Performance Analyzer | `axiom:swift-performance-analyzer` |
| | SwiftUI Performance Analyzer | `axiom:swiftui-performance-analyzer` |
| **Concurrency** | Concurrency Auditor | `axiom:concurrency-auditor` |
| **UI/UX** | Accessibility Auditor | `axiom:accessibility-auditor` |
| | SwiftUI Architecture Auditor | `axiom:swiftui-architecture-auditor` |
| | SwiftUI Navigation Auditor | `axiom:swiftui-nav-auditor` |
| | Liquid Glass Auditor | `axiom:liquid-glass-auditor` |
| | TextKit Auditor | `axiom:textkit-auditor` |
| | Modernization Helper | `axiom:modernization-helper` |
| **Data & Storage** | Core Data Auditor | `axiom:core-data-auditor` |
| | Storage Auditor | `axiom:storage-auditor` |
| | iCloud Auditor | `axiom:icloud-auditor` |
| | Codable Auditor | `axiom:codable-auditor` |
| **Camera & Media** | Camera Auditor | `axiom:camera-auditor` |
| **Networking & Security** | Networking Auditor | `axiom:networking-auditor` |
| | Security Privacy Scanner | `axiom:security-privacy-scanner` |
| **Testing** | Test Failure Analyzer | `axiom:test-failure-analyzer` |
| | Test Runner | `axiom:test-runner` |
| | Test Debugger | `axiom:test-debugger` |
| | Testing Auditor | `axiom:testing-auditor` |
| **IAP** | IAP Auditor | `axiom:iap-auditor` |
| | IAP Implementation | `axiom:iap-implementation` |
| **Utility** | Simulator Tester | `axiom:simulator-tester` |

### Axiom Commands (Slash Commands)

| Command | Purpose |
|---------|---------|
| `/axiom:status` | Project health dashboard |
| `/axiom:fix-build` | Diagnose and fix Xcode build failures |
| `/axiom:optimize-build` | Scan for build performance optimizations |
| `/axiom:run-tests` | Run XCUITests and parse results |
| `/axiom:screenshot` | Capture simulator screenshot |
| `/axiom:test-simulator` | Launch simulator testing agent |
| `/axiom:ask` | Route iOS question to appropriate skill |
| `/axiom:audit <type>` | Run specific audits |

### Overlap Analysis

| Current ios-superpowers | Axiom Equivalent | Action |
|------------------------|------------------|--------|
| `apple-docs-fetcher` | sosumi MCP integrated | **REMOVE** - Use Axiom's built-in sosumi access |
| `apple-docs-fetcher-lite` | sosumi MCP integrated | **REMOVE** - Axiom handles token management |
| `axiom-xcode-debugging` (skill ref) | `axiom:build-fixer` (agent) | **REPLACE** with Task agent |
| `axiom-memory-debugging` (skill ref) | `axiom:memory-auditor` (agent) | **REPLACE** with Task agent |
| `axiom-swift-concurrency` (skill ref) | `axiom:concurrency-auditor` (agent) | **REPLACE** with Task agent |
| `axiom-swiftui-26-ref` (skill ref) | `axiom:swiftui-architecture-auditor` (agent) | **REPLACE** with Task agent |
| `axiom-liquid-glass` (skill ref) | `axiom:liquid-glass-auditor` (agent) | **REPLACE** with Task agent |
| `axiom-swiftdata` (skill ref) | `axiom:core-data-auditor` (agent) | **REPLACE** with Task agent |
| `axiom-database-migration` (skill ref) | `axiom:core-data-auditor` (agent) | **MERGE** into single agent |
| `axiom-ui-testing` (skill ref) | `axiom:test-runner`, `axiom:test-debugger` | **SPLIT** into specialized agents |

---

## Enhancement Plan

### Phase 1: Remove Redundant Apple Docs Fetching

**Problem:** ios-superpowers currently invokes `apple-docs-fetcher` separately, but Axiom already has integrated sosumi.ai MCP access.

**Solution:**
- Remove explicit `apple-docs-fetcher` invocations from ios-superpowers
- Add instruction to use Axiom's integrated sosumi MCP calls directly
- Keep fallback to WebFetch for sosumi.ai API when MCP unavailable

**Changes:**
1. Update `ios-superpowers/SKILL.md` Step 3 to use direct MCP calls
2. Remove references to `apple-docs-fetcher` skill
3. Add note that Axiom agents automatically access sosumi.ai

### Phase 2: Expand Axiom Agent Routing Matrix

**Problem:** Current routing only covers 8 skills. Axiom provides 25+ specialized agents.

**Solution:** Create comprehensive routing matrix by iOS sub-domain.

#### New Routing Matrix

```
ios-superpowers <action> <context>
        │
        ├── debug (systematic debugging)
        │   ├── Build Issues → axiom:build-fixer
        │   ├── Memory Issues → axiom:memory-auditor
        │   ├── Concurrency Issues → axiom:concurrency-auditor
        │   ├── SwiftUI Issues → axiom:swiftui-architecture-auditor
        │   ├── Navigation Issues → axiom:swiftui-nav-auditor
        │   ├── Camera Issues → axiom:camera-auditor
        │   ├── Networking Issues → axiom:networking-auditor
        │   ├── iCloud Issues → axiom:icloud-auditor
        │   ├── IAP Issues → axiom:iap-auditor
        │   └── General → superpowers:systematic-debugging + sosumi docs
        │
        ├── tdd (test-driven development)
        │   ├── Flaky Tests → axiom:test-failure-analyzer
        │   ├── UI Tests → axiom:test-debugger
        │   ├── Test Quality → axiom:testing-auditor
        │   └── General → superpowers:test-driven-development + sosumi docs
        │
        ├── review (code review)
        │   ├── Accessibility → axiom:accessibility-auditor
        │   ├── Concurrency → axiom:concurrency-auditor
        │   ├── Security → axiom:security-privacy-scanner
        │   ├── Performance → axiom:swift-performance-analyzer
        │   ├── SwiftUI Patterns → axiom:swiftui-architecture-auditor
        │   ├── Energy → axiom:energy-auditor
        │   └── General → superpowers:requesting-code-review + sosumi docs
        │
        ├── plan (implementation planning)
        │   ├── IAP Feature → axiom:iap-implementation
        │   ├── Liquid Glass UI → axiom:liquid-glass-auditor (audit first)
        │   ├── Modernization → axiom:modernization-helper
        │   └── General → superpowers:writing-plans + sosumi docs
        │
        ├── execute (implementation)
        │   ├── Run Tests → axiom:test-runner
        │   ├── Simulator Test → axiom:simulator-tester
        │   └── General → superpowers:executing-plans + sosumi docs
        │
        ├── brainstorm (design exploration)
        │   └── Always → superpowers:brainstorming + sosumi docs
        │
        └── parallel (multi-agent dispatch)
            └── Route each task to appropriate Axiom agent
```

### Phase 3: Add Domain-Specific Workflows

Create specialized sub-workflows for common iOS domains:

#### 3.1 Build & Environment Workflow

```
ios-superpowers debug "BUILD FAILED..."
    │
    ├── 1. Run /axiom:status (project health check)
    ├── 2. Classify build issue type
    │   ├── Module not found → axiom:build-fixer
    │   ├── SPM conflict → axiom:spm-conflict-resolver
    │   └── Slow build → axiom:build-optimizer
    ├── 3. Execute Axiom agent
    ├── 4. If unresolved, fetch sosumi docs for framework
    └── 5. Apply fix and verify with swift build
```

#### 3.2 Performance Workflow

```
ios-superpowers debug "slow/memory/battery..."
    │
    ├── 1. Classify performance issue
    │   ├── Memory → axiom:memory-auditor
    │   ├── Battery → axiom:energy-auditor
    │   ├── Swift perf → axiom:swift-performance-analyzer
    │   └── SwiftUI perf → axiom:swiftui-performance-analyzer
    ├── 2. Execute Axiom agent
    ├── 3. Get Instruments recommendations
    ├── 4. Apply optimizations
    └── 5. Benchmark before/after
```

#### 3.3 Concurrency Workflow

```
ios-superpowers debug "@MainActor/Sendable/actor..."
    │
    ├── 1. Run axiom:concurrency-auditor on affected files
    ├── 2. Fetch Swift 6 concurrency docs via sosumi
    ├── 3. Identify isolation boundaries
    ├── 4. Apply patterns from Axiom + docs
    └── 5. Verify with strict concurrency checking
```

#### 3.4 UI/UX Workflow

```
ios-superpowers debug "SwiftUI/navigation/accessibility..."
    │
    ├── 1. Classify UI issue
    │   ├── Architecture → axiom:swiftui-architecture-auditor
    │   ├── Navigation → axiom:swiftui-nav-auditor
    │   ├── Accessibility → axiom:accessibility-auditor
    │   ├── Liquid Glass → axiom:liquid-glass-auditor
    │   └── TextKit → axiom:textkit-auditor
    ├── 2. Run appropriate auditor
    ├── 3. Capture screenshots if visual issue
    │   └── axiom:simulator-tester or /axiom:screenshot
    ├── 4. Apply fixes
    └── 5. Visual verification
```

#### 3.5 Testing Workflow

```
ios-superpowers tdd/debug "test..."
    │
    ├── 1. Classify testing issue
    │   ├── Flaky → axiom:test-failure-analyzer
    │   ├── Debug failing → axiom:test-debugger
    │   ├── Run tests → axiom:test-runner
    │   └── Audit quality → axiom:testing-auditor
    ├── 2. Execute appropriate agent
    ├── 3. Parse xcresult bundle
    ├── 4. Apply fixes or write new tests
    └── 5. Re-run and verify
```

#### 3.6 Data & Storage Workflow

```
ios-superpowers debug "Core Data/SwiftData/iCloud/storage..."
    │
    ├── 1. Classify data issue
    │   ├── Core Data → axiom:core-data-auditor
    │   ├── iCloud sync → axiom:icloud-auditor
    │   ├── File storage → axiom:storage-auditor
    │   └── Codable → axiom:codable-auditor
    ├── 2. Execute appropriate auditor
    ├── 3. Check schema migrations if applicable
    ├── 4. Apply fixes
    └── 5. Verify data integrity
```

### Phase 4: Improve Issue Classification

Create a more precise classification algorithm:

```python
def classify_issue(context: str) -> tuple[str, str]:
    """Returns (domain, axiom_agent)"""

    # Build & Environment
    if matches(context, ["BUILD FAILED", "module not found", "compile error", "linker error"]):
        return ("build", "axiom:build-fixer")
    if matches(context, ["SPM", "package resolution", "dependency conflict"]):
        return ("build", "axiom:spm-conflict-resolver")
    if matches(context, ["slow build", "build time", "incremental"]):
        return ("build", "axiom:build-optimizer")

    # Performance
    if matches(context, ["memory leak", "retain cycle", "memory warning", "EXC_BAD_ACCESS"]):
        return ("performance", "axiom:memory-auditor")
    if matches(context, ["battery", "energy", "power consumption"]):
        return ("performance", "axiom:energy-auditor")
    if matches(context, ["slow", "performance", "lag", "frame drop"]) and "SwiftUI" in context:
        return ("performance", "axiom:swiftui-performance-analyzer")
    if matches(context, ["slow", "performance", "allocation"]):
        return ("performance", "axiom:swift-performance-analyzer")

    # Concurrency
    if matches(context, ["@MainActor", "actor-isolated", "Sendable", "data race", "nonisolated", "Swift 6"]):
        return ("concurrency", "axiom:concurrency-auditor")

    # UI/UX
    if matches(context, ["accessibility", "VoiceOver", "Dynamic Type", "WCAG"]):
        return ("ui", "axiom:accessibility-auditor")
    if matches(context, ["navigation", "NavigationStack", "deep link"]):
        return ("ui", "axiom:swiftui-nav-auditor")
    if matches(context, ["Liquid Glass", "glass effect", "blur", "material", "iOS 26"]):
        return ("ui", "axiom:liquid-glass-auditor")
    if matches(context, ["TextKit", "UITextView", "Writing Tools"]):
        return ("ui", "axiom:textkit-auditor")
    if matches(context, ["deprecated", "modernize", "iOS 17", "iOS 18"]):
        return ("ui", "axiom:modernization-helper")
    if matches(context, ["SwiftUI", "@State", "@Binding", "architecture"]):
        return ("ui", "axiom:swiftui-architecture-auditor")

    # Data & Storage
    if matches(context, ["Core Data", "migration", "NSManagedObject", "schema"]):
        return ("data", "axiom:core-data-auditor")
    if matches(context, ["iCloud", "CloudKit", "sync"]):
        return ("data", "axiom:icloud-auditor")
    if matches(context, ["file storage", "documents", "backup"]):
        return ("data", "axiom:storage-auditor")
    if matches(context, ["Codable", "JSON", "encoding", "decoding"]):
        return ("data", "axiom:codable-auditor")

    # Camera & Media
    if matches(context, ["camera", "AVCapture", "video", "photo"]):
        return ("media", "axiom:camera-auditor")

    # Networking & Security
    if matches(context, ["networking", "URLSession", "API", "connection"]):
        return ("networking", "axiom:networking-auditor")
    if matches(context, ["security", "privacy", "credentials", "keychain"]):
        return ("security", "axiom:security-privacy-scanner")

    # Testing
    if matches(context, ["flaky test", "CI fail", "test passes locally"]):
        return ("testing", "axiom:test-failure-analyzer")
    if matches(context, ["debug test", "fix test"]):
        return ("testing", "axiom:test-debugger")
    if matches(context, ["run tests", "XCUITest"]):
        return ("testing", "axiom:test-runner")
    if matches(context, ["test quality", "test audit"]):
        return ("testing", "axiom:testing-auditor")

    # IAP
    if matches(context, ["IAP", "StoreKit", "purchase", "subscription"]):
        return ("iap", "axiom:iap-auditor")

    # Default
    return ("general", None)
```

### Phase 5: Update Skill Files

#### 5.1 Update ios-superpowers/SKILL.md

Key changes:
- Remove `apple-docs-fetcher` references
- Use sosumi MCP directly: `mcp__sosumi__searchAppleDocumentation`, `mcp__sosumi__fetchAppleDocumentation`
- Replace skill references with Task agent invocations
- Add comprehensive routing matrix from Phase 2
- Add domain-specific workflows from Phase 3

#### 5.2 Update axiom-integration.md

Key changes:
- Expand from 8 skills to 25+ agents
- Add routing decision tree with all domains
- Include Task tool invocation examples
- Document command equivalents

#### 5.3 Update ios-debug.md

Key changes:
- Replace skill-based routing with agent-based routing
- Add domain-specific diagnostic workflows
- Include /axiom:status as first step
- Add visual verification with /axiom:screenshot

#### 5.4 Update dispatch.md

Key changes (already well-aligned):
- Verify agent matrix is complete
- Add any new Axiom agents
- Ensure ios-superpowers integration documented

---

## Implementation Checklist

### Phase 1: Remove Apple Docs Fetcher Redundancy
- [ ] Update ios-superpowers/SKILL.md to use sosumi MCP directly
- [ ] Remove references to apple-docs-fetcher skill
- [ ] Update fallback to WebFetch for sosumi.ai API
- [ ] Test sosumi MCP access works via Axiom

### Phase 2: Expand Axiom Agent Routing
- [ ] Create comprehensive routing matrix in SKILL.md
- [ ] Update axiom-integration.md with all 25+ agents
- [ ] Add Task tool invocation examples for each agent
- [ ] Test routing logic with sample issues

### Phase 3: Add Domain-Specific Workflows
- [ ] Add Build & Environment workflow
- [ ] Add Performance workflow
- [ ] Add Concurrency workflow
- [ ] Add UI/UX workflow
- [ ] Add Testing workflow
- [ ] Add Data & Storage workflow
- [ ] Add Camera/Media workflow
- [ ] Add Networking/Security workflow
- [ ] Add IAP workflow

### Phase 4: Improve Classification
- [ ] Implement classification algorithm in SKILL.md
- [ ] Add pattern matching table
- [ ] Test classification accuracy

### Phase 5: Update Documentation
- [ ] Update CLAUDE.md with new capabilities
- [ ] Update commands/README.md
- [ ] Add examples for each workflow
- [ ] Create quick-reference card

---

## Migration Guide

### For Developers Using ios-superpowers

**Before (current):**
```
/ios-superpowers debug "memory leak in ViewModel"
→ Invokes apple-docs-fetcher
→ Selects axiom-memory-debugging (skill reference)
→ Runs superpowers:systematic-debugging
```

**After (enhanced):**
```
/ios-superpowers debug "memory leak in ViewModel"
→ Classifies as (performance, axiom:memory-auditor)
→ Launches Task with subagent_type="axiom:memory-auditor"
→ Agent uses sosumi MCP for Apple docs
→ Applies memory debugging patterns
→ Reports findings and fixes
```

### Breaking Changes

1. **apple-docs-fetcher no longer invoked** - Use sosumi MCP directly or rely on Axiom agents
2. **Skill references replaced with agents** - `axiom-xcode-debugging` → `axiom:build-fixer`
3. **More specific routing** - Tasks may route to different agents than before

### Compatibility

- All `/ios-superpowers <action>` commands continue to work
- Superpowers skills still available as fallback
- Manual sosumi access still possible via MCP tools

---

## Benefits

1. **More Precise Debugging** - 25+ specialized agents vs 8 generic skills
2. **Integrated Apple Docs** - No separate fetcher skill, Axiom handles it
3. **Domain Expertise** - Each agent has deep knowledge of its iOS sub-domain
4. **Reduced Token Usage** - Agents handle their own context management
5. **Visual Verification** - Built-in screenshot and simulator testing
6. **Test Integration** - Specialized test debugging and running agents

---

## Appendix A: Complete Axiom Agent Reference

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| Build Fixer | `axiom:build-fixer` | BUILD FAILED, module not found | Fix Xcode build failures |
| Build Optimizer | `axiom:build-optimizer` | slow build, build time | Speed up incremental builds |
| SPM Resolver | `axiom:spm-conflict-resolver` | SPM, package resolution | Resolve dependency conflicts |
| Memory Auditor | `axiom:memory-auditor` | memory leak, retain cycle | Find memory issues |
| Energy Auditor | `axiom:energy-auditor` | battery, power | Optimize energy usage |
| Swift Performance | `axiom:swift-performance-analyzer` | slow, allocation | Optimize Swift code |
| SwiftUI Performance | `axiom:swiftui-performance-analyzer` | janky scroll, frame drop | Optimize SwiftUI views |
| Concurrency Auditor | `axiom:concurrency-auditor` | @MainActor, Sendable, data race | Fix Swift 6 concurrency |
| Accessibility Auditor | `axiom:accessibility-auditor` | VoiceOver, accessibility | Audit accessibility |
| SwiftUI Architecture | `axiom:swiftui-architecture-auditor` | @State, architecture | Improve SwiftUI patterns |
| SwiftUI Nav | `axiom:swiftui-nav-auditor` | navigation, deep link | Fix navigation issues |
| Liquid Glass | `axiom:liquid-glass-auditor` | glass effect, blur | iOS 26+ styling |
| TextKit Auditor | `axiom:textkit-auditor` | UITextView, Writing Tools | Fix text handling |
| Modernization | `axiom:modernization-helper` | deprecated, iOS 17/18 | Update legacy code |
| Core Data Auditor | `axiom:core-data-auditor` | Core Data, migration | Audit data layer |
| Storage Auditor | `axiom:storage-auditor` | file storage, backup | Fix storage issues |
| iCloud Auditor | `axiom:icloud-auditor` | iCloud, CloudKit, sync | Fix cloud sync |
| Codable Auditor | `axiom:codable-auditor` | Codable, JSON | Fix encoding/decoding |
| Camera Auditor | `axiom:camera-auditor` | camera, AVCapture | Fix camera code |
| Networking Auditor | `axiom:networking-auditor` | URLSession, API | Fix networking |
| Security Scanner | `axiom:security-privacy-scanner` | security, credentials | Security audit |
| Test Failure Analyzer | `axiom:test-failure-analyzer` | flaky test, CI fail | Diagnose test failures |
| Test Runner | `axiom:test-runner` | run tests | Execute tests |
| Test Debugger | `axiom:test-debugger` | debug test | Fix failing tests |
| Testing Auditor | `axiom:testing-auditor` | test quality | Audit test suite |
| IAP Auditor | `axiom:iap-auditor` | StoreKit, purchase | Audit in-app purchases |
| IAP Implementation | `axiom:iap-implementation` | add subscription | Implement IAP |
| Simulator Tester | `axiom:simulator-tester` | visual verification | Screenshot + test |

---

## Appendix B: Axiom Command Quick Reference

| Command | Purpose |
|---------|---------|
| `/axiom:status` | Show project health dashboard |
| `/axiom:fix-build` | Launch build-fixer agent |
| `/axiom:optimize-build` | Launch build-optimizer agent |
| `/axiom:run-tests` | Launch test-runner agent |
| `/axiom:screenshot` | Capture simulator screenshot |
| `/axiom:test-simulator` | Launch simulator-tester agent |
| `/axiom:ask <question>` | Route iOS question to appropriate skill |
| `/axiom:audit accessibility` | Launch accessibility-auditor |
| `/axiom:audit concurrency` | Launch concurrency-auditor |
| `/axiom:audit memory` | Launch memory-auditor |
| `/axiom:audit swiftui-performance` | Launch swiftui-performance-analyzer |
| `/axiom:audit security` | Launch security-privacy-scanner |
| `/axiom:audit liquid-glass` | Launch liquid-glass-auditor |
| `/axiom:audit core-data` | Launch core-data-auditor |
| `/axiom:audit camera` | Launch camera-auditor |
| `/axiom:audit networking` | Launch networking-auditor |
| `/axiom:audit storage` | Launch storage-auditor |
| `/axiom:audit icloud` | Launch icloud-auditor |
| `/axiom:audit codable` | Launch codable-auditor |
| `/axiom:audit energy` | Launch energy-auditor |
| `/axiom:audit swiftui-nav` | Launch swiftui-nav-auditor |
| `/axiom:audit swiftui-architecture` | Launch swiftui-architecture-auditor |
| `/axiom:audit textkit` | Launch textkit-auditor |
| `/axiom:audit modernization` | Launch modernization-helper |
| `/axiom:audit testing` | Launch testing-auditor |
| `/axiom:audit test-failures` | Launch test-failure-analyzer |
| `/axiom:audit iap` | Launch iap-auditor |

---
name: ios-superpowers
description: iOS-aware orchestrator that routes to specialized Axiom agents and ensures Apple documentation grounding via sosumi.ai MCP. Use this instead of raw superpowers skills for all iOS/Swift development work.
---

# iOS Superpowers Orchestrator

**CRITICAL:** This skill MUST be used instead of raw superpowers skills for ALL iOS/Swift work in this repository.

## Purpose

Orchestrates iOS development workflows by:
1. Classifying issues to route to the most appropriate Axiom agent (25+ specialized agents)
2. Fetching Apple documentation via sosumi.ai MCP for API verification
3. Delegating to superpowers workflows with enriched iOS context
4. Verifying implementation against Apple docs and iOS best practices

## How It Works

```
+---------------------------------------------------------------------+
|                    ios-superpowers                                   |
|                                                                      |
|  1. Parse request and detect iOS context (Swift files, APIs, errors)|
|  2. Classify issue type to select Axiom agent (see routing matrix)  |
|  3. Fetch Apple docs via sosumi MCP (mcp__sosumi__*)                 |
|  4. Launch Axiom agent via Task tool if specialized handling needed |
|  5. Delegate to superpowers skill with docs + Axiom context         |
|  6. Verify implementation against fetched docs                      |
+---------------------------------------------------------------------+
```

**Key Integration Points:**
- **Axiom Agents:** 25+ specialized agents accessed via Task tool (subagent_type)
- **Apple Docs:** Direct MCP calls to sosumi.ai (mcp__sosumi__searchAppleDocumentation, mcp__sosumi__fetchAppleDocumentation)
- **Superpowers:** Underlying workflows for brainstorming, planning, debugging, etc.

---

## Usage

Instead of invoking superpowers directly, use this orchestrator:

| Instead of... | Use... |
|---------------|--------|
| `superpowers:brainstorming` | `ios-superpowers brainstorm <topic>` |
| `superpowers:writing-plans` | `ios-superpowers plan <feature>` |
| `superpowers:executing-plans` | `ios-superpowers execute <plan-path>` |
| `superpowers:requesting-code-review` | `ios-superpowers review` |
| `superpowers:systematic-debugging` | `ios-superpowers debug <issue>` |
| `superpowers:test-driven-development` | `ios-superpowers tdd <feature>` |
| `superpowers:dispatching-parallel-agents` | `ios-superpowers parallel <tasks>` |

---

## Workflow

### Step 1: Parse Request

Extract from arguments:
- **Action**: brainstorm, plan, execute, review, debug, tdd, parallel
- **Context**: Feature name, file paths, or issue description

### Step 2: Detect iOS APIs

Scan the context for iOS-related terms:

**Frameworks to detect:**
- SwiftUI, UIKit, AppKit
- AVFoundation, Vision, CoreML
- Firebase, CloudKit, CoreData, SwiftData
- Combine, async/await, Sendable
- LAContext, LocalAuthentication
- PhotosUI, CameraController

**Patterns to detect:**
- `@MainActor`, `actor`, `nonisolated`
- `@Published`, `@StateObject`, `@Observable`
- `async`, `await`, `Task`, `Continuation`
- `CVPixelBuffer`, `CMSampleBuffer`

### Step 3: Fetch Apple Documentation

Use sosumi.ai MCP directly for Apple documentation:

```
# Search for API documentation
mcp__sosumi__searchAppleDocumentation(query: "<API name>")

# Fetch specific documentation page
mcp__sosumi__fetchAppleDocumentation(path: "<doc path>")
```

**Priority order:**
1. Specific APIs mentioned in task (e.g., "AVCaptureSession")
2. Concurrency patterns if async code involved
3. Framework-level docs for context

**Token budget:** 8K per API, 25K max total

**Note:** Axiom agents launched via Task tool automatically have access to sosumi.ai MCP. You only need to fetch docs manually when not using an Axiom agent.

### Step 4: Select Axiom Agent

Based on task type, route to appropriate Axiom agent using the Task tool:

#### Build & Environment

| Issue Contains | Axiom Agent | Task subagent_type |
|----------------|-------------|-------------------|
| BUILD FAILED, module not found, compile error | Build Fixer | `axiom:build-fixer` |
| slow build, build time, incremental | Build Optimizer | `axiom:build-optimizer` |
| SPM, package resolution, dependency conflict | SPM Resolver | `axiom:spm-conflict-resolver` |

#### Performance

| Issue Contains | Axiom Agent | Task subagent_type |
|----------------|-------------|-------------------|
| memory leak, retain cycle, memory warning | Memory Auditor | `axiom:memory-auditor` |
| battery, energy, power consumption | Energy Auditor | `axiom:energy-auditor` |
| slow, performance, lag (Swift code) | Swift Performance | `axiom:swift-performance-analyzer` |
| SwiftUI slow, janky scroll, frame drop | SwiftUI Performance | `axiom:swiftui-performance-analyzer` |

#### Concurrency

| Issue Contains | Axiom Agent | Task subagent_type |
|----------------|-------------|-------------------|
| @MainActor, actor, Sendable, data race | Concurrency Auditor | `axiom:concurrency-auditor` |
| Swift 6, strict concurrency, isolation | Concurrency Auditor | `axiom:concurrency-auditor` |

#### UI/UX

| Issue Contains | Axiom Agent | Task subagent_type |
|----------------|-------------|-------------------|
| accessibility, VoiceOver, Dynamic Type | Accessibility Auditor | `axiom:accessibility-auditor` |
| SwiftUI architecture, state management | SwiftUI Architecture | `axiom:swiftui-architecture-auditor` |
| navigation, deep link, NavigationStack | SwiftUI Nav Auditor | `axiom:swiftui-nav-auditor` |
| Liquid Glass, glass effect, blur, iOS 26 | Liquid Glass Auditor | `axiom:liquid-glass-auditor` |
| TextKit, UITextView, Writing Tools | TextKit Auditor | `axiom:textkit-auditor` |
| deprecated, modernize, iOS 17/18 | Modernization Helper | `axiom:modernization-helper` |

#### Data & Storage

| Issue Contains | Axiom Agent | Task subagent_type |
|----------------|-------------|-------------------|
| Core Data, migration, schema | Core Data Auditor | `axiom:core-data-auditor` |
| file storage, documents, backup | Storage Auditor | `axiom:storage-auditor` |
| iCloud, CloudKit, sync | iCloud Auditor | `axiom:icloud-auditor` |
| Codable, JSON, encoding/decoding | Codable Auditor | `axiom:codable-auditor` |

#### Camera & Media

| Issue Contains | Axiom Agent | Task subagent_type |
|----------------|-------------|-------------------|
| camera, AVCapture, video, photo | Camera Auditor | `axiom:camera-auditor` |

#### Networking & Security

| Issue Contains | Axiom Agent | Task subagent_type |
|----------------|-------------|-------------------|
| networking, URLSession, API, connection | Networking Auditor | `axiom:networking-auditor` |
| security, privacy, credentials, keychain | Security Scanner | `axiom:security-privacy-scanner` |

#### Testing

| Issue Contains | Axiom Agent | Task subagent_type |
|----------------|-------------|-------------------|
| flaky test, CI fail, test passes locally | Test Failure Analyzer | `axiom:test-failure-analyzer` |
| run tests, XCUITest, test results | Test Runner | `axiom:test-runner` |
| debug test, fix test | Test Debugger | `axiom:test-debugger` |
| test quality, test audit | Testing Auditor | `axiom:testing-auditor` |

#### In-App Purchase

| Issue Contains | Axiom Agent | Task subagent_type |
|----------------|-------------|-------------------|
| IAP, StoreKit, purchase, subscription | IAP Auditor | `axiom:iap-auditor` |
| add subscription, implement IAP | IAP Implementation | `axiom:iap-implementation` |

#### Utility

| Need | Axiom Agent | Task subagent_type |
|------|-------------|-------------------|
| Visual verification, screenshots | Simulator Tester | `axiom:simulator-tester` |

### Step 5: Invoke Superpowers with Context

Delegate to the appropriate superpowers skill with prefixed context:

```markdown
## Apple Documentation Context

[Fetched docs summary - key APIs, signatures, availability]

## Axiom Skill Active

Using: [axiom-skill-name]
Patterns: [relevant patterns from Axiom skill]

---

Now proceeding with [superpowers skill]...
```

### Step 6: Verify Against Docs

After superpowers completes, verify:
- [ ] No deprecated APIs introduced
- [ ] Concurrency patterns match Swift 6 requirements
- [ ] API usage matches documented signatures
- [ ] Thread safety requirements satisfied

---

## API Detection Patterns

```swift
// These patterns trigger sosumi MCP documentation fetch:

// Concurrency
@MainActor           -> fetch "Swift MainActor"
actor MyActor        -> fetch "Swift actor"
nonisolated          -> fetch "Swift nonisolated"
async/await          -> fetch "Swift concurrency"
Task { }             -> fetch "Swift Task"
withCheckedContinuation -> fetch "Swift continuation"

// SwiftUI
@Published           -> fetch "SwiftUI Published"
@StateObject         -> fetch "SwiftUI StateObject"
@Observable          -> fetch "Swift Observable"
NavigationStack      -> fetch "SwiftUI NavigationStack"
.containerRelativeFrame -> fetch "SwiftUI containerRelativeFrame"

// Vision/Camera
AVCaptureSession     -> fetch "AVFoundation AVCaptureSession"
VNCoreMLModel        -> fetch "Vision VNCoreMLModel"
CVPixelBuffer        -> fetch "Core Video CVPixelBuffer"
VNRecognizeTextRequest -> fetch "Vision VNRecognizeTextRequest"

// Auth
LAContext            -> fetch "LocalAuthentication LAContext"

// Data
SwiftData            -> fetch "SwiftData"
@Model               -> fetch "SwiftData Model"
ModelContext         -> fetch "SwiftData ModelContext"
```

---

## Axiom Integration

### When to Use Axiom Agents

Axiom agents provide iOS-specific patterns, debugging workflows, and best practices that go beyond raw Apple documentation. They are launched via the Task tool with a `subagent_type` parameter.

**Always launch an Axiom agent when:**
1. Debugging iOS-specific issues (build, memory, concurrency, networking)
2. Auditing code for patterns (accessibility, security, performance)
3. Working with iOS 26+ features (Liquid Glass)
4. Writing or debugging tests (XCUITest, Swift Testing)
5. Working with data persistence (Core Data, SwiftData, iCloud)
6. Camera/media work (AVFoundation, Vision)

### How to Launch Axiom Agents

Use the Task tool with the appropriate `subagent_type`:

```
Task(
    description: "Debug memory leak in ViewModel",
    prompt: "Analyze the ViewModel for retain cycles and memory leaks...",
    subagent_type: "axiom:memory-auditor"
)
```

### Axiom Agent Routing Logic

```
IF task contains "BUILD FAILED" OR "module not found" OR "compile error" OR "linker error":
    -> Task(subagent_type="axiom:build-fixer")

ELSE IF task contains "slow build" OR "build time":
    -> Task(subagent_type="axiom:build-optimizer")

ELSE IF task contains "SPM" OR "package resolution" OR "dependency conflict":
    -> Task(subagent_type="axiom:spm-conflict-resolver")

ELSE IF task contains "leak" OR "retain cycle" OR "memory warning" OR "EXC_BAD_ACCESS":
    -> Task(subagent_type="axiom:memory-auditor")

ELSE IF task contains "battery" OR "energy" OR "power consumption":
    -> Task(subagent_type="axiom:energy-auditor")

ELSE IF task contains "slow" OR "lag" OR "performance":
    IF context mentions SwiftUI:
        -> Task(subagent_type="axiom:swiftui-performance-analyzer")
    ELSE:
        -> Task(subagent_type="axiom:swift-performance-analyzer")

ELSE IF task contains "@MainActor" OR "actor" OR "Sendable" OR "data race" OR "Swift 6":
    -> Task(subagent_type="axiom:concurrency-auditor")

ELSE IF task contains "accessibility" OR "VoiceOver" OR "Dynamic Type" OR "WCAG":
    -> Task(subagent_type="axiom:accessibility-auditor")

ELSE IF task contains "navigation" OR "deep link" OR "NavigationStack":
    -> Task(subagent_type="axiom:swiftui-nav-auditor")

ELSE IF task contains "Liquid Glass" OR "glass effect" OR "blur" OR "material" OR "iOS 26":
    -> Task(subagent_type="axiom:liquid-glass-auditor")

ELSE IF task contains "TextKit" OR "UITextView" OR "Writing Tools":
    -> Task(subagent_type="axiom:textkit-auditor")

ELSE IF task contains "deprecated" OR "modernize" OR "iOS 17" OR "iOS 18":
    -> Task(subagent_type="axiom:modernization-helper")

ELSE IF task contains "SwiftUI" OR "View" OR "@State" OR "@Binding" OR "architecture":
    -> Task(subagent_type="axiom:swiftui-architecture-auditor")

ELSE IF task contains "Core Data" OR "migration" OR "NSManagedObject" OR "schema":
    -> Task(subagent_type="axiom:core-data-auditor")

ELSE IF task contains "file storage" OR "documents" OR "backup":
    -> Task(subagent_type="axiom:storage-auditor")

ELSE IF task contains "iCloud" OR "CloudKit" OR "sync":
    -> Task(subagent_type="axiom:icloud-auditor")

ELSE IF task contains "Codable" OR "JSON" OR "encoding" OR "decoding":
    -> Task(subagent_type="axiom:codable-auditor")

ELSE IF task contains "camera" OR "AVCapture" OR "video" OR "photo":
    -> Task(subagent_type="axiom:camera-auditor")

ELSE IF task contains "networking" OR "URLSession" OR "API" OR "connection":
    -> Task(subagent_type="axiom:networking-auditor")

ELSE IF task contains "security" OR "privacy" OR "credentials" OR "keychain":
    -> Task(subagent_type="axiom:security-privacy-scanner")

ELSE IF task contains "flaky test" OR "CI fail" OR "test passes locally":
    -> Task(subagent_type="axiom:test-failure-analyzer")

ELSE IF task contains "run tests" OR "XCUITest":
    -> Task(subagent_type="axiom:test-runner")

ELSE IF task contains "debug test" OR "fix test":
    -> Task(subagent_type="axiom:test-debugger")

ELSE IF task contains "test quality" OR "test audit":
    -> Task(subagent_type="axiom:testing-auditor")

ELSE IF task contains "IAP" OR "StoreKit" OR "purchase" OR "subscription":
    -> Task(subagent_type="axiom:iap-auditor")

ELSE:
    -> No Axiom agent needed (use sosumi docs + superpowers only)
```

---

## Domain-Specific Workflows

### Build & Environment Workflow

When debugging build issues:

```
ios-superpowers debug "BUILD FAILED..." or "module not found"
    │
    ├── 1. Run /axiom:status (project health check)
    │
    ├── 2. Classify build issue type:
    │   ├── Module not found, BUILD FAILED → axiom:build-fixer
    │   ├── SPM conflict, dependency error → axiom:spm-conflict-resolver
    │   └── Slow build, incremental issues → axiom:build-optimizer
    │
    ├── 3. Launch Axiom agent:
    │   Task(
    │       description: "Fix build failure",
    │       prompt: "[error message + affected files]",
    │       subagent_type: "axiom:build-fixer"
    │   )
    │
    ├── 4. If unresolved, fetch sosumi docs for framework:
    │   mcp__sosumi__searchAppleDocumentation(query: "AVFoundation")
    │
    └── 5. Apply fix and verify:
        swift build
```

### Performance Workflow

When debugging performance issues:

```
ios-superpowers debug "slow/memory/battery..."
    │
    ├── 1. Classify performance issue:
    │   ├── Memory leak, retain cycle → axiom:memory-auditor
    │   ├── Battery drain, energy → axiom:energy-auditor
    │   ├── SwiftUI janky, frame drops → axiom:swiftui-performance-analyzer
    │   └── General slow, allocations → axiom:swift-performance-analyzer
    │
    ├── 2. Launch Axiom agent:
    │   Task(
    │       description: "Diagnose memory leak",
    │       prompt: "[symptoms + affected files]",
    │       subagent_type: "axiom:memory-auditor"
    │   )
    │
    ├── 3. Get Instruments recommendations from agent
    │
    ├── 4. Apply optimizations
    │
    └── 5. Benchmark before/after
```

### Concurrency Workflow

When debugging Swift 6 concurrency issues:

```
ios-superpowers debug "@MainActor/Sendable/actor..."
    │
    ├── 1. Launch concurrency auditor:
    │   Task(
    │       description: "Audit concurrency",
    │       prompt: "[error message + file paths]",
    │       subagent_type: "axiom:concurrency-auditor"
    │   )
    │
    ├── 2. Fetch Swift 6 concurrency docs:
    │   mcp__sosumi__fetchAppleDocumentation(path: "/documentation/swift/sendable")
    │   mcp__sosumi__fetchAppleDocumentation(path: "/documentation/swift/mainactor")
    │
    ├── 3. Identify isolation boundaries from audit
    │
    ├── 4. Apply patterns from Axiom + docs
    │
    └── 5. Verify with strict concurrency checking:
        swift build -Xswiftc -strict-concurrency=complete
```

### UI/UX Workflow

When debugging SwiftUI or UI issues:

```
ios-superpowers debug "SwiftUI/navigation/accessibility..."
    │
    ├── 1. Classify UI issue:
    │   ├── Architecture, state management → axiom:swiftui-architecture-auditor
    │   ├── Navigation, deep links → axiom:swiftui-nav-auditor
    │   ├── Accessibility, VoiceOver → axiom:accessibility-auditor
    │   ├── Liquid Glass, blur, iOS 26 → axiom:liquid-glass-auditor
    │   └── TextKit, text views → axiom:textkit-auditor
    │
    ├── 2. Launch appropriate auditor:
    │   Task(
    │       description: "Audit accessibility",
    │       prompt: "[issue + affected views]",
    │       subagent_type: "axiom:accessibility-auditor"
    │   )
    │
    ├── 3. Capture screenshots if visual issue:
    │   /axiom:screenshot
    │   OR Task(subagent_type="axiom:simulator-tester")
    │
    ├── 4. Apply fixes from audit
    │
    └── 5. Visual verification
```

### Testing Workflow

When debugging or running tests:

```
ios-superpowers tdd/debug "test..."
    │
    ├── 1. Classify testing issue:
    │   ├── Flaky test, CI fail → axiom:test-failure-analyzer
    │   ├── Debug failing test → axiom:test-debugger
    │   ├── Run tests → axiom:test-runner
    │   └── Audit test quality → axiom:testing-auditor
    │
    ├── 2. Launch appropriate agent:
    │   Task(
    │       description: "Analyze flaky test",
    │       prompt: "[test name + failure pattern]",
    │       subagent_type: "axiom:test-failure-analyzer"
    │   )
    │
    ├── 3. Parse xcresult bundle (agent handles this)
    │
    ├── 4. Apply fixes or write new tests
    │
    └── 5. Re-run and verify:
        swift test
```

### Data & Storage Workflow

When debugging data persistence issues:

```
ios-superpowers debug "Core Data/SwiftData/iCloud/storage..."
    │
    ├── 1. Classify data issue:
    │   ├── Core Data, migration, schema → axiom:core-data-auditor
    │   ├── iCloud sync, CloudKit → axiom:icloud-auditor
    │   ├── File storage, backup → axiom:storage-auditor
    │   └── Codable, JSON encoding → axiom:codable-auditor
    │
    ├── 2. Launch appropriate auditor:
    │   Task(
    │       description: "Audit Core Data migration",
    │       prompt: "[schema changes + model files]",
    │       subagent_type: "axiom:core-data-auditor"
    │   )
    │
    ├── 3. Check schema migrations if applicable
    │
    ├── 4. Apply fixes
    │
    └── 5. Verify data integrity
```

### Camera & Media Workflow

When debugging camera or media issues:

```
ios-superpowers debug "camera/AVCapture/video..."
    │
    ├── 1. Launch camera auditor:
    │   Task(
    │       description: "Audit camera code",
    │       prompt: "[issue + camera service files]",
    │       subagent_type: "axiom:camera-auditor"
    │   )
    │
    ├── 2. Fetch AVFoundation docs:
    │   mcp__sosumi__fetchAppleDocumentation(path: "/documentation/avfoundation")
    │
    ├── 3. Check for deprecated APIs, threading issues
    │
    ├── 4. Apply fixes
    │
    └── 5. Test on device (camera requires hardware)
```

### Networking & Security Workflow

When debugging networking or security issues:

```
ios-superpowers debug "networking/security/credentials..."
    │
    ├── 1. Classify issue:
    │   ├── Networking, URLSession, API → axiom:networking-auditor
    │   └── Security, credentials, privacy → axiom:security-privacy-scanner
    │
    ├── 2. Launch appropriate agent:
    │   Task(
    │       description: "Security audit",
    │       prompt: "[concerns + affected files]",
    │       subagent_type: "axiom:security-privacy-scanner"
    │   )
    │
    ├── 3. Review findings (hardcoded credentials, missing privacy manifest, etc.)
    │
    ├── 4. Apply fixes
    │
    └── 5. Verify no sensitive data exposed
```

### IAP Workflow

When working with in-app purchases:

```
ios-superpowers debug/plan "IAP/StoreKit/subscription..."
    │
    ├── 1. Classify IAP task:
    │   ├── Audit existing IAP → axiom:iap-auditor
    │   └── Implement new IAP → axiom:iap-implementation
    │
    ├── 2. Launch appropriate agent:
    │   Task(
    │       description: "Audit StoreKit implementation",
    │       prompt: "[current IAP code + issues]",
    │       subagent_type: "axiom:iap-auditor"
    │   )
    │
    ├── 3. Review transaction handling, receipt validation
    │
    ├── 4. Apply fixes or implement features
    │
    └── 5. Test with StoreKit configuration file
```

---

## Examples

### Example 1: Brainstorming iOS Feature

```
/ios-superpowers brainstorm biometric authentication flow
```

Orchestrator will:
1. Detect: LAContext, LocalAuthentication, Face ID
2. Fetch: LAContext docs via `mcp__sosumi__fetchAppleDocumentation`
3. Axiom: None needed (auth flow design, not debugging)
4. Invoke: superpowers:brainstorming with docs context

### Example 2: Planning Camera Feature

```
/ios-superpowers plan real-time object detection
```

Orchestrator will:
1. Detect: AVCaptureSession, Vision, VNCoreMLModel, CVPixelBuffer
2. Fetch: Camera setup docs, Vision request docs via sosumi MCP
3. Axiom: Launch `axiom:camera-auditor` for camera patterns
4. Invoke: superpowers:writing-plans with docs + Axiom context

### Example 3: Debugging Build Failure

```
/ios-superpowers debug "BUILD FAILED - module 'AVFoundation' not found"
```

Orchestrator will:
1. Detect: AVFoundation, build failure
2. Classify: BUILD FAILED → `axiom:build-fixer`
3. Launch: `Task(subagent_type="axiom:build-fixer", prompt="...")`
4. Agent uses sosumi MCP for AVFoundation docs automatically
5. Apply fix and verify with `swift build`

### Example 4: Debugging Memory Issue

```
/ios-superpowers debug "memory leak in image processing pipeline"
```

Orchestrator will:
1. Detect: memory leak, image processing
2. Classify: memory leak → `axiom:memory-auditor`
3. Launch: `Task(subagent_type="axiom:memory-auditor", prompt="...")`
4. Agent scans for retain cycles, weak reference issues
5. Report findings and suggested fixes

### Example 5: Executing with Parallel Agents

```
/ios-superpowers parallel "Fix concurrency issues in CameraService, HouseholdItemDetector"
```

Orchestrator will:
1. Detect: actor, Sendable, nonisolated, continuation
2. Classify: concurrency → `axiom:concurrency-auditor`
3. Launch parallel agents:
   ```
   Task(subagent_type="axiom:concurrency-auditor", prompt="Audit CameraService...")
   Task(subagent_type="axiom:concurrency-auditor", prompt="Audit HouseholdItemDetector...")
   ```
4. Each agent has sosumi MCP access for Swift 6 concurrency docs
5. Combine results and apply fixes

### Example 6: Code Review

```
/ios-superpowers review
```

Orchestrator will:
1. **Scan changed files** for iOS APIs (imports, class names, patterns)
2. **Fetch Apple docs** via `mcp__sosumi__searchAppleDocumentation`
3. **Select Axiom agents** based on code patterns and launch auditors:
   - SwiftUI views → `Task(subagent_type="axiom:swiftui-architecture-auditor")`
   - Concurrency patterns → `Task(subagent_type="axiom:concurrency-auditor")`
   - Accessibility → `Task(subagent_type="axiom:accessibility-auditor")`
   - Security concerns → `Task(subagent_type="axiom:security-privacy-scanner")`
4. **Build verification context** combining:
   - Apple documentation (API signatures, availability, deprecations)
   - Axiom audit results (pattern violations, best practices)
5. **Invoke superpowers:requesting-code-review** with enriched context
6. **Post-review verification**:
   - Check API usage against Apple docs
   - Verify Swift 6 concurrency requirements
   - Flag deprecated APIs or patterns

**Code Review Checklist (automatic):**
- [ ] API signatures match Apple documentation
- [ ] iOS version requirements satisfied (deployment target)
- [ ] No deprecated APIs introduced
- [ ] Swift 6 concurrency rules followed (Sendable, actor isolation)
- [ ] SwiftUI patterns match current best practices
- [ ] Memory management appropriate (weak/unowned references)

---

## Code Review Workflow (Detailed)

When `ios-superpowers review` is invoked, the following workflow executes:

### Phase 1: API Detection

```
1. Get list of changed files (git diff)
2. For each Swift file:
   - Parse import statements
   - Extract framework names (SwiftUI, Vision, AVFoundation, etc.)
   - Detect API usage patterns (@MainActor, actor, async/await)
   - Identify class/struct/protocol names
3. Build API list for documentation lookup
```

### Phase 2: Apple Documentation Fetch

```
For each detected API:
1. Call mcp__sosumi__searchAppleDocumentation(query)
2. If specific match found:
   - Call mcp__sosumi__fetchAppleDocumentation(path)
   - Extract: API signature, parameters, availability, deprecations
3. If MCP unavailable:
   - Fallback to sosumi.ai API via WebFetch
4. Build documentation context (max 25K tokens)
```

### Phase 3: Axiom Agent Selection

Based on detected patterns, launch relevant Axiom agents via Task tool:

| Pattern Detected | Axiom Agent | Task subagent_type |
|------------------|-------------|-------------------|
| `@MainActor`, `actor`, `nonisolated` | Concurrency Auditor | `axiom:concurrency-auditor` |
| `@State`, `@Binding`, `View`, architecture | SwiftUI Architecture | `axiom:swiftui-architecture-auditor` |
| `.glass`, `.blur`, `Material`, iOS 26 | Liquid Glass Auditor | `axiom:liquid-glass-auditor` |
| `@Model`, `ModelContext`, SwiftData | Core Data Auditor | `axiom:core-data-auditor` |
| `XCUITest`, `XCUIElement` | Testing Auditor | `axiom:testing-auditor` |
| Build errors in review | Build Fixer | `axiom:build-fixer` |
| Memory warnings | Memory Auditor | `axiom:memory-auditor` |
| VoiceOver, accessibility | Accessibility Auditor | `axiom:accessibility-auditor` |
| credentials, keychain, privacy | Security Scanner | `axiom:security-privacy-scanner` |

### Phase 4: Context Assembly

Combine documentation and Axiom agent results:

```markdown
## Apple Documentation Context

[API summaries, signatures, availability info from sosumi MCP]

## Axiom Agent Audit Results

[Results from launched Axiom agents - pattern violations, recommendations]

## Code Review Focus Areas

Based on detected patterns:
- Concurrency: Check @MainActor boundaries, Sendable conformance
- SwiftUI: Verify view composition, state management
- Data: Check model relationships, query performance
- Testing: Verify accessibility identifiers, test coverage
- Security: Check for hardcoded credentials, privacy manifest
```

### Phase 5: Invoke Code Review

```
Tool: Skill
Parameters:
  skill: superpowers:requesting-code-review

Context includes:
- Changed files
- Apple documentation summaries (from sosumi MCP)
- Axiom agent audit results
- iOS-specific review checklist
```

### Phase 6: Post-Review Verification

After review completes, verify:
1. All flagged APIs match Apple documentation
2. Suggested fixes follow Swift 6 patterns
3. No deprecated APIs remain unaddressed
4. Concurrency patterns are correct
5. Axiom agent recommendations addressed

---

## MCP Server Integration

### sosumi.ai (Apple Documentation)

Primary source for Apple Developer documentation:

```
mcp__sosumi__searchAppleDocumentation(query)  # Search for docs
mcp__sosumi__fetchAppleDocumentation(path)    # Fetch specific doc
```

**Fallback:** If MCP unavailable, use sosumi.ai API via WebFetch

### Token Management

- Search results: ~500 tokens each
- Fetched docs: 2K-8K tokens each
- **Budget per request:** 25K tokens max
- **Strategy:** Search first, fetch selectively, extract and discard

---

## Integration with Other Skills

### ios-sprint-executor

ios-sprint-executor calls ios-superpowers internally for:
- Phase 2 planning (plan)
- Phase 3 execution (execute)
- Phase 4 code review (review)

### verified-stage-development

Routes iOS stages (2.2, 3.1, 4.1) to ios-superpowers automatically:
- Uses agent routing matrix
- Includes Axiom agent selection

### sosumi.ai MCP

Apple documentation is fetched directly via sosumi MCP tools:
- `mcp__sosumi__searchAppleDocumentation`: Search for documentation
- `mcp__sosumi__fetchAppleDocumentation`: Fetch specific doc page

Axiom agents launched via Task tool automatically have MCP access - no need to fetch docs separately when using an Axiom agent.

---

## Fallback Behavior

If no iOS APIs detected:
1. Log: "No iOS APIs detected, proceeding without Apple docs fetch"
2. Skip Axiom skill selection
3. Delegate directly to superpowers skill
4. Still available for manual docs fetch if needed

---

## Error Handling

### MCP Server Unavailable

```
WARNING: sosumi.ai MCP server unavailable.

Falling back to WebFetch API:
- WebFetch("https://sosumi.ai/api/search?q=...")
- WebFetch("https://sosumi.ai/api/docs...")

Continuing with degraded functionality.
```

### Token Budget Exceeded

```
WARNING: Token budget exceeded (28K > 25K max).

Reducing scope:
- Trimming fetched docs to summaries
- Prioritizing most relevant APIs

Continuing with reduced context.
```

### Axiom Agent Unavailable

```
WARNING: Axiom agent [subagent_type] not available.

Falling back to:
1. Direct sosumi MCP documentation fetch
2. superpowers skill without Axiom patterns

Continuing with Apple documentation only.
```

---

## Arguments Format

```
<action> <context>

Actions:
- brainstorm <topic>      # Design phase exploration
- plan <feature>          # Implementation planning
- execute <plan-path>     # Execute implementation plan
- review                  # Request code review
- debug <issue>           # Systematic debugging
- tdd <feature>           # Test-driven development
- parallel <task-list>    # Parallel agent dispatch
```

---

## Notes

- This skill wraps superpowers, not replaces it
- Apple docs are fetched fresh for each invocation
- Axiom skills provide iOS-specific patterns beyond docs
- Token budget enforced to prevent context overflow
- Always prefer this skill over raw superpowers for iOS work

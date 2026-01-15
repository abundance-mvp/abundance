---
name: ios-superpowers
description: iOS-aware orchestrator that ensures Apple documentation is fetched before any superpowers workflow. Use this instead of raw superpowers skills for all iOS/Swift development work.
---

# iOS Superpowers Orchestrator

**CRITICAL:** This skill MUST be used instead of raw superpowers skills for ALL iOS/Swift work in this repository.

## Purpose

Wraps superpowers workflows with automatic Apple documentation fetching to ensure:
1. Swift 6 concurrency patterns are verified against current docs
2. iOS API usage follows latest Apple guidelines
3. SwiftUI patterns match current best practices
4. No deprecated APIs are introduced

## How It Works

```
+---------------------------------------------------------------------+
|                    ios-superpowers                                   |
|                                                                      |
|  1. Detect iOS context (Swift files, iOS APIs mentioned)            |
|  2. Extract relevant APIs/frameworks from task                      |
|  3. Invoke apple-docs-fetcher for each API                          |
|  4. Delegate to requested superpowers skill with docs context       |
|  5. Verify implementation against fetched docs                      |
+---------------------------------------------------------------------+
```

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

For each detected API/framework, invoke:

```
mcp__sosumi__searchAppleDocumentation(query: "<API name>")
mcp__sosumi__fetchAppleDocumentation(path: "<doc path>")
```

**Priority order:**
1. Specific APIs mentioned in task (e.g., "AVCaptureSession")
2. Concurrency patterns if async code involved
3. Framework-level docs for context

**Token budget:** 8K per API, 25K max total

### Step 4: Select Axiom Sub-Skill

Based on task type, route to appropriate Axiom skill:

| Task Type | Axiom Skill | When to Use |
|-----------|-------------|-------------|
| Build/Compile Issues | `axiom-xcode-debugging` | Xcode build failures, module not found |
| Memory Issues | `axiom-memory-debugging` | Leaks, retain cycles, memory warnings |
| Concurrency/Async | `axiom-swift-concurrency` | Actor isolation, Sendable, data races |
| UI Development | `axiom-swiftui-26-ref` | SwiftUI views, modifiers, layout |
| Liquid Glass Styling | `axiom-liquid-glass` | iOS 26+ glass effects, blur, materials |
| Database/Persistence | `axiom-swiftdata` | SwiftData models, queries, migrations |
| Database Migration | `axiom-database-migration` | Core Data to SwiftData transitions |
| UI Testing | `axiom-ui-testing` | XCUITest, accessibility, automation |

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
// These patterns trigger apple-docs-fetcher:

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

### When to Use Axiom Skills

Axiom skills provide iOS-specific patterns, debugging workflows, and best practices that go beyond raw Apple documentation.

**Always activate Axiom when:**
1. Debugging iOS-specific issues (build, memory, concurrency)
2. Implementing SwiftUI views or components
3. Working with iOS 26+ features (Liquid Glass)
4. Writing UI tests with XCUITest
5. Migrating or working with SwiftData

### Axiom Skill Routing Logic

```
IF task contains "build fail" OR "module not found" OR "compile error":
    -> axiom-xcode-debugging

ELSE IF task contains "leak" OR "retain cycle" OR "memory":
    -> axiom-memory-debugging

ELSE IF task contains "@MainActor" OR "actor" OR "Sendable" OR "concurrency":
    -> axiom-swift-concurrency

ELSE IF task contains "SwiftUI" OR "View" OR "@State" OR "@Binding":
    IF iOS 26+ OR contains "glass" OR "blur":
        -> axiom-liquid-glass
    ELSE:
        -> axiom-swiftui-26-ref

ELSE IF task contains "SwiftData" OR "@Model" OR "ModelContext":
    -> axiom-swiftdata

ELSE IF task contains "XCUITest" OR "UI test" OR "accessibility":
    -> axiom-ui-testing

ELSE:
    -> No Axiom skill needed (use Apple docs only)
```

---

## Examples

### Example 1: Brainstorming iOS Feature

```
/ios-superpowers brainstorm biometric authentication flow
```

Orchestrator will:
1. Detect: LAContext, LocalAuthentication, Face ID
2. Fetch: LAContext docs, biometricType, evaluatePolicy
3. Axiom: None (auth flow design, not debugging)
4. Invoke: superpowers:brainstorming with docs context

### Example 2: Planning Camera Feature

```
/ios-superpowers plan real-time object detection
```

Orchestrator will:
1. Detect: AVCaptureSession, Vision, VNCoreMLModel, CVPixelBuffer
2. Fetch: Camera setup docs, Vision request docs, buffer handling
3. Axiom: axiom-swift-concurrency (async camera pipeline)
4. Invoke: superpowers:writing-plans with docs + Axiom context

### Example 3: Debugging Build Failure

```
/ios-superpowers debug "BUILD FAILED - module 'AVFoundation' not found"
```

Orchestrator will:
1. Detect: AVFoundation, build failure
2. Fetch: AVFoundation framework docs
3. Axiom: axiom-xcode-debugging (build troubleshooting)
4. Invoke: superpowers:systematic-debugging with Axiom patterns

### Example 4: Executing with Parallel Agents

```
/ios-superpowers parallel "Fix concurrency issues in CameraService, HouseholdItemDetector"
```

Orchestrator will:
1. Detect: actor, Sendable, nonisolated, continuation
2. Fetch: Swift 6 concurrency docs for each pattern
3. Axiom: axiom-swift-concurrency for each agent
4. Invoke: superpowers:dispatching-parallel-agents
5. Each agent receives relevant Apple docs + Axiom patterns

### Example 5: Code Review

```
/ios-superpowers review
```

Orchestrator will:
1. **Scan changed files** for iOS APIs (imports, class names, patterns)
2. **Fetch Apple docs** for each detected API via apple-docs-fetcher
3. **Select Axiom skills** based on code patterns:
   - SwiftUI views → axiom-swiftui-26-ref
   - Concurrency patterns → axiom-swift-concurrency
   - Data persistence → axiom-swiftdata
   - UI tests → axiom-ui-testing
4. **Build verification context** combining:
   - Apple documentation (API signatures, availability, deprecations)
   - Axiom patterns (best practices, common issues, iOS-specific patterns)
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

### Phase 3: Axiom Skill Selection

Based on detected patterns, activate relevant Axiom skills:

| Pattern Detected | Axiom Skill Activated |
|------------------|----------------------|
| `@MainActor`, `actor`, `nonisolated` | axiom-swift-concurrency |
| `@State`, `@Binding`, `View` | axiom-swiftui-26-ref |
| `.glass`, `.blur`, `Material` | axiom-liquid-glass |
| `@Model`, `ModelContext` | axiom-swiftdata |
| `XCUITest`, `XCUIElement` | axiom-ui-testing |
| Build errors in review | axiom-xcode-debugging |
| Memory warnings in review | axiom-memory-debugging |

### Phase 4: Context Assembly

Combine documentation and Axiom patterns:

```markdown
## Apple Documentation Context

[API summaries, signatures, availability info]

## Axiom iOS Patterns

[Relevant patterns from activated Axiom skills]

## Code Review Focus Areas

Based on detected patterns:
- Concurrency: Check @MainActor boundaries, Sendable conformance
- SwiftUI: Verify view composition, state management
- Data: Check model relationships, query performance
- Testing: Verify accessibility identifiers, test coverage
```

### Phase 5: Invoke Code Review

```
Tool: Skill
Parameters:
  skill: superpowers:requesting-code-review

Context includes:
- Changed files
- Apple documentation summaries
- Axiom pattern guidance
- iOS-specific review checklist
```

### Phase 6: Post-Review Verification

After review completes, verify:
1. All flagged APIs match Apple documentation
2. Suggested fixes follow Swift 6 patterns
3. No deprecated APIs remain unaddressed
4. Concurrency patterns are correct

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
- Includes Axiom skill selection

### apple-docs-fetcher

Called automatically by ios-superpowers. Do not invoke separately unless:
- Manual doc lookup needed outside workflow
- Refreshing stale documentation

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

### Axiom Skill Not Found

```
WARNING: Axiom skill [skill-name] not found.

Continuing without Axiom patterns.
Apple documentation still available.
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

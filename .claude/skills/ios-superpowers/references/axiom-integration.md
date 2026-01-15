# Axiom iOS Plugin Integration

This document describes how ios-superpowers integrates with Axiom iOS development skills.

## Available Axiom Skills

### axiom-xcode-debugging

**Purpose:** Troubleshoot Xcode build failures and compilation issues

**Trigger patterns:**
- "BUILD FAILED"
- "module not found"
- "No such module"
- "Undefined symbol"
- "linker error"
- "code signing error"

**Common resolutions:**
- Clean build folder
- Resolve SPM dependencies
- Fix import statements
- Update build settings
- Resolve signing certificates

### axiom-memory-debugging

**Purpose:** Diagnose memory leaks, retain cycles, and memory warnings

**Trigger patterns:**
- "memory leak"
- "retain cycle"
- "memory warning"
- "EXC_BAD_ACCESS"
- "zombie object"

**Tools used:**
- Instruments Memory Leaks
- Instruments Allocations
- Debug Memory Graph
- malloc_history

### axiom-swift-concurrency

**Purpose:** Fix Swift 6 concurrency issues and actor isolation errors

**Trigger patterns:**
- "@MainActor"
- "actor-isolated"
- "Sendable"
- "data race"
- "nonisolated"
- "Task isolation"

**Swift 6 patterns:**
- Actor isolation boundaries
- Sendable conformance
- MainActor annotations
- Continuation safety
- Task priorities

### axiom-swiftui-26-ref

**Purpose:** SwiftUI best practices and modern patterns

**Trigger patterns:**
- "SwiftUI"
- "@State"
- "@Binding"
- "@Observable"
- "View"
- "modifier"

**iOS 17+ features:**
- @Observable macro
- NavigationStack
- containerRelativeFrame
- scrollTargetBehavior
- phaseAnimator

### axiom-liquid-glass

**Purpose:** iOS 26+ Liquid Glass styling and effects

**Trigger patterns:**
- "liquid glass"
- "glass effect"
- "blur"
- "material"
- "vibrancy"

**Design patterns:**
- GlassBackgroundModifier
- LiquidGlassHelpers
- Material backgrounds
- Vibrancy effects
- System blur styles

### axiom-swiftdata

**Purpose:** SwiftData models, queries, and persistence

**Trigger patterns:**
- "SwiftData"
- "@Model"
- "ModelContext"
- "@Query"
- "PersistentModel"

**Patterns:**
- Model definitions
- Relationships
- Query predicates
- Migration strategies
- CloudKit sync

### axiom-database-migration

**Purpose:** Core Data to SwiftData migration

**Trigger patterns:**
- "migration"
- "Core Data"
- "NSManagedObject"
- "schema change"

**Migration patterns:**
- Lightweight migration
- Custom migration mapping
- Version management
- Data preservation

### axiom-ui-testing

**Purpose:** XCUITest automation and accessibility

**Trigger patterns:**
- "XCUITest"
- "UI test"
- "accessibility"
- "XCUIElement"
- "automation"

**Testing patterns:**
- Element queries
- Accessibility identifiers
- Test case organization
- Async wait patterns
- Screenshot capture

---

## Routing Decision Tree

```
START
  |
  v
[Is this a build/compile issue?]
  |-- YES --> axiom-xcode-debugging
  |
  v
[Is this a memory issue?]
  |-- YES --> axiom-memory-debugging
  |
  v
[Is this a concurrency issue?]
  |-- YES --> axiom-swift-concurrency
  |
  v
[Is this SwiftUI work?]
  |-- YES --> [iOS 26+ styling?]
  |             |-- YES --> axiom-liquid-glass
  |             |-- NO  --> axiom-swiftui-26-ref
  |
  v
[Is this SwiftData work?]
  |-- YES --> [Migration from Core Data?]
  |             |-- YES --> axiom-database-migration
  |             |-- NO  --> axiom-swiftdata
  |
  v
[Is this UI testing?]
  |-- YES --> axiom-ui-testing
  |
  v
[No Axiom skill needed]
  --> Use Apple docs only
```

---

## Combining with Apple Docs

Each Axiom skill should be combined with relevant Apple documentation:

| Axiom Skill | Apple Docs to Fetch |
|-------------|---------------------|
| axiom-xcode-debugging | Xcode Build Settings, SPM |
| axiom-memory-debugging | Instruments, Memory Management |
| axiom-swift-concurrency | Swift Concurrency, Actor |
| axiom-swiftui-26-ref | SwiftUI, @Observable |
| axiom-liquid-glass | SwiftUI Materials, UIVisualEffect |
| axiom-swiftdata | SwiftData, Model |
| axiom-database-migration | Core Data Migration |
| axiom-ui-testing | XCTest, XCUITest |

---

## Context Injection Pattern

When invoking a superpowers skill, inject Axiom context like this:

```markdown
## Axiom iOS Skill Context

**Active Skill:** axiom-swift-concurrency

**Key Patterns from Axiom:**

1. Actor Isolation
   - Use `@MainActor` for UI-bound properties
   - Mark `nonisolated` for thread-safe methods
   - Prefer `actor` over `class` for mutable shared state

2. Sendable Conformance
   - Value types are implicitly Sendable
   - Use `@unchecked Sendable` sparingly with proper synchronization
   - Capture lists in closures must be Sendable

3. Task Safety
   - Use `withCheckedContinuation` not `withUnsafeContinuation`
   - Cancel tasks explicitly in deinit/onDisappear
   - Avoid capturing `self` in long-running tasks

---

## Apple Documentation Context

[Fetched Apple docs here]

---

Now proceeding with superpowers:systematic-debugging...
```

---

## Error Recovery

If an Axiom skill is referenced but not installed:

1. Log warning but continue
2. Provide Apple docs context only
3. Note which Axiom patterns would have been helpful
4. Suggest installing Axiom plugin

```
WARNING: Axiom skill 'axiom-swift-concurrency' not available.

Continuing with Apple documentation only.

For better iOS debugging support, install the Axiom iOS plugin.
```

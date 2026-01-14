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
┌─────────────────────────────────────────────────────────────────┐
│                    ios-superpowers                               │
│                                                                  │
│  1. Detect iOS context (Swift files, iOS APIs mentioned)        │
│  2. Extract relevant APIs/frameworks from task                  │
│  3. Invoke apple-docs-fetcher for each API                      │
│  4. Delegate to requested superpowers skill with docs context   │
│  5. Verify implementation against fetched docs                  │
└─────────────────────────────────────────────────────────────────┘
```

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
- Firebase, CloudKit, CoreData
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

**Cache results** in conversation context for use by superpowers skill.

### Step 4: Invoke Superpowers with Context

Delegate to the appropriate superpowers skill with prefixed context:

```
"Apple Documentation Context:
[Fetched docs summary]

Now proceeding with [superpowers skill]..."
```

### Step 5: Verify Against Docs

After superpowers completes, verify:
- [ ] No deprecated APIs introduced
- [ ] Concurrency patterns match Swift 6 requirements
- [ ] API usage matches documented signatures
- [ ] Thread safety requirements satisfied

## API Detection Patterns

```swift
// These patterns trigger apple-docs-fetcher:

// Concurrency
@MainActor           → fetch "Swift MainActor"
actor MyActor        → fetch "Swift actor"
nonisolated          → fetch "Swift nonisolated"
async/await          → fetch "Swift concurrency"
Task { }             → fetch "Swift Task"
withCheckedContinuation → fetch "Swift continuation"

// SwiftUI
@Published           → fetch "SwiftUI Published"
@StateObject         → fetch "SwiftUI StateObject"
@Observable          → fetch "Swift Observable"

// Vision/Camera
AVCaptureSession     → fetch "AVFoundation AVCaptureSession"
VNCoreMLModel        → fetch "Vision VNCoreMLModel"
CVPixelBuffer        → fetch "Core Video CVPixelBuffer"

// Auth
LAContext            → fetch "LocalAuthentication LAContext"
```

## Examples

### Example 1: Brainstorming iOS Feature

```
/ios-superpowers brainstorm biometric authentication flow
```

Orchestrator will:
1. Detect: LAContext, LocalAuthentication, Face ID
2. Fetch: LAContext docs, biometricType, evaluatePolicy
3. Invoke: superpowers:brainstorming with docs context

### Example 2: Planning Camera Feature

```
/ios-superpowers plan real-time object detection
```

Orchestrator will:
1. Detect: AVCaptureSession, Vision, VNCoreMLModel, CVPixelBuffer
2. Fetch: Camera setup docs, Vision request docs, buffer handling
3. Invoke: superpowers:writing-plans with docs context

### Example 3: Executing with Parallel Agents

```
/ios-superpowers parallel "Fix concurrency issues in CameraService, HouseholdItemDetector"
```

Orchestrator will:
1. Detect: actor, Sendable, nonisolated, continuation
2. Fetch: Swift 6 concurrency docs for each pattern
3. Invoke: superpowers:dispatching-parallel-agents
4. Each agent receives relevant Apple docs

## Integration with Existing Skills

This orchestrator enhances but doesn't replace:
- **ios-sprint-executor**: Use for full sprint orchestration
- **apple-docs-fetcher**: Called automatically by this skill
- **superpowers/***: Delegated to with docs context

## Fallback Behavior

If no iOS APIs detected:
- Log: "No iOS APIs detected, proceeding without Apple docs fetch"
- Delegate directly to superpowers skill
- Still available for manual docs fetch if needed

## Arguments

```
$ARGUMENTS format:
<action> <context>

Actions:
- brainstorm <topic>
- plan <feature>
- execute <plan-path>
- review
- debug <issue>
- tdd <feature>
- parallel <task-list>
```

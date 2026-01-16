# Axiom iOS Plugin Integration

This document describes how ios-superpowers integrates with Axiom iOS development agents.

## Overview

Axiom provides **25+ specialized agents** for iOS development, launched via the Task tool with a `subagent_type` parameter. These agents automatically have access to the sosumi.ai MCP for Apple documentation.

---

## Complete Axiom Agent Reference

### Build & Environment

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| Build Fixer | `axiom:build-fixer` | BUILD FAILED, module not found, compile error, linker error | Fix Xcode build failures |
| Build Optimizer | `axiom:build-optimizer` | slow build, build time, incremental | Speed up build times |
| SPM Resolver | `axiom:spm-conflict-resolver` | SPM, package resolution, dependency conflict | Resolve dependency conflicts |

### Performance

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| Memory Auditor | `axiom:memory-auditor` | memory leak, retain cycle, memory warning, EXC_BAD_ACCESS | Find memory issues |
| Energy Auditor | `axiom:energy-auditor` | battery, energy, power consumption | Optimize battery usage |
| Swift Performance | `axiom:swift-performance-analyzer` | slow, performance, allocation, lag | Optimize Swift code |
| SwiftUI Performance | `axiom:swiftui-performance-analyzer` | janky scroll, frame drop, view updates | Optimize SwiftUI views |

### Concurrency

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| Concurrency Auditor | `axiom:concurrency-auditor` | @MainActor, actor, Sendable, data race, Swift 6, isolation | Fix Swift 6 concurrency |

### UI/UX

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| Accessibility Auditor | `axiom:accessibility-auditor` | VoiceOver, accessibility, Dynamic Type, WCAG | Audit accessibility |
| SwiftUI Architecture | `axiom:swiftui-architecture-auditor` | @State, @Binding, architecture, state management | Improve SwiftUI patterns |
| SwiftUI Nav | `axiom:swiftui-nav-auditor` | navigation, deep link, NavigationStack | Fix navigation issues |
| Liquid Glass | `axiom:liquid-glass-auditor` | glass effect, blur, material, iOS 26 | iOS 26+ styling |
| TextKit Auditor | `axiom:textkit-auditor` | UITextView, Writing Tools, TextKit | Fix text handling |
| Modernization | `axiom:modernization-helper` | deprecated, iOS 17/18, modernize | Update legacy code |

### Data & Storage

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| Core Data Auditor | `axiom:core-data-auditor` | Core Data, migration, NSManagedObject, schema | Audit data layer |
| Storage Auditor | `axiom:storage-auditor` | file storage, documents, backup | Fix storage issues |
| iCloud Auditor | `axiom:icloud-auditor` | iCloud, CloudKit, sync | Fix cloud sync |
| Codable Auditor | `axiom:codable-auditor` | Codable, JSON, encoding, decoding | Fix encoding/decoding |

### Camera & Media

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| Camera Auditor | `axiom:camera-auditor` | camera, AVCapture, video, photo | Fix camera code |

### Networking & Security

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| Networking Auditor | `axiom:networking-auditor` | URLSession, API, connection, networking | Fix networking issues |
| Security Scanner | `axiom:security-privacy-scanner` | security, credentials, keychain, privacy | Security audit |

### Testing

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| Test Failure Analyzer | `axiom:test-failure-analyzer` | flaky test, CI fail, test passes locally | Diagnose test failures |
| Test Runner | `axiom:test-runner` | run tests, XCUITest | Execute tests |
| Test Debugger | `axiom:test-debugger` | debug test, fix test | Fix failing tests |
| Testing Auditor | `axiom:testing-auditor` | test quality, test audit | Audit test suite |

### In-App Purchase

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| IAP Auditor | `axiom:iap-auditor` | StoreKit, purchase, subscription, IAP | Audit in-app purchases |
| IAP Implementation | `axiom:iap-implementation` | add subscription, implement IAP | Implement IAP |

### Utility

| Agent | subagent_type | Trigger Patterns | Primary Use Case |
|-------|---------------|------------------|------------------|
| Simulator Tester | `axiom:simulator-tester` | visual verification, screenshots, simulator | Screenshot + test |

---

## Routing Decision Tree

```
START
  │
  ├── [Build/Compile Issue?]
  │   ├── BUILD FAILED, module not found → axiom:build-fixer
  │   ├── slow build, build time → axiom:build-optimizer
  │   └── SPM, package conflict → axiom:spm-conflict-resolver
  │
  ├── [Performance Issue?]
  │   ├── memory leak, retain cycle → axiom:memory-auditor
  │   ├── battery, energy → axiom:energy-auditor
  │   ├── SwiftUI slow, janky → axiom:swiftui-performance-analyzer
  │   └── general slow/lag → axiom:swift-performance-analyzer
  │
  ├── [Concurrency Issue?]
  │   └── @MainActor, actor, Sendable → axiom:concurrency-auditor
  │
  ├── [UI/UX Issue?]
  │   ├── accessibility, VoiceOver → axiom:accessibility-auditor
  │   ├── navigation, deep link → axiom:swiftui-nav-auditor
  │   ├── Liquid Glass, blur → axiom:liquid-glass-auditor
  │   ├── TextKit, UITextView → axiom:textkit-auditor
  │   ├── deprecated, modernize → axiom:modernization-helper
  │   └── SwiftUI architecture → axiom:swiftui-architecture-auditor
  │
  ├── [Data/Storage Issue?]
  │   ├── Core Data, schema → axiom:core-data-auditor
  │   ├── iCloud, CloudKit → axiom:icloud-auditor
  │   ├── file storage, backup → axiom:storage-auditor
  │   └── Codable, JSON → axiom:codable-auditor
  │
  ├── [Camera/Media Issue?]
  │   └── camera, AVCapture → axiom:camera-auditor
  │
  ├── [Networking/Security Issue?]
  │   ├── networking, URLSession → axiom:networking-auditor
  │   └── security, credentials → axiom:security-privacy-scanner
  │
  ├── [Testing Issue?]
  │   ├── flaky test, CI fail → axiom:test-failure-analyzer
  │   ├── run tests → axiom:test-runner
  │   ├── debug test → axiom:test-debugger
  │   └── test quality → axiom:testing-auditor
  │
  ├── [IAP Issue?]
  │   ├── audit purchases → axiom:iap-auditor
  │   └── implement IAP → axiom:iap-implementation
  │
  └── [No Match]
      └── Use sosumi MCP docs + superpowers only
```

---

## How to Launch Axiom Agents

Use the Task tool with the appropriate `subagent_type`:

### Basic Invocation

```
Task(
    description: "Fix memory leak in ViewModel",
    prompt: "Analyze InventoryViewModel.swift for retain cycles and memory leaks. The app shows increasing memory usage after loading catalog.",
    subagent_type: "axiom:memory-auditor"
)
```

### With Specific Files

```
Task(
    description: "Audit concurrency in camera service",
    prompt: """
    Audit the following files for Swift 6 concurrency violations:
    - Sources/CameraFeature/CameraService.swift
    - Sources/CameraFeature/PhotoProcessor.swift

    Check for:
    - Missing @MainActor annotations
    - Sendable conformance issues
    - Actor isolation problems
    """,
    subagent_type: "axiom:concurrency-auditor"
)
```

### Parallel Execution

```
# Launch multiple agents in one message for parallel execution

Task(
    description: "Audit accessibility in ItemCard",
    prompt: "Check ItemCard.swift for accessibility issues...",
    subagent_type: "axiom:accessibility-auditor"
)

Task(
    description: "Audit memory in InventoryViewModel",
    prompt: "Check InventoryViewModel.swift for retain cycles...",
    subagent_type: "axiom:memory-auditor"
)
```

---

## Combining with Apple Documentation

Axiom agents automatically have access to sosumi.ai MCP. However, you can also pre-fetch documentation:

```
# 1. Fetch relevant Apple docs first
mcp__sosumi__searchAppleDocumentation(query: "Swift MainActor")
mcp__sosumi__fetchAppleDocumentation(path: "/documentation/swift/mainactor")

# 2. Include doc context in agent prompt
Task(
    description: "Fix actor isolation in ViewModel",
    prompt: """
    Context from Apple docs:
    [Insert fetched documentation summary]

    Analyze HomeViewModel.swift for @MainActor issues...
    """,
    subagent_type: "axiom:concurrency-auditor"
)
```

---

## Axiom Commands Reference

These commands invoke Axiom agents directly:

| Command | Agent Launched | When to Use |
|---------|----------------|-------------|
| `/axiom:status` | None (info only) | See project health dashboard |
| `/axiom:fix-build` | `axiom:build-fixer` | BUILD FAILED errors |
| `/axiom:optimize-build` | `axiom:build-optimizer` | Slow incremental builds |
| `/axiom:run-tests` | `axiom:test-runner` | Run and parse test results |
| `/axiom:screenshot` | `axiom:simulator-tester` | Capture simulator screenshot |
| `/axiom:test-simulator` | `axiom:simulator-tester` | Visual verification |
| `/axiom:ask <question>` | Varies | Route iOS question to appropriate agent |

### Audit Commands

| Command | Agent Launched |
|---------|----------------|
| `/axiom:audit accessibility` | `axiom:accessibility-auditor` |
| `/axiom:audit concurrency` | `axiom:concurrency-auditor` |
| `/axiom:audit memory` | `axiom:memory-auditor` |
| `/axiom:audit swiftui-performance` | `axiom:swiftui-performance-analyzer` |
| `/axiom:audit swift-performance` | `axiom:swift-performance-analyzer` |
| `/axiom:audit security` | `axiom:security-privacy-scanner` |
| `/axiom:audit liquid-glass` | `axiom:liquid-glass-auditor` |
| `/axiom:audit core-data` | `axiom:core-data-auditor` |
| `/axiom:audit camera` | `axiom:camera-auditor` |
| `/axiom:audit networking` | `axiom:networking-auditor` |
| `/axiom:audit storage` | `axiom:storage-auditor` |
| `/axiom:audit icloud` | `axiom:icloud-auditor` |
| `/axiom:audit codable` | `axiom:codable-auditor` |
| `/axiom:audit energy` | `axiom:energy-auditor` |
| `/axiom:audit swiftui-nav` | `axiom:swiftui-nav-auditor` |
| `/axiom:audit swiftui-architecture` | `axiom:swiftui-architecture-auditor` |
| `/axiom:audit textkit` | `axiom:textkit-auditor` |
| `/axiom:audit modernization` | `axiom:modernization-helper` |
| `/axiom:audit testing` | `axiom:testing-auditor` |
| `/axiom:audit test-failures` | `axiom:test-failure-analyzer` |
| `/axiom:audit iap` | `axiom:iap-auditor` |

---

## Error Recovery

If an Axiom agent is unavailable:

```
WARNING: Axiom agent 'axiom:concurrency-auditor' not available.

Falling back to:
1. Direct sosumi MCP documentation fetch
2. superpowers workflow without Axiom patterns

Continuing with Apple documentation only.
```

**Recovery steps:**
1. Fetch relevant Apple docs via sosumi MCP
2. Proceed with superpowers skill (e.g., systematic-debugging)
3. Note which Axiom patterns would have been helpful
4. Report degraded functionality to user

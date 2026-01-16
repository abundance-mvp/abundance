---
name: ios-debug
description: Debug iOS issues using Axiom agents and Apple documentation via sosumi.ai MCP
---

# iOS Debug Command

Systematic iOS debugging using Axiom agents and sosumi.ai documentation.

## Usage

```
/ios-debug [issue-description]
/ios-debug [error-message]
```

## Examples

```
/ios-debug "BUILD FAILED - module 'AVFoundation' not found"
/ios-debug "App crashes on launch with EXC_BAD_ACCESS"
/ios-debug "Swift 6 actor isolation error in ViewModel"
/ios-debug "Memory leak in image processing"
/ios-debug "VoiceOver doesn't announce button labels"
/ios-debug "iCloud sync not working"
```

## What This Does

1. **Run Project Health Check**
   ```
   /axiom:status
   ```

2. **Classify Issue Type → Select Axiom Agent**

3. **Launch Axiom Agent via Task Tool**
   ```
   Task(
       description: "[issue summary]",
       prompt: "[detailed context]",
       subagent_type: "[axiom:agent-name]"
   )
   ```

4. **Fetch Apple Documentation** (if needed)
   ```
   mcp__sosumi__searchAppleDocumentation(query: "[API]")
   mcp__sosumi__fetchAppleDocumentation(path: "[doc path]")
   ```

5. **Apply Fix and Verify**

---

## Issue Routing Matrix

### Build & Environment

| Symptoms | Axiom Agent | Task subagent_type |
|----------|-------------|-------------------|
| BUILD FAILED, module not found, compile error | Build Fixer | `axiom:build-fixer` |
| slow build, build time, incremental | Build Optimizer | `axiom:build-optimizer` |
| SPM, package resolution, dependency conflict | SPM Resolver | `axiom:spm-conflict-resolver` |

### Performance

| Symptoms | Axiom Agent | Task subagent_type |
|----------|-------------|-------------------|
| memory leak, retain cycle, EXC_BAD_ACCESS | Memory Auditor | `axiom:memory-auditor` |
| battery drain, energy, power | Energy Auditor | `axiom:energy-auditor` |
| SwiftUI slow, janky scroll, frame drop | SwiftUI Performance | `axiom:swiftui-performance-analyzer` |
| slow, lag, allocations | Swift Performance | `axiom:swift-performance-analyzer` |

### Concurrency

| Symptoms | Axiom Agent | Task subagent_type |
|----------|-------------|-------------------|
| @MainActor, actor-isolated, Sendable | Concurrency Auditor | `axiom:concurrency-auditor` |
| data race, Swift 6, isolation | Concurrency Auditor | `axiom:concurrency-auditor` |

### UI/UX

| Symptoms | Axiom Agent | Task subagent_type |
|----------|-------------|-------------------|
| accessibility, VoiceOver, Dynamic Type | Accessibility Auditor | `axiom:accessibility-auditor` |
| SwiftUI architecture, state management | SwiftUI Architecture | `axiom:swiftui-architecture-auditor` |
| navigation, deep link, NavigationStack | SwiftUI Nav Auditor | `axiom:swiftui-nav-auditor` |
| Liquid Glass, blur, material, iOS 26 | Liquid Glass Auditor | `axiom:liquid-glass-auditor` |
| TextKit, UITextView, Writing Tools | TextKit Auditor | `axiom:textkit-auditor` |
| deprecated, iOS 17/18, modernize | Modernization Helper | `axiom:modernization-helper` |

### Data & Storage

| Symptoms | Axiom Agent | Task subagent_type |
|----------|-------------|-------------------|
| Core Data, migration, schema | Core Data Auditor | `axiom:core-data-auditor` |
| iCloud, CloudKit, sync | iCloud Auditor | `axiom:icloud-auditor` |
| file storage, documents, backup | Storage Auditor | `axiom:storage-auditor` |
| Codable, JSON, encoding/decoding | Codable Auditor | `axiom:codable-auditor` |

### Camera & Media

| Symptoms | Axiom Agent | Task subagent_type |
|----------|-------------|-------------------|
| camera, AVCapture, video, photo | Camera Auditor | `axiom:camera-auditor` |

### Networking & Security

| Symptoms | Axiom Agent | Task subagent_type |
|----------|-------------|-------------------|
| networking, URLSession, API, connection | Networking Auditor | `axiom:networking-auditor` |
| security, credentials, keychain, privacy | Security Scanner | `axiom:security-privacy-scanner` |

### Testing

| Symptoms | Axiom Agent | Task subagent_type |
|----------|-------------|-------------------|
| flaky test, CI fail, test passes locally | Test Failure Analyzer | `axiom:test-failure-analyzer` |
| debug test, fix test | Test Debugger | `axiom:test-debugger` |
| test quality, test audit | Testing Auditor | `axiom:testing-auditor` |

### In-App Purchase

| Symptoms | Axiom Agent | Task subagent_type |
|----------|-------------|-------------------|
| IAP, StoreKit, purchase, subscription | IAP Auditor | `axiom:iap-auditor` |

---

## Workflow

```
1. Parse error/issue description
2. Run /axiom:status for project health
3. Route to Axiom agent via Task tool
4. Agent uses sosumi.ai MCP for Apple docs
5. Agent applies fix pattern
6. Write test to verify fix
7. Run swift test
8. Document solution
```

---

## Integration with superpowers:systematic-debugging

This command wraps superpowers:systematic-debugging with iOS-specific enhancements:
- Automatic Axiom agent selection via Task tool
- Apple docs grounding via sosumi.ai MCP (agents have automatic access)
- iOS-specific diagnostic patterns from Axiom

---

## Quick Axiom Commands

For common issues, use direct Axiom commands:

| Command | When to Use |
|---------|-------------|
| `/axiom:fix-build` | BUILD FAILED errors |
| `/axiom:optimize-build` | Slow incremental builds |
| `/axiom:run-tests` | Run and debug tests |
| `/axiom:screenshot` | Capture visual state |
| `/axiom:audit accessibility` | VoiceOver issues |
| `/axiom:audit concurrency` | Swift 6 violations |
| `/axiom:audit memory` | Retain cycles, leaks |
| `/axiom:audit security` | Credentials, privacy |

---

## Output

- Root cause identified
- Fix applied with test
- Documentation reference (sosumi.ai)
- Commit with explanation

---
name: ios-debug
description: Debug iOS issues using Axiom agents and skills
---

# iOS Debug Command

Systematic iOS debugging using Axiom agents and skills.

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

3. **Load Axiom Skill for Context**
   ```
   Skill(skill="axiom-{domain-skill}")
   ```

4. **Launch Axiom Agent via Task Tool**
   ```
   Task(
       description: "[issue summary]",
       prompt: "[detailed context]",
       subagent_type: "[axiom:agent-name]"
   )
   ```

5. **Fetch Apple Documentation** (if needed)
   ```
   Skill(skill="axiom-apple-docs-research", args="[API name]")
   ```

6. **Apply Fix and Verify**

---

## Issue Routing Matrix

### Build & Environment

| Symptoms | Axiom Agent | Axiom Skill |
|----------|-------------|-------------|
| BUILD FAILED, module not found, compile error | `axiom:build-fixer` | `axiom-xcode-debugging` |
| slow build, build time, incremental | `axiom:build-optimizer` | `axiom-build-performance` |
| SPM, package resolution, dependency conflict | `axiom:spm-conflict-resolver` | `axiom-build-debugging` |

### Performance

| Symptoms | Axiom Agent | Axiom Skill |
|----------|-------------|-------------|
| memory leak, retain cycle, EXC_BAD_ACCESS | `axiom:memory-auditor` | `axiom-memory-debugging` |
| battery drain, energy, power | `axiom:energy-auditor` | `axiom-energy-diag` |
| SwiftUI slow, janky scroll, frame drop | `axiom:swiftui-performance-analyzer` | `axiom-swiftui-performance` |
| slow, lag, allocations | `axiom:swift-performance-analyzer` | `axiom-performance-profiling` |

### Concurrency

| Symptoms | Axiom Agent | Axiom Skill |
|----------|-------------|-------------|
| @MainActor, actor-isolated, Sendable | `axiom:concurrency-auditor` | `axiom-swift-concurrency` |
| data race, Swift 6, isolation | `axiom:concurrency-auditor` | `axiom-swift-concurrency` |

### UI/UX

| Symptoms | Axiom Agent | Axiom Skill |
|----------|-------------|-------------|
| accessibility, VoiceOver, Dynamic Type | `axiom:accessibility-auditor` | `axiom-accessibility-diag` |
| SwiftUI architecture, state management | `axiom:swiftui-architecture-auditor` | `axiom-swiftui-architecture` |
| navigation, deep link, NavigationStack | `axiom:swiftui-nav-auditor` | `axiom-swiftui-nav-diag` |
| Liquid Glass, blur, material, iOS 26 | `axiom:liquid-glass-auditor` | `axiom-liquid-glass` |
| TextKit, UITextView, Writing Tools | `axiom:textkit-auditor` | `axiom-textkit-ref` |
| deprecated, iOS 17/18, modernize | `axiom:modernization-helper` | - |

### Data & Storage

| Symptoms | Axiom Agent | Axiom Skill |
|----------|-------------|-------------|
| Core Data, migration, schema | `axiom:core-data-auditor` | `axiom-core-data-diag` |
| iCloud, CloudKit, sync | `axiom:icloud-auditor` | `axiom-cloud-sync-diag` |
| file storage, documents, backup | `axiom:storage-auditor` | `axiom-storage-diag` |
| Codable, JSON, encoding/decoding | `axiom:codable-auditor` | `axiom-codable` |

### Camera & Media

| Symptoms | Axiom Agent | Axiom Skill |
|----------|-------------|-------------|
| camera, AVCapture, video, photo | `axiom:camera-auditor` | `axiom-avfoundation-ref` |

### Networking & Security

| Symptoms | Axiom Agent | Axiom Skill |
|----------|-------------|-------------|
| networking, URLSession, API, connection | `axiom:networking-auditor` | `axiom-networking-diag` |
| security, credentials, keychain, privacy | `axiom:security-privacy-scanner` | `axiom-privacy-ux` |

### Testing

| Symptoms | Axiom Agent | Axiom Skill |
|----------|-------------|-------------|
| flaky test, CI fail, test passes locally | `axiom:test-failure-analyzer` | `axiom-ui-testing` |
| debug test, fix test | `axiom:test-debugger` | `axiom-ui-testing` |
| test quality, test audit | `axiom:testing-auditor` | `axiom-ui-testing` |

### In-App Purchase

| Symptoms | Axiom Agent | Axiom Skill |
|----------|-------------|-------------|
| IAP, StoreKit, purchase, subscription | `axiom:iap-auditor` | `axiom-storekit-ref` |

---

## Workflow

```
1. Parse error/issue description
2. Run /axiom:status for project health
3. Load Axiom skill for domain context
4. Route to Axiom agent via Task tool
5. Agent applies fix pattern
6. Write test to verify fix
7. Run swift test
8. Document solution
```

---

## Integration with superpowers:systematic-debugging

This command wraps superpowers:systematic-debugging with iOS-specific enhancements:
- Automatic Axiom agent selection via Task tool
- Apple docs grounding via `axiom-apple-docs-research` skill
- iOS-specific diagnostic patterns from Axiom skills

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

## Error Handling

**No fallbacks.** If an Axiom agent or skill is unavailable, STOP and explain:

- Which agent/skill was needed
- What domain was detected
- How to resolve the issue

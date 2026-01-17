# Axiom iOS Plugin Integration

Complete reference for Axiom agents, skills, commands, and hooks.

---

## Agents (via Task tool)

Launch agents using `Task(subagent_type="axiom:{agent-name}")`.

### Build & Environment

| Agent | subagent_type | Trigger Patterns |
|-------|---------------|------------------|
| Build Fixer | `axiom:build-fixer` | BUILD FAILED, module not found, compile error, linker error |
| Build Optimizer | `axiom:build-optimizer` | slow build, build time, incremental |
| SPM Conflict Resolver | `axiom:spm-conflict-resolver` | SPM, package resolution, dependency conflict |

### Code Quality

| Agent | subagent_type | Trigger Patterns |
|-------|---------------|------------------|
| Concurrency Auditor | `axiom:concurrency-auditor` | @MainActor, actor, Sendable, data race, Swift 6 |
| Memory Auditor | `axiom:memory-auditor` | memory leak, retain cycle, EXC_BAD_ACCESS |
| Energy Auditor | `axiom:energy-auditor` | battery, energy, power consumption |
| Swift Performance Analyzer | `axiom:swift-performance-analyzer` | slow, allocation, performance |
| Codable Auditor | `axiom:codable-auditor` | Codable, JSON, encoding, decoding |

### UI & Design

| Agent | subagent_type | Trigger Patterns |
|-------|---------------|------------------|
| Accessibility Auditor | `axiom:accessibility-auditor` | VoiceOver, accessibility, Dynamic Type, WCAG |
| SwiftUI Architecture Auditor | `axiom:swiftui-architecture-auditor` | @State, MVVM, architecture, state management |
| SwiftUI Nav Auditor | `axiom:swiftui-nav-auditor` | NavigationStack, deep link, navigation |
| SwiftUI Performance Analyzer | `axiom:swiftui-performance-analyzer` | janky scroll, frame drop, view updates |
| Liquid Glass Auditor | `axiom:liquid-glass-auditor` | Liquid Glass, glass effect, blur, iOS 26 |
| TextKit Auditor | `axiom:textkit-auditor` | TextKit, UITextView, Writing Tools |

### Camera & Media

| Agent | subagent_type | Trigger Patterns |
|-------|---------------|------------------|
| Camera Auditor | `axiom:camera-auditor` | camera, AVCapture, video, photo |

### Persistence & Storage

| Agent | subagent_type | Trigger Patterns |
|-------|---------------|------------------|
| Core Data Auditor | `axiom:core-data-auditor` | Core Data, migration, NSManagedObject, schema |
| iCloud Auditor | `axiom:icloud-auditor` | iCloud, CloudKit, sync |
| Storage Auditor | `axiom:storage-auditor` | file storage, documents, backup |

### Networking & Security

| Agent | subagent_type | Trigger Patterns |
|-------|---------------|------------------|
| Networking Auditor | `axiom:networking-auditor` | URLSession, API, connection, networking |
| Security Privacy Scanner | `axiom:security-privacy-scanner` | security, credentials, keychain, privacy |

### Testing

| Agent | subagent_type | Trigger Patterns |
|-------|---------------|------------------|
| Test Failure Analyzer | `axiom:test-failure-analyzer` | flaky test, CI fail, test passes locally |
| Test Runner | `axiom:test-runner` | run tests, XCUITest |
| Test Debugger | `axiom:test-debugger` | debug test, fix test |
| Testing Auditor | `axiom:testing-auditor` | test quality, test audit |
| Simulator Tester | `axiom:simulator-tester` | visual verification, screenshots, simulator |

### In-App Purchase

| Agent | subagent_type | Trigger Patterns |
|-------|---------------|------------------|
| IAP Auditor | `axiom:iap-auditor` | StoreKit, purchase, subscription, IAP |
| IAP Implementation | `axiom:iap-implementation` | add subscription, implement IAP |

---

## Skills (via Skill tool)

Invoke skills using `Skill(skill="axiom-{skill-name}")`.

### UI & Design

| Skill | Purpose |
|-------|---------|
| `axiom-hig` | Quick design decisions and HIG compliance |
| `axiom-hig-ref` | Comprehensive HIG reference with code examples |
| `axiom-liquid-glass` | Implementing Liquid Glass effects |
| `axiom-liquid-glass-ref` | Complete Liquid Glass adoption guide |
| `axiom-swiftui-architecture` | Separating logic from views |
| `axiom-swiftui-layout` | Adaptive layouts for iPad, iOS 26 |
| `axiom-swiftui-layout-ref` | ViewThatFits, AnyLayout, Layout protocol |
| `axiom-swiftui-nav` | NavigationStack vs NavigationSplitView |
| `axiom-swiftui-nav-diag` | Navigation failures and deep links |
| `axiom-swiftui-performance` | Sluggish apps and animation stutters |
| `axiom-swiftui-debugging` | View updates, preview crashes, layout |
| `axiom-swiftui-debugging-diag` | Complex state dependencies |
| `axiom-swiftui-gestures` | Tap, drag, long press, rotation |
| `axiom-swiftui-26-ref` | iOS 26 SwiftUI features |
| `axiom-swiftui-animation-ref` | Complete animation reference |
| `axiom-swiftui-containers-ref` | SwiftUI containers reference |
| `axiom-textkit-ref` | TextKit 2 and Writing Tools |
| `axiom-typography-ref` | San Francisco fonts, Dynamic Type |
| `axiom-uikit-animation-debugging` | CAAnimation issues |

### Computer Vision & ML

| Skill | Purpose |
|-------|---------|
| `axiom-vision` | Subject segmentation, pose detection, OCR |
| `axiom-coreml` | Deploy custom ML models, LLM inference |
| `axiom-speech` | Speech-to-text (iOS 26+) |
| `axiom-foundation-models` | On-device AI with Apple framework |
| `axiom-foundation-models-ref` | Complete Foundation Models API |
| `axiom-foundation-models-diag` | Context limits, guardrails, slow generation |

### Debugging

| Skill | Purpose |
|-------|---------|
| `axiom-xcode-debugging` | BUILD FAILED, simulator hangs |
| `axiom-memory-debugging` | Memory leaks, retain cycles |
| `axiom-build-debugging` | Dependency conflicts, SPM failures |
| `axiom-build-performance` | Slow builds, type checking |
| `axiom-performance-profiling` | Instruments profiling |
| `axiom-auto-layout-debugging` | Constraint conflicts |
| `axiom-deep-link-debugging` | Debug-only deep links |
| `axiom-objc-block-retain-cycles` | Block memory leaks |

### Concurrency

| Skill | Purpose |
|-------|---------|
| `axiom-swift-concurrency` | Swift 6 actor isolation, Sendable |

### Persistence & Storage

| Skill | Purpose |
|-------|---------|
| `axiom-codable` | JSON encoding/decoding |
| `axiom-core-data` | Stack setup, concurrency |
| `axiom-core-data-diag` | Schema migrations, thread-confinement |
| `axiom-swiftdata` | @Model, @Query, CloudKit |
| `axiom-swiftdata-migration` | Custom schema migrations |
| `axiom-swiftdata-migration-diag` | Migration crashes |
| `axiom-database-migration` | Schema changes |
| `axiom-cloud-sync` | CloudKit vs iCloud Drive |
| `axiom-cloud-sync-diag` | Sync failures, CloudKit errors |
| `axiom-cloudkit-ref` | CloudKit API reference |
| `axiom-icloud-drive-ref` | File-based iCloud sync |
| `axiom-storage` | Storage location decisions |
| `axiom-storage-diag` | Missing files, data recovery |
| `axiom-storage-management-ref` | Cache management |
| `axiom-file-protection-ref` | File encryption |
| `axiom-grdb` | Raw SQL queries |
| `axiom-sqlitedata` | SQLiteData patterns |
| `axiom-sqlitedata-migration` | SwiftData to SQLiteData |
| `axiom-realm-migration-ref` | Realm to SwiftData |

### Integration

| Skill | Purpose |
|-------|---------|
| `axiom-apple-docs-research` | Fetch Apple Developer documentation |
| `axiom-app-intents` | Siri, Apple Intelligence, Shortcuts |
| `axiom-app-intents-ref` | App Intents API reference |
| `axiom-app-shortcuts-ref` | App Shortcuts implementation |
| `axiom-app-discoverability` | Complete discoverability strategy |
| `axiom-core-spotlight-ref` | Core Spotlight indexing |
| `axiom-extensions-widgets` | Widgets, Live Activities |
| `axiom-extensions-widgets-ref` | Complete WidgetKit API |
| `axiom-in-app-purchases` | StoreKit 2 implementation |
| `axiom-storekit-ref` | Complete StoreKit 2 API |
| `axiom-networking` | UDP/TCP connections |
| `axiom-networking-diag` | Connection timeouts, TLS |
| `axiom-network-framework-ref` | Network.framework API |
| `axiom-now-playing` | Lock Screen/Control Center |
| `axiom-avfoundation-ref` | AVFoundation audio APIs |
| `axiom-core-location` | Location services |
| `axiom-core-location-ref` | Modern Core Location APIs |
| `axiom-core-location-diag` | Location update issues |
| `axiom-haptics` | Core Haptics patterns |
| `axiom-localization` | App localization |
| `axiom-privacy-ux` | Privacy manifests, permissions |
| `axiom-energy-ref` | Energy optimization APIs |
| `axiom-energy-diag` | Battery drain diagnosis |

### Testing

| Skill | Purpose |
|-------|---------|
| `axiom-ui-testing` | Recording UI tests, flaky tests |

### Accessibility

| Skill | Purpose |
|-------|---------|
| `axiom-accessibility-diag` | VoiceOver issues, WCAG compliance |

---

## Commands

| Command | Purpose |
|---------|---------|
| `/axiom:ask` | Route question to appropriate skill |
| `/axiom:audit <area>` | Run specific audit |
| `/axiom:status` | Project health dashboard |
| `/axiom:fix-build` | Launch build-fixer agent |
| `/axiom:optimize-build` | Launch build-optimizer agent |
| `/axiom:screenshot` | Capture simulator screenshot |
| `/axiom:test-simulator` | Launch simulator testing |

### Audit Areas

```
/axiom:audit accessibility
/axiom:audit codable
/axiom:audit concurrency
/axiom:audit core-data
/axiom:audit energy
/axiom:audit icloud
/axiom:audit iap
/axiom:audit liquid-glass
/axiom:audit memory
/axiom:audit modernization
/axiom:audit networking
/axiom:audit security
/axiom:audit storage
/axiom:audit swift-performance
/axiom:audit swiftui-architecture
/axiom:audit swiftui-nav
/axiom:audit swiftui-performance
/axiom:audit test-failures
/axiom:audit testing
/axiom:audit textkit
```

---

## Hooks (Automatic)

| Hook | Event | Action |
|------|-------|--------|
| Build Failure Auto-Trigger | xcodebuild/swift build fails | Suggests `/axiom:fix-build` |
| Session Environment Check | SessionStart | Checks zombie processes (>5), Derived Data (>10GB) |
| Core Data Model Protection | Edit .xcdatamodeld | Warns about migrations, suggests audit |
| Swift Auto-Format | Edit .swift files | Runs `swiftformat` |

---

## Agent Invocation Examples

### Basic

```
Task(
    description="Fix memory leak",
    prompt="Analyze ViewModel for retain cycles",
    subagent_type="axiom:memory-auditor"
)
```

### With Files

```
Task(
    description="Audit concurrency",
    prompt="""
    Audit these files for Swift 6 violations:
    - Sources/CameraFeature/CameraService.swift
    - Sources/CameraFeature/PhotoProcessor.swift
    """,
    subagent_type="axiom:concurrency-auditor"
)
```

### Parallel

```
# Launch multiple agents in one message
Task(
    description="Audit accessibility in ItemCard",
    prompt="Check ItemCard.swift for accessibility issues",
    subagent_type="axiom:accessibility-auditor"
)

Task(
    description="Audit memory in InventoryViewModel",
    prompt="Check InventoryViewModel.swift for retain cycles",
    subagent_type="axiom:memory-auditor"
)
```

---

## Skill Invocation Examples

### Load Context

```
Skill(skill="axiom-swift-concurrency")
```

### With Args

```
Skill(skill="axiom-apple-docs-research", args="AVCaptureSession configuration")
```

---
name: ios-superpowers
description: Deterministic iOS orchestrator that routes to Axiom agents and skills based on domain classification. Use instead of raw superpowers for ALL iOS/Swift work.
---

# ios-superpowers v2

**CRITICAL:** Use this instead of raw superpowers skills for ALL iOS/Swift work.

## 0. MCP Server Availability

Two MCP servers provide build and documentation tools. Check availability at session start.

| Server | Tool Prefix | Requires | Use For |
|--------|-------------|----------|---------|
| **Xcode Native Bridge** (`xcode`) | `mcp__xcode__*` | Xcode running with project open, macOS 26 | Builds, previews, diagnostics, Apple docs, project-aware file ops |
| **XcodeBuildMCP** (`XcodeBuildMCP`) | `mcp__XcodeBuildMCP__*` | None (headless) | Simulators, devices, UI automation, debugging |

**Availability check:** At session start, try `mcp__xcode__XcodeListWindows`. If it fails, mcpbridge is unavailable — fall back to `swift build` and `axiom-apple-docs-research` for all operations. Log: "mcpbridge unavailable — using CLI fallback."

---

## Arguments

```
<action> <context>

Actions: debug | tdd | review | plan | execute | brainstorm | parallel
```

---

## 1. Domain Detection

Match context against patterns. First match wins.

| Priority | Domain | Patterns |
|----------|--------|----------|
| 1 | build | `BUILD FAILED`, `module not found`, `linker error`, `compile error` |
| 2 | build-slow | `slow build`, `build time`, `incremental build` |
| 3 | spm | `SPM`, `Package.swift`, `package resolution`, `dependency conflict` |
| 4 | concurrency | `@MainActor`, `actor`, `Sendable`, `data race`, `Swift 6`, `nonisolated`, `isolation` |
| 5 | memory | `memory leak`, `retain cycle`, `EXC_BAD_ACCESS`, `deinit not called` |
| 6 | energy | `battery`, `energy`, `power consumption`, `background drain` |
| 7 | ui-arch | `@State`, `@Binding`, `MVVM`, `view model`, `state management`, `ObservableObject` |
| 8 | ui-nav | `NavigationStack`, `NavigationPath`, `deep link`, `navigation` |
| 9 | ui-perf | `janky`, `frame drop`, `LazyVStack`, `view updates`, `ScrollView slow` |
| 10 | ui-access | `VoiceOver`, `accessibility`, `Dynamic Type`, `WCAG` |
| 11 | ui-glass | `Liquid Glass`, `glass effect`, `.blur`, `material`, `iOS 26` |
| 12 | ui-text | `TextKit`, `UITextView`, `Writing Tools`, `NSTextStorage` |
| 13 | media-camera | `camera`, `AVCapture`, `photo`, `video capture` |
| 14 | media-audio | `AVAudioSession`, `audio`, `AVAudioEngine` |
| 15 | media-vision | `Vision`, `VNRequest`, `object detection`, `OCR` |
| 16 | data-core | `Core Data`, `NSManagedObject`, `migration`, `@FetchRequest` |
| 17 | data-swift | `SwiftData`, `@Model`, `@Query`, `ModelContext` |
| 18 | data-icloud | `iCloud`, `CloudKit`, `sync`, `NSFileCoordinator` |
| 19 | data-codable | `Codable`, `JSON`, `encoding`, `decoding`, `JSONDecoder` |
| 20 | data-storage | `file storage`, `documents`, `backup`, `FileManager` |
| 21 | network | `URLSession`, `API`, `connection`, `Network.framework` |
| 22 | security | `security`, `credentials`, `keychain`, `Privacy Manifest` |
| 23 | test | `XCUITest`, `XCTest`, `flaky`, `test fail`, `swift test` |
| 24 | iap | `StoreKit`, `subscription`, `purchase`, `IAP`, `transaction` |
| 25 | location | `CLLocation`, `GPS`, `geofence`, `location services` |
| 26 | intents | `App Intents`, `Siri`, `Shortcuts`, `Spotlight` |
| 27 | widgets | `Widget`, `Live Activity`, `WidgetKit` |
| 28 | foundation-models | `Foundation Models`, `Apple Intelligence`, `on-device AI` |
| 99 | general | (no match) |

---

## 2. Routing Matrix

Deterministic mapping: `(action, domain) → (axiom_agent, axiom_skill, superpowers_skill)`

### debug Action

| Domain | Axiom Agent | Axiom Skill | Superpowers |
|--------|-------------|-------------|-------------|
| build | `axiom:build-fixer` | `axiom-xcode-debugging` | - |
| build-slow | `axiom:build-optimizer` | `axiom-build-performance` | - |
| spm | `axiom:spm-conflict-resolver` | `axiom-build-debugging` | - |
| concurrency | `axiom:concurrency-auditor` | `axiom-swift-concurrency` | `systematic-debugging` |
| memory | `axiom:memory-auditor` | `axiom-memory-debugging` | `systematic-debugging` |
| energy | `axiom:energy-auditor` | `axiom-energy-diag` | `systematic-debugging` |
| ui-arch | `axiom:swiftui-architecture-auditor` | `axiom-swiftui-architecture` | `systematic-debugging` |
| ui-nav | `axiom:swiftui-nav-auditor` | `axiom-swiftui-nav-diag` | `systematic-debugging` |
| ui-perf | `axiom:swiftui-performance-analyzer` | `axiom-swiftui-performance` | `systematic-debugging` |
| ui-access | `axiom:accessibility-auditor` | `axiom-accessibility-diag` | `systematic-debugging` |
| ui-glass | `axiom:liquid-glass-auditor` | `axiom-liquid-glass` | `systematic-debugging` |
| ui-text | `axiom:textkit-auditor` | `axiom-textkit-ref` | `systematic-debugging` |
| media-camera | `axiom:camera-auditor` | `axiom-avfoundation-ref` | `systematic-debugging` |
| media-audio | - | `axiom-avfoundation-ref` | `systematic-debugging` |
| media-vision | - | `axiom-vision` | `systematic-debugging` |
| data-core | `axiom:core-data-auditor` | `axiom-core-data-diag` | `systematic-debugging` |
| data-swift | - | `axiom-swiftdata-migration-diag` | `systematic-debugging` |
| data-icloud | `axiom:icloud-auditor` | `axiom-cloud-sync-diag` | `systematic-debugging` |
| data-codable | `axiom:codable-auditor` | `axiom-codable` | `systematic-debugging` |
| data-storage | `axiom:storage-auditor` | `axiom-storage-diag` | `systematic-debugging` |
| network | `axiom:networking-auditor` | `axiom-networking-diag` | `systematic-debugging` |
| security | `axiom:security-privacy-scanner` | `axiom-privacy-ux` | `systematic-debugging` |
| test | `axiom:test-failure-analyzer` | `axiom-ui-testing` | `systematic-debugging` |
| iap | `axiom:iap-auditor` | `axiom-storekit-ref` | `systematic-debugging` |
| location | - | `axiom-core-location-diag` | `systematic-debugging` |
| intents | - | `axiom-app-intents-ref` | `systematic-debugging` |
| widgets | - | `axiom-extensions-widgets-ref` | `systematic-debugging` |
| foundation-models | - | `axiom-foundation-models-diag` | `systematic-debugging` |
| general | - | - | `systematic-debugging` |

### tdd Action

| Domain | Axiom Agent | Axiom Skill | Superpowers |
|--------|-------------|-------------|-------------|
| test | `axiom:test-runner` | `axiom-ui-testing` | `test-driven-development` |
| * | - | `axiom-ui-testing` | `test-driven-development` |

### review Action

**Two-phase architecture:** Phase 1 runs fixed horizontal auditors. Phase 2 detects modules/frameworks from changed files and dispatches domain-specific auditors + loads skills.

#### Phase 1: Fixed Horizontal Auditors (always run)

| Axiom Agents (parallel) | Superpowers |
|------------------------|-------------|
| `axiom:concurrency-auditor`, `axiom:accessibility-auditor`, `axiom:swiftui-architecture-auditor`, `axiom:security-privacy-scanner`, `axiom:memory-auditor` | `requesting-code-review` |

#### Phase 2: Dynamic Domain Auditors (based on changed files)

Detect modules from file paths, then dispatch additional agents and load skills.

**Module → Additional Agents:**

| Module (file path prefix) | Additional Agents | Additional Skills to Load |
|---------------------------|-------------------|--------------------------|
| `Sources/CameraFeature/` | `axiom:camera-auditor`, `axiom:energy-auditor` | `axiom-camera-capture`, `axiom-avfoundation-ref` |
| `Sources/VisionCore/` | — | `axiom-vision`, `axiom-vision-ref` |
| `Sources/EdgeTAMFeature/` | — | `axiom-ios-ml`, `axiom-foundation-models` |
| `Sources/Persistence/` | `axiom:codable-auditor`, `axiom:networking-auditor` | `axiom-codable`, `axiom-networking`, `axiom-storage` |
| `Sources/CollectionFeature/` | `axiom:swiftui-performance-analyzer`, `axiom:swiftui-nav-auditor` | `axiom-swiftui-performance`, `axiom-swiftui-nav` |
| `Sources/OnboardingFeature/` | — | `axiom-privacy-ux` |
| `Sources/Core/DesignSystem/` | — | `axiom-hig`, `axiom-liquid-glass` |
| `Tests/` | `axiom:testing-auditor` | `axiom-ui-testing` |

**Framework → Additional Agents (import-based, supplements module detection):**

| Import detected in diff | Additional Agent |
|--------------------------|-----------------|
| `AVFoundation` or `Photos` | `axiom:camera-auditor` (if not already added) |
| `Vision` or `CoreML` | — (load `axiom-vision` skill) |
| `NavigationStack` or `NavigationPath` usage | `axiom:swiftui-nav-auditor` (if not already added) |
| `Codable` conformance or `JSONDecoder`/`JSONEncoder` | `axiom:codable-auditor` (if not already added) |

**UI file detection (integrates polish auditors):**

When changed files match `*View.swift`, `*Sheet.swift`, `*Card.swift`, `*Badge.swift`, `*Button.swift`, `*Overlay.swift`:
- Add `axiom:liquid-glass-auditor`
- Add palette auditor (general-purpose with `palette-auditor.md` prompt)
- Add HIG auditor (general-purpose with `hig-auditor.md` prompt)
- Mark polish as covered — skip separate `/polish` invocation

**Budget cap:** Load at most 3 additional skills in Phase 2 (prioritize by number of changed files per module). Phase 2 agents have no cap — they run in parallel with Phase 1.

### plan Action

| Domain | Axiom Agent | Axiom Skill | Superpowers |
|--------|-------------|-------------|-------------|
| iap | `axiom:iap-implementation` | `axiom-storekit-ref` | `writing-plans` |
| ui-glass | `axiom:liquid-glass-auditor` | `axiom-liquid-glass-ref` | `writing-plans` |
| foundation-models | - | `axiom-foundation-models-ref` | `writing-plans` |
| * | - | `axiom-apple-docs-research` | `writing-plans` |

### execute Action

| Domain | Axiom Agent | Superpowers |
|--------|-------------|-------------|
| test | `axiom:test-runner` | `executing-plans` |
| * | - | `executing-plans` |

### brainstorm Action

| Domain | Axiom Skill | Superpowers |
|--------|-------------|-------------|
| ui-* | `axiom-hig`, `axiom-swiftui-architecture` | `brainstorming` |
| * | `axiom-apple-docs-research` | `brainstorming` |

### parallel Action

| Domain | Routing |
|--------|---------|
| * | Route each subtask through domain detection, launch agents in parallel |

---

## 3. Execution Sequences

### debug Execution

```
1. domain = DETECT(context)
2. route = ROUTING_MATRIX[debug][domain]
3. IF route.axiom_skill:
   Skill(skill=route.axiom_skill)
4. IF route.axiom_agent:
   Task(
     description="Debug {domain} issue",
     prompt=context,
     subagent_type=route.axiom_agent
   )
   WAIT for result
5. IF route.superpowers:
   Skill(skill="superpowers:{route.superpowers}")
6. VERIFY()
```

### tdd Execution

```
1. domain = DETECT(context)
2. Skill(skill="axiom-ui-testing")
3. IF domain == test:
   Task(subagent_type="axiom:test-runner", prompt=context)
4. Skill(skill="superpowers:test-driven-development")
5. VERIFY()
```

### review Execution

```
1. changed_files = `git diff --name-only`

--- Phase 1: Fixed Horizontal Auditors (always) ---

2. Launch 5 agents in parallel (single message):
   Task(subagent_type="axiom:concurrency-auditor",          prompt=changed_files)
   Task(subagent_type="axiom:accessibility-auditor",         prompt=changed_files)
   Task(subagent_type="axiom:swiftui-architecture-auditor",  prompt=changed_files)
   Task(subagent_type="axiom:security-privacy-scanner",      prompt=changed_files)
   Task(subagent_type="axiom:memory-auditor",                prompt=changed_files)

--- Phase 2: Dynamic Domain Auditors (based on changed files) ---

3. modules = EXTRACT_MODULES(changed_files)
   // e.g., {"CameraFeature": [file1, file2], "Persistence": [file3]}

4. phase2_agents = []
   phase2_skills = []

   FOR module IN modules:
     route = MODULE_SKILL_MAP[module]
     phase2_agents += route.agents
     phase2_skills += route.skills

5. DEDUP phase2_agents (remove any already in Phase 1)

6. IF changed_files match *View.swift, *Sheet.swift, *Card.swift, etc.:
     phase2_agents += [axiom:liquid-glass-auditor]
     phase2_agents += [general-purpose(palette-auditor), general-purpose(hig-auditor)]
     polish_covered = true

7. Launch Phase 2 agents in parallel (single message):
   FOR agent IN phase2_agents:
     Task(subagent_type=agent, prompt=relevant_files_for_module)

--- Phase 3: Skill-Enriched Synthesis ---

8. WAIT for all Phase 1 + Phase 2 agents

9. COMBINE all audit_results (Phase 1 + Phase 2)

10. Load domain skills for reviewer context (max 3):
    phase2_skills = PRIORITIZE(phase2_skills, by=file_count_per_module)
    FOR skill IN phase2_skills[:3]:
      Skill(skill=skill)

11. Skill(skill="superpowers:requesting-code-review", context=audit_results + domain_skills)

12. IF critical_findings (P0/P1):
    OFFER_ISSUE_FILING(findings)

13. IF polish_covered:
    Report: "Polish auditors ran as part of review (palette, HIG, liquid-glass)."

14. VERIFY()
```

### Issue Filing from Review

When code review finds critical issues (P0/P1 severity):

```
1. FOR each critical_finding:
   - Extract: file, line, description, severity
   - Present: "Found critical issue: [description] in [file]:[line]"

2. Ask: "File as issue(s)? (y/n/select)"
   - y → File all as separate issues
   - n → Skip, continue review
   - select → Let user pick which to file

3. FOR each selected_finding:
   Skill(skill="file-issue", args="--source code-review --context <finding>")

   Context:
   {
     "source": "code-review",
     "file": "path/to/file.swift",
     "line": 123,
     "finding": "description",
     "severity": "P0",
     "auditor": "axiom:concurrency-auditor"
   }

4. Continue with remaining review
5. Summary includes: "Filed X issues: [links]"
```

### plan Execution

```
1. domain = DETECT(context)
2. route = ROUTING_MATRIX[plan][domain]
3. IF route.axiom_agent:
   Task(subagent_type=route.axiom_agent, prompt=context)
4. APPLE_DOCS(context):
   IF mcpbridge available:
     mcp__xcode__DocumentationSearch(query=context)
   ELSE:
     Skill(skill=route.axiom_skill OR "axiom-apple-docs-research")
5. Skill(skill="superpowers:writing-plans")
6. VERIFY()
```

### execute Execution

```
1. domain = DETECT(context)
2. IF domain == test:
   Task(subagent_type="axiom:test-runner")
3. Skill(skill="superpowers:executing-plans")
4. VERIFY()
```

### brainstorm Execution

```
1. domain = DETECT(context)
2. IF domain starts with "ui-":
   Skill(skill="axiom-hig")
   Skill(skill="axiom-swiftui-architecture")
3. ELSE:
   APPLE_DOCS(context):
     IF mcpbridge available:
       mcp__xcode__DocumentationSearch(query=context)
     ELSE:
       Skill(skill="axiom-apple-docs-research", args=context)
4. Skill(skill="superpowers:brainstorming")
```

### parallel Execution

```
1. tasks = PARSE(context)
2. FOR task IN tasks:
   domain = DETECT(task)
   route = ROUTING_MATRIX[debug][domain]
   IF route.axiom_agent:
     Task(subagent_type=route.axiom_agent, prompt=task)
3. Skill(skill="superpowers:dispatching-parallel-agents")
```

---

## 4. Verification (`superpowers:verification-before-completion`)

**REQUIRED:** Every execution sequence ends with `VERIFY()`. This is the gate function from `superpowers:verification-before-completion`. No completion claims without fresh evidence.

### Gate Function (VERIFY)

```
1. IDENTIFY: What commands prove the work is correct?
2. RUN: Execute FULL commands (fresh, not cached):
   - Build: `mcp__xcode__BuildProject` (preferred) or `swift build` (fallback)
   - Tests: `mcp__xcode__RunAllTests` (preferred) or `swift test` (fallback)
3. READ: Full output — exit code, test counts, error messages
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence. Do NOT claim success.
   - If YES: State claim WITH evidence (exit code, N/N tests passed)
5. ONLY THEN: Claim completion

Skip any step = unverified claim. Do not proceed.
```

### Additional Checks (after build/test pass)

- [ ] No deprecated APIs introduced (check via `mcp__xcode__DocumentationSearch` or `axiom-apple-docs-research`)
- [ ] Swift 6 concurrency satisfied (actor isolation, Sendable)
- [ ] API signatures match Apple documentation

### Backend Verification (when applicable)

If iOS changes involve backend communication:

```
1. Check Cloud Functions status:
   mcp__plugin_firebase_firebase__functions_list_functions

2. Check for errors after deploy:
   mcp__plugin_firebase_firebase__functions_get_logs
   - function_names: ["ai-pipeline-orchestrator"]
   - min_severity: "WARNING"
   - order: "desc"

3. Verify Firestore operations work:
   mcp__plugin_firebase_firebase__firestore_list_collections
```

### Dispatched Agent Verification

When dispatching Task agents (debug, review, tdd, parallel), include this instruction in every agent prompt:

```
VERIFICATION REQUIRED: Before claiming work is complete, you MUST run build/test
commands, read full output, and report results WITH evidence (exit codes, test
counts). No 'should work' or 'looks good' claims. Evidence before claims, always.
```

Agent reports without evidence are unverified — treat as unconfirmed and re-verify independently.

---

## 5. Error Handling (Fail-Fast)

**NO FALLBACKS.** If something fails, STOP and explain:

### Agent Unavailable

```
ERROR: Axiom agent '{subagent_type}' is not available.

Required agent: {agent_name}
Domain detected: {domain}
Action attempted: {action}

This agent is required for {domain} issues. Check that:
1. Axiom plugin is installed and configured
2. The agent subagent_type is correct: {subagent_type}

Cannot proceed without this agent.
```

### Skill Not Found

```
ERROR: Axiom skill '{skill_name}' not found.

Required skill: {skill_name}
Domain detected: {domain}

This skill is required for {action} on {domain}. Check that:
1. Axiom plugin is installed
2. Skill name is correct

Cannot proceed without this skill.
```

### Domain Detection Failed

```
ERROR: Could not detect iOS domain from context.

Context provided: "{context}"

No patterns matched. Provide more specific context including:
- Error messages
- API names (e.g., @MainActor, AVCaptureSession)
- Framework names (e.g., SwiftUI, CoreData)

Cannot proceed without domain classification.
```

### Verification Failed

```
ERROR: Post-execution verification failed (superpowers:verification-before-completion).

Evidence:
- Command: {command_run}
- Exit code: {exit_code}
- Output: {relevant_output}

Issues found:
- [ ] {verification_issue_1}
- [ ] {verification_issue_2}

Fix these issues before proceeding. Do NOT claim success.
```

---

## 6. Axiom Inventory Reference

### Agents (via Task tool)

| Agent | subagent_type | Domain |
|-------|---------------|--------|
| Build Fixer | `axiom:build-fixer` | build |
| Build Optimizer | `axiom:build-optimizer` | build-slow |
| SPM Conflict Resolver | `axiom:spm-conflict-resolver` | spm |
| Concurrency Auditor | `axiom:concurrency-auditor` | concurrency |
| Memory Auditor | `axiom:memory-auditor` | memory |
| Energy Auditor | `axiom:energy-auditor` | energy |
| Accessibility Auditor | `axiom:accessibility-auditor` | ui-access |
| SwiftUI Architecture Auditor | `axiom:swiftui-architecture-auditor` | ui-arch |
| SwiftUI Nav Auditor | `axiom:swiftui-nav-auditor` | ui-nav |
| SwiftUI Performance Analyzer | `axiom:swiftui-performance-analyzer` | ui-perf |
| Liquid Glass Auditor | `axiom:liquid-glass-auditor` | ui-glass |
| TextKit Auditor | `axiom:textkit-auditor` | ui-text |
| Camera Auditor | `axiom:camera-auditor` | media-camera |
| Core Data Auditor | `axiom:core-data-auditor` | data-core |
| iCloud Auditor | `axiom:icloud-auditor` | data-icloud |
| Storage Auditor | `axiom:storage-auditor` | data-storage |
| Codable Auditor | `axiom:codable-auditor` | data-codable |
| Networking Auditor | `axiom:networking-auditor` | network |
| Security Privacy Scanner | `axiom:security-privacy-scanner` | security |
| Test Failure Analyzer | `axiom:test-failure-analyzer` | test |
| Test Runner | `axiom:test-runner` | test |
| Test Debugger | `axiom:test-debugger` | test |
| Testing Auditor | `axiom:testing-auditor` | test |
| IAP Auditor | `axiom:iap-auditor` | iap |
| IAP Implementation | `axiom:iap-implementation` | iap |
| Simulator Tester | `axiom:simulator-tester` | test |
| Swift Performance Analyzer | `axiom:swift-performance-analyzer` | performance |

### Skills (via Skill tool)

**UI & Design:**
`axiom-hig`, `axiom-hig-ref`, `axiom-liquid-glass`, `axiom-liquid-glass-ref`, `axiom-swiftui-architecture`, `axiom-swiftui-layout`, `axiom-swiftui-layout-ref`, `axiom-swiftui-nav`, `axiom-swiftui-nav-diag`, `axiom-swiftui-performance`, `axiom-swiftui-debugging`, `axiom-swiftui-debugging-diag`, `axiom-swiftui-gestures`, `axiom-swiftui-26-ref`, `axiom-swiftui-animation-ref`, `axiom-swiftui-containers-ref`, `axiom-textkit-ref`, `axiom-typography-ref`, `axiom-uikit-animation-debugging`

**Computer Vision & ML:**
`axiom-vision`, `axiom-coreml`, `axiom-speech`, `axiom-foundation-models`, `axiom-foundation-models-ref`, `axiom-foundation-models-diag`

**Debugging:**
`axiom-xcode-debugging`, `axiom-memory-debugging`, `axiom-build-debugging`, `axiom-build-performance`, `axiom-performance-profiling`, `axiom-auto-layout-debugging`, `axiom-deep-link-debugging`, `axiom-objc-block-retain-cycles`

**Concurrency:**
`axiom-swift-concurrency`

**Persistence & Storage:**
`axiom-codable`, `axiom-core-data`, `axiom-core-data-diag`, `axiom-swiftdata`, `axiom-swiftdata-migration`, `axiom-swiftdata-migration-diag`, `axiom-database-migration`, `axiom-cloud-sync`, `axiom-cloud-sync-diag`, `axiom-cloudkit-ref`, `axiom-icloud-drive-ref`, `axiom-storage`, `axiom-storage-diag`, `axiom-storage-management-ref`, `axiom-file-protection-ref`, `axiom-grdb`, `axiom-sqlitedata`, `axiom-sqlitedata-migration`, `axiom-realm-migration-ref`

**Integration:**
`axiom-apple-docs-research`, `axiom-app-intents`, `axiom-app-intents-ref`, `axiom-app-shortcuts-ref`, `axiom-app-discoverability`, `axiom-core-spotlight-ref`, `axiom-extensions-widgets`, `axiom-extensions-widgets-ref`, `axiom-in-app-purchases`, `axiom-storekit-ref`, `axiom-networking`, `axiom-networking-diag`, `axiom-network-framework-ref`, `axiom-now-playing`, `axiom-avfoundation-ref`, `axiom-core-location`, `axiom-core-location-ref`, `axiom-core-location-diag`, `axiom-haptics`, `axiom-localization`, `axiom-privacy-ux`, `axiom-energy-ref`, `axiom-energy-diag`

**Testing:**
`axiom-ui-testing`

**Accessibility:**
`axiom-accessibility-diag`

### Commands (via /axiom:*)

| Command | Purpose |
|---------|---------|
| `/axiom:ask` | Route question to appropriate skill |
| `/axiom:audit <area>` | Run specific audit |
| `/axiom:status` | Project health dashboard |
| `/axiom:fix-build` | Launch build-fixer agent |
| `/axiom:optimize-build` | Launch build-optimizer agent |
| `/axiom:screenshot` | Capture simulator screenshot |
| `/axiom:test-simulator` | Launch simulator testing |

### Hooks (Automatic)

| Hook | Trigger | Action |
|------|---------|--------|
| Build Failure | xcodebuild/swift build fails | Suggests `/axiom:fix-build` |
| Session Start | New Claude Code session | Checks zombie processes, Derived Data |
| Core Data Protection | Edit .xcdatamodeld | Warns about migrations |
| Swift Auto-Format | Edit .swift files | Runs swiftformat |

---

## 7. Examples

### Example 1: Debug Concurrency Issue

```
/ios-superpowers debug "@MainActor warning in CameraViewModel"
```

Execution:
1. Domain detected: `concurrency` (pattern: @MainActor)
2. Skill: `axiom-swift-concurrency`
3. Agent: `Task(subagent_type="axiom:concurrency-auditor")`
4. Superpowers: `systematic-debugging`
5. Verify Swift 6 compliance

### Example 2: Plan Camera Feature

```
/ios-superpowers plan real-time object detection with Vision
```

Execution:
1. Domain detected: `media-vision` (pattern: Vision, object detection)
2. Skill: `axiom-apple-docs-research` (fetch Vision API docs)
3. Skill: `axiom-vision`
4. Superpowers: `writing-plans`

### Example 3: Code Review (Camera + Persistence changes)

```
/ios-superpowers review
```

Changed files:
- `Sources/CameraFeature/CameraService.swift`
- `Sources/CameraFeature/PhotoProcessor.swift`
- `Sources/Persistence/ItemService.swift`
- `Sources/CollectionFeature/ItemDetailView.swift`

Execution:

Phase 1 (fixed):
1. Get changed files: `git diff --name-only`
2. Launch 5 horizontal auditors in parallel:
   - `axiom:concurrency-auditor`
   - `axiom:accessibility-auditor`
   - `axiom:swiftui-architecture-auditor`
   - `axiom:security-privacy-scanner`
   - `axiom:memory-auditor`

Phase 2 (dynamic):
3. Detect modules: CameraFeature, Persistence, CollectionFeature
4. Additional agents:
   - `axiom:camera-auditor` (CameraFeature)
   - `axiom:energy-auditor` (CameraFeature)
   - `axiom:codable-auditor` (Persistence)
   - `axiom:networking-auditor` (Persistence)
   - `axiom:swiftui-performance-analyzer` (CollectionFeature)
   - `axiom:swiftui-nav-auditor` (CollectionFeature)
5. UI file detected (`ItemDetailView.swift`):
   - `axiom:liquid-glass-auditor`
   - palette auditor, HIG auditor
6. Launch all Phase 2 agents in parallel

Phase 3 (synthesis):
7. Load skills (top 3 by file count): `axiom-camera-capture`, `axiom-codable`, `axiom-swiftui-performance`
8. Superpowers: `requesting-code-review` (with all audit results + skill context)
9. Polish covered — skip separate `/polish`

### Example 4: Debug Build Failure

```
/ios-superpowers debug "BUILD FAILED: module 'AVFoundation' not found"
```

Execution:
1. Domain detected: `build` (pattern: BUILD FAILED, module not found)
2. Skill: `axiom-xcode-debugging`
3. Agent: `Task(subagent_type="axiom:build-fixer")`
4. No superpowers needed (agent is self-contained)

---

## 8. Post-Review: Documentation Check

After the `review` action completes:

1. Run: `uv run scripts/check_doc_freshness.py --quiet`
2. If exit code 1 (stale docs):
   - Print: "Documentation may need updating. Stale docs detected for iOS scope."
   - Print: "Run `/doc-superpowers review-pr ios` for details."
3. If exit code 0: no action needed.

---

## 9. Token Budget

| Component | Budget |
|-----------|--------|
| Domain detection | 0 (table lookup) |
| Axiom agent (Phase 1 + Phase 2) | Agent-managed (each agent has own context) |
| Phase 2 domain skills (max 3) | 5K-15K per skill, 45K total |
| Apple docs (via axiom-apple-docs-research) | 8K per API, 25K total |
| Superpowers context | 5K |
| **Total max (non-review)** | **50K** |
| **Total max (review)** | **75K** (agents run in separate contexts) |

**Review budget note:** Phase 1 and Phase 2 agents run as Task subagents with their own context windows, so they don't consume the main budget. The main context only sees their summarized results + up to 3 loaded skills for Phase 3 synthesis.

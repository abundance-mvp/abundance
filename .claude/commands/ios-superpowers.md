---
name: ios-superpowers
description: Deterministic iOS orchestrator that routes to Axiom agents and skills. Use instead of raw superpowers for ALL iOS/Swift work.
---

# ios-superpowers

**CRITICAL:** Use this instead of raw superpowers skills for ALL iOS/Swift work.

## Usage

```
/ios-superpowers <action> <context>
```

## Actions

| Action | Purpose | Example |
|--------|---------|---------|
| `debug` | Debug iOS issues | `/ios-superpowers debug "@MainActor warning"` |
| `tdd` | Test-driven development | `/ios-superpowers tdd add camera tests` |
| `review` | Two-phase code review (horizontal + domain-specific auditors) | `/ios-superpowers review` |
| `plan` | Plan implementation | `/ios-superpowers plan object detection` |
| `execute` | Execute a plan | `/ios-superpowers execute docs/plans/...` |
| `brainstorm` | Design exploration | `/ios-superpowers brainstorm auth flow` |
| `parallel` | Multi-agent dispatch | `/ios-superpowers parallel "fix A, fix B"` |

## How It Works

1. **Detect** iOS domain from context (build, concurrency, UI, data, etc.)
2. **Route** to appropriate Axiom agent/skill based on deterministic matrix
3. **Invoke** superpowers skill with enriched context
4. **Verify** against Apple documentation

## Domain Detection

Patterns are matched in priority order:

| Domain | Patterns |
|--------|----------|
| build | BUILD FAILED, module not found |
| concurrency | @MainActor, actor, Sendable |
| memory | leak, retain cycle |
| ui-* | SwiftUI, navigation, accessibility |
| data-* | CoreData, SwiftData, iCloud |
| media-* | camera, Vision, audio |
| network | URLSession, API |
| test | XCUITest, flaky |

## Axiom Integration

This command uses Axiom exclusively:

- **Agents** for execution (via Task tool)
- **Skills** for context (via Skill tool)
- **Commands** for utilities (`/axiom:status`, `/axiom:screenshot`)

For Apple documentation, uses `axiom-apple-docs-research`.

## Error Handling

**No fallbacks.** If something fails, stops and explains:

- Agent unavailable → Shows which agent and why needed
- Skill not found → Shows which skill and domain
- Domain detection failed → Asks for more specific context

## Examples

### Debug Build Failure

```
/ios-superpowers debug "BUILD FAILED: module 'AVFoundation' not found"
```

Routes to: `axiom:build-fixer` agent

### Debug Concurrency

```
/ios-superpowers debug "@MainActor warning in CameraViewModel"
```

Routes to: `axiom-swift-concurrency` skill + `axiom:concurrency-auditor` agent + `systematic-debugging`

### Plan Feature

```
/ios-superpowers plan real-time object detection with Vision
```

Routes to: `axiom-apple-docs-research` + `axiom-vision` skill + `writing-plans`

### Code Review

```
/ios-superpowers review
```

Routes to: Two-phase review:
- **Phase 1:** 5 fixed horizontal auditors (concurrency, accessibility, architecture, security, memory)
- **Phase 2:** Dynamic auditors based on changed modules (camera, codable, nav, energy, testing, polish)
- **Phase 3:** Skill-enriched synthesis with `requesting-code-review`

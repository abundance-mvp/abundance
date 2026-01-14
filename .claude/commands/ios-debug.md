---
name: ios-debug
description: Debug iOS issues using Axiom skills and Apple documentation
---

# iOS Debug Command

Systematic iOS debugging using Axiom skills and sosumi.ai documentation.

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
```

## What This Does

1. **Identify Issue Type**
   - Build/Compile → axiom-xcode-debugging
   - Memory → axiom-memory-debugging
   - Concurrency → axiom-swift-concurrency
   - UI → axiom-swiftui-* or axiom-liquid-glass
   - Database → axiom-swiftdata or axiom-database-migration
   - Testing → axiom-ui-testing
   - Energy → axiom-energy

2. **Activate Axiom Skill**
   - Systematic diagnosis workflow
   - Environment-first diagnostics
   - Common issue checklist

3. **Fetch Apple Documentation**
   - Use sosumi.ai MCP to look up APIs
   - Search for error messages
   - Get official fix patterns

4. **Apply Fix**
   - Follow documented patterns
   - Write test to verify fix
   - Commit with explanation

## Issue Routing

| Symptoms | Axiom Skill | First Action |
|----------|-------------|--------------|
| BUILD FAILED | axiom-xcode-debugging | Check build settings |
| module not found | axiom-xcode-debugging | Check target membership |
| EXC_BAD_ACCESS | axiom-memory-debugging | Check zombies |
| Memory leak | axiom-memory-debugging | Run Instruments |
| Actor isolated | axiom-swift-concurrency | Check actor boundaries |
| Data race | axiom-swift-concurrency | Add Sendable |
| SwiftUI crash | axiom-swiftui-* | Check state updates |
| Migration error | axiom-database-migration | Check schema version |
| Test flaky | axiom-ui-testing | Check async waits |
| Battery drain | axiom-energy | Run Power Profiler |

## Workflow

```
1. Parse error/issue description
2. Route to Axiom skill
3. Run diagnostic workflow
4. Search sosumi.ai for API info
5. Apply fix pattern
6. Write test
7. Verify fix
8. Document solution
```

## Integration with superpowers:systematic-debugging

This command wraps superpowers:systematic-debugging with iOS-specific enhancements:
- Automatic Axiom skill selection
- Apple docs grounding via sosumi.ai MCP
- iOS-specific diagnostic patterns

## Output

- Root cause identified
- Fix applied with test
- Documentation reference
- Commit with explanation

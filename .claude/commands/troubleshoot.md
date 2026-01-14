# iOS-Aware Troubleshooting

Debug bugs, test failures, and unexpected behavior with mandatory Apple documentation verification for iOS issues.

## Process

### Phase 1: Detect iOS Framework Involvement

Analyze the problem context for iOS indicators:
- **Error messages**: Contains `Swift`, `iOS`, framework names (Vision, AVFoundation, SwiftUI, etc.)
- **Stack traces**: Swift files, iOS SDK paths, Xcode errors
- **File locations**: `Sources/*.swift`, `App/*.swift`, `Tests/*Tests.swift`
- **Keywords**: `@MainActor`, `async`, `Task`, `@Observable`, `actor`, `Sendable`

**If iOS framework detected** → Proceed to Phase 2
**If NO iOS involvement** → Skip to Phase 3

### Phase 2: Fetch Apple Documentation (iOS only)

**MANDATORY for iOS-related issues.**

1. Extract iOS APIs from error/context:
   - Framework APIs mentioned in error
   - Classes/structs in stack trace
   - Swift features in failing code

2. Invoke apple-docs-fetcher (max 3-5 APIs):
   ```
   Tool: Skill
   Parameters:
     skill: apple-docs-fetcher
   ```

3. Check documentation for:
   - Correct API usage patterns
   - Threading/concurrency requirements (@MainActor, Sendable)
   - iOS version availability
   - Known issues or deprecations
   - Required entitlements or capabilities

### Phase 3: Invoke Systematic Debugging

Use the superpowers systematic-debugging skill:

```
Tool: Skill
Parameters:
  skill: superpowers:systematic-debugging
```

Follow the five-phase framework:
1. **Root cause investigation** - Find where the problem originates
2. **Pattern analysis** - Understand why it's happening (compare with Apple docs)
3. **Hypothesis testing** - Verify understanding before fixing
4. **Implementation** - Apply the correct solution (per Apple docs patterns)
5. **Verification** - Confirm fix works and follows Apple best practices

### Phase 4: Verify Fix Against Apple Documentation (iOS only)

After implementing a fix for iOS code:

1. Re-invoke apple-docs-fetcher for the APIs used in the fix
2. Verify:
   - Fix uses latest Apple patterns (not deprecated APIs)
   - Threading model is correct
   - iOS version requirements are met
   - No new warnings introduced

---

## Red Flags - STOP and Fetch Apple Docs

If you catch yourself thinking:
- "I know how this iOS API works" → STOP, verify with docs
- "This Swift concurrency issue is obvious" → STOP, check actor isolation rules
- "The fix is simple" → STOP, verify it follows current Apple patterns
- "I'll check docs after fixing" → STOP, check docs BEFORE fixing

**All iOS debugging requires Apple docs verification. No exceptions.**

---

## Problem to Debug

$ARGUMENTS

If no arguments provided, check recent logs and GitHub Actions results for the current branch to identify and troubleshoot any failures.

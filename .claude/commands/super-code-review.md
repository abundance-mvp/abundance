# iOS-Aware Code Review

Perform comprehensive code review with mandatory Apple documentation verification for iOS code.

## Process

### Phase 1: Detect iOS Code in Changes

First, identify what files are being reviewed:
- If reviewing a PR: `gh pr diff $ARGUMENTS` or `git diff main...HEAD`
- If reviewing current branch: `git diff main`

Scan for iOS framework indicators:
- **iOS imports**: `import SwiftUI`, `import UIKit`, `import Vision`, `import AVFoundation`, `import Combine`, `import CoreML`
- **iOS keywords**: `@Observable`, `@MainActor`, `@State`, `@Published`, `Task`, `async`, `await`
- **File extensions**: `.swift` files in `Sources/` or `App/`

**If iOS code detected** → Proceed to Phase 2
**If NO iOS code** → Skip to Phase 3

### Phase 2: Fetch Apple Documentation (iOS only)

**MANDATORY for iOS code changes.**

1. Extract specific APIs from the changed code:
   - SwiftUI modifiers (`.animation()`, `.containerRelativeFrame()`, etc.)
   - Swift features (`@Observable`, typed throws, actors)
   - Framework APIs (`VNCoreMLRequest`, `AVCaptureSession`, etc.)

2. Invoke apple-docs-fetcher for each API (max 3-5 APIs):
   ```
   Tool: Skill
   Parameters:
     skill: apple-docs-fetcher
   ```

3. Verify against latest Apple documentation:
   - API signatures match usage
   - iOS version requirements met (check deployment target)
   - No deprecated APIs used
   - Using latest best practices

### Phase 3: Invoke Code Reviewer

Use the superpowers plugin's requesting-code-review skill:

```
Tool: Skill
Parameters:
  skill: superpowers:requesting-code-review
```

Include in the review context:
- Apple documentation findings from Phase 2 (if iOS)
- CLAUDE.md requirements and project standards
- ADR compliance (ADR-010 SwiftUI-only, etc.)
- Test coverage requirements (80%+)

### Phase 4: Report Findings

Code reviewer validates:
- Implementation matches plan/requirements
- Follows ADRs and DESIGN docs
- Test coverage adequate (80%+)
- Code quality (no lint errors)
- **iOS: Uses latest Apple APIs correctly** (from Phase 2)

Confidence threshold: 80

---

## Red Flags - STOP and Fetch Apple Docs

If you catch yourself thinking:
- "I know this API from training data" → STOP, fetch docs
- "This SwiftUI pattern is straightforward" → STOP, verify with docs
- "Fetching docs takes time" → STOP, it takes 2 seconds and saves hours
- "I'm confident about this iOS API" → STOP, verify availability/deprecation

**All iOS code changes require Apple docs verification. No exceptions.**

---

## Target

$ARGUMENTS

If no arguments provided, review the current branch's changes against the main branch.

Check codebase for architecture drift from ADRs and design documents.

This command uses Claude Code's conversational interface with severity-based reporting:

1. Loads all ADR constraints from docs/adr/
2. Scans codebase for violations (Swift, TypeScript, rules)
3. Assigns severity: P0 (blocks PR), P1 (requires approval), P2 (warn)
4. Reports file:line locations with fix suggestions

Usage:
```
/check-drift
```

When this command runs, Claude will:
- Load the drift-detector agent specification from `.claude/agents/drift-detector.md`
- Scan ios/, backend/, and configuration files
- Generate a drift report with severity levels

Expected output:
```
🚫 P0 VIOLATION (BLOCKS PR):
  File: ios/Views/LoginView.swift:3
  Rule: ADR-010 (SwiftUI-only architecture)
  Found: import UIKit
  Fix: Replace UIKit components with SwiftUI equivalents

⚠️  P1 VIOLATION (REQUIRES REVIEW):
  File: Package.swift:12
  Rule: ADR-015 (Dependency approval process)
  Found: Unauthorized dependency 'Alamofire'
  Fix: Open ADR to justify or use URLSession per ADR-007

ℹ️  P2 WARNING:
  File: ios/Models/User.swift:25
  Rule: ADR-020 (Naming conventions)
  Found: Variable 'usr_id' violates camelCase rule
  Fix: Rename to 'userId'
```

Severity Levels:
- **P0**: CI fails, PR blocked - fix immediately
- **P1**: CI passes with warning, requires 1 additional approval
- **P2**: Informational only, trending tracked in retros

Integration with CI:
This command is also invoked by the drift-detector GitHub Action on PR creation.
See: `.github/workflows/security-pr-review.yml`

Agent Specification: `.claude/agents/drift-detector.md`
